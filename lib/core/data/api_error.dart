/// Mensagens de erro legíveis no app de estudo (Ciclo CJ).
/// Evita `ClientException` / stack em inglês na UI.
String humanApiError(Object e, {String fallback = 'Não deu para carregar — tente de novo.'}) {
  final s = e.toString().toLowerCase();
  if (s.contains('socket') ||
      s.contains('connection refused') ||
      s.contains('failed host lookup') ||
      s.contains('network is unreachable') ||
      s.contains('clientexception') ||
      s.contains('connection reset') ||
      s.contains('timed out') ||
      s.contains('timeout')) {
    return 'Sem conexão local. Reabra pelo ícone PAES MED AI.';
  }
  if (s.contains('404') || s.contains('not found')) {
    return 'Não encontrado no acervo local.';
  }
  if (s.contains('400') || s.contains('invalid')) {
    return 'Pedido inválido. Ajuste e tente de novo.';
  }
  if (s.contains('500') || s.contains('internal')) {
    return 'Falha no servidor local. Tente de novo em instantes.';
  }
  // Não expõe stack/exception eng
  if (s.contains('exception') || s.contains('error:') || s.contains('http')) {
    return fallback;
  }
  final raw = e.toString().trim();
  if (raw.length > 120 || raw.contains('\n')) return fallback;
  // Só retorna texto curto se já parecer humano
  if (RegExp(r'^[A-Za-zÀ-ú0-9 .,\-–—!?()]+$').hasMatch(raw) && raw.length < 80) {
    return raw;
  }
  return fallback;
}

/// Erros ao abrir PDF/arquivo local (open-path / ano).
String humanOpenPathError(
  Object e, {
  String? label,
}) {
  final s = e.toString().toLowerCase();
  final name = (label != null && label.isNotEmpty) ? label : 'Arquivo';
  if (s.contains('404') ||
      s.contains('not found') ||
      s.contains('não encontrado') ||
      s.contains('nao encontrado')) {
    return '$name sumiu do disco — coloque o PDF em data/provas ou atualize o acervo.';
  }
  if (s.contains('403')) {
    return 'Só abrimos arquivos dentro da pasta de dados do app.';
  }
  if (s.contains('500') ||
      s.contains('não foi possível abrir') ||
      s.contains('nao foi possivel abrir')) {
    return '$name está no PC mas não abriu — use Abrir provas na Biblioteca.';
  }
  return humanApiError(e, fallback: '$name no PC mas não abriu — verifique data/provas.');
}
