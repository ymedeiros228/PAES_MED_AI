import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../data/library_api.dart';

class LibraryState {
  const LibraryState({
    this.library,
    this.coverage,
    this.curation,
    this.error,
    this.msg,
    this.partialLoadNote,
    this.busy = false,
    this.searchHits = const [],
    this.searchNote,
    this.searchHistoryNote,
    this.searching = false,
    this.searchSourceKind = 'todos',
    this.searchHistory = const [],
    this.hitSelected = 0,
    this.showFirstRunCoach = false,
    this.studyPdfs = const [],
    this.pdfsLoaded = false,
  });

  final Map<String, dynamic>? library;
  final Map<String, dynamic>? coverage;
  final Map<String, dynamic>? curation;
  final String? error;
  final String? msg;
  final String? partialLoadNote;
  final bool busy;
  final List<Map<String, dynamic>> searchHits;
  final String? searchNote;
  final String? searchHistoryNote;
  final bool searching;
  final String searchSourceKind;
  final List<Map<String, dynamic>> searchHistory;
  final int hitSelected;
  final bool showFirstRunCoach;
  final List<Map<String, dynamic>> studyPdfs;
  final bool pdfsLoaded;

  LibraryState copyWith({
    Map<String, dynamic>? library,
    Map<String, dynamic>? coverage,
    Map<String, dynamic>? curation,
    String? error,
    String? msg,
    String? partialLoadNote,
    bool? busy,
    List<Map<String, dynamic>>? searchHits,
    String? searchNote,
    String? searchHistoryNote,
    bool? searching,
    String? searchSourceKind,
    List<Map<String, dynamic>>? searchHistory,
    int? hitSelected,
    bool? showFirstRunCoach,
    List<Map<String, dynamic>>? studyPdfs,
    bool? pdfsLoaded,
    bool clearError = false,
    bool clearMsg = false,
    bool clearSearchNote = false,
  }) {
    return LibraryState(
      library: library ?? this.library,
      coverage: coverage ?? this.coverage,
      curation: curation ?? this.curation,
      error: clearError ? null : (error ?? this.error),
      msg: clearMsg ? null : (msg ?? this.msg),
      partialLoadNote: partialLoadNote ?? this.partialLoadNote,
      busy: busy ?? this.busy,
      searchHits: searchHits ?? this.searchHits,
      searchNote: clearSearchNote ? null : (searchNote ?? this.searchNote),
      searchHistoryNote: searchHistoryNote ?? this.searchHistoryNote,
      searching: searching ?? this.searching,
      searchSourceKind: searchSourceKind ?? this.searchSourceKind,
      searchHistory: searchHistory ?? this.searchHistory,
      hitSelected: hitSelected ?? this.hitSelected,
      showFirstRunCoach: showFirstRunCoach ?? this.showFirstRunCoach,
      studyPdfs: studyPdfs ?? this.studyPdfs,
      pdfsLoaded: pdfsLoaded ?? this.pdfsLoaded,
    );
  }
}

final libraryControllerProvider =
    StateNotifierProvider<LibraryController, LibraryState>((ref) {
  return LibraryController(ref);
});

/// Estado e chamadas HTTP do acervo — diálogos e navegação ficam na tela.
class LibraryController extends StateNotifier<LibraryState> {
  LibraryController(this._ref) : super(const LibraryState());

  final Ref _ref;

  void setMsg(String? message) => state = state.copyWith(msg: message);

  void setSearchSourceKind(String kind) =>
      state = state.copyWith(searchSourceKind: kind);

  void setHitSelected(int index) => state = state.copyWith(hitSelected: index);

  void clearSearchResults() => state = state.copyWith(
        searchHits: [],
        clearSearchNote: true,
        hitSelected: 0,
      );

  void bumpRefreshTick() => _ref.read(refreshTickProvider.notifier).state++;

  Future<void> loadFirstRunCoach() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      showFirstRunCoach: prefs.getBool('first_run_coach_pending') ?? false,
    );
  }

  Future<void> dismissFirstRunCoach() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_run_coach_pending', false);
    state = state.copyWith(showFirstRunCoach: false);
  }

  Future<void> load() async {
    state = state.copyWith(busy: true, clearError: true, partialLoadNote: null);
    try {
      final data = await LibraryApi.fetchLibrary();
      Map<String, dynamic>? cov;
      Map<String, dynamic>? cur;
      String? partialNote;
      try {
        cov = Map<String, dynamic>.from(await LibraryApi.fetchCoverage() as Map);
      } catch (e) {
        partialNote = humanApiError(e, fallback: 'Cobertura do edital indisponível.');
      }
      try {
        cur = Map<String, dynamic>.from(await LibraryApi.fetchCurationInventory() as Map);
      } catch (e) {
        partialNote ??= humanApiError(e, fallback: 'Inventário de curadoria indisponível.');
      }
      state = state.copyWith(
        library: Map<String, dynamic>.from(data as Map),
        coverage: cov,
        curation: cur,
        partialLoadNote: partialNote,
      );
      await loadStudyPdfs();
    } catch (e) {
      state = state.copyWith(
        error: humanApiError(e, fallback: 'Não deu para carregar a Biblioteca. Tente de novo.'),
      );
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<void> loadSearchHistory() async {
    try {
      final map = await LibraryApi.fetchSearchHistory();
      state = state.copyWith(
        searchHistory: (map['items'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
        searchHistoryNote: null,
      );
    } catch (e) {
      state = state.copyWith(
        searchHistory: [],
        searchHistoryNote: humanApiError(e, fallback: 'Histórico de buscas indisponível.'),
      );
    }
  }

  Future<void> runSearch(String query) async {
    if (query.trim().isEmpty) {
      clearSearchResults();
      return;
    }
    state = state.copyWith(searching: true);
    try {
      final map = await LibraryApi.search(query: query, sourceKind: state.searchSourceKind);
      state = state.copyWith(
        searchHits: (map['items'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
        searchNote: map['note']?.toString(),
        hitSelected: 0,
      );
      await loadSearchHistory();
    } catch (e) {
      state = state.copyWith(
        searchHits: [],
        searchNote: humanApiError(e, fallback: 'Busca indisponível agora. Tente de novo.'),
      );
    } finally {
      state = state.copyWith(searching: false);
    }
  }

  Future<void> loadStudyPdfs() async {
    try {
      final list = await LibraryApi.fetchPdfList();
      state = state.copyWith(studyPdfs: list, pdfsLoaded: true);
    } catch (_) {
      state = state.copyWith(pdfsLoaded: true);
    }
  }

  Future<Map<String, dynamic>> semana1Bootstrap() async {
    state = state.copyWith(busy: true, msg: 'Semana 1: atualizando 2024–26…');
    try {
      return await LibraryApi.semana1Bootstrap();
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<Map<String, dynamic>> commitOnDisk() async {
    state = state.copyWith(busy: true, msg: 'Gravando PDFs no acervo…');
    try {
      return await LibraryApi.commitOnDisk();
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<Map<String, dynamic>> importAllComplete() async {
    state = state.copyWith(busy: true, msg: 'Importando todos os pares com gabarito…');
    try {
      return await LibraryApi.importAllComplete();
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<Map<String, dynamic>> importYearSafe(int year) async {
    state = state.copyWith(busy: true, msg: 'Importando do PC · PAES $year…');
    try {
      return await LibraryApi.importYearSafe(year);
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<Map<String, dynamic>> bootstrapAndCommitYear(int year) async {
    state = state.copyWith(busy: true, msg: 'Gravando PAES $year no acervo…');
    try {
      return await LibraryApi.bootstrapAndCommitYear(year);
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<Map<String, dynamic>> importYearPreview(int year) async {
    state = state.copyWith(busy: true, msg: 'Importando $year para revisão...');
    try {
      return await LibraryApi.importYearPreview(year);
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<Map<String, dynamic>> fetchYear(int year) async {
    state = state.copyWith(busy: true, msg: 'Baixando oficiais PAES $year...');
    try {
      return await LibraryApi.fetchYear(year);
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<void> classifyPending() async {
    state = state.copyWith(busy: true);
    try {
      await LibraryApi.classifyPending();
      state = state.copyWith(msg: 'Classificação concluída');
      await load();
    } catch (e) {
      state = state.copyWith(msg: humanApiError(e, fallback: 'Não deu para concluir. Tente de novo.'));
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<void> syncEdital() async {
    state = state.copyWith(busy: true);
    try {
      final data = await LibraryApi.syncEdital();
      state = state.copyWith(msg: 'Syllabus: $data');
      await load();
    } catch (e) {
      state = state.copyWith(msg: humanApiError(e, fallback: 'Não deu para concluir. Tente de novo.'));
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<void> fixQuestions() async {
    state = state.copyWith(busy: true);
    try {
      final data = await LibraryApi.fixQuestions();
      final msgStr =
          data is Map ? (data['message']?.toString() ?? 'Correção concluída') : 'Correção concluída';
      state = state.copyWith(msg: msgStr);
      await load();
    } catch (e) {
      state = state.copyWith(msg: humanApiError(e, fallback: 'Não deu para corrigir agora. Tente de novo.'));
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<String> openFolder(String folder) async {
    final data = await LibraryApi.openFolder(folder);
    final path = (data as Map)['path']?.toString() ?? folder;
    state = state.copyWith(msg: 'Pasta aberta: $path');
    return path;
  }

  Future<String> openPortal(String portal) async {
    try {
      final data = await LibraryApi.openUrl(portal);
      final url = data['url']?.toString() ?? portal;
      state = state.copyWith(msg: 'Portal aberto no navegador: $url');
      return url;
    } catch (e) {
      final err = humanApiError(
        e,
        fallback: 'Portal: $portal — abra no navegador e drope paes_YYYY.pdf / gabarito_YYYY.pdf.',
      );
      state = state.copyWith(msg: err);
      rethrow;
    }
  }

  Future<void> openSearchPath(Map<String, dynamic> hit) async {
    final path = hit['path']?.toString() ?? '';
    if (path.isEmpty) return;
    try {
      await LibraryApi.openPath(path);
      state = state.copyWith(msg: 'Abrindo ${hit['label'] ?? path}');
    } catch (e) {
      state = state.copyWith(
        msg: humanOpenPathError(e, label: hit['label']?.toString() ?? 'Arquivo'),
      );
    }
  }
}
