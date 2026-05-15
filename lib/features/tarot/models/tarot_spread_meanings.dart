import 'package:flutter/foundation.dart';

/// Position-specific reading text for a card placed in the three-card
/// "Là où tu en es / L'énergie du moment / Le conseil" spread.
///
/// Optional on every [TarotCard]: editorial validation happens card by
/// card, so only the cards already validated carry a non-null
/// [TarotSpreadMeanings]. For the others, the rendering code falls back
/// to the existing body text (meaning or domain).
@immutable
class TarotSpreadMeanings {
  const TarotSpreadMeanings({
    required this.whereYouAre,
    required this.currentEnergy,
    required this.advice,
  });

  factory TarotSpreadMeanings.fromJson(Map<String, dynamic> json) {
    return TarotSpreadMeanings(
      whereYouAre: json['where_you_are'] as String,
      currentEnergy: json['current_energy'] as String,
      advice: json['advice'] as String,
    );
  }

  final String whereYouAre;
  final String currentEnergy;
  final String advice;
}
