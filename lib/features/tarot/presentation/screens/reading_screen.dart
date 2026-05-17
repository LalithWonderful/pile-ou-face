import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/app_theme.dart';
import '../../../../app/tarot_scope.dart';
import '../../models/drawn_card.dart';
import '../../models/reading_intent.dart';
import '../../models/tarot_spread.dart';
import '../../services/daily_share_text_builder.dart';
import '../widgets/card_art_placeholder.dart';
import '../widgets/drawn_card_view.dart';

typedef DailyShareInvoker = Future<void> Function(String text);

Future<void> _defaultShareInvoker(String text) =>
    SharePlus.instance.share(ShareParams(text: text));

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({
    super.key,
    this.spread = TarotSpread.single,
    this.isDaily = false,
    this.intent,
    this.shareInvoker,
  });

  final TarotSpread spread;
  final bool isDaily;

  /// When set (and [isDaily] is false), drives the AppBar title, the
  /// idle description, the per-card body text and the optional footer
  /// below the redraw button. The 3-card spread is always used in this
  /// mode.
  final ReadingIntent? intent;

  /// Injection point used in tests to bypass the native share sheet.
  /// In production the platform implementation is used.
  final DailyShareInvoker? shareInvoker;

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  List<DrawnCard>? _result;
  Object? _error;
  bool _loading = false;
  bool _quotaExhausted = false;

  @override
  void initState() {
    super.initState();
    if (widget.intent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkQuota());
    }
  }

  Future<void> _checkQuota() async {
    final scope = TarotScope.of(context);
    final remaining = await scope.quotaService.remaining(widget.intent!);
    if (remaining == 0 && mounted) {
      setState(() => _quotaExhausted = true);
    }
  }

  TarotSpread get _effectiveSpread {
    if (widget.isDaily) return TarotSpread.single;
    if (widget.intent != null) return TarotSpread.threeCards;
    return widget.spread;
  }

  String get _appBarTitle {
    if (widget.isDaily) return 'Mon message du jour';
    if (widget.intent != null) return widget.intent!.title;
    return widget.spread.label;
  }

  String get _idleDescription {
    if (widget.isDaily) {
      return 'Prends un instant pour toi.\n'
          'Ton message t’attend.';
    }
    if (widget.intent != null) return widget.intent!.intro;
    return widget.spread.description;
  }

  String get _idleCta =>
      widget.isDaily ? 'Révéler mon message' : 'Révéler le tirage';

  String get _idleHint => widget.isDaily
      ? 'À toi d’interpréter.'
      : 'Prends un instant, puis révèle ton tirage.';

  Future<void> _reveal() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final scope = TarotScope.of(context);
      final List<DrawnCard> draw;
      if (widget.isDaily) {
        final daily = await scope.dailyService.getOrCreateToday();
        draw = <DrawnCard>[daily];
      } else {
        if (widget.intent != null) {
          final consumed = await scope.quotaService.tryConsume(widget.intent!);
          if (!consumed) {
            if (!mounted) return;
            setState(() {
              _quotaExhausted = true;
              _loading = false;
            });
            return;
          }
        }
        draw = await scope.drawService.draw(_effectiveSpread);
      }
      if (!mounted) return;
      setState(() {
        _result = draw;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _redraw() {
    setState(() {
      _result = null;
      _error = null;
    });
    _reveal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        leading: widget.intent != null
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return _ErrorState(
        key: const ValueKey('error'),
        message: _error.toString(),
        onRetry: _reveal,
      );
    }
    if (_quotaExhausted && widget.intent != null) {
      return _QuotaExhaustedState(
        key: const ValueKey('quota_exhausted'),
        intent: widget.intent!,
      );
    }
    final result = _result;
    if (result == null) {
      return _IdleState(
        key: const ValueKey('idle'),
        spread: _effectiveSpread,
        description: _idleDescription,
        ctaLabel: _idleCta,
        hint: _idleHint,
        loading: _loading,
        onReveal: _reveal,
        showBackground: widget.isDaily || widget.intent != null,
      );
    }
    return _RevealedState(
      key: const ValueKey('revealed'),
      spread: _effectiveSpread,
      drawn: result,
      isDaily: widget.isDaily,
      intent: widget.intent,
      onRedraw: _redraw,
      shareInvoker: widget.shareInvoker ?? _defaultShareInvoker,
    );
  }
}

class _IdleState extends StatelessWidget {
  const _IdleState({
    super.key,
    required this.spread,
    required this.description,
    required this.ctaLabel,
    required this.hint,
    required this.loading,
    required this.onReveal,
    required this.showBackground,
  });

  final TarotSpread spread;
  final String description;
  final String ctaLabel;
  final String hint;
  final bool loading;
  final VoidCallback onReveal;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isSingle = spread.cardCount == 1;
    final cardWidth = isSingle ? 160.0 : 92.0;
    final showPositions = !isSingle;

    final body = LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 1),
                  _IntroText(description: description),
                  const SizedBox(height: 24),
                  Center(
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: List.generate(spread.cardCount, (i) {
                        final placeholder = CardArtPlaceholder(
                          variant: CardArtVariant.faceDown,
                          width: cardWidth,
                        );
                        if (!showPositions) return placeholder;
                        return SizedBox(
                          width: cardWidth,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              placeholder,
                              const SizedBox(height: 8),
                              Text(
                                spread.positions[i].toUpperCase(),
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
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    hint,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.deepGreen.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                  const Spacer(flex: 1),
                  ElevatedButton.icon(
                    onPressed: loading ? null : onReveal,
                    icon: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.ivory,
                            ),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(loading ? 'Un instant…' : ctaLabel),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (showBackground) {
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
          body,
        ],
      );
    }
    return body;
  }
}

class _IntroText extends StatelessWidget {
  const _IntroText({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lines = description
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final primary = lines.isNotEmpty ? lines.first : description.trim();
    final secondary =
        lines.length > 1 ? lines.skip(1).join(' ') : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          primary,
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.deepGreen,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        if (secondary != null) ...[
          const SizedBox(height: 6),
          Text(
            secondary,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.charcoal,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _RevealedState extends StatelessWidget {
  const _RevealedState({
    super.key,
    required this.spread,
    required this.drawn,
    required this.isDaily,
    required this.intent,
    required this.onRedraw,
    required this.shareInvoker,
  });

  final TarotSpread spread;
  final List<DrawnCard> drawn;
  final bool isDaily;
  final ReadingIntent? intent;
  final VoidCallback onRedraw;
  final DailyShareInvoker shareInvoker;

  @override
  Widget build(BuildContext context) {
    if (spread.cardCount > 1) {
      return _StaggeredReveal(
        index: 0,
        child: _MultiCardPager(
          drawn: drawn,
          spread: spread,
          intent: intent,
          onRedraw: onRedraw,
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final hasRedraw = !isDaily;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      itemCount: drawn.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index < drawn.length) {
          return _StaggeredReveal(
            index: index,
            child: DrawnCardView(
              drawnCard: drawn[index],
              position: null,
              positionIndex: null,
              intent: intent,
              expanded: isDaily,
            ),
          );
        }
        return _StaggeredReveal(
          index: drawn.length,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: hasRedraw
                ? Column(
                    children: [
                      OutlinedButton.icon(
                        onPressed: onRedraw,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Faire un autre tirage'),
                      ),
                      if (intent?.footer != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          intent!.footer!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.subtle,
                            fontStyle: FontStyle.italic,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  )
                : _DailyFooter(
                    drawn: drawn.first,
                    shareInvoker: shareInvoker,
                  ),
          ),
        );
      },
    );
  }
}

class _MultiCardPager extends StatefulWidget {
  const _MultiCardPager({
    required this.drawn,
    required this.spread,
    required this.intent,
    required this.onRedraw,
  });

  final List<DrawnCard> drawn;
  final TarotSpread spread;
  final ReadingIntent? intent;
  final VoidCallback onRedraw;

  @override
  State<_MultiCardPager> createState() => _MultiCardPagerState();
}

class _MultiCardPagerState extends State<_MultiCardPager> {
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;

  void _goTo(int index) {
    if (index < 0 || index >= widget.drawn.length) return;
    setState(() => _currentIndex = index);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final card = widget.drawn[_currentIndex];
    final position = widget.spread.positions[_currentIndex];

    final prevLabel = _currentIndex > 0
        ? widget.spread.positions[_currentIndex - 1]
        : 'Précédente';
    final nextLabel = _currentIndex < widget.drawn.length - 1
        ? widget.spread.positions[_currentIndex + 1]
        : 'Suivante';

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Carte ${_currentIndex + 1} sur ${widget.drawn.length}',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.subtle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  position,
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.deepGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: DrawnCardView(
              key: ValueKey(card.card.id),
              drawnCard: card,
              position: null,
              positionIndex: _currentIndex,
              intent: widget.intent,
              expanded: true,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _goTo(_currentIndex - 1),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.softGold,
                          width: 1.5,
                        ),
                        backgroundColor: AppColors.ivory,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Précédent',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.subtle,
                            ),
                          ),
                          Text(
                            prevLabel,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.deepGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 8),
                if (_currentIndex < widget.drawn.length - 1)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _goTo(_currentIndex + 1),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.softGold,
                          width: 1.5,
                        ),
                        backgroundColor: AppColors.ivory,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Suivant',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.subtle,
                            ),
                          ),
                          Text(
                            nextLabel,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.deepGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const Spacer(),
              ],
            ),
          ),
          if (_currentIndex == widget.drawn.length - 1) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).popUntil(
                  (route) => route.isFirst,
                ),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Revenir à l\'accueil'),
              ),
            ),
          ],
          if (widget.intent?.footer != null) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                widget.intent!.footer!,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.subtle,
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                ),
              ),
            ),
          ],
          if (widget.intent != null) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _QuotaHint(intent: widget.intent!),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuotaHint extends StatelessWidget {
  const _QuotaHint({required this.intent});

  final ReadingIntent intent;

  String get _themeLabel => switch (intent) {
        ReadingIntent.general => 'situation',
        ReadingIntent.love => 'amour',
        ReadingIntent.work => 'travail',
        ReadingIntent.money => 'argent',
      };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<int>(
      future: TarotScope.of(context).quotaService.remaining(intent),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final remaining = snapshot.data!;
        if (remaining == 1) {
          return Text(
            'Il te reste un tirage $_themeLabel aujourd’hui.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.subtle,
              fontStyle: FontStyle.italic,
              fontSize: 11,
            ),
          );
        }
        if (remaining == 0) {
          return Text(
            'Laisse ce message infuser.\n'
            'Tu peux revenir demain pour un nouveau tirage $_themeLabel.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.subtle,
              fontStyle: FontStyle.italic,
              fontSize: 11,
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _DailyFooter extends StatefulWidget {
  const _DailyFooter({
    required this.drawn,
    required this.shareInvoker,
  });

  final DrawnCard drawn;
  final DailyShareInvoker shareInvoker;

  @override
  State<_DailyFooter> createState() => _DailyFooterState();
}

class _DailyFooterState extends State<_DailyFooter> {
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final text = buildDailyShareText(widget.drawn);
      await widget.shareInvoker(text);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le partage n’a pas pu se lancer.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: _sharing ? null : _share,
          icon: _sharing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.deepGreen,
                  ),
                )
              : const Icon(Icons.ios_share),
          label: Text(_sharing ? 'Un instant…' : 'Partager ce message'),
        ),
        const SizedBox(height: 14),
        Text(
          'À toi d’interpréter.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.deepGreen,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Application de divertissement et d’introspection.',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.subtle,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _StaggeredReveal extends StatefulWidget {
  const _StaggeredReveal({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<_StaggeredReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _startTimer = Timer(
      Duration(milliseconds: 110 * widget.index),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}

class _QuotaExhaustedState extends StatelessWidget {
  const _QuotaExhaustedState({super.key, required this.intent});

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

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.subtle),
            const SizedBox(height: 12),
            Text(
              'Impossible de charger le tirage.',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: textTheme.bodySmall?.copyWith(color: AppColors.subtle),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
