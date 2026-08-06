import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/data/study_prefs_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../core/widgets/week_close_panel.dart';

/// Hoje: hero com coach do dia + checklist + prontidão/semana (Ciclo C/F).
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Map<String, dynamic>? checkpoint;
  String? checkpointLoadError;
  bool showFirstRunCoach = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadCheckpoint();
    _loadFirstRunCoach();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
      final exam = ref.read(examDateProvider).date;
      if (exam.isNotEmpty) {
        unawaited(ref.read(examDateProvider.notifier).retrySync());
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event, String sessionPath, String closePath) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyS ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      context.go(sessionPath);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyL) {
      context.go(closePath);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyR || key == LogicalKeyboardKey.f5) {
      ref.read(refreshTickProvider.notifier).state++;
      _loadCheckpoint();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _loadFirstRunCoach() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => showFirstRunCoach = prefs.getBool('first_run_coach_pending') ?? false);
  }

  Future<void> _dismissFirstRunCoach() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_run_coach_pending', false);
    if (mounted) setState(() => showFirstRunCoach = false);
  }

  Future<void> _loadCheckpoint() async {
    try {
      final raw = await apiClient.get('/api/session/checkpoint');
      final cp = (raw as Map)['checkpoint'];
      if (cp is Map && cp['started'] == true) {
        setState(() {
          checkpoint = Map<String, dynamic>.from(cp);
          checkpointLoadError = null;
        });
      } else {
        setState(() {
          checkpoint = null;
          checkpointLoadError = null;
        });
      }
    } catch (e) {
      setState(() {
        checkpoint = null;
        checkpointLoadError = humanApiError(
          e,
          fallback: 'Checkpoint de sessão indisponível no Hoje.',
        );
      });
    }
  }

  Future<void> _discardCheckpoint() async {
    try {
      await apiClient.delete('/api/session/checkpoint');
      setState(() {
        checkpoint = null;
        checkpointLoadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            humanApiError(e, fallback: 'Não foi possível descartar a sessão salva.'),
          ),
        ),
      );
    }
  }

  String _checkpointShort(Map<String, dynamic> cp) {
    final phase = cp['phaseName']?.toString() ?? '';
    final phaseLabel = switch (phase) {
      'theory' => 'Teoria',
      'questions' => 'Questões',
      'revisions' || 'review' || 'cards' => 'Revisão',
      _ => phase.isEmpty ? 'Sessão' : phase,
    };
    final q = (cp['qIndex'] as num?)?.toInt();
    if (phase == 'questions' && q != null) return '$phaseLabel · item ${q + 1}';
    return phaseLabel;
  }

  Future<void> _closeDay() async {
    try {
      final data = await apiClient.post('/api/study/day-close', {});
      final map = Map<String, dynamic>.from(data as Map);
      if (!mounted) return;
      ref.read(refreshTickProvider.notifier).state++;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(map['message']?.toString() ?? 'Dia encerrado.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanApiError(e, fallback: 'Não foi possível encerrar o dia.'))),
      );
    }
  }

  Future<void> _closeWeek() async {
    try {
      final data = await apiClient.post('/api/study/week-close', {});
      final map = Map<String, dynamic>.from(data as Map);
      if (!mounted) return;
      ref.read(refreshTickProvider.notifier).state++;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(map['message']?.toString() ?? 'Semana encerrada.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanApiError(e, fallback: 'Não foi possível fechar a semana.'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dashboardProvider);
    final examDaysLocal = ref.watch(examDateProvider.notifier).daysUntilExam;
    final exam = ref.watch(examDateProvider).date;
    final focus = ref.watch(focusModeProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        title: 'Não foi possível carregar',
        subtitle: humanApiError(e, fallback: 'Reabra pelo ícone PAES MED AI na área de trabalho.'),
        action: Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          children: [
            FilledButton(
              onPressed: () => ref.read(refreshTickProvider.notifier).state++,
              child: const Text('Tentar de novo'),
            ),
            TextButton(
              onPressed: () => context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1'),
              child: const Text('Sessão'),
            ),
          ],
        ),
      ),
      data: (data) {
        final routine = Map<String, dynamic>.from(data['dailyRoutine'] as Map? ?? {});
        final checklist = Map<String, dynamic>.from(routine['checklist'] as Map? ?? {});
        final sessionPath = routine['sessionPath']?.toString() ??
            (data['officialUnlocked'] == true
                ? '/sessao?examBoard=UEMA_PAES&preferNatureza=1'
                : '/sessao');
        final coachLine = routine['line']?.toString() ?? 'Pronto para estudar?';
        final closePath = routine['closePath']?.toString() ?? '/fila';
        final closeLabel = routine['closeLabel']?.toString() ?? 'Ver fila';
        final progress = routine['progressLabel']?.toString() ?? '';
        final backupReminder = routine['backupReminder']?.toString();
        final dayClosed = routine['dayClosed'] == true || checklist['dayClosed'] == true;
        final week = Map<String, dynamic>.from(
          (data['weekProgress'] as Map?) ?? (routine['week'] as Map?) ?? const {},
        );
        final readiness = Map<String, dynamic>.from(data['readiness'] as Map? ?? const {});
        final calendar = Map<String, dynamic>.from(data['studyCalendar'] as Map? ?? const {});
        final countdown = Map<String, dynamic>.from(
          (data['examCountdown'] as Map?) ?? (routine['countdown'] as Map?) ?? const {},
        );
        final examDaysApi = countdown['daysLeft'] is num ? (countdown['daysLeft'] as num).toInt() : null;
        final examDays = examDaysApi ?? examDaysLocal;
        final officialN = data['statsBasis'] is Map
            ? ((data['statsBasis'] as Map)['officialCount'] as int? ?? 0)
            : 0;
        // Coach só com acervo vazio: se já há oficiais e flag pendente, limpa sem mostrar
        if (showFirstRunCoach && officialN > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && showFirstRunCoach) unawaited(_dismissFirstRunCoach());
          });
        }
        final openGaps = data['openGaps'] as Map?;
        final gapItems = openGaps?['items'] as List? ?? const [];
        final gapN = openGaps?['openCount'] as int? ?? gapItems.length;
        final hot = (data['errorHotTopics'] as List? ?? []).take(2).toList();
        final dueCardsFuture = apiClient.get('/api/flashcards?dueOnly=true');
        final readyScore = (readiness['score'] as num?)?.toDouble();
        final calItems = calendar['items'] as List? ?? const [];

        return Focus(
          focusNode: _focusNode,
          onKeyEvent: (node, event) => _onKey(node, event, sessionPath, closePath),
          child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                constraints: const BoxConstraints(minHeight: 360),
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient(Theme.of(context).brightness),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAES MED AI',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontSize: 34,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (countdown['label']?.toString().isNotEmpty == true)
                          ? countdown['label'].toString()
                          : examDays == null
                              ? 'Medicina · UEMA'
                              : examDays >= 0
                                  ? '$examDays dias para a prova'
                                  : 'Prova na conta',
                      style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 15),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      coachLine,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            height: 1.25,
                          ),
                    ),
                    if (progress.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        progress,
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.navy,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                          ),
                          onPressed: () => context.go(sessionPath),
                          child: Text(
                            checkpoint != null
                                ? 'Continuar · ${_checkpointShort(checkpoint!)} (S)'
                                : 'Começar sessão (S)',
                          ),
                        ),
                        if (checkpoint != null)
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white70),
                            ),
                            onPressed: _discardCheckpoint,
                            child: const Text('Recomeçar'),
                          ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                          ),
                          onPressed: () => context.go(closePath),
                          child: Text('$closeLabel (L)'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'S sessão · L fila · R atualiza · Enter',
                      style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: kPageMaxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (checkpointLoadError != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: QuietEmpty(
                                message: checkpointLoadError!,
                                action: TextButton(
                                  onPressed: _loadCheckpoint,
                                  child: const Text('Tentar'),
                                ),
                              ),
                            ),
                          if (ref.watch(examDateProvider).syncError != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: QuietEmpty(
                                message: ref.watch(examDateProvider).syncError!,
                                action: TextButton(
                                  onPressed: () => unawaited(
                                    ref.read(examDateProvider.notifier).retrySync(),
                                  ),
                                  child: const Text('Tentar'),
                                ),
                              ),
                            ),
                          if (showFirstRunCoach && officialN == 0)
                            SurfacePanel(
                              margin: const EdgeInsets.only(bottom: 16),
                              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.45),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Comece pelo acervo', style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Com as provas UEMA na Biblioteca, o estudo fica alinhado à banca.',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      FilledButton(
                                        onPressed: () {
                                          _dismissFirstRunCoach();
                                          context.go('/biblioteca');
                                        },
                                        child: const Text('Ir à Biblioteca'),
                                      ),
                                      TextButton(onPressed: _dismissFirstRunCoach, child: const Text('Depois')),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                          SectionLabel('Checklist do dia', hint: progress.isEmpty ? null : progress),
                          _CheckRow(
                            done: checklist['session'] == true,
                            label: 'Sessão (~15+ min)',
                            actionLabel: 'Sessão',
                            onAction: () => context.go(sessionPath),
                          ),
                          FutureBuilder(
                            future: dueCardsFuture,
                            builder: (context, snap) {
                              if (!snap.hasData) {
                                return _CheckRow(
                                  done: false,
                                  label: 'Cards do dia…',
                                  actionLabel: null,
                                  onAction: null,
                                );
                              }
                              final list = snap.data is List ? snap.data as List : const [];
                              final n = list.length;
                              final done = n == 0 || checklist['cards'] == true;
                              return _CheckRow(
                                done: done,
                                label: n == 0 ? 'Cards em dia' : '$n card(s) para revisar',
                                actionLabel: n == 0 ? null : 'Cards',
                                onAction: n == 0 ? null : () => context.go('/flashcards?due=1'),
                              );
                            },
                          ),
                          _CheckRow(
                            done: checklist['revisions'] == true,
                            label: gapN > 0
                                ? '$gapN lacuna(s) aberta(s)'
                                : 'Revisões / lacunas em dia',
                            actionLabel: gapN > 0 || checklist['revisions'] != true ? 'Fila' : null,
                            onAction: () => context.go('/fila'),
                          ),
                          _CheckRow(
                            done: dayClosed,
                            label: dayClosed ? 'Dia encerrado' : 'Encerrar o dia',
                            actionLabel: dayClosed ? null : 'Fechar',
                            onAction: dayClosed ? null : _closeDay,
                          ),

                          const SizedBox(height: 8),
                          SectionLabel('Agora', hint: 'próximo passo · espelha Fila'),
                          if (gapN > 0)
                            for (final raw in gapItems.take(1))
                              Builder(
                                builder: (_) {
                                  final g = Map<String, dynamic>.from(raw as Map);
                                  final s = g['subject']?.toString() ?? '';
                                  final t = g['topic']?.toString() ?? '';
                                  return PlaylistTile(
                                    title: 'Retomar · $s',
                                    subtitle: t,
                                    badge: 'lacuna',
                                    leadingIcon: Icons.flag_rounded,
                                    onPlay: () => context.go(
                                      '/adaptativo?subject=${Uri.encodeComponent(s)}'
                                      '&topic=${Uri.encodeComponent(t)}',
                                    ),
                                  );
                                },
                              )
                          else if (hot.isNotEmpty)
                            Builder(
                              builder: (_) {
                                final item = Map<String, dynamic>.from(hot.first as Map);
                                final key = item['key']?.toString() ?? '';
                                final parts = key.split('::');
                                final s = parts.isNotEmpty ? parts[0] : '';
                                final t = parts.length > 1 ? parts[1] : '';
                                return PlaylistTile(
                                  title: s.isEmpty ? key : s,
                                  subtitle: t.isEmpty ? 'Reforçar' : t,
                                  badge: 'reforçar',
                                  leadingIcon: Icons.replay_rounded,
                                  onPlay: s.isEmpty
                                      ? null
                                      : () => context.go(
                                            '/adaptativo?subject=${Uri.encodeComponent(s)}'
                                            '&topic=${Uri.encodeComponent(t)}',
                                          ),
                                );
                              },
                            )
                          else
                            QuietEmpty(
                              message: routine['hint']?.toString() ?? 'Pode partir para a sessão.',
                              action: TextButton(
                                onPressed: () => context.go(sessionPath),
                                child: const Text('Sessão'),
                              ),
                            ),

                          Consumer(
                            builder: (context, ref, _) {
                              final prog = ref.watch(essayProgressProvider).asData?.value;
                              if (prog == null) return const SizedBox.shrink();
                              final c = prog['count'] as int? ?? 0;
                              final mission = prog['nextMission'];
                              if (c < 1 || mission is! Map) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: PlaylistTile(
                                  title: 'Missão de redação · ${mission['label'] ?? 'eixo'}',
                                  subtitle: 'treino local · não banca',
                                  badge: 'missão',
                                  leadingIcon: Icons.edit_note_rounded,
                                  onPlay: () => context.go('/redacao'),
                                ),
                              );
                            },
                          ),

                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            initiallyExpanded: false,
                            title: Text('Mais do dia', style: Theme.of(context).textTheme.titleSmall),
                            subtitle: const Text('semana, pulso, ritmo e atalhos'),
                            children: [
                              if (week.isNotEmpty) ...[
                                SectionLabel('Semana', hint: week['hint']?.toString()),
                                SurfacePanel(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        week['label']?.toString() ?? 'Semana',
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(
                                        value: ((week['minutesPercent'] as num?) ?? 0) / 100.0,
                                        minHeight: 6,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${week['minutes'] ?? 0}/${week['goalMinutes'] ?? 300} min · '
                                        '${week['daysActive'] ?? 0}/${week['goalDays'] ?? 5} dias · '
                                        'streak ${week['streakDays'] ?? data['streakDays'] ?? 0}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              Builder(
                                builder: (_) {
                                  final wc = Map<String, dynamic>.from(data['weekClose'] as Map? ?? const {});
                                  if (wc.isEmpty) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: WeekClosePanel(
                                      weekClose: wc,
                                      onCloseWeek: _closeWeek,
                                    ),
                                  );
                                },
                              ),
                              FutureBuilder(
                                future: apiClient.get('/api/backup/last'),
                                builder: (context, snap) {
                                  if (!snap.hasData || snap.data is! Map) return const SizedBox.shrink();
                                  final last = Map<String, dynamic>.from(snap.data as Map);
                                  final hasOk = last['ok'] == true;
                                  String? staleMsg;
                                  if (!hasOk) {
                                    staleMsg = 'Nenhum backup verificado — salve em Ajustes.';
                                  } else {
                                    final at = last['at']?.toString() ?? '';
                                    if (at.isNotEmpty) {
                                      try {
                                        final when = DateTime.parse(at);
                                        if (DateTime.now().difference(when).inDays > 7) {
                                          staleMsg = 'Último backup há mais de 7 dias ($at).';
                                        }
                                      } catch (_) {
                                        staleMsg = 'Data do último backup inválida — refaça em Ajustes.';
                                      }
                                    }
                                  }
                                  if (staleMsg == null) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: QuietEmpty(
                                      message: staleMsg,
                                      action: TextButton(
                                        onPressed: () => context.go('/configuracoes'),
                                        child: const Text('Fazer backup'),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (readyScore != null) ...[
                                const SizedBox(height: 12),
                                SectionLabel('Pulso local', hint: 'Não é probabilidade de aprovação UEMA'),
                                SurfacePanel(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        readiness['label']?.toString() ?? 'Pulso',
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Indicador ${readyScore.toStringAsFixed(0)}/100',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(
                                        value: (readyScore / 100).clamp(0.0, 1.0),
                                        minHeight: 6,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      if (readiness['tip'] != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          readiness['tip'].toString(),
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                              if (calItems.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                SectionLabel('28 dias', hint: calendar['hint']?.toString()),
                                SurfacePanel(
                                  child: Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: [
                                      for (final raw in calItems)
                                        Builder(
                                          builder: (cellCtx) {
                                            final it = Map<String, dynamic>.from(raw as Map);
                                            final active = it['active'] == true;
                                            final closed = it['closed'] == true;
                                            final isToday = it['isToday'] == true;
                                            final date = it['date']?.toString() ?? '';
                                            final cs = Theme.of(context).colorScheme;
                                            Color bg;
                                            if (closed) {
                                              bg = cs.primary.withOpacity(0.85);
                                            } else if (active) {
                                              bg = cs.primary.withOpacity(0.35);
                                            } else {
                                              bg = cs.onSurface.withOpacity(0.08);
                                            }
                                            String statusLine;
                                            if (closed && active) {
                                              statusLine = 'estudou e encerrou o dia';
                                            } else if (closed) {
                                              statusLine = 'encerrou o dia (sem resposta registrada)';
                                            } else if (active) {
                                              statusLine = 'estudou (resposta registrada)';
                                            } else {
                                              statusLine = 'sem estudo registrado';
                                            }
                                            final tip = date.isEmpty
                                                ? statusLine
                                                : '$date · $statusLine';
                                            return Tooltip(
                                              message: tip,
                                              child: Semantics(
                                                label: tip,
                                                button: true,
                                                child: InkWell(
                                                  onTap: () {
                                                    showModalBottomSheet<void>(
                                                      context: cellCtx,
                                                      showDragHandle: true,
                                                      builder: (sheetCtx) {
                                                        return Padding(
                                                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                                                          child: Column(
                                                            mainAxisSize: MainAxisSize.min,
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                date.isEmpty ? 'Dia' : date,
                                                                style: Theme.of(sheetCtx)
                                                                    .textTheme
                                                                    .titleMedium
                                                                    ?.copyWith(fontWeight: FontWeight.w800),
                                                              ),
                                                              const SizedBox(height: 8),
                                                              Text(statusLine),
                                                              const SizedBox(height: 6),
                                                              Text(
                                                                'Só histórico local — dia sem estudo não inventa atividade.',
                                                                style: Theme.of(sheetCtx)
                                                                    .textTheme
                                                                    .bodySmall
                                                                    ?.copyWith(
                                                                      color: Theme.of(sheetCtx)
                                                                          .colorScheme
                                                                          .onSurface
                                                                          .withOpacity(0.6),
                                                                    ),
                                                              ),
                                                              if (isToday) ...[
                                                                const SizedBox(height: 12),
                                                                Text(
                                                                  'Hoje',
                                                                  style: TextStyle(
                                                                    color: Theme.of(sheetCtx).colorScheme.primary,
                                                                    fontWeight: FontWeight.w700,
                                                                  ),
                                                                ),
                                                                const SizedBox(height: 8),
                                                                Wrap(
                                                                  spacing: 8,
                                                                  runSpacing: 8,
                                                                  children: [
                                                                    FilledButton(
                                                                      onPressed: () {
                                                                        Navigator.pop(sheetCtx);
                                                                        context.go(sessionPath);
                                                                      },
                                                                      child: const Text('Sessão'),
                                                                    ),
                                                                    if (!closed && !dayClosed)
                                                                      OutlinedButton(
                                                                        onPressed: () {
                                                                          Navigator.pop(sheetCtx);
                                                                          unawaited(_closeDay());
                                                                        },
                                                                        child: const Text('Encerrar dia'),
                                                                      ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                  borderRadius: BorderRadius.circular(2),
                                                  child: Container(
                                                    width: 12,
                                                    height: 12,
                                                    decoration: BoxDecoration(
                                                      color: bg,
                                                      borderRadius: BorderRadius.circular(2),
                                                      border: isToday
                                                          ? Border.all(color: cs.primary, width: 1.5)
                                                          : null,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                              if (backupReminder != null)
                                QuietEmpty(
                                  message: backupReminder,
                                  action: TextButton(
                                    onPressed: () => context.go('/configuracoes'),
                                    child: const Text('Ajustes'),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              SectionLabel('Seu ritmo'),
                              StatsStrip(
                                items: [
                                  ('${data['streakDays'] ?? 0}', 'dias seguidos'),
                                  ('${data['studyMinutesToday'] ?? 0}', 'min hoje'),
                                  ('${((data['accuracy'] as num? ?? 0) * 100).toStringAsFixed(0)}%', 'acerto'),
                                ],
                              ),
                              if (!focus) ...[
                                SectionLabel('Explorar'),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ActionChip(
                                      avatar: const Icon(Icons.playlist_play_rounded, size: 18),
                                      label: const Text('Fila'),
                                      onPressed: () => context.go('/fila'),
                                    ),
                                    ActionChip(
                                      avatar: const Icon(Icons.local_hospital_rounded, size: 18),
                                      label: const Text('Domínio'),
                                      onPressed: () => context.go('/medicina'),
                                    ),
                                    ActionChip(
                                      avatar: const Icon(Icons.menu_book_rounded, size: 18),
                                      label: const Text('Biblioteca'),
                                      onPressed: () => context.go('/biblioteca'),
                                    ),
                                    ActionChip(
                                      avatar: const Icon(Icons.bolt_rounded, size: 18),
                                      label: const Text('Simulados'),
                                      onPressed: () => context.go('/simulados'),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Modo foco — só sessão e checklist. Desligue com F.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                              if (exam.isNotEmpty && examDays != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  examDays >= 0 ? 'Prova: $exam' : 'Data da prova: $exam',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
        );
      },
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.done,
    required this.label,
    this.actionLabel,
    this.onAction,
  });

  final bool done;
  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: done ? cs.primary : cs.onSurface.withOpacity(0.35),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done ? cs.onSurface.withOpacity(0.55) : null,
                  ),
            ),
          ),
          if (actionLabel != null && onAction != null && !done)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
