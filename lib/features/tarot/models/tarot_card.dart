import 'package:flutter/foundation.dart';

import 'tarot_spread_meanings.dart';

@immutable
class TarotCard {
  const TarotCard({
    required this.id,
    required this.number,
    required this.name,
    required this.imagePath,
    required this.keywordsUpright,
    required this.keywordsReversed,
    required this.meaningUpright,
    required this.meaningReversed,
    required this.love,
    required this.work,
    required this.money,
    required this.advice,
    required this.warning,
    required this.shortMessage,
    required this.shareMessage,
    required this.tags,
    this.spreadMeanings,
  });

  factory TarotCard.fromJson(Map<String, dynamic> json) {
    List<String> readStringList(String key) =>
        (json[key] as List<dynamic>? ?? const <dynamic>[])
            .map((e) => e as String)
            .toList(growable: false);

    final spread = json['spread_meanings'];

    return TarotCard(
      id: json['id'] as String,
      number: json['number'] as int,
      name: json['name'] as String,
      imagePath: json['image_path'] as String?,
      keywordsUpright: readStringList('keywords_upright'),
      keywordsReversed: readStringList('keywords_reversed'),
      meaningUpright: json['meaning_upright'] as String,
      meaningReversed: json['meaning_reversed'] as String,
      love: json['love'] as String,
      work: json['work'] as String,
      money: json['money'] as String,
      advice: json['advice'] as String,
      warning: json['warning'] as String,
      shortMessage: json['short_message'] as String,
      shareMessage: json['share_message'] as String,
      tags: readStringList('tags'),
      spreadMeanings: spread is Map<String, dynamic>
          ? TarotSpreadMeanings.fromJson(spread)
          : null,
    );
  }

  final String id;
  final int number;
  final String name;
  final String? imagePath;
  final List<String> keywordsUpright;
  final List<String> keywordsReversed;
  final String meaningUpright;
  final String meaningReversed;
  final String love;
  final String work;
  final String money;
  final String advice;
  final String warning;
  final String shortMessage;
  final String shareMessage;
  final List<String> tags;

  /// Optional 3-card position-specific reading. Only present on cards
  /// that have been editorially validated; rendering code must fall
  /// back when null.
  final TarotSpreadMeanings? spreadMeanings;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TarotCard && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
