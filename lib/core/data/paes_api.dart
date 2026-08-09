import '../../features/questions/domain/question.dart';
import 'api_client.dart';

typedef JsonMap = Map<String, dynamic>;

class PaesApi {
  PaesApi({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  Future<JsonMap> health() => _map(_client.get('/health'));

  Future<List<Question>> questions([Map<String, String>? filters]) async {
    final raw = await _client.get('/api/questions', filters);
    return _questions(raw);
  }

  Future<Question> question(String id) async {
    final raw = await _client.get('/api/questions/$id');
    return Question.fromJson(_asMap(raw));
  }

  Future<JsonMap> dashboard() => _map(_client.get('/api/dashboard'));

  Future<JsonMap> today() => _map(_client.get('/api/today'));

  Future<List<JsonMap>> revisions() => _maps(_client.get('/api/revisions'));

  Future<List<JsonMap>> frequency() =>
      _maps(_client.get('/api/stats/frequency'));

  Future<JsonMap> medicine() => _map(_client.get('/api/stats/medicine'));

  Future<JsonMap> bankProfile() => _map(_client.get('/api/stats/bank-profile'));

  Future<List<JsonMap>> lessons() => _maps(_client.get('/api/lessons'));

  Future<List<JsonMap>> essays() => _maps(_client.get('/api/essays'));

  Future<List<JsonMap>> flashcards(
      {bool dueOnly = false, bool axesOnly = false}) {
    final query = <String, String>{
      if (dueOnly) 'dueOnly': 'true',
      if (axesOnly) 'axesOnly': 'true',
    };
    return _maps(_client.get('/api/flashcards', query.isEmpty ? null : query));
  }

  Future<JsonMap> sessionPlan({
    String? examBoard,
    int? year,
    String? subject,
    String? topic,
    bool? preferNatureza,
  }) {
    final query = <String, String>{
      if (examBoard?.isNotEmpty == true) 'examBoard': examBoard!,
      if (year != null) 'year': '$year',
      if (subject?.isNotEmpty == true) 'subject': subject!,
      if (topic?.isNotEmpty == true) 'topic': topic!,
      if (preferNatureza != null) 'preferNatureza': '$preferNatureza',
    };
    return _map(_client.get('/api/session/plan', query));
  }

  Future<JsonMap> answer(JsonMap payload) =>
      _map(_client.post('/api/answers', payload));

  Future<JsonMap> createSimulation(JsonMap payload) {
    return _map(_client.post('/api/simulations', payload));
  }

  Future<JsonMap> gradeSimulation(JsonMap payload) {
    return _map(_client.post('/api/simulations/grade', payload));
  }

  Future<JsonMap> adaptiveTraining(JsonMap payload) {
    return _map(_client.post('/api/training/adaptive', payload));
  }

  Future<JsonMap> recoverGap(JsonMap payload) {
    return _map(_client.post('/api/gaps/recover', payload));
  }

  Future<JsonMap> _map(Future<dynamic> request) async {
    return _asMap(await request);
  }

  Future<List<JsonMap>> _maps(Future<dynamic> request) async {
    final raw = await request;
    if (raw is! List) {
      throw const FormatException('A API retornou uma lista inválida.');
    }
    return raw.map(_asMap).toList(growable: false);
  }

  List<Question> _questions(dynamic raw) {
    if (raw is! List) {
      throw const FormatException('A API retornou questões inválidas.');
    }
    return raw
        .map((item) => Question.fromJson(_asMap(item)))
        .toList(growable: false);
  }

  JsonMap _asMap(dynamic raw) {
    if (raw is! Map) {
      throw const FormatException('A API retornou um objeto inválido.');
    }
    return Map<String, dynamic>.from(raw);
  }
}

final paesApi = PaesApi();
