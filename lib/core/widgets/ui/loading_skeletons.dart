import 'package:flutter/material.dart';

import 'layout_tokens.dart';
import 'surface_panel.dart';

/// Loading calmo (pulso teal) — para áreas pequenas/ações. Para telas
/// inteiras prefira skeletons (`SkeletonPage`, `SkeletonList`, `SkeletonCard`).
class SoftLoader extends StatefulWidget {
  const SoftLoader({this.label, this.compact = false, super.key});

  final String? label;
  final bool compact;

  @override
  State<SoftLoader> createState() => _SoftLoaderState();
}

class _SoftLoaderState extends State<SoftLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respeita "reduzir animações" do sistema.
    if (AppMotion.reduced(context)) {
      _pulse.stop();
      _pulse.value = 0.6;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = widget.compact ? 20.0 : 26.0;
    // RepaintBoundary: o pulso repinta só este quadradinho, não a tela.
    final indicator = RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _PulsePainter(_pulse, cs.primary)),
      ),
    );
    final semantic = widget.label ?? 'Carregando';
    if (widget.compact && widget.label == null) {
      return Semantics(label: semantic, child: Center(child: indicator));
    }
    return Semantics(
      label: semantic,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(widget.compact ? kGap16 : kGap32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              indicator,
              if (widget.label != null) ...[
                const SizedBox(height: kGap16),
                Text(
                  widget.label!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.72)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter(this.anim, this.color) : super(repaint: anim);
  final Animation<double> anim;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeInOut.transform(anim.value);
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(c, r * (0.75 + 0.25 * t), Paint()..color = color.withOpacity(0.18 + 0.22 * t));
    canvas.drawCircle(c, r * 0.45, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PulsePainter old) => old.color != color || old.anim != anim;
}

// ─── Skeletons (shimmer) ─────────────────────────────────────────────
// Um único AnimationController por bloco de skeleton (SkeletonScope),
// compartilhado por todas as caixinhas; a pintura acontece só na camada
// do CustomPaint (sem rebuild de widgets por frame).

/// Compartilha uma única animação de shimmer com todos os skeletons abaixo.
/// Os widgets `Skeleton*` já criam um escopo sozinhos se não houver um acima;
/// envolva manualmente só se montar vários `SkeletonBox` soltos.
class SkeletonScope extends StatefulWidget {
  const SkeletonScope({required this.child, super.key});
  final Widget child;

  @override
  State<SkeletonScope> createState() => _SkeletonScopeState();
}

class _SkeletonScopeState extends State<SkeletonScope> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _ctrl.stop();
      _ctrl.value = 0.5;
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      animation: _ctrl,
      child: Semantics(
        label: 'Carregando',
        child: ExcludeSemantics(child: RepaintBoundary(child: widget.child)),
      ),
    );
  }
}

class _ShimmerScope extends InheritedWidget {
  const _ShimmerScope({required this.animation, required super.child});
  final Animation<double> animation;

  static Animation<double>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>()?.animation;

  @override
  bool updateShouldNotify(_ShimmerScope old) => old.animation != animation;
}

/// Garante um [SkeletonScope] acima (cria se não houver).
class _EnsureScope extends StatelessWidget {
  const _EnsureScope({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (_ShimmerScope.maybeOf(context) != null) return child;
    return SkeletonScope(child: child);
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({
    required this.animation,
    required this.base,
    required this.highlight,
    required this.radius,
  }) : super(repaint: animation);

  final Animation<double>? animation;
  final Color base;
  final Color highlight;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    canvas.drawRRect(rrect, Paint()..color = base);
    final progress = animation?.value ?? 0.5;
    final shimmerWidth = size.width * 0.5;
    final dx = -shimmerWidth + progress * (size.width + shimmerWidth);
    final shader = LinearGradient(
      colors: [base, highlight, base],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(dx, 0, shimmerWidth, size.height));
    canvas.drawRRect(rrect, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter old) =>
      old.base != base || old.highlight != highlight || old.radius != radius || old.animation != animation;
}

/// Caixa de skeleton (bloco cinza com shimmer).
///
/// ```dart
/// SkeletonBox(width: 120, height: 16)
/// SkeletonBox(height: 160, radius: 16) // imagem/gráfico
/// ```
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({this.width, this.height = 16, this.radius = 8, super.key});
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: CustomPaint(
        painter: _ShimmerPainter(
          animation: _ShimmerScope.maybeOf(context),
          base: isDark ? cs.surfaceContainerHigh : cs.surfaceContainerHighest,
          highlight: isDark ? cs.surfaceContainerHighest : cs.surfaceContainerLow,
          radius: radius,
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
    return _EnsureScope(
      child: FractionallySizedBox(
        widthFactor: widthFraction.clamp(0.05, 1.0),
        alignment: Alignment.centerLeft,
        child: SkeletonBox(height: height, radius: height * 0.4),
      ),
    );
  }
}

/// Card placeholder: título + [lines] linhas.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({this.lines = 2, super.key});
  final int lines;

  @override
  Widget build(BuildContext context) {
    return _EnsureScope(
      child: SurfacePanel(
        padding: const EdgeInsets.all(kGap20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 160, height: 18, radius: 6),
            const SizedBox(height: kGap16),
            for (int i = 0; i < lines; i++) ...[
              FractionallySizedBox(
                widthFactor: i == lines - 1 && lines > 1 ? 0.55 : 1,
                alignment: Alignment.centerLeft,
                child: const SkeletonBox(height: 12, radius: 5),
              ),
              if (i < lines - 1) const SizedBox(height: kGap8 + 2),
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
    return const _EnsureScope(
      child: SurfacePanel(
        padding: EdgeInsets.all(kGap24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonBox(width: 48, height: 48, radius: 12),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 120, height: 16, radius: 5),
                      SizedBox(height: 8),
                      SkeletonBox(height: 12, radius: 5, width: 180),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 18),
            SkeletonBox(height: 28, radius: 6, width: 220),
            SizedBox(height: 10),
            SkeletonBox(height: 14, radius: 5),
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
    return const _EnsureScope(
      child: SurfacePanel(
        padding: EdgeInsets.symmetric(horizontal: kGap16, vertical: 14),
        child: Row(
          children: [
            SkeletonBox(width: 36, height: 36, radius: 10),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 160, height: 14, radius: 5),
                  SizedBox(height: 8),
                  SkeletonBox(height: 11, radius: 5, width: 100),
                ],
              ),
            ),
            SkeletonBox(width: 50, height: 24, radius: 6),
          ],
        ),
      ),
    );
  }
}

/// Lista de skeleton cards — uma única animação para todos.
class SkeletonList extends StatelessWidget {
  const SkeletonList({this.count = 5, this.lines = 2, super.key});
  final int count;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return _EnsureScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < count; i++) ...[
            SkeletonCard(lines: lines),
            if (i < count - 1) const SizedBox(height: kGap12),
          ],
        ],
      ),
    );
  }
}

/// Tela inteira carregando: cabeçalho + cards, já na largura padrão.
/// Use no `loading:` de um AsyncValue de página.
///
/// ```dart
/// loading: () => const SkeletonPage(),
/// ```
class SkeletonPage extends StatelessWidget {
  const SkeletonPage({this.cards = 3, this.maxWidth = kPageMaxWidth, super.key});
  final int cards;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final gutter = pageGutterFor(w);
        final h = w.isFinite && w - maxWidth > 0 ? (w - maxWidth) / 2 + gutter : gutter;
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(h, kGap24, h, kGap24),
          child: _EnsureScope(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 90, height: 12, radius: 4),
                const SizedBox(height: kGap12),
                const SkeletonBox(width: 260, height: 28, radius: 8),
                const SizedBox(height: kGap12),
                const SkeletonBox(width: 380, height: 14, radius: 5),
                const SizedBox(height: kGap32),
                for (var i = 0; i < cards; i++) ...[
                  SkeletonCard(lines: i == 0 ? 3 : 2),
                  const SizedBox(height: kGap12),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
