import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';

class AtmosphericBackground extends StatelessWidget {
  final bool isNight;
  final Widget child;

  const AtmosphericBackground({super.key, required this.isNight, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: isNight ? AppGradients.deepNight : AppGradients.goldenDay,
            ),
          ),
        ),
        Positioned.fill(
          child: isNight ? const _StarField() : const _DayGlow(),
        ),
        child,
      ],
    );
  }
}

class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StarPainter());
  }
}

class _StarPainter extends CustomPainter {
  static final List<_Star> _stars = _generateStars();

  static List<_Star> _generateStars() {
    final rng = Random(42);
    return List.generate(65, (i) => _Star(
          x: rng.nextDouble(),
          y: rng.nextDouble(),
          radius: 0.8 + rng.nextDouble() * 2.0,
          opacity: 0.25 + rng.nextDouble() * 0.65,
        ));
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in _stars) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(star.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(star.x * size.width, star.y * size.height), star.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => false;
}

class _Star {
  final double x, y, radius, opacity;
  const _Star({required this.x, required this.y, required this.radius, required this.opacity});
}

class _DayGlow extends StatelessWidget {
  const _DayGlow();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -60,
          right: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.highlight.withOpacity(0.12), Colors.transparent],
                stops: const [0, 1],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
