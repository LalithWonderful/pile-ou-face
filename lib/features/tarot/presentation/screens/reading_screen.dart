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
      return 'Pile ou Face a un message pour toi. '
          'Prends un instant, puis révèle-le.';
    }
    if (widget.intent != null) return widget.intent!.intro;
    return widget.spread.description;
  }

  String get _idleCta =>
      widget.isDaily ? 'Révéler mon message' : 'Révéler le tirage';

  String get _idleHint => widget.isDaily
      ? 'Libre à toi de l’interpréter.'
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
      appBar: AppBar(title: Text(_appBarTitle)),
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
  });

  final TarotSpread spread;
  final String description;
  final String ctaLabel;
  final String hint;
  final bool loading;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isSingle = spread.cardCount == 1;
    final cardWidth = isSingle ? 160.0 : 92.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.subtle,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      alignment: WrapAlignment.center,
                      children: List.generate(
                        spread.cardCount,
                        (_) => CardArtPlaceholder(
                          variant: CardArtVariant.faceDown,
                          width: cardWidth,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    hint,
                    textAlign: TextAlign.center,
                    style:
                        textTheme.bodySmall?.copyWith(color: AppColors.subtle),
                  ),
                  const Spacer(),
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
              position: spread.cardCount > 1 ? spread.positions[index] : null,
              intent: intent,
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
          'Libre à toi de l’interpréter.',
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
