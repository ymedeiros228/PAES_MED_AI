import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paes_med_ai/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('abre o app PAES MED AI', (tester) async {
    // Onboarding ainda não concluído → o router resolve para /onboarding, que
    // renderiza a marca "PAES MED AI" sem depender do backend.
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: PaesMedAiApp()));

    // O redirect do go_router lê SharedPreferences de forma assíncrona; alguns
    // pumps com tempo deixam a navegação assentar sem esperar rede.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('PAES MED AI'), findsWidgets);
  });
}
