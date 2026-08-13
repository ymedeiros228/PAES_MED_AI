import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/data/study_prefs_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/tour_overlay.dart';
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
  // Futures cached para evitar recriar a cada rebuild (performance)
  late final Future<dynamic> _essayProgressFuture;
  late final Future<dynamic> _backupLastFuture;
  late final Future<dynamic> _dueCardsFuture;
  late final Future<dynamic> _gamificationFuture;

  @override
  void initState() {
    super.initState();
    _essayProgressFuture = apiClient.get('/api/essays/progress');
    _backupLastFuture = apiClient.get('/api/backup/last');
    _dueCardsFuture = apiClient.get('/api/flashcards?dueOnly=true');
    _gamificationFuture = apiClient.get('/api/gamification');
    _loadCheckpoint();
    _loadFirstRunCoach();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
      final exam = ref.read(examDateProvider).date;
      if (exam.isNotEmpty) {
        unawaited(ref.read(examDateProvider.notifier).retrySync());
      }
      if (mounted) {
        TourOverlay.maybeShow(
          context,
          key: 'tour_dashboard_v1',
          title: 'Bem-vindo ao Inicio',
          body: 'Aqui voce ve tudo: seu nivel de XP, streak de estudo, '
              'topico do dia, flashcards para revisar e atalhos rapidos. '
              'Aperte "Estudar" para comecar.',
          icon: Icons.home_rounded,
        );
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
          fallback: 'Sessão salva indisponível agora.',
        );
      });
    }
  }

  Future<void> _discardCheckpoint() async {
    // Confirma antes de descartar — checkpoint pode ter progresso significativo.
    final phase = checkpoint != null ? _checkpointShort(checkpoint!) : '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar sessão?'),
        content: Text(
          phase.isNotEmpty
              ? 'Você tem uma sessão em andamento ($phase). '
                  'Descartar significa perder esse progresso.'
              : 'Descartar a sessão salva? Você vai começar do zero na próxima.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Descartar')),
        ],
      ),
    );
    if (confirmed != true) return;
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
      HapticFeedback.mediumImpact();
      // Confete se o dia foi completo (todos os itens do checklist)
      final checklist = map['checklist'] is Map
          ? Map<String, dynamic>.from(map['checklist'] as Map)
          : <String, dynamic>{};
      final allDone = checklist['session'] == true &&
          checklist['cards'] == true &&
          checklist['revisions'] == true;
      if (allDone || map['complete'] == true) {
        ConfettiBurst.fire(context);
      }
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
      loading: () => PageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(title: 'Hoje', eyebrow: 'PAES MED AI'),
            const SkeletonCard(lines: 3),
            const SizedBox(height: 12),
            const SkeletonCard(lines: 2),
            const SizedBox(height: 12),
            const SkeletonCard(lines: 2),
          ],
        ),
      ),
      error: (e, _) => EmptyState(
        title: 'Não foi possível carregar',
        subtitle: humanApiError(e, fallback: 'Reabra pelo ícone PAES MED AI na área de trabalho.'),
        action: Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          children: [
            TapScale(
              child: FilledButton(
                onPressed: () => ref.read(refreshTickProvider.notifier).state++,
                child: const Text('Tentar de novo'),
              ),
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
        final cs = Theme.of(context).colorScheme;
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
        // Semana 1 OK = base oficial mínima (2024–26 importados em uso real)
        final semana1Ok = officialN >= 30;
        // Coach some só com Semana 1 ok — não com 1 oficial solto
        if (showFirstRunCoach && semana1Ok) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && showFirstRunCoach) unawaited(_dismissFirstRunCoach());
          });
        }
        final openGaps = data['openGaps'] as Map?;
        final gapItems = openGaps?['items'] as List? ?? const [];
        final gapN = openGaps?['openCount'] as int? ?? gapItems.length;
        final hot = (data['errorHotTopics'] as List? ?? []).take(2).toList();
        final dueCardsFuture = _dueCardsFuture;
        final readyScore = (readiness['score'] as num?)?.toDouble();
        final calItems = calendar['items'] as List? ?? const [];

        return Focus(
          focusNode: _focusNode,
          onKeyEvent: (node, event) => _onKey(node, event, sessionPath, closePath),
          child: CustomScrollView(
          slivers: [
            // Hero compacto: gradient + countdown + CTA principal
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient(Theme.of(context).brightness),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contagem regressiva destacada
                    if (examDays != null && examDays >= 0) ...[
                      Text(
                        '$examDays',
                        style: GoogleFonts.poppins(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'dias para a prova',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'PAES MED AI',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Medicina · UEMA',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Coach line — uma frase curta
                    Text(
                      coachLine,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        color: Colors.white,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    // CTA principal + ação secundária
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        TapScale(
                          child: PulseButton(
                            pulse: checkpoint != null,
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              context.go(sessionPath);
                            },
                            child: Text(
                              checkpoint != null
                                  ? 'Continuar · ${_checkpointShort(checkpoint!)}'
                                  : 'Começar sessão',
                            ),
                          ),
                        ),
                        if (checkpoint != null)
                          OutlinedButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              _discardCheckpoint();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withOpacity(0.4)),
                            ),
                            child: const Text('Recomeçar'),
                          ),
                      ],
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
                          if (showFirstRunCoach && !semana1Ok)
                            SurfacePanel(
                              margin: const EdgeInsets.only(bottom: 16),
                              color: Theme.of(context).colorScheme.primaryContainer.f45,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Primeiros passos',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    officialN > 0
                                        ? 'Você já tem $officialN questões oficiais. '
                                            'Acesse a Biblioteca para importar mais provas.'
                                        : 'Acesse a Biblioteca para importar as provas oficiais da UEMA '
                                            'e comece a estudar.',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: cs.onSurface.withOpacity(0.85),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      TapScale(
                                        child: FilledButton(
                                          onPressed: () {
                                            context.go('/biblioteca?semana1=1');
                                          },
                                          child: const Text('Ir à Biblioteca'),
                                        ),
                                      ),
                                      TextButton(onPressed: _dismissFirstRunCoach, child: const Text('Depois')),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                          // Card de gamificacao + atalhos rapidos
                          FutureBuilder(
                            future: _gamificationFuture,
                            builder: (context, snap) {
                              if (!snap.hasData || snap.data is! Map) return const SizedBox.shrink();
                              final g = Map<String, dynamic>.from(snap.data as Map);
                              return _DashboardGamificationCard(data: g);
                            },
                          ),
                          const SizedBox(height: 16),
                          // Atalhos rapidos
                          _QuickActionsGrid(),
                          const SizedBox(height: 16),
                          // Topico do dia + flashcards due
                          _TodayTopicAndCardsRow(
                            dueCardsFuture: _dueCardsFuture,
                            todayTopic: data['studyToday'] is Map
                                ? Map<String, dynamic>.from(data['studyToday'] as Map)
                                : null,
                          ),
                          const SizedBox(height: 16),
                          // StaggeredFadeIn: entrada escalonada do checklist (anel → itens)
                          StaggeredFadeIn(
                            children: [
                              SectionLabel('Checklist do dia', hint: progress.isEmpty ? null : progress),
                              // Anel de progresso do dia — RepaintBoundary isola a animação
                              RepaintBoundary(
                                child: _DayProgressRing(
                                  sessionDone: checklist['session'] == true,
                                  cardsDone: checklist['cards'] == true,
                                  revisionsDone: checklist['revisions'] == true,
                                  dayClosed: dayClosed,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Meta diária
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.flag_outlined, size: 16, color: cs.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Meta: ${ref.watch(dailyGoalProvider)}min/dia',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withOpacity(0.6)),
                                    ),
                                    const Spacer(),
                                    if (examDaysLocal != null && examDaysLocal > 0)
                                      Text(
                                        '$examDaysLocal dias até a prova',
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary),
                                      ),
                                  ],
                                ),
                              ),
                              StudyCheckRow(
                                done: checklist['session'] == true,
                                label: 'Sessão de estudo',
                                actionLabel: 'Estudar',
                                onAction: () => context.go(sessionPath),
                              ),
                              FutureBuilder(
                                future: dueCardsFuture,
                                builder: (context, snap) {
                                  if (!snap.hasData) {
                                    return const StudyCheckRow(
                                      done: false,
                                      label: 'Flashcards do dia…',
                                    );
                                  }
                                  final list = snap.data is List ? snap.data as List : const [];
                                  final n = list.length;
                                  final done = n == 0 || checklist['cards'] == true;
                                  return StudyCheckRow(
                                    done: done,
                                    label: n == 0 ? 'Flashcards em dia' : '$n flashcard(s) para revisar',
                                    actionLabel: n == 0 ? null : 'Revisar',
                                    onAction: n == 0 ? null : () => context.go('/flashcards?due=1'),
                                  );
                                },
                              ),
                              StudyCheckRow(
                                done: checklist['revisions'] == true,
                                label: gapN > 0
                                    ? '$gapN tópico(s) para revisar'
                                    : 'Revisões em dia',
                                actionLabel: gapN > 0 || checklist['revisions'] != true ? 'Ver fila' : null,
                                onAction: () => context.go('/fila'),
                              ),
                              StudyCheckRow(
                                done: dayClosed,
                                label: dayClosed ? 'Dia encerrado' : 'Encerrar o dia',
                                actionLabel: dayClosed ? null : 'Fechar',
                                onAction: dayClosed ? null : _closeDay,
                              ),
                            ],
                          ),

                          // StaggeredFadeIn: entrada suave da missão de redação
                          StaggeredFadeIn(
                            children: [
                              MissionQuestCard(
                                title: 'Treino de redação',
                                why: 'Pratique a redação com temas baseados no que você precisa melhorar.',
                                ctaLabel: 'Praticar',
                                status: MissionQuestStatus.open,
                                onCta: () => context.go('/redacao'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          SectionLabel('Próximo passo', hint: 'baseado na sua fila'),
                          if (gapN > 0)
                            for (final raw in gapItems.take(1))
                              Builder(
                                builder: (_) {
                                  final g = Map<String, dynamic>.from(raw as Map);
                                  final s = g['subject']?.toString() ?? '';
                                  final t = g['topic']?.toString() ?? '';
                                  return PlaylistTile(
                                    title: 'Revisar · $s',
                                    subtitle: t,
                                    badge: 'revisar',
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

                          FutureBuilder(
                            future: _essayProgressFuture,
                            builder: (context, snap) {
                              if (snap.connectionState == ConnectionState.waiting) {
                                return const CompactStatus(
                                  message: 'Carregando treino de redação…',
                                  icon: Icons.hourglass_empty_rounded,
                                );
                              }
                              if (snap.hasError || snap.data is! Map) {
                                return const CompactStatus(
                                  message: 'Treino de redação indisponível agora.',
                                  icon: Icons.sync_problem_outlined,
                                );
                              }
                              final prog = Map<String, dynamic>.from(snap.data as Map);
                              final c = prog['count'] as int? ?? 0;
                              final mission = prog['nextMission'];
                              if (c < 1 || mission is! Map) {
                                return const CompactStatus(
                                  message: 'Nenhum treino de redação disponível.',
                                  icon: Icons.edit_note_outlined,
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: PlaylistTile(
                                  title: 'Redação · ${mission['label'] ?? 'tema'}',
                                  subtitle: 'prática de redação',
                                  badge: 'redação',
                                  leadingIcon: Icons.edit_note_rounded,
                                  onPlay: () => context.go('/redacao'),
                                ),
                              );
                            },
                          ),

                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            initiallyExpanded: true,
                            title: Text(
                              'Mais do dia',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              'semana, progresso e ritmo',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: cs.onSurface.f72,
                              ),
                            ),
                            children: [
                              PlaylistTile(
                                title: 'Ver meu relevo',
                                subtitle: 'Picos firmes e vales a treinar · progresso local',
                                badge: 'mapa',
                                leadingIcon: Icons.terrain_rounded,
                                onPlay: () => context.go('/progresso'),
                              ),
                              if (week.isNotEmpty) ...[
                                SectionLabel('Semana', hint: week['hint']?.toString()),
                                SurfacePanel(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        week['label']?.toString() ?? 'Semana',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      LinearProgressIndicator(
                                        value: ((week['minutesPercent'] as num?) ?? 0) / 100.0,
                                        minHeight: 6,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${week['minutes'] ?? 0}/${week['goalMinutes'] ?? 300} min · '
                                        '${week['daysActive'] ?? 0}/${week['goalDays'] ?? 5} dias · '
                                        'streak ${week['streakDays'] ?? data['streakDays'] ?? 0}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: cs.onSurface.f72,
                                          fontFeatures: const [FontFeature.tabularFigures()],
                                        ),
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
                                    child: RepaintBoundary(
                                      child: WeekClosePanel(
                                        weekClose: wc,
                                        onCloseWeek: _closeWeek,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              FutureBuilder(
                                future: _backupLastFuture,
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
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Indicador ${readyScore.toStringAsFixed(0)}/100',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: cs.onSurface.f55,
                                          fontFeatures: const [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      LinearProgressIndicator(
                                        value: (readyScore / 100).clamp(0.0, 1.0),
                                        minHeight: 6,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      if (readiness['tip'] != null) ...[
                                        const SizedBox(height: 10),
                                        SelectableText(
                                          readiness['tip'].toString(),
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: cs.onSurface.f72,
                                            height: 1.5,
                                          ),
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
                                              bg = cs.primary.f85;
                                            } else if (active) {
                                              bg = cs.primary.f35;
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
                                                    HapticFeedback.selectionClick();
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
                                                                    TapScale(
                                                                      child: FilledButton(
                                                                        onPressed: () {
                                                                          Navigator.pop(sheetCtx);
                                                                          context.go(sessionPath);
                                                                        },
                                                                        child: const Text('Sessão'),
                                                                      ),
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
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: SizedBox(
                                                    width: 32,
                                                    height: 32,
                                                    child: Center(
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
                              // StaggeredFadeIn: entrada escalonada do pulo de ritmo
                              StaggeredFadeIn(
                                children: [
                                  SectionLabel('Seu ritmo'),
                                  RepaintBoundary(
                                    child: StatsStrip(
                                      items: [
                                        ('${data['streakDays'] ?? 0}', 'dias seguidos'),
                                        ('${data['studyMinutesToday'] ?? 0}', 'min hoje'),
                                        ('${((data['accuracy'] as num? ?? 0) * 100).toStringAsFixed(0)}%', 'acerto'),
                                      ],
                                    ),
                                  ),
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
                                      label: const Text('Áreas'),
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
                                    ActionChip(
                                      avatar: const Icon(Icons.center_focus_strong_rounded, size: 18),
                                      label: const Text('Modo Foco'),
                                      onPressed: () => context.go('/foco'),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Modo foco ativado — só o essencial. Desligue no menu lateral.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: cs.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                              if (exam.isNotEmpty && examDays != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  examDays >= 0 ? 'Prova: $exam' : 'Data da prova: $exam',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: cs.onSurface.f45,
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

/// Anel de progresso circular do dia — mostra visualmente quantos itens
/// do checklist foram concluídos (sessão, cartões, revisões, encerrar dia).
class _DayProgressRing extends StatefulWidget {
  const _DayProgressRing({
    required this.sessionDone,
    required this.cardsDone,
    required this.revisionsDone,
    required this.dayClosed,
  });

  final bool sessionDone;
  final bool cardsDone;
  final bool revisionsDone;
  final bool dayClosed;

  @override
  State<_DayProgressRing> createState() => _DayProgressRingState();
}

class _DayProgressRingState extends State<_DayProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_DayProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionDone != widget.sessionDone ||
        oldWidget.cardsDone != widget.cardsDone ||
        oldWidget.revisionsDone != widget.revisionsDone ||
        oldWidget.dayClosed != widget.dayClosed) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // 4 itens no checklist
    final doneCount = [
      widget.sessionDone,
      widget.cardsDone,
      widget.revisionsDone,
      widget.dayClosed,
    ].where((d) => d).length;
    final total = 4;
    final targetProgress = doneCount / total;

    // Mensagem motivacional baseada no progresso
    final message = switch (doneCount) {
      0 => 'Bom começo! Que tal uma sessão?',
      1 => 'Já começou — siga assim.',
      2 => 'Metade do caminho. Continue.',
      3 => 'Quase lá — só falta encerrar.',
      _ => 'Dia completo. Descanse.',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Anel circular animado
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: targetProgress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Trilha de fundo
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 5,
                      color: cs.surfaceContainerHighest,
                    ),
                    // Progresso
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 5,
                      color: doneCount == total ? cs.primary : cs.tertiary,
                      strokeCap: StrokeCap.round,
                    ),
                    // Texto central
                    Center(
                      child: Text(
                        '$doneCount/$total',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                if (doneCount == total)
                  Text(
                    'Dia encerrado — volte amanhã',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _DashboardGamificationCard extends StatelessWidget {
  const _DashboardGamificationCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final level = data['level'] ?? 1;
    final levelTitle = data['levelTitle'] ?? 'Iniciante';
    final xp = data['xp'] ?? 0;
    final progress = (data['levelProgress'] ?? 0.0) as double;
    final unlocked = data['unlockedCount'] ?? 0;
    final total = data['totalAchievements'] ?? 0;
    final streak = data['stats'] is Map ? (data['stats']['streakDays'] ?? 0) : 0;
    final next = data['nextAchievement'] as Map?;

    return SurfacePanel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.primaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$level',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cs.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nivel $level - $levelTitle',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        '$xp XP - $unlocked/$total medalhas',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Streak visual
                if (streak is int && streak > 0) ...[
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: const Color(0xFFE8A04B),
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$streak',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE8A04B),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(cs.primary),
              ),
            ),
            if (next != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.emoji_events_outlined, size: 14, color: cs.onSurface.withOpacity(0.5)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Proxima: ${next['title']} (${((next['progress'] ?? 0) * 100).round()}%)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                  TapScale(
                    child: TextButton(
                      onPressed: () => context.go('/conquistas'),
                      child: const Text('Ver todas'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final actions = [
      ('Estudar', Icons.school_rounded, '/sessao?examBoard=UEMA_PAES&preferNatureza=1', cs.primary),
      ('Flashcards', Icons.style_rounded, '/flashcards', cs.secondary),
      ('Tutor IA', Icons.auto_awesome_rounded, '/tutor', const Color(0xFF8B5CF6)),
      ('Redacao', Icons.edit_note_rounded, '/redacao', const Color(0xFFE8A04B)),
      ('Simulado', Icons.bolt_rounded, '/simulados', const Color(0xFFD3544A)),
      ('Aulas', Icons.video_library_rounded, '/aulas', cs.tertiary),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        for (final a in actions)
          TapScale(
            child: Material(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.go(a.$3);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(a.$2, color: a.$4, size: 28),
                    const SizedBox(height: 6),
                    Text(
                      a.$1,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}


class _TodayTopicAndCardsRow extends StatelessWidget {
  const _TodayTopicAndCardsRow({required this.dueCardsFuture, this.todayTopic});
  final Future<dynamic> dueCardsFuture;
  final Map<String, dynamic>? todayTopic;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _TopicCard(topic: todayTopic)),
        const SizedBox(width: 10),
        Expanded(
          child: FutureBuilder(
            future: dueCardsFuture,
            builder: (context, snap) {
              final list = snap.data is List ? snap.data as List : const [];
              final n = list.length;
              return _DueCardsCard(dueCount: n);
            },
          ),
        ),
      ],
    );
  }
}


class _TopicCard extends StatelessWidget {
  const _TopicCard({this.topic});
  final Map<String, dynamic>? topic;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final subj = topic?['subject']?.toString() ?? '';
    final top = topic?['topic']?.toString() ?? '';
    final hasTopic = subj.isNotEmpty && top.isNotEmpty;

    return SurfacePanel(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  'Topico do dia',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (hasTopic) ...[
              Text(
                subj,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                top,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: cs.onSurface.withOpacity(0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              TapScale(
                child: FilledButton.tonal(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    final nat = const {'Biologia', 'Quimica', 'Fisica'}.contains(subj);
                    context.go('/sessao?examBoard=UEMA_PAES'
                        '&subject=${Uri.encodeComponent(subj)}'
                        '&topic=${Uri.encodeComponent(top)}'
                        '&preferNatureza=${nat ? '1' : '0'}');
                  },
                  child: const Text('Estudar'),
                ),
              ),
            ] else
              Text(
                'Nenhum topico planejado',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class _DueCardsCard extends StatelessWidget {
  const _DueCardsCard({required this.dueCount});
  final int dueCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SurfacePanel(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.style_rounded, size: 18, color: cs.secondary),
                const SizedBox(width: 6),
                Text(
                  'Flashcards',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$dueCount',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: dueCount > 0 ? cs.secondary : cs.onSurface.withOpacity(0.3),
              ),
            ),
            Text(
              dueCount > 0 ? 'para revisar hoje' : 'tudo em dia!',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 10),
            if (dueCount > 0)
              TapScale(
                child: FilledButton.tonal(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.go('/flashcards');
                  },
                  child: const Text('Revisar'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
