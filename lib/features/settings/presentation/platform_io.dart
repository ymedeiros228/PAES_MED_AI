// platform_io.dart — implementacao desktop/mobile (usa dart:io)
import 'dart:async';
import 'dart:io' show Directory, File, HttpClient, Platform, Process, X509Certificate, FileMode;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

(String, bool) readVersionFile() {
  final isWin = !identical(0, 0.0) && Platform.isWindows;
  if (!isWin) return ('', false);
  try {
    final exe = Platform.resolvedExecutable;
    final dir = p.dirname(exe);
    final sibling = File(p.join(p.dirname(dir), 'VERSION.txt'));
    final same = File(p.join(dir, 'VERSION.txt'));
    final buildFile = sibling.existsSync() ? sibling : same;
    if (buildFile.existsSync()) {
      final value = buildFile.readAsStringSync().trim();
      if (value.isNotEmpty) return (value, true);
    }
  } catch (_) {}
  return ('', false);
}

bool get isWindows {
  try {
    return !identical(0, 0.0) && Platform.isWindows;
  } catch (_) {
    return false;
  }
}

/// Log do updater em disco para diagnostico no cliente.
void _updaterLog(String message) {
  debugPrint('[Updater] $message');
  try {
    String? logDir;
    final dataDir = Platform.environment['PAES_DATA_DIR'] ?? '';
    if (dataDir.isNotEmpty && Directory(dataDir).existsSync()) {
      logDir = p.join(dataDir, 'logs');
    } else {
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
      if (localAppData.isNotEmpty) {
        logDir = p.join(localAppData, 'PAES_MED_AI', 'data', 'logs');
      }
    }
    if (logDir == null) return;
    Directory(logDir).createSync(recursive: true);
    final logFile = File(p.join(logDir, 'updater.log'));
    final ts = DateTime.now().toIso8601String();
    logFile.writeAsStringSync('[$ts] $message\n', mode: FileMode.append);
  } catch (_) {}
}

/// Tenta abrir uma URL no browser.
Future<bool> _openUrl(String url) async {
  try {
    await Process.start('cmd', ['/c', 'start', '', url], runInShell: true);
    return true;
  } catch (_) {
    return false;
  }
}

/// Faz download do instalador .exe para a pasta temp.
/// [url] e o link direto do asset (ex: .../download/v1.0.0.54/PAESMedAI_Setup_1.0.0.54.exe)
/// Retorna o path local ou null em caso de erro.
/// Em VMs sem certificados CA atualizados, faz fallback para HTTPS sem
/// verificacao de certificado (necessario para baixar do GitHub).
Future<String?> _downloadSetup(String url, void Function(int received, int total)? onProgress) async {
  _updaterLog('Iniciando download: $url');
  Future<String?> doDownload({required bool insecure}) async {
    final client = HttpClient()
      ..userAgent = 'PAES-MED-AI-Updater'
      ..connectionTimeout = const Duration(seconds: 120);
    if (insecure) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    }
    try {
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set('User-Agent', 'PAES-MED-AI-Updater');
      final response = await req.close();
      if (response.statusCode != 200) {
        _updaterLog('Download falhou: HTTP ${response.statusCode}');
        return null;
      }

      final total = response.contentLength;
      final tempDir = Directory.systemTemp.createTempSync('paes_update_');
      final fileName = url.split('/').last;
      final out = File(p.join(tempDir.path, fileName.isNotEmpty ? fileName : 'PAESMedAI_Setup_latest.exe'));

      final sink = out.openWrite();
      var received = 0;
      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        if (onProgress != null && total > 0) onProgress(received, total);
      }
      await sink.close();
      _updaterLog('Download concluido: $received bytes -> ${out.path}');
      return out.path;
    } finally {
      client.close();
    }
  }

  try {
    return await doDownload(insecure: false);
  } catch (e) {
    _updaterLog('HTTPS padrao falhou ($e), tentando sem verificacao de certificado');
    try {
      return await doDownload(insecure: true);
    } catch (e2) {
      _updaterLog('Erro no download: $e2');
      return null;
    }
  }
}

/// Executa o instalador .exe via `cmd /c start`.
/// Usar `cmd /c start` em vez de `Process.start` direto porque:
/// 1. `start` respeita o manifest do exe e triggera UAC se necessario
///    (essencial se o app esta em Program Files)
/// 2. `Process.start` em modo detached NAO triggera UAC — o instalador
///    silenciosamente falha ou nao abre
/// 3. `start` abre o instalador como um processo independente do app
Future<bool> _runInstaller(String setupPath) async {
  _updaterLog('Executando instalador: $setupPath');
  try {
    // `cmd /c start "" "setup.exe" /FORCECLOSEAPPLICATIONS /NORESTART`
    // As aspas vazias "" sao importantes: `start` trata o primeiro
    // argumento entre aspas como titulo da janela, nao como comando.
    final result = await Process.run(
      'cmd',
      ['/c', 'start', '""', '"$setupPath"', '/FORCECLOSEAPPLICATIONS', '/NORESTART'],
      runInShell: true,
    );
    _updaterLog('cmd start exitCode=${result.exitCode} stdout=${result.stdout} stderr=${result.stderr}');
    // `start` retorna 0 se abriu o processo, mesmo que o instalador
    // ainda esteja carregando. Se exitCode != 0, algo deu errado.
    if (result.exitCode != 0) {
      _updaterLog('Falha: cmd start retornou ${result.exitCode}');
      return false;
    }
    // Da um tempinho para o instalador abrir (UAC pode demorar).
    await Future.delayed(const Duration(seconds: 2));
    _updaterLog('Instalador lancado com sucesso');
    return true;
  } catch (e) {
    _updaterLog('Erro ao executar instalador: $e');
    return false;
  }
}

/// Atualizador nativo em Dart. Nao precisa de Python.
/// Recebe a URL direta do asset .exe da nova versao.
/// onProgress: (recebido, total) em bytes.
/// Retorna (sucesso, mensagem).
Future<(bool, String)> runNativeUpdater(String downloadUrl, {void Function(int received, int total)? onProgress}) async {
  if (!isWindows) return (false, 'Atualização automática só funciona no Windows.');

  _updaterLog('=== Iniciando atualizacao ===');
  _updaterLog('URL: $downloadUrl');

  // 1) Download
  final path = await _downloadSetup(downloadUrl, onProgress);
  if (path == null || !File(path).existsSync()) {
    _updaterLog('Falha: download retornou null ou arquivo nao existe');
    return (false, 'Não foi possível baixar a nova versão. Verifique a conexão com a internet.');
  }

  // 2) Verifica tamanho minimo (instalador e ~80-100MB)
  final fileSize = File(path).lengthSync();
  _updaterLog('Tamanho do arquivo: ${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB');
  if (fileSize < 1000000) {
    _updaterLog('Falha: arquivo muito pequeno ($fileSize bytes) — download incompleto?');
    return (false, 'O download parece incompleto (${(fileSize / 1024).round()} KB). Tente novamente.');
  }

  // 3) Executa o instalador
  final ok = await _runInstaller(path);
  if (!ok) {
    _updaterLog('Falha: instalador nao iniciou');
    return (false, 'Falha ao iniciar o instalador. Tente baixar manualmente no GitHub.');
  }

  // 4) Instalador iniciado. O app sera fechado pelo caller apos confirmar.
  _updaterLog('=== Atualizacao iniciada com sucesso ===');
  return (true, 'Instalador iniciado. O app será fechado automaticamente.');
}

/// Mantem compatibilidade com o nome antigo. Preferencialmente chame runNativeUpdater.
Future<bool> launchUpdater() async {
  if (!isWindows) return false;
  // Abre o GitHub releases como fallback generico.
  return _openUrl('https://github.com/ymedeiros228/PAES_MED_AI/releases/latest');
}
