import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paes_med_ai/app.dart';

void main() {
  testWidgets('abre o app PAES MED AI', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PaesMedAiApp()));
    await tester.pump();
    expect(find.textContaining('PAES'), findsWidgets);
  });
}
