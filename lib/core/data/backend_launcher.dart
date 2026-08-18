// backend_launcher.dart — inicia o backend Python local no Windows
import 'dart:io' show File, Platform, Process, ProcessStartMode, Directory;
import 'package:path/path.dart' as p;

/// Inicia o backend Python (uvicorn) em background no Windows.
/// Procura python.exe no sistema, seta PYTHONPATH para as libs embutidas
/// e PAES_DATA_DIR para a pasta data ao lado do exe.
/// Retorna true se o processo foi iniciado.
Future<bool> launchLocalBackend() async {
  if (!Platform.isWindows) return false;
  try {
    final exe = Platform.resolvedExecutable;
    final appDir = p.dirname(exe); // .../app
    final root = p.dirname(appDir); // .../PAES_MED_AI

    final backendDir = p.join(root, 'backend');
    final libsDir = p.join(root, 'libs');
    final dataDir = p.join(root, 'data');

    // Se nao existe backend ao lado, tenta estrutura de instalador
    final altBackend = p.join(appDir, 'backend');
    final altLibs = p.join(appDir, 'libs');
    final altData = p.join(appDir, 'data');

    final useBackend = Directory(backendDir).existsSync() ? backendDir : altBackend;
    final useLibs = Directory(libsDir).existsSync() ? libsDir : altLibs;
    final useData = Directory(dataDir).existsSync() ? dataDir : altData;

    if (!Directory(useBackend).existsSync()) return false;

    // Procura python
    final py = _findPython();
    if (py.isEmpty) return false;

    // Inicia o backend com PYTHONPATH e PAES_DATA_DIR setados
    final env = Map<String, String>.from(Platform.environment);
    if (Directory(useLibs).existsSync()) {
      env['PYTHONPATH'] = useLibs;
    }
    env['PAES_DATA_DIR'] = useData;

    await Process.start(
      py,
      ['-m', 'uvicorn', 'main:app', '--host', '127.0.0.1', '--port', '8000'],
      workingDirectory: useBackend,
      environment: env,
      runInShell: true,
      mode: ProcessStartMode.detached,
    );
    return true;
  } catch (_) {
    return false;
  }
}

String _findPython() {
  // Tenta no PATH primeiro
  try {
    final result = Process.runSync('where', ['python.exe']);
    if (result.exitCode == 0) {
      final lines = (result.stdout as String).trim().split('\n');
      if (lines.isNotEmpty) return lines.first.trim();
    }
  } catch (_) {}

  // Locais comuns
  final home = Platform.environment['USERNAME'] ?? '';
  final candidates = <String>[
    'C:\\Users\\$home\\AppData\\Local\\Programs\\Python\\Python313\\python.exe',
    'C:\\Users\\$home\\AppData\\Local\\Programs\\Python\\Python312\\python.exe',
    'C:\\Users\\$home\\AppData\\Local\\Programs\\Python\\Python311\\python.exe',
    'C:\\Users\\$home\\AppData\\Local\\Programs\\Python\\Python310\\python.exe',
    'C:\\Python313\\python.exe',
    'C:\\Python312\\python.exe',
    'C:\\Python311\\python.exe',
  ];
  for (final c in candidates) {
    if (File(c).existsSync()) return c;
  }
  return '';
}
