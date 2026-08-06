import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paes_med_ai/core/data/providers.dart';
import 'package:paes_med_ai/features/essay/presentation/essay_screen.dart';

Map<String, dynamic> _progress({
  required int streak,
  String weakest = 'cohesion',
}) {
  return {
    'count': 3,
    'meanScore': 7.2,
    'streakDays': streak,
    'disclaimer': 'treino local · não banca',
    'axes': ['grammar', 'cohesion', 'coherence', 'argumentation', 'intervention'],
    'labels': {
      'grammar': 'Gramática',
      'cohesion': 'Coesão',
      'coherence': 'Coerência',
      'argumentation': 'Argumentação',
      'intervention': 'Intervenção',
    },
    'averages': {
      'grammar': 8.0,
      'cohesion': 4.0,
      'coherence': 6.5,
      'argumentation': 7.0,
      'intervention': 5.0,
    },
    'lastAxisScores': {
      'grammar': 7.0,
      'cohesion': 5.0,
      'coherence': 6.0,
      'argumentation': 8.0,
      'intervention': 6.0,
    },
    'weakestAxis': weakest,
  };
}

Widget _wrap(Map<String, dynamic> progress) {
  return ProviderScope(
    overrides: [
      essayProgressProvider.overrideWith((ref) async => progress),
      essaysProvider.overrideWith((ref) async => const []),
    ],
    child: const MaterialApp(home: Scaffold(body: EssayScreen())),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('mostra streak e destaque do eixo mais fraco', (tester) async {
    await tester.pumpWidget(_wrap(_progress(streak: 3)));
    await _settle(tester);

    expect(find.textContaining('Sequência de 3'), findsOneWidget);
    expect(find.text('Coesão'), findsWidgets); // eixo (label)
    expect(find.text('focar'), findsOneWidget); // marcador do eixo fraco
    // Legenda do radar duplo (média vs última)
    expect(find.text('média'), findsOneWidget);
    expect(find.text('última'), findsOneWidget);
  });

  testWidgets('streak 0 exibe convite para começar', (tester) async {
    await tester.pumpWidget(_wrap(_progress(streak: 0)));
    await _settle(tester);

    expect(find.textContaining('Comece sua sequência'), findsOneWidget);
  });
}
