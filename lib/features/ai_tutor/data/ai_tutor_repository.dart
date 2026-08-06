import 'package:paes_med_ai/core/data/api_client.dart';
import 'package:paes_med_ai/core/data/api_error.dart';
import 'package:paes_med_ai/features/ai_tutor/domain/chat_message.dart';

class AiTutorException implements Exception {
  const AiTutorException(this.message);
  final String message;
  @override
  String toString() => message;
}

class TutorAnswer {
  const TutorAnswer({
    required this.answer,
    this.citations = const [],
    this.ragMode,
    this.uncited = false,
    this.hasLocalBase = true,
  });
  final String answer;
  final List<Map<String, dynamic>> citations;
  final String? ragMode;
  final bool uncited;
  final bool hasLocalBase;
}

class AiTutorRepository {
  Future<TutorAnswer> ask({
    required String message,
    required List<ChatMessage> history,
    String style = 'professor',
  }) async {
    try {
      final data = await apiClient.post('/api/chat', {
        'message': message,
        'style': style,
        'history': history.map((item) => item.toJson()).toList(),
      });
      final map = Map<String, dynamic>.from(data as Map);
      final answer = map['answer']?.toString();
      if (answer == null || answer.trim().isEmpty) {
        throw const AiTutorException('A IA retornou uma resposta vazia.');
      }
      final cites = (map['citations'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      return TutorAnswer(
        answer: answer.trim(),
        citations: cites,
        ragMode: map['ragMode']?.toString(),
        uncited: map['uncited'] == true,
        hasLocalBase: map['hasLocalBase'] != false,
      );
    } on ApiException catch (e) {
      throw AiTutorException(e.message);
    } catch (e) {
      throw AiTutorException(humanApiError(e, fallback: 'Não deu para falar com o Tutor IA.'));
    }
  }
}
