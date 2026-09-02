import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/media_reinforcement.dart';
import '../../../../core/widgets/ui_kit.dart';

/// Resultado pós-simulado: acerto, gaps, debrief e CTAs.
class SimulationReportPanel extends StatelessWidget {
  const SimulationReportPanel({
    super.key,
    required this.report,
    required this.clock,
    required this.wrongResults,
    required this.debriefBuilder,
    required this.onRemediateGaps,
    required this.onExportReport,
    required this.onResetSim,
  });

  final Map<String, dynamic> report;
  final String clock;
  final List<Map<String, dynamic>> wrongResults;
  final Widget Function(String questionId, String subject, String topic) debriefBuilder;
  final VoidCallback onRemediateGaps;
  final VoidCallback onExportReport;
  final VoidCallback onResetSim;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gaps = report['gaps'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Resultado'),
        SurfacePanel(
          margin: const EdgeInsets.only(bottom: 12),
          color: cs.primaryContainer.f35,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: ((report['accuracy'] as num) * 100).toDouble()),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  final pct = value.toStringAsFixed(0);
                  final color = value >= 70
                      ? cs.primary
                      : value >= 40
                          ? cs.tertiary
                          : cs.error;
                  return Text(
                    '$pct% de acerto',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
                  );
                },
              ),
              Text(
                '${report['correct']}/${report['total']} corretas · tempo $clock',
                style: TextStyle(fontSize: 14, height: 1.5, color: cs.onPrimaryContainer.withOpacity(0.9)),
              ),
              if (report['estimatedScore'] != null) ...[
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: ((report['estimatedScore'] as num)).toDouble()),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Text(
                      'Nota estimada: ${value.toStringAsFixed(0)}/1000',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    );
                  },
                ),
                Text(
                  'Estimativa local — não é nota oficial UEMA.',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.6)),
                ),
              ],
              if (report['avgTimeMs'] != null)
                Text(
                  'Média ${((report['avgTimeMs'] as num) / 1000).toStringAsFixed(1)}s por item',
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
                ),
              if (report['warning'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${report['warning']}',
                  style: TextStyle(color: cs.error),
                ),
              ],
            ],
          ),
        ),
        if ((report['subjectBreakdown'] as List? ?? []).isNotEmpty) ...[
          const SectionLabel('Por disciplina'),
          for (final s in (report['subjectBreakdown'] as List).take(8))
            PlaylistTile(
              title: (s as Map)['subject']?.toString() ?? '—',
              subtitle:
                  '${s['correct']}/${s['total']} · ${(((s['accuracy'] as num?) ?? 0) * 100).toStringAsFixed(0)}%',
              leadingIcon: Icons.school_outlined,
            ),
        ],
        if (gaps.isNotEmpty) ...[
          const SectionLabel('Tópicos para revisar'),
          for (final g in gaps.take(6))
            PlaylistTile(
              title: '${(g as Map)['subject']} · ${g['topic']}',
              subtitle: '${g['wrong']} erro(s)',
              leadingIcon: Icons.flag_outlined,
              onPlay: () => context.go(
                '/adaptativo?subject=${Uri.encodeComponent(g['subject']?.toString() ?? '')}'
                '&topic=${Uri.encodeComponent(g['topic']?.toString() ?? '')}',
              ),
            ),
          Builder(
            builder: (_) {
              final gapMaps = gaps.whereType<Map>().toList();
              if (gapMaps.isEmpty) return const SizedBox.shrink();
              final g0 = Map<String, dynamic>.from(gapMaps.first);
              final s = g0['subject']?.toString() ?? '';
              final t = g0['topic']?.toString() ?? '';
              if (s.isEmpty || t.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: MediaReinforcement(subject: s, topic: t, compact: true),
              );
            },
          ),
        ],
        if (wrongResults.isNotEmpty) ...[
          const SectionLabel('Erros — debrief', hint: '4 eixos quando a resolução for real'),
          for (final r in wrongResults.take(8))
            SurfacePanel(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${r['subject'] ?? ''} · ${r['topic'] ?? ''}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
                  ),
                  debriefBuilder(
                    r['questionId']?.toString() ?? '',
                    r['subject']?.toString() ?? '',
                    r['topic']?.toString() ?? '',
                  ),
                ],
              ),
            ),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: gaps.isNotEmpty
                  ? () {
                      HapticFeedback.selectionClick();
                      onRemediateGaps();
                    }
                  : () {
                      HapticFeedback.selectionClick();
                      context.go('/fila');
                    },
              icon: const Icon(Icons.playlist_play_rounded),
              label: Text(
                gaps.isNotEmpty
                    ? 'Mandar tópicos para revisar para a Fila'
                    : 'Continuar na Fila',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonal(
              onPressed: () {
                HapticFeedback.selectionClick();
                context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1');
              },
              child: const Text('Sessão Natureza'),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                context.go('/redacao');
              },
              child: const Text('Redação'),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                context.go('/dashboard');
              },
              child: const Text('Hoje'),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onExportReport();
              },
              child: const Text('Exportar resumo'),
            ),
            OutlinedButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onResetSim();
              },
              child: const Text('Novo simulado'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(
            'Detalhe das respostas',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
          ),
          children: [
            for (final r in (report['results'] as List? ?? []))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  (r as Map)['correct'] == true ? Icons.check_circle : Icons.cancel,
                  color: r['correct'] == true ? cs.primary : cs.error,
                ),
                title: Text('${r['subject']} · ${r['topic']}'),
                trailing: TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.go('/questoes/${r['questionId']}');
                  },
                  child: const Text('Ver'),
                ),
              ),
            if ((report['professorHints'] as List? ?? []).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Macete dos erros',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
              ),
              for (final h in (report['professorHints'] as List).take(5))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${(h as Map)['topic']}'),
                  subtitle: Text(h['macete']?.toString() ?? ''),
                  trailing: TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      context.go('/questoes/${h['questionId']}');
                    },
                    child: const Text('Abrir'),
                  ),
                ),
            ],
          ],
        ),
      ],
    );
  }
}
