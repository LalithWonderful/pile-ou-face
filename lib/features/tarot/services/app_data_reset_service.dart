import 'package:shared_preferences/shared_preferences.dart';

import 'local_storage_keys.dart';

/// Removes every app-specific key from local SharedPreferences.
///
/// This is intentionally narrow: only the keys listed in [LocalStorageKeys]
/// are deleted. No global `prefs.clear()` is performed, so any system-level
/// or third-party preferences are left untouched.
class AppDataResetService {
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(LocalStorageKeys.dailyReadingDate);
    await prefs.remove(LocalStorageKeys.dailyReadingCardId);
    await prefs.remove(LocalStorageKeys.dailyReadingReversed);
    await prefs.remove(LocalStorageKeys.dailyIntentCounters);
  }
}
