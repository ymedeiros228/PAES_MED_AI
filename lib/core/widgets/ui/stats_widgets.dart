import 'package:flutter/material.dart';
import 'micro_interactions.dart';

import '../../theme/app_theme.dart';
import 'layout_tokens.dart';
import 'surface_panel.dart';

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

