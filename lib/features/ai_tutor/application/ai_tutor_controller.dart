import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paes_med_ai/features/ai_tutor/data/ai_tutor_repository.dart';
import 'package:paes_med_ai/features/ai_tutor/domain/chat_message.dart';

class AiTutorState {
  const AiTutorState({
    required this.messages,
    this.isLoading = false,
    this.error,
    this.style = 'professor',
    this.preferOfficial = true,
    this.errorType,
    this.contextSubject,
    this.contextTopic,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final String style;
  final bool preferOfficial;
  final String? errorType;
  final String? contextSubject;
  final String? contextTopic;

  AiTutorState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    String? style,
    bool? preferOfficial,
    String? errorType,
    String? contextSubject,
    String? contextTopic,
    bool clearError = false,
    bool clearErrorContext = false,
  }) {
    return AiTutorState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      style: style ?? this.style,
      preferOfficial: preferOfficial ?? this.preferOfficial,
      errorType: clearErrorContext ? null : (errorType ?? this.errorType),
      contextSubject: clearErrorContext ? null : (contextSubject ?? this.contextSubject),
      contextTopic: clearErrorContext ? null : (contextTopic ?? this.contextTopic),
    );
  }
}

final aiTutorRepositoryProvider = Provider<AiTutorRepository>((ref) {
  return AiTutorRepository();
});

final aiTutorControllerProvider =
    StateNotifierProvider<AiTutorController, AiTutorState>((ref) {
  return AiTutorController(ref.watch(aiTutorRepositoryProvider));
});

class AiTutorController extends StateNotifier<AiTutorState> {
  AiTutorController(this._repository)
      : super(
          const AiTutorState(
            messages: [
              ChatMessage(
                role: ChatRole.assistant,
                content:
                    'Olá! Sou seu tutor do PAES/UEMA (base local). '
                    'Diagnosticamos o tipo de erro, explicamos o ponto certo e guiamos o próximo passo — '
                    'sem inventar estatísticas. O que estudamos?',
              ),
            ],
          ),
        );

  final AiTutorRepository _repository;

  void setStyle(String style) {
    state = state.copyWith(style: style);
  }

  void setPreferOfficial(bool value) {
    state = state.copyWith(preferOfficial: value);
  }

  void setErrorContext({
    String? errorType,
    String? subject,
    String? topic,
  }) {
    state = state.copyWith(
      errorType: errorType,
      contextSubject: subject,
      contextTopic: topic,
    );
  }

  Future<void> send(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || state.isLoading) return;

    final previousHistory = List<ChatMessage>.from(state.messages);
    final userMessage = ChatMessage(role: ChatRole.user, content: text);
    state = state.copyWith(
      messages: [...previousHistory, userMessage],
      isLoading: true,
      clearError: true,
    );

    try {
      final answer = await _repository.ask(
        message: text,
        history: previousHistory,
        style: state.style,
        preferOfficial: state.preferOfficial,
        errorType: state.errorType,
        subject: state.contextSubject,
        topic: state.contextTopic,
      );
      // GZ: só commit se grounded (cites) ou uncited explícito
      if (!answer.isGroundedOk) {
        state = state.copyWith(
          isLoading: false,
          error: 'Resposta sem fonte na base local. Tente de novo ou abra Biblioteca.',
        );
        return;
      }
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            role: ChatRole.assistant,
            content: answer.answer,
            citations: answer.citations,
            uncited: answer.uncited,
            hasLocalBase: answer.hasLocalBase,
          ),
        ],
        isLoading: false,
        clearError: true,
      );
    } on AiTutorException catch (error) {
      state = state.copyWith(isLoading: false, error: error.message);
    }
  }

  void clearConversation() {
    state = AiTutorState(
      style: state.style,
      preferOfficial: state.preferOfficial,
      messages: const [
        ChatMessage(
          role: ChatRole.assistant,
          content: 'Conversa reiniciada. Qual conteúdo do edital/provas deseja estudar agora?',
        ),
      ],
    );
  }
}
