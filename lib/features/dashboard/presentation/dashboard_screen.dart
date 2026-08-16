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
import 'dashboard_update_banner.dart';
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
                                    style: GoogleFonts.inter(
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
                          _SimpleQuickActions(cs: cs, sessionPath: sessionPath),
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
      ('Materiais', Icons.picture_as_pdf_rounded, '/materiais', const Color(0xFF2196F3)),
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


class _SmartCoachCard extends StatelessWidget {
  const _SmartCoachCard({required this.insights});
  final Map<String, dynamic> insights;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dailyTip = insights['dailyTip']?.toString() ?? '';
    final weakAlerts = (insights['weakAlerts'] as List?) ?? [];
    final trend = Map<String, dynamic>.from(insights['weeklyTrend'] as Map? ?? {});
    final nextAction = insights['nextAction'] as Map?;

    return SurfacePanel(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.tertiary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Coach IA',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (dailyTip.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_rounded, color: cs.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dailyTip,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (trend.isNotEmpty) ...[
              const SizedBox(height: 12),
              _TrendChip(trend: trend),
            ],
            if (nextAction != null) ...[
              const SizedBox(height: 12),
              TapScale(
                child: Material(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.go(nextAction['path']?.toString() ?? '/sessao');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(_iconFor(nextAction['icon']?.toString() ?? 'play_arrow'),
                              color: cs.primary, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nextAction['title']?.toString() ?? 'Estudar agora',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                ),
                                if (nextAction['subtitle'] != null)
                                  Text(
                                    nextAction['subtitle'].toString(),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: cs.onSurface.withOpacity(0.6),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_rounded, color: cs.onSurface.withOpacity(0.4)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (weakAlerts.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Pontos de atencao',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              for (final wa in weakAlerts.take(3))
                _WeakAlertChip(alert: wa as Map),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String name) => switch (name) {
    'style' => Icons.style_rounded,
    'school' => Icons.school_rounded,
    'bolt' => Icons.bolt_rounded,
    'edit' => Icons.edit_rounded,
    _ => Icons.play_arrow_rounded,
  };
}


class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.trend});
  final Map<String, dynamic> trend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = trend['trend']?.toString() ?? 'sem_dados';
    final msg = trend['message']?.toString() ?? '';

    final (icon, color) = switch (t) {
      'melhorou' => (Icons.trending_up_rounded, const Color(0xFF4CAF50)),
      'piorou' => (Icons.trending_down_rounded, cs.error),
      'estavel' => (Icons.trending_flat_rounded, cs.onSurface.withOpacity(0.5)),
      'novo' => (Icons.auto_awesome_rounded, cs.primary),
      _ => (Icons.info_outline_rounded, cs.onSurface.withOpacity(0.4)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _WeakAlertChip extends StatelessWidget {
  const _WeakAlertChip({required this.alert});
  final Map alert;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final subj = alert['subject']?.toString() ?? '';
    final topic = alert['topic']?.toString() ?? '';
    final msg = alert['message']?.toString() ?? '';
    final path = alert['actionPath']?.toString() ?? '/sessao';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TapScale(
        child: Material(
          color: cs.errorContainer.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              HapticFeedback.selectionClick();
              context.go(path);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: cs.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$subj - $topic',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          msg,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: cs.onSurface.withOpacity(0.4)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _RecommendationsCard extends StatelessWidget {
  const _RecommendationsCard({required this.recommendations});
  final Map<String, dynamic> recommendations;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final summary = recommendations['summary']?.toString() ?? '';
    final materials = (recommendations['materialSuggestions'] as List?) ?? [];
    final exams = (recommendations['examSuggestions'] as List?) ?? [];
    final hasMaterials = materials.isNotEmpty;
    final hasExams = exams.isNotEmpty;

    if (!hasMaterials && !hasExams && summary.isEmpty) {
      return const SizedBox.shrink();
    }

    return SurfacePanel(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.tertiary, cs.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Recomendacoes de Estudo',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            if (summary.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tips_and_updates_rounded, color: cs.tertiary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        summary,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (hasMaterials) ...[
              const SizedBox(height: 16),
              Text(
                'Materiais sugeridos',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              for (final m in materials.take(3))
                _MaterialSuggestionTile(material: m as Map),
            ],
            if (hasExams) ...[
              const SizedBox(height: 16),
              Text(
                'Provas historicas para treinar',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              for (final e in exams.take(3))
                _ExamSuggestionTile(exam: e as Map),
            ],
          ],
        ),
      ),
    );
  }
}


class _MaterialSuggestionTile extends StatelessWidget {
  const _MaterialSuggestionTile({required this.material});
  final Map material;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = material['title']?.toString() ?? '';
    final reason = material['reason']?.toString() ?? '';
    final subject = material['subject']?.toString() ?? '';
    final actionPath = material['actionPath']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TapScale(
        child: Material(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              HapticFeedback.selectionClick();
              context.go(actionPath);
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.menu_book_rounded, color: cs.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$subject · $reason',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: cs.onSurface.withOpacity(0.4)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _ExamSuggestionTile extends StatelessWidget {
  const _ExamSuggestionTile({required this.exam});
  final Map exam;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final year = exam['year']?.toString() ?? '';
    final official = exam['officialQuestions']?.toString() ?? '0';
    final reason = exam['reason']?.toString() ?? '';
    final actionPath = exam['actionPath']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TapScale(
        child: Material(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              HapticFeedback.selectionClick();
              context.go(actionPath);
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.assignment_rounded, color: cs.secondary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PAES $year',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$official questoes oficiais · $reason',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: cs.onSurface.withOpacity(0.4)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets simplificados para o dashboard limpo
// ---------------------------------------------------------------------------

/// 4 atalhos grandes e claros
class _SimpleQuickActions extends StatelessWidget {
  const _SimpleQuickActions({required this.cs, required this.sessionPath});
  final ColorScheme cs;
  final String sessionPath;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(
        icon: Icons.menu_book,
        label: 'Biblioteca',
        subtitle: '92 PDFs',
        color: cs.primary,
        onTap: () => context.go('/biblioteca'),
      ),
      _ActionItem(
        icon: Icons.play_circle_fill,
        label: 'Praticar',
        subtitle: 'Questões',
        color: cs.tertiary,
        onTap: () => context.go(sessionPath),
      ),
      _ActionItem(
        icon: Icons.smart_toy,
        label: 'Tutor IA',
        subtitle: 'Dúvidas',
        color: cs.secondary,
        onTap: () => context.go('/tutor'),
      ),
      _ActionItem(
        icon: Icons.history_edu,
        label: 'Provas',
        subtitle: 'Oficiais',
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
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      a.subtitle,
                      style: GoogleFonts.inter(
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
                style: GoogleFonts.poppins(
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
              style: GoogleFonts.inter(
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
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              if (examDays != null && examDays! > 0)
                Text(
                  '$examDays dias',
                  style: GoogleFonts.inter(
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
            style: GoogleFonts.inter(
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
                  style: GoogleFonts.inter(
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
