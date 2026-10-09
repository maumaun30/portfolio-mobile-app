import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme_controller.dart';
import '../theme/tokens.dart';

/// Round sun/moon button — same affordance as the web nav's ThemeToggle.
/// Moon in light mode (switch to dark), sun in dark mode (switch to light).
class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeControllerProvider) == Brightness.dark;
    return Tooltip(
      message: 'Toggle theme',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => ref.read(themeControllerProvider.notifier).toggle(),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTokens.line),
          ),
          alignment: Alignment.center,
          child: Icon(
            isDark ? LucideIcons.sun : LucideIcons.moon,
            size: 14,
            color: AppTokens.inkDim,
          ),
        ),
      ),
    );
  }
}
