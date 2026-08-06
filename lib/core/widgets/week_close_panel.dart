import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/api_client.dart';
import '../data/api_error.dart';
import 'ui_kit.dart';

/// Fecho da semana — payload `weekClose` de dashboard/today (Ciclo AM).
/// Exportar semana → `POST /api/study/export-week` (Ciclo BT).
class WeekClosePanel extends StatefulWidget {
  const WeekClosePanel({
    super.key,
    required this.weekClose,
    this.onCloseWeek,
  });

  final Map<String, dynamic> weekClose;
  final VoidCallback? onCloseWeek;

  @override
  State<WeekClosePanel> createState() => _WeekClosePanelState();
}

class _WeekClosePanelState extends State<WeekClosePanel> {
  String? exportMsg;
  bool exportBusy = false;

  Future<void> _exportWeek() async {
    setState(() {
      exportBusy = true;
      exportMsg = null;
    });
    try {
      final data = await apiClient.post('/api/study/export-week', {});
      final map = Map<String, dynamic>.from(data as Map);
      final path = map['path']?.toString() ?? '';
      final dir = map['dir']?.toString() ?? '';
      if (dir.isNotEmpty) {
        try {
          await apiClient.post('/api/library/open-path', {'path': dir});
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        exportMsg = path.isNotEmpty
            ? path
            : (map['filename']?.toString() ?? 'exportado');
        exportBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path.isNotEmpty
                ? 'Semana exportada: $path'
                : (map['message']?.toString() ?? 'Exportado'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        exportMsg = humanApiError(e, fallback: 'Não deu para exportar a semana.');
        exportBusy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekClose = widget.weekClose;
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
                    builder: (gapCtx) {
                      final g = Map<String, dynamic>.from(raw as Map);
                      final key = g['key']?.toString() ?? '';
                      final parts = key.split('::');
                      final subject = parts.isNotEmpty && parts[0].isNotEmpty
                          ? parts[0]
                          : (g['subject']?.toString() ?? '');
                      final topic = parts.length >= 2
                          ? parts.sublist(1).join('::')
                          : (g['topic']?.toString() ?? '');
                      final label = subject.isNotEmpty
                          ? (topic.isNotEmpty ? '$subject · $topic' : subject)
                          : (key.isNotEmpty ? key : 'Lacuna');
                      if (subject.isEmpty) {
                        return Text('· $label', style: Theme.of(context).textTheme.bodySmall);
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => context.go(
                                  '/adaptativo?subject=${Uri.encodeComponent(subject)}'
                                  '&topic=${Uri.encodeComponent(topic)}',
                                ),
                                child: Text(
                                  '· $label → treinar',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                try {
                                  await apiClient.post('/api/gaps/recover', {
                                    'subject': subject,
                                    'topic': topic,
                                  });
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Lacuna marcada como recuperada (treino local).'),
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        humanApiError(e, fallback: 'Não deu para marcar a lacuna.'),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Recuperada'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (canClose && widget.onCloseWeek != null)
                    FilledButton(
                      onPressed: widget.onCloseWeek,
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
                    onPressed: exportBusy ? null : _exportWeek,
                    child: Text(exportBusy ? 'Exportando…' : 'Exportar semana'),
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
              if (exportMsg != null) ...[
                const SizedBox(height: 8),
                Text(
                  exportMsg!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.65),
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
