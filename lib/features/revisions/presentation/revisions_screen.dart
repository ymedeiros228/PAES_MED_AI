import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/ui_kit.dart';

class RevisionsScreen extends ConsumerWidget {
  const RevisionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                            badge: 'revisar',
                            leadingIcon: Icons.replay_rounded,
                            onPlay: () => context.go(
                              '/adaptativo?subject=${Uri.encodeComponent(subject)}'
                              '&topic=${Uri.encodeComponent(topic)}',
                            ),
                            secondary: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Marcar feita',
                                  icon: const Icon(Icons.check_circle_outline),
                                  onPressed: () async {
                                    await apiClient.post(
                                      '/api/revisions/complete'
                                      '?subject=${Uri.encodeComponent(subject)}'
                                      '&topic=${Uri.encodeComponent(topic)}',
                                      {},
                                    );
                                    ref.read(refreshTickProvider.notifier).state++;
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
