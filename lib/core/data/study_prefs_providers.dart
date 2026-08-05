import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/onboarding/presentation/onboarding_screen.dart';
import 'api_client.dart';

final focusModeProvider = StateNotifierProvider<FocusModeNotifier, bool>((ref) {
  return FocusModeNotifier();
});

class FocusModeNotifier extends StateNotifier<bool> {
  FocusModeNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    // Default ON (ciclo I): primeira abertura foca estudar, não Analytics.
    if (!p.containsKey(StudyPrefs.focusModeKey)) {
      await p.setBool(StudyPrefs.focusModeKey, true);
      state = true;
      return;
    }
    state = p.getBool(StudyPrefs.focusModeKey) ?? true;
  }

  Future<void> setFocus(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(StudyPrefs.focusModeKey, value);
    state = value;
  }
}

final examDateProvider = StateNotifierProvider<ExamDateNotifier, String>((ref) {
  return ExamDateNotifier();
});

class ExamDateNotifier extends StateNotifier<String> {
  ExamDateNotifier() : super('') {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final local = p.getString(StudyPrefs.examDateKey) ?? '';
    if (local.isNotEmpty) {
      state = local;
      return;
    }
    // Ciclo CH: hydrate do backend se prefs local vazia (local wins se já tem).
    try {
      final raw = await apiClient.get('/api/study/exam-date');
      final apiDate = (raw is Map ? raw['examDate'] : null)?.toString().trim() ?? '';
      if (apiDate.isNotEmpty && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(apiDate)) {
        await p.setString(StudyPrefs.examDateKey, apiDate);
        state = apiDate;
        return;
      }
    } catch (_) {}
    state = '';
  }

  Future<void> setDate(String iso) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(StudyPrefs.examDateKey, iso);
    state = iso;
    // Sync com backend (Ciclo F) — contagem no coach/Hoje
    try {
      await apiClient.post('/api/study/exam-date', {
        'examDate': iso.trim().isEmpty ? null : iso.trim(),
      });
    } catch (_) {
      // offline / API morta: pref local continua válida
    }
  }

  int? get daysUntilExam {
    if (state.isEmpty) return null;
    try {
      final d = DateTime.parse(state);
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
