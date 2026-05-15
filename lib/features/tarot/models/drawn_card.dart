import 'package:flutter/foundation.dart';

import 'tarot_card.dart';

@immutable
class DrawnCard {
  const DrawnCard({required this.card, required this.reversed});

  final TarotCard card;
  final bool reversed;

  String get meaning => reversed ? card.reversedMeaning : card.uprightMeaning;

  String get orientationLabel => reversed ? 'Sens inversé' : 'Sens droit';
}
