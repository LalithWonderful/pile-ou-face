import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../app/tarot_scope.dart';
import '../../models/drawn_card.dart';
import '../../models/reading_intent.dart';
import '../widgets/card_art_placeholder.dart';
import 'reading_screen.dart';

/// Ritual selection screen sitting between the home intent buttons and
/// the existing 3-card [ReadingScreen]. The user picks 3 face-down cards
/// out of the full 22-card Major Arcana deck (or whatever the asset
/// holds — `min(poolSize, deck.length)` keeps small fixtures viable in
/// tests). The picks are then forwarded to the reading screen as a
/// pre-built draw, so the validated reveal layout is reused verbatim.
///
/// Quota is consumed on the very first pick (one quota per ritual), to
/// mirror the previous "Révéler le tirage" commit point while preventing
/// the user from cycling the choice screen for free retries.
class ThreeCardChoiceScreen extends StatefulWidget {
  const ThreeCardChoiceScreen({
    super.key,
    required this.intent,
    this.random,
  });

  final ReadingIntent intent;

  /// Test seam: injects a deterministic [math.Random] so the candidate
  /// pool and per-card orientation are reproducible.
  final math.Random? random;

  /// Upper bound on the candidate pool size. The bundled Major Arcana
  /// deck has 22 cards; tests sometimes feed a smaller fixture, in
  /// which case the pool is clamped to `min(poolSize, deck.length)`.
  static const int poolSize = 22;

  /// How long the initial shuffle/fan-out animation runs.
  static const Duration shuffleDuration = Duration(milliseconds: 900);

  /// How long the "Ton tirage t’attend." pause is held before the
  /// reading screen replaces the choice screen.
  static const Duration transitionDelay = Duration(milliseconds: 900);

  static const List<String> kPositions = <String>[
    'Là où tu en es',
    'L’énergie du moment',
    'Le conseil',
  ];

  /// Stable key for the gesture surface of pool card [index]. Exposed so
  /// widget tests can target a specific candidate slot — visual order of
  /// the Stack is preserved even after a card is picked, so tests cannot
  /// rely on hit-test position alone.
  @visibleForTesting
  static Key poolCardKey(int index) => ValueKey('threeCardChoicePool#$index');

  @override
  State<ThreeCardChoiceScreen> createState() => _ThreeCardChoiceScreenState();
}

class _PoolEntry {
  _PoolEntry({required this.drawn});
  final DrawnCard drawn;
  bool picked = false;
}

class _ThreeCardChoiceScreenState extends State<ThreeCardChoiceScreen>
    with SingleTickerProviderStateMixin {
  late final math.Random _random;
  late final AnimationController _shuffleController;

  List<_PoolEntry> _pool = const <_PoolEntry>[];
  final List<DrawnCard> _picked = <DrawnCard>[];

  bool _loading = true;
  bool _quotaExhausted = false;
  bool _consumed = false;
  bool _committed = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _random = widget.random ?? math.Random();
    _shuffleController = AnimationController(
      vsync: this,
      duration: ThreeCardChoiceScreen.shuffleDuration,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _shuffleController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    final scope = TarotScope.of(context);
    try {
      final remaining = await scope.quotaService.remaining(widget.intent);
      if (!mounted) return;
      if (remaining == 0) {
        setState(() {
          _loading = false;
          _quotaExhausted = true;
        });
        return;
      }
      final cards = await scope.repository.loadMajorArcana();
      if (!mounted) return;
      if (cards.length < 3) {
        setState(() {
          _loading = false;
          _error = StateError(
            'Not enough cards in deck (${cards.length}) for a 3-card draw.',
          );
        });
        return;
      }
      final shuffled = List.of(cards)..shuffle(_random);
      final size = math.min(ThreeCardChoiceScreen.poolSize, shuffled.length);
      setState(() {
        _pool = <_PoolEntry>[
          for (var i = 0; i < size; i++)
            _PoolEntry(
              drawn: DrawnCard(
                card: shuffled[i],
                reversed: _random.nextBool(),
              ),
            ),
        ];
        _loading = false;
      });
      // The fan is contained — all 22 cards live in the same Stack, no
      // horizontal scroll to centre, so the spread animation can start
      // straight away.
      _shuffleController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _onCardTap(int index) async {
    if (_committed || !mounted) return;
    if (index < 0 || index >= _pool.length) return;
    if (_pool[index].picked) return;
    if (_picked.length >= 3) return;
    // Taps are ignored until the shuffle animation has fully settled, so
    // the user does not pick a card that is still flying into place.
    if (_shuffleController.status != AnimationStatus.completed) return;

    if (!_consumed) {
      final scope = TarotScope.of(context);
      final ok = await scope.quotaService.tryConsume(widget.intent);
      if (!mounted) return;
      if (!ok) {
        setState(() => _quotaExhausted = true);
        return;
      }
      _consumed = true;
    }

    setState(() {
      _pool[index].picked = true;
      _picked.add(_pool[index].drawn);
    });

    if (_picked.length == 3) {
      setState(() => _committed = true);
      await Future<void>.delayed(ThreeCardChoiceScreen.transitionDelay);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ReadingScreen(
            intent: widget.intent,
            preparedDraw: List<DrawnCard>.unmodifiable(_picked),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.intent.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // Both the decorative background AND the page content sit
      // inside Positioned.fill children of a StackFit.expand Stack —
      // this forces every layer to fill the full Scaffold body,
      // including the bottom home-indicator strip. The previous
      // attempt failed because `SafeArea(child: _buildBody())` was a
      // *non-positioned* child of a default-loose Stack: the inner
      // SingleChildScrollView shrunk to its content height, the
      // Stack reported that shorter size to the Scaffold, and the
      // area below the content fell back to the Scaffold's plain
      // ivory background.
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                'assets/tarot/backgrounds/question_reading_bg.webp',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(child: _buildBody()),
          ),
          if (_committed)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: AppColors.ivory.withValues(alpha: 0.92),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Ton tirage t’attend.',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.deepGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Impossible de préparer le tirage.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }
    if (_quotaExhausted) {
      return _ChoiceQuotaExhausted(intent: widget.intent);
    }
    return _buildChoiceLayout();
  }

  Widget _buildChoiceLayout() {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
        final slotWidth = isNarrow ? 78.0 : 92.0;
        // A touch larger than the previous pass so the deck has more
        // presence, while still leaving the container-padding margin
        // intact so the fan never becomes a strip.
        final poolCardWidth = isNarrow ? 50.0 : 58.0;
        // Container margin so the fan sits like an object on the page —
        // even the outermost card always breathes against an empty
        // strip of background.
        final fanContainerPadding = isNarrow ? 28.0 : 32.0;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Choisis tes 3 cartes',
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.deepGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'La bonne carte est celle qui t’appelle.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.charcoal,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SlotsRow(
                  positions: ThreeCardChoiceScreen.kPositions,
                  filled: _picked.length,
                  slotWidth: slotWidth,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _picked.length < 3
                      ? 'Carte ${_picked.length + 1} sur 3'
                      : 'Ton tirage est prêt.',
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.softGold,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // The fan is its own contained object. All 22 cards live
              // inside a fixed-width Stack — no horizontal scroll, no
              // strip — and the surrounding padding ensures the
              // outermost card always sits well away from the screen
              // edges. The cream/foliage background continues
              // unimpeded behind and below the fan. The pre-fan gap
              // stays small (combined with a slimmer `_topBuffer`
              // inside the fan) so the deck reads as anchored to the
              // counter above rather than floating in an empty cream
              // block.
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: fanContainerPadding,
                ),
                child: _PoolFan(
                  pool: _pool,
                  shuffleAnim: _shuffleController,
                  cardWidth: poolCardWidth,
                  onTap: _onCardTap,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SlotsRow extends StatelessWidget {
  const _SlotsRow({
    required this.positions,
    required this.filled,
    required this.slotWidth,
  });

  final List<String> positions;
  final int filled;
  final double slotWidth;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final children = <Widget>[];
    for (var i = 0; i < positions.length; i++) {
      if (i > 0) children.add(const SizedBox(width: 8));
      children.add(
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Slot(filled: i < filled, width: slotWidth),
              const SizedBox(height: 8),
              Text(
                positions[i].toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 2,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.softGold,
                  fontSize: 9,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.filled, required this.width});

  final bool filled;
  final double width;

  static const double _aspect = 1 / 1.6;

  @override
  Widget build(BuildContext context) {
    final height = width / _aspect;
    return SizedBox(
      width: width,
      height: height,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(anim),
            child: child,
          ),
        ),
        child: filled
            ? CardArtPlaceholder(
                key: const ValueKey('filled'),
                variant: CardArtVariant.faceDown,
                width: width,
              )
            : Container(
                key: const ValueKey('empty'),
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.ivory.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.softGold.withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Contained, fixed-width arc of face-down cards. The widget is no
/// longer a horizontal strip — all 22 candidates live inside a single
/// `Stack` sized to the parent's bounded width, so the deck reads as
/// an object on the page rather than a frieze that crosses the screen.
/// No horizontal scroll is needed: the polar formula spreads the cards
/// across the available `fanWidth`, with a quadratic vertical curve
/// that gives the centre card visual prominence and lets the outer
/// cards drop into a real arc.
///
/// Geometry for card `i` (with `centerIndex = (total - 1) / 2`):
///   normalized = (i - centerIndex) / centerIndex     // ∈ [-1, +1]
///   cardCenterX = fanWidth / 2 + normalized * centerSpan / 2
///   cardTop    = topBuffer + |normalized|² * arcDepth
///   cardAngle  = normalized * maxRotationDeg (radians)
///
/// To keep card taps unambiguous when cards heavily overlap, the
/// widget renders a two-layer Stack: the visual cards sit in a lower
/// `IgnorePointer` layer, while a top layer of `Positioned`
/// gesture surfaces covers each card's visible peek strip. The
/// interactive layer also tracks press state so the touched card
/// lifts slightly to acknowledge the finger — and lifts a touch more
/// on actual selection, just before it fades out. The pressed (or
/// picked-and-fading) card is also reordered to draw on top of its
/// neighbours so the lift is actually seen.
class _PoolFan extends StatefulWidget {
  const _PoolFan({
    required this.pool,
    required this.shuffleAnim,
    required this.cardWidth,
    required this.onTap,
  });

  final List<_PoolEntry> pool;
  final Animation<double> shuffleAnim;
  final double cardWidth;
  final void Function(int index) onTap;

  static const double _aspect = 1 / 1.6;

  /// Maximum fan angle (in degrees) at the extreme outer cards. 30°
  /// keeps the arc clearly readable while the slightly bigger cards
  /// don't make the outer sides look too open.
  static const double _maxRotationDeg = 30;

  /// How far the outer cards drop below the centre, in logical
  /// pixels. Combined with the quadratic distance term this produces
  /// the rounded curve.
  static const double _arcDepth = 60;

  /// Vertical lift applied on touch-down so the pressed card visibly
  /// acknowledges the finger.
  static const double _pressLift = 14;

  /// Slightly larger lift applied at the moment a card is selected,
  /// before it fades out — the little ceremonial rise that an instant
  /// fade would miss.
  static const double _pickLift = 22;

  /// Vertical breathing room reserved at the top of the fan so a
  /// pressed or selected centre card has room to lift without
  /// overflowing the SizedBox. Trimmed to match `_pickLift` so the
  /// fan as a whole sits closer to the counter above — the deck no
  /// longer floats in a wide empty cream block.
  static const double _topBuffer = 18;

  /// Vertical breathing room reserved at the bottom of the fan so the
  /// rotated bounding box of an outer card doesn't get clipped.
  static const double _bottomBuffer = 22;

  static const Duration _pressAnimation = Duration(milliseconds: 160);
  static const Duration _fadeAnimation = Duration(milliseconds: 260);

  @override
  State<_PoolFan> createState() => _PoolFanState();
}

class _PoolFanState extends State<_PoolFan> {
  /// Index of the card currently being pressed (touch is down on its
  /// hit region and not yet cancelled). `null` means no press.
  int? _pressedIndex;

  void _setPressed(int? index) {
    if (_pressedIndex == index) return;
    setState(() => _pressedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildFan(constraints.maxWidth);
      },
    );
  }

  Widget _buildFan(double fanWidth) {
    final pool = widget.pool;
    final n = pool.length;
    if (n == 0) return const SizedBox.shrink();

    final cardWidth = widget.cardWidth;
    final cardHeight = cardWidth / _PoolFan._aspect;
    // Span over which card *centres* are distributed: leftmost centre
    // is at cardWidth / 2, rightmost at fanWidth - cardWidth / 2.
    final centerSpan = math.max(0.0, fanWidth - cardWidth);
    final maxAngle = _PoolFan._maxRotationDeg * math.pi / 180;
    final fanHeight = _PoolFan._topBuffer +
        _PoolFan._arcDepth +
        cardHeight +
        _PoolFan._bottomBuffer;

    // Reorder visual cards so the pressed one (and any picked card
    // mid-fade) draws on top of its neighbours — without this, a lift
    // would be hidden under the cards rendered after it in the Stack.
    final naturalOrder = <int>[];
    final highlighted = <int>[];
    for (var i = 0; i < n; i++) {
      if (i == _pressedIndex || pool[i].picked) {
        highlighted.add(i);
      } else {
        naturalOrder.add(i);
      }
    }
    final drawOrder = <int>[...naturalOrder, ...highlighted];

    return SizedBox(
      width: fanWidth,
      height: fanHeight,
      child: AnimatedBuilder(
        animation: widget.shuffleAnim,
        builder: (context, _) {
          final t =
              Curves.easeOutCubic.transform(widget.shuffleAnim.value);
          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              for (final i in drawOrder)
                _buildVisualCard(
                  index: i,
                  total: n,
                  cardWidth: cardWidth,
                  cardHeight: cardHeight,
                  centerSpan: centerSpan,
                  fanWidth: fanWidth,
                  maxAngle: maxAngle,
                  t: t,
                ),
              for (var i = 0; i < n; i++)
                if (!pool[i].picked)
                  _buildHitRegion(
                    index: i,
                    total: n,
                    cardWidth: cardWidth,
                    centerSpan: centerSpan,
                    fanWidth: fanWidth,
                    fanHeight: fanHeight,
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVisualCard({
    required int index,
    required int total,
    required double cardWidth,
    required double cardHeight,
    required double centerSpan,
    required double fanWidth,
    required double maxAngle,
    required double t,
  }) {
    final centerIndex = (total - 1) / 2;
    final normalized =
        centerIndex > 0 ? (index - centerIndex) / centerIndex : 0.0;

    // Final fan position via the polar/quadratic formula.
    final fanCardCenterX = fanWidth / 2 + normalized * centerSpan / 2;
    final fanLeft = fanCardCenterX - cardWidth / 2;
    final arcDrop =
        math.pow(normalized.abs(), 2).toDouble() * _PoolFan._arcDepth;
    final fanTop = _PoolFan._topBuffer + arcDrop;
    final fanAngle = normalized * maxAngle;

    // Initial stacked position: all cards centred horizontally in the
    // fan area, anchored at the centre card's final vertical position
    // so during the spread the centre stays put and the outer cards
    // visibly rotate and drop into place.
    final stackedLeft = (fanWidth - cardWidth) / 2;
    final stackedTop = _PoolFan._topBuffer;
    final stackedAngle = (index.isEven ? -1 : 1) * 0.05;

    final left = stackedLeft + (fanLeft - stackedLeft) * t;
    final top = stackedTop + (fanTop - stackedTop) * t;
    final angle = stackedAngle + (fanAngle - stackedAngle) * t;

    final entry = widget.pool[index];
    final isPressed = !entry.picked && _pressedIndex == index;
    final liftY = entry.picked
        ? -_PoolFan._pickLift
        : (isPressed ? -_PoolFan._pressLift : 0.0);
    final scaleFactor = entry.picked
        ? 0.88
        : (isPressed ? 1.03 : 1.0);

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: _PoolFan._pressAnimation,
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..translateByDouble(0.0, liftY, 0.0, 1.0)
            ..scaleByDouble(scaleFactor, scaleFactor, 1.0, 1.0),
          transformAlignment: Alignment.center,
          child: AnimatedOpacity(
            duration: _PoolFan._fadeAnimation,
            opacity: entry.picked ? 0.0 : 1.0,
            child: Transform.rotate(
              angle: angle,
              child: CardArtPlaceholder(
                variant: CardArtVariant.faceDown,
                width: cardWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHitRegion({
    required int index,
    required int total,
    required double cardWidth,
    required double centerSpan,
    required double fanWidth,
    required double fanHeight,
  }) {
    // Each card's hit region matches its visible peek strip: width =
    // step between adjacent card left-edges, except for the rightmost
    // card which has no neighbour to its right and is therefore fully
    // visible. Vertical span covers the full fan height so the deep
    // arc never strands a tappable area.
    final centerIndex = (total - 1) / 2;
    final normalized =
        centerIndex > 0 ? (index - centerIndex) / centerIndex : 0.0;
    final fanCardCenterX = fanWidth / 2 + normalized * centerSpan / 2;
    final fanLeft = fanCardCenterX - cardWidth / 2;
    final step = total > 1 ? centerSpan / (total - 1) : cardWidth;
    final hitWidth = (index == total - 1) ? cardWidth : step;

    return Positioned(
      left: fanLeft,
      top: 0,
      width: hitWidth,
      height: fanHeight,
      child: GestureDetector(
        key: ThreeCardChoiceScreen.poolCardKey(index),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(index),
        onTapUp: (_) => _setPressed(null),
        onTapCancel: () => _setPressed(null),
        onTap: () => widget.onTap(index),
      ),
    );
  }
}

class _ChoiceQuotaExhausted extends StatelessWidget {
  const _ChoiceQuotaExhausted({required this.intent});

  final ReadingIntent intent;

  String get _themePhrase => switch (intent) {
        ReadingIntent.general => 'pour ta situation',
        ReadingIntent.love => 'sur l’amour',
        ReadingIntent.work => 'sur le travail',
        ReadingIntent.money => 'sur l’argent',
      };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // The decorative background is now painted at the parent Scaffold
    // body level — no need for this widget to draw its own.
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tu as déjà tiré deux messages $_themePhrase aujourd’hui.',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.deepGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Laisse ces messages faire leur chemin.\n'
              'Reviens demain pour un nouveau souffle.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.charcoal,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).popUntil(
                (route) => route.isFirst,
              ),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Revenir à l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }
}
