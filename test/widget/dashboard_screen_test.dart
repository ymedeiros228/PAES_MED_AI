import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paes_med_ai/core/data/providers.dart';
import 'package:paes_med_ai/features/dashboard/presentation/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _dashboardPayload() => {
      'dailyRoutine': {
        'checklist': {'session': false, 'cards': false, 'revisions': false},
        'line': 'Vamos estudar hoje',
        'sessionPath': '/sessao',
        'closePath': '/fila',
        'progressLabel': '1/3 do dia',
      },
      'statsBasis': {'officialCount': 5},
      'streakDays': 4,
      'studyMinutesToday': 20,
      'accuracy': 0.7,
      'weekProgress': <String, dynamic>{},
      'readiness': <String, dynamic>{},
      'studyCalendar': <String, dynamic>{},
      'examCountdown': <String, dynamic>{},
      'openGaps': {'items': <dynamic>[], 'openCount': 0},
      'errorHotTopics': <dynamic>[],
      'weekClose': <String, dynamic>{},
    };

Widget _wrap({required List<dynamic> dueCards}) {
  final recent = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
  return ProviderScope(
    overrides: [
      dashboardProvider.overrideWith((ref) async => _dashboardPayload()),
      flashcardsProvider.overrideWith((ref) async => dueCards),
      essayProgressProvider.overrideWith((ref) async => {'count': 0}),
      lastBackupProvider.overrideWith((ref) async => {'ok': true, 'at': recent}),
    ],
    child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'focus_mode': false,
      'first_run_coach_pending': false,
      'exam_date_iso': '',
    });
  });

  testWidgets('mostra hero e o resumo "Seu ritmo" acima da dobra', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(dueCards: const []));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('PAES MED AI'), findsWidgets);
    expect(find.text('Seu ritmo'), findsOneWidget);
    expect(find.text('dias seguidos'), findsOneWidget);
    // Cards em dia quando não há cards devidos.
    expect(find.text('Cards em dia'), findsOneWidget);
  });

  testWidgets('linha de cards reflete a contagem de devidos', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(dueCards: const [1, 2, 3]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('3 card(s) para revisar'), findsOneWidget);
  });
}
