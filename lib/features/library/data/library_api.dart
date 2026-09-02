import '../../../core/data/api_client.dart';

/// Chamadas HTTP do acervo/biblioteca — sem UI nem setState.
class LibraryApi {
  LibraryApi._();

  static Future<Map<String, dynamic>> fetchLibrary() async {
    final data = await apiClient.get('/api/library');
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> fetchCoverage() async {
    final data = await apiClient.get('/api/edital/coverage');
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> fetchCurationInventory() async {
    final data = await apiClient.get('/api/curation/inventory');
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> fetchSearchHistory({int limit = 12}) async {
    final data = await apiClient.get('/api/library/search-history', {'limit': '$limit'});
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> search({
    required String query,
    required String sourceKind,
    int limit = 30,
  }) async {
    final params = <String, String>{'q': query, 'limit': '$limit'};
    if (sourceKind == 'oficial' || sourceKind == 'estudo') {
      params['sourceKind'] = sourceKind;
    }
    final data = await apiClient.get('/api/library/search', params);
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<List<Map<String, dynamic>>> fetchPdfList() async {
    final data = await apiClient.get('/api/materials/pdf-list');
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (data is Map && data['items'] is List) {
      return (data['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return const [];
  }

  static Future<Map<String, dynamic>> openUrl(String url) async {
    final data = await apiClient.post('/api/library/open-url', {'url': url});
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> openFolder(String folder) async {
    final data = await apiClient.post('/api/library/open-folder', {'folder': folder});
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> semana1Bootstrap() async {
    final data = await apiClient.post('/api/acervo/bootstrap-and-commit-available', {
      'dryRun': false,
      'overwrite': false,
      'minConfidence': 0.55,
      'skipCommitted': true,
      'autoProfessor': true,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<void> classifyPending() async {
    await apiClient.post('/api/ingest/classify-pending', {});
  }

  static Future<Map<String, dynamic>> commitOnDisk() async {
    final data = await apiClient.post('/api/acervo/commit-on-disk', {
      'dryRun': false,
      'minConfidence': 0.55,
      'skipCommitted': true,
      'autoProfessor': true,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> importAllComplete() async {
    final data = await apiClient.post('/api/acervo/import-all-complete', {
      'minConfidence': 0.55,
      'skipIfCommitted': false,
      'classifyAfter': true,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> importYearSafe(int year) async {
    final data = await apiClient.post('/api/acervo/import-year-safe', {
      'year': year,
      'commit': true,
      'minConfidence': 0.55,
      'skipIfCommitted': false,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> parseGate({
    Map<String, dynamic>? yearHealth,
    Map<String, dynamic>? pending,
  }) async {
    final data = await apiClient.post('/api/acervo/parse-gate', {
      if (yearHealth != null) 'yearHealth': yearHealth,
      if (pending != null) 'pending': pending,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> bootstrapAndCommitYear(int year) async {
    final data = await apiClient.post('/api/acervo/bootstrap-and-commit', {
      'dryRun': false,
      'overwrite': false,
      'year': year,
      'minConfidence': 0.55,
      'autoProfessor': true,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> importYearPreview(int year) async {
    final data = await apiClient.post('/api/ingest/import-year', {'year': year, 'commit': false});
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> fetchYear(int year) async {
    final data = await apiClient.post('/api/acervo/fetch-year', {
      'year': year,
      'dryRun': false,
      'overwrite': false,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<dynamic> syncEdital() async {
    return apiClient.post('/api/edital/sync-syllabus', {});
  }

  static Future<dynamic> fixQuestions() async {
    return apiClient.post('/api/library/fix-questions', {});
  }

  static Future<void> openPath(String path) async {
    await apiClient.openPath(path);
  }
}
