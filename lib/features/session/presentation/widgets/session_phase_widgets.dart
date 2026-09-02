import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/media_reinforcement.dart';
import '../../../../core/widgets/ui_kit.dart';

/// Fase de teoria do edital na sessão guiada.
class SessionTheoryPanel extends StatelessWidget {
  const SessionTheoryPanel({
    super.key,
    required this.snippets,
    required this.subject,
    required this.topic,
  });

  final List<String> snippets;
  final String subject;
  final String topic;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final display = snippets.length > 10 ? snippets.take(10).toList() : snippets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 24),
        Row(
          children: [
            Text(
              'Teoria do edital',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              snippets.isEmpty ? 'Passo 1 de 2' : 'Passo 1 de 2 · ler',
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
        if (snippets.isEmpty)
          QuietEmpty(
            message: 'Sem teoria do edital para o assunto de hoje. Atualize o edital na Biblioteca.',
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
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: SelectableText(display[si]),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        const Text('Leia os trechos acima (~20 min) e avance para as questões.'),
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
