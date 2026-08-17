import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ui_kit.dart';

/// Debrief honesto: 4 eixos se `real`; senão rascunho (Ciclo AB/AF).
class ResolutionDebrief extends StatelessWidget {
  const ResolutionDebrief({
    super.key,
    required this.question,
    this.professor,
    this.trailing,
  });

  final Map<String, dynamic> question;
  final Map<String, dynamic>? professor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final prof = professor ?? {};
    final quality = (prof['resolutionQuality'] ?? question['resolutionQuality'] ?? 'template').toString();
    final label = (prof['studentResolutionLabel'] ?? question['studentResolutionLabel'] ?? '').toString();
    final axesRaw = prof['resolutionAxes'] ?? question['resolutionAxes'];
    final axes = axesRaw is Map ? Map<String, dynamic>.from(axesRaw) : <String, dynamic>{};
    final resolution = (prof['resolution'] ?? question['resolution'] ?? '').toString();
    final macete = (prof['macete'] ?? question['macete'] ?? '').toString();
    final pegadinha = (prof['pegadinha'] ?? question['pegadinha'] ?? '').toString();
    final banca = (prof['bancaIntent'] ?? question['bancaIntent'] ?? '').toString();
    final isReal = quality == 'real';
    final cs = Theme.of(context).colorScheme;

    Widget axisBlock(String title, String? body) {
      final t = (body ?? '').trim();
      if (t.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontFamily: 'Poppins', 
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              t,
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 14,
                height: 1.6,
                color: cs.onPrimaryContainer,
              ),
            ),
          ],
        ),
      );
    }

    return SurfacePanel(
      color: cs.primaryContainer.f55,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isReal ? 'Explicação (4 eixos)' : 'Rascunho / modelo',
                  style: TextStyle(fontFamily: 'Poppins', 
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              if (label.isNotEmpty || isReal)
                Chip(
                  label: Text(
                    isReal
                        ? 'Explicação completa'
                        : (label == 'rascunho' ? 'Rascunho didático' : 'Modelo de apoio'),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
          Builder(
            builder: (context) {
              final board = (prof['examBoard'] ?? question['examBoard'] ?? 'TREINO').toString().toUpperCase();
              final similar = prof['similarityOf'] ?? question['similarityOf'];
              final blabel = board == 'UEMA_PAES'
                  ? 'Oficial PAES-UEMA'
                  : board == 'OUTRA'
                      ? 'Outra banca (reforço — não oficial UEMA)'
                      : 'Treino rotulado (não oficial UEMA)';
              return Text(
                similar != null ? '$blabel · similar a $similar' : blabel,
                style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: board == 'UEMA_PAES' ? cs.primary : cs.tertiary,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          if (!isReal)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Isto não é texto oficial da banca nem aula fechada — só apoio didático local.',
                style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 13,
                  color: cs.onPrimaryContainer.withOpacity(0.7),
                ),
              ),
            ),
          if (isReal) ...[
            axisBlock('Comando', axes['comando']?.toString()),
            axisBlock('Conceito', axes['conceito']?.toString()),
            axisBlock('Gabarito', axes['gabarito']?.toString()),
            axisBlock('Distrator', axes['distrator']?.toString()),
            if (!axes.values.any((v) => (v?.toString() ?? '').trim().isNotEmpty) &&
                resolution.trim().isNotEmpty)
              SelectableText(
                resolution,
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.6),
              ),
          ] else if (resolution.trim().isNotEmpty) ...[
            Text(
              'Texto',
              style: TextStyle(fontFamily: 'Poppins', 
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              resolution,
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 12),
          ],
          if (macete.trim().isNotEmpty) ...[
            Text(
              'Macete',
              style: TextStyle(fontFamily: 'Poppins', 
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              macete,
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 12),
          ],
          if (pegadinha.trim().isNotEmpty) ...[
            Text(
              'Pegadinha',
              style: TextStyle(fontFamily: 'Poppins', 
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              pegadinha,
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 12),
          ],
          if (banca.trim().isNotEmpty) ...[
            Text(
              'Intenção da banca',
              style: TextStyle(fontFamily: 'Poppins', 
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              banca,
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.6),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(height: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}
