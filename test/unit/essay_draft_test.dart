import 'package:flutter_test/flutter_test.dart';
import 'package:paes_med_ai/features/essay/essay_draft.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('EssayDraft', () {
    test('round-trip toJson/fromJson', () {
      const d = EssayDraft(theme: 'Tema X', text: 'Meu texto');
      final back = EssayDraft.fromJson(d.toJson());
      expect(back, d);
    });

    test('fromJson tolera campos ausentes', () {
      final d = EssayDraft.fromJson(const {});
      expect(d.theme, '');
      expect(d.text, '');
      expect(d.isEmpty, isTrue);
    });

    test('isEmpty considera só espaços', () {
      expect(const EssayDraft(theme: 'T', text: '   ').isEmpty, isTrue);
      expect(const EssayDraft(theme: 'T', text: 'ok').isEmpty, isFalse);
    });
  });

  group('save/load/clear', () {
    test('save depois load devolve o mesmo rascunho', () async {
      const d = EssayDraft(theme: 'Saúde', text: 'Parágrafo de teste');
      await saveEssayDraft(d);
      expect(await loadEssayDraft(), d);
    });

    test('load sem nada salvo é null', () async {
      expect(await loadEssayDraft(), isNull);
    });

    test('save com texto vazio limpa (load null)', () async {
      await saveEssayDraft(const EssayDraft(theme: 'T', text: 'algo'));
      await saveEssayDraft(const EssayDraft(theme: 'T', text: '   '));
      expect(await loadEssayDraft(), isNull);
    });

    test('clear remove o rascunho', () async {
      await saveEssayDraft(const EssayDraft(theme: 'T', text: 'algo'));
      await clearEssayDraft();
      expect(await loadEssayDraft(), isNull);
    });

    test('load ignora JSON inválido', () async {
      SharedPreferences.setMockInitialValues({'essay_draft_v1': 'nao-e-json'});
      expect(await loadEssayDraft(), isNull);
    });
  });
}
