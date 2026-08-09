import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Layout padding padrão das telas âncora.
const kPagePadding = EdgeInsets.fromLTRB(28, 20, 28, 40);
const kPageMaxWidth = 1080.0;
const kRadiusMicro = 4.0;
const kRadiusControl = 10.0;
const kRadiusButton = 12.0;
const kRadiusPanel = 16.0;
const kRadiusPanelSoft = 18.0;
const kRadiusHighlight = 20.0;
const kGap4 = 4.0;
const kGap8 = 8.0;
const kGap12 = 12.0;
const kGap16 = 16.0;
const kGap24 = 24.0;

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
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
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
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimaryContainer,
                      ),
                ),
              ),
            ],
          ],
        ),
        Container(
          margin: const EdgeInsets.only(top: 10),
          width: 36,
          height: 3,
          decoration: BoxDecoration(
            color: cs.primary.f85,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
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
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.f72,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class SurfacePanel extends StatelessWidget {
  const SurfacePanel({
    required this.child,
    this.padding = const EdgeInsets.all(kGap16),
    this.color,
    this.margin = EdgeInsets.zero,
    this.soft = true,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final EdgeInsets margin;
  /// Sombra leve + borda suave (padrão hospitalidade).
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? cs.surface.withOpacity(isDark ? 0.94 : 0.98),
        borderRadius: BorderRadius.circular(soft ? kRadiusPanelSoft : kRadiusPanel),
        border: Border.all(color: cs.outlineVariant.withOpacity(soft ? 0.55 : 0.85)),
        boxShadow: soft && !isDark
            ? [
                BoxShadow(
                  color: const Color(0xFF0A1628).withOpacity(0.045),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: child,
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
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                if (widget.subtitle != null)
                                  Text(
                                    widget.subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall,
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
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                Container(width: 1, height: 36, color: cs.outlineVariant),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      items[i].$1,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      items[i].$2,
                      style: Theme.of(context).textTheme.bodySmall,
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
                        const SizedBox(width: 4),
                      ],
                      Text(
                        phases[i],
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: i == currentIndex
                                  ? cs.onPrimary
                                  : i < currentIndex
                                      ? cs.primary
                                      : cs.onSurface.f72,
                              fontWeight: FontWeight.w700,
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

class QuietEmpty extends StatelessWidget {
  const QuietEmpty({required this.message, this.action, this.icon, super.key});
  final String message;
  final Widget? action;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: message,
      button: action != null,
      child: SurfacePanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(kRadiusButton),
              ),
              child: Icon(
                icon ?? Icons.hourglass_empty_rounded,
                size: 18,
                color: cs.onSurface.f55,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.f72,
                      height: 1.35,
                    ),
              ),
            ),
            if (action != null) ...[const SizedBox(width: 8), action!],
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
              final curve = Curves.easeOutCubic.transform(progress.toDouble());
              return Opacity(
                opacity: curve,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - curve)),
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

    if (paragraphs.length <= 1) {
      // Texto curto: SelectableText simples em container
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh.f38,
          borderRadius: BorderRadius.circular(kRadiusPanel),
          border: Border.all(color: cs.outlineVariant.f38),
        ),
        child: SelectableText(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.f38,
        borderRadius: BorderRadius.circular(kRadiusPanel),
        border: Border.all(color: cs.outlineVariant.f38),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < paragraphs.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            SelectableText(
              paragraphs[i],
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
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
              const SizedBox(height: 14),
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => Text(
                  widget.label!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

/// Lista de skeleton cards para telas de listagem.
class SkeletonList extends StatelessWidget {
  const SkeletonList({this.count = 5, this.lines = 2, super.key});
  final int count;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: count,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SkeletonCard(lines: lines),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                        borderRadius: BorderRadius.circular(kRadiusControl),
                      ),
                      child: Text(
                        letter,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: letterFg,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.35,
                            color: widget.revealCorrect == true
                                ? cs.onPrimaryContainer
                                : null,
                            fontWeight: widget.revealCorrect == true ? FontWeight.w600 : null,
                          ),
                    ),
                  ),
                  // Ícone de feedback (certo/errado) ao revelar gabarito
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      trailingIcon,
                      size: 22,
                      color: widget.revealCorrect == true ? cs.primary : cs.error,
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
class StudyCheckRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SurfacePanel(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      soft: false,
      color: done ? cs.primaryContainer.withOpacity(0.28) : null,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? cs.primary : cs.surfaceContainerHigh,
            ),
            child: Icon(
              done ? Icons.check_rounded : Icons.circle_outlined,
              size: 16,
              color: done ? cs.onPrimary : cs.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done ? cs.onSurface.f55 : null,
                    fontWeight: done ? FontWeight.w500 : FontWeight.w600,
                  ),
            ),
          ),
          if (actionLabel != null && onAction != null && !done)
            FilledButton.tonal(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Text(actionLabel!),
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
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: textOn,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: muted,
                              height: 1.4,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
          if (child != null) ...[const SizedBox(height: 14), child!],
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
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
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(why, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            honestNote,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.primary),
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
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w700,
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
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == 0 ? cs.primary : cs.outlineVariant,
                        ),
                      ),
                      if (i < items.length - 1)
                        Container(
                          width: 2,
                          height: 36,
                          color: cs.outlineVariant.withOpacity(0.7),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        if (items[i].subtitle != null)
                          Text(
                            items[i].subtitle!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurface.f72,
                                ),
                          ),
                        if (items[i].trailing != null) ...[
                          const SizedBox(height: 6),
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Continuar sessão',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
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
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.f72,
                ),
          ),
          const SizedBox(height: 12),
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
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: i <= step ? cs.onPrimary : cs.onSurface.f72,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: i == step ? FontWeight.w800 : FontWeight.w500,
                            color: i == step ? cs.primary : cs.onSurface.f72,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
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
