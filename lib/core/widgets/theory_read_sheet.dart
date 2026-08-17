import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/api_client.dart';
import '../data/api_error.dart';
import '../theme/app_theme.dart';
import 'ui_kit.dart';

String adaptiveTrainPath(String subject, String topic) =>
    '/adaptativo?subject=${Uri.encodeComponent(subject)}'
    '&topic=${Uri.encodeComponent(topic)}';

/// Bottom sheet F2: materiais locais + mark-read + treino adaptativo.
Future<void> openTheoryReadSheet(
  BuildContext context, {
  required String subject,
  required String topic,
  String? trainPath,
}) async {
  try {
    final matFuture = apiClient.get(
      '/api/library/materials',
      {'subject': subject, 'topic': topic},
    );
    final readFuture = apiClient.get(
      '/api/study/reads',
      {'subject': subject, 'topic': topic},
    );
    final artFuture = apiClient.get(
      '/api/media/articles',
      {'subject': subject, 'topic': topic},
    );
    final matRaw = await matFuture;
    final readRaw = await readFuture;
    final artRaw = await artFuture;
    if (!context.mounted) return;
    final map = Map<String, dynamic>.from(matRaw as Map);
    final readMap = Map<String, dynamic>.from(readRaw as Map);
    final artMap = Map<String, dynamic>.from(artRaw as Map);
    final items = (map['items'] as List? ?? []).whereType<Map>().toList();
    final articles = (artMap['items'] as List? ?? []).whereType<Map>().toList();
    final note = map['note']?.toString();
    final artDisclaimer = artMap['disclaimer']?.toString();
    var isRead = readMap['read'] == true;
    final nextTrainPath = trainPath ?? adaptiveTrainPath(subject, topic);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
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
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(ctx).colorScheme.onSurface),
                    ),
                    const SizedBox(height: 8),
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
                                style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w800, color: Theme.of(ctx).colorScheme.onSurface),
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
                                style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.62)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
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
                        child: AnimatedScale(
                          scale: isRead ? 1.0 : 0.85,
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutBack,
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
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(ctx).colorScheme.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (note != null && note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SelectableText(note, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Theme.of(ctx).colorScheme.onSurface)),
                    ],
                    if (items.isEmpty) ...[
                      const SizedBox(height: 16),
                      QuietEmpty(
                        message: note ??
                            'Sem material local para $subject · $topic. '
                            'O app não inventa edital — coloque fontes nas pastas do PC.',
                        action: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            FilledButton.tonal(
                              onPressed: () async {
                                HapticFeedback.selectionClick();
                                try {
                                  await apiClient.post('/api/library/open-folder', {
                                    'folder': 'edital',
                                  });
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          humanApiError(e, fallback: 'Não abriu a pasta edital.'),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Pasta edital'),
                            ),
                            OutlinedButton(
                              onPressed: () async {
                                HapticFeedback.selectionClick();
                                try {
                                  await apiClient.post('/api/library/open-folder', {
                                    'folder': 'provas',
                                  });
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          humanApiError(e, fallback: 'Não abriu a pasta provas.'),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Pasta provas'),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                context.go('/biblioteca');
                              },
                              child: const Text('Biblioteca'),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      for (final raw in items.take(8))
                        Builder(
                          builder: (_) {
                            final it = Map<String, dynamic>.from(raw);
                            final path = it['path']?.toString() ?? '';
                            final snippet = it['snippet']?.toString() ?? '';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(it['label']?.toString() ?? it['kind']?.toString() ?? 'item'),
                              subtitle: snippet.isNotEmpty
                                  ? Text(
                                      snippet.length > 200 ? '${snippet.substring(0, 200)}…' : snippet,
                                    )
                                  : Text(path.isNotEmpty ? path : (it['kind']?.toString() ?? '')),
                              trailing: path.isNotEmpty
                                  ? IconButton(
                                      tooltip: 'Abrir',
                                      icon: const Icon(Icons.open_in_new_rounded),
                                      onPressed: () async {
                                        try {
                                          await apiClient.openPath(path);
                                          if (ctx.mounted) {
                                            showOpenPathSnackBar(
                                              ctx,
                                              message: 'Abrindo ${it['label'] ?? 'material'}',
                                            );
                                          }
                                        } catch (e) {
                                          final err = humanOpenPathError(
                                            e,
                                            label: it['label']?.toString() ?? 'Material',
                                          );
                                          try {
                                            await apiClient.post(
                                              '/api/library/open-folder',
                                              {'folder': it['folder'] ?? 'edital'},
                                            );
                                            if (ctx.mounted) {
                                              showOpenPathSnackBar(
                                                ctx,
                                                message: '$err · pasta aberta.',
                                                isError: true,
                                              );
                                            }
                                          } catch (e2) {
                                            if (ctx.mounted) {
                                              showOpenPathSnackBar(
                                                ctx,
                                                message: humanOpenPathError(
                                                  e2,
                                                  label: it['label']?.toString() ?? 'Material',
                                                ),
                                                isError: true,
                                              );
                                            }
                                          }
                                        }
                                      },
                                    )
                                  : null,
                            );
                          },
                        ),
                    ],
                    if (articles.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Leituras de reforço',
                        style: TextStyle(fontFamily: 'Poppins', 
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(ctx).colorScheme.onSurface,
                        ),
                      ),
                      if (artDisclaimer != null)
                        SelectableText(
                          artDisclaimer,
                          style: TextStyle(fontFamily: 'Inter', 
                            fontSize: 13,
                            color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      for (final raw in articles.take(5))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(raw['title']?.toString() ?? 'Leitura'),
                          subtitle: Text(raw['source']?.toString() ?? raw['channel']?.toString() ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Marquei como lido',
                                icon: const Icon(Icons.check_circle_outline, size: 20),
                                onPressed: () async {
                                  final u = raw['url']?.toString() ?? '';
                                  if (u.isEmpty) return;
                                  try {
                                    await apiClient.post('/api/media/mark-read', {
                                      'url': u,
                                      'subject': subject,
                                      'topic': topic,
                                      'title': raw['title']?.toString(),
                                    });
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Marcado como lido (local).')),
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
                              ),
                              const Icon(Icons.open_in_new_rounded, size: 18),
                            ],
                          ),
                          onTap: () async {
                            final u = raw['url']?.toString() ?? '';
                            if (u.isEmpty) return;
                            try {
                              await apiClient.post('/api/media/open', {
                                'url': u,
                                'kind': 'article',
                                'subject': subject,
                                'topic': topic,
                                'title': raw['title']?.toString(),
                              });
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      humanApiError(e, fallback: 'Não deu para abrir o material.'),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      isRead
                          ? 'Passo 2 · Teoria lida — treine o tópico agora.'
                          : 'Passo 1 · Leia o material e marque como lido. Depois treine.',
                      style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(ctx).colorScheme.onSurface.f72,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (isRead)
                          FilledButton.icon(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              Navigator.pop(ctx);
                              context.go(nextTrainPath);
                            },
                            icon: const Icon(Icons.psychology_rounded, size: 18),
                            label: const Text('Treinar agora'),
                          )
                        else
                          FilledButton(
                            onPressed: () async {
                              HapticFeedback.selectionClick();
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
                            child: const Text('Pular para treino'),
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
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para abrir a leitura.'))),
    );
  }
}
