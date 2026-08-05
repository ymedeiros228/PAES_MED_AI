import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'ui_kit.dart';

/// Fecho da semana — payload `weekClose` de dashboard/today (Ciclo AM).
class WeekClosePanel extends StatelessWidget {
  const WeekClosePanel({
    super.key,
    required this.weekClose,
    this.onCloseWeek,
  });

  final Map<String, dynamic> weekClose;
  final VoidCallback? onCloseWeek;

  @override
  Widget build(BuildContext context) {
    if (weekClose.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final closed = weekClose['closedThisWeek'] == true;
    final canClose = weekClose['canClose'] == true && !closed;
    final hint = weekClose['hint']?.toString() ?? 'Fecho da semana';
    final due = weekClose['due'];
    final gaps = (weekClose['gaps'] as List? ?? []).take(3).toList();
    final ctas = Map<String, dynamic>.from(weekClose['ctas'] as Map? ?? const {});
    final nat = ctas['natureza']?.toString() ?? '/sessao?examBoard=UEMA_PAES&preferNatureza=1';
    final sim = ctas['simulado']?.toString() ?? '/simulados';
    final fila = ctas['filaDue']?.toString() ?? '/fila';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          'Fecho da semana',
          hint: closed ? 'Já encerrada' : (canClose ? 'Pode encerrar' : null),
        ),
        SurfacePanel(
          margin: const EdgeInsets.only(bottom: 12),
          color: closed ? cs.primaryContainer.withOpacity(0.35) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hint, style: Theme.of(context).textTheme.bodyMedium),
              if (due != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Cards due: $due',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.65),
                      ),
                ),
              ],
              if (gaps.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Lacunas quentes',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                for (final raw in gaps)
                  Builder(
                    builder: (_) {
                      final g = Map<String, dynamic>.from(raw as Map);
                      final key = g['key']?.toString() ?? '';
                      final parts = key.split('::');
                      final label = parts.length >= 2
                          ? '${parts[0]} · ${parts[1]}'
                          : (g['subject'] != null
                              ? '${g['subject']} · ${g['topic'] ?? ''}'
                              : key);
                      return Text('· $label', style: Theme.of(context).textTheme.bodySmall);
                    },
                  ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (canClose && onCloseWeek != null)
                    FilledButton(
                      onPressed: onCloseWeek,
                      child: const Text('Encerrar semana'),
                    )
                  else if (closed)
                    Text(
                      'Semana encerrada',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.primary),
                    )
                  else
                    FilledButton(
                      onPressed: () => context.go(nat),
                      child: const Text('Sessão Natureza'),
                    ),
                  FilledButton.tonal(
                    onPressed: () => context.go(sim),
                    child: const Text('Simulado'),
                  ),
                  OutlinedButton(
                    onPressed: () => context.go(fila),
                    child: const Text('Fila'),
                  ),
                  if (!canClose && !closed)
                    TextButton(
                      onPressed: () => context.go(nat),
                      child: const Text('Natureza'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
