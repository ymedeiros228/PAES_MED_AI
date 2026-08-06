import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paes_med_ai/features/ai_tutor/application/ai_tutor_controller.dart';
import 'package:paes_med_ai/features/ai_tutor/data/ai_tutor_repository.dart';
import 'package:paes_med_ai/features/ai_tutor/domain/chat_message.dart';
import 'package:paes_med_ai/features/ai_tutor/presentation/ai_tutor_screen.dart';

class _FakeRepo extends AiTutorRepository {
  _FakeRepo(this._answer);
  final TutorAnswer _answer;

  @override
  Future<TutorAnswer> ask({
    required String message,
    required List<ChatMessage> history,
    String style = 'professor',
  }) async =>
      _answer;
}

Widget _wrap(AiTutorRepository repo) {
  return ProviderScope(
    overrides: [aiTutorRepositoryProvider.overrideWithValue(repo)],
    child: const MaterialApp(home: Scaffold(body: AiTutorScreen())),
  );
}

void main() {
  testWidgets('mostra a saudação do assistente como bolha', (tester) async {
    await tester.pumpWidget(_wrap(_FakeRepo(const TutorAnswer(answer: 'x'))));
    await tester.pump();
    expect(find.textContaining('Sou seu tutor'), findsOneWidget);
  });

  testWidgets('enviar mostra a bolha do usuário e a resposta', (tester) async {
    await tester.pumpWidget(
      _wrap(_FakeRepo(const TutorAnswer(answer: 'Resposta do tutor'))),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'minha dúvida');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump(); // dispara o send
    await tester.pump(const Duration(milliseconds: 50)); // resolve o future

    expect(find.text('minha dúvida'), findsOneWidget);
    expect(find.text('Resposta do tutor'), findsOneWidget);
  });

  testWidgets('resposta sem base local exibe aviso honesto', (tester) async {
    await tester.pumpWidget(
      _wrap(_FakeRepo(const TutorAnswer(answer: 'resp', hasLocalBase: false))),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'oi');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Sem base local para citar'), findsOneWidget);
  });

  testWidgets('resposta com citações mostra a seção de fontes', (tester) async {
    await tester.pumpWidget(
      _wrap(
        _FakeRepo(
          const TutorAnswer(
            answer: 'resp com fonte',
            citations: [
              {'type': 'question', 'id': 'q1', 'label': 'Questão 1', 'year': '2024'},
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'fonte?');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Fontes na base'), findsOneWidget);
  });
}
