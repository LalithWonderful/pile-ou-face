import 'dart:math';

import '../data/tarot_repository.dart';
import '../models/drawn_card.dart';
import '../models/tarot_card.dart';
import '../models/tarot_spread.dart';

class TarotDrawService {
  TarotDrawService({required this.repository, Random? random})
      : _random = random ?? Random();

  final TarotRepository repository;
  final Random _random;

  Future<List<DrawnCard>> draw(TarotSpread spread) async {
    final cards = await repository.loadMajorArcana();
    if (spread.cardCount > cards.length) {
      throw StateError(
        'Not enough cards in deck (${cards.length}) for ${spread.cardCount}.',
      );
    }
    final pool = List<TarotCard>.of(cards)..shuffle(_random);
    return List<DrawnCard>.generate(
      spread.cardCount,
      (i) => DrawnCard(card: pool[i], reversed: _random.nextBool()),
      growable: false,
    );
  }
}
