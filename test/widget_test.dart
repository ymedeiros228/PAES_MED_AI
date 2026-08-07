import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paes_med_ai/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('abre o app PAES MED AI', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_done_v1': false});
    await tester.pumpWidget(const ProviderScope(child: PaesMedAiApp()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('PAES'), findsWidgets);
  });
}
