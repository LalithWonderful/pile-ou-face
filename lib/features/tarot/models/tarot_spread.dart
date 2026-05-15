enum TarotSpread {
  single(
    label: 'Tirage du jour',
    description: 'Une carte pour éclairer la journée.',
    cardCount: 1,
    positions: ['Aujourd’hui'],
  ),
  threeCards(
    label: 'Tirage en trois cartes',
    description: 'Passé, présent, futur.',
    cardCount: 3,
    positions: ['Passé', 'Présent', 'Futur'],
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
