import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Overlay de confete simples — mostra particulas coloridas caindo.
/// Uso: ConfettiOverlay.show(context); // mostra por 2 segundos
class ConfettiOverlay {
  static OverlayEntry? _entry;

  static void show(BuildContext context, {Duration duration = const Duration(seconds: 2)}) {
    if (_entry != null) return;
    _entry = OverlayEntry(
      builder: (ctx) => _ConfettiWidget(duration: duration),
    );
    Overlay.of(context).insert(_entry!);
    Timer(duration + const Duration(milliseconds: 500), () {
      _entry?.remove();
      _entry = null;
    });
  }
}

class _ConfettiWidget extends StatefulWidget {
  const _ConfettiWidget({required this.duration});
  final Duration duration;

  @override
  State<_ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<_ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _particles = List.generate(40, (_) => _Particle(_rng));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (ctx, _) {
          return CustomPaint(
            size: size,
            painter: _ConfettiPainter(_particles, _ctrl.value),
          );
        },
      ),
    );
  }
}

class _Particle {
  _Particle(this.rng) {
    x = rng.nextDouble();
    startY = -0.1 - rng.nextDouble() * 0.3;
    speed = 0.8 + rng.nextDouble() * 0.6;
    size = 4 + rng.nextDouble() * 6;
    color = colors[rng.nextInt(colors.length)];
    rotation = rng.nextDouble() * math.pi * 2;
    rotSpeed = (rng.nextDouble() - 0.5) * 4;
    drift = (rng.nextDouble() - 0.5) * 0.3;
  }
  final math.Random rng;
  late double x;
  late double startY;
  late double speed;
  late double size;
  late Color color;
  late double rotation;
  late double rotSpeed;
  late double drift;

  static const colors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFE8A04B),
  ];
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.progress);
  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.startY + p.speed * progress) * size.height;
      final x = (p.x + p.drift * progress) * size.width;
      final rot = p.rotation + p.rotSpeed * progress;

      final opacity = progress < 0.8 ? 1.0 : (1.0 - (progress - 0.8) / 0.2);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      canvas.scale(1.0, 0.5);

      final paint = Paint()..color = p.color.withOpacity(opacity);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
