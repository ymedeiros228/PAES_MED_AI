/// Copy amigável para o aluno (PAES/UEMA) — sem jargão de git/dev/SRS em inglês.
library;

/// Tipos de erro na sessão / simulado.
const Map<String, String> kErrorTypeLabelsPt = {
  'conceito': 'Conteúdo',
  'interpretacao': 'Interpretação',
  'calculo': 'Cálculo',
  'distracao': 'Atração',
  'tempo': 'Tempo',
};

String errorTypeLabelPt(String raw) =>
    kErrorTypeLabelsPt[raw] ?? raw;

/// Subtítulo calmo; atalhos ficam no tooltip.
const String kSoftAtalhosHint = 'Atalhos no teclado (passe o mouse no ?)';

/// `next_due` ISO / SQL date → “Hoje”, “Amanhã”, “há N dias”, “em N dias”, ou data curta.
String humanDueLabel(String? raw) {
  if (raw == null || raw.isEmpty || raw == '—') return '—';
  final trimmed = raw.trim();
  DateTime? parsed;
  try {
    parsed = DateTime.tryParse(trimmed);
  } catch (_) {
    parsed = null;
  }
  if (parsed == null && trimmed.length >= 10) {
    parsed = DateTime.tryParse(trimmed.substring(0, 10));
  }
  if (parsed == null) return trimmed;
  final now = DateTime.now();
  final a = DateTime(now.year, now.month, now.day);
  final b = DateTime(parsed.year, parsed.month, parsed.day);
  final diff = b.difference(a).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Amanhã';
  if (diff == -1) return 'Ontem';
  if (diff > 1 && diff <= 14) return 'em $diff dias';
  if (diff < -1 && diff >= -14) return 'há ${-diff} dias';
  final dd = parsed.day.toString().padLeft(2, '0');
  final mm = parsed.month.toString().padLeft(2, '0');
  return '$dd/$mm/${parsed.year}';
}
