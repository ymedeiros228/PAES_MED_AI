import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
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
