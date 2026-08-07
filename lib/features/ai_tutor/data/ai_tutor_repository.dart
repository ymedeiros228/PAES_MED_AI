import 'package:paes_med_ai/core/data/api_client.dart';
import 'package:paes_med_ai/core/data/api_error.dart';
import 'package:paes_med_ai/features/ai_tutor/domain/chat_message.dart';

class AiTutorException implements Exception {
  const AiTutorException(this.message);
  final String message;
  @override
  String toString() => message;
}

class TutorStatus {
  const TutorStatus({
    required this.ok,
    required this.provider,
    required this.model,
    required this.message,
    this.configured = false,
    this.openaiConfigured = false,
    this.ollamaConfigured = false,
    this.hint,
    this.lastError,
  });

  final bool ok;
  final String provider;
  final String model;
  final String message;
  final bool configured;
  final bool openaiConfigured;
  final bool ollamaConfigured;
  final String? hint;
  final String? lastError;

  factory TutorStatus.fromJson(Map<String, dynamic> map) {
    final provider = map['provider']?.toString() ?? 'offline';
    final model = map['model']?.toString() ?? 'offline-tutor-v2';
    final message = map['message']?.toString() ??
        (provider == 'openai'
            ? 'Modelo: $model · online'
            : provider == 'ollama'
                ? 'Ollama:$model · local'
                : 'Tutor local (base + pedagogia)');
    return TutorStatus(
      ok: map['ok'] != false,
      provider: provider,
      model: model,
      message: message,
      configured: map['configured'] == true ||
          map['openai_configured'] == true ||
          map['ollama_configured'] == true,
      openaiConfigured: map['openai_configured'] == true,
      ollamaConfigured: map['ollama_configured'] == true,
      hint: map['hint']?.toString(),
      lastError: map['lastError']?.toString(),
    );
  }
}

class TutorAnswer {
  const TutorAnswer({
    required this.answer,
    this.citations = const [],
    this.ragMode,
    this.uncited = false,
    this.hasLocalBase = true,
    this.model,
    this.provider,
  });
  final String answer;
  final List<Map<String, dynamic>> citations;
  final String? ragMode;
  final bool uncited;
  final bool hasLocalBase;
  final String? model;
  final String? provider;
}

class AiTutorRepository {
  Future<TutorStatus> fetchStatus() async {
    try {
      final data = await apiClient.get(
        '/api/tutor/status',
        null,
        ApiClient.healthTimeout,
      );
      return TutorStatus.fromJson(Map<String, dynamic>.from(data as Map));
    } on ApiException catch (e) {
      throw AiTutorException(e.message);
    } catch (e) {
      throw AiTutorException(humanApiError(e, fallback: 'Não deu para ler o status do Tutor.'));
    }
  }

  Future<TutorAnswer> ask({
    required String message,
    required List<ChatMessage> history,
    String style = 'professor',
    bool preferOffline = false,
  }) async {
    try {
      final data = await apiClient.post('/api/chat', {
        'message': message,
        'style': style,
        'history': history.map((item) => item.toJson()).toList(),
        'preferOffline': preferOffline,
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
        model: map['model']?.toString(),
        provider: map['provider']?.toString(),
      );
    } on ApiException catch (e) {
      throw AiTutorException(e.message);
    } catch (e) {
      throw AiTutorException(humanApiError(e, fallback: 'Não deu para falar com o Tutor IA.'));
    }
  }
}
