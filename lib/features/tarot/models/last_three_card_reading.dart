import 'package:flutter/foundation.dart';

import 'drawn_card.dart';
import 'reading_intent.dart';

/// In-memory snapshot of the most recent 3-card reading the user
/// completed. Persistence lives in `LastReadingService`; this model is
/// what consumers (HomeScreen, ReadingScreen) read after a successful
/// `load()`.
@immutable
class LastThreeCardReading {
  const LastThreeCardReading({
    required this.intent,
    required this.cards,
    required this.createdAt,
  });

  final ReadingIntent intent;

  /// The three drawn cards in the original selection order — card 0 is
  /// "Là où tu en es", card 1 "L'énergie du moment", card 2 "Le
  /// conseil". `cards.length` is always 3 for snapshots returned by
  /// `LastReadingService.load`.
  final List<DrawnCard> cards;

  final DateTime createdAt;
}
