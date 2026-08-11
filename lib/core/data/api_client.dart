import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Conditional import: na web usa open_url_web.dart (JS interop), no desktop usa stub.
import 'open_url_stub.dart' if (dart.library.html) 'open_url_web.dart' show openUrlInBrowser;

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiTimeoutException implements Exception {
  const ApiTimeoutException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Timeouts progressivos (anteriormente 60s/180s/300s — usuário achava que travou).
  /// GET 15s: leituras devem ser rápidas (SQLite local + índices).
  /// POST 60s: IA pode demorar, mas 60s é o limite razoável para feedback.
  /// Upload 180s: PDFs grandes podem demorar para parsear.
  static const _getTimeout = Duration(seconds: 15);
  static const _postTimeout = Duration(seconds: 60);
  static const _deleteTimeout = Duration(seconds: 15);
  static const _uploadTimeout = Duration(seconds: 180);

  String get baseUrl {
    if (_configuredBaseUrl.trim().isNotEmpty) {
      return _configuredBaseUrl.trim().replaceFirst(RegExp(r'/$'), '');
    }
    // Web sem API_BASE_URL: tenta o mesmo host (deploy unificado backend+front).
    if (kIsWeb) {
      return '${windowOrigin}';
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  /// Origin atual no browser (vazio fora da web).
  static String get windowOrigin {
    if (kIsWeb) {
      try {
        return Uri.base.origin;
      } catch (_) {
        return '';
      }
    }
    return '';
  }

  Future<dynamic> get(String path, [Map<String, String>? query]) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    try {
      final response = await _client.get(uri).timeout(_getTimeout);
      return _decode(response);
    } on TimeoutException {
      throw const ApiTimeoutException('Tempo esgotado (15s). O servidor local pode estar ocupado.');
    }
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
          .timeout(_postTimeout);
      return _decode(response);
    } on TimeoutException {
      throw const ApiTimeoutException('Tempo esgotado (60s). A IA pode estar lenta — tente de novo.');
    }
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _client.delete(uri).timeout(_deleteTimeout);
      return _decode(response);
    } on TimeoutException {
      throw const ApiTimeoutException('Tempo esgotado (15s). Tente de novo.');
    }
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
    try {
      final streamed = await req.send().timeout(_uploadTimeout);
      final response = await http.Response.fromStream(streamed);
      return _decode(response);
    } on TimeoutException {
      throw const ApiTimeoutException('Upload esgotou (180s). PDFs muito grandes podem falhar.');
    }
  }

  /// Upload a partir de bytes (web: FilePicker retorna bytes, não path).
  Future<dynamic> postMultipartBytes(
    String path, {
    required String fileField,
    required List<int> fileBytes,
    required String filename,
    Map<String, String> fields = const {},
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final req = http.MultipartRequest('POST', uri);
    req.fields.addAll(fields);
    req.files.add(http.MultipartFile.fromBytes(fileField, fileBytes, filename: filename));
    try {
      final streamed = await req.send().timeout(_uploadTimeout);
      final response = await http.Response.fromStream(streamed);
      return _decode(response);
    } on TimeoutException {
      throw const ApiTimeoutException('Upload esgotou (180s). PDFs muito grandes podem falhar.');
    }
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

  /// Abre arquivo/pasta via /api/library/open-path.
  /// Na web, se o backend retornar webUrl, abre no browser (window.open).
  /// No desktop, o backend abre no SO (os.startfile).
  Future<Map<String, dynamic>> openPath(String path) async {
    final result = await post('/api/library/open-path', {'path': path});
    final map = Map<String, dynamic>.from(result as Map);
    // Se veio webUrl (web mode), abre no browser
    final webUrl = map['webUrl']?.toString();
    if (kIsWeb && webUrl != null && webUrl.isNotEmpty) {
      final fullUrl = webUrl.startsWith('http')
          ? webUrl
          : '$baseUrl$webUrl';
      openUrlInBrowser(fullUrl);
    }
    return map;
  }
}

final apiClient = ApiClient();
