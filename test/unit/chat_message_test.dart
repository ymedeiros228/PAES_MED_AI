import 'package:flutter_test/flutter_test.dart';
import 'package:paes_med_ai/features/ai_tutor/domain/chat_message.dart';

void main() {
  group('ChatMessage', () {
    test('isUser reflete o papel', () {
      const user = ChatMessage(role: ChatRole.user, content: 'oi');
      const assistant = ChatMessage(role: ChatRole.assistant, content: 'olá');
      expect(user.isUser, isTrue);
      expect(assistant.isUser, isFalse);
    });

    test('toJson serializa apenas role/content (sem citações)', () {
      const msg = ChatMessage(
        role: ChatRole.assistant,
        content: 'resposta',
        citations: [
          {'type': 'question', 'id': 'q1'},
        ],
        uncited: true,
        hasLocalBase: false,
      );
      expect(msg.toJson(), {'role': 'assistant', 'content': 'resposta'});
    });

    test('toJson usa "user" quando é do usuário', () {
      const msg = ChatMessage(role: ChatRole.user, content: 'pergunta');
      expect(msg.toJson()['role'], 'user');
    });

    test('defaults: sem citações, uncited false, hasLocalBase true', () {
      const msg = ChatMessage(role: ChatRole.assistant, content: 'x');
      expect(msg.citations, isEmpty);
      expect(msg.uncited, isFalse);
      expect(msg.hasLocalBase, isTrue);
    });
  });
}
