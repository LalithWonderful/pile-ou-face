import 'package:flutter/widgets.dart';

import '../features/tarot/data/tarot_repository.dart';
import '../features/tarot/services/daily_quota_service.dart';
import '../features/tarot/services/daily_reading_service.dart';
import '../features/tarot/services/tarot_draw_service.dart';

class TarotScope extends InheritedWidget {
  const TarotScope({
    super.key,
    required this.repository,
    required this.drawService,
    required this.dailyService,
    required this.quotaService,
    required super.child,
  });

  final TarotRepository repository;
  final TarotDrawService drawService;
  final DailyReadingService dailyService;
  final DailyQuotaService quotaService;

  static TarotScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TarotScope>();
    assert(scope != null, 'TarotScope not found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(TarotScope oldWidget) =>
      repository != oldWidget.repository ||
      drawService != oldWidget.drawService ||
      dailyService != oldWidget.dailyService ||
      quotaService != oldWidget.quotaService;
}
