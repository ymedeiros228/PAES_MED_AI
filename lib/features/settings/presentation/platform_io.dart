// platform_io.dart — implementacao desktop/mobile (usa dart:io)
import 'dart:async';
import 'dart:io' show Directory, File, Platform, Process;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

/// Path para a pasta de instalacao do app.
/// Usado pelo updater para substituir a versao antiga.
String? _installDir() {
  try {
    final exe = Platform.resolvedExecutable;
    return p.dirname(p.dirname(exe)); // <...>/PAES_MED_AI
  } catch (_) {
    return null;
  }
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
Future<String?> _downloadSetup(String url, void Function(int received, int total)? onProgress) async {
  try {
    final client = http.Client();
    final request = http.Request('GET', Uri.parse(url));
    request.headers['User-Agent'] = 'PAES-MED-AI-Updater';
    final response = await client.send(request).timeout(const Duration(seconds: 120));
    if (response.statusCode != 200) {
      debugPrint('Updater: download falhou, status=${response.statusCode}');
      client.close();
      return null;
    }

    final total = response.contentLength ?? 0;
    final tempDir = Directory.systemTemp.createTempSync('paes_update_');
    final fileName = url.split('/').last;
    final out = File(p.join(tempDir.path, fileName.isNotEmpty ? fileName : 'PAESMedAI_Setup_latest.exe'));

    final sink = out.openWrite();
    var received = 0;
    await for (final chunk in response.stream) {
      sink.add(chunk);
      received += chunk.length;
      if (onProgress != null && total > 0) onProgress(received, total);
    }
    await sink.close();
    client.close();
    return out.path;
  } catch (e) {
    debugPrint('Updater: erro no download: $e');
    return null;
  }
}

/// Executa o instalador .exe em modo silencioso e fecha o app.
/// Usa /SILENT do Inno Setup (barra de progresso, sem wizard).
Future<bool> _runInstaller(String setupPath) async {
  try {
    final installDir = _installDir() ?? '';
    final args = [
      '/c',
      'start',
      '',
      setupPath,
      if (installDir.isNotEmpty) '/DIR=$installDir',
      '/SILENT',
      '/NOCANCEL',
      '/SUPPRESSMSGBOXES',
    ];
    // Inicia o instalador e NAO espera (senao travaria o app).
    // Depois de iniciado, pede para o usuario fechar o app manualmente.
    final r = await Process.start('cmd', args, runInShell: true);
    if (r.pid <= 0) return false;
    // Da um tempinho para o SO iniciar o installer.
    await Future.delayed(const Duration(seconds: 2));
    return true;
  } catch (e) {
    debugPrint('Updater: erro ao executar instalador: $e');
    return false;
  }
}

/// Atualizador nativo em Dart. Nao precisa de Python.
/// Recebe a URL direta do asset .exe da nova versao.
/// onProgress: (recebido, total) em bytes.
/// Retorna (sucesso, mensagem).
Future<(bool, String)> runNativeUpdater(String downloadUrl, {void Function(int received, int total)? onProgress}) async {
  if (!isWindows) return (false, 'Atualizacao automatica so funciona no Windows.');

  // 1) Download
  final path = await _downloadSetup(downloadUrl, onProgress);
  if (path == null || !File(path).existsSync()) {
    return (false, 'Nao foi possivel baixar a nova versao. Verifique a conexao.');
  }

  // 2) Executa o instalador
  final ok = await _runInstaller(path);
  if (!ok) {
    return (false, 'Falha ao iniciar o instalador.');
  }

  // 3) Pede para o usuario fechar o app manualmente.
  // O instalador /SILENT ja esta rodando e vai substituir a instalacao.
  return (true, 'Instalador baixado e iniciado. Feche o app para concluir a atualizacao.');
}

/// Mantem compatibilidade com o nome antigo. Preferencialmente chame runNativeUpdater.
Future<bool> launchUpdater() async {
  if (!isWindows) return false;
  // Abre o GitHub releases como fallback generico.
  return _openUrl('https://github.com/ymedeiros228/PAES_MED_AI/releases/latest');
}
