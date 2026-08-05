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
    final response = await _client.get(uri).timeout(const Duration(seconds: 60));
    return _decode(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 180));
    return _decode(response);
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.delete(uri).timeout(const Duration(seconds: 30));
    return _decode(response);
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
