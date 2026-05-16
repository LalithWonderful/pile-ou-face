import '../models/drawn_card.dart';

String buildDailyShareText(DrawnCard drawn) {
  final shareMessage = drawn.card.shareMessage.trim();
  return 'Pile ou Face avait un message pour moi aujourd’hui :\n\n'
      '$shareMessage';
}
