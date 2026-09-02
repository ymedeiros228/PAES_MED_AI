import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paes_med_ai/core/data/api_client.dart';
import 'package:paes_med_ai/features/focus/application/focus_controller.dart';

Map<String, dynamic> _q(String id, int correct) => {
      'id': id,
      'statement': 'Enunciado $id',
      'options': ['A', 'B', 'C', 'D'],
      'correctIndex': correct,
      'subject': 'Biologia',
      'topic': 'Genética',
      'year': 2024,
      'resolution': 'Resolução $id',
    };

FocusController _controllerReturning(List<Map<String, dynamic>> questions) {
  final api = ApiClient(
    // Bytes UTF-8 explícitos: o ApiClient decodifica com utf8.decode, e o
    // http.Response(String) codifica em latin1 por padrão (quebraria acentos).
    client: MockClient(
      (req) async => http.Response.bytes(utf8.encode(jsonEncode(questions)), 200),
    ),
  );
  return FocusController(api: api);
}

void main() {
  group('FocusState', () {
    const q = FocusQuestion(
      id: 'x',
      statement: 's',
      options: ['a', 'b'],
      correctIndex: 0,
      subject: 'Bio',
      topic: 'Gen',
      year: 2024,
    );

    test('currentQuestion e total', () {
      const empty = FocusState();
      expect(empty.currentQuestion, isNull);
      expect(empty.total, 0);

      const withQ = FocusState(questions: [q]);
      expect(withQ.currentQuestion, q);
      expect(withQ.total, 1);
    });

    test('answeredCount considera revealed', () {
      const s0 = FocusState(questions: [q], currentIndex: 0, revealed: false);
      const s1 = FocusState(questions: [q], currentIndex: 0, revealed: true);
      expect(s0.answeredCount, 0);
      expect(s1.answeredCount, 1);
    });

    test('copyWith com clearError zera o erro', () {
      const s = FocusState(error: 'boom');
      expect(s.copyWith(clearError: true).error, isNull);
      expect(s.copyWith().error, 'boom');
    });
  });

  group('FocusController fluxo', () {
    test('loadQuestions popula estado e reseta placar', () async {
      final c = _controllerReturning([_q('q1', 1), _q('q2', 0)]);
      addTearDown(c.dispose);

      await c.loadQuestions(count: 2);

      expect(c.state.total, 2);
      expect(c.state.isLoading, isFalse);
      expect(c.state.error, isNull);
      expect(c.state.currentIndex, 0);
      expect(c.state.correctCount, 0);
    });

    test('selecionar + revelar conta acerto e avança; erro registra id', () async {
      final c = _controllerReturning([_q('q1', 1), _q('q2', 0)]);
      addTearDown(c.dispose);
      await c.loadQuestions(count: 2);

      // Q1: correta é índice 1 → acerta.
      c.selectOption(1);
      expect(c.state.selectedIndex, 1);
      c.revealAnswer();
      expect(c.state.revealed, isTrue);
      expect(c.state.correctCount, 1);
      expect(c.state.wrongIds, isEmpty);

      c.nextQuestion();
      expect(c.state.currentIndex, 1);
      expect(c.state.revealed, isFalse);
      expect(c.state.selectedIndex, isNull);

      // Q2: correta é índice 0 → erra ao escolher 2.
      c.selectOption(2);
      c.revealAnswer();
      expect(c.state.correctCount, 1);
      expect(c.state.wrongIds, ['q2']);

      // Última questão → finaliza.
      c.nextQuestion();
      expect(c.state.finished, isTrue);
    });

    test('selectOption é ignorado após revelar; revealAnswer sem seleção é no-op', () async {
      final c = _controllerReturning([_q('q1', 0)]);
      addTearDown(c.dispose);
      await c.loadQuestions(count: 1);

      // Sem seleção, revelar não faz nada.
      c.revealAnswer();
      expect(c.state.revealed, isFalse);

      c.selectOption(0);
      c.revealAnswer();
      expect(c.state.revealed, isTrue);

      // Após revelado, não muda a seleção.
      c.selectOption(3);
      expect(c.state.selectedIndex, 0);
    });

    test('avançar limpa a seleção da questão anterior (regressão)', () async {
      final c = _controllerReturning([_q('q1', 0), _q('q2', 0)]);
      addTearDown(c.dispose);
      await c.loadQuestions(count: 2);

      c.selectOption(2);
      c.revealAnswer();
      expect(c.state.selectedIndex, 2);

      c.nextQuestion();
      // Sem o clearSelected, o índice antigo (2) vazaria para a próxima questão.
      expect(c.state.selectedIndex, isNull);
      expect(c.state.revealed, isFalse);
    });

    test('nextQuestion antes de revelar é no-op', () async {
      final c = _controllerReturning([_q('q1', 0), _q('q2', 0)]);
      addTearDown(c.dispose);
      await c.loadQuestions(count: 2);

      c.nextQuestion();
      expect(c.state.currentIndex, 0);
    });

    test('reset limpa questões e placar mantendo filtros', () async {
      final c = _controllerReturning([_q('q1', 0)]);
      addTearDown(c.dispose);
      c.configure(subject: 'Biologia', year: 2024);
      await c.loadQuestions(count: 1);
      c.selectOption(0);
      c.revealAnswer();

      c.reset();
      expect(c.state.total, 0);
      expect(c.state.finished, isFalse);
      expect(c.state.correctCount, 0);
      expect(c.state.subject, 'Biologia');
      expect(c.state.year, 2024);
    });

    test('lista vazia vira erro amigável', () async {
      final c = _controllerReturning([]);
      addTearDown(c.dispose);

      await c.loadQuestions(count: 5);
      expect(c.state.error, isNotNull);
      expect(c.state.isLoading, isFalse);
      expect(c.state.total, 0);
    });
  });
}
