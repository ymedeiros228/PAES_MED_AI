import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Anel de acerto animado (0-100), usado nas telas de resultado.
class ScoreRing extends StatelessWidget {
  const ScoreRing({required this.percent, this.size = 140, this.label, super.key});

  final double percent;
  final double size;

  /// Texto pequeno abaixo da porcentagem (ex.: "de acerto").
  final String? label;

  static Color colorFor(double pct) {
    if (pct >= 70) return const Color(0xFF2E9E5B);
    if (pct >= 45) return const Color(0xFFE59B1F);
    return const Color(0xFFD64545);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final target = percent.clamp(0, 100).toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final color = colorFor(v);
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(v / 100, color, cs.surfaceContainerHighest),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${v.round()}%',
                      style: TextStyle(fontSize: size * 0.26, fontWeight: FontWeight.w800, color: color)),
                  if (label != null)
                    Text(label!, style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.65))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction, this.color, this.track);
  final double fraction;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.09;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = color;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * fraction, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.fraction != fraction || old.color != color || old.track != track;
}
