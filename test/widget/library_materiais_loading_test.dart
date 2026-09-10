import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paes_med_ai/core/widgets/ui_kit.dart';
import 'package:paes_med_ai/features/library/presentation/widgets/library_materiais_tab.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SizedBox(height: 600, child: child)));

void main() {
  testWidgets('estado de carregamento usa skeleton, não spinner',
      (tester) async {
    await tester.pumpWidget(
      _wrap(const LibraryMateriaisTab(pdfsLoaded: false, pdfs: [])),
    );
    // pump curto para não travar no shimmer (que repete indefinidamente).
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(SkeletonListTile), findsWidgets);
  });

  testWidgets('estado vazio mostra mensagem, sem skeleton', (tester) async {
    await tester.pumpWidget(
      _wrap(const LibraryMateriaisTab(pdfsLoaded: true, pdfs: [])),
    );
    await tester.pump();

    expect(find.byType(SkeletonListTile), findsNothing);
    expect(find.text('Nenhum PDF disponível.'), findsOneWidget);
  });
}
