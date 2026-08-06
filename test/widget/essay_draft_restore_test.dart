import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paes_med_ai/core/data/providers.dart';
import 'package:paes_med_ai/features/essay/presentation/essay_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap() {
  return ProviderScope(
    overrides: [
      essayProgressProvider.overrideWith((ref) async => {'count': 0}),
      essaysProvider.overrideWith((ref) async => const []),
    ],
    child: const MaterialApp(home: Scaffold(body: EssayScreen())),
  );
}

void main() {
  testWidgets('restaura rascunho salvo no campo de texto ao abrir', (tester) async {
    const savedText = 'Este é o meu rascunho salvo previamente para o teste.';
    SharedPreferences.setMockInitialValues({
      'essay_draft_v1': jsonEncode({'theme': 'Tecnologia', 'text': savedText}),
    });

    await tester.pumpWidget(_wrap());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(savedText), findsOneWidget);
    expect(find.textContaining('Rascunho restaurado'), findsOneWidget);
  });

  testWidgets('sem rascunho salvo, campo começa vazio', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(_wrap());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // A nota padrão (não "restaurado") aparece.
    expect(find.textContaining('Rascunho salvo automaticamente'), findsOneWidget);
    expect(find.textContaining('Rascunho restaurado'), findsNothing);
  });
}
