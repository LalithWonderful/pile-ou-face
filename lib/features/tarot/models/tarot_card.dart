import 'package:flutter/foundation.dart';

@immutable
class TarotCard {
  const TarotCard({
    required this.id,
    required this.number,
    required this.name,
    required this.keywords,
    required this.uprightMeaning,
    required this.reversedMeaning,
  });

  factory TarotCard.fromJson(Map<String, dynamic> json) {
    return TarotCard(
      id: json['id'] as String,
      number: json['number'] as int,
      name: json['name'] as String,
      keywords: (json['keywords'] as List<dynamic>)
          .map((e) => e as String)
          .toList(growable: false),
      uprightMeaning: json['uprightMeaning'] as String,
      reversedMeaning: json['reversedMeaning'] as String,
    );
  }

  final String id;
  final int number;
  final String name;
  final List<String> keywords;
  final String uprightMeaning;
  final String reversedMeaning;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TarotCard && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
