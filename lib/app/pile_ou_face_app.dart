import 'package:flutter/material.dart';

import '../features/tarot/data/tarot_repository.dart';
import '../features/tarot/presentation/screens/home_screen.dart';
import '../features/tarot/services/daily_reading_service.dart';
import '../features/tarot/services/tarot_draw_service.dart';
import 'app_theme.dart';
import 'tarot_scope.dart';

class PileOuFaceApp extends StatefulWidget {
  const PileOuFaceApp({
    super.key,
    this.repository,
    this.drawService,
    this.dailyService,
  });

  final TarotRepository? repository;
  final TarotDrawService? drawService;
  final DailyReadingService? dailyService;

  @override
  State<PileOuFaceApp> createState() => _PileOuFaceAppState();
}

class _PileOuFaceAppState extends State<PileOuFaceApp> {
  late final TarotRepository _repository;
  late final TarotDrawService _drawService;
  late final DailyReadingService _dailyService;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? TarotRepository();
    _drawService =
        widget.drawService ?? TarotDrawService(repository: _repository);
    _dailyService =
        widget.dailyService ?? DailyReadingService(repository: _repository);
  }

  @override
  Widget build(BuildContext context) {
    return TarotScope(
      repository: _repository,
      drawService: _drawService,
      dailyService: _dailyService,
      child: MaterialApp(
        title: 'Pile ou Face',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const HomeScreen(),
      ),
    );
  }
}
