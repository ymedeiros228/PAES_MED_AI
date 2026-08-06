import 'package:flutter_test/flutter_test.dart';
import 'package:paes_med_ai/core/data/study_prefs_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _isoFrom(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  group('ExamDateState.copyWith', () {
    const base = ExamDateState(
      date: '2027-01-01',
      syncError: 'erro',
      hydrateNote: 'nota',
    );

    test('clearSyncError zera o erro', () {
      final c = base.copyWith(clearSyncError: true);
      expect(c.syncError, isNull);
      expect(c.hydrateNote, 'nota');
      expect(c.date, '2027-01-01');
    });

    test('clearHydrateNote zera a nota', () {
      final c = base.copyWith(clearHydrateNote: true);
      expect(c.hydrateNote, isNull);
      expect(c.syncError, 'erro');
    });

    test('atualiza a data preservando o resto', () {
      final c = base.copyWith(date: '2027-12-31');
      expect(c.date, '2027-12-31');
      expect(c.syncError, 'erro');
    });
  });

  group('ExamDateNotifier.daysUntilExam', () {
    late ExamDateNotifier notifier;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Uma data local válida faz o _load() retornar cedo, sem tocar a rede.
      SharedPreferences.setMockInitialValues({'exam_date_iso': '2099-12-31'});
      notifier = ExamDateNotifier();
      // Deixa o _load() assíncrono do construtor assentar antes de sobrescrever.
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() => notifier.dispose());

    test('null quando data vazia', () {
      notifier.state = const ExamDateState();
      expect(notifier.daysUntilExam, isNull);
    });

    test('null quando ISO inválida', () {
      notifier.state = const ExamDateState(date: 'not-a-date');
      expect(notifier.daysUntilExam, isNull);
    });

    test('0 quando a data é hoje', () {
      notifier.state = ExamDateState(date: _isoFrom(DateTime.now()));
      expect(notifier.daysUntilExam, 0);
    });

    test('positivo para data futura', () {
      notifier.state = ExamDateState(
        date: _isoFrom(DateTime.now().add(const Duration(days: 10))),
      );
      expect(notifier.daysUntilExam, inInclusiveRange(9, 10));
    });

    test('negativo para data passada', () {
      notifier.state = const ExamDateState(date: '2000-01-01');
      expect(notifier.daysUntilExam, lessThan(0));
    });
  });
}
