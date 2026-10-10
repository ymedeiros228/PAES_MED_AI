import 'package:flutter_test/flutter_test.dart';
import 'package:paes_med_ai/core/data/study_prefs_providers.dart';

void main() {
  final now = DateTime(2026, 10, 10, 15);
  test('prova que já passou é negativa e isPast', () {
    final cd = ExamCountdown.fromIso('2026-09-26', now: now);
    expect(cd.daysLeft, -14);
    expect(cd.isPast, isTrue);
    expect(cd.shortLabel, contains('já passou'));
  });
  test('prova futura e hoje', () {
    expect(ExamCountdown.fromIso('2026-10-17', now: now).daysLeft, 7);
    expect(ExamCountdown.fromIso('2026-10-10', now: now).isToday, isTrue);
  });
  test('sem data', () {
    expect(ExamCountdown.fromIso('', now: now).hasDate, isFalse);
  });
}
