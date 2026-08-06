import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/api_client.dart';
import '../data/api_error.dart';
import 'ui_kit.dart';

/// Bottom sheet F2: materiais locais + mark-read + empty honesto.
Future<void> openTheoryReadSheet(
  BuildContext context, {
  required String subject,
  required String topic,
  String? trainSessionPath,
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
    final sessionPath = trainSessionPath ??
        '/sessao?examBoard=UEMA_PAES&preferNatureza=1'
            '&subject=${Uri.encodeComponent(subject)}'
            '&topic=${Uri.encodeComponent(topic)}';

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
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                    if (isRead)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Marcado como li${readMap['at'] != null ? ' · ${readMap['at']}' : ''}',
                          style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                                color: Theme.of(ctx).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    if (note != null && note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(note, style: Theme.of(ctx).textTheme.bodySmall),
                    ],
                    if (items.isEmpty) ...[
                      const SizedBox(height: 16),
                      QuietEmpty(
                        message: note ?? 'Sem material local para este tópico.',
                        action: TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.go('/biblioteca');
                          },
                          child: const Text('Biblioteca'),
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
                                          await apiClient.post('/api/library/open-path', {'path': path});
                                        } catch (e) {
                                          try {
                                            await apiClient.post(
                                              '/api/library/open-folder',
                                              {'folder': it['folder'] ?? 'edital'},
                                            );
                                          } catch (e2) {
                                            if (ctx.mounted) {
                                              ScaffoldMessenger.of(ctx).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    humanApiError(
                                                      e2,
                                                      fallback: 'Não deu para abrir o material.',
                                                    ),
                                                  ),
                                                ),
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
                      Text('Leituras de reforço', style: Theme.of(ctx).textTheme.titleSmall),
                      if (artDisclaimer != null)
                        Text(artDisclaimer, style: Theme.of(ctx).textTheme.bodySmall),
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton(
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
                          child: Text(isRead ? 'Li de novo' : 'Marquei como li'),
                        ),
                        FilledButton.tonal(
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.go(sessionPath);
                          },
                          child: const Text('Treinar tópico'),
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
