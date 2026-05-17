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

/// Key on the invisible touch surface that wraps the home logo and hosts
/// the debug-only sustained-press reset gesture. Exposed at file scope so
/// widget tests can target it directly instead of guessing the rendered
/// Image bounds (which can be smaller than the touch target on purpose).
@visibleForTesting
const Key homeLogoTouchTargetKey = ValueKey('home-logo-touch-target');

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openDailyMessage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ReadingScreen(isDaily: true),
      ),
    );
  }

  void _openIntent(BuildContext context, ReadingIntent intent) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReadingScreen(intent: intent),
      ),
    );
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
                        onDebugSustainedPress: kDebugMode
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
    required this.onDebugSustainedPress,
  });

  /// How long the user must keep their finger down on the logo to trigger
  /// the hidden debug reset. Kept long enough that an accidental tap or a
  /// regular long-press cannot fire it.
  static const Duration debugHoldDuration = Duration(seconds: 5);

  /// Pixel height of the rendered home logo. Tuned so the screen stays
  /// balanced on large iPhones while remaining usable on a 320x568 viewport.
  static const double logoSize = 56;

  /// Edge of the invisible square touch target that hosts the debug
  /// sustained-press gesture. Larger than [logoSize] so a small finger
  /// jitter while holding never falls outside the Listener.
  static const double debugTouchTargetSize = 96;

  final TextStyle? titleStyle;

  /// Fired when the user keeps a single pointer pressed on the logo for
  /// [debugHoldDuration]. `null` (and therefore the gesture surface) in
  /// release builds. The title text never participates in this gesture.
  final VoidCallback? onDebugSustainedPress;

  @override
  State<_HomeTitle> createState() => _HomeTitleState();
}

class _HomeTitleState extends State<_HomeTitle> {
  Timer? _holdTimer;

  void _onPointerDown(PointerDownEvent _) {
    final callback = widget.onDebugSustainedPress;
    if (callback == null) return;
    _holdTimer?.cancel();
    _holdTimer = Timer(_HomeTitle.debugHoldDuration, () {
      _holdTimer = null;
      callback();
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  @override
  void dispose() {
    _cancelHold();
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

    // The rendered logo stays small (56 px) for visual balance, but the
    // touch target is enlarged so a finger that drifts a few pixels
    // during the 5-second hold stays inside the Listener.
    Widget touchSurface = SizedBox(
      key: homeLogoTouchTargetKey,
      width: _HomeTitle.debugTouchTargetSize,
      height: _HomeTitle.debugTouchTargetSize,
      child: Center(child: logoImage),
    );

    if (widget.onDebugSustainedPress != null) {
      // The debug gesture lives on the logo touch target only, never on
      // the title text. HitTestBehavior.opaque ensures the full 96x96
      // square absorbs pointer events, including the padded margin
      // around the visible 56 px logo.
      touchSurface = Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onPointerDown,
        onPointerUp: (_) => _cancelHold(),
        onPointerCancel: (_) => _cancelHold(),
        child: touchSurface,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        touchSurface,
        const SizedBox(height: 8),
        Text(
          'Pile ou Face',
          textAlign: TextAlign.center,
          style: widget.titleStyle,
        ),
      ],
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
