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
