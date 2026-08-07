/// Copy amigável para o aluno (PAES/UEMA) — sem jargão de git/dev/SRS em inglês.

/// Tipos de erro na sessão / simulado.
const Map<String, String> kErrorTypeLabelsPt = {
  'conceito': 'Conceito',
  'interpretacao': 'Interpretação',
  'calculo': 'Cálculo',
  'distracao': 'Distração',
  'tempo': 'Tempo',
};

String errorTypeLabelPt(String raw) =>
    kErrorTypeLabelsPt[raw] ?? raw;

/// Subtítulo calmo; atalhos ficam no tooltip.
const String kSoftAtalhosHint = 'Atalhos no teclado (passe o mouse no ?)';
