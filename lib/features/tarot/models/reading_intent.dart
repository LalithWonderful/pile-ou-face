/// User-facing intent driving the 3-card reading on the home screen.
///
/// Each intent carries its own home CTA label, AppBar title and idle
/// intro. The [footer] is optional and is rendered as a small disclaimer
/// below the redraw button after revelation — used only for money to
/// remind the user that the reading is not financial advice.
enum ReadingIntent {
  general(
    homeLabel: 'Une situation',
    title: 'Je me pose une question',
    intro: 'Pense à ta question.\n'
        'Trois cartes pour y voir plus clair.',
    footer: null,
  ),
  love(
    homeLabel: 'L’amour',
    title: 'Question d’amour',
    intro: 'Pense à cette personne, cette relation ou cette envie d’aimer.\n'
        'Trois cartes pour écouter ce que ton cœur sait déjà.',
    footer: null,
  ),
  work(
    homeLabel: 'Le travail',
    title: 'Question de travail',
    intro: 'Pense à ton projet, ton choix ou ta situation professionnelle.\n'
        'Trois cartes pour prendre du recul.',
    footer: null,
  ),
  money(
    homeLabel: 'L’argent',
    title: 'Question d’argent',
    intro: 'Pense à une dépense, un projet ou une question d’argent.\n'
        'Trois cartes pour y voir plus clair.',
    footer: 'Ne remplace pas un conseil financier.',
  );

  const ReadingIntent({
    required this.homeLabel,
    required this.title,
    required this.intro,
    required this.footer,
  });

  final String homeLabel;
  final String title;
  final String intro;
  final String? footer;
}
