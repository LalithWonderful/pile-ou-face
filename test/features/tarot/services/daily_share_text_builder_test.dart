import 'package:flutter_test/flutter_test.dart';
import 'package:pile_ou_face/features/tarot/models/drawn_card.dart';
import 'package:pile_ou_face/features/tarot/models/tarot_card.dart';
import 'package:pile_ou_face/features/tarot/services/daily_share_text_builder.dart';

const _sampleShareMessage =
    'J’ai tiré Le Mat — l’envie de tout lâcher et de sauter.';

DrawnCard _drawnSample({String shareMessage = _sampleShareMessage}) {
  final card = TarotCard(
    id: 'le_mat',
    number: 0,
    name: 'Le Mat',
    imagePath: null,
    keywordsUpright: const ['liberté'],
    keywordsReversed: const ['dispersion'],
    meaningUpright: 'Un pas neuf.',
    meaningReversed: 'Dispersion.',
    love: 'Souffle frais.',
    work: 'Idée à oser.',
    advice: 'Avance d’un pas.',
    warning: 'Sois honnête avec toi.',
    shortMessage: 'Un pas neuf.',
    shareMessage: shareMessage,
    tags: const ['commencement'],
  );
  return DrawnCard(card: card, reversed: false);
}

void main() {
  group('buildDailyShareText', () {
    test('embeds the share_message of the drawn card', () {
      final text = buildDailyShareText(_drawnSample());
      expect(text, contains(_sampleShareMessage));
    });

    test('contains the editorial framing lines', () {
      final text = buildDailyShareText(_drawnSample());
      expect(
        text,
        contains('Pile ou Face avait un message pour moi aujourd’hui :'),
      );
      expect(text, contains('Libre à moi de l’interpréter.'),);
    });

    test('keeps the layout: intro + share_message + signoff', () {
      final text = buildDailyShareText(_drawnSample());
      final lines = text.split('\n');
      expect(lines.first,
          'Pile ou Face avait un message pour moi aujourd’hui :');
      expect(lines[1], isEmpty);
      expect(lines[2], _sampleShareMessage);
      expect(lines[3], isEmpty);
      expect(lines.last, 'Libre à moi de l’interpréter.');
    });

    test('does not include voyance-flavoured wording', () {
      final text = buildDailyShareText(_drawnSample()).toLowerCase();
      for (final forbidden in [
        'les cartes disent',
        'ton destin',
        'mauvais présage',
        'voyance',
        'tu vas',
        'c’est certain',
      ]) {
        expect(text.contains(forbidden), isFalse,
            reason: 'share text should not contain "$forbidden"');
      }
    });

    test('trims surrounding whitespace from the share_message', () {
      final text = buildDailyShareText(
        _drawnSample(shareMessage: '  Une phrase à partager.  '),
      );
      expect(text, contains('\n\nUne phrase à partager.\n\n'));
    });
  });
}
