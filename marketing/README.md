# Marketing Screenshots

## Daily Message Screenshots (real card artwork)

Generate all 44 screenshots of the "Mon message du jour" screen with the
actual tarot card illustrations (WEBP rendered on the iOS simulator):

```bash
./marketing/run_screenshots.sh
```

**Prerequisites:**
- iOS Simulator booted (e.g. `open -a Simulator`)
- `flutter` and `dart` in your PATH

**What happens:**
1. A small HTTP server starts on `localhost:8765` to receive PNG bytes.
2. The integration test runs on the iOS simulator.
3. Each of the 22 Major Arcana cards is rendered in both upright and reversed
   orientation via the production `ReadingScreen` with `preparedDraw`.
4. Screenshots are captured at the device's native pixel ratio and sent back
   to the host server.
5. Output lands in `marketing/screenshots/daily_message/`.

**Manual run (if you prefer not to use the wrapper):**

```bash
# Terminal 1 — start the receiver
dart marketing/screenshot_server.dart

# Terminal 2 — run the test
flutter test integration_test/marketing_screenshots_test.dart
```

---

## Legacy widget-test approach (placeholder artwork only)

The file `test/marketing_screenshots_test.dart` still works as a fast,
offline widget test, but it renders placeholder gradients instead of real
card artwork because Flutter's test software renderer cannot decode WEBP.
