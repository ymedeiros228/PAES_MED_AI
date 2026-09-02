String libraryUiStatusLabel(String? s) {
  switch (s) {
    case 'committed':
      return 'No acervo';
    case 'onDisk':
      return 'Par com gabarito · pode gravar';
    case 'partial':
      return 'Parcial · sem gabarito';
    case 'partialGab':
      return 'Só gabarito · falta prova';
    case 'preview':
      return 'Precisa revisar';
    case 'found':
      return 'Pode baixar';
    case 'needs_manual':
      return 'Baixar à mão';
    default:
      return 'Vazio';
  }
}

String libraryUiBadge(
  String? status, {
  required bool ready,
  required bool diskOk,
  required bool hasProva,
  required bool hasGab,
}) {
  if (ready) return 'pronto';
  if (status == 'partial' || (hasProva && !hasGab)) return 'parcial';
  if (diskOk) return 'prova + gabarito';
  return status ?? '';
}
