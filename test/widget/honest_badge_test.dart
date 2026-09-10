import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paes_med_ai/core/widgets/ui/session_widgets.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('mostra rótulo padrão e ícone informativo', (tester) async {
    await tester.pumpWidget(_wrap(const HonestBadge()));
    await tester.pump();

    expect(find.text('treino local · não banca'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
  });

  testWidgets('aceita rótulo e ícone customizados', (tester) async {
    await tester.pumpWidget(
      _wrap(const HonestBadge(
        label: 'Ouro',
        icon: Icons.workspace_premium_outlined,
      )),
    );
    await tester.pump();

    expect(find.text('Ouro'), findsOneWidget);
    expect(find.byIcon(Icons.workspace_premium_outlined), findsOneWidget);
    expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
  });

  testWidgets('renderiza como pill (Container com borda arredondada)',
      (tester) async {
    await tester.pumpWidget(_wrap(const HonestBadge()));
    await tester.pump();

    final container = tester.widget<Container>(
      find.ancestor(
        of: find.byIcon(Icons.info_outline_rounded),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.borderRadius, isNotNull);
    expect(decoration.border, isNotNull);
  });
}
