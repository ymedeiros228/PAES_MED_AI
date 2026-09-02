import 'package:flutter/material.dart';

import 'surface_panel.dart';

/// Loading calmo (mint/teal) — evita spinner cru centralizado.
/// Usa pulse animation em vez de spinner rotativo — mais suave e moderno.
class SoftLoader extends StatefulWidget {
  const SoftLoader({this.label, this.compact = false, super.key});

  final String? label;
  final bool compact;

  @override
  State<SoftLoader> createState() => _SoftLoaderState();
}

class _SoftLoaderState extends State<SoftLoader> with TickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = widget.compact ? 22.0 : 28.0;
    final indicator = AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.primary.withOpacity(0.3 + t * 0.5),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(0.15 + t * 0.2),
                blurRadius: 8 + t * 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary,
              ),
            ),
          ),
        );
      },
    );
    if (widget.compact && widget.label == null) {
      return Center(child: indicator);
    }
    return Center(
      child: Padding(
        padding: EdgeInsets.all(widget.compact ? 16 : 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            indicator,
            if (widget.label != null) ...[
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => Text(
                  widget.label!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withOpacity(0.55 + _pulse.value * 0.25),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Skeletons (shimmer placeholders) ────────────────────────────────
// Dão sensação de "já está quase" em vez de spinner (que parece espera).
// Usar em telas âncora enquanto dados carregam: SkeletonCard, SkeletonList, etc.

class _ShimmerPainter extends CustomPainter {
  final Color base;
  final Color highlight;
  final double progress;

  const _ShimmerPainter(this.base, this.highlight, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = base;
    canvas.drawRect(Offset.zero & size, paint);
    final shimmerWidth = size.width * 0.4;
    final dx = -shimmerWidth + progress * (size.width + shimmerWidth);
    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.topRight,
      colors: [base, highlight, base],
      stops: [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(dx, 0, shimmerWidth, size.height));
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter old) => old.progress != progress;
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({this.width, this.height = 16, this.radius = 8});
  final double? width;
  final double height;
  final double radius;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = cs.surfaceContainerHighest;
    final highlight = cs.surfaceContainerLow;
    final w = widget.width ?? double.infinity;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => CustomPaint(
        painter: _ShimmerPainter(base, highlight, _ctrl.value),
        child: child,
      ),
      child: SizedBox(
        width: w,
        height: widget.height,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            color: base,
          ),
        ),
      ),
    );
  }
}

/// Linha placeholder com largura proporcional (0.0–1.0).
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({this.widthFraction = 1.0, this.height = 14, super.key});
  final double widthFraction;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFraction.clamp(0.05, 1.0),
      alignment: Alignment.centerLeft,
      child: _ShimmerBox(height: height, radius: height * 0.4),
    );
  }
}

/// Card placeholder: título + 2 linhas + métrica.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({this.lines = 2, super.key});
  final int lines;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ShimmerBox(width: 140, height: 18, radius: 6),
            const SizedBox(height: 12),
            for (int i = 0; i < lines; i++) ...[
              _ShimmerBox(height: 12, radius: 5, width: i == lines - 1 ? 200 : double.infinity),
              if (i < lines - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton para telas de hero (dashboard) — imita um card grande com métrica.
class SkeletonHeroCard extends StatelessWidget {
  const SkeletonHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _ShimmerBox(width: 48, height: 48, radius: 12),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _ShimmerBox(width: 120, height: 16, radius: 5),
                      const SizedBox(height: 8),
                      const _ShimmerBox(height: 12, radius: 5, width: 180),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _ShimmerBox(height: 28, radius: 6, width: 220),
            const SizedBox(height: 10),
            const _ShimmerBox(height: 14, radius: 5),
          ],
        ),
      ),
    );
  }
}

/// Skeleton para listas com ícone à esquerda (questões, revisões, domínio).
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const _ShimmerBox(width: 36, height: 36, radius: 10),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(width: 160, height: 14, radius: 5),
                  SizedBox(height: 8),
                  _ShimmerBox(height: 11, radius: 5, width: 100),
                ],
              ),
            ),
            _ShimmerBox(width: 50, height: 24, radius: 6),
          ],
        ),
      ),
    );
  }
}

/// Lista de skeleton cards para telas de listagem — substitui SoftLoader.
class SkeletonList extends StatelessWidget {
  const SkeletonList({this.count = 5, this.lines = 2, super.key});
  final int count;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < count; i++) ...[
          SkeletonCard(lines: lines),
          if (i < count - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}
