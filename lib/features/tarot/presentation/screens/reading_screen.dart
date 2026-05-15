import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../app/tarot_scope.dart';
import '../../models/drawn_card.dart';
import '../../models/tarot_spread.dart';
import '../widgets/drawn_card_view.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key, required this.spread});

  final TarotSpread spread;

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  late Future<List<DrawnCard>> _drawFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _drawFuture = TarotScope.of(context).drawService.draw(widget.spread);
  }

  void _redraw() {
    setState(() {
      _drawFuture = TarotScope.of(context).drawService.draw(widget.spread);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.spread.label)),
      body: SafeArea(
        child: FutureBuilder<List<DrawnCard>>(
          future: _drawFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(message: snapshot.error.toString());
            }
            final cards = snapshot.data ?? const <DrawnCard>[];
            return _DrawResult(
              spread: widget.spread,
              drawn: cards,
              onRedraw: _redraw,
            );
          },
        ),
      ),
    );
  }
}

class _DrawResult extends StatelessWidget {
  const _DrawResult({
    required this.spread,
    required this.drawn,
    required this.onRedraw,
  });

  final TarotSpread spread;
  final List<DrawnCard> drawn;
  final VoidCallback onRedraw;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: drawn.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index < drawn.length) {
          return DrawnCardView(
            drawnCard: drawn[index],
            position: spread.positions[index],
          );
        }
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: OutlinedButton.icon(
            onPressed: onRedraw,
            icon: const Icon(Icons.refresh),
            label: const Text('Retirer'),
          ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

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
          ],
        ),
      ),
    );
  }
}
