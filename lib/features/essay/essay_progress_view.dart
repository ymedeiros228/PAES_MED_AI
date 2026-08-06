// Helpers puros (sem Flutter) para a UI de progresso de Redação.
//
// Extraídos de `essay_screen.dart` para permitir testes unitários da lógica
// de radar/streak/eixo mais fraco sem montar widgets.

double _clamp10(Object? raw) {
  final v = raw is num ? raw.toDouble() : 0.0;
  if (v < 0.0) return 0.0;
  if (v > 10.0) return 10.0;
  return v;
}

/// Valores (0–10) do radar para a média por eixo, na ordem de [axes].
List<double> essayRadarValues(Map<String, dynamic> averages, List<String> axes) {
  return [for (final key in axes) _clamp10(averages[key])];
}

/// Valores (0–10) da última redação por eixo, ou null se não houver dado útil.
List<double>? essayRadarLastValues(
  Map<String, dynamic>? lastAxisScores,
  List<String> axes,
) {
  if (lastAxisScores == null || lastAxisScores.isEmpty) return null;
  final hasAny = axes.any((key) => lastAxisScores[key] is num);
  if (!hasAny) return null;
  return [for (final key in axes) _clamp10(lastAxisScores[key])];
}

/// Rótulo humano para a sequência (streak) de dias.
String streakLabel(int streakDays) {
  if (streakDays <= 0) return 'Comece sua sequência hoje';
  return 'Sequência de $streakDays dia(s)';
}

/// Chave do eixo mais fraco no payload de progresso, ou null.
String? weakestAxisKey(Map<String, dynamic> progress) {
  final weak = progress['weakestAxis']?.toString();
  if (weak == null || weak.isEmpty) return null;
  return weak;
}

/// Rótulo amigável do eixo mais fraco (usa `labels` quando existir).
String? weakestAxisLabel(Map<String, dynamic> progress) {
  final weak = weakestAxisKey(progress);
  if (weak == null) return null;
  final labels = progress['labels'];
  if (labels is Map && labels[weak] != null) {
    return labels[weak].toString();
  }
  return weak;
}

/// True quando [axisKey] é o eixo mais fraco do progresso.
bool isWeakestAxis(Map<String, dynamic> progress, String axisKey) {
  return weakestAxisKey(progress) == axisKey;
}
