import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    final WidgetStateProperty<Icon?> thumbIcon =
        WidgetStateProperty.resolveWith<Icon?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return const Icon(Icons.nightlight_round, color: Colors.amber);
          }
          return const Icon(Icons.wb_sunny_rounded, color: Colors.orange);
        });

    return Switch(
      value: isDarkMode,
      onChanged: (val) => ref.read(themeProvider.notifier).toggleTheme(val),
      thumbIcon: thumbIcon,
      activeThumbColor: Colors.grey.shade800,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: Colors.blue.shade100,
    );
  }
}
