import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/data/study_prefs_providers.dart';
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
  Map<String, dynamic>? smartPlan;
  String? error;
  bool loading = false;
  String? exportMsg;
  bool weekOnly = true;
  int selected = 0;
  String _todaySessionPath = '/sessao';
  final _focusNode = FocusNode();

  String _sessionPathFor(Map<String, dynamic> item) {
    final subject = item['subject']?.toString() ?? '';
    final topic = item['topic']?.toString() ?? '';
    final nat = const {'Biologia', 'Química', 'Física'}.contains(subject);
    return '/sessao?examBoard=UEMA_PAES'
        '&subject=${Uri.encodeComponent(subject)}'
        '&topic=${Uri.encodeComponent(topic)}'
        '&preferNatureza=${nat ? '1' : '0'}';
  }

  List<Map<String, dynamic>> _visibleItems() {
    final visible = weekOnly ? plan.take(7).toList() : plan;
    return visible.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  void _syncSelection() {
    final items = _visibleItems();
    if (items.isEmpty) {
      selected = 0;
      return;
    }
    if (selected >= items.length) selected = items.length - 1;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final items = _visibleItems();
    if (key == LogicalKeyboardKey.keyS) {
      context.go(_todaySessionPath);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyR || key == LogicalKeyboardKey.f5) {
      unawaited(_load());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyE && plan.isNotEmpty) {
      unawaited(_exportWeek());
      return KeyEventResult.handled;
    }
    if (items.isEmpty) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyJ) {
      setState(() => selected = (selected + 1).clamp(0, items.length - 1));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyK) {
      setState(() => selected = (selected - 1).clamp(0, items.length - 1));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      context.go(_sessionPathFor(items[selected.clamp(0, items.length - 1)]));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space) {
      final item = items[selected.clamp(0, items.length - 1)];
      unawaited(_toggleDone(item, item['done'] != true));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _load({bool regenerate = false}) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final exam = ref.read(examDateProvider).date;
      final until = ref.read(examDateProvider.notifier).daysUntilExam;
      if (until != null && until > 0 && until < 180) {
        days = until;
      }
      // Carregar cronograma inteligente em paralelo
      final results = await Future.wait([
        regenerate
            ? apiClient.post('/api/plans/generate', {
                'days': days,
                'examDate': exam.isEmpty ? null : exam,
              })
            : apiClient.get('/api/plans/$days'),
        apiClient.get('/api/plans/smart${exam.isEmpty ? '' : '?examDate=$exam'}'),
      ]);
      plan = results[0] as List<dynamic>;
      smartPlan = results[1] is Map<String, dynamic>
          ? Map<String, dynamic>.from(results[1] as Map)
          : null;
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
      if (mounted) {
        setState(
          () => exportMsg = humanApiError(e, fallback: 'Não deu para marcar o dia no plano.'),
        );
      }
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
          await apiClient.openPath(dir);
        } catch (e) {
          if (mounted) {
            setState(
              () => exportMsg =
                  '${exportMsg ?? 'Exportado'} · ${humanApiError(e, fallback: 'Pasta de export não abriu.')}',
            );
          }
        }
      }
    } catch (e) {
      setState(() => exportMsg = humanApiError(e, fallback: 'Não deu para exportar o plano.'));
    }
  }

  Future<void> _exportWeek() async {
    final week = plan.take(7).toList();
    final buf = StringBuffer('# Plano da semana — PAES MED AI\n\n');
    final exam = ref.read(examDateProvider).date;
    if (exam.isNotEmpty) buf.writeln('Prova: $exam\n');
    buf.writeln('Estimativas, não garantia.\n');
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
    final exam = ref.read(examDateProvider).date;
    if (exam.isNotEmpty) buf.writeln('Prova: $exam\n');
    buf.writeln('Estimativas, não garantia.\n');
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
    _load();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final until = ref.watch(examDateProvider.notifier).daysUntilExam;
    final examState = ref.watch(examDateProvider);
    final exam = examState.date;
    final cs = Theme.of(context).colorScheme;
    final visible = _visibleItems();
    _syncSelection();
    final doneN = plan.where((e) => (e as Map)['done'] == true).length;
    final progress = plan.isEmpty ? 0.0 : doneN / plan.length;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
      children: [
        PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: 'Planejar',
                title: 'Plano de estudos',
                subtitle: until == null
                    ? 'Defina a data da prova em Ajustes'
                    : 'Faltam $until dias${exam.isEmpty ? '' : ' · $exam'}',
                trailing: FilledButton.tonal(
                  onPressed: loading ? null : () { HapticFeedback.selectionClick(); _load(regenerate: true); },
                  child: const Text('Regenerar'),
                ),
              ),

              // Card de cronograma inteligente
              if (smartPlan != null) ...[
                _SmartPlanCard(data: smartPlan!),
                const SizedBox(height: 16),
              ],

              if (examState.syncError != null) ...[
                QuietEmpty(
                  message: examState.syncError!,
                  action: Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () { HapticFeedback.selectionClick(); unawaited(ref.read(examDateProvider.notifier).retrySync()); },
                        child: const Text('Sincronizar'),
                      ),
                      TextButton(
                        onPressed: () { HapticFeedback.selectionClick(); context.go('/configuracoes'); },
                        child: const Text('Ajustes'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

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
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
                          ),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface).copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(kRadiusControl),
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
                              HapticFeedback.selectionClick();
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
                              HapticFeedback.selectionClick();
                              setState(() => days = until);
                              _load(regenerate: true);
                            },
                    ),
                  FilterChip(
                    label: Text(weekOnly ? 'Só semana' : 'Plano completo'),
                    selected: weekOnly,
                    onSelected: (v) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        weekOnly = v;
                        selected = 0;
                      });
                    },
                  ),
                  OutlinedButton(
                    onPressed: plan.isEmpty ? null : () { HapticFeedback.selectionClick(); _exportWeek(); },
                    child: const Text('Exportar plano (semana) (E)'),
                  ),
                  OutlinedButton(
                    onPressed: plan.isEmpty ? null : () { HapticFeedback.selectionClick(); _exportMonth(); },
                    child: const Text('Exportar plano (mês)'),
                  ),
                ],
              ),
              if (exportMsg != null) ...[
                const SizedBox(height: 8),
                Text(exportMsg!, style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withOpacity(0.7)).copyWith(color: cs.primary)),
              ],
              if (loading) ...[
                const SizedBox(height: 12),
                const SkeletonList(count: 3, lines: 2),
              ],
              if (error != null) ...[
                const SizedBox(height: 8),
                QuietEmpty(
                  message: error!,
                  action: TextButton(
                    onPressed: () { HapticFeedback.selectionClick(); unawaited(_load()); },
                    child: const Text('Tentar de novo'),
                  ),
                ),
              ],

              const SizedBox(height: 8),
              FutureBuilder(
                future: Future.wait([
                  apiClient.get('/api/revisions'),
                  apiClient.get('/api/dashboard'),
                ]),
                builder: (context, snap) {
                  if (!snap.hasData) return const SkeletonList(count: 2, lines: 3);
                  final revs = (snap.data![0] as List?) ?? [];
                  final dash = Map<String, dynamic>.from(snap.data![1] as Map);
                  final hot = (dash['errorHotTopics'] as List? ?? []).take(3).toList();
                  final routine = Map<String, dynamic>.from(dash['dailyRoutine'] as Map? ?? {});
                  final sessionPath = routine['sessionPath']?.toString() ?? '/sessao';
                  if (sessionPath != _todaySessionPath) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _todaySessionPath = sessionPath);
                    });
                  }
                  final rSubj = routine['subject']?.toString() ?? '';
                  final rTopic = routine['topic']?.toString() ?? '';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (rSubj.isNotEmpty)
                        SurfacePanel(
                          margin: const EdgeInsets.only(bottom: 12, top: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Hoje: $rSubj · $rTopic',
                                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
                                ),
                              ),
                              FilledButton(
                                onPressed: () { HapticFeedback.mediumImpact(); context.go(sessionPath); },
                                child: const Text('Fazer agora (S)'),
                              ),
                            ],
                          ),
                        ),
                      SurfacePanel(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: cs.primaryContainer.f35,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Foco da semana', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
                            const SizedBox(height: 4),
                            Text(
                              '${revs.length} revisões · erros recentes abaixo',
                              style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
                            ),
                            for (final raw in hot)
                              PlaylistTile(
                                title: (raw as Map)['key']?.toString() ?? '',
                                subtitle: '${raw['misses']} erros',
                                badge: 'foco',
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
                                message: 'Sem erros recentes — treine a fila.',
                                action: TextButton(
                                  onPressed: () { HapticFeedback.selectionClick(); context.go('/fila'); },
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
                hint: '↑/↓ J/K · Enter sessão · Espaço marca feito · Play no ícone',
              ),

              if (!loading && plan.isEmpty)
                QuietEmpty(
                  message: 'Gere um plano com Regenerar.',
                  action: FilledButton(
                    onPressed: () { HapticFeedback.mediumImpact(); _load(regenerate: true); },
                    child: const Text('Gerar'),
                  ),
                ),

              for (var i = 0; i < visible.length; i++)
                Builder(
                  builder: (context) {
                    final item = visible[i];
                    final active = i == selected;
                    final done = item['done'] == true;
                    final fromErrors = item['fromErrors'] == true ||
                        (item['reason']?.toString().contains('Erro recente') ?? false);
                    final subject = item['subject']?.toString() ?? '';
                    final topic = item['topic']?.toString() ?? '';
                    return SurfacePanel(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: active
                          ? cs.primaryContainer.f55
                          : done
                          ? cs.primaryContainer.withOpacity(0.25)
                          : fromErrors
                              ? cs.tertiaryContainer.withOpacity(0.4)
                              : null,
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      child: Row(
                        children: [
                          Checkbox(
                            value: done,
                            onChanged: (v) { HapticFeedback.selectionClick(); _toggleDone(item, v ?? false); },
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: fromErrors ? cs.tertiaryContainer : cs.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(kRadiusControl),
                            ),
                            child: Text(
                              '${item['day']}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: fromErrors ? cs.onTertiaryContainer : cs.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$subject — $topic',
                                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface).copyWith(
                                        decoration: done ? TextDecoration.lineThrough : null,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                SelectableText(
                                  item['reason']?.toString() ?? '',
                                  maxLines: 3,
                                  style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
                                ),
                                if (fromErrors)
                                  Text(
                                    'Erro recente',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface).copyWith(
                                          color: cs.tertiary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Sessão neste tópico',
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setState(() => selected = i);
                              context.go(_sessionPathFor(item));
                            },
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
                  onPressed: () { HapticFeedback.selectionClick(); setState(() => weekOnly = false); },
                  child: Text('Ver todos os ${plan.length} dias'),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
    );
  }
}


class _SmartPlanCard extends StatelessWidget {
  const _SmartPlanCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final countdown = data['countdownDays'] ?? 60;
    final studyDays = data['totalStudyDays'] ?? 0;
    final reviewDays = data['totalReviewDays'] ?? 0;
    final totalTopics = data['totalTopics'] ?? 0;
    final schedule = (data['schedule'] as List?) ?? [];

    // Primeiro dia de estudo
    final todayItem = schedule.isNotEmpty ? schedule[0] as Map : null;
    final todayGoals = todayItem?['dailyGoals'] as Map?;
    final todayTopics = (todayItem?['topics'] as List?) ?? [];

    return SurfacePanel(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '$countdown',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cronograma Inteligente',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$studyDays dias de estudo + $reviewDays de revisao - $totalTopics topicos',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (todayTopics.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Hoje:',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final t in todayTopics.take(2))
                    Chip(
                      label: Text(
                        '${t['subject']} - ${t['topic']}',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ],
            if (todayGoals != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (todayGoals['questions'] != null)
                    _GoalChip(icon: Icons.quiz_outlined, label: '${todayGoals['questions']} questoes'),
                  const SizedBox(width: 8),
                  if (todayGoals['flashcards'] != null)
                    _GoalChip(icon: Icons.style_outlined, label: '${todayGoals['flashcards']} cards'),
                  if (todayGoals['essay'] == true) ...[
                    const SizedBox(width: 8),
                    _GoalChip(icon: Icons.edit_outlined, label: 'Redacao'),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 12),
            TapScale(
              child: FilledButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  if (todayTopics.isNotEmpty) {
                    final t = todayTopics[0] as Map;
                    final subj = t['subject']?.toString() ?? '';
                    final topic = t['topic']?.toString() ?? '';
                    final nat = const {'Biologia', 'Quimica', 'Fisica'}.contains(subj);
                    context.go('/sessao?examBoard=UEMA_PAES'
                        '&subject=${Uri.encodeComponent(subj)}'
                        '&topic=${Uri.encodeComponent(topic)}'
                        '&preferNatureza=${nat ? '1' : '0'}');
                  } else {
                    context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1');
                  }
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Estudar agora'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurface.withOpacity(0.6)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
