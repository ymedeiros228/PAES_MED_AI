import 'package:shared_preferences/shared_preferences.dart';

/// Controla quando o confete de conquistas deve aparecer na tela de Progresso.
///
/// Antes o confete disparava toda vez que a aba abria com qualquer conquista
/// desbloqueada (`unlockedCount > 0`), virando ruído repetitivo. Agora só
/// comemoramos quando o total de conquistas cresce além do que o usuário já
/// viu — ou seja, num desbloqueio novo de verdade.

const _seenUnlockedKey = 'progress_seen_unlocked_v1';

/// Retorna true quando há um desbloqueio novo a comemorar.
bool shouldCelebrateUnlocks(int currentUnlocked, int seenUnlocked) =>
    currentUnlocked > 0 && currentUnlocked > seenUnlocked;

/// Quantidade de conquistas que o usuário já viu comemorada (0 se nunca).
Future<int> lastCelebratedUnlocks() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_seenUnlockedKey) ?? 0;
}

/// Persiste o total de conquistas já visto (nunca regride).
Future<void> markCelebratedUnlocks(int count) async {
  final prefs = await SharedPreferences.getInstance();
  final current = prefs.getInt(_seenUnlockedKey) ?? 0;
  if (count > current) await prefs.setInt(_seenUnlockedKey, count);
}
