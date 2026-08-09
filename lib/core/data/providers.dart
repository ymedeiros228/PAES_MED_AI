import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'paes_api.dart';
import '../../features/questions/domain/question.dart';

final refreshTickProvider = StateProvider<int>((ref) => 0);

/// Provider de questões usando string canônica como chave da family.
/// Antes usava Map<String,String> como chave, mas Map usa identidade para
/// ==/hashCode — cada build() criava um novo Map = novo provider = novo fetch
/// = cancelava o anterior = carregamento infinito.
/// Agora a chave é uma string estável ("subject=Bio&year=2024&...").
final questionsProvider = FutureProvider.autoDispose
    .family<List<Question>, String>((ref, filtersKey) async {
  ref.watch(refreshTickProvider);
  final filters = _parseFiltersKey(filtersKey);
  return paesApi.questions(filters.isEmpty ? null : filters);
});

/// Converte Map de filtros em string canônica estável para usar como chave
/// do provider. Ordem determinística garante mesmo key = mesmo provider.
String filtersKey(Map<String, String> filters) {
  if (filters.isEmpty) return '';
  final entries = filters.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries.map((e) => '${e.key}=${e.value}').join('&');
}

Map<String, String> _parseFiltersKey(String key) {
  if (key.isEmpty) return const {};
  final map = <String, String>{};
  for (final part in key.split('&')) {
    final idx = part.indexOf('=');
    if (idx > 0) map[part.substring(0, idx)] = part.substring(idx + 1);
  }
  return map;
}

/// Providers das telas âncora usam keepAlive para preservar o cache
/// entre navegações (stale-while-revalidate): ao voltar para a tela,
/// os dados aparecem instantaneamente e o refreshTick força refetch.
final dashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.keepAlive();
  ref.watch(refreshTickProvider);
  return paesApi.dashboard();
});

final frequencyProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.keepAlive();
  ref.watch(refreshTickProvider);
  return paesApi.frequency();
});

final medicineProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.keepAlive();
  ref.watch(refreshTickProvider);
  return paesApi.medicine();
});

final bankProfileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.keepAlive();
  ref.watch(refreshTickProvider);
  return paesApi.bankProfile();
});

final lessonsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.keepAlive();
  ref.watch(refreshTickProvider);
  return paesApi.lessons();
});

final essaysProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.keepAlive();
  ref.watch(refreshTickProvider);
  return paesApi.essays();
});

final revisionsApiProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.keepAlive();
  ref.watch(refreshTickProvider);
  return paesApi.revisions();
});

final flashcardsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.keepAlive();
  ref.watch(refreshTickProvider);
  return paesApi.flashcards(dueOnly: true);
});

final flashcardsAllProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.keepAlive();
  ref.watch(refreshTickProvider);
  return paesApi.flashcards();
});

final flashcardsAxesProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.keepAlive();
  ref.watch(refreshTickProvider);
  return paesApi.flashcards(axesOnly: true);
});
