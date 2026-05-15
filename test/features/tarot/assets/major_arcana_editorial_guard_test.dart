import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const editorialFields = [
    'meaning_upright',
    'meaning_reversed',
    'love',
    'work',
    'money',
    'advice',
    'warning',
    'short_message',
    'share_message',
  ];

  final forbiddenPatterns = <_ForbiddenPattern>[
    const _ForbiddenPattern(r'tu vas', 'tu vas'),
    const _ForbiddenPattern(r'vous allez', 'vous allez'),
    const _ForbiddenPattern(r'cela va arriver', 'cela va arriver'),
    const _ForbiddenPattern(r'ça va arriver', 'ça va arriver'),
    const _ForbiddenPattern(r"c'est certain", "c'est certain"),
    const _ForbiddenPattern(r'ton destin', 'ton destin'),
    const _ForbiddenPattern(r'votre destin', 'votre destin'),
    const _ForbiddenPattern(r'mauvais présage', 'mauvais présage'),
    const _ForbiddenPattern(r'les cartes disent', 'les cartes disent'),
    const _ForbiddenPattern(r'les cartes savent', 'les cartes savent'),
    const _ForbiddenPattern(r'tu dois absolument', 'tu dois absolument'),
    const _ForbiddenPattern(r'il faut absolument', 'il faut absolument'),
    const _ForbiddenPattern(r'\bprédit[es]?\b', 'prédit'),
    const _ForbiddenPattern(r'prédiction certaine', 'prédiction certaine'),
    const _ForbiddenPattern(r'\bvoyance\b', 'voyance'),
  ];

  test(
    'major_arcana.json must not contain forbidden editorial expressions',
    () async {
      final jsonString = await rootBundle.loadString(
        'assets/tarot/major_arcana.json',
      );
      final cards = jsonDecode(jsonString) as List<dynamic>;

      final failures = <String>[];

      for (final card in cards) {
        final cardMap = card as Map<String, dynamic>;
        final cardName = (cardMap['name'] as String?) ??
            (cardMap['id'] as String? ?? 'unknown');

        // Flat editorial fields, plus the nested spread_meanings subkeys
        // (Lot 14 extension). Each entry is "human-readable field
        // name" → "string value".
        final scanTargets = <String, String>{};
        for (final field in editorialFields) {
          final value = cardMap[field];
          if (value is String) scanTargets[field] = value;
        }
        final spread = cardMap['spread_meanings'];
        if (spread is Map<String, dynamic>) {
          for (final entry in spread.entries) {
            final value = entry.value;
            if (value is String) {
              scanTargets['spread_meanings.${entry.key}'] = value;
            }
          }
        }

        for (final target in scanTargets.entries) {
          final value = target.value;
          final normalized = value.toLowerCase().replaceAll('’', "'");

          for (final pattern in forbiddenPatterns) {
            final regex = RegExp(pattern.regex, caseSensitive: false);
            if (regex.hasMatch(normalized)) {
              failures.add(
                '${cardMap['id']} ($cardName) → field "${target.key}"\n'
                '  Forbidden expression: "${pattern.label}"\n'
                '  Text: "$value"',
              );
            }
          }
        }
      }

      if (failures.isNotEmpty) {
        fail(
          'Editorial guard detected ${failures.length} forbidden '
          'expression(s):\n\n${failures.join('\n\n')}',
        );
      }
    },
  );
}

class _ForbiddenPattern {
  final String regex;
  final String label;

  const _ForbiddenPattern(this.regex, this.label);
}
