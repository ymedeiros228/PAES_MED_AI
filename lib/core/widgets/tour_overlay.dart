import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tour guiado: mostra balao explicativo na primeira visita de cada tela.
/// Uso: TourOverlay.maybeShow(context, key: 'tour_dashboard', title: '...', body: '...')
class TourOverlay {
  static Future<void> maybeShow(
    BuildContext context, {
    required String key,
    required String title,
    required String body,
    IconData icon = Icons.lightbulb_outline_rounded,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(key) == true) return;
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          body,
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Pular'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );

    await prefs.setBool(key, true);
  }
}
