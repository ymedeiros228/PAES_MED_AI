import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Helper padronizado para snackbars — success/error/info com ícone e cor.
/// Substitui as 40+ chamadas manuais de ScaffoldMessenger.showSnackBar
/// por uma API consistente e acessível.
class SnackbarHelper {
  SnackbarHelper._();

  static void success(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    HapticFeedback.lightImpact();
    _show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      behavior: SnackBarBehavior.floating,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    HapticFeedback.heavyImpact();
    _show(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      isError: true,
      behavior: SnackBarBehavior.floating,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      behavior: SnackBarBehavior.floating,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required SnackBarBehavior behavior,
    bool isError = false,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final cs = Theme.of(context).colorScheme;
    messenger.showSnackBar(
      SnackBar(
        behavior: behavior,
        duration: isError ? const Duration(seconds: 5) : const Duration(seconds: 3),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: isError ? cs.onError : cs.onPrimary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
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
}
