import 'package:flutter_test/flutter_test.dart';
import 'package:paes_med_ai/features/dashboard/dashboard_view.dart';

void main() {
  group('checkpointShortLabel', () {
    test('mapeia fases conhecidas', () {
      expect(checkpointShortLabel({'phaseName': 'theory'}), 'Teoria');
      expect(checkpointShortLabel({'phaseName': 'revisions'}), 'Revisão');
      expect(checkpointShortLabel({'phaseName': 'cards'}), 'Revisão');
    });

    test('questions com índice mostra o item (1-based)', () {
      expect(checkpointShortLabel({'phaseName': 'questions', 'qIndex': 0}), 'Questões · item 1');
      expect(checkpointShortLabel({'phaseName': 'questions', 'qIndex': 4}), 'Questões · item 5');
    });

    test('questions sem índice mostra só a fase', () {
      expect(checkpointShortLabel({'phaseName': 'questions'}), 'Questões');
    });

    test('fase vazia/desconhecida', () {
      expect(checkpointShortLabel(const {}), 'Sessão');
      expect(checkpointShortLabel({'phaseName': 'custom'}), 'custom');
    });
  });

  group('backupStaleMessage', () {
    final now = DateTime(2026, 8, 6, 12);

    test('null quando não há dado', () {
      expect(backupStaleMessage(null, now), isNull);
    });

    test('avisa quando não há backup ok', () {
      expect(
        backupStaleMessage({'ok': false}, now),
        'Nenhum backup verificado — salve em Ajustes.',
      );
    });

    test('null quando backup ok e recente', () {
      final recent = now.subtract(const Duration(days: 2)).toIso8601String();
      expect(backupStaleMessage({'ok': true, 'at': recent}, now), isNull);
    });

    test('avisa quando > 7 dias', () {
      final old = now.subtract(const Duration(days: 10)).toIso8601String();
      final msg = backupStaleMessage({'ok': true, 'at': old}, now);
      expect(msg, contains('mais de 7 dias'));
    });

    test('avisa quando data inválida', () {
      expect(
        backupStaleMessage({'ok': true, 'at': 'nao-e-data'}, now),
        contains('inválida'),
      );
    });

    test('null quando ok e sem data', () {
      expect(backupStaleMessage({'ok': true, 'at': ''}, now), isNull);
    });
  });

  group('cardsChecklist', () {
    test('0 cards devidos = em dia, sem ação', () {
      final r = cardsChecklist(0, false);
      expect(r.done, isTrue);
      expect(r.label, 'Cards em dia');
      expect(r.actionLabel, isNull);
    });

    test('N cards devidos = pendente com ação', () {
      final r = cardsChecklist(3, false);
      expect(r.done, isFalse);
      expect(r.label, '3 card(s) para revisar');
      expect(r.actionLabel, 'Cards');
    });

    test('flag do checklist marca como done mesmo com cards devidos', () {
      final r = cardsChecklist(3, true);
      expect(r.done, isTrue);
      expect(r.actionLabel, 'Cards'); // ação continua disponível
    });
  });
}
