import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/media_reinforcement.dart';
import '../../../../core/widgets/ui_kit.dart';

/// Bloco de teoria já limpo pelo backend (theorySections: {title, body}).
class TheoryBlock {
  const TheoryBlock({this.title, required this.body});

  final String? title;
  final String body;

  /// Aceita `theorySections` (mapas) e, como fallback, `theorySnippets` (strings
  /// no formato "Título\ncorpo"). Remove Markdown cru que ainda venha do edital
  /// e descarta blocos repetidos.
  static List<TheoryBlock> fromPlan(Map<String, dynamic>? plan) {
    if (plan == null) return const [];
    final phases = plan['phases'] is Map ? plan['phases'] as Map : const {};
    final rawSections = plan['theorySections'] ?? phases['theorySections'];
    final out = <TheoryBlock>[];
    final seen = <String>{};
    void add(String? title, String body) {
      final clean = cleanMarkdown(body);
      if (clean.isEmpty || !seen.add(clean)) return;
      final t = title == null ? null : cleanMarkdown(title);
      out.add(TheoryBlock(title: (t == null || t.isEmpty) ? null : t, body: clean));
    }

    if (rawSections is List) {
      for (final raw in rawSections) {
        if (raw is Map) {
          add(raw['title']?.toString(), raw['body']?.toString() ?? '');
        }
      }
    }
    if (out.isNotEmpty) return out;
    final rawSnippets = plan['theorySnippets'] ?? phases['theorySnippets'];
    if (rawSnippets is List) {
      for (final raw in rawSnippets) {
        add(null, raw?.toString() ?? '');
      }
    }
    return out;
  }

  /// '## Título' → 'Título', '- item' → '• item', '**x**' → 'x'.
  static String cleanMarkdown(String text) {
    final lines = text
        .split('\n')
        .where((line) => !line.trim().startsWith('<!--'))
        .map((line) {
      var l = line.trim();
      l = l.replaceFirst(RegExp(r'^#{1,6}\s+'), '');
      l = l.replaceFirst(RegExp(r'^[-*+]\s+'), '• ');
      l = l.replaceAllMapped(RegExp(r'(\*\*|__)(.+?)\1'), (m) => m[2] ?? '');
      return l;
    });
    return lines.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }
}

/// Fase de teoria do tópico na sessão guiada.
class SessionTheoryPanel extends StatelessWidget {
  const SessionTheoryPanel({
    super.key,
    required this.blocks,
    required this.subject,
    required this.topic,
  });

  final List<TheoryBlock> blocks;
  final String subject;
  final String topic;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final display = blocks.length > 12 ? blocks.take(12).toList() : blocks;
    final heading = topic.isNotEmpty ? 'Teoria · $topic' : 'Teoria do tópico';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                heading,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
            Text(
              display.isEmpty ? 'Passo 1 de 2' : 'Passo 1 de 2 · ${display.length} blocos',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 0.45),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 4,
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (display.isEmpty)
          QuietEmpty(
            message: 'Sem teoria local para o assunto de hoje. Gere o material do tópico na Biblioteca.',
            action: FilledButton.tonal(
              onPressed: () => context.go('/biblioteca'),
              child: const Text('Abrir Biblioteca'),
            ),
          )
        else
          StaggeredFadeIn(
            key: const ValueKey('theory_snippets'),
            children: [
              for (var si = 0; si < display.length; si++)
                SurfacePanel(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${si + 1} de ${display.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                      if (display[si].title != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          display[si].title!,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: SelectableText(
                          display[si].body,
                          style: const TextStyle(height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        const Text('Leia os blocos acima (~20 min) e avance para as questões.'),
        if (subject.isNotEmpty || topic.isNotEmpty)
          MediaReinforcement(subject: subject, topic: topic, compact: true),
      ],
    );
  }
}

/// Fase de revisão com flashcards na sessão guiada.
class SessionRevisionsPanel extends StatelessWidget {
  const SessionRevisionsPanel({
    super.key,
    required this.sessionCards,
    required this.cardIndex,
    required this.cardsDone,
    required this.cardFlipped,
    required this.revisionQueueLength,
    this.cardReviewError,
    required this.onToggleFlip,
    required this.onReveal,
    required this.onRemembered,
    required this.onForgot,
    required this.onLoadRevisions,
    required this.onDismissReviewError,
  });

  final List<Map<String, dynamic>> sessionCards;
  final int cardIndex;
  final int cardsDone;
  final bool cardFlipped;
  final int revisionQueueLength;
  final String? cardReviewError;
  final VoidCallback onToggleFlip;
  final VoidCallback onReveal;
  final VoidCallback onRemembered;
  final VoidCallback onForgot;
  final VoidCallback onLoadRevisions;
  final VoidCallback onDismissReviewError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 24),
        const SectionLabel('Revisão prática'),
        if (sessionCards.isEmpty)
          QuietEmpty(
            message:
                'Nenhum cartão para revisar agora ($revisionQueueLength '
                'assunto(s) na fila). Carregue revisões para praticar com questões.',
            action: FilledButton.tonal(
              onPressed: onLoadRevisions,
              child: const Text('Carregar revisões'),
            ),
          )
        else ...[
          Text('Cartão ${cardIndex + 1}/${sessionCards.length} · feitos $cardsDone'),
          const SizedBox(height: 8),
          SurfacePanel(
            padding: EdgeInsets.zero,
            child: ListTile(
              title: Text(sessionCards[cardIndex]['front']?.toString() ?? ''),
              subtitle: cardFlipped
                  ? Text(sessionCards[cardIndex]['back']?.toString() ?? '')
                  : const Text('Toque para revelar'),
              onTap: onToggleFlip,
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.tonal(onPressed: onReveal, child: const Text('Revelar (Space)')),
              TapScale(
                child: FilledButton(onPressed: onRemembered, child: const Text('Lembrei (L)')),
              ),
              OutlinedButton(onPressed: onForgot, child: const Text('Esqueci (E)')),
            ],
          ),
          if (cardReviewError != null) ...[
            const SizedBox(height: 8),
            QuietEmpty(
              message: cardReviewError!,
              action: TextButton(
                onPressed: onDismissReviewError,
                child: const Text('Tentar de novo'),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
