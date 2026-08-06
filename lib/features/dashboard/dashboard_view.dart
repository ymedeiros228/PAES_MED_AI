// Helpers puros (sem Flutter) para o Dashboard/Hoje, extraídos de
// `dashboard_screen.dart` para permitir testes unitários da lógica sem widgets.

/// Rótulo curto do checkpoint de sessão para o CTA "Continuar".
String checkpointShortLabel(Map<String, dynamic> cp) {
  final phase = cp['phaseName']?.toString() ?? '';
  final phaseLabel = switch (phase) {
    'theory' => 'Teoria',
    'questions' => 'Questões',
    'revisions' || 'review' || 'cards' => 'Revisão',
    _ => phase.isEmpty ? 'Sessão' : phase,
  };
  final q = (cp['qIndex'] as num?)?.toInt();
  if (phase == 'questions' && q != null) return '$phaseLabel · item ${q + 1}';
  return phaseLabel;
}

/// Mensagem de backup obsoleto/ausente, ou null quando há backup recente e ok.
/// Regras: sem backup ok → avisa; backup > 7 dias → avisa; data inválida → avisa.
String? backupStaleMessage(Map<String, dynamic>? last, DateTime now) {
  if (last == null) return null;
  final hasOk = last['ok'] == true;
  if (!hasOk) return 'Nenhum backup verificado — salve em Ajustes.';
  final at = last['at']?.toString() ?? '';
  if (at.isEmpty) return null;
  final DateTime when;
  try {
    when = DateTime.parse(at);
  } catch (_) {
    return 'Data do último backup inválida — refaça em Ajustes.';
  }
  if (now.difference(when).inDays > 7) {
    return 'Último backup há mais de 7 dias ($at).';
  }
  return null;
}

/// Resultado da linha de checklist de cards do dia.
typedef CardsChecklist = ({bool done, String label, String? actionLabel});

/// Deriva a linha de "cards do dia" a partir da contagem de cards devidos e da
/// flag de conclusão vinda do checklist do backend.
CardsChecklist cardsChecklist(int dueCount, bool cardsDoneFlag) {
  final done = dueCount == 0 || cardsDoneFlag;
  return (
    done: done,
    label: dueCount == 0 ? 'Cards em dia' : '$dueCount card(s) para revisar',
    actionLabel: dueCount == 0 ? null : 'Cards',
  );
}
