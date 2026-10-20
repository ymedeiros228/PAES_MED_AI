import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
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
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui/subject_style.dart';
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

  @override
  void initState() {
    super.initState();
    _loadCheckpoint();
    _loadFirstRunCoach();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final exam = ref.read(examDateProvider).date;
      if (exam.isNotEmpty) {
        unawaited(ref.read(examDateProvider.notifier).retrySync());
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
          AppButton.tertiary(label: 'Cancelar', onPressed: () => Navigator.pop(ctx, false)),
          AppButton.primary(label: 'Descartar', onPressed: () => Navigator.pop(ctx, true)),
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
    final examCd = ref.watch(examCountdownProvider);

    return async.when(
      loading: () => const PageScaffold(
        eyebrow: 'PAES MED AI',
        title: 'Início',
        child: SkeletonPage(),
      ),
      error: (e, _) => PageScaffold(
        eyebrow: 'PAES MED AI',
        title: 'Início',
        child: ErrorState(
          message: humanApiError(e,
              fallback: kIsWeb
                  ? 'Recarregue a página (F5).'
                  : 'Reabra pelo ícone PAES MED AI na área de trabalho.'),
          onRetry: () => ref.read(refreshTickProvider.notifier).state++,
          secondary: AppButton.tertiary(
            label: 'Ir para a sessão',
            onPressed: () => context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1'),
          ),
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
        // Fonte única: data salva em Ajustes (igual à barra lateral). A API só
        // entra se não houver data local.
        final examDays = examCd.hasDate ? examCd.daysLeft : examDaysApi;
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

        final dueCards = data['flashcardsDueCount'] as int? ?? 0;
        final totalAnswered = data['totalAnswered'] as int? ?? 0;
        final accuracyBySubject = (data['accuracyBySubject'] is Map)
            ? Map<String, dynamic>.from(data['accuracyBySubject'] as Map)
            : const <String, dynamic>{};
        final passo = _nextStep(data) ?? _routineStep(routine);
        // A frase do backend já cita a matéria/tópico: não repetir o título.
        final linha = checkpoint != null
            ? 'Você parou em ${_checkpointShort(checkpoint!)}.'
            : (passo != null && coachLine.contains(passo))
                ? 'Sessão guiada: teoria rápida, questões das provas anteriores e revisão.'
                : coachLine;

        return CustomScrollView(
          slivers: [
            // Herói: quanto falta para a prova e o próximo passo, uma vez só.
            SliverToBoxAdapter(
              child: ContentWidth(
                vertical: const EdgeInsets.only(top: 24),
                child: PageHero(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CountdownHeadline(
                        cd: examCd,
                        daysFallback: examDays,
                        oficial: ref.watch(examDateProvider).date == kDataProvaOficial,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        checkpoint != null ? 'Sessão em andamento' : (passo ?? 'Pronto para estudar?'),
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        linha,
                        style: TextStyle(
                          fontSize: 15.5,
                          color: Colors.white.withOpacity(0.86),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
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
                              child: Text(checkpoint != null ? 'Continuar sessão' : 'Começar a estudar'),
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
                                side: BorderSide(color: Colors.white.f40),
                              ),
                              child: const Text('Recomeçar'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  ContentWidth(
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
                                action: AppButton.tertiary(
                                  label: 'Tentar',
                                  onPressed: _loadCheckpoint,
                                ),
                              ),
                            ),
                          if (ref.watch(examDateProvider).syncError != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: QuietEmpty(
                                message: ref.watch(examDateProvider).syncError!,
                                action: AppButton.tertiary(
                                  label: 'Tentar',
                                  onPressed: () => unawaited(
                                    ref.read(examDateProvider.notifier).retrySync(),
                                  ),
                                ),
                              ),
                            ),
                          if (showFirstRunCoach && !semana1Ok)
                            AppCard(
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
                                      color: cs.onPrimaryContainer.f90,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      AppButton.primary(
                                        label: 'Ir à Biblioteca',
                                        onPressed: () => context.go('/biblioteca?semana1=1'),
                                      ),
                                      AppButton.tertiary(label: 'Depois', onPressed: _dismissFirstRunCoach),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                          // Atualização do app instalado (só no PC).
                          if (!kIsWeb) const UpdateBanner(),

                          StaggeredFadeIn(
                            children: [
                              _TodayStrip(
                                minutesToday: (data['studyMinutesToday'] as num?)?.toInt() ??
                                    ((data['studyToday'] as Map?)?['minutes'] as num?)?.toInt() ??
                                    0,
                                goal: ref.watch(dailyGoalProvider),
                                streakDays: data['streakDays'] as int? ?? 0,
                                dueCards: dueCards,
                                accuracy: (data['accuracy'] as num?)?.toDouble() ?? 0,
                                totalAnswered: totalAnswered,
                              ),
                              const SizedBox(height: 20),
                              _SimpleChecklist(
                                cs: cs,
                                sessionDone: checklist['session'] == true,
                                cardsDone: checklist['cards'] == true,
                                revisionsDone: checklist['revisions'] == true,
                                dayClosed: dayClosed,
                                gapN: gapN,
                                dueCards: dueCards,
                                onSession: () => context.go(sessionPath),
                                onCards: () => context.go('/flashcards?due=1'),
                                onRevisions: () => context.go('/fila'),
                                onCloseDay: dayClosed ? null : _closeDay,
                              ),
                              if (accuracyBySubject.isNotEmpty) ...[
                                const SizedBox(height: 28),
                                _SubjectsGrid(accuracy: accuracyBySubject),
                              ],
                              const SizedBox(height: 32),
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
        );
      },
    );
  }
}

/// Próximo passo (disciplina · tópico) vindo de `studyToday`, se houver.
String? _nextStep(Map<String, dynamic> data) {
  final st = data['studyToday'];
  if (st is! Map) return null;
  final subj = st['subject']?.toString() ?? '';
  final topic = st['topic']?.toString() ?? '';
  if (subj.isEmpty || topic.isEmpty) return null;
  return '$subj · $topic';
}

/// Foco do coach do dia quando ainda não há `studyToday`.
String? _routineStep(Map<String, dynamic> routine) {
  final subj = routine['subject']?.toString() ?? '';
  final topic = routine['topic']?.toString() ?? '';
  if (subj.isEmpty || topic.isEmpty) return null;
  return '$subj · $topic';
}

// ===========================================================================
// Contagem regressiva do herói
// ===========================================================================

/// "33 dias para a prova" + a data por extenso (o único lugar do Início com isso).
class _CountdownHeadline extends StatelessWidget {
  const _CountdownHeadline({
    required this.cd,
    required this.daysFallback,
    required this.oficial,
  });
  final ExamCountdown cd;
  final int? daysFallback;
  final bool oficial;

  @override
  Widget build(BuildContext context) {
    if (cd.isPast) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A prova de ${cd.dateLabel} já passou',
            style: AppFonts.display(fontSize: 26, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.go('/configuracoes'),
            style: TextButton.styleFrom(foregroundColor: Colors.white, padding: EdgeInsets.zero),
            icon: const Icon(Icons.event_rounded, size: 18),
            label: const Text('Definir a data da próxima prova'),
          ),
        ],
      );
    }
    final days = cd.hasDate ? cd.daysLeft : daysFallback;
    if (days == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PAES MED AI',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.go('/configuracoes'),
            style: TextButton.styleFrom(foregroundColor: Colors.white, padding: EdgeInsets.zero),
            icon: const Icon(Icons.event_rounded, size: 18),
            label: const Text('Marcar a data da prova'),
          ),
        ],
      );
    }
    final data = cd.date;
    var quando = data == null ? '' : MaterialLocalizations.of(context).formatFullDate(data);
    if (quando.isNotEmpty) {
      quando = quando[0].toUpperCase() + quando.substring(1);
      if (oficial) quando += ' · das 13h30 às 18h30';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(
              days == 0 ? 'Hoje' : '$days',
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.0,
                letterSpacing: -1.5,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                days == 0
                    ? 'é o dia da prova'
                    : days == 1
                        ? 'dia para a prova'
                        : 'dias para a prova',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (quando.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            quando,
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.75)),
          ),
        ],
      ],
    );
  }
}

// ===========================================================================
// Hoje: meta, sequência, flashcards e acerto numa faixa só
// ===========================================================================

class _TodayStrip extends StatelessWidget {
  const _TodayStrip({
    required this.minutesToday,
    required this.goal,
    required this.streakDays,
    required this.dueCards,
    required this.accuracy,
    required this.totalAnswered,
  });
  final int minutesToday;
  final int goal;
  final int streakDays;
  final int dueCards;
  final double accuracy;
  final int totalAnswered;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final meta = goal > 0 ? (minutesToday / goal).clamp(0.0, 1.0).toDouble() : 0.0;
    final itens = <Widget>[
      _TodayItem(
        leading: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  value: meta,
                  strokeWidth: 4,
                  color: cs.primary,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
              ),
              Icon(Icons.timer_outlined, size: 18, color: cs.primary),
            ],
          ),
        ),
        label: 'Meta do dia',
        value: '$minutesToday de $goal min',
      ),
      _TodayItem(
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFF08A24),
        label: 'Sequência',
        value: streakDays == 0
            ? 'Comece hoje'
            : streakDays == 1
                ? '1 dia'
                : '$streakDays dias',
      ),
      _TodayItem(
        icon: Icons.style_rounded,
        color: const Color(0xFF5B9BF0),
        label: 'Flashcards para hoje',
        value: dueCards == 0 ? 'Nenhum' : '$dueCards',
        onTap: dueCards > 0 ? () => context.go('/flashcards?due=1') : null,
      ),
      _TodayItem(
        icon: Icons.track_changes_rounded,
        color: const Color(0xFF2E9E5B),
        label: 'Acerto geral',
        value: totalAnswered > 0 ? '${(accuracy * 100).round()}%' : '—',
        hint: totalAnswered == 0
            ? 'Responda questões para ver'
            : totalAnswered == 1
                ? '1 questão respondida'
                : '$totalAnswered questões respondidas',
      ),
    ];
    return AppCard(
      padding: const EdgeInsets.all(kGap16),
      child: LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth >= 760 ? 4 : 2;
          const gap = kGap16;
          final w = ((c.maxWidth - gap * (cols - 1)) / cols).floorToDouble();
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [for (final it in itens) SizedBox(width: w, child: it)],
          );
        },
      ),
    );
  }
}

class _TodayItem extends StatelessWidget {
  const _TodayItem({
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.leading,
    this.hint,
    this.onTap,
  });
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final Widget? leading;
  final String? hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tom = color ?? cs.primary;
    final conteudo = Row(
      children: [
        leading ??
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tom.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: tom, size: 21),
            ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: context.text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (hint != null)
                Text(
                  hint!,
                  style: context.text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (onTap != null) Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurfaceVariant),
      ],
    );
    final semantica = Semantics(
      label: '$label: $value${hint != null ? ', $hint' : ''}',
      button: onTap != null,
      excludeSemantics: true,
      child: conteudo,
    );
    if (onTap == null) return semantica;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(padding: const EdgeInsets.all(2), child: semantica),
    );
  }
}

// ===========================================================================
// Acerto por matéria (só aparece quando já há respostas)
// ===========================================================================

class _SubjectsGrid extends StatelessWidget {
  const _SubjectsGrid({required this.accuracy});
  final Map<String, dynamic> accuracy;

  @override
  Widget build(BuildContext context) {
    // Mais fraca primeiro: é onde vale treinar.
    final names = accuracy.keys.toList()
      ..sort((a, b) => (_frac(accuracy[a]) ?? 0).compareTo(_frac(accuracy[b]) ?? 0));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Acerto por matéria', icon: Icons.auto_stories_rounded),
        const SizedBox(height: kGap12),
        LayoutBuilder(builder: (context, c) {
          final cols = (c.maxWidth / 220).floor().clamp(2, 4);
          final w = (c.maxWidth - (cols - 1) * kGap12) / cols;
          return Wrap(
            spacing: kGap12,
            runSpacing: kGap12,
            children: [
              for (final n in names)
                SizedBox(
                  width: w,
                  child: _SubjectCard(name: n, mastery: _frac(accuracy[n])),
                ),
            ],
          );
        }),
      ],
    );
  }

  static double? _frac(dynamic v) {
    if (v is! num) return null;
    final d = v.toDouble();
    return (d > 1 ? d / 100 : d).clamp(0.0, 1.0);
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.name, required this.mastery});
  final String name;
  final double? mastery;

  @override
  Widget build(BuildContext context) {
    final v = subjectVisual(name);
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(kGap16),
      onTap: () => context.go('/adaptativo?subject=${Uri.encodeComponent(name)}'),
      semanticLabel: 'Treinar $name',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: v.soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(v.icon, color: v.color, size: 22),
              ),
              const Spacer(),
              Text(
                mastery == null ? '—' : '${(mastery! * 100).round()}%',
                style: context.text.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800, color: v.color),
              ),
            ],
          ),
          const SizedBox(height: kGap12),
          Text(name,
              style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: kGap8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: mastery ?? 0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                minHeight: 7,
                color: v.color,
                backgroundColor: v.soft,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'de acerto · toque para treinar',
            style: context.text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Atividades do dia
// ===========================================================================

class _SimpleChecklist extends StatelessWidget {
  const _SimpleChecklist({
    required this.cs,
    required this.sessionDone,
    required this.cardsDone,
    required this.revisionsDone,
    required this.dayClosed,
    required this.gapN,
    required this.dueCards,
    required this.onSession,
    required this.onCards,
    required this.onRevisions,
    required this.onCloseDay,
  });
  final ColorScheme cs;
  final bool sessionDone;
  final bool cardsDone;
  final bool revisionsDone;
  final bool dayClosed;
  final int gapN;
  final int dueCards;
  final VoidCallback onSession;
  final VoidCallback onCards;
  final VoidCallback onRevisions;
  final VoidCallback? onCloseDay;

  @override
  Widget build(BuildContext context) {
    final feitos = [sessionDone, cardsDone, revisionsDone].where((b) => b).length;
    return AppCard(
      title: 'Atividades do dia',
      subtitle: feitos == 3
          ? 'Tudo feito hoje.'
          : feitos == 1
              ? '1 de 3 feita'
              : '$feitos de 3 feitas',
      icon: Icons.checklist_rounded,
      trailing: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: feitos / 3),
              duration: const Duration(milliseconds: 250),
              builder: (_, v, __) => SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  value: v,
                  strokeWidth: 5,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
              ),
            ),
            Text('$feitos/3', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CheckRow(
            done: sessionDone,
            label: 'Uma sessão de estudo (15 min ou mais)',
            icon: Icons.play_circle_outline,
            onAction: onSession,
            cs: cs,
          ),
          _CheckRow(
            done: cardsDone,
            label: cardsDone
                ? 'Flashcards em dia'
                : dueCards == 1
                    ? 'Revisar 1 flashcard'
                    : 'Revisar $dueCards flashcards',
            icon: Icons.style_outlined,
            onAction: onCards,
            cs: cs,
          ),
          _CheckRow(
            done: revisionsDone,
            label: gapN == 0
                ? 'Revisões em dia'
                : gapN == 1
                    ? 'Revisar 1 assunto que você errou'
                    : 'Revisar $gapN assuntos que você errou',
            icon: Icons.replay_outlined,
            onAction: onRevisions,
            cs: cs,
          ),
          if (onCloseDay != null) ...[
            const SizedBox(height: kGap8),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton.tertiary(
                label: 'Encerrar o dia',
                icon: Icons.check_circle_outline,
                onPressed: onCloseDay,
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: done ? null : onAction,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Icon(
                done ? Icons.check_circle : icon,
                size: 22,
                color: done ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: done ? FontWeight.w600 : FontWeight.w500,
                    color: done ? cs.primary : cs.onSurface,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (!done)
                Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
