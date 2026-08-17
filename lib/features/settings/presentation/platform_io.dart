// platform_io.dart — implementacao desktop/mobile (usa dart:io)
import 'dart:io' show File, Platform, Process;
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

/// Procura o python.exe no PATH e em locais comuns do Windows.
String _findPython() {
  // Locais comuns
  final home = Platform.environment['USERNAME'] ?? '';
  final candidates = <String>[
    'C:\\Users\\$home\\AppData\\Local\\Programs\\Python\\Python313\\python.exe',
    'C:\\Users\\$home\\AppData\\Local\\Programs\\Python\\Python312\\python.exe',
    'C:\\Users\\$home\\AppData\\Local\\Programs\\Python\\Python311\\python.exe',
    'C:\\Users\\$home\\AppData\\Local\\Programs\\Python\\Python310\\python.exe',
  ];
  for (final c in candidates) {
    if (File(c).existsSync()) return c;
  }
  // Tenta no PATH
  try {
    final result = Process.runSync('where', ['python.exe']);
    if (result.exitCode == 0) {
      final lines = (result.stdout as String).trim().split('\n');
      if (lines.isNotEmpty) return lines.first.trim();
    }
  } catch (_) {}
  return '';
}

/// Retorna o path do updater_gui.py se existir, ou vazio.
String updaterScriptPath() {
  if (!isWindows) return '';
  try {
    final exe = Platform.resolvedExecutable;
    final dir = p.dirname(exe); // .../app
    final root = p.dirname(dir); // .../PAES_MED_AI
    final candidates = [
      p.join(root, 'tools', 'updater_gui.py'),
      p.join(dir, 'tools', 'updater_gui.py'),
    ];
    for (final c in candidates) {
      if (File(c).existsSync()) return c;
    }
  } catch (_) {}
  return '';
}

Future<bool> launchUpdater() async {
  if (!isWindows) return false;
  try {
    final py = _findPython();
    if (py.isEmpty) return false;
    final script = updaterScriptPath();
    if (script.isEmpty) return false;
    // Chama python diretamente, sem passar por cmd/bat
    // runInShell=true para herdar o desktop e mostrar a janela tkinter
    await Process.start(py, [script], runInShell: true);
    return true;
  } catch (_) {}
  return false;
}
