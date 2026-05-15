import 'package:flutter/foundation.dart';

import 'tarot_card.dart';

@immutable
class DrawnCard {
  const DrawnCard({required this.card, required this.reversed});

  final TarotCard card;
  final bool reversed;

  String get meaning => reversed ? card.meaningReversed : card.meaningUpright;

  List<String> get keywords =>
      reversed ? card.keywordsReversed : card.keywordsUpright;

  String get orientationLabel => reversed ? 'Sens inversé' : 'Sens droit';

  String get advice => card.advice;
}
