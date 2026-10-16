import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paes_med_ai/core/theme/app_theme.dart';
import 'package:paes_med_ai/core/widgets/ui_kit.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );

void main() {
  group('isOfficialQuestion', () {
    test('confia no campo isOfficial do backend', () {
      expect(isOfficialQuestion({'isOfficial': true, 'examBoard': 'TREINO'}), isTrue);
      expect(isOfficialQuestion({'isOfficial': false, 'examBoard': 'UEMA_PAES'}), isFalse);
    });

    test('sem o campo, usa a banca e depois a fonte', () {
      expect(isOfficialQuestion({'examBoard': 'UEMA_PAES'}), isTrue);
      expect(isOfficialQuestion({'examBoard': 'TREINO', 'source': 'pdf'}), isFalse);
      expect(isOfficialQuestion({'source': 'pdf_2019'}), isTrue);
      // Ano sozinho não torna a questão oficial (antes o simulado dizia "oficial").
      expect(isOfficialQuestion({'year': 2020}), isFalse);
    });
  });

  testWidgets('faixa de erro mostra a letra certa', (tester) async {
    await tester.pumpWidget(_wrap(const AnswerFeedbackBanner(correct: false, correctIndex: 2)));
    await tester.pumpAndSettle();
    expect(find.text('Não foi dessa vez. A resposta certa é a C.'), findsOneWidget);
  });

  testWidgets('atalhos: 1–5 e A–E escolhem, Enter confirma, N avança', (tester) async {
    final picked = <int>[];
    var entered = 0;
    var next = 0;
    await tester.pumpWidget(_wrap(QuestionKeyHandler(
      optionCount: 5,
      onSelect: picked.add,
      onEnter: () => entered++,
      onNext: () => next++,
      child: const SizedBox.expand(),
    )));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);

    expect(picked, [1, 4]);
    expect(entered, 1);
    expect(next, 1);
  });

  testWidgets('atalhos respeitam o número de alternativas e o bloqueio', (tester) async {
    final picked = <int>[];
    await tester.pumpWidget(_wrap(QuestionKeyHandler(
      optionCount: 3,
      onSelect: picked.add,
      child: const SizedBox.expand(),
    )));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    expect(picked, isEmpty);

    await tester.pumpWidget(_wrap(const QuestionKeyHandler(
      optionCount: 5,
      child: SizedBox.expand(),
    )));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    expect(picked, isEmpty);
  });

  testWidgets('trilha pinta acerto e erro', (tester) async {
    await tester.pumpWidget(_wrap(const QuestionHeader(
      index: 2,
      total: 4,
      marks: [QuestionMark.correct, QuestionMark.wrong, QuestionMark.pending, QuestionMark.pending],
      subject: 'Biologia',
      official: true,
      year: 2023,
    )));
    await tester.pumpAndSettle();
    expect(find.text('Questão 3 de 4'), findsOneWidget);
    expect(find.text('Oficial PAES 2023'), findsOneWidget);
  });
}
