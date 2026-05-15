import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/tarot_card.dart';

typedef AssetStringLoader = Future<String> Function(String key);

class TarotRepository {
  TarotRepository({
    AssetStringLoader? loader,
    this.assetKey = 'assets/tarot/major_arcana.json',
  }) : _loader = loader ?? rootBundle.loadString;

  final AssetStringLoader _loader;
  final String assetKey;

  List<TarotCard>? _cache;

  Future<List<TarotCard>> loadMajorArcana() async {
    final cached = _cache;
    if (cached != null) {
      return cached;
    }
    final raw = await _loader(assetKey);
    final decoded = jsonDecode(raw) as List<dynamic>;
    final cards = decoded
        .map((e) => TarotCard.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    _cache = cards;
    return cards;
  }

  void clearCache() => _cache = null;
}
