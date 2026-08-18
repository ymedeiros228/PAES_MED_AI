// backend_launcher.dart — inicia o backend Python local no Windows.
//
// Estrategia (em ordem):
//   1. paes_backend.exe  (bundle PyInstaller — nao precisa de Python instalado)
//   2. python.exe -m uvicorn main:app  (requer Python + deps no cliente)
//
// PASTA DE DADOS GRAVAVEL:
//   Se o app for instalado em Program Files, a pasta <install>/data NAO e
//   gravavel por processos sem admin. O SQLite precisa escrever no .db,
//   criar backups, logs, etc. Por isso, PAES_DATA_DIR aponta para:
//     %LOCALAPPDATA%\PAES_MED_AI\data
//   Na primeira execucao, o banco seed e PDFs sao copiados do <install>/data
//   para essa pasta gravavel. Em dev (repo), usa <root>/data normalmente.
//
// Em ambos os casos:
//   - seta PAES_DATA_DIR para a pasta data gravavel
//   - mata processo que ocupa a porta 8000 antes de subir
//   - grava log em <data>/logs/backend_launcher.log para diagnostico
//   - roda detached (nao bloqueia o app)
import 'dart:io' show File, Platform, Process, ProcessStartMode, Directory, FileMode;
import 'dart:async';
import 'package:path/path.dart' as p;

/// Inicia o backend local no Windows. Retorna true se algum backend foi iniciado.
Future<bool> launchLocalBackend() async {
  if (!Platform.isWindows) return false;
  final log = _BackendLogger();
  try {
    final exe = Platform.resolvedExecutable;
    final appDir = p.dirname(exe); // .../app
    final root = p.dirname(appDir); // .../PAES_MED_AI

    // Estrutura instalador: <root>/backend, <root>/data, <root>/libs
    // Estrutura dev:        <root>/backend, <root>/data
    final backendDir = p.join(root, 'backend');
    final libsDir = p.join(root, 'libs');
    final installDataDir = p.join(root, 'data');

    // Estrutura alternativa (tudo dentro de app/, portable zip)
    final altBackend = p.join(appDir, 'backend');
    final altLibs = p.join(appDir, 'libs');
    final altInstallData = p.join(appDir, 'data');

    final useBackend = Directory(backendDir).existsSync() ? backendDir : altBackend;
    final useLibs = Directory(libsDir).existsSync() ? libsDir : altLibs;
    final sourceDataDir = Directory(installDataDir).existsSync() ? installDataDir : altInstallData;

    // Descobre a pasta de dados GRAVAVEL.
    // Em dev (repo): usa <root>/data (e gravavel).
    // Em instalacao (Program Files): usa %LOCALAPPDATA%\PAES_MED_AI\data.
    final useData = _resolveWritableDataDir(sourceDataDir, root, log);

    log.line('=== launchLocalBackend ===');
    log.line('exe=$exe');
    log.line('root=$root');
    log.line('useBackend=$useBackend (exists=${Directory(useBackend).existsSync()})');
    log.line('sourceDataDir=$sourceDataDir (exists=${Directory(sourceDataDir).existsSync()})');
    log.line('useData (gravavel)=$useData');

    if (!Directory(useBackend).existsSync()) {
      log.line('ERRO: pasta backend nao encontrada');
      return false;
    }

    // Garante que a pasta data gravavel existe.
    try {
      Directory(useData).createSync(recursive: true);
    } catch (e) {
      log.line('ERRO: nao criou $useData: $e');
      return false;
    }

    // Copia dados seed (banco + PDFs) do <install>/data para o data gravavel
    // na primeira execucao. So copia o que ainda nao existe.
    _seedWritableData(sourceDataDir, useData, log);

    // Libera a porta 8000 se ja estiver ocupada (evita "address already in use").
    await _freePort8000(log);

    // Ambiente base.
    final env = Map<String, String>.from(Platform.environment);
    if (Directory(useLibs).existsSync()) {
      env['PYTHONPATH'] = useLibs;
    }
    env['PAES_DATA_DIR'] = useData;
    // Backend em modo desktop: backup automatico ligado, bootstrap prod desligado.
    env['PAES_AUTO_BACKUP'] = '1';
    env.remove('PAES_BOOTSTRAP_PROD');

    // 1) Tenta o bundle PyInstaller (paes_backend.exe) — nao precisa de Python.
    final backendExe = p.join(useBackend, 'paes_backend.exe');
    log.line('procurando bundle: $backendExe (exists=${File(backendExe).existsSync()})');
    if (File(backendExe).existsSync()) {
      try {
        final proc = await Process.start(
          backendExe,
          ['--host', '127.0.0.1', '--port', '8000'],
          workingDirectory: useBackend,
          environment: env,
          mode: ProcessStartMode.detached,
        );
        log.line('[OK] backend iniciado via paes_backend.exe (PID=${proc.pid})');
        // Espera 3s e verifica se o processo ainda esta vivo.
        // Se crashou imediatamente, o exit code ja estara disponivel.
        int? exitCode;
        try {
          exitCode = await proc.exitCode.timeout(const Duration(seconds: 3));
        } catch (_) {
          // Timeout = processo ainda rodando = OK
        }
        if (exitCode != null) {
          log.line('ERRO: paes_backend.exe crashou em <3s (exitCode=$exitCode)');
          // Tenta ler stderr para diagnostico.
          try {
            final stderr = await proc.stderr
                .timeout(const Duration(seconds: 1))
                .join('\n');
            if (stderr.isNotEmpty) {
              log.line('stderr do backend: $stderr');
            }
          } catch (_) {}
        } else {
          log.line('backend vivo apos 3s — OK');
        }
        return true;
      } catch (e) {
        log.line('falhou paes_backend.exe: $e — caindo para python.exe');
      }
    } else {
      log.line('AVISO: paes_backend.exe nao encontrado em $backendExe');
      log.line('  Conteudo de $useBackend:');
      try {
        for (final f in Directory(useBackend).listSync()) {
          log.line('    ${f.path}');
        }
      } catch (e) {
        log.line('  Erro ao listar: $e');
      }
    }

    // 2) Cai para python.exe -m uvicorn. Filtra stub da Microsoft Store.
    final py = _findPython(log);
    if (py.isEmpty) {
      log.line('ERRO: python.exe nao encontrado (ou so stub da Store)');
      return false;
    }
    log.line('python encontrado: $py');

    try {
      await Process.start(
        py,
        ['-m', 'uvicorn', 'main:app', '--host', '127.0.0.1', '--port', '8000'],
        workingDirectory: useBackend,
        environment: env,
        runInShell: true,
        mode: ProcessStartMode.detached,
      );
      log.line('[OK] backend iniciado via python -m uvicorn');
      return true;
    } catch (e) {
      log.line('ERRO ao iniciar python -m uvicorn: $e');
      return false;
    }
  } catch (e, st) {
    log.line('ERRO inesperado: $e\n$st');
    return false;
  }
}

/// Decide qual pasta de dados usar:
/// - Em dev (repo): <root>/data (gravavel, nao precisa de LOCALAPPDATA).
/// - Em instalacao: %LOCALAPPDATA%\PAES_MED_AI\data (sempre gravavel pelo usuario).
/// Criterio: se <root> contem "Program Files" ou se <sourceDataDir> nao for
/// gravavel, usa LOCALAPPDATA. Caso contrario, usa <sourceDataDir>.
String _resolveWritableDataDir(String sourceDataDir, String root, _BackendLogger log) {
  // Dev: se o root nao esta em Program Files e a pasta e gravavel, usa ela.
  final lowerRoot = root.toLowerCase();
  final isProgramFiles = lowerRoot.contains('program files');
  if (!isProgramFiles) {
    // Testa se consegue escrever um arquivo temporario na pasta.
    if (_isDirWritable(sourceDataDir)) {
      log.line('data dir gravavel: $sourceDataDir (modo dev/portable)');
      return sourceDataDir;
    }
    log.line('aviso: $sourceDataDir nao e gravavel — caindo para LOCALAPPDATA');
  } else {
    log.line('install em Program Files detectado — usando LOCALAPPDATA');
  }
  // Instalacao em Program Files: usa %LOCALAPPDATA%\PAES_MED_AI\data
  final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
  if (localAppData.isEmpty) {
    log.line('ERRO: LOCALAPPDATA nao definido — usando $sourceDataDir como fallback');
    return sourceDataDir;
  }
  return p.join(localAppData, 'PAES_MED_AI', 'data');
}

/// Testa se uma pasta e gravavel tentando criar/escrever/deletar um arquivo temp.
bool _isDirWritable(String dirPath) {
  try {
    final d = Directory(dirPath);
    if (!d.existsSync()) return false;
    final testFile = File(p.join(dirPath, '.paes_write_test'));
    testFile.writeAsStringSync('ok');
    testFile.deleteSync();
    return true;
  } catch (_) {
    return false;
  }
}

/// Copia dados seed (banco + PDFs + edital) do <install>/data para o data
/// gravavel na primeira execucao. So copia arquivos que ainda nao existem
/// no destino. Nao sobrescreve dados do usuario.
void _seedWritableData(String sourceDir, String destDir, _BackendLogger log) {
  final src = Directory(sourceDir);
  if (!src.existsSync()) {
    log.line('seed: pasta origem $sourceDir nao existe — pulando copia');
    return;
  }
  try {
    _copyTreeIfMissing(src, Directory(destDir), log);
    log.line('seed: copia concluida de $sourceDir -> $destDir');
  } catch (e) {
    log.line('seed: erro ao copiar $sourceDir -> $destDir: $e');
  }
}

/// Copia recursivamente, mas so arquivos que nao existem no destino.
void _copyTreeIfMissing(Directory src, Directory dst, _BackendLogger log) {
  for (final entity in src.listSync(recursive: false)) {
    final name = p.basename(entity.path);
    final target = p.join(dst.path, name);
    if (entity is File) {
      final tf = File(target);
      if (!tf.existsSync()) {
        try {
          tf.parent.createSync(recursive: true);
          entity.copySync(target);
        } catch (e) {
          log.line('seed: nao copiou ${entity.path}: $e');
        }
      }
    } else if (entity is Directory) {
      final td = Directory(target);
      if (!td.existsSync()) {
        td.createSync(recursive: true);
      }
      _copyTreeIfMissing(entity, td, log);
    }
  }
}

/// Mata o processo que esta ouvindo na porta 8000 (se houver).
/// Usa netstat + taskkill. Falhas sao silenciosas (so log).
Future<void> _freePort8000(_BackendLogger log) async {
  try {
    final r = await Process.run('netstat', ['-ano', '-p', 'tcp']);
    if (r.exitCode != 0) return;
    final lines = (r.stdout as String).split('\n');
    for (final line in lines) {
      // Linha tipo:  TCP    127.0.0.1:8000      0.0.0.0:0      LISTENING   1234
      if (!line.contains('LISTENING')) continue;
      if (!line.contains(':8000')) continue;
      final pid = RegExp(r'\s(\d+)\s*$').firstMatch(line)?.group(1);
      if (pid == null || pid == '0') continue;
      log.line('porta 8000 ocupada pelo PID $pid — matando');
      await Process.run('taskkill', ['/F', '/PID', pid], runInShell: true);
      // Da um tempo para o SO liberar o socket.
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }
  } catch (e) {
    log.line('aviso _freePort8000: $e');
  }
}

/// Procura python.exe real (nao o stub da Microsoft Store).
/// O stub em WindowsApps tem 0 bytes e abre a Store ao ser executado.
String _findPython(_BackendLogger log) {
  // 1) `where python.exe` no PATH — filtra stubs.
  try {
    final result = Process.runSync('where', ['python.exe']);
    if (result.exitCode == 0) {
      final lines = (result.stdout as String)
          .trim()
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      for (final candidate in lines) {
        if (_isRealPython(candidate, log)) return candidate;
      }
    }
  } catch (e) {
    log.line('aviso where python.exe: $e');
  }

  // 2) `py -3` launcher do Windows (instalado junto com Python oficial).
  try {
    final result = Process.runSync('py', ['-3', '-c', 'import sys; print(sys.executable)']);
    if (result.exitCode == 0) {
      final candidate = (result.stdout as String).trim().split('\n').first.trim();
      if (candidate.isNotEmpty && _isRealPython(candidate, log)) return candidate;
    }
  } catch (_) {}

  // 3) Locais comuns de instalacao user-level.
  final home = Platform.environment['USERNAME'] ?? '';
  final candidates = <String>[
    'C:\\Users\\$home\\AppData\\Local\\Programs\\Python\\Python313\\python.exe',
    'C:\\Users\\$home\\AppData\\Local\\Programs\\Python\\Python312\\python.exe',
    'C:\\Users\\$home\\AppData\\Local\\Programs\\Python\\Python311\\python.exe',
    'C:\\Users\\$home\\AppData\\Local\\Programs\\Python\\Python310\\python.exe',
    'C:\\Python313\\python.exe',
    'C:\\Python312\\python.exe',
    'C:\\Python311\\python.exe',
    'C:\\Python310\\python.exe',
  ];
  for (final c in candidates) {
    if (_isRealPython(c, log)) return c;
  }
  return '';
}

/// True se o caminho aponta para um python.exe real (nao stub da Store).
/// Criterio: arquivo existe, nao esta em WindowsApps, e roda `--version`.
bool _isRealPython(String path, _BackendLogger log) {
  try {
    final f = File(path);
    if (!f.existsSync()) return false;
    // Stub da Microsoft Store fica em ...\\AppData\\Local\\Microsoft\\WindowsApps\\
    if (path.toLowerCase().contains('windowsapps')) return false;
    // Tamanho 0 = stub.
    if (f.statSync().size == 0) return false;
    // Confirma rodando --version.
    final r = Process.runSync(path, ['--version']);
    if (r.exitCode != 0) return false;
    return true;
  } catch (e) {
    log.line('aviso _isRealPython($path): $e');
    return false;
  }
}

/// Logger simples que appenda em <data>/logs/backend_launcher.log e tambem
/// printa no console (util em dev). Tolerante a falhas de IO.
class _BackendLogger {
  _BackendLogger();
  String? _path;

  String _resolvePath() {
    if (_path != null) return _path!;
    try {
      final exe = Platform.resolvedExecutable;
      final appDir = p.dirname(exe);
      final root = p.dirname(appDir);
      // Tenta <root>/data primeiro (dev), depois LOCALAPPDATA (instalacao).
      String dataDir = Directory(p.join(root, 'data')).existsSync()
          ? p.join(root, 'data')
          : p.join(appDir, 'data');
      // Se <root>/data nao for gravavel (Program Files), usa LOCALAPPDATA.
      if (!_isDirWritable(dataDir)) {
        final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
        if (localAppData.isNotEmpty) {
          dataDir = p.join(localAppData, 'PAES_MED_AI', 'data');
        }
      }
      final logsDir = p.join(dataDir, 'logs');
      Directory(logsDir).createSync(recursive: true);
      _path = p.join(logsDir, 'backend_launcher.log');
    } catch (_) {
      _path = '';
    }
    return _path!;
  }

  void line(String msg) {
    final stamped = '[${DateTime.now().toIso8601String()}] $msg';
    // ignore: avoid_print
    print(stamped);
    final path = _resolvePath();
    if (path.isEmpty) return;
    try {
      File(path).writeAsStringSync('$stamped\n', mode: FileMode.append);
    } catch (_) {}
  }
}
