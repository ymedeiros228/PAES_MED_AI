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
export 'ui/gamification_effects.dart';
export 'ui/session_widgets.dart';

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
