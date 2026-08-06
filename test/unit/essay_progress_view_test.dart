import 'package:flutter_test/flutter_test.dart';
import 'package:paes_med_ai/features/essay/essay_progress_view.dart';

void main() {
  const axes = ['grammar', 'cohesion', 'coherence', 'argumentation', 'intervention'];

  group('essayRadarValues', () {
    test('mapeia médias na ordem dos eixos e faz clamp 0–10', () {
      final v = essayRadarValues(
        {'grammar': 8, 'cohesion': 5.5, 'coherence': 12, 'argumentation': -3},
        axes,
      );
      expect(v, [8.0, 5.5, 10.0, 0.0, 0.0]);
    });

    test('valores ausentes/não numéricos viram 0', () {
      expect(essayRadarValues({'grammar': 'x'}, axes), [0.0, 0.0, 0.0, 0.0, 0.0]);
    });
  });

  group('essayRadarLastValues', () {
    test('null quando mapa vazio ou sem números', () {
      expect(essayRadarLastValues(null, axes), isNull);
      expect(essayRadarLastValues(const {}, axes), isNull);
      expect(essayRadarLastValues(const {'grammar': 'n/a'}, axes), isNull);
    });

    test('retorna valores quando há ao menos um número', () {
      final v = essayRadarLastValues({'grammar': 7, 'cohesion': 9}, axes);
      expect(v, [7.0, 9.0, 0.0, 0.0, 0.0]);
    });
  });

  group('streakLabel', () {
    test('0 ou negativo convida a começar', () {
      expect(streakLabel(0), 'Comece sua sequência hoje');
      expect(streakLabel(-2), 'Comece sua sequência hoje');
    });

    test('positivo mostra a contagem', () {
      expect(streakLabel(1), 'Sequência de 1 dia(s)');
      expect(streakLabel(5), 'Sequência de 5 dia(s)');
    });
  });

  group('weakest axis', () {
    test('weakestAxisKey lê o campo', () {
      expect(weakestAxisKey({'weakestAxis': 'cohesion'}), 'cohesion');
      expect(weakestAxisKey(const {}), isNull);
      expect(weakestAxisKey(const {'weakestAxis': ''}), isNull);
    });

    test('weakestAxisLabel usa labels quando existir', () {
      expect(
        weakestAxisLabel({
          'weakestAxis': 'cohesion',
          'labels': {'cohesion': 'Coesão'},
        }),
        'Coesão',
      );
      // Sem label mapeado, retorna a própria chave.
      expect(weakestAxisLabel({'weakestAxis': 'cohesion'}), 'cohesion');
      expect(weakestAxisLabel(const {}), isNull);
    });

    test('isWeakestAxis compara a chave', () {
      final p = {'weakestAxis': 'grammar'};
      expect(isWeakestAxis(p, 'grammar'), isTrue);
      expect(isWeakestAxis(p, 'cohesion'), isFalse);
    });
  });
}
