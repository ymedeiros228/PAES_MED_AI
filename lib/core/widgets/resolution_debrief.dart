import 'package:flutter/material.dart';

/// Debrief limpo: explicação no corpo; fonte só no rodapé (Ciclo HJ).
class ResolutionDebrief extends StatelessWidget {
  const ResolutionDebrief({
    super.key,
    required this.question,
    this.professor,
    this.trailing,
    this.onOpenPdf,
    this.pdfAvailable = false,
    this.pdfYear,
  });

  final Map<String, dynamic> question;
  final Map<String, dynamic>? professor;
  final Widget? trailing;
  final VoidCallback? onOpenPdf;
  final bool pdfAvailable;
  final int? pdfYear;

  @override
  Widget build(BuildContext context) {
    final prof = professor ?? {};
    final quality = (prof['resolutionQuality'] ?? question['resolutionQuality'] ?? 'template').toString();
    final axesRaw = prof['resolutionAxes'] ?? question['resolutionAxes'];
    final axes = axesRaw is Map ? Map<String, dynamic>.from(axesRaw) : <String, dynamic>{};
    final resolution = (prof['resolution'] ?? question['resolution'] ?? '').toString();
    final macete = (prof['macete'] ?? question['macete'] ?? '').toString();
    final pegadinha = (prof['pegadinha'] ?? question['pegadinha'] ?? '').toString();
    final banca = (prof['bancaIntent'] ?? question['bancaIntent'] ?? '').toString();
    final isReal = quality == 'real';
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    Widget axisBlock(String title, String? body) {
      final t = (body ?? '').trim();
      if (t.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            SelectableText(t, style: tt.bodyLarge?.copyWith(height: 1.4)),
          ],
        ),
      );
    }

    final board = (prof['examBoard'] ?? question['examBoard'] ?? 'TREINO').toString().toUpperCase();
    final similar = prof['similarityOf'] ?? question['similarityOf'];
    final fonteParts = <String>[];
    if (board == 'UEMA_PAES') {
      fonteParts.add('Oficial PAES-UEMA');
    } else if (board == 'OUTRA') {
      fonteParts.add('Outra banca (reforço)');
    } else {
      fonteParts.add('Treino (não oficial UEMA)');
    }
    if (similar != null && similar.toString().trim().isNotEmpty) {
      fonteParts.add('item semelhante no acervo');
    }
    if (pdfYear != null) {
      fonteParts.add(pdfAvailable ? 'PDF $pdfYear' : 'PDF $pdfYear indisponível');
    }
    final fonteLine = fonteParts.join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isReal ? 'Explicação' : 'Apoio didático',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (!isReal) ...[
          const SizedBox(height: 6),
          Text(
            'Não é texto oficial da banca — só apoio local.',
            style: tt.bodySmall,
          ),
        ],
        const SizedBox(height: 12),
        if (isReal) ...[
          axisBlock('Comando', axes['comando']?.toString()),
          axisBlock('Conceito', axes['conceito']?.toString()),
          axisBlock('Gabarito', axes['gabarito']?.toString()),
          axisBlock('Distrator', axes['distrator']?.toString()),
          if (!axes.values.any((v) => (v?.toString() ?? '').trim().isNotEmpty) &&
              resolution.trim().isNotEmpty)
            SelectableText(resolution, style: tt.bodyLarge?.copyWith(height: 1.4)),
        ] else if (resolution.trim().isNotEmpty) ...[
          SelectableText(resolution, style: tt.bodyLarge?.copyWith(height: 1.4)),
          const SizedBox(height: 8),
        ],
        if (macete.trim().isNotEmpty) ...[
          Text('Macete', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          Text(macete, style: tt.bodyMedium),
          const SizedBox(height: 8),
        ],
        if (pegadinha.trim().isNotEmpty) ...[
          Text('Pegadinha', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          Text(pegadinha, style: tt.bodyMedium),
          const SizedBox(height: 8),
        ],
        if (banca.trim().isNotEmpty) ...[
          Text('Intenção da banca', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          Text(banca, style: tt.bodyMedium),
        ],
        if (trailing != null) ...[
          const SizedBox(height: 14),
          trailing!,
        ],
        const SizedBox(height: 16),
        Divider(color: cs.outlineVariant.withOpacity(0.7)),
        const SizedBox(height: 8),
        Text(
          'Fonte',
          style: tt.labelSmall?.copyWith(
            color: cs.onSurface.withOpacity(0.45),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          fonteLine,
          style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.55)),
        ),
        if (onOpenPdf != null && pdfAvailable) ...[
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: onOpenPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
            label: Text(pdfYear != null ? 'Abrir PDF $pdfYear' : 'Abrir PDF'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: cs.onSurface.withOpacity(0.65),
            ),
          ),
        ],
      ],
    );
  }
}
