import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/backend/backend_startup.dart';
import '../features/habits/presentation/habit_list_screen.dart';
import 'theme.dart';
import 'theme_controller.dart';

final backendReadyProvider = FutureProvider<bool>((ref) async {
  return BackendStartup.waitForReady();
});

class HabitTrackerApp extends ConsumerWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColor = ref.watch(appThemeColorProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final backendReady = ref.watch(backendReadyProvider);

    return MaterialApp(
      title: 'Kals TickOff',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: buildCustomTheme(themeColor, isDark: false),
      darkTheme: buildCustomTheme(themeColor, isDark: true),
      home: backendReady.when(
        data: (isReady) {
          if (isReady) {
            return const HabitListScreen();
          }
          return _StartupErrorView(onRetry: () {
            ref.invalidate(backendReadyProvider);
          });
        },
        loading: () => _StartupLoadingView(themeColor: themeColor),
        error: (_, __) => _StartupErrorView(onRetry: () {
          ref.invalidate(backendReadyProvider);
        }),
      ),
    );
  }
}

class _StartupLoadingView extends StatelessWidget {
  final Color themeColor;

  const _StartupLoadingView({required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Icon(
                  Icons.bolt_rounded,
                  size: 44,
                  color: themeColor,
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Starting local services...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartupErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _StartupErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 44,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Unable to start Kals TickOff local services.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please check device permissions or retry starting the local engine.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
