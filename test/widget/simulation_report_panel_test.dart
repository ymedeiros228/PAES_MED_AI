import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paes_med_ai/features/simulations/presentation/widgets/simulation_report_panel.dart';

Widget _wrap(Map<String, dynamic> report) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: SimulationReportPanel(
          report: report,
          clock: '12:34',
          wrongResults: const [],
          debriefBuilder: (a, b, c) => const SizedBox.shrink(),
          onRemediateGaps: () {},
          onExportReport: () {},
          onResetSim: () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('mostra barras de acerto por disciplina com percentual e barra',
      (tester) async {
    final report = <String, dynamic>{
      'accuracy': 0.6,
      'correct': 3,
      'total': 5,
      'gaps': const [],
      'results': const [],
      'subjectBreakdown': const [
        {'subject': 'Biologia', 'correct': 4, 'total': 5, 'accuracy': 0.8},
        {'subject': 'Física', 'correct': 1, 'total': 5, 'accuracy': 0.2},
      ],
    };

    await tester.pumpWidget(_wrap(report));
    await tester.pumpAndSettle();

    expect(find.text('Por disciplina'), findsOneWidget);
    expect(find.text('Biologia'), findsOneWidget);
    expect(find.text('Física'), findsOneWidget);
    expect(find.text('4/5 · 80%'), findsOneWidget);
    expect(find.text('1/5 · 20%'), findsOneWidget);
    // Uma barra por disciplina.
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
  });

  testWidgets('calcula acerto a partir de correct/total quando accuracy falta',
      (tester) async {
    final report = <String, dynamic>{
      'accuracy': 0.5,
      'correct': 1,
      'total': 2,
      'gaps': const [],
      'results': const [],
      'subjectBreakdown': const [
        {'subject': 'Química', 'correct': 1, 'total': 2},
      ],
    };

    await tester.pumpWidget(_wrap(report));
    await tester.pumpAndSettle();

    expect(find.text('Química'), findsOneWidget);
    expect(find.text('1/2 · 50%'), findsOneWidget);
  });
}
