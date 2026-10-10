import 'package:flutter_test/flutter_test.dart';
import 'package:paes_med_ai/features/settings/presentation/platform_io.dart';

void main() {
  group('isTrustedSetupUrl', () {
    test('aceita instalador de release oficial', () {
      expect(
        isTrustedSetupUrl(
          'https://github.com/ymedeiros228/PAES_MED_AI/releases/download/v1.0.0.80/PAESMedAI_Setup_1.0.0.80.exe',
        ),
        isTrue,
      );
    });

    test('recusa http, outro host, outro repo ou arquivo que não é .exe', () {
      for (final url in [
        'http://github.com/ymedeiros228/PAES_MED_AI/releases/download/v1/x.exe',
        'https://evil.com/ymedeiros228/PAES_MED_AI/releases/download/v1/x.exe',
        'https://github.com/outro/PAES_MED_AI/releases/download/v1/x.exe',
        'https://github.com/ymedeiros228/PAES_MED_AI/releases/download/v1/x.zip',
        'lixo',
      ]) {
        expect(isTrustedSetupUrl(url), isFalse, reason: url);
      }
    });
  });
}
