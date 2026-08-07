import 'package:flutter/material.dart';

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
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            SelectableText(t),
          ],
        ),
      );
    }

    return Card(
      color: cs.primaryContainer.withOpacity(0.55),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isReal ? 'Explicação (4 eixos)' : 'Rascunho / modelo',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: board == 'UEMA_PAES' ? cs.primary : cs.tertiary,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            if (!isReal)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Isto não é texto oficial da banca nem aula fechada — só apoio didático local.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (isReal) ...[
              axisBlock('Comando', axes['comando']?.toString()),
              axisBlock('Conceito', axes['conceito']?.toString()),
              axisBlock('Gabarito', axes['gabarito']?.toString()),
              axisBlock('Distrator', axes['distrator']?.toString()),
              if (!axes.values.any((v) => (v?.toString() ?? '').trim().isNotEmpty) &&
                  resolution.trim().isNotEmpty)
                SelectableText(resolution),
              if (!axes.values.any((v) => (v?.toString() ?? '').trim().isNotEmpty) &&
                  resolution.trim().isEmpty)
                Text(
                  'Gabarito oficial não disponível neste item. Revise o conceito do tópico '
                  'com materiais locais (vídeo/PDF/busca) — a plataforma não inventa a chave da banca.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ] else if (resolution.trim().isNotEmpty) ...[
              const Text('Texto', style: TextStyle(fontWeight: FontWeight.w700)),
              SelectableText(resolution),
              const SizedBox(height: 8),
            ] else ...[
              Text(
                'Sem resolução guardada — use o bloco «O que isso ensina» e o pack de materiais do tópico '
                '(treino local; não inventamos gabarito oficial).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
            ],
            if (macete.trim().isNotEmpty) ...[
              const Text('Macete', style: TextStyle(fontWeight: FontWeight.w700)),
              Text(macete),
              const SizedBox(height: 8),
            ],
            if (pegadinha.trim().isNotEmpty) ...[
              const Text('Pegadinha', style: TextStyle(fontWeight: FontWeight.w700)),
              Text(pegadinha),
              const SizedBox(height: 8),
            ],
            if (banca.trim().isNotEmpty) ...[
              const Text('Intenção da banca', style: TextStyle(fontWeight: FontWeight.w700)),
              Text(banca),
            ],
            if (trailing != null) ...[
              const SizedBox(height: 10),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
