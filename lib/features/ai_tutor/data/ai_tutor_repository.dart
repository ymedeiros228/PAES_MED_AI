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
    this.preferOfficial,
  });
  final String answer;
  final List<Map<String, dynamic>> citations;
  final String? ragMode;
  final bool uncited;
  final bool hasLocalBase;
  final bool? preferOfficial;

  /// Sucesso F3: tem fontes OU recusa explícita (uncited + motivo).
  bool get isGroundedOk => citations.isNotEmpty || uncited;
}

class AiTutorRepository {
  Future<TutorAnswer> ask({
    required String message,
    required List<ChatMessage> history,
    String style = 'professor',
    bool? preferOfficial,
  }) async {
    try {
      final body = <String, dynamic>{
        'message': message,
        'style': style,
        'history': history.map((item) => item.toJson()).toList(),
      };
      if (preferOfficial != null) {
        body['preferOfficial'] = preferOfficial;
      }
      // F3: alias /api/tutor/ask (mesmo contrato de /api/chat)
      final data = await apiClient.post('/api/tutor/ask', body);
      final map = Map<String, dynamic>.from(data as Map);
      final answer = map['answer']?.toString();
      if (answer == null || answer.trim().isEmpty) {
        throw const AiTutorException('A IA retornou uma resposta vazia.');
      }
      final cites = (map['citations'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final uncited = map['uncited'] == true;
      final result = TutorAnswer(
        answer: answer.trim(),
        citations: cites,
        ragMode: map['ragMode']?.toString(),
        uncited: uncited,
        hasLocalBase: map['hasLocalBase'] != false,
        preferOfficial: map['preferOfficial'] is bool ? map['preferOfficial'] as bool : null,
      );
      // GZ: bloquear resposta "ok" sem fonte e sem recusa explícita
      if (!result.isGroundedOk) {
        throw const AiTutorException(
          'Resposta sem fonte na base local. Tente de novo ou abra Biblioteca / Sessão.',
        );
      }
      return result;
    } on AiTutorException {
      rethrow;
    } on ApiException catch (e) {
      throw AiTutorException(e.message);
    } catch (e) {
      throw AiTutorException(humanApiError(e, fallback: 'Não deu para falar com o Tutor IA.'));
    }
  }
}
