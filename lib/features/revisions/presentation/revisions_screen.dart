import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/data/theory_reads.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/theory_topic_sheet.dart';
import '../../../core/widgets/ui_kit.dart';

class RevisionsScreen extends ConsumerStatefulWidget {
  const RevisionsScreen({super.key});

  @override
  ConsumerState<RevisionsScreen> createState() => _RevisionsScreenState();
}

class _RevisionsScreenState extends ConsumerState<RevisionsScreen> {
  Map<String, bool> theoryReadByKey = {};
  String? _readsSignature;

  bool _isTheoryRead(String subject, String topic) =>
      theoryReadByKey[theoryReadKey(subject, topic)] == true;

  Future<void> _loadReads(List<dynamic> items) async {
    final pairs = <(String, String)>[];
    for (final raw in items) {
      final item = Map<String, dynamic>.from(raw as Map);
      final s = item['subject']?.toString() ?? '';
      final t = item['topic']?.toString() ?? '';
      if (s.isNotEmpty && t.isNotEmpty) pairs.add((s, t));
    }
    final sig = pairs.map((p) => theoryReadKey(p.$1, p.$2)).join(';');
    if (sig == _readsSignature) return;
    _readsSignature = sig;
    final out = await fetchTheoryReadMap(pairs);
    if (mounted) setState(() => theoryReadByKey = out);
  }

  Future<void> _openTheory(String subject, String topic) async {
    await TheoryTopicSheet.show(
      context,
      subject: subject,
      topic: topic,
      onMarkedRead: () {
        if (mounted) setState(() => theoryReadByKey[theoryReadKey(subject, topic)] = true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(revisionsApiProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => EmptyState(
        title: 'Revisões indisponíveis',
        subtitle: 'Reabra o app e tente de novo.',
        action: FilledButton(
          onPressed: () => ref.read(refreshTickProvider.notifier).state++,
          child: const Text('Tentar de novo'),
        ),
      ),
      data: (items) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadReads(items));
        return ListView(
          children: [
            PageBody(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeader(
                    eyebrow: 'Analisar',
                    title: 'Revisões',
                    subtitle: items.isEmpty
                        ? 'Os erros viram revisões aqui'
                        : '${items.length} assunto(s) agendado(s)',
                    trailing: IconButton(
                      tooltip: 'Atualizar',
                      onPressed: () => ref.read(refreshTickProvider.notifier).state++,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ),
                  if (items.isEmpty)
                    EmptyState(
                      title: 'Nada agendado',
                      subtitle: 'Erre na sessão ou no simulado — as lacunas aparecem aqui.',
                      action: Wrap(
                        spacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          FilledButton(onPressed: () => context.go('/sessao'), child: const Text('Sessão')),
                          FilledButton.tonal(onPressed: () => context.go('/simulados'), child: const Text('Simulados')),
                        ],
                      ),
                    )
                  else
                    for (final raw in items)
                      Builder(
                        builder: (_) {
                          final item = Map<String, dynamic>.from(raw as Map);
                          final subject = item['subject']?.toString() ?? '';
                          final topic = item['topic']?.toString() ?? '';
                          final due = item['next_due']?.toString() ?? '—';
                          final days = item['interval_days'];
                          return PlaylistTile(
                            title: '$subject · $topic',
                            subtitle: 'Próxima: $due${days != null ? ' · a cada ${days}d' : ''}',
                            badge: _isTheoryRead(subject, topic) ? 'Li' : 'revisar',
                            leadingIcon: Icons.replay_rounded,
                            onPlay: () => context.go(
                              '/adaptativo?subject=${Uri.encodeComponent(subject)}'
                              '&topic=${Uri.encodeComponent(topic)}',
                            ),
                            secondary: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Teoria local (PDF/edital)',
                                  icon: Icon(
                                    _isTheoryRead(subject, topic)
                                        ? Icons.menu_book_rounded
                                        : Icons.menu_book_outlined,
                                  ),
                                  onPressed: subject.isEmpty || topic.isEmpty
                                      ? null
                                      : () => _openTheory(subject, topic),
                                ),
                                IconButton(
                                  tooltip: 'Perguntar ao tutor',
                                  icon: const Icon(Icons.psychology_outlined),
                                  onPressed: () => context.go(
                                    '/tutor?subject=${Uri.encodeComponent(subject)}'
                                    '&topic=${Uri.encodeComponent(topic)}',
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Marcar feita',
                                  icon: const Icon(Icons.check_circle_outline),
                                  onPressed: () async {
                                    try {
                                      await apiClient.post(
                                        '/api/revisions/complete'
                                        '?subject=${Uri.encodeComponent(subject)}'
                                        '&topic=${Uri.encodeComponent(topic)}',
                                        {},
                                      );
                                      ref.read(refreshTickProvider.notifier).state++;
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              humanApiError(e, fallback: 'Não deu para marcar a revisão.'),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Marcar recuperada',
                                  icon: const Icon(Icons.flag_outlined),
                                  onPressed: () async {
                                    try {
                                      await apiClient.post('/api/gaps/recover', {
                                        'subject': subject,
                                        'topic': topic,
                                      });
                                      ref.read(refreshTickProvider.notifier).state++;
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Lacuna marcada como recuperada (treino local).',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              humanApiError(e, fallback: 'Não deu para marcar a lacuna.'),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
