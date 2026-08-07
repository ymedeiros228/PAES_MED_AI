import 'package:flutter_test/flutter_test.dart';
import 'package:paes_med_ai/features/essay/essay_progress_view.dart';

void main() {
  const axes = ['grammar', 'cohesion', 'coherence', 'argumentation', 'intervention'];

  group('essayRadarValues', () {
    test('clampa 0–10 e preenche eixos faltando com 0', () {
      final v = essayRadarValues({'grammar': 12, 'cohesion': -1, 'coherence': 5.5}, axes);
      expect(v, [10.0, 0.0, 5.5, 0.0, 0.0]);
    });
  });

  group('essayRadarLastValues', () {
    test('null quando vazio', () {
      expect(essayRadarLastValues(null, axes), isNull);
      expect(essayRadarLastValues({}, axes), isNull);
    });

    test('devolve lista quando há números', () {
      final v = essayRadarLastValues({'grammar': 7}, axes);
      expect(v, isNotNull);
      expect(v!.first, 7.0);
    });
  });

  group('streak / weakest', () {
    test('streakLabel', () {
      expect(streakLabel(0), 'Comece sua sequência hoje');
      expect(streakLabel(3), 'Sequência de 3 dia(s)');
    });

    test('weakestAxisKey/Label/isWeakest', () {
      final p = {
        'weakestAxis': 'cohesion',
        'labels': {'cohesion': 'Coesão'},
      };
      expect(weakestAxisKey(p), 'cohesion');
      expect(weakestAxisLabel(p), 'Coesão');
      expect(isWeakestAxis(p, 'cohesion'), isTrue);
      expect(isWeakestAxis(p, 'grammar'), isFalse);
    });
  });
}
