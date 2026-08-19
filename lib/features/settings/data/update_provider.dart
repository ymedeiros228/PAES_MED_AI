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
        // Novos releases usam o instalador .exe (PAESMedAI_Setup_X.X.X.X.exe)
        if (name.toLowerCase().startsWith('paesmedai_setup') && name.toLowerCase().endsWith('.exe')) {
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
    // Compara versões com ate 4 partes: 1.0.0.56 vs 1.0.0.57
    final l = _parseVersion(local);
    final r = _parseVersion(remote);
    final maxLen = l.length > r.length ? l.length : r.length;
    for (int i = 0; i < maxLen; i++) {
      final li = i < l.length ? l[i] : 0;
      final ri = i < r.length ? r[i] : 0;
      if (ri > li) return true;
      if (ri < li) return false;
    }
    return false;
  }

  List<int> _parseVersion(String v) {
    final clean = v.replaceFirst(RegExp(r'^v'), '').split('+').first;
    final parts = clean.split('.').map(int.tryParse).toList();
    // Retorna todas as partes disponiveis (ate 4: major.minor.patch.build)
    return parts.whereType<int>().toList();
  }

  void dismiss() {
    state = state.copyWith(hasUpdate: false);
  }
}

final updateProvider = StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
  return UpdateNotifier()..check();
});

final updateCheckProvider = Provider<UpdateState>((ref) => ref.watch(updateProvider));
