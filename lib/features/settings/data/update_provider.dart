import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_version.dart';

class UpdateState {
  final String? latestVersion;
  final String? publishedAt;
  final String? releaseUrl;
  final String? zipUrl;
  final String? error;
  final bool hasUpdate;
  final bool checking;

  const UpdateState({
    this.latestVersion,
    this.publishedAt,
    this.releaseUrl,
    this.zipUrl,
    this.error,
    this.hasUpdate = false,
    this.checking = false,
  });

  UpdateState copyWith({
    String? latestVersion,
    String? publishedAt,
    String? releaseUrl,
    String? zipUrl,
    String? error,
    bool? hasUpdate,
    bool? checking,
  }) =>
      UpdateState(
        latestVersion: latestVersion ?? this.latestVersion,
        publishedAt: publishedAt ?? this.publishedAt,
        releaseUrl: releaseUrl ?? this.releaseUrl,
        zipUrl: zipUrl ?? this.zipUrl,
        error: error ?? this.error,
        hasUpdate: hasUpdate ?? this.hasUpdate,
        checking: checking ?? this.checking,
      );
}

class UpdateNotifier extends StateNotifier<UpdateState> {
  UpdateNotifier() : super(const UpdateState());

  static const _owner = 'ymedeiros228';
  static const _repo = 'PAES_MED_AI';

  Future<void> check() async {
    state = state.copyWith(checking: true, error: null);
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$_owner/$_repo/releases/latest'),
        headers: {'User-Agent': 'PAES_MED_AI'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('GitHub API retornou ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final latest = data['tag_name']?.toString() ?? '';
      final published = data['published_at']?.toString() ?? '';
      final releaseUrl = data['html_url']?.toString() ?? '';
      final assets = (data['assets'] as List?) ?? [];
      String? zipUrl;
      for (final asset in assets) {
        final name = (asset as Map)['name']?.toString() ?? '';
        if (name.toLowerCase().startsWith('paes_med_ai_windows') && name.toLowerCase().endsWith('.zip')) {
          zipUrl = asset['browser_download_url']?.toString();
          break;
        }
      }

      final local = kAppVersionLabel;
      final hasUpdate = _hasNewerVersion(local, latest);

      state = UpdateState(
        latestVersion: latest,
        publishedAt: published,
        releaseUrl: releaseUrl,
        zipUrl: zipUrl,
        hasUpdate: hasUpdate,
        checking: false,
      );
    } catch (e) {
      state = UpdateState(error: e.toString(), checking: false);
    }
  }

  bool _hasNewerVersion(String local, String remote) {
    // Compara versões simples: remove prefixo 'v' e compara numericamente
    final l = _parseVersion(local);
    final r = _parseVersion(remote);
    for (int i = 0; i < 3; i++) {
      if (r[i] > l[i]) return true;
      if (r[i] < l[i]) return false;
    }
    return false;
  }

  List<int> _parseVersion(String v) {
    final clean = v.replaceFirst(RegExp(r'^v'), '').split('+').first;
    final parts = clean.split('.').map(int.tryParse).toList();
    return [
      parts.isNotEmpty ? (parts[0] ?? 0) : 0,
      parts.length > 1 ? (parts[1] ?? 0) : 0,
      parts.length > 2 ? (parts[2] ?? 0) : 0,
    ];
  }

  void dismiss() {
    state = state.copyWith(hasUpdate: false);
  }
}

final updateProvider = StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
  return UpdateNotifier()..check();
});

final updateCheckProvider = Provider<UpdateState>((ref) => ref.watch(updateProvider));
