import 'package:flutter_test/flutter_test.dart';
import 'package:paes_med_ai/features/progress/achievement_celebration.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('shouldCelebrateUnlocks', () {
    test('comemora quando cresce além do já visto', () {
      expect(shouldCelebrateUnlocks(5, 4), isTrue);
      expect(shouldCelebrateUnlocks(1, 0), isTrue);
    });

    test('não comemora quando igual ou menor ao já visto', () {
      expect(shouldCelebrateUnlocks(4, 4), isFalse);
      expect(shouldCelebrateUnlocks(3, 4), isFalse);
    });

    test('não comemora sem nenhuma conquista', () {
      expect(shouldCelebrateUnlocks(0, 0), isFalse);
    });
  });

  group('persistência de comemorações', () {
    test('sem nada salvo, o visto começa em zero', () async {
      expect(await lastCelebratedUnlocks(), 0);
    });

    test('marca e lê o total comemorado', () async {
      await markCelebratedUnlocks(4);
      expect(await lastCelebratedUnlocks(), 4);
    });

    test('nunca regride o total já visto', () async {
      await markCelebratedUnlocks(6);
      await markCelebratedUnlocks(2);
      expect(await lastCelebratedUnlocks(), 6);
    });

    test('fluxo: primeira visita comemora uma vez, depois silencia', () async {
      // Primeira carga: 4 desbloqueadas, nada visto ainda.
      final seen1 = await lastCelebratedUnlocks();
      expect(shouldCelebrateUnlocks(4, seen1), isTrue);
      await markCelebratedUnlocks(4);

      // Segunda carga com o mesmo total: sem confete.
      final seen2 = await lastCelebratedUnlocks();
      expect(shouldCelebrateUnlocks(4, seen2), isFalse);

      // Novo desbloqueio (5): comemora de novo.
      final seen3 = await lastCelebratedUnlocks();
      expect(shouldCelebrateUnlocks(5, seen3), isTrue);
    });
  });
}
