import 'dart:math';

import 'package:flutter/material.dart';

class KickingSunAnimation extends CustomPainter {
  final double baseSize;
  final double soundLevel;
  final double time;

  KickingSunAnimation({
    required this.baseSize,
    required this.soundLevel,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = baseSize / 2;

    // Gradient for the sun
    final gradient = LinearGradient(
      colors: [
        Color(0xFFFFD700).withOpacity(0.8),
        Color(0xFFFFE5B4).withOpacity(0.7),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final shader = gradient.createShader(
      Rect.fromCircle(center: center, radius: radius),
    );

    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Color(0xFFFFE5B4).withOpacity(0.8)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 50.0);

    // Draw shadow
    canvas.drawCircle(center, radius + 10, shadowPaint);

    // Path for the sun with kicking effect
    final path = Path();
    const segments = 100;
    final kickStrength = soundLevel * 20.0;
    final kickAngle = time * 2 * pi;

    for (int i = 0; i <= segments; i++) {
      final angle = (i / segments) * 2 * pi;
      final baseRadius = radius;

      // Calculate distance to the kick point
      final distanceToKick = (angle - kickAngle).abs();
      final normalizedDistance =
          distanceToKick > pi ? 2 * pi - distanceToKick : distanceToKick;
      final kickEffect = kickStrength * exp(-pow(normalizedDistance, 2) / 0.5);

      final adjustedRadius = baseRadius + kickEffect;

      final x = center.dx + adjustedRadius * cos(angle);
      final y = center.dy + adjustedRadius * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(KickingSunAnimation oldDelegate) {
    return oldDelegate.baseSize != baseSize ||
        oldDelegate.soundLevel != soundLevel ||
        oldDelegate.time != time;
  }
}
