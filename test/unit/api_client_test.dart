import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paes_med_ai/core/data/api_client.dart';

void main() {
  group('ApiClient', () {
    test('get decodifica JSON 2xx', () async {
      final client = ApiClient(
        client: MockClient((req) async {
          expect(req.method, 'GET');
          return http.Response(jsonEncode({'status': 'ok'}), 200);
        }),
      );
      final data = await client.get('/health');
      expect(data, {'status': 'ok'});
    });

    test('get repassa query params', () async {
      late Uri seen;
      final client = ApiClient(
        client: MockClient((req) async {
          seen = req.url;
          return http.Response('{}', 200);
        }),
      );
      await client.get('/api/library/search', {'q': 'genetica'});
      expect(seen.queryParameters['q'], 'genetica');
    });

    test('post envia corpo JSON e content-type', () async {
      late http.Request seen;
      final client = ApiClient(
        client: MockClient((req) async {
          seen = req;
          return http.Response(jsonEncode({'ok': true}), 200);
        }),
      );
      final data = await client.post('/api/chat', {'message': 'oi'});
      expect(data, {'ok': true});
      expect(seen.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(seen.body), {'message': 'oi'});
    });

    test('corpo vazio vira mapa vazio', () async {
      final client = ApiClient(
        client: MockClient((req) async => http.Response('', 200)),
      );
      final data = await client.get('/api/noop');
      expect(data, {});
    });

    test('status de erro lança ApiException com detail', () async {
      final client = ApiClient(
        client: MockClient(
          (req) async => http.Response(jsonEncode({'detail': 'Falha X'}), 400),
        ),
      );
      expect(
        () => client.get('/api/boom'),
        throwsA(
          isA<ApiException>().having((e) => e.message, 'message', 'Falha X'),
        ),
      );
    });

    test('erro sem detail usa mensagem padrão de HTTP', () async {
      final client = ApiClient(
        client: MockClient((req) async => http.Response('{}', 500)),
      );
      expect(
        () => client.post('/api/boom', {}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('500'),
          ),
        ),
      );
    });
  });
}
