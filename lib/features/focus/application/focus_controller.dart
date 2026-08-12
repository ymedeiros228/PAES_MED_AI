import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paes_med_ai/core/data/api_client.dart';
import 'package:paes_med_ai/core/data/api_error.dart';

class FocusQuestion {
  const FocusQuestion({
    required this.id,
    required this.statement,
    required this.options,
    required this.correctIndex,
    required this.subject,
    required this.topic,
    required this.year,
    this.resolution,
  });

  final String id;
  final String statement;
  final List<String> options;
  final int correctIndex;
  final String subject;
  final String topic;
  final int year;
  final String? resolution;
}

class FocusState {
  const FocusState({
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedIndex,
    this.revealed = false,
    this.isLoading = false,
    this.error,
    this.subject,
    this.year,
    this.correctCount = 0,
    this.wrongIds = const [],
    this.elapsedSeconds = 0,
    this.questionStartSeconds = 0,
    this.finished = false,
  });

  final List<FocusQuestion> questions;
  final int currentIndex;
  final int? selectedIndex;
  final bool revealed;
  final bool isLoading;
  final String? error;
  final String? subject;
  final int? year;
  final int correctCount;
  final List<String> wrongIds;
  final int elapsedSeconds;
  final int questionStartSeconds;
  final bool finished;

  FocusQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  int get total => questions.length;
  int get answeredCount => currentIndex + (revealed ? 1 : 0);

  FocusState copyWith({
    List<FocusQuestion>? questions,
    int? currentIndex,
    int? selectedIndex,
    bool? revealed,
    bool? isLoading,
    String? error,
    String? subject,
    int? year,
    int? correctCount,
    List<String>? wrongIds,
    int? elapsedSeconds,
    int? questionStartSeconds,
    bool? finished,
    bool clearError = false,
  }) {
    return FocusState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      revealed: revealed ?? this.revealed,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      subject: subject ?? this.subject,
      year: year ?? this.year,
      correctCount: correctCount ?? this.correctCount,
      wrongIds: wrongIds ?? this.wrongIds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      questionStartSeconds: questionStartSeconds ?? this.questionStartSeconds,
      finished: finished ?? this.finished,
    );
  }
}

final focusControllerProvider =
    StateNotifierProvider<FocusController, FocusState>((ref) {
  return FocusController();
});

class FocusController extends StateNotifier<FocusState> {
  FocusController() : super(const FocusState());

  Timer? _ticker;

  void configure({String? subject, int? year}) {
    state = state.copyWith(subject: subject, year: year);
  }

  Future<void> loadQuestions({int count = 20}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final params = <String, String>{'limit': count.toString()};
      if (state.subject != null && state.subject!.isNotEmpty) {
        params['subject'] = state.subject!;
      }
      if (state.year != null) {
        params['year'] = state.year.toString();
      }
      final qs = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      final data = await apiClient.get('/api/questions?$qs');
      final list = data is List ? data : ((data as Map)['items'] as List? ?? []);
      final questions = <FocusQuestion>[];
      for (final item in list) {
        final m = Map<String, dynamic>.from(item as Map);
        questions.add(FocusQuestion(
          id: m['id']?.toString() ?? '',
          statement: m['statement']?.toString() ?? '',
          options: List<String>.from((m['options'] as List? ?? []).map((e) => e.toString())),
          correctIndex: int.tryParse(m['correctIndex']?.toString() ?? '0') ?? 0,
          subject: m['subject']?.toString() ?? 'Geral',
          topic: m['topic']?.toString() ?? 'Geral',
          year: int.tryParse(m['year']?.toString() ?? '0') ?? 0,
          resolution: m['resolution']?.toString(),
        ));
      }
      if (questions.isEmpty) {
        state = state.copyWith(isLoading: false, error: 'Nenhuma questão encontrada com esses filtros.');
        return;
      }
      state = FocusState(
        questions: questions,
        subject: state.subject,
        year: state.year,
        isLoading: false,
        questionStartSeconds: 0,
      );
      _startTicker();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: humanApiError(e, fallback: 'Não deu para carregar questões.'));
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(
        elapsedSeconds: state.elapsedSeconds + 1,
        questionStartSeconds: state.questionStartSeconds + 1,
      );
    });
  }

  void selectOption(int index) {
    if (state.revealed) return;
    state = state.copyWith(selectedIndex: index);
  }

  void revealAnswer() {
    if (state.selectedIndex == null || state.revealed) return;
    final q = state.currentQuestion;
    if (q == null) return;
    final isCorrect = state.selectedIndex == q.correctIndex;
    state = state.copyWith(
      revealed: true,
      correctCount: state.correctCount + (isCorrect ? 1 : 0),
      wrongIds: isCorrect ? state.wrongIds : [...state.wrongIds, q.id],
    );
  }

  void nextQuestion() {
    if (!state.revealed) return;
    if (state.currentIndex + 1 >= state.questions.length) {
      _ticker?.cancel();
      state = state.copyWith(finished: true);
      return;
    }
    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      selectedIndex: null,
      revealed: false,
      questionStartSeconds: 0,
    );
  }

  void reset() {
    _ticker?.cancel();
    state = FocusState(subject: state.subject, year: state.year);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
