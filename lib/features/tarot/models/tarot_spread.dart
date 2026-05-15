enum TarotSpread {
  single(
    label: 'Tirage du jour',
    description: 'Une carte pour éclairer la journée.',
    cardCount: 1,
    positions: ['Aujourd’hui'],
  ),
  threeCards(
    label: 'Tirage en trois cartes',
    description: 'Une situation, son énergie, et le conseil qui s’y rattache.',
    cardCount: 3,
    positions: ['Situation', 'Énergie', 'Conseil'],
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
