import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/api_client.dart';
import '../data/api_error.dart';
import 'study_material_pack.dart';
import 'ui_kit.dart';

String adaptiveTrainPath(String subject, String topic) =>
    '/adaptativo?subject=${Uri.encodeComponent(subject)}'
    '&topic=${Uri.encodeComponent(topic)}';

/// Bottom sheet F2: abre na hora (lista/fila não travam no await de materials).
Future<void> openTheoryReadSheet(
  BuildContext context, {
  required String subject,
  required String topic,
  String? trainPath,
  String? whyThisMatters,
  bool fromMistake = false,
}) async {
  final nextTrainPath = trainPath ?? adaptiveTrainPath(subject, topic);
  final why = (whyThisMatters ?? '').trim();
  // Dispara fetch em paralelo com o sheet (não bloqueia paint da lista).
  final matFuture = apiClient.get(
    '/api/library/materials',
    {'subject': subject, 'topic': topic},
  );
  final readFuture = apiClient.get(
    '/api/study/reads',
    {'subject': subject, 'topic': topic},
  );

  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return FutureBuilder<List<dynamic>>(
        future: Future.wait([matFuture, readFuture]),
        builder: (ctx, snap) {
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: QuietEmpty(
                message: humanApiError(snap.error!, fallback: 'Não deu para abrir o material.'),
                action: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fechar'),
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: SoftLoader(label: 'Carregando teoria…', compact: true),
            );
          }
          final matRaw = snap.data![0];
          final readRaw = snap.data![1];
          final map = Map<String, dynamic>.from(matRaw as Map);
          final readMap = Map<String, dynamic>.from(readRaw as Map);
          final items = (map['items'] as List? ?? []).whereType<Map>().toList();
          final note = map['note']?.toString();
          var isRead = readMap['read'] == true;

          return StatefulBuilder(
            builder: (ctx, setModal) {
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.55,
                minChildSize: 0.35,
                maxChildSize: 0.9,
                builder: (_, scroll) {
                  return ListView(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      Text(
                        'Teoria · $subject · $topic',
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                      if (fromMistake || why.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SurfacePanel(
                          padding: const EdgeInsets.all(12),
                          soft: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fromMistake ? 'Por que isso importa agora' : 'Por que isso importa',
                                style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                why.isNotEmpty
                                    ? why
                                    : 'Erro recente neste tópico — firme o conceito com material local '
                                        'antes de treinar em sequência (treino local, sem inventar oficial).',
                                style: Theme.of(ctx).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Column(
                          key: ValueKey<bool>(isRead),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isRead ? 'Passo 2 de 2' : 'Passo 1 de 2',
                                  style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const Spacer(),
                                Icon(
                                  isRead ? Icons.psychology_rounded : Icons.menu_book_outlined,
                                  size: 16,
                                  color: Theme.of(ctx).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isRead ? 'Treinar' : 'Ler',
                                  style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                                        color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.62),
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: isRead ? 1.0 : 0.5,
                                minHeight: 4,
                                backgroundColor: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isRead)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: Theme.of(ctx).colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  readMap['at'] != null
                                      ? 'Marcado como lido · ${readMap['at']}'
                                      : 'Marcado como lido',
                                  style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                                        color: Theme.of(ctx).colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (note != null && note.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(note, style: Theme.of(ctx).textTheme.bodySmall),
                      ],
                      const SizedBox(height: 8),
                      StudyMaterialPack(subject: subject, topic: topic),
                      if (items.isEmpty) ...[
                        const SizedBox(height: 8),
                        QuietEmpty(
                          message:
                              'Sem arquivo local da banca neste tópico — use as abas Vídeos / Leituras / Buscar acima.',
                          action: FilledButton.tonal(
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.go('/biblioteca');
                            },
                            child: const Text('Biblioteca'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        isRead
                            ? (fromMistake
                                ? 'Passo 2 · Conceito revisado — treine com foco no tópico fraco.'
                                : 'Passo 2 · Teoria lida — treine o tópico agora.')
                            : (fromMistake
                                ? 'Passo 1 · Errou neste tema: leia o material e marque lido antes de bombear Q.'
                                : 'Passo 1 · Escolha um material, leia e marque como lido. Depois treine.'),
                        style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                              color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.72),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (isRead)
                            AnimatedScale(
                              scale: isRead ? 1.0 : 0.94,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutBack,
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  context.go(nextTrainPath);
                                },
                                icon: const Icon(Icons.psychology_rounded, size: 18),
                                label: const Text('Treinar agora'),
                              ),
                            )
                          else
                            AnimatedScale(
                              scale: 1.0,
                              duration: const Duration(milliseconds: 220),
                              child: FilledButton(
                                onPressed: () async {
                                  try {
                                    final r = await apiClient.post('/api/study/mark-read', {
                                      'subject': subject,
                                      'topic': topic,
                                    });
                                    final m = Map<String, dynamic>.from(r as Map);
                                    setModal(() {
                                      isRead = true;
                                      readMap['at'] = m['at'];
                                      readMap['read'] = true;
                                    });
                                    HapticFeedback.lightImpact();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Marcado como lido. Próximo: treinar o tópico.'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            humanApiError(e, fallback: 'Não deu para marcar como lido.'),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Marquei como li'),
                              ),
                            ),
                          if (isRead)
                            OutlinedButton(
                              onPressed: () async {
                                try {
                                  await apiClient.post('/api/study/mark-read', {
                                    'subject': subject,
                                    'topic': topic,
                                  });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Marcado como li (local).')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          humanApiError(e, fallback: 'Não deu para marcar como lido.'),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Li de novo'),
                            )
                          else
                            OutlinedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                context.go(nextTrainPath);
                              },
                              child: Text(fromMistake ? 'Treinar mesmo assim' : 'Pular para treino'),
                            ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.go('/biblioteca');
                            },
                            child: const Text('Biblioteca'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      );
    },
  );
}
