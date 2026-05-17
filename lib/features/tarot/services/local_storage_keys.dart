/// Centralised keys for all SharedPreferences entries used by the app.
///
/// Keeping keys in one place makes [AppDataResetService] safe and predictable:
/// we only remove keys we know about, never calling `prefs.clear()` globally.
class LocalStorageKeys {
  LocalStorageKeys._();

  static const String dailyReadingDate = 'daily_reading.date';
  static const String dailyReadingCardId = 'daily_reading.card_id';
  static const String dailyReadingReversed = 'daily_reading.reversed';
  static const String dailyIntentCounters = 'quota.daily_intent_counters';
  static const String lastThreeCardReading = 'last_reading.three_card';
}
