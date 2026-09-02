import 'package:flutter/material.dart';

class ConfettiBurst {
  ConfettiBurst._();

  static OverlayEntry? _entry;

  /// Dispara confete por [duration] (default 2.5s).
  static void fire(
    BuildContext context, {
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    _entry?.remove();
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (ctx) => _ConfettiOverlay(duration: duration),
    );
    _entry = entry;
    overlay.insert(entry);
  }
}

class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay({required this.duration});
  final Duration duration;

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward().then((_) {
        if (mounted) {
          ConfettiBurst._entry?.remove();
          ConfettiBurst._entry = null;
        }
      });
    // Gera 40 partículas com cores e posições aleatórias
    final colors = [
      const Color(0xFFFFD700), // dourado
      const Color(0xFF4FC3F7), // azul
      const Color(0xFF80CBC4), // verde-agua
      const Color(0xFFB39DDB), // lilas
      const Color(0xFFFF8A65), // laranja
      const Color(0xFFFFFFFF), // branco
    ];
    final rng = DateTime.now().microsecond;
    _particles = List.generate(40, (i) {
      return _ConfettiParticle(
        x: 0.1 + (i * 0.02 + (rng % 100) / 100 * 0.8) % 0.8,
        startY: -0.1 - (i % 5) * 0.05,
        endY: 0.8 + (i % 3) * 0.1,
        drift: ((i * 7 + rng) % 100 - 50) / 200.0,
        color: colors[i % colors.length],
        size: 4.0 + (i % 4) * 2.0,
        rotation: (i * 37) % 360,
        rotationSpeed: (i % 2 == 0 ? 1 : -1) * (90.0 + i * 10),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _ConfettiPainter(
                particles: _particles,
                progress: _controller.value,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  _ConfettiParticle({
    required this.x,
    required this.startY,
    required this.endY,
    required this.drift,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });

  final double x; // 0..1 (posicao horizontal relativa)
  final double startY; // 0..1 (posicao vertical inicial)
  final double endY; // 0..1 (posicao vertical final)
  final double drift; // desvio horizontal
  final Color color;
  final double size;
  final double rotation; // graus
  final double rotationSpeed; // graus por segundo
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.progress});
  final List<_ConfettiParticle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Posicao vertical: cai de startY para endY
      final y = (p.startY + (p.endY - p.startY) * progress) * size.height;
      // Drift horizontal: seno para dar efeito de balanco
      final driftX = p.drift * size.width * progress * (1 - progress * 0.3);
      final x = p.x * size.width + driftX;
      // Fade out nos ultimos 30%
      final alpha = progress < 0.7 ? 1.0 : (1.0 - (progress - 0.7) / 0.3);
      // Rotacao
      final angle = (p.rotation + p.rotationSpeed * progress) * 3.14159 / 180;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);

      final paint = Paint()
        ..color = p.color.withOpacity(alpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      // Retangulo colorido (confete classico)
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

/// Cartão com efeito de virar 3D (rotação no eixo Y).
/// Mostra [front] quando não virado e [back] quando virado.
/// Animação suave com perspective transform — mais realista que fade.
class FlipCard3D extends StatefulWidget {
  const FlipCard3D({
    required this.front,
    required this.back,
    required this.flipped,
    super.key,
  });

  final Widget front;
  final Widget back;
  final bool flipped;

  @override
  State<FlipCard3D> createState() => _FlipCard3DState();
}

class _FlipCard3DState extends State<FlipCard3D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _flipAnim;
  late final Animation<double> _frontScale;
  late final Animation<double> _backScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _flipAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    // Escala para simular profundidade 3D
    _frontScale = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _backScale = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
    if (widget.flipped) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(FlipCard3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flipped != widget.flipped) {
      if (widget.flipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final angle = _flipAnim.value * 3.14159; // 0 a pi
        // Determina qual face mostrar baseado no angulo
        final showFront = angle < 1.5708; // < pi/2
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateY(angle),
          child: showFront
              ? Transform.scale(
                  scale: _frontScale.value,
                  child: widget.front,
                )
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(3.14159),
                  child: Transform.scale(
                    scale: _backScale.value,
                    child: widget.back,
                  ),
                ),
        );
      },
    );
  }
}

class PulseButton extends StatefulWidget {
  const PulseButton({
    required this.onPressed,
    required this.child,
    this.pulse = true,
    super.key,
  });

  final VoidCallback onPressed;
  final Widget child;
  final bool pulse;

  @override
  State<PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<PulseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scale = Tween(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.pulse) {
      return FilledButton(onPressed: widget.onPressed, child: widget.child);
    }
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: child,
        );
      },
      child: FilledButton(onPressed: widget.onPressed, child: widget.child),
    );
  }
}

class AchievementToast {
  AchievementToast._();

  static OverlayEntry? _current;

  /// Exibe uma conquista por [duration] (default 4s).
  static void show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    Color color = const Color(0xFFFFD700),
    Duration duration = const Duration(seconds: 4),
  }) {
    _current?.remove();
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (ctx) => _AchievementOverlay(
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
        duration: duration,
        onDismiss: () {
          _current?.remove();
          _current = null;
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }
}

class _AchievementOverlay extends StatefulWidget {
  const _AchievementOverlay({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.duration,
    required this.onDismiss,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_AchievementOverlay> createState() => _AchievementOverlayState();
}

class _AchievementOverlayState extends State<_AchievementOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _slide = Tween(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();

    // Auto-dismiss após duration
    Future.delayed(widget.duration, () {
      if (!mounted) return;
      _dismiss();
    });
  }

  void _dismiss() {
    if (_dismissing) return;
    _dismissing = true;
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 80,
      left: 0,
      right: 0,
      child: Center(
        child: SlideTransition(
          position: _slide,
          child: ScaleTransition(
            scale: _scale,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withOpacity(0.15),
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.color, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícone com glow
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withOpacity(0.2),
                        border: Border.all(color: widget.color, width: 2),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CONQUISTA DESBLOQUEADA',
                            style: TextStyle(
                              color: widget.color.withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StaggeredFadeIn extends StatefulWidget {
  const StaggeredFadeIn({
    required this.children,
    this.itemDelay = const Duration(milliseconds: 80),
    this.duration = const Duration(milliseconds: 350),
    super.key,
  });

  final List<Widget> children;
  final Duration itemDelay;
  final Duration duration;

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration + widget.itemDelay * widget.children.length,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final start = widget.itemDelay.inMilliseconds * i;
              final end = start + widget.duration.inMilliseconds;
              final t = (_controller.value * 1000 - start).clamp(0, end - start);
              final progress = (t / (end - start)).clamp(0.0, 1.0);
              // easeOutQuart: saída mais rápida, repouso mais lento — mais natural
              final curve = Curves.easeOutQuart.transform(progress.toDouble());
              return Opacity(
                opacity: curve,
                child: Transform.translate(
                  // 16px slide-up (vs 12) — mais perceptível mas ainda sutil
                  offset: Offset(0, 16 * (1 - curve)),
                  child: child,
                ),
              );
            },
            child: widget.children[i],
          ),
      ],
    );
  }
}

