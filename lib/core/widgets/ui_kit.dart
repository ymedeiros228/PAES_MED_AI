import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'ui/layout_tokens.dart';
import 'ui/surface_panel.dart';

export 'ui/layout_tokens.dart';
export 'ui/surface_panel.dart';
export 'ui/constellation_map.dart';
export 'ui/loading_skeletons.dart';

/// Centraliza o conteúdo e aplica padding — ar como apps desktop modernos.
class PageBody extends StatelessWidget {
  const PageBody({
    required this.child,
    this.padding = kPagePadding,
    this.maxWidth = kPageMaxWidth,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.trailing,
    this.badge,
    super.key,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? trailing;
  /// Badge contextual ao lado do título (ex: "oficial", "treino", contador).
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              color: cs.primary,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: cs.onSurface,
                  height: 1.2,
                ),
              ),
            ),
            if (badge != null && badge!.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.f65,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: cs.primary.f85,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurface.f72,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 520 || MediaQuery.sizeOf(context).width < 700;
          if (trailing == null) return heading;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                heading,
                const SizedBox(height: kGap8),
                Align(alignment: Alignment.centerRight, child: trailing!),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: heading),
              const SizedBox(width: kGap12),
              trailing!,
            ],
          );
        },
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {this.hint, this.chip, super.key});
  final String label;
  final String? hint;
  final String? chip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              if (chip != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: cs.tertiaryContainer,
                  ),
                  child: Text(
                    chip!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cs.onTertiaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                hint!,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.f72,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Linha tipo playlist (Fila / Domínio / Plano).
class PlaylistTile extends StatefulWidget {
  const PlaylistTile({
    required this.title,
    this.subtitle,
    this.badge,
    this.badgeColor,
    this.leadingIcon = Icons.play_circle_outline_rounded,
    this.onPlay,
    this.secondary,
    this.active = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? badge;
  /// Cor do fundo do badge (ex.: tertiary / primary) — status sem depender só do texto.
  final Color? badgeColor;
  final IconData leadingIcon;
  final VoidCallback? onPlay;
  final Widget? secondary;
  final bool active;

  @override
  State<PlaylistTile> createState() => _PlaylistTileState();
}

class _PlaylistTileState extends State<PlaylistTile> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = widget.active
        ? cs.primaryContainer.f55
        : hover
            ? cs.surfaceContainerHigh.f55
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      cursor: widget.onPlay != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: Tooltip(
        message: widget.title,
        waitDuration: const Duration(milliseconds: 800),
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: kGap8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(kRadiusButton),
          border: Border.all(
            color: widget.active
                ? cs.primary.f22
                : (hover ? cs.outlineVariant.f65 : Colors.transparent),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(kRadiusButton),
            onTap: widget.onPlay,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 4,
                    decoration: BoxDecoration(
                      color: widget.active ? cs.primary : Colors.transparent,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(kGap8, kGap12, kGap12, kGap12),
                      child: Row(
                        children: [
                          Icon(
                            widget.leadingIcon,
                            color: widget.active ? cs.primary : cs.onSurface.f45,
                            size: 26,
                          ),
                          const SizedBox(width: kGap12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                ),
                                if (widget.subtitle != null)
                                  Text(
                                    widget.subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: cs.onSurface.f72),
                                  ),
                              ],
                            ),
                          ),
                          if (widget.badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: widget.badgeColor ?? cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.badge!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: widget.badgeColor != null
                                      ? (ThemeData.estimateBrightnessForColor(widget.badgeColor!) ==
                                              Brightness.dark
                                          ? Colors.white
                                          : cs.onSurface)
                                      : null,
                                ),
                              ),
                            ),
                          ],
                          if (widget.secondary != null) ...[
                            const SizedBox(width: 8),
                            widget.secondary!,
                          ] else if (widget.onPlay != null) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right_rounded, color: cs.onSurface.f35),
                          ],
                        ],
                      ),
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

class StatsStrip extends StatelessWidget {
  const StatsStrip({required this.items, super.key});
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Semântica agregada para leitores de tela: "5 dias seguidos, 42 min hoje, 78% acerto"
    final semanticLabel = items.map((e) => '${e.$1} ${e.$2}').join(', ');
    return Semantics(
      label: semanticLabel,
      child: SurfacePanel(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Container(width: 1, height: 36, color: cs.outlineVariant.f40),
              Expanded(
                child: Column(
                  children: [
                    _StatValue(
                      raw: items[i].$1,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: cs.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[i].$2,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.f72,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Extrai sufixo (%, min, etc.) e usa AnimatedCounter para a parte numérica.
class _StatValue extends StatelessWidget {
  const _StatValue({required this.raw, required this.style});
  final String raw;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    // Tenta separar número do sufixo (ex: "78%", "42 min", "5")
    final match = RegExp(r'^(-?\d+)(.*)$').firstMatch(raw);
    if (match == null) {
      return Text(raw, style: style);
    }
    final value = int.tryParse(match.group(1)!) ?? 0;
    final suffix = match.group(2) ?? '';
    return AnimatedCounter(value: value, suffix: suffix, style: style);
  }
}

/// Barra de fases da sessão (mínima, tipo player).
/// Estados: done (check verde), current (primary preenchido), upcoming (cinza).
class PhaseProgressBar extends StatelessWidget {
  const PhaseProgressBar({
    required this.phases,
    required this.currentIndex,
    this.onSelect,
    super.key,
  });

  final List<String> phases;
  final int currentIndex;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SurfacePanel(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          for (var i = 0; i < phases.length; i++) ...[
            if (i > 0)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: i <= currentIndex ? cs.primary : cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            InkWell(
              onTap: onSelect == null ? null : () => onSelect!(i),
              borderRadius: BorderRadius.circular(kRadiusHighlight),
              child: Tooltip(
                message: phases[i],
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: i == currentIndex
                        ? cs.primary
                        : i < currentIndex
                            ? cs.primaryContainer.f65
                            : cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(kRadiusHighlight),
                    border: i < currentIndex && i != currentIndex
                        ? Border.all(color: cs.primary.f38, width: 1)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (i < currentIndex) ...[
                        Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        phases[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: i == currentIndex ? FontWeight.w700 : FontWeight.w600,
                          color: i == currentIndex
                              ? cs.onPrimary
                              : i < currentIndex
                                  ? cs.primary
                                  : cs.onSurface.f72,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class QuietEmpty extends StatefulWidget {
  const QuietEmpty({required this.message, this.action, this.icon, super.key});
  final String message;
  final Widget? action;
  final IconData? icon;

  @override
  State<QuietEmpty> createState() => _QuietEmptyState();
}

class _QuietEmptyState extends State<QuietEmpty>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: widget.message,
      button: widget.action != null,
      child: SurfacePanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) => Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.surfaceContainerHigh,
                      cs.surfaceContainerHigh.withOpacity(0.6 + _ctrl.value * 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.outlineVariant.withOpacity(0.3 + _ctrl.value * 0.15),
                    width: 1,
                  ),
                ),
                child: child,
              ),
              child: Icon(
                widget.icon ?? Icons.inbox_rounded,
                size: 20,
                color: cs.onSurface.f55,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.message,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface.f72,
                  height: 1.5,
                ),
              ),
            ),
            if (widget.action != null) ...[const SizedBox(width: 10), widget.action!],
          ],
        ),
      ),
    );
  }
}

/// Estado secundário compacto para não fazer uma seção desaparecer em silêncio.
class CompactStatus extends StatelessWidget {
  const CompactStatus({
    required this.message,
    this.icon = Icons.info_outline_rounded,
    super.key,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: message,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 17, color: cs.onSurface.withOpacity(0.58)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.f72,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formata enunciado de questão em parágrafos legíveis.
/// Detecta mudanças de parágrafo (ponto final + maiúscula) e adiciona
/// espaçamento vertical entre eles — melhora muito a leitura no desktop.
/// Animação de entrada fade-in em cascata para listas de widgets.
/// Cada item aparece com um pequeno atraso, criando um efeito visual suave.

/// Notificação gamificada de conquista — aparece como overlay temporário.
///
/// Mostra um ícone, título e subtítulo com animação de entrada (slide + scale)
/// e saída automática após [duration]. Use [AchievementToast.show] para exibir.
/// Botão com efeito de pulso suave para chamar atenção.
/// Útil para CTAs importantes como "Continuar sessão" quando há checkpoint.
/// Efeito de confete leve — partículas coloridas que caem e somem.
/// Usa OverlayEntry temporário; não precisa de dependência externa.
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

class StatementView extends StatelessWidget {
  const StatementView({
    required this.text,
    this.maxLines,
    super.key,
  });

  final String text;
  final int? maxLines;

  /// Divide o texto em parágrafos por pontos finais seguidos de maiúscula.
  /// Preserva citações e abreviações comuns (Sr., Dr., etc.).
  List<String> _splitParagraphs(String raw) {
    if (raw.isEmpty) return [raw];
    // Adiciona \n\n após ponto final seguido de espaço + maiúscula
    // Mas não após abreviações comuns
    final abbr = RegExp(
      r'\b(?:Sr|Sra|Dr|Dra|Prof|Profa|Art|Ed|Ex|p|pp|vol|fig|tab|al|cf|op|cit)\.\s*$',
      caseSensitive: false,
    );
    final paragraphBreak = RegExp(r'(?<=[.!?])\s+(?=[A-ZÀ-Ý""\[])');
    final parts = raw.split(paragraphBreak);
    // Filtra abreviações: se o parágrafo anterior termina com abreviação,
    // junta com o próximo
    final merged = <String>[];
    for (var i = 0; i < parts.length; i++) {
      if (merged.isNotEmpty && abbr.hasMatch(merged.last.trim())) {
        merged[merged.length - 1] = '${merged.last} ${parts[i]}';
      } else {
        merged.add(parts[i]);
      }
    }
    return merged.where((p) => p.trim().isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final paragraphs = _splitParagraphs(text);

    // Estilo serif para enunciados — Lora (Google Fonts) para leitura confortável
    final statementStyle = TextStyle(fontFamily: 'Georgia', 
      fontSize: 15.5,
      height: 1.65,
      letterSpacing: 0.15,
      color: cs.onSurface,
    );

    if (paragraphs.length <= 1) {
      // Texto curto: SelectableText simples em container
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh.f38,
          borderRadius: BorderRadius.circular(kRadiusPanel),
          border: Border.all(color: cs.outlineVariant.f38),
        ),
        child: SelectableText(
          text,
          style: statementStyle,
          contextMenuBuilder: (context, editableTextState) =>
              AdaptiveTextSelectionToolbar.editableText(
            editableTextState: editableTextState,
          ),
        ),
      );
    }

    // Múltiplos parágrafos: container com cada parágrafo separado
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.f38,
        borderRadius: BorderRadius.circular(kRadiusPanel),
        border: Border.all(color: cs.outlineVariant.f38),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < paragraphs.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            SelectableText(
              paragraphs[i],
              style: statementStyle,
              contextMenuBuilder: (context, editableTextState) =>
                  AdaptiveTextSelectionToolbar.editableText(
                editableTextState: editableTextState,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Alternativa A–E em painéis clicáveis (sessão / simulado).
class ChoiceOptionTile extends StatefulWidget {
  const ChoiceOptionTile({
    required this.index,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.revealCorrect,
    super.key,
  });

  final int index;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;
  /// null = ainda sem revelar; true/false após correção.
  final bool? revealCorrect;

  @override
  State<ChoiceOptionTile> createState() => _ChoiceOptionTileState();
}

class _ChoiceOptionTileState extends State<ChoiceOptionTile> {
  bool _hover = false;

  void _handleTap() {
    if (widget.onTap == null) return;
    // Haptic feedback sutil ao selecionar uma alternativa.
    HapticFeedback.selectionClick();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final letter = widget.index >= 0 && widget.index < 5 ? 'ABCDE'[widget.index] : '?';
    Color border = cs.outlineVariant.f60;
    Color bg = cs.surface;
    Color letterBg = cs.surfaceContainerHigh;
    Color letterFg = cs.onSurface.f72;
    IconData? trailingIcon;

    if (widget.revealCorrect == true) {
      border = cs.primary.f55;
      bg = cs.primaryContainer.f45;
      letterBg = cs.primary;
      letterFg = cs.onPrimary;
      trailingIcon = Icons.check_circle_rounded;
    } else if (widget.revealCorrect == false && widget.selected) {
      border = cs.error.f45;
      bg = cs.errorContainer.f35;
      letterBg = cs.error;
      letterFg = cs.onError;
      trailingIcon = Icons.cancel_rounded;
    } else if (widget.selected) {
      border = cs.primary.f55;
      bg = cs.primaryContainer.f38;
      letterBg = cs.primary;
      letterFg = cs.onPrimary;
    } else if (_hover && widget.enabled) {
      border = cs.outlineVariant.f85;
      bg = cs.surfaceContainerHigh.f50;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        cursor: widget.enabled && widget.onTap != null
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? _handleTap : null,
            borderRadius: BorderRadius.circular(kRadiusButton),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(kRadiusButton),
                border: Border.all(
                  color: border,
                  width: widget.selected || widget.revealCorrect != null ? 1.4 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Letra A/B/C/D/E com animação de scale ao selecionar
                  AnimatedScale(
                    scale: widget.selected || widget.revealCorrect != null ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: letterBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        letter,
                        style: TextStyle(
                          color: letterFg,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SelectableText(
                      widget.label,
                      style: TextStyle(
                        height: 1.45,
                        fontSize: 14,
                        color: widget.revealCorrect == true
                            ? cs.onPrimaryContainer
                            : cs.onSurface,
                        fontWeight: widget.revealCorrect == true ? FontWeight.w600 : null,
                      ),
                      contextMenuBuilder: (context, editableTextState) =>
                          AdaptiveTextSelectionToolbar.editableText(
                        editableTextState: editableTextState,
                      ),
                    ),
                  ),
                  // Ícone de feedback (certo/errado) ao revelar gabarito
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: AnimatedScale(
                        scale: 1.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        child: Icon(
                          trailingIcon,
                          size: 20,
                          color: widget.revealCorrect == true ? cs.primary : cs.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Linha de checklist do dia (Hoje).
class StudyCheckRow extends StatefulWidget {
  const StudyCheckRow({
    required this.done,
    required this.label,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final bool done;
  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<StudyCheckRow> createState() => _StudyCheckRowState();
}

class _StudyCheckRowState extends State<StudyCheckRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.25, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    if (widget.done) _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant StudyCheckRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.done && widget.done) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SurfacePanel(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      soft: false,
      color: widget.done ? cs.primaryContainer.withOpacity(0.28) : null,
      child: Row(
        children: [
          ScaleTransition(
            scale: widget.done ? _scale : const AlwaysStoppedAnimation(1.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.done ? cs.primary : cs.surfaceContainerHigh,
              ),
              child: Icon(
                widget.done ? Icons.check_rounded : Icons.circle_outlined,
                size: 16,
                color: widget.done ? cs.onPrimary : cs.onSurface.withOpacity(0.4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                decoration: widget.done ? TextDecoration.lineThrough : null,
                color: widget.done ? cs.onSurface.f55 : cs.onSurface,
                fontWeight: widget.done ? FontWeight.w500 : FontWeight.w600,
              ),
            ),
          ),
          if (widget.actionLabel != null && widget.onAction != null && !widget.done)
            FilledButton.tonal(
              onPressed: () {
                HapticFeedback.selectionClick();
                widget.onAction!();
              },
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Text(widget.actionLabel!),
            ),
        ],
      ),
    );
  }
}

/// Faixa de atmosfera (gradiente mint→sand) — sem “card farm”.
class HeroStudyStrip extends StatelessWidget {
  const HeroStudyStrip({
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.trailing,
    this.child,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? eyebrow;
  final Widget? trailing;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textOn = isDark ? Colors.white : const Color(0xFF0A1628);
    final muted = textOn.f72;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0B1A2C), Color(0xFF0C3D36), Color(0xFF0A1628)]
              : const [Color(0xFFE6F6F1), Color(0xFFF6F4F1), Color(0xFFDCEEE8)],
        ),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFF0C7A63).withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (eyebrow != null) ...[
                      Text(
                        eyebrow!.toUpperCase(),
                        style: TextStyle(
                          color: isDark ? const Color(0xFF3DC9A8) : const Color(0xFF0C7A63),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.4,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        color: textOn,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: muted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
          if (child != null) ...[const SizedBox(height: 16), child!],
        ],
      ),
    );
  }
}

enum MissionQuestStatus { open, active, cleared }

/// Missão com um CTA — redação / Hoje / Progresso.
class MissionQuestCard extends StatelessWidget {
  const MissionQuestCard({
    required this.title,
    required this.why,
    required this.ctaLabel,
    required this.onCta,
    this.status = MissionQuestStatus.open,
    this.honestNote = 'treino local · não banca',
    super.key,
  });

  final String title;
  final String why;
  final String ctaLabel;
  final VoidCallback? onCta;
  final MissionQuestStatus status;
  final String honestNote;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusLabel = switch (status) {
      MissionQuestStatus.open => 'Aberta',
      MissionQuestStatus.active => 'Em curso',
      MissionQuestStatus.cleared => 'Concluída',
    };
    final statusColor = switch (status) {
      MissionQuestStatus.open => cs.tertiary,
      MissionQuestStatus.active => cs.primary,
      MissionQuestStatus.cleared => cs.primary.f85,
    };
    return SurfacePanel(
      margin: const EdgeInsets.only(bottom: 14),
      color: cs.tertiaryContainer.withOpacity(0.32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            why,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurface.withOpacity(0.88),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            honestNote,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
          if (onCta != null && status != MissionQuestStatus.cleared) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onCta, child: Text(ctaLabel)),
          ],
        ],
      ),
    );
  }
}

/// Chip de variação (+0,8 coesão).
class DeltaChip extends StatelessWidget {
  const DeltaChip({required this.label, this.delta, super.key});

  final String label;
  final double? delta;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final d = delta;
    final Color bg;
    final Color fg;
    String text;
    if (d == null) {
      bg = cs.surfaceContainerHighest;
      fg = cs.onSurface.f65;
      text = label;
    } else if (d > 0.05) {
      bg = cs.primaryContainer;
      fg = cs.onPrimaryContainer;
      text = '+${d.toStringAsFixed(1)} $label';
    } else if (d < -0.05) {
      bg = cs.errorContainer.f55;
      fg = cs.onErrorContainer;
      text = '${d.toStringAsFixed(1)} $label';
    } else {
      bg = cs.surfaceContainerHighest;
      fg = cs.onSurface.f65;
      text = '· $label';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(kRadiusHighlight)),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class HonestBadge extends StatelessWidget {
  const HonestBadge({this.label = 'treino local · não banca', super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: cs.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Linha de histórico soft (redação / progresso).
class SoftTimeline extends StatelessWidget {
  const SoftTimeline({required this.items, super.key});

  final List<SoftTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (items.isEmpty) {
      return QuietEmpty(message: 'Ainda sem histórico.');
    }
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          InkWell(
            onTap: items[i].onTap,
            borderRadius: BorderRadius.circular(kRadiusButton),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      // Ponto do timeline com anel suave no item atual
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == 0 ? cs.primary : cs.surfaceContainerHighest,
                          border: i == 0
                              ? Border.all(color: cs.primary.withOpacity(0.3), width: 3)
                              : null,
                        ),
                      ),
                      if (i < items.length - 1)
                        Container(
                          width: 2,
                          height: 32,
                          color: cs.outlineVariant.withOpacity(0.5),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        if (items[i].subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            items[i].subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.f72,
                              height: 1.4,
                            ),
                          ),
                        ],
                        if (items[i].trailing != null) ...[
                          const SizedBox(height: 8),
                          items[i].trailing!,
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class SoftTimelineItem {
  const SoftTimelineItem({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
}

/// Banner “Continuar sessão” com fases teoria → questões → revisão (Ciclo HU).
class SessionResumeBanner extends StatelessWidget {
  const SessionResumeBanner({
    required this.phaseName,
    required this.subtitle,
    required this.onContinue,
    this.onDiscard,
    super.key,
  });

  final String phaseName;
  final String subtitle;
  final VoidCallback onContinue;
  final VoidCallback? onDiscard;

  static int phaseStep(String phaseName) {
    return switch (phaseName) {
      'theory' => 0,
      'questions' => 1,
      'revisions' || 'review' || 'cards' => 2,
      _ => 0,
    };
  }

  static String phaseLabel(String phaseName) {
    return switch (phaseName) {
      'theory' => 'Teoria',
      'questions' => 'Questões',
      'revisions' || 'review' || 'cards' => 'Revisão',
      _ => phaseName.isEmpty ? 'Sessão' : phaseName,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final step = phaseStep(phaseName);
    const labels = ['Teoria', 'Questões', 'Revisão'];
    return SurfacePanel(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      color: cs.primaryContainer.withOpacity(0.42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.history_edu_rounded, color: cs.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Continuar sessão',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              if (onDiscard != null)
                TextButton(
                  onPressed: onDiscard,
                  child: const Text('Descartar'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: cs.onPrimaryContainer.withOpacity(0.85),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: i <= step ? cs.primary : cs.outlineVariant,
                        borderRadius: BorderRadius.circular(kRadiusMicro),
                      ),
                    ),
                  ),
                Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i <= step ? cs.primary : cs.surfaceContainerHighest,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: i <= step ? cs.onPrimary : cs.onSurface.f72,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: i == step ? FontWeight.w700 : FontWeight.w500,
                        color: i == step ? cs.primary : cs.onSurface.f72,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onContinue,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text('Continuar · ${phaseLabel(phaseName)}'),
          ),
        ],
      ),
    );
  }
}

/// Conta de 0 até [value] com animação suave (count-up).
/// Estilo Duolingo/Khan — números ganham vida ao aparecer.
class AnimatedCounter extends StatefulWidget {
  const AnimatedCounter({
    required this.value,
    this.duration = const Duration(milliseconds: 900),
    this.style,
    this.suffix = '',
    this.prefix = '',
    super.key,
  });

  final int value;
  final Duration duration;
  final TextStyle? style;
  final String suffix;
  final String prefix;

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  int _lastValue = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: widget.duration, vsync: this);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _lastValue = oldWidget.value;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final current = (_lastValue + (widget.value - _lastValue) * _anim.value).round();
        return Text(
          '${widget.prefix}$current${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}

/// Botão com scale down ao pressionar (micro-interação moderna).
/// Envolve qualquer botão Material para dar feedback tátil visual.
class TapScale extends StatefulWidget {
  const TapScale({
    required this.child,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 100),
    super.key,
  });

  final Widget child;
  final double scaleDown;
  final Duration duration;

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.scaleDown : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Fade-in escalonado para listas — cada item aparece com delay progressivo.
/// Mais simples que AnimatedList para casos estáticos.
class StaggeredListView extends StatelessWidget {
  const StaggeredListView({
    required this.children,
    this.itemDelay = const Duration(milliseconds: 60),
    this.initialDelay = const Duration(milliseconds: 80),
    super.key,
  });

  final List<Widget> children;
  final Duration itemDelay;
  final Duration initialDelay;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i++)
          _StaggeredItem(
            delay: initialDelay + itemDelay * i,
            child: children[i],
          ),
      ],
    );
  }
}

class _StaggeredItem extends StatefulWidget {
  const _StaggeredItem({required this.delay, required this.child});
  final Duration delay;
  final Widget child;

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}
