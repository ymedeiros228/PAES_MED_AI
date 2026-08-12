// platform_io.dart — implementacao desktop/mobile (usa dart:io)
import 'dart:io' show File, Platform;
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
