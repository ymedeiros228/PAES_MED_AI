import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/ui_kit.dart';
import 'session_widgets.dart';

/// Painel de encerramento da sessão guiada — resumo, gaps e próximos passos.
class SessionEndPanel extends StatelessWidget {
  const SessionEndPanel({
    super.key,
    required this.correctCount,
    required this.totalAnswered,
    required this.gaps,
    required this.subject,
    required this.topic,
    required this.onCloseStudyDay,
  });

  final int correctCount;
  final int totalAnswered;
  final List<Map<String, String>> gaps;
  final String subject;
  final String topic;
  final VoidCallback onCloseStudyDay;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final wrong = (totalAnswered - correctCount).clamp(0, totalAnswered);
    final pct = totalAnswered > 0 ? (correctCount / totalAnswered * 100).round() : 0;

    return SurfacePanel(
      margin: const EdgeInsets.only(bottom: 16),
      color: cs.primaryContainer.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pct >= 70 ? 'Bom trabalho!' : 'Bloco encerrado',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              if (totalAnswered > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            totalAnswered > 0
                ? '$correctCount acerto${correctCount == 1 ? '' : 's'} · $wrong erro${wrong == 1 ? '' : 's'} · $totalAnswered questão${totalAnswered == 1 ? '' : 'ês'}'
                : 'Sessão encerrada.',
            style: TextStyle(
              fontSize: 13,
              color: cs.onPrimaryContainer.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 14),
          SessionInsightBanner(
            correctCount: correctCount,
            wrongCount: wrong,
            total: totalAnswered,
            subject: subject,
            topic: topic,
          ),
          if (gaps.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Revisar agora',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in gaps.take(3))
                  ActionChip(
                    label: Text('${g['subject']} · ${g['topic']}'),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      final s = Uri.encodeComponent(g['subject'] ?? '');
                      final t = Uri.encodeComponent(g['topic'] ?? '');
                      context.go('/adaptativo?subject=$s&topic=$t');
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          TapScale(
            child: FilledButton.icon(
              onPressed: () => context.go('/fila'),
              icon: const Icon(Icons.playlist_play_rounded),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              label: const Text('Continuar na Fila', style: TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: onCloseStudyDay,
                child: const Text('Encerrar dia'),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () => context.go('/inicio'),
                child: const Text('Voltar ao Início'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
