import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import 'layout_tokens.dart';
import 'surface_panel.dart';

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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Ainda sem histórico.',
          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        ),
      );
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
