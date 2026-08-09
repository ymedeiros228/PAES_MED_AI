import 'dart:ui';

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

  testWidgets('onboarding permite concluir em janela baixa', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 420));
    SharedPreferences.setMockInitialValues({'onboarding_done_v1': false});
    await tester.pumpWidget(const ProviderScope(child: PaesMedAiApp()));
    await tester.pump();

    for (var i = 0; i < 3; i++) {
      final continueButton = find.text('Continuar');
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pump();
    }

    final finishButton = find.text('Ir para Hoje');
    await tester.ensureVisible(finishButton);
    expect(finishButton, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
