import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';

/// Card de modo de simulado (dia da prova, PAES, revisão, disciplina).
class SimulationModeCard extends StatelessWidget {
  const SimulationModeCard({
    super.key,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TapScale(
        child: GestureDetector(
          onTap: onTap,
          child: SurfacePanel(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            color: selected ? cs.primaryContainer.f55 : cs.surface.withOpacity(0.9),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kRadiusPanel),
                border: Border.all(
                  color: selected ? cs.primary : cs.outlineVariant.f85,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: selected ? cs.primary : cs.onSurface.withOpacity(0.7)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: selected ? cs.onPrimaryContainer : cs.onSurface,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: selected
                                ? cs.onPrimaryContainer.withOpacity(0.85)
                                : cs.onSurface.f72,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle_rounded, color: cs.primary, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cronômetro circular do simulado do dia.
class SimulationCircularTimer extends StatelessWidget {
  const SimulationCircularTimer({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
  });

  final int remainingSeconds;
  final int totalSeconds;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress =
        totalSeconds > 0 ? (remainingSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;
    final mins = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (remainingSeconds % 60).toString().padLeft(2, '0');
    final progressColor = progress > 0.5
        ? cs.primary
        : progress > 0.25
            ? Colors.amber
            : cs.error;
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(120, 120),
            painter: _SimulationTimerPainter(
              progress: progress,
              trackColor: cs.surfaceContainerHighest,
              progressColor: progressColor,
            ),
          ),
          Text(
            '$mins:$secs',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimulationTimerPainter extends CustomPainter {
  const _SimulationTimerPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    const strokeWidth = 8.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_SimulationTimerPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor;
}
