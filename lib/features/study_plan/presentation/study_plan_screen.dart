import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/data/study_prefs_providers.dart';
import '../../../core/widgets/media_reinforcement.dart';
import '../../../core/widgets/ui_kit.dart';

/// Plano de estudos — modo visual (calendário leve + checklist).
class StudyPlanScreen extends ConsumerStatefulWidget {
  const StudyPlanScreen({super.key});

  @override
  ConsumerState<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends ConsumerState<StudyPlanScreen> {
  int days = 30;
  List<dynamic> plan = [];
  String? error;
  bool loading = false;
  String? exportMsg;
  bool weekOnly = true;

  Future<void> _load({bool regenerate = false}) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final exam = ref.read(examDateProvider);
      final until = ref.read(examDateProvider.notifier).daysUntilExam;
      if (until != null && until > 0 && until < 180) {
        days = until;
      }
      if (regenerate) {
        plan = await apiClient.post('/api/plans/generate', {
          'days': days,
          'examDate': exam.isEmpty ? null : exam,
        }) as List<dynamic>;
      } else {
        plan = await apiClient.get('/api/plans/$days') as List<dynamic>;
      }
      ref.read(refreshTickProvider.notifier).state++;
    } catch (e) {
      error = humanApiError(e, fallback: 'Não deu para carregar o plano. Tente de novo.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _toggleDone(Map<String, dynamic> item, bool done) async {
    try {
      await apiClient.post('/api/plans/done', {
        'days': days,
        'day': item['day'],
        'done': done,
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => exportMsg = humanApiError(e, fallback: 'Não deu para marcar o dia. Tente de novo.'));
    }
  }

  Future<void> _exportMarkdown(String markdown, String filename) async {
    try {
      final data = await apiClient.post('/api/study/export-day', {
        'markdown': markdown,
        'filename': filename,
      });
      final map = Map<String, dynamic>.from(data as Map);
      final path = map['path']?.toString() ?? '';
      setState(() => exportMsg = path.isNotEmpty ? 'Exportado: $path' : 'Exportado em data/exports');
      if (path.isNotEmpty) {
        try {
          final parent = path.replaceAll('\\', '/');
          final dir = parent.contains('/')
              ? parent.substring(0, parent.lastIndexOf('/'))
              : path;
          await apiClient.post('/api/library/open-path', {'path': dir});
        } catch (_) {}
      }
    } catch (e) {
      setState(() => exportMsg = humanApiError(e, fallback: 'Não deu para exportar o plano.'));
    }
  }

  Future<void> _exportWeek() async {
    final week = plan.take(7).toList();
    final buf = StringBuffer('# Plano da semana — PAES MED AI\n\n');
    final exam = ref.read(examDateProvider);
    if (exam.isNotEmpty) buf.writeln('Prova: $exam\n');
    buf.writeln('Estimativas de incidência ≠ garantia.\n');
    for (final raw in week) {
      final item = Map<String, dynamic>.from(raw as Map);
      buf.writeln('## Dia ${item['day']}: ${item['subject']} — ${item['topic']}');
      buf.writeln('${item['reason']}\n');
    }
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '').substring(0, 15);
    await _exportMarkdown(buf.toString(), 'plano_semana_$stamp.md');
  }

  Future<void> _exportMonth() async {
    final month = plan.take(30).toList();
    final buf = StringBuffer('# Plano do mês — PAES MED AI\n\n');
    final exam = ref.read(examDateProvider);
    if (exam.isNotEmpty) buf.writeln('Prova: $exam\n');
    buf.writeln('Estimativas ≠ garantia.\n');
    for (final raw in month) {
      final item = Map<String, dynamic>.from(raw as Map);
      buf.writeln('- Dia ${item['day']}: ${item['subject']} — ${item['topic']}');
    }
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '').substring(0, 15);
    await _exportMarkdown(buf.toString(), 'plano_mes_$stamp.md');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final until = ref.watch(examDateProvider.notifier).daysUntilExam;
    final exam = ref.watch(examDateProvider);
    final cs = Theme.of(context).colorScheme;
    final visible = weekOnly ? plan.take(7).toList() : plan;
    final doneN = plan.where((e) => (e as Map)['done'] == true).length;
    final progress = plan.isEmpty ? 0.0 : doneN / plan.length;

    return ListView(
      children: [
        PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: 'Planejar',
                title: 'Plano de estudos',
                subtitle: until == null
                    ? 'Defina a data da prova em Ajustes para calibrar o ritmo.'
                    : 'Faltam $until dias${exam.isEmpty ? '' : ' · $exam'}. Incidência + erros recentes.',
                trailing: FilledButton.tonal(
                  onPressed: loading ? null : () => _load(regenerate: true),
                  child: const Text('Regenerar'),
                ),
              ),

              SurfacePanel(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.isEmpty ? 'Sem plano gerado' : '$doneN / ${plan.length} dias marcados',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: cs.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in [30, 60, 90])
                    ChoiceChip(
                      label: Text('$d dias'),
                      selected: days == d,
                      onSelected: loading
                          ? null
                          : (_) {
                              setState(() => days = d);
                              _load(regenerate: true);
                            },
                    ),
                  if (until != null && until > 0)
                    ChoiceChip(
                      label: Text('Até a prova ($until)'),
                      selected: days == until,
                      onSelected: loading
                          ? null
                          : (_) {
                              setState(() => days = until);
                              _load(regenerate: true);
                            },
                    ),
                  FilterChip(
                    label: Text(weekOnly ? 'Só semana' : 'Plano completo'),
                    selected: weekOnly,
                    onSelected: (v) => setState(() => weekOnly = v),
                  ),
                  OutlinedButton(
                    onPressed: plan.isEmpty ? null : _exportWeek,
                    child: const Text('Exportar plano (semana)'),
                  ),
                  OutlinedButton(
                    onPressed: plan.isEmpty ? null : _exportMonth,
                    child: const Text('Exportar plano (mês)'),
                  ),
                ],
              ),
              if (exportMsg != null) ...[
                const SizedBox(height: 8),
                Text(exportMsg!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.primary)),
              ],
              if (loading) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(minHeight: 2),
              ],
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: TextStyle(color: cs.error)),
              ],

              const SizedBox(height: 8),
              FutureBuilder(
                future: Future.wait([
                  apiClient.get('/api/revisions'),
                  apiClient.get('/api/dashboard'),
                ]),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  final revs = (snap.data![0] as List?) ?? [];
                  final dash = Map<String, dynamic>.from(snap.data![1] as Map);
                  final hot = (dash['errorHotTopics'] as List? ?? []).take(3).toList();
                  final routine = Map<String, dynamic>.from(dash['dailyRoutine'] as Map? ?? {});
                  final sessionPath = routine['sessionPath']?.toString() ?? '/sessao';
                  final rSubj = routine['subject']?.toString() ?? '';
                  final rTopic = routine['topic']?.toString() ?? '';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (rSubj.isNotEmpty)
                        SurfacePanel(
                          margin: const EdgeInsets.only(bottom: 12, top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Hoje: $rSubj · $rTopic',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                  ),
                                  FilledButton(
                                    onPressed: () => context.go(sessionPath),
                                    child: const Text('Fazer agora'),
                                  ),
                                ],
                              ),
                              if (rTopic.isNotEmpty)
                                MediaReinforcement(
                                  subject: rSubj,
                                  topic: rTopic,
                                  compact: true,
                                  heading: 'Reforço do coach',
                                ),
                            ],
                          ),
                        ),
                      SurfacePanel(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: cs.primaryContainer.withOpacity(0.35),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Foco da semana', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 4),
                            Text(
                              '${revs.length} revisões · hot errors abaixo',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            for (final raw in hot)
                              PlaylistTile(
                                title: (raw as Map)['key']?.toString() ?? '',
                                subtitle: '${raw['misses']} misses',
                                badge: 'hot',
                                leadingIcon: Icons.whatshot_rounded,
                                onPlay: () {
                                  final key = raw['key']?.toString() ?? '';
                                  final parts = key.split('::');
                                  context.go(
                                    '/adaptativo?subject=${Uri.encodeComponent(parts.isNotEmpty ? parts[0] : '')}'
                                    '&topic=${Uri.encodeComponent(parts.length > 1 ? parts[1] : '')}',
                                  );
                                },
                              ),
                            if (hot.isEmpty)
                              QuietEmpty(
                                message: 'Sem hot errors — treine a fila.',
                                action: TextButton(
                                  onPressed: () => context.go('/fila'),
                                  child: const Text('Fila'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              SectionLabel(
                weekOnly ? 'Próximos 7 dias' : 'Cronograma ($days dias)',
                hint: 'Toque o dia para marcar · “Play” abre sessão no tópico',
              ),

              if (!loading && plan.isEmpty)
                QuietEmpty(
                  message: 'Gere um plano com Regenerar.',
                  action: FilledButton(
                    onPressed: () => _load(regenerate: true),
                    child: const Text('Gerar'),
                  ),
                ),

              for (final raw in visible)
                Builder(
                  builder: (context) {
                    final item = Map<String, dynamic>.from(raw as Map);
                    final done = item['done'] == true;
                    final fromErrors = item['fromErrors'] == true ||
                        (item['reason']?.toString().contains('Erro recente') ?? false);
                    final subject = item['subject']?.toString() ?? '';
                    final topic = item['topic']?.toString() ?? '';
                    final nat = const {'Biologia', 'Química', 'Física'}.contains(subject);
                    return SurfacePanel(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: done
                          ? cs.primaryContainer.withOpacity(0.25)
                          : fromErrors
                              ? cs.tertiaryContainer.withOpacity(0.4)
                              : null,
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                      child: Row(
                        children: [
                          Checkbox(
                            value: done,
                            onChanged: (v) => _toggleDone(item, v ?? false),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: fromErrors ? cs.tertiaryContainer : cs.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${item['day']}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: fromErrors ? cs.onTertiaryContainer : cs.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$subject — $topic',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        decoration: done ? TextDecoration.lineThrough : null,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                Text(
                                  item['reason']?.toString() ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (fromErrors)
                                  Text(
                                    'Erro recente',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: cs.tertiary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Sessão neste tópico',
                            onPressed: () => context.go(
                              '/sessao?examBoard=UEMA_PAES'
                              '&subject=${Uri.encodeComponent(subject)}'
                              '&topic=${Uri.encodeComponent(topic)}'
                              '&preferNatureza=${nat ? '1' : '0'}',
                            ),
                            icon: Icon(Icons.play_circle_fill_rounded, color: cs.primary),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              if (weekOnly && plan.length > 7) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => setState(() => weekOnly = false),
                  child: Text('Ver todos os ${plan.length} dias'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
