import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/data/theme_mode_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_shell.dart';
import 'core/widgets/startup_splash.dart';
import 'features/adaptive/presentation/adaptive_training_screen.dart';
import 'features/ai_tutor/presentation/ai_tutor_screen.dart';
import 'features/approval/presentation/approval_screen.dart';
import 'features/bank_profile/presentation/bank_profile_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/essay/presentation/essay_screen.dart';
import 'features/flashcards/presentation/flashcards_screen.dart';
import 'features/focus/presentation/focus_screen.dart';
import 'features/gamification/presentation/gamification_screen.dart';
import 'features/lessons/presentation/lessons_screen.dart';
import 'features/library/presentation/ingest_review_screen.dart';
import 'features/materials/presentation/study_reader_screen.dart';
import 'features/library/presentation/library_screen.dart';
import 'features/medicine/presentation/medicine_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/progress/presentation/progress_screen.dart';
import 'features/questions/presentation/question_detail_screen.dart';
import 'features/questions/presentation/questions_screen.dart';
import 'features/revisions/presentation/revisions_screen.dart';
import 'features/session/presentation/guided_session_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/settings/presentation/updates_screen.dart';
import 'features/simulations/presentation/simulations_screen.dart';
import 'features/study_plan/presentation/study_plan_screen.dart';
import 'features/today/presentation/today_queue_screen.dart';

final onboardingTick = ValueNotifier<int>(0);

void notifyOnboardingFinished() => onboardingTick.value++;

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  refreshListenable: onboardingTick,
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_done_v1') ?? false;
    final onOnboarding = state.matchedLocation == '/onboarding';
    if (!done && !onOnboarding) return '/onboarding';
    if (done && onOnboarding) return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (_, __) => _fadePage(const DashboardScreen()),
        ),
        GoRoute(
          path: '/fila',
          pageBuilder: (_, __) => _fadePage(const TodayQueueScreen()),
        ),
        GoRoute(path: '/sessao', pageBuilder: (context, state) {
          final yearRaw = state.uri.queryParameters['year'];
          final natRaw = state.uri.queryParameters['preferNatureza'];
          bool? preferNatureza;
          if (natRaw == '1' || natRaw == 'true') preferNatureza = true;
          if (natRaw == '0' || natRaw == 'false') preferNatureza = false;
          return _fadePage(GuidedSessionScreen(
            examBoard: state.uri.queryParameters['examBoard'],
            year: yearRaw == null ? null : int.tryParse(yearRaw),
            preferNatureza: preferNatureza,
            subject: state.uri.queryParameters['subject'],
            topic: state.uri.queryParameters['topic'],
          ));
        }),
        GoRoute(
          path: '/adaptativo',
          pageBuilder: (context, state) => _fadePage(AdaptiveTrainingScreen(
            initialSubject: state.uri.queryParameters['subject'],
            initialTopic: state.uri.queryParameters['topic'],
          )),
        ),
        GoRoute(
          path: '/questoes',
          pageBuilder: (context, state) => _fadePage(QuestionsScreen(
            initialSubject: state.uri.queryParameters['subject'],
            initialTopic: state.uri.queryParameters['topic'],
            initialExamBoard: state.uri.queryParameters['examBoard'],
          )),
        ),
        GoRoute(
          path: '/questoes/:id',
          pageBuilder: (_, state) => _fadePage(QuestionDetailScreen(questionId: state.pathParameters['id']!)),
        ),
        GoRoute(path: '/simulados', pageBuilder: (_, __) => _fadePage(const SimulationsScreen())),
        GoRoute(path: '/cronograma', pageBuilder: (_, __) => _fadePage(const StudyPlanScreen())),
        GoRoute(path: '/revisoes', pageBuilder: (_, __) => _fadePage(const RevisionsScreen())),
        GoRoute(
          path: '/flashcards',
          pageBuilder: (_, state) {
            final due = state.uri.queryParameters['due'];
            final dueOnly = due != '0' && due != 'false';
            return _fadePage(FlashcardsScreen(dueOnlyInitial: dueOnly));
          },
        ),
        GoRoute(path: '/medicina', pageBuilder: (_, __) => _fadePage(const MedicineScreen())),
        GoRoute(path: '/progresso', pageBuilder: (_, __) => _fadePage(const ProgressScreen())),
        GoRoute(path: '/banca', pageBuilder: (_, __) => _fadePage(const BankProfileScreen())),
        GoRoute(path: '/biblioteca', pageBuilder: (_, __) => _fadePage(const LibraryScreen())),
        GoRoute(
          path: '/biblioteca/revisao',
          pageBuilder: (context, state) {
            final extra = state.extra;
            if (extra is IngestReviewArgs) {
              return _fadePage(IngestReviewScreen(args: extra));
            }
            return _fadePage(const _RevisaoRedirect());
          },
        ),
        GoRoute(path: '/aulas', pageBuilder: (_, __) => _fadePage(const LessonsScreen())),
        GoRoute(
          path: '/materiais',
          redirect: (_, __) => '/biblioteca',
        ),
        GoRoute(
          path: '/estudar',
          pageBuilder: (_, state) {
            final q = state.uri.queryParameters;
            return _fadePage(StudyReaderScreen(
              pdfFilename: q['pdf'] ?? '',
              title: q['title'] ?? 'Material',
              subject: q['subject'] ?? '',
              topic: q['topic'] ?? '',
            ));
          },
        ),
        GoRoute(path: '/redacao', pageBuilder: (_, __) => _fadePage(const EssayScreen())),
        GoRoute(path: '/aprovacao', pageBuilder: (_, __) => _fadePage(const ApprovalScreen())),
        GoRoute(path: '/conquistas', pageBuilder: (_, __) => _fadePage(const GamificationScreen())),
        GoRoute(
          path: '/tutor',
          pageBuilder: (_, state) {
            final q = state.uri.queryParameters;
            return _fadePage(AiTutorScreen(
              seedSubject: q['subject'],
              seedTopic: q['topic'],
              seedQuery: q['q'],
            ));
          },
        ),
        GoRoute(path: '/configuracoes', pageBuilder: (_, __) => _fadePage(const SettingsScreen())),
        GoRoute(path: '/atualizacoes', pageBuilder: (_, __) => _fadePage(const UpdatesScreen())),
        GoRoute(
          path: '/foco',
          pageBuilder: (context, state) {
            final subject = state.uri.queryParameters['subject'];
            final yearRaw = state.uri.queryParameters['year'];
            return _fadePage(FocusScreen(
              subject: subject,
              year: yearRaw == null ? null : int.tryParse(yearRaw),
            ));
          },
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Builder(
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Essa página não existe',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Volte ao início e siga pelo menu. Se veio de um link antigo, abra Hoje.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: cs.onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => GoRouter.of(ctx).go('/hoje'),
                  child: const Text('Ir para Hoje'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  ),
);

/// Cria uma CustomTransitionPage com fade suave (250ms) para transições
/// entre telas dentro do ShellRoute. Mais sutil que o slide padrão do
/// Material, evitando "flicker" ao trocar de aba no NavigationBar.
CustomTransitionPage<void> _fadePage(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class PaesMedAiApp extends ConsumerStatefulWidget {
  const PaesMedAiApp({super.key});

  @override
  ConsumerState<PaesMedAiApp> createState() => _PaesMedAiAppState();
}

class _PaesMedAiAppState extends ConsumerState<PaesMedAiApp> {
  bool _backendReady = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'PAES MED AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
      // Scrollbars sempre visíveis no desktop — descobre que há mais conteúdo
      builder: (context, child) {
        // No desktop, mostra splash ate o backend ficar pronto
        if (!_backendReady &&
            !kIsWeb &&
            defaultTargetPlatform == TargetPlatform.windows) {
          return StartupSplash(
            onReady: () => setState(() => _backendReady = true),
          );
        }
        return ScrollConfiguration(
          behavior: const _PaesScrollBehavior(),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// ScrollBehavior desktop: scrollbars visíveis, drag com mouse/trackpad.
class _PaesScrollBehavior extends MaterialScrollBehavior {
  const _PaesScrollBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    // Scrollbar sempre visível no desktop — descobre que há mais conteúdo.
    return Scrollbar(
      controller: details.controller,
      thumbVisibility: true,
      child: child,
    );
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

/// Deep-link / refresh sem args: manda de volta à Biblioteca (não embute Library silenciosa).
class _RevisaoRedirect extends StatefulWidget {
  const _RevisaoRedirect();

  @override
  State<_RevisaoRedirect> createState() => _RevisaoRedirectState();
}

class _RevisaoRedirectState extends State<_RevisaoRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Abra Revisar a partir da Biblioteca (ano pareado).')),
      );
      context.go('/biblioteca');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
