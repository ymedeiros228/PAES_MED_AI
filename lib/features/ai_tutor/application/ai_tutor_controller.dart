import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paes_med_ai/features/ai_tutor/data/ai_tutor_repository.dart';
import 'package:paes_med_ai/features/ai_tutor/domain/chat_message.dart';

class AiTutorState {
  const AiTutorState({
    required this.messages,
    this.isLoading = false,
    this.error,
    this.style = 'professor',
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final String style;

  AiTutorState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    String? style,
    bool clearError = false,
  }) {
    return AiTutorState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      style: style ?? this.style,
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
                    'Olá! Sou seu tutor calibrado no PAES/UEMA (base local + edital). '
                    'Não invento estatísticas. Posso explicar como professor, fazer macetes, mapas e cartões de estudo. O que estudamos?',
              ),
            ],
          ),
        );

  final AiTutorRepository _repository;

  void setStyle(String style) {
    state = state.copyWith(style: style);
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
      );
      final localizedAnswer = answer.answer.replaceAllMapped(
        RegExp(r'\bStep\s+(\d+)\b', caseSensitive: false),
        (match) => 'Passo ${match.group(1)}',
      );
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            role: ChatRole.assistant,
            content: localizedAnswer,
            citations: answer.citations,
            uncited: answer.uncited,
            hasLocalBase: answer.hasLocalBase,
            model: answer.model,
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
      messages: const [
        ChatMessage(
          role: ChatRole.assistant,
          content:
              'Conversa reiniciada. Qual conteúdo do edital/provas deseja estudar agora?',
        ),
      ],
    );
  }
}
