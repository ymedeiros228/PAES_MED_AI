import 'package:flutter_test/flutter_test.dart';
import 'package:paes_med_ai/features/ai_tutor/application/ai_tutor_controller.dart';
import 'package:paes_med_ai/features/ai_tutor/data/ai_tutor_repository.dart';
import 'package:paes_med_ai/features/ai_tutor/domain/chat_message.dart';

void main() {
  group('AiTutorState.copyWith', () {
    const base = AiTutorState(
      messages: [ChatMessage(role: ChatRole.assistant, content: 'oi')],
      isLoading: false,
      error: 'erro antigo',
      style: 'professor',
    );

    test('mantém valores quando nada muda', () {
      final copy = base.copyWith();
      expect(copy.messages, base.messages);
      expect(copy.isLoading, base.isLoading);
      expect(copy.error, base.error);
      expect(copy.style, base.style);
    });

    test('clearError zera o erro mesmo se error for passado', () {
      final copy = base.copyWith(clearError: true, error: 'novo');
      expect(copy.error, isNull);
    });

    test('atualiza style e isLoading isoladamente', () {
      final copy = base.copyWith(style: 'macete', isLoading: true);
      expect(copy.style, 'macete');
      expect(copy.isLoading, isTrue);
      expect(copy.error, 'erro antigo');
    });
  });

  group('TutorAnswer', () {
    test('defaults honestos', () {
      const a = TutorAnswer(answer: 'texto');
      expect(a.citations, isEmpty);
      expect(a.ragMode, isNull);
      expect(a.uncited, isFalse);
      expect(a.hasLocalBase, isTrue);
    });
  });
}
