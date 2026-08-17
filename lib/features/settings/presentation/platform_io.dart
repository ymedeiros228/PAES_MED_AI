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

/// Retorna o path do atualizador (.bat) se existir, ou vazio.
String updaterPath() {
  if (!isWindows) return '';
  try {
    final exe = Platform.resolvedExecutable;
    final dir = p.dirname(exe); // .../app
    final root = p.dirname(dir); // .../PAES_MED_AI
    // Procura em varios lugares possiveis
    final candidates = [
      p.join(root, 'Atualizar_PAES_MED_AI.bat'), // raiz do app
      p.join(root, 'tools', 'Atualizar_PAES_MED_AI.bat'), // tools/
      p.join(dir, 'Atualizar_PAES_MED_AI.bat'), // mesma pasta do exe
    ];
    for (final c in candidates) {
      if (File(c).existsSync()) return c;
    }
  } catch (_) {}
  return '';
}

Future<bool> launchUpdater() async {
  final path = updaterPath();
  if (path.isEmpty) return false;
  try {
    final process = await Process.start('cmd.exe', ['/c', 'start', '', path]);
    return await process.exitCode == 0;
  } catch (_) {}
  return false;
}
