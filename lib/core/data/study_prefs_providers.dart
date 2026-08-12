import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'api_error.dart';

/// Chaves de preferências persistidas em SharedPreferences.
class StudyPrefs {
  static const focusModeKey = 'focus_mode';
  static const examDateKey = 'exam_date';
}

final focusModeProvider = StateNotifierProvider<FocusModeNotifier, bool>((ref) {
  return FocusModeNotifier();
});

class FocusModeNotifier extends StateNotifier<bool> {
  FocusModeNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    // Default OFF: novos usuários veem todos os recursos.
    if (!p.containsKey(StudyPrefs.focusModeKey)) {
      await p.setBool(StudyPrefs.focusModeKey, false);
      state = false;
      return;
    }
    state = p.getBool(StudyPrefs.focusModeKey) ?? false;
  }

  Future<void> setFocus(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(StudyPrefs.focusModeKey, value);
    state = value;
  }
}

class ExamDateState {
  const ExamDateState({
    this.date = '',
    this.syncError,
    this.hydrateNote,
  });

  final String date;
  final String? syncError;
  final String? hydrateNote;

  ExamDateState copyWith({
    String? date,
    String? syncError,
    bool clearSyncError = false,
    String? hydrateNote,
    bool clearHydrateNote = false,
  }) {
    return ExamDateState(
      date: date ?? this.date,
      syncError: clearSyncError ? null : (syncError ?? this.syncError),
      hydrateNote: clearHydrateNote ? null : (hydrateNote ?? this.hydrateNote),
    );
  }
}

final examDateProvider = StateNotifierProvider<ExamDateNotifier, ExamDateState>((ref) {
  return ExamDateNotifier();
});

class ExamDateNotifier extends StateNotifier<ExamDateState> {
  ExamDateNotifier() : super(const ExamDateState()) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final local = p.getString(StudyPrefs.examDateKey) ?? '';
    if (local.isNotEmpty) {
      state = ExamDateState(date: local);
      return;
    }
    // Ciclo CH: hydrate do backend se prefs local vazia (local wins se já tem).
    try {
      final raw = await apiClient.get('/api/study/exam-date');
      final apiDate = (raw is Map ? raw['examDate'] : null)?.toString().trim() ?? '';
      if (apiDate.isNotEmpty && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(apiDate)) {
        await p.setString(StudyPrefs.examDateKey, apiDate);
        state = ExamDateState(date: apiDate);
        return;
      }
    } catch (e) {
      state = ExamDateState(
        hydrateNote: humanApiError(
          e,
          fallback: 'Data da prova não veio do servidor — defina em Ajustes.',
        ),
      );
      return;
    }
    state = const ExamDateState();
  }

  Future<void> setDate(String iso) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(StudyPrefs.examDateKey, iso);
    state = state.copyWith(date: iso, clearSyncError: true, clearHydrateNote: true);
    // Sync com backend (Ciclo F) — contagem no coach/Hoje
    try {
      await apiClient.post('/api/study/exam-date', {
        'examDate': iso.trim().isEmpty ? null : iso.trim(),
      });
      state = state.copyWith(clearSyncError: true, clearHydrateNote: true);
    } catch (e) {
      state = state.copyWith(
        syncError: humanApiError(
          e,
          fallback: 'Data salva localmente, mas não sincronizou com a API.',
        ),
      );
    }
  }

  Future<void> retrySync() async => setDate(state.date);

  int? get daysUntilExam {
    if (state.date.isEmpty) return null;
    try {
      final d = DateTime.parse(state.date);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return d.difference(today).inDays;
    } catch (_) {
      return null;
    }
  }
}

final tutorOnlinePrefProvider = StateNotifierProvider<TutorOnlinePrefNotifier, bool>((ref) {
  return TutorOnlinePrefNotifier();
});

class TutorOnlinePrefNotifier extends StateNotifier<bool> {
  TutorOnlinePrefNotifier() : super(true) {
    _load();
  }

  static const _key = 'tutor_openai_pref';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = p.getBool(_key) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, value);
    state = value;
  }
}
