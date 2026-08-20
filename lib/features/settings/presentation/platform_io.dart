// platform_io.dart — implementacao desktop/mobile (usa dart:io)
import 'dart:async';
import 'dart:io' show Directory, File, HttpClient, Platform, Process, ProcessStartMode, X509Certificate;
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
        debugPrint('Updater: download falhou, status=${response.statusCode}');
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
      return out.path;
    } finally {
      client.close();
    }
  }

  try {
    return await doDownload(insecure: false);
  } catch (e) {
    debugPrint('Updater: HTTPS padrao falhou ($e), tentando sem verificacao de certificado');
    try {
      return await doDownload(insecure: true);
    } catch (e2) {
      debugPrint('Updater: erro no download: $e2');
      return null;
    }
  }
}

/// Executa o instalador .exe diretamente, sem wrapper .vbs ou .bat.
/// O Inno Setup abre em MODO WIZARD (Avancar/Instalar/Concluir).
/// /FORCECLOSEAPPLICATIONS faz o Inno Setup fechar paes_med_ai.exe e
/// paes_backend.exe automaticamente antes de copiar os arquivos.
/// Nao usa /DIR= — o Inno Setup detecta o path anterior pelo registro
/// ou usa DefaultDirName automaticamente (evita "pasta nao encontrada").
Future<bool> _runInstaller(String setupPath) async {
  try {
    final r = await Process.start(
      setupPath,
      ['/FORCECLOSEAPPLICATIONS', '/NORESTART'],
      mode: ProcessStartMode.detached,
    );
    if (r.pid <= 0) return false;
    // Da um tempinho para o SO iniciar o instalador.
    await Future.delayed(const Duration(milliseconds: 500));
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

  // 3) Instalador iniciado. O app sera fechado pelo caller apos confirmar.
  return (true, 'Instalador iniciado. O app será fechado automaticamente.');
}

/// Mantem compatibilidade com o nome antigo. Preferencialmente chame runNativeUpdater.
Future<bool> launchUpdater() async {
  if (!isWindows) return false;
  // Abre o GitHub releases como fallback generico.
  return _openUrl('https://github.com/ymedeiros228/PAES_MED_AI/releases/latest');
}
