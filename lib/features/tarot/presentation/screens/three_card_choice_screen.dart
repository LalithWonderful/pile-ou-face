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
  final ScrollController _poolScrollController = ScrollController();

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
    _poolScrollController.dispose();
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
      // Centre the horizontal scroll on the strip BEFORE starting the
      // spread animation, so the initial deck stack sits in the middle
      // of the viewport instead of off the left edge.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_poolScrollController.hasClients) {
          final max = _poolScrollController.position.maxScrollExtent;
          _poolScrollController.jumpTo(max / 2);
        }
        _shuffleController.forward();
      });
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
      body: SafeArea(child: _buildBody()),
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
    return Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.25,
            child: Image.asset(
              'assets/tarot/backgrounds/question_reading_bg.webp',
              fit: BoxFit.cover,
            ),
          ),
        ),
        _buildChoiceLayout(),
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
    );
  }

  Widget _buildChoiceLayout() {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
        final slotWidth = isNarrow ? 78.0 : 92.0;
        final poolCardWidth = isNarrow ? 64.0 : 76.0;
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
              const SizedBox(height: 16),
              // The pool itself does NOT inherit the horizontal padding —
              // it owns its own scrollable strip so the fan can extend
              // edge-to-edge and feel like a real spread deck.
              _PoolFan(
                pool: _pool,
                shuffleAnim: _shuffleController,
                scrollController: _poolScrollController,
                cardWidth: poolCardWidth,
                onTap: _onCardTap,
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

/// Horizontal fan of face-down cards. The fan can be wider than the
/// viewport — the user swipes left/right to browse the full Major
/// Arcana — and is centred on first paint so the spread animation
/// happens in front of the eyes instead of off-screen.
///
/// To keep card taps unambiguous when cards heavily overlap, the widget
/// uses a two-layer Stack: the visual cards sit in a lower IgnorePointer
/// layer, and a top layer of small `Positioned` gesture surfaces covers
/// only the visible "peek" strip of each card. A test that taps the
/// stable [ThreeCardChoiceScreen.poolCardKey] therefore hits exactly the
/// intended index, even when 22 cards are packed onto a 320 px viewport.
class _PoolFan extends StatelessWidget {
  const _PoolFan({
    required this.pool,
    required this.shuffleAnim,
    required this.scrollController,
    required this.cardWidth,
    required this.onTap,
  });

  final List<_PoolEntry> pool;
  final Animation<double> shuffleAnim;
  final ScrollController scrollController;
  final double cardWidth;
  final void Function(int index) onTap;

  static const double _aspect = 1 / 1.6;

  /// Fraction of [cardWidth] that each successive card moves to the
  /// right. 0.42 keeps the per-card hit strip wide enough to tap
  /// comfortably (~28 px on narrow phones) while still squeezing 22
  /// cards into a strip that is roughly two viewports wide on a 320 px
  /// screen.
  static const double _peekFraction = 0.42;

  /// Maximum fan angle (in degrees) applied at the extreme outer cards.
  static const double _maxRotationDeg = 9;

  /// Vertical drop applied to the outermost cards, in logical pixels.
  /// Inner cards stay near the top so the fan arc reads naturally.
  static const double _arcDepth = 12;

  @override
  Widget build(BuildContext context) {
    final n = pool.length;
    if (n == 0) return const SizedBox.shrink();
    final cardHeight = cardWidth / _aspect;
    final peek = cardWidth * _peekFraction;
    final stripWidth = cardWidth + peek * (n - 1);
    final fanHeight = cardHeight + _arcDepth + 16;
    final maxAngle = _maxRotationDeg * math.pi / 180;

    return SizedBox(
      height: fanHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: scrollController,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: stripWidth,
          height: fanHeight,
          child: AnimatedBuilder(
            animation: shuffleAnim,
            builder: (context, _) {
              final t = Curves.easeOutCubic.transform(shuffleAnim.value);
              return Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  // Visual layer — hit-transparent so overlapping cards
                  // never steal a tap meant for the card whose peek the
                  // user sees.
                  for (var i = 0; i < n; i++)
                    _buildVisualCard(
                      index: i,
                      total: n,
                      peek: peek,
                      maxAngle: maxAngle,
                      stripWidth: stripWidth,
                      t: t,
                    ),
                  // Hit layer — only over the visible peek strip of
                  // each card (full card width for the rightmost one).
                  for (var i = 0; i < n; i++)
                    if (!pool[i].picked)
                      _buildHitRegion(
                        index: i,
                        total: n,
                        peek: peek,
                        cardHeight: cardHeight,
                      ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVisualCard({
    required int index,
    required int total,
    required double peek,
    required double maxAngle,
    required double stripWidth,
    required double t,
  }) {
    final fanLeft = index * peek;
    // Stack centred on the strip so the spread reads as a radial
    // explosion rather than a slide-out from the left edge.
    final stackedLeft = (stripWidth - cardWidth) / 2;
    final left = stackedLeft + (fanLeft - stackedLeft) * t;

    final fanAngle = total > 1
        ? -maxAngle + (2 * maxAngle) * (index / (total - 1))
        : 0.0;
    final stackedAngle = (index.isEven ? -1 : 1) * 0.05;
    final angle = stackedAngle + (fanAngle - stackedAngle) * t;

    // Outer cards drop a few pixels so the fan curves like an arc.
    final centerIndex = (total - 1) / 2;
    final distance =
        centerIndex > 0 ? (index - centerIndex).abs() / centerIndex : 0.0;
    final fanTop = distance * _arcDepth;
    const stackedTop = 4.0;
    final top = stackedTop + (fanTop - stackedTop) * t;

    final entry = pool[index];

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: entry.picked ? 0 : 1,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 250),
            scale: entry.picked ? 0.85 : 1.0,
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
    required double peek,
    required double cardHeight,
  }) {
    // Every card except the last shows only its left "peek" strip —
    // that is the natural tap target. The last card has no neighbour
    // to its right, so its whole width is hittable.
    final hitLeft = index * peek;
    final hitWidth = (index == total - 1) ? cardWidth : peek;
    return Positioned(
      left: hitLeft,
      top: 4,
      width: hitWidth,
      height: cardHeight,
      child: GestureDetector(
        key: ThreeCardChoiceScreen.poolCardKey(index),
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
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
    return Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.25,
            child: Image.asset(
              'assets/tarot/backgrounds/question_reading_bg.webp',
              fit: BoxFit.cover,
            ),
          ),
        ),
        Padding(
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
        ),
      ],
    );
  }
}
