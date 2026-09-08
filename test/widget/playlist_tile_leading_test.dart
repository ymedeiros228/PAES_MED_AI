import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paes_med_ai/core/widgets/ui_kit.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('sem leading usa o ícone padrão', (tester) async {
    await tester.pumpWidget(
      _wrap(const PlaylistTile(
        title: 'Item',
        leadingIcon: Icons.play_circle_outline_rounded,
      )),
    );
    await tester.pump();

    expect(find.byIcon(Icons.play_circle_outline_rounded), findsOneWidget);
  });

  testWidgets('leading customizado substitui o ícone', (tester) async {
    await tester.pumpWidget(
      _wrap(const PlaylistTile(
        title: 'Item',
        leadingIcon: Icons.play_circle_outline_rounded,
        leading: Text('7', key: ValueKey('rank')),
      )),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('rank')), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    // O ícone padrão não deve aparecer quando há leading.
    expect(find.byIcon(Icons.play_circle_outline_rounded), findsNothing);
  });
}
