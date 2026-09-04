import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CompletionCelebrationState {
  final String habitId;
  final String habitName;
  final Color habitColor;
  final int triggerKey;

  const CompletionCelebrationState({
    required this.habitId,
    required this.habitName,
    required this.habitColor,
    required this.triggerKey,
  });
}

class CompletionCelebrationNotifier
    extends Notifier<CompletionCelebrationState?> {
  @override
  CompletionCelebrationState? build() => null;

  void trigger(CompletionCelebrationState celebration) {
    state = celebration;
  }

  void clear() {
    state = null;
  }
}

final completionCelebrationProvider = NotifierProvider<
    CompletionCelebrationNotifier, CompletionCelebrationState?>(
  CompletionCelebrationNotifier.new,
);

class CompletionCelebrationOverlay extends ConsumerStatefulWidget {
  const CompletionCelebrationOverlay({super.key});

  @override
  ConsumerState<CompletionCelebrationOverlay> createState() =>
      _CompletionCelebrationOverlayState();
}

class _CompletionCelebrationOverlayState
    extends ConsumerState<CompletionCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _scaleAnim;

  CompletionCelebrationState? _activeState;
  int _lastHandledKey = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    // 0.0 - 0.20 (0 - 190ms): Entrance slide & fade in
    // 0.20 - 0.75 (190 - 710ms): Hold / settle
    // 0.75 - 1.0 (710 - 950ms): Smooth fade & slide out
    _fadeAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_controller);

    _slideAnim = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0.0, 0.45), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: ConstantTween(Offset.zero),
        weight: 53,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0.0, 0.3))
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 25,
      ),
    ]).animate(_controller);

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.85, end: 1.02).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.02, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 38,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.9).chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _activeState = null;
        });
        ref.read(completionCelebrationProvider.notifier).clear();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerCelebration(CompletionCelebrationState state) {
    setState(() {
      _activeState = state;
      _lastHandledKey = state.triggerKey;
    });
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final celebrationState = ref.watch(completionCelebrationProvider);

    if (celebrationState != null && celebrationState.triggerKey != _lastHandledKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _triggerCelebration(celebrationState);
        }
      });
    }

    if (_activeState == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habitColor = _activeState!.habitColor;
    final habitName = _activeState!.habitName;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.value <= 0.0 || _controller.value >= 1.0) {
          return const SizedBox.shrink();
        }

        return Opacity(
          opacity: _fadeAnim.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: _slideAnim.value * 50.0,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.96)
              : Colors.white.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: habitColor.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: habitColor.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left celebratory sparkling tick badge
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Sparkle burst behind badge
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      size: const Size(40, 40),
                      painter: _MiniSparklePainter(
                        progress: _controller.value,
                        color: habitColor,
                      ),
                    );
                  },
                ),
                // Badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: habitColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Message text
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Completed!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: habitColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text('✨', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    habitName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _MiniSparklePainter extends CustomPainter {
  final double progress;
  final Color color;

  _MiniSparklePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress > 0.85) return;
    final center = Offset(size.width / 2, size.height / 2);
    final gold = const Color(0xFFFBBF24);

    // Radiate 6 micro-sparkles
    final ease = Curves.easeOutCubic.transform((progress * 1.5).clamp(0.0, 1.0));
    final opacity = (1.0 - (progress * 1.3)).clamp(0.0, 1.0);

    for (int i = 0; i < 6; i++) {
      final angle = i * (math.pi / 3) + 0.2;
      final dist = 16.0 + (ease * 16.0);
      final px = center.dx + math.cos(angle) * dist;
      final py = center.dy + math.sin(angle) * dist;

      final paint = Paint()
        ..color = (i % 2 == 0 ? gold : color).withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(px, py), 2.0 * (1.0 - ease * 0.4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniSparklePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
