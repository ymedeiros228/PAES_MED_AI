import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paes_med_ai/core/data/study_prefs_providers.dart';
import 'package:paes_med_ai/features/ai_tutor/data/ai_tutor_repository.dart';
import 'package:paes_med_ai/features/ai_tutor/domain/chat_message.dart';

class AiTutorState {
  const AiTutorState({
    required this.messages,
    this.isLoading = false,
    this.error,
    this.style = 'professor',
    this.status,
    this.lastModel,
    this.lastProvider,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final String style;
  final TutorStatus? status;
  final String? lastModel;
  final String? lastProvider;

  /// Alias de UI legível (chip).
  TutorStatus? get tutorStatus => status;
  String? get activeModel => lastModel ?? status?.model;
  String? get activeProvider => lastProvider ?? status?.provider;

  String get modeChip {
    if (lastModel != null && lastModel!.isNotEmpty) {
      final p = lastProvider ?? status?.provider ?? '';
      if (p == 'openai') return 'Modelo: $lastModel · online';
      if (p == 'ollama') return 'Ollama:$lastModel · local';
      if (lastModel!.contains('offline') || p == 'offline' || p == 'local') {
        return 'Tutor local (base + pedagogia)';
      }
      return 'Modelo: $lastModel';
    }
    return status?.message ?? 'Tutor local (base + pedagogia)';
  }

  AiTutorState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    String? style,
    TutorStatus? status,
    String? lastModel,
    String? lastProvider,
    bool clearError = false,
  }) {
    return AiTutorState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      style: style ?? this.style,
      status: status ?? this.status,
      lastModel: lastModel ?? this.lastModel,
      lastProvider: lastProvider ?? this.lastProvider,
    );
  }
}

final aiTutorRepositoryProvider = Provider<AiTutorRepository>((ref) {
  return AiTutorRepository();
});

final aiTutorControllerProvider =
    StateNotifierProvider<AiTutorController, AiTutorState>((ref) {
  return AiTutorController(
    ref.watch(aiTutorRepositoryProvider),
    () => ref.read(tutorOnlinePrefProvider),
  );
});

class AiTutorController extends StateNotifier<AiTutorState> {
  AiTutorController(this._repository, this._isOnlinePrefEnabled)
      : super(
          const AiTutorState(
            messages: [
              ChatMessage(
                role: ChatRole.assistant,
                content:
                    'Olá! Sou seu tutor do PAES/UEMA (base local + edital). '
                    'Sem chave OpenAI/Ollama ainda ensino com pedagogia e trechos da base — '
                    'nunca invento % de cobrança ou gabarito ausente. O que estudamos?',
              ),
            ],
          ),
        ) {
    // Status em paralelo ao chat: não bloqueia digitação.
    loadStatus();
  }

  final AiTutorRepository _repository;
  final bool Function() _isOnlinePrefEnabled;

  Future<void> loadStatus() async {
    try {
      final status = await _repository.fetchStatus();
      state = state.copyWith(status: status);
    } catch (_) {
      // status é soft — chat local segue usable
    }
  }

  /// Alias usado pela UI.
  Future<void> refreshStatus() => loadStatus();

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
      final preferOffline = !_isOnlinePrefEnabled();
      final answer = await _repository.ask(
        message: text,
        history: previousHistory,
        style: state.style,
        preferOffline: preferOffline,
      );
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            role: ChatRole.assistant,
            content: answer.answer,
            citations: answer.citations,
            uncited: answer.uncited,
            hasLocalBase: answer.hasLocalBase,
            model: answer.model,
            provider: answer.provider,
          ),
        ],
        isLoading: false,
        lastModel: answer.model,
        lastProvider: answer.provider,
        clearError: true,
      );
      // Soft refresh status (model/provider chip)
      loadStatus();
    } on AiTutorException catch (error) {
      state = state.copyWith(isLoading: false, error: error.message);
    }
  }

  void clearConversation() {
    state = AiTutorState(
      style: state.style,
      status: state.status,
      lastModel: state.lastModel,
      lastProvider: state.lastProvider,
      messages: const [
        ChatMessage(
          role: ChatRole.assistant,
          content: 'Conversa reiniciada. Qual conteúdo do edital/provas deseja estudar agora?',
        ),
      ],
    );
  }
}
