import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api_client.dart';

/// Mensagens de erro legíveis no app de estudo (Ciclo CJ).
/// Evita `ClientException` / stack em inglês na UI.
String humanApiError(Object e, {String fallback = 'Não deu para carregar — tente de novo.'}) {
  // ApiTimeoutException já traz mensagem humanizada específica — usa direto.
  if (e is ApiTimeoutException) return e.message;
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
    return '$name sumiu do disco — coloque o PDF na pasta Provas ou atualize o acervo.';
  }
  if (s.contains('403')) {
    return 'Só abrimos arquivos dentro da pasta de dados do app.';
  }
  if (s.contains('500') ||
      s.contains('não foi possível abrir') ||
      s.contains('nao foi possivel abrir')) {
    return '$name está no PC mas não abriu — use Abrir provas na Biblioteca.';
  }
  return humanApiError(e, fallback: '$name no PC mas não abriu — verifique a pasta Provas.');
}

/// Toast único para open-path (2 linhas + ícone) — IDEAS Global/open-path.
void showOpenPathSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.folder_off_outlined : Icons.folder_open_outlined,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.45,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      action: actionLabel != null && onAction != null
          ? SnackBarAction(label: actionLabel, onPressed: onAction)
          : null,
    ),
  );
}
