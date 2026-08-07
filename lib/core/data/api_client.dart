import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Concurrent same-URL GET short-circuit (Hoje, packs duplicados).
  final Map<String, Future<dynamic>> _inflightGet = {};

  String get baseUrl {
    if (_configuredBaseUrl.trim().isNotEmpty) {
      return _configuredBaseUrl.trim().replaceFirst(RegExp(r'/$'), '');
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  /// GETs de tela (lista/dashboard): falha rápido se API local caída.
  static const Duration listTimeout = Duration(seconds: 12);
  /// Health/status leve (banner, chip tutor).
  static const Duration healthTimeout = Duration(seconds: 3);
  /// POSTs longos (ingest/IA).
  static const Duration longTimeout = Duration(seconds: 180);

  Future<dynamic> get(
    String path, [
    Map<String, String>? query,
    Duration? timeout,
  ]) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final key = '${uri.toString()}|${(timeout ?? listTimeout).inMilliseconds}';
    final existing = _inflightGet[key];
    if (existing != null) return existing;

    final future = () async {
      try {
        final response = await _client.get(uri).timeout(timeout ?? listTimeout);
        return _decode(response);
      } on ApiException {
        rethrow;
      } on Exception catch (e) {
        throw ApiException(_timeoutOrNet(e));
      } finally {
        _inflightGet.remove(key);
      }
    }();

    _inflightGet[key] = future;
    return future;
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(body),
          )
          .timeout(longTimeout);
      return _decode(response);
    } on ApiException {
      rethrow;
    } on Exception catch (e) {
      throw ApiException(_timeoutOrNet(e));
    }
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _client.delete(uri).timeout(const Duration(seconds: 25));
      return _decode(response);
    } on ApiException {
      rethrow;
    } on Exception catch (e) {
      throw ApiException(_timeoutOrNet(e));
    }
  }

  String _timeoutOrNet(Object e) {
    final s = e.toString();
    if (s.contains('TimeoutException') || s.contains('timed out')) {
      return 'API local demorou demais — confira se a janela do backend subiu e tente de novo.';
    }
    if (s.contains('SocketException') || s.contains('Connection refused') || s.contains('Failed host lookup')) {
      return 'API local offline — abra pelo atalho PAES MED AI na área de trabalho.';
    }
    if (e is ApiException) return e.message;
    return s;
  }

  Future<dynamic> postMultipart(
    String path, {
    required String fileField,
    required String filePath,
    String filename = 'upload.bin',
    Map<String, String> fields = const {},
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final req = http.MultipartRequest('POST', uri);
    req.fields.addAll(fields);
    req.files.add(await http.MultipartFile.fromPath(fileField, filePath, filename: filename));
    final streamed = await req.send().timeout(const Duration(seconds: 300));
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    final raw = response.body.trim().isEmpty ? '{}' : utf8.decode(response.bodyBytes);
    final decoded = jsonDecode(raw);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final detail = decoded is Map ? decoded['detail']?.toString() : null;
    throw ApiException(detail ?? 'Erro HTTP ${response.statusCode}');
  }
}

final apiClient = ApiClient();
