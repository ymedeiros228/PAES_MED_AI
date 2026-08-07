import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import '../../features/questions/domain/question.dart';

final refreshTickProvider = StateProvider<int>((ref) => 0);

List<dynamic> _asJsonList(dynamic data) {
  if (data is List) return data;
  if (data is Map) {
    final items = data['items'] ?? data['questions'] ?? data['rows'];
    if (items is List) return items;
  }
  return const [];
}

Map<String, dynamic> _asJsonMap(dynamic data) {
  if (data is Map) return Map<String, dynamic>.from(data);
  return <String, dynamic>{};
}

/// keepAlive implícito (sem autoDispose): troca de filtros ainda refaz o load,
/// mas sair da tela e voltar não recomeça do zero e evita “reload loop”.
final questionsProvider =
    FutureProvider.family<List<Question>, String>((ref, filterQuery) async {
  ref.watch(refreshTickProvider);
  final filters = _parseQuery(filterQuery);
  final data = await apiClient.get('/api/questions', filters.isEmpty ? null : filters);
  final out = <Question>[];
  for (final raw in _asJsonList(data)) {
    if (raw is! Map) continue;
    try {
      out.add(Question.fromJson(Map<String, dynamic>.from(raw)));
    } catch (_) {
      // linha quebrada na base: não derruba a lista inteira
    }
  }
  return out;
});

Map<String, String> _parseQuery(String query) {
  if (query.trim().isEmpty) return {};
  final map = <String, String>{};
  for (final part in query.split('&')) {
    if (part.isEmpty) continue;
    final i = part.indexOf('=');
    if (i <= 0) continue;
    final k = Uri.decodeQueryComponent(part.substring(0, i));
    final v = Uri.decodeQueryComponent(part.substring(i + 1));
    if (k.isNotEmpty) map[k] = v;
  }
  return map;
}

/// Codifica filtros em chave estável e ordenada (use no QuestionsScreen).
String encodeQuestionFilters(Map<String, String> filters) {
  if (filters.isEmpty) return '';
  final keys = filters.keys.toList()..sort();
  return keys
      .map((k) => '${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(filters[k] ?? '')}')
      .join('&');
}

/// keepAlive (sem autoDispose): Hoje reusa entre navegações sem cold fetch.
final dashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  final data = await apiClient.get('/api/dashboard');
  return _asJsonMap(data);
});

final frequencyProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return _asJsonList(await apiClient.get('/api/stats/frequency'));
});

final medicineProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  final data = await apiClient.get('/api/stats/medicine');
  return _asJsonMap(data);
});

final bankProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  final data = await apiClient.get('/api/stats/bank-profile');
  return _asJsonMap(data);
});

final lessonsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return _asJsonList(await apiClient.get('/api/lessons'));
});

final essaysProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return _asJsonList(await apiClient.get('/api/essays'));
});

final revisionsApiProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return _asJsonList(await apiClient.get('/api/revisions'));
});

final flashcardsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return _asJsonList(await apiClient.get('/api/flashcards', {'dueOnly': 'true'}));
});

final flashcardsAllProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return _asJsonList(await apiClient.get('/api/flashcards'));
});

final flashcardsAxesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return _asJsonList(await apiClient.get('/api/flashcards', {'axesOnly': 'true'}));
});

/// Caminho gamificado Q&A + redação — keepAlive: trilhas em várias telas
/// sem re-fetch a cada troca de rota.
final studyPathProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  final data = await apiClient.get('/api/study/path');
  return _asJsonMap(data);
});

/// Coach didático (Ciclo JC): fracos + 1 próximo passo honesto.
final studyCoachProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return _asJsonMap(await apiClient.get('/api/study/coach'));
});

/// Status leve do tutor (não bloqueia o chat nem usa /health pesado).
final tutorStatusProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final data = await apiClient.get(
      '/api/tutor/status',
      null,
      ApiClient.healthTimeout,
    );
    return _asJsonMap(data);
  } catch (_) {
    return <String, dynamic>{
      'ok': false,
      'configured': false,
      'mode': 'offline',
      'hint': 'API local indisponível — confira o atalho PAES MED AI.',
    };
  }
});
