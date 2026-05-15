import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../app/tarot_scope.dart';
import '../../models/tarot_card.dart';
import '../widgets/card_art_placeholder.dart';
import 'card_detail_screen.dart';

class CardsLibraryScreen extends StatefulWidget {
  const CardsLibraryScreen({super.key});

  @override
  State<CardsLibraryScreen> createState() => _CardsLibraryScreenState();
}

class _CardsLibraryScreenState extends State<CardsLibraryScreen> {
  late Future<List<TarotCard>> _cardsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cardsFuture = TarotScope.of(context).repository.loadMajorArcana();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bibliothèque des cartes')),
      body: SafeArea(
        child: FutureBuilder<List<TarotCard>>(
          future: _cardsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Impossible de charger les cartes.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.subtle,
                        ),
                  ),
                ),
              );
            }
            final cards = snapshot.data ?? const <TarotCard>[];
            return ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _CardTile(card: cards[i]),
            );
          },
        ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card});

  final TarotCard card;

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CardDetailScreen(card: card),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.softGold.withValues(alpha: 0.3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetail(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CardArtPlaceholder.mini(card: card),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.deepGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card.keywordsUpright.join(' · '),
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.subtle,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.subtle),
            ],
          ),
        ),
      ),
    );
  }
}
