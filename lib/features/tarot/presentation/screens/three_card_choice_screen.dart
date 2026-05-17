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
/// out of a shuffled candidate pool; the picks are then forwarded to the
/// reading screen as a pre-built draw, so the validated reveal layout is
/// reused verbatim.
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

  /// Number of face-down cards rendered in the candidate fan. Kept small
  /// so the fan fits on a 320 px viewport without overflowing.
  static const int poolSize = 7;

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
        final poolCardWidth = isNarrow ? 62.0 : 74.0;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choisis tes 3 cartes',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.deepGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'La bonne carte est celle qui t’appelle.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.charcoal,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              _SlotsRow(
                positions: ThreeCardChoiceScreen.kPositions,
                filled: _picked.length,
                slotWidth: slotWidth,
              ),
              const SizedBox(height: 12),
              Text(
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
              const SizedBox(height: 16),
              _PoolFan(
                pool: _pool,
                shuffleAnim: _shuffleController,
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

class _PoolFan extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final n = pool.length;
    if (n == 0) return const SizedBox.shrink();
    final cardHeight = cardWidth / _aspect;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Overlap so the whole fan fits on a 320 px viewport.
        final spacing = n > 1 ? (width - cardWidth) / (n - 1) : 0.0;
        final maxAngle = 14 * math.pi / 180;
        return SizedBox(
          width: width,
          height: cardHeight + 28,
          child: AnimatedBuilder(
            animation: shuffleAnim,
            builder: (context, _) {
              final t = Curves.easeOutCubic.transform(shuffleAnim.value);
              return Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  for (var i = 0; i < n; i++)
                    _buildPositioned(
                      index: i,
                      total: n,
                      spacing: spacing,
                      maxAngle: maxAngle,
                      cardHeight: cardHeight,
                      width: width,
                      t: t,
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPositioned({
    required int index,
    required int total,
    required double spacing,
    required double maxAngle,
    required double cardHeight,
    required double width,
    required double t,
  }) {
    final fanLeft = index * spacing;
    final stackedLeft = (width - cardWidth) / 2;
    final left = stackedLeft + (fanLeft - stackedLeft) * t;

    final fanAngle = total > 1
        ? -maxAngle + (2 * maxAngle) * (index / (total - 1))
        : 0.0;
    final stackedAngle = (index.isEven ? -1 : 1) * 0.05;
    final angle = stackedAngle + (fanAngle - stackedAngle) * t;

    // Outer cards drop a few pixels so the fan curves slightly.
    final fanTop = fanAngle.abs() * 18;
    const stackedTop = 4.0;
    final top = stackedTop + (fanTop - stackedTop) * t;

    final entry = pool[index];

    return Positioned(
      left: left,
      top: top,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: entry.picked ? 0 : 1,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 250),
          scale: entry.picked ? 0.85 : 1.0,
          child: Transform.rotate(
            angle: angle,
            child: GestureDetector(
              key: ThreeCardChoiceScreen.poolCardKey(index),
              behavior: HitTestBehavior.opaque,
              onTap: entry.picked ? null : () => onTap(index),
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
