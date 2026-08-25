import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import 'dashboard_update_banner.dart';
import '../../../core/data/study_prefs_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/tour_overlay.dart';
import '../../../core/widgets/ui_kit.dart';

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
  // Futures cached para evitar recriar a cada rebuild (performance)
  late final Future<dynamic> _recommendationsFuture;

  @override
  void initState() {
    super.initState();
    _recommendationsFuture = apiClient.get('/api/coach/recommendations');
    _loadCheckpoint();
    _loadFirstRunCoach();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final exam = ref.read(examDateProvider).date;
      if (exam.isNotEmpty) {
        unawaited(ref.read(examDateProvider.notifier).retrySync());
      }
      if (mounted) {
        TourOverlay.maybeShow(
          context,
          key: 'tour_dashboard_v1',
          title: 'Bem-vindo ao Início',
          body: 'Aqui você vê tudo: seu nível de XP, streak de estudo, '
              'tópico do dia, flashcards para revisar e atalhos rápidos. '
              'Aperte "Estudar" para começar.',
          icon: Icons.home_rounded,
        );
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dashboardProvider);
    final examDaysLocal = ref.watch(examDateProvider.notifier).daysUntilExam;

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
        final dayClosed = routine['dayClosed'] == true || checklist['dayClosed'] == true;
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

        return CustomScrollView(
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
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'dias para a prova',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'PAES MED AI',
                        style: TextStyle(
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
                        style: TextStyle(
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
                      style: TextStyle(
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
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: cs.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    officialN > 0
                                        ? 'Você já tem $officialN questões oficiais. '
                                            'Acesse a Biblioteca para importar mais provas.'
                                        : 'Acesse a Biblioteca para importar as provas oficiais da UEMA '
                                            'e comece a estudar.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: cs.onPrimaryContainer.withOpacity(0.9),
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

                          // Notificacao de atualizacao disponivel
                          const UpdateBanner(),
                          const SizedBox(height: 20),

                          // Atalhos rapidos - 4 cards grandes e limpos
                          _SimpleQuickActions(
                            cs: cs,
                            sessionPath: sessionPath,
                            officialN: officialN,
                            flashcardsDue: data['flashcardsDueCount'] as int? ?? 0,
                          ),
                          const SizedBox(height: 20),

                          // XP + Streak + Tópico do dia + Flashcards due (linha integrada)
                          _DashboardStatsRow(
                            cs: cs,
                            streakDays: data['streakDays'] as int? ?? 0,
                            studyToday: data['studyToday'] as Map?,
                            flashcardsDue: data['flashcardsDueCount'] as int? ?? 0,
                            sessionPath: sessionPath,
                          ),
                          const SizedBox(height: 20),

                          // Mini-gráfico de evolução da semana (7 barras)
                          _WeekMiniChart(
                            cs: cs,
                            weekProgress: data['weekProgress'] as Map?,
                            studyCalendar: (data['studyCalendar'] as Map?)?['items'] as List?,
                          ),
                          const SizedBox(height: 20),

                          // Recomendacao do dia - um card simples
                          FutureBuilder(
                            future: _recommendationsFuture,
                            builder: (context, snap) {
                              if (!snap.hasData || snap.data is! Map) return const SizedBox.shrink();
                              final recs = Map<String, dynamic>.from(snap.data as Map);
                              return _SimpleRecommendationCard(recommendations: recs, cs: cs);
                            },
                          ),
                          const SizedBox(height: 20),

                          // Checklist simples do dia
                          _SimpleChecklist(
                            cs: cs,
                            sessionDone: checklist['session'] == true,
                            cardsDone: checklist['cards'] == true,
                            revisionsDone: checklist['revisions'] == true,
                            dayClosed: dayClosed,
                            gapN: gapN,
                            onSession: () => context.go(sessionPath),
                            onCards: () => context.go('/flashcards?due=1'),
                            onRevisions: () => context.go('/fila'),
                            onCloseDay: dayClosed ? null : _closeDay,
                            examDays: examDaysLocal,
                            dailyGoal: ref.watch(dailyGoalProvider),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ===========================================================================
// NOVOS WIDGETS: XP/Streak + Tópico do dia + Flashcards due + Mini-gráfico
// ===========================================================================

/// Linha com XP/streak + tópico do dia + flashcards due (3 cards integrados)
class _DashboardStatsRow extends StatelessWidget {
  const _DashboardStatsRow({
    required this.cs,
    required this.streakDays,
    required this.studyToday,
    required this.flashcardsDue,
    required this.sessionPath,
  });
  final ColorScheme cs;
  final int streakDays;
  final Map? studyToday;
  final int flashcardsDue;
  final String sessionPath;

  @override
  Widget build(BuildContext context) {
    final study = studyToday != null ? Map<String, dynamic>.from(studyToday!) : null;
    final subj = study?['subject']?.toString() ?? '';
    final topic = study?['topic']?.toString() ?? '';
    final hasTopic = subj.isNotEmpty && topic.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Linha 1: Streak + Flashcards due
        Row(
          children: [
            Expanded(
              child: _StatCard(
                cs: cs,
                icon: Icons.local_fire_department_rounded,
                value: '$streakDays',
                label: 'dias seguidos',
                color: cs.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                cs: cs,
                icon: Icons.style_rounded,
                value: '$flashcardsDue',
                label: 'flashcards hoje',
                color: cs.tertiary,
                onTap: flashcardsDue > 0 ? () => context.go('/flashcards?due=1') : null,
              ),
            ),
          ],
        ),
        if (hasTopic) ...[
          const SizedBox(height: 12),
          // Tópico do dia
          Material(
            color: cs.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.go(sessionPath),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.today_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tópico do dia',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withOpacity(0.5),
                            ),
                          ),
                          Text(
                            '$subj · $topic',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.play_arrow_rounded, color: cs.primary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Card de estatística individual (streak, flashcards, etc)
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.cs,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });
  final ColorScheme cs;
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cs.surfaceContainerHighest.withOpacity(0.3),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mini-gráfico de evolução da semana (7 barras)
class _WeekMiniChart extends StatelessWidget {
  const _WeekMiniChart({
    required this.cs,
    required this.weekProgress,
    required this.studyCalendar,
  });
  final ColorScheme cs;
  final Map? weekProgress;
  final List? studyCalendar;

  @override
  Widget build(BuildContext context) {
    // studyCalendar tem 28 dias com {date, active, closed, isToday, weekday}
    final calendar = studyCalendar ?? [];
    final last7 = calendar.length >= 7
        ? calendar.sublist(calendar.length - 7)
        : calendar;
    // Cada item: active=true -> barra cheia, closed=true -> meia barra, resto -> vazio
    final bars = <bool>[]; // active
    final closed = <bool>[]; // closed
    for (final item in last7) {
      if (item is Map) {
        bars.add(item['active'] == true);
        closed.add(item['closed'] == true);
      } else {
        bars.add(false);
        closed.add(false);
      }
    }
    final weekLabel = weekProgress?['label']?.toString() ?? 'Esta semana';
    final daysActive = weekProgress?['daysActive'] as int? ?? 0;
    final goalDays = weekProgress?['goalDays'] as int? ?? 5;
    final dayLabels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

    return SurfacePanel(
      color: cs.surfaceContainerHighest.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Evolução da semana',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '$daysActive/$goalDays dias',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              weekLabel,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withOpacity(0.5),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            if (bars.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Sem dados ainda',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 80,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < bars.length; i++) ...[
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Container(
                                width: double.infinity,
                                height: bars[i] ? 60 : (closed[i] ? 30 : 6),
                                constraints: const BoxConstraints(minHeight: 4),
                                decoration: BoxDecoration(
                                  color: bars[i]
                                      ? cs.primary.withOpacity(0.8)
                                      : closed[i]
                                          ? cs.primary.withOpacity(0.4)
                                          : cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              i < dayLabels.length ? dayLabels[i] : '',
                              style: TextStyle(
                                fontSize: 10,
                                color: cs.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i < bars.length - 1) const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets simplificados para o dashboard limpo
// ---------------------------------------------------------------------------

/// 4 atalhos grandes e claros — sem redundância com o hero.
class _SimpleQuickActions extends StatelessWidget {
  const _SimpleQuickActions({
    required this.cs,
    required this.sessionPath,
    required this.officialN,
    required this.flashcardsDue,
  });
  final ColorScheme cs;
  final String sessionPath;
  final int officialN;
  final int flashcardsDue;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(
        icon: Icons.menu_book_rounded,
        label: 'Biblioteca',
        subtitle: officialN > 0 ? '$officialN questões' : 'Importar provas',
        color: cs.primary,
        onTap: () => context.go('/biblioteca'),
      ),
      _ActionItem(
        icon: Icons.smart_toy_rounded,
        label: 'Tutor IA',
        subtitle: 'Tirar dúvidas',
        color: cs.secondary,
        onTap: () => context.go('/tutor'),
      ),
      _ActionItem(
        icon: Icons.style_rounded,
        label: 'Flashcards',
        subtitle: flashcardsDue > 0 ? '$flashcardsDue para revisar' : 'Em dia',
        color: cs.tertiary,
        onTap: () => context.go('/flashcards?due=1'),
      ),
      _ActionItem(
        icon: Icons.history_edu_rounded,
        label: 'Simulados',
        subtitle: 'Provas oficiais',
        color: cs.error,
        onTap: () => context.go('/simulados'),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: actions.map((a) => _buildCard(context, a)).toList(),
    );
  }

  Widget _buildCard(BuildContext context, _ActionItem a) {
    return Material(
      color: cs.surfaceContainerHighest.withOpacity(0.3),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: a.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: a.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(a.icon, color: a.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      a.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      a.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionItem {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
}

/// Card de recomendação simples
class _SimpleRecommendationCard extends StatelessWidget {
  const _SimpleRecommendationCard({required this.recommendations, required this.cs});
  final Map<String, dynamic> recommendations;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final summary = recommendations['summary']?.toString() ?? '';
    final materials = recommendations['materials'] as List? ?? [];
    final exams = recommendations['exams'] as List? ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: cs.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Recomendação do dia',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              summary,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: cs.onSurface.withOpacity(0.8),
              ),
            ),
          ],
          if (materials.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: materials.take(3).map((raw) {
                final m = Map<String, dynamic>.from(raw as Map);
                final title = m['title']?.toString() ?? 'Material';
                final pdf = m['pdfFilename']?.toString() ?? '';
                return ActionChip(
                  avatar: const Icon(Icons.picture_as_pdf, size: 16),
                  label: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onPressed: pdf.isNotEmpty
                      ? () => context.go(Uri(path: '/estudar', queryParameters: {
                            'pdf': pdf,
                            'title': title,
                            'subject': m['subject']?.toString() ?? '',
                          }).toString())
                      : null,
                );
              }).toList(),
            ),
          ],
          if (exams.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: exams.take(2).map((raw) {
                final e = Map<String, dynamic>.from(raw as Map);
                final year = e['year']?.toString() ?? '';
                return ActionChip(
                  avatar: const Icon(Icons.history_edu, size: 16),
                  label: Text('PAES $year'),
                  onPressed: () => context.go('/simulados?ano=$year'),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Checklist simples do dia
class _SimpleChecklist extends StatelessWidget {
  const _SimpleChecklist({
    required this.cs,
    required this.sessionDone,
    required this.cardsDone,
    required this.revisionsDone,
    required this.dayClosed,
    required this.gapN,
    required this.onSession,
    required this.onCards,
    required this.onRevisions,
    required this.onCloseDay,
    required this.examDays,
    required this.dailyGoal,
  });
  final ColorScheme cs;
  final bool sessionDone;
  final bool cardsDone;
  final bool revisionsDone;
  final bool dayClosed;
  final int gapN;
  final VoidCallback onSession;
  final VoidCallback onCards;
  final VoidCallback onRevisions;
  final VoidCallback? onCloseDay;
  final int? examDays;
  final int dailyGoal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist_rounded, color: cs.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Atividades do dia',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              if (examDays != null && examDays! > 0)
                Text(
                  '$examDays dias',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _CheckRow(
            done: sessionDone,
            label: 'Sessão de estudo',
            icon: Icons.play_circle_outline,
            onAction: onSession,
            cs: cs,
          ),
          _CheckRow(
            done: cardsDone,
            label: 'Flashcards',
            icon: Icons.style_outlined,
            onAction: onCards,
            cs: cs,
          ),
          _CheckRow(
            done: revisionsDone,
            label: gapN > 0 ? '$gapN tópicos para revisar' : 'Revisões em dia',
            icon: Icons.replay_outlined,
            onAction: onRevisions,
            cs: cs,
          ),
          if (onCloseDay != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onCloseDay,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Encerrar dia'),
                style: TextButton.styleFrom(
                  foregroundColor: cs.primary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Meta: $dailyGoal min/dia',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.done,
    required this.label,
    required this.icon,
    required this.onAction,
    required this.cs,
  });
  final bool done;
  final String label;
  final IconData icon;
  final VoidCallback onAction;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: done ? null : onAction,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              Icon(
                done ? Icons.check_circle : icon,
                size: 22,
                color: done ? cs.primary : cs.onSurface.withOpacity(0.4),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: done ? FontWeight.w600 : FontWeight.w500,
                    color: done ? cs.primary : cs.onSurface.withOpacity(0.7),
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (!done)
                Icon(Icons.chevron_right, size: 20, color: cs.onSurface.withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
