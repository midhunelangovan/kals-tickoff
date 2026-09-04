import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../app/theme_controller.dart';

class EmptyHabitsState extends ConsumerWidget {
  final VoidCallback onAddHabit;

  const EmptyHabitsState({super.key, required this.onAddHabit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shades = ref.watch(appThemeShadesProvider);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: shades.backgroundTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 38,
                color: shades.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No habits yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Build your daily routine by tracking your first positive habit today.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAddHabit,
              style: ElevatedButton.styleFrom(
                backgroundColor: shades.primary,
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add your first habit'),
            ),
          ],
        ),
      ),
    );
  }
}
