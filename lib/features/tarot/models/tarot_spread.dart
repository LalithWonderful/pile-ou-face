enum TarotSpread {
  single(
    label: 'Tirage du jour',
    description: 'Une carte pour éclairer la journée.',
    cardCount: 1,
    positions: ['Aujourd’hui'],
  ),
  threeCards(
    label: 'Éclairer une situation',
    description:
        'Pense à une situation. Pile ou Face t’aide à la regarder sous '
        'trois angles : là où tu en es, l’énergie du moment, et le '
        'conseil à garder.',
    cardCount: 3,
    positions: ['Là où tu en es', 'L’énergie du moment', 'Le conseil'],
  );

  const TarotSpread({
    required this.label,
    required this.description,
    required this.cardCount,
    required this.positions,
  });

  final String label;
  final String description;
  final int cardCount;
  final List<String> positions;
}
