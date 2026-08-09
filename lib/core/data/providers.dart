import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'paes_api.dart';
import '../../features/questions/domain/question.dart';

final refreshTickProvider = StateProvider<int>((ref) => 0);

final questionsProvider = FutureProvider.autoDispose
    .family<List<Question>, Map<String, String>>((ref, filters) async {
  ref.watch(refreshTickProvider);
  return paesApi.questions(filters.isEmpty ? null : filters);
});

final dashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return paesApi.dashboard();
});

final frequencyProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return paesApi.frequency();
});

final medicineProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return paesApi.medicine();
});

final bankProfileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return paesApi.bankProfile();
});

final lessonsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return paesApi.lessons();
});

final essaysProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return paesApi.essays();
});

final revisionsApiProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return paesApi.revisions();
});

final flashcardsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return paesApi.flashcards(dueOnly: true);
});

final flashcardsAllProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return paesApi.flashcards();
});

final flashcardsAxesProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return paesApi.flashcards(axesOnly: true);
});
