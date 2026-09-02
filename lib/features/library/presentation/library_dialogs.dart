import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Diálogos do acervo — UI isolada da orquestração em [LibraryScreen].
abstract final class LibraryDialogs {
  static Future<String?> postCommitCta({
    required BuildContext context,
    required String title,
    required String body,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(ctx, 'later');
            },
            child: const Text('Depois'),
          ),
          FilledButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx, 'study');
            },
            child: const Text('Estudar agora'),
          ),
        ],
      ),
    );
  }

  static Future<String?> fetchPlaybook({
    required BuildContext context,
    required String title,
    required String body,
    bool canCommitDisk = false,
    bool showPortal = false,
    bool showRetry = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          if (canCommitDisk)
            FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(ctx, 'disk');
              },
              child: const Text('Gravar PDFs do PC'),
            )
          else
            FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(ctx, 'provas');
              },
              child: const Text('Abrir provas'),
            ),
          if (showPortal)
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.pop(ctx, 'portal');
              },
              child: const Text('Portal'),
            ),
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(ctx, 'gabaritos');
            },
            child: const Text('Abrir gabaritos'),
          ),
          if (showRetry)
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.pop(ctx, 'retry');
              },
              child: const Text('Tentar de novo'),
            ),
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(ctx, 'ok');
            },
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  static Future<void> importAllComplete({
    required BuildContext context,
    required String message,
    required String perYear,
    required String waitLine,
    required int officialN,
    required bool hasWaitingYears,
    required VoidCallback onOpenGabaritos,
    required VoidCallback onStudy,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar todos com gabarito'),
        content: SingleChildScrollView(
          child: Text(
            '$message\n\n$perYear$waitLine\n\n'
            'Base oficial: $officialN. Abrir sessão só com oficiais com gabarito?',
          ),
        ),
        actions: [
          if (hasWaitingYears)
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.pop(ctx);
                onOpenGabaritos();
              },
              child: const Text('Abrir pasta Gabaritos'),
            ),
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(ctx);
            },
            child: const Text('Fechar'),
          ),
          FilledButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx);
              onStudy();
            },
            child: const Text('Estudar'),
          ),
        ],
      ),
    );
  }

  /// `true` = abrir gabaritos, `false` = OK, `null` = ver preview.
  static Future<bool?> importYearMissingGabarito({
    required BuildContext context,
    required int year,
    required String message,
    bool hasPreview = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('PAES $year · sem gabarito'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(ctx, false);
            },
            child: const Text('OK'),
          ),
          FilledButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx, true);
            },
            child: const Text('Abrir gabaritos'),
          ),
          if (hasPreview)
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.pop(ctx, null);
              },
              child: const Text('Ver preview'),
            ),
        ],
      ),
    );
  }

  static Future<String?> confirmStudyReady({required BuildContext context}) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tudo pronto para estudar'),
        content: const Text(
          'As questões foram importadas e estão prontas para uso.\n'
          'Bons estudos!',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx, 'study');
            },
            child: const Text('Estudar agora'),
          ),
        ],
      ),
    );
  }

  static Future<bool?> fetchYearDownloaded({
    required BuildContext context,
    required int year,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('PAES $year baixado'),
        content: const Text('PDFs na pasta. Abrir revisão agora?'),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(ctx, false);
            },
            child: const Text('Depois'),
          ),
          FilledButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx, true);
            },
            child: const Text('Revisar'),
          ),
        ],
      ),
    );
  }
}
