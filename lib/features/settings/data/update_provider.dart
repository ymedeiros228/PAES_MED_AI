import 'dart:async' show TimeoutException;
import 'dart:convert';
import 'dart:io' show HttpClient, SocketException, X509Certificate;
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

  /// Busca a release mais recente no GitHub.
  /// Em VMs sem certificados de CA atualizados, o HTTPS falha. Por isso
  /// tenta primeiro com verificacao normal; se der HandshakeException,
  /// faz uma segunda tentativa aceitando qualquer certificado.
  Future<String> _fetchReleaseJson() async {
    Future<String> doFetch({required bool insecure}) async {
      final client = HttpClient()
        ..userAgent = 'PAES_MED_AI'
        ..connectionTimeout = const Duration(seconds: 15);
      if (insecure) {
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      }
      try {
        final req = await client.getUrl(
          Uri.parse('https://api.github.com/repos/$_owner/$_repo/releases/latest'),
        );
        req.headers.set('User-Agent', 'PAES_MED_AI');
        final response = await req.close();
        if (response.statusCode != 200) {
          throw Exception('GitHub API retornou ${response.statusCode}');
        }
        final body = await response.transform(utf8.decoder).join();
        return body;
      } finally {
        client.close();
      }
    }

    try {
      return await doFetch(insecure: false);
    } catch (e) {
      // Fallback para certificados invalidos (VMs limpas).
      return await doFetch(insecure: true);
    }
  }

  Future<void> check() async {
    state = state.copyWith(checking: true, error: null);
    try {
      final raw = await _fetchReleaseJson().timeout(const Duration(seconds: 30));
      final data = jsonDecode(raw) as Map<String, dynamic>;
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
      String msg;
      if (e is SocketException) {
        msg = 'Sem conexao com a internet. Verifique sua rede e tente novamente.';
      } else if (e is TimeoutException) {
        msg = 'Tempo esgotado ao verificar atualizacoes. Tente novamente.';
      } else if (e.toString().contains('HandshakeException')) {
        msg = 'Erro de certificado SSL. Tente novamente em uma rede diferente.';
      } else if (e.toString().contains('403')) {
        msg = 'GitHub limitou as requisicoes. Aguarde alguns minutos e tente novamente.';
      } else {
        msg = 'Nao foi possivel verificar atualizacoes. Tente novamente.';
      }
      state = UpdateState(error: msg, checking: false);
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
