import 'package:shared_preferences/shared_preferences.dart';

import 'local_storage_keys.dart';

/// Removes app-specific keys from local SharedPreferences.
///
/// This is intentionally narrow: only the keys listed in [LocalStorageKeys]
/// are considered. No global `prefs.clear()` is performed, so any system-level
/// or third-party preferences are left untouched.
///
/// IMPORTANT — daily quota preservation: the per-intent quota key
/// ([LocalStorageKeys.dailyIntentCounters]) is intentionally preserved by
/// [clearAll] so users cannot bypass the 2-per-intent daily limit by tapping
/// "Effacer mes données". Manual debug resets go through
/// `DailyQuotaService.resetDailyQuotaForDebug` (kDebugMode only).
class AppDataResetService {
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(LocalStorageKeys.dailyReadingDate);
    await prefs.remove(LocalStorageKeys.dailyReadingCardId);
    await prefs.remove(LocalStorageKeys.dailyReadingReversed);
    // dailyIntentCounters is deliberately NOT removed here: clearing it
    // would let users reset their 2-per-intent daily quota at will.
  }
}
