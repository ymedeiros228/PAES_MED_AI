import 'package:flutter/material.dart';

import '../../../../core/data/api_client.dart';
import '../../../../core/data/api_error.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../domain/question.dart';

/// Aviso discreto para questões que citam figura/gráfico/tabela que não vem
/// no texto (enunciado extraído de PDF). Some sozinho se o enunciado não cita.
class FiguraAviso extends StatelessWidget {
  const FiguraAviso({required this.statement, this.sourcePdf, this.year, super.key});

  final String statement;
  final String? sourcePdf;
  final int? year;

  @override
  Widget build(BuildContext context) {
    if (!mencionaFigura(statement)) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final pdf = sourcePdf;
    return Padding(
      padding: const EdgeInsets.only(bottom: kGap12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: kGap12, vertical: kGap8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.image_not_supported_outlined, size: 18, color: cs.onSurface.withOpacity(0.65)),
            const SizedBox(width: kGap8),
            Expanded(
              child: Text(
                'Esta questão tem figura na prova original.',
                style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.75)),
              ),
            ),
            if (pdf != null && pdf.isNotEmpty)
              TextButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await apiClient.openPath(pdf);
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(humanOpenPathError(e, label: 'PDF da prova${year != null ? ' $year' : ''}'))),
                    );
                  }
                },
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                label: const Text('Abrir a prova'),
              ),
          ],
        ),
      ),
    );
  }
}
