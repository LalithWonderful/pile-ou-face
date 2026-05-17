import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../app/tarot_scope.dart';
import '../../models/reading_intent.dart';
import 'cards_library_screen.dart';
import 'reading_screen.dart';
import 'settings_screen.dart';
import 'three_card_choice_screen.dart';

/// Key on the invisible touch surface that wraps the home logo and hosts
/// the debug-only sustained-press reset gesture. Exposed at file scope so
/// widget tests can target it directly instead of guessing the rendered
/// Image bounds (which are smaller than the touch target on purpose).
@visibleForTesting
const Key homeLogoDebugPressTargetKey = ValueKey('homeLogoDebugPressTarget');

/// Key on the "Revoir mon dernier tirage" CTA. Used by widget tests to
/// assert visibility / tap behaviour without depending on the literal
/// label text.
@visibleForTesting
const Key homeReopenLastReadingKey = ValueKey('homeReopenLastReading');

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Tracks whether a saved 3-card reading exists in local storage.
  /// Re-checked on screen mount AND on return from the choice flow.
  bool _hasLastReading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshLastReading());
  }

  Future<void> _refreshLastReading() async {
    if (!mounted) return;
    final has = await TarotScope.of(context).lastReadingService.hasSavedReading();
    if (!mounted) return;
    if (has != _hasLastReading) {
      setState(() => _hasLastReading = has);
    }
  }

  void _openDailyMessage(BuildContext context) {
    // Daily reading is independent of the 3-card history — no refresh.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ReadingScreen(isDaily: true),
      ),
    );
  }

  Future<void> _openIntent(
      BuildContext context, ReadingIntent intent) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ThreeCardChoiceScreen(intent: intent),
      ),
    );
    // The choice screen pushReplacements ReadingScreen, so this future
    // resolves once the whole flow has popped back to HomeScreen.
    // Re-check storage to surface "Revoir mon dernier tirage" if the
    // user completed (or even accidentally exited) the tirage.
    await _refreshLastReading();
  }

  Future<void> _reopenLastReading() async {
    final scope = TarotScope.of(context);
    final snapshot = await scope.lastReadingService.load();
    if (!mounted || snapshot == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReadingScreen(
          intent: snapshot.intent,
          preparedDraw: snapshot.cards,
        ),
      ),
    );
    // No quota mutation, no storage mutation — nothing to refresh.
  }

  void _openLibrary(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CardsLibraryScreen(),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  Future<void> _resetQuotasForDebug(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final scope = TarotScope.of(context);
    await scope.quotaService.resetDailyQuotaForDebug();
    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Quotas de test réinitialisés.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                'assets/tarot/backgrounds/question_reading_bg.webp',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0.0, constraints.maxHeight - 48),
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () => _openSettings(context),
                            icon: const Icon(Icons.settings_outlined),
                            color: AppColors.deepGreen,
                            tooltip: 'Paramètres',
                          ),
                        ],
                      ),
                      const Spacer(flex: 2),
                      _HomeTitle(
                        onDebugReset: kDebugMode
                            ? () => _resetQuotasForDebug(context)
                            : null,
                        titleStyle: textTheme.displaySmall?.copyWith(
                          color: AppColors.deepGreen,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'C’est le moment de tirer une carte.',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.deepGreen,
                          height: 1.4,
                        ),
                      ),
                      const Spacer(flex: 2),
                      ElevatedButton.icon(
                        onPressed: () => _openDailyMessage(context),
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Découvrir ton message du jour'),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Je me pose une question sur…',
                        textAlign: TextAlign.center,
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.deepGreen.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _IntentButtonsGrid(onTap: (i) => _openIntent(context, i)),
                      if (_hasLastReading) ...[
                        const SizedBox(height: 18),
                        Center(
                          child: TextButton.icon(
                            key: homeReopenLastReadingKey,
                            onPressed: _reopenLastReading,
                            icon: const Icon(
                              Icons.history,
                              size: 16,
                            ),
                            label: const Text('Revoir mon dernier tirage'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.deepGreen
                                  .withValues(alpha: 0.85),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              minimumSize: const Size(0, 32),
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const Spacer(flex: 3),
                      Text(
                        'À toi d’interpréter.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.deepGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Application de divertissement et d’introspection.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.subtle,
                          fontSize: 11,
                        ),
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 6),
                        Center(
                          child: TextButton(
                            onPressed: () => _openLibrary(context),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  AppColors.subtle.withValues(alpha: 0.85),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              minimumSize: const Size(0, 28),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            child: const Text('Voir les cartes'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      ],
    ),
    );
  }
}

class _HomeTitle extends StatefulWidget {
  const _HomeTitle({
    required this.titleStyle,
    required this.onDebugReset,
  });

  /// Number of taps required on the logo (within [tapWindow]) to fire
  /// the hidden debug reset.
  static const int debugTapsRequired = 5;

  /// Sliding window that the user must complete the tap sequence in.
  /// A pause longer than this resets the counter, so a single stray tap
  /// will not accumulate over a real session.
  static const Duration tapWindow = Duration(seconds: 3);

  /// Pixel height of the rendered home logo. Sits inline with the title
  /// at displaySmall size, so a value in the 34–36 range looks balanced.
  static const double logoSize = 36;

  /// Horizontal gap between the logo and the title text.
  static const double logoTitleGap = 6;

  final TextStyle? titleStyle;

  /// Fired when the user has tapped the logo [debugTapsRequired] times
  /// inside [tapWindow]. `null` (and therefore the gesture surface) in
  /// release builds. The title text never participates in this gesture.
  final VoidCallback? onDebugReset;

  @override
  State<_HomeTitle> createState() => _HomeTitleState();
}

class _HomeTitleState extends State<_HomeTitle> {
  int _tapCount = 0;
  Timer? _windowTimer;

  void _handleLogoTap() {
    final callback = widget.onDebugReset;
    if (callback == null) return;
    _windowTimer?.cancel();
    _tapCount++;
    if (_tapCount >= _HomeTitle.debugTapsRequired) {
      _tapCount = 0;
      _windowTimer = null;
      callback();
      return;
    }
    _windowTimer = Timer(_HomeTitle.tapWindow, () {
      _tapCount = 0;
      _windowTimer = null;
    });
  }

  @override
  void dispose() {
    _windowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // NOTE on the asset: pile_ou_face_logo.png is currently a PNG without
    // an alpha channel, so a textured beige square is visible behind the
    // mark on this screen. The fix is an asset replacement (re-export the
    // logo with a transparent background) — NOT a Container colour or
    // any other Flutter-side overlay, which would tint the logo edges or
    // mask part of the design.
    final logoImage = Image.asset(
      'assets/tarot/branding/pile_ou_face_logo.png',
      height: _HomeTitle.logoSize,
      width: _HomeTitle.logoSize,
      fit: BoxFit.contain,
    );

    // The tap target is the visible logo itself — no invisible padding
    // around it, so the Row's visual gap to the title is exactly
    // [_HomeTitle.logoTitleGap] without a hidden buffer inflating it.
    Widget touchSurface = SizedBox(
      key: homeLogoDebugPressTargetKey,
      width: _HomeTitle.logoSize,
      height: _HomeTitle.logoSize,
      child: logoImage,
    );

    if (widget.onDebugReset != null) {
      // Tap-based reset (5 taps inside a 3-second window) is far more
      // reliable on iOS simulator than a sustained press, which the
      // ancestor Scrollable could cancel on the slightest finger jitter.
      // The gesture surface is only installed in debug builds, so a
      // release build has no debug behaviour on the logo whatsoever.
      touchSurface = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleLogoTap,
        child: touchSurface,
      );
    }

    // FittedBox.scaleDown keeps the inline header at full size on regular
    // iPhones and gracefully shrinks the whole logo+title row on narrow
    // viewports (e.g. 320 px) instead of overflowing.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          touchSurface,
          const SizedBox(width: _HomeTitle.logoTitleGap),
          Text(
            'Pile ou Face',
            textAlign: TextAlign.center,
            style: widget.titleStyle,
          ),
        ],
      ),
    );
  }
}

class _IntentButtonsGrid extends StatelessWidget {
  const _IntentButtonsGrid({required this.onTap});

  final void Function(ReadingIntent) onTap;

  ButtonStyle _compactStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _button(BuildContext context, ReadingIntent intent) {
    return OutlinedButton(
      style: _compactStyle(context),
      onPressed: () => onTap(intent),
      child: Text(intent.homeLabel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _button(context, ReadingIntent.general)),
            const SizedBox(width: 10),
            Expanded(child: _button(context, ReadingIntent.love)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _button(context, ReadingIntent.work)),
            const SizedBox(width: 10),
            Expanded(child: _button(context, ReadingIntent.money)),
          ],
        ),
      ],
    );
  }
}
