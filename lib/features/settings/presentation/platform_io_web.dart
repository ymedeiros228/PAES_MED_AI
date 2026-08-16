// platform_io_web.dart — stub web (nao usa dart:io)
(String, bool) readVersionFile() {
  return ('', false);
}

bool get isWindows => false;
String updaterPath() => '';
Future<bool> launchUpdater() async => false;
