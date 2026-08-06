import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import '../../features/questions/domain/question.dart';

final refreshTickProvider = StateProvider<int>((ref) => 0);

final questionsProvider = FutureProvider.autoDispose.family<List<Question>, Map<String, String>>((ref, filters) async {
  ref.watch(refreshTickProvider);
  final data = await apiClient.get('/api/questions', filters.isEmpty ? null : filters);
  return (data as List).map((e) => Question.fromJson(Map<String, dynamic>.from(e as Map))).toList();
});

final dashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  final data = await apiClient.get('/api/dashboard');
  return Map<String, dynamic>.from(data as Map);
});

final frequencyProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return await apiClient.get('/api/stats/frequency') as List<dynamic>;
});

final medicineProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  final data = await apiClient.get('/api/stats/medicine');
  return Map<String, dynamic>.from(data as Map);
});

final bankProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  final data = await apiClient.get('/api/stats/bank-profile');
  return Map<String, dynamic>.from(data as Map);
});

final lessonsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return await apiClient.get('/api/lessons') as List<dynamic>;
});

final essaysProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return await apiClient.get('/api/essays') as List<dynamic>;
});

/// Progresso de redação (eixos, streak, missão). Centraliza a chamada usada por
/// Redação, Hoje e Dashboard, evitando 3 requisições duplicadas.
final essayProgressProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  final data = await apiClient.get('/api/essays/progress');
  return Map<String, dynamic>.from(data as Map);
});

final revisionsApiProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return await apiClient.get('/api/revisions') as List<dynamic>;
});

final flashcardsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return await apiClient.get('/api/flashcards', {'dueOnly': 'true'}) as List<dynamic>;
});

final flashcardsAllProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return await apiClient.get('/api/flashcards') as List<dynamic>;
});

final flashcardsAxesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return await apiClient.get('/api/flashcards', {'axesOnly': 'true'}) as List<dynamic>;
});
