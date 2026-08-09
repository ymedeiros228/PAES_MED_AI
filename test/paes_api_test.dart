import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:paes_med_ai/core/data/api_client.dart';
import 'package:paes_med_ai/core/data/paes_api.dart';

class _FakeClient extends http.BaseClient {
  _FakeClient(this.handler);

  final Future<http.Response> Function(http.Request request) handler;

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return handler(http.Request('GET', url));
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request as http.Request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

Map<String, dynamic> _questionJson() => {
      'id': 'q-1',
      'year': 2024,
      'subject': 'Biologia',
      'topic': 'Genetica',
      'statement': 'Qual alternativa está correta?',
      'options': ['A', 'B', 'C', 'D', 'E'],
      'correctIndex': 2,
      'difficulty': 'media',
    };

void main() {
  test('converte a lista de questões em Question', () async {
    final api = PaesApi(
      client: ApiClient(
        client: _FakeClient(
          (_) async => http.Response.bytes(
              utf8.encode(jsonEncode([_questionJson()])), 200),
        ),
      ),
    );

    final questions = await api.questions();

    expect(questions, hasLength(1));
    expect(questions.single.id, 'q-1');
    expect(questions.single.options, ['A', 'B', 'C', 'D', 'E']);
  });

  test('rejeita resposta que não é uma lista de revisões', () {
    final api = PaesApi(
      client: ApiClient(
        client: _FakeClient(
          (_) async =>
              http.Response.bytes(utf8.encode(jsonEncode({'items': []})), 200),
        ),
      ),
    );

    expect(api.revisions(), throwsA(isA<FormatException>()));
  });
}
