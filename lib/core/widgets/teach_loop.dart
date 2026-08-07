import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'media_reinforcement.dart';
import 'theory_read_sheet.dart';
import 'ui_kit.dart';

/// Bloco didático pós-resposta / coach (Ciclo JC) — ensina de verdade, sem inventar oficial.
class DidacticTeachBlock extends StatelessWidget {
  const DidacticTeachBlock({
    required this.teach,
    this.compact = false,
    this.showMedia = true,
    super.key,
  });

  final Map<String, dynamic> teach;
  final bool compact;
  final bool showMedia;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final correct = teach['correct'] == true;
    final wrong = teach['correct'] == false;
    final force = teach['forceReview'] == true || wrong;
    final concept = teach['concept']?.toString() ?? '';
    final why = teach['whyThisMatters']?.toString() ?? '';
    final points = (teach['reviewPoints'] as List? ?? [])
        .map((e) => e.toString())
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final gab = teach['gabarito'] is Map
        ? Map<String, dynamic>.from(teach['gabarito'] as Map)
        : <String, dynamic>{};
    final gabStatus = gab['status']?.toString() ?? '';
    final gabMsg = gab['message']?.toString() ?? '';
    final subj = teach['subject']?.toString() ?? '';
    final top = teach['topic']?.toString() ?? '';
    final next = (teach['nextSteps'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final disclaimer = teach['disclaimer']?.toString();

    Future<void> openTheory() async {
      if (subj.isEmpty) return;
      await openTheoryReadSheet(
        context,
        subject: subj,
        topic: top,
        whyThisMatters: why.isNotEmpty
            ? why
            : (wrong
                ? 'Você errou neste tópico — leia o conceito antes de treinar em sequência.'
                : null),
        fromMistake: wrong,
        trainPath: subj.isNotEmpty
            ? adaptiveTrainPath(subj, top)
            : null,
      );
    }

    void goStep(Map<String, dynamic> step) {
      final action = step['action']?.toString() ?? '';
      final route = step['route']?.toString();
      if (action == 'open_theory') {
        openTheory();
        return;
      }
      if (route != null && route.isNotEmpty) {
        context.go(route);
      }
    }

    return SurfacePanel(
      margin: const EdgeInsets.only(bottom: 12),
      color: force
          ? cs.tertiaryContainer.withOpacity(0.45)
          : cs.primaryContainer.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                force
                    ? Icons.school_outlined
                    : correct
                        ? Icons.lightbulb_outline
                        : Icons.menu_book_outlined,
                size: 20,
                color: cs.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  force ? 'Revisar conceito' : 'O que isso ensina',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (teach['label'] != null)
                Text(
                  teach['label']!.toString(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                ),
            ],
          ),
          if (why.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              why,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.75),
                  ),
            ),
          ],
          if (gabMsg.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  gabStatus == 'unavailable'
                      ? Icons.info_outline
                      : Icons.check_box_outlined,
                  size: 16,
                  color: gabStatus == 'unavailable' ? cs.tertiary : cs.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    gabMsg,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          if (concept.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Conceito',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            SelectableText(concept),
          ],
          if (points.isNotEmpty && !compact) ...[
            const SizedBox(height: 10),
            Text(
              'O que revisar',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            for (final p in points.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('· $p', style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
          if (showMedia && subj.isNotEmpty) ...[
            const SizedBox(height: 8),
            MediaReinforcement(
              subject: subj,
              topic: top,
              compact: true,
              heading: force ? 'Materiais antes da próxima Q' : 'Materiais do tópico',
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (force && subj.isNotEmpty)
                FilledButton.icon(
                  onPressed: openTheory,
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: const Text('Revisar conceito'),
                ),
              for (final step in next.take(3))
                if (step['action']?.toString() != 'open_theory' || !force)
                  force && step['id']?.toString() == 'same_topic'
                      ? OutlinedButton(
                          onPressed: () => goStep(step),
                          child: Text(step['label']?.toString() ?? 'Próximo'),
                        )
                      : FilledButton.tonal(
                          onPressed: () => goStep(step),
                          child: Text(step['label']?.toString() ?? 'Próximo'),
                        ),
            ],
          ),
          if (disclaimer != null && disclaimer.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              disclaimer,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.48),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Card do coach no Hoje — uma ação primária clara.
class StudyCoachCard extends StatelessWidget {
  const StudyCoachCard({
    required this.coach,
    this.onRetry,
    super.key,
  });

  final Map<String, dynamic> coach;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = coach['primary'] is Map
        ? Map<String, dynamic>.from(coach['primary'] as Map)
        : <String, dynamic>{};
    final line = coach['line']?.toString() ?? 'O que estudar agora';
    final headline = coach['headline']?.toString() ?? 'Coach de estudo';
    final material = coach['materialLane'] is Map
        ? Map<String, dynamic>.from(coach['materialLane'] as Map)
        : <String, dynamic>{};
    final revision = coach['revisionLane'] is Map
        ? Map<String, dynamic>.from(coach['revisionLane'] as Map)
        : null;
    final weak = (coach['weakTopics'] as List? ?? []).take(2).toList();
    final disclaimer = coach['disclaimer']?.toString();
    final route = primary['route']?.toString() ?? '/sessao';

    return SurfacePanel(
      margin: const EdgeInsets.only(bottom: 16),
      soft: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_outlined, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  headline,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (onRetry != null)
                IconButton(
                  tooltip: 'Atualizar coach',
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(line, style: Theme.of(context).textTheme.bodyMedium),
          if (weak.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final raw in weak)
                  if (raw is Map)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        '${raw['subject']} · ${raw['topic']}'
                        '${raw['wrongRate'] != null ? ' · ${raw['wrongRate']}% err' : ''}',
                      ),
                    ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => context.go(route),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(primary['label']?.toString() ?? 'Estudar agora'),
          ),
          if (primary['why'] != null) ...[
            const SizedBox(height: 6),
            Text(
              primary['why'].toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.65),
                  ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (material['route'] != null)
                TextButton(
                  onPressed: () => context.go(material['route'].toString()),
                  child: Text(material['label']?.toString() ?? 'Materiais'),
                ),
              if (revision != null && revision['route'] != null)
                TextButton(
                  onPressed: () => context.go(revision['route'].toString()),
                  child: Text(revision['label']?.toString() ?? 'Revisão'),
                ),
            ],
          ),
          if (disclaimer != null) ...[
            const SizedBox(height: 6),
            Text(
              disclaimer,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.45),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
