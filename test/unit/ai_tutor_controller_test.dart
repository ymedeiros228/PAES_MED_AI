import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paes_med_ai/features/ai_tutor/application/ai_tutor_controller.dart';
import 'package:paes_med_ai/features/ai_tutor/data/ai_tutor_repository.dart';
import 'package:paes_med_ai/features/ai_tutor/domain/chat_message.dart';

/// Repositório fake controlável para testar o controller sem rede.
class _FakeRepo extends AiTutorRepository {
  _FakeRepo({this.answer, this.error});

  final TutorAnswer? answer;
  final AiTutorException? error;
  int calls = 0;
  List<ChatMessage>? lastHistory;

  @override
  Future<TutorAnswer> ask({
    required String message,
    required List<ChatMessage> history,
    String style = 'professor',
  }) async {
    calls++;
    lastHistory = history;
    if (error != null) throw error!;
    return answer ?? TutorAnswer(answer: 'eco: $message');
  }
}

ProviderContainer _containerWith(AiTutorRepository repo) {
  final c = ProviderContainer(
    overrides: [aiTutorRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('AiTutorController', () {
    test('estado inicial tem 1 saudação do assistente', () {
      final c = _containerWith(_FakeRepo());
      final state = c.read(aiTutorControllerProvider);
      expect(state.messages.length, 1);
      expect(state.messages.first.role, ChatRole.assistant);
      expect(state.isLoading, isFalse);
    });

    test('send() feliz anexa bolha do usuário e a resposta', () async {
      final repo = _FakeRepo(
        answer: const TutorAnswer(answer: 'Resposta com base', hasLocalBase: true),
      );
      final c = _containerWith(repo);
      final notifier = c.read(aiTutorControllerProvider.notifier);

      await notifier.send('O que cai em genética?');

      final msgs = c.read(aiTutorControllerProvider).messages;
      expect(msgs.length, 3); // saudação + usuário + assistente
      expect(msgs[1].role, ChatRole.user);
      expect(msgs[1].content, 'O que cai em genética?');
      expect(msgs[2].role, ChatRole.assistant);
      expect(msgs[2].content, 'Resposta com base');
      expect(c.read(aiTutorControllerProvider).isLoading, isFalse);
      // O histórico enviado ao repo não inclui a mensagem nova do usuário.
      expect(repo.lastHistory!.length, 1);
    });

    test('entrada vazia é ignorada (não chama o repo)', () async {
      final repo = _FakeRepo();
      final c = _containerWith(repo);
      await c.read(aiTutorControllerProvider.notifier).send('   ');
      expect(repo.calls, 0);
      expect(c.read(aiTutorControllerProvider).messages.length, 1);
    });

    test('erro do repositório vira state.error sem quebrar', () async {
      final repo = _FakeRepo(error: const AiTutorException('offline'));
      final c = _containerWith(repo);
      final notifier = c.read(aiTutorControllerProvider.notifier);

      await notifier.send('oi');

      final state = c.read(aiTutorControllerProvider);
      expect(state.error, 'offline');
      expect(state.isLoading, isFalse);
      // A bolha do usuário permanece; não há bolha do assistente nova.
      expect(state.messages.where((m) => m.isUser).length, 1);
      expect(state.messages.last.isUser, isTrue);
    });

    test('setStyle altera o estilo e é enviado ao repo', () async {
      final repo = _FakeRepo();
      final c = _containerWith(repo);
      final notifier = c.read(aiTutorControllerProvider.notifier);
      notifier.setStyle('macete');
      expect(c.read(aiTutorControllerProvider).style, 'macete');
      await notifier.send('dá um macete');
      expect(repo.calls, 1);
    });

    test('clearConversation reseta para uma saudação', () async {
      final c = _containerWith(_FakeRepo());
      final notifier = c.read(aiTutorControllerProvider.notifier);
      await notifier.send('oi');
      expect(c.read(aiTutorControllerProvider).messages.length, greaterThan(1));
      notifier.clearConversation();
      final msgs = c.read(aiTutorControllerProvider).messages;
      expect(msgs.length, 1);
      expect(msgs.first.role, ChatRole.assistant);
    });
  });
}
