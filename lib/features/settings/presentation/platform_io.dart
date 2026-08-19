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

/// Cria um .bat temporario que:
/// 1. Espera o app fechar (timeout 3s)
/// 2. Roda o instalador em /SILENT no mesmo diretorio
/// 3. Se limpa (auto-delete)
///
/// Necessario porque o Inno Setup nao consegue substituir
/// paes_med_ai.exe e paes_backend.exe enquanto estao em uso.
Future<String?> _createUpdateLauncher(String setupPath) async {
  try {
    final installDir = _installDir() ?? '';
    final batPath = p.join(
      Directory.systemTemp.createTempSync('paes_update_').path,
      'atualizar_paes_med_ai.bat',
    );
    final lines = [
      '@echo off',
      'setlocal',
      'set SETUP="$setupPath"',
      'set DIR=${installDir.isNotEmpty ? '/DIR="$installDir"' : ''}',
      'echo [PAES Update Launcher] aguardando o app fechar...',
      'timeout /t 3 /nobreak > nul',
      'echo Iniciando instalador...',
      'start "" /wait %SETUP% /SILENT /NOCANCEL /SUPPRESSMSGBOXES /NORESTART %DIR%',
      'if %errorlevel% == 0 (',
      '  echo Atualizacao concluida.',
      ') else (',
      '  echo Atualizacao terminou com codigo %errorlevel%',
      ')',
      'del "%~f0"',
    ];
    File(batPath).writeAsStringSync(lines.join('\r\n'));
    return batPath;
  } catch (e) {
    debugPrint('Updater: erro ao criar update launcher: $e');
    return null;
  }
}

/// Executa o instalador .exe em modo silencioso e fecha o app.
/// Usa /SILENT do Inno Setup (barra de progresso, sem wizard).
/// O Inno Setup com /SILENT substitui os arquivos, mas precisa que o
/// app feche para liberar os .exe e DLLs.
Future<bool> _runInstaller(String setupPath) async {
  try {
    final batPath = await _createUpdateLauncher(setupPath);
    if (batPath == null || !File(batPath).existsSync()) return false;

    // Inicia o .bat em uma janela separada e NAO espera.
    // O .bat vive sozinho, espera o app fechar e roda o instalador.
    final r = await Process.start(
      'cmd',
      ['/c', batPath],
      runInShell: true,
      mode: ProcessStartMode.detached,
    );
    if (r.pid <= 0) return false;
    // Da um tempinho para o SO iniciar o .bat.
    await Future.delayed(const Duration(seconds: 1));
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
