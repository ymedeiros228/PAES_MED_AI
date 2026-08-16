import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/ux_copy.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/ui_kit.dart';

class RevisionsScreen extends ConsumerStatefulWidget {
  const RevisionsScreen({super.key});

  @override
  ConsumerState<RevisionsScreen> createState() => _RevisionsScreenState();
}

class _RevisionsScreenState extends ConsumerState<RevisionsScreen> {
  int selected = 0;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _openItem(int i) {
    if (i < 0 || i >= _items.length) return;
    final item = _items[i];
    final subject = item['subject']?.toString() ?? '';
    final topic = item['topic']?.toString() ?? '';
    if (subject.isEmpty && topic.isEmpty) return;
    context.go(
      '/adaptativo?subject=${Uri.encodeComponent(subject)}&topic=${Uri.encodeComponent(topic)}',
    );
  }

  void _moveSelection(int delta) {
    if (_items.isEmpty) return;
    setState(() => selected = (selected + delta).clamp(0, _items.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(revisionsApiProvider);
    return async.when(
        loading: () => const SkeletonList(count: 5, lines: 2),
        error: (e, _) => EmptyState(
          title: 'Revisões indisponíveis',
          subtitle: humanApiError(e, fallback: 'Reabra o app e tente de novo.'),
          action: Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilledButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(refreshTickProvider.notifier).state++;
                },
                child: const Text('Tentar de novo'),
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.go('/sessao');
                },
                child: const Text('Sessão'),
              ),
            ],
          ),
        ),
        data: (items) {
          _items = [for (final raw in items) Map<String, dynamic>.from(raw as Map)];
          if (selected >= _items.length && _items.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => selected = _items.length - 1);
            });
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              PageBody(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PageHeader(
                      eyebrow: 'Analisar',
                      title: 'Revisões',
                      subtitle: _items.isEmpty
                          ? 'Revise os tópicos que você errou'
                          : '${_items.length} assunto(s) para reforço',
                      trailing: IconButton(
                        tooltip: 'Atualizar',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          ref.read(refreshTickProvider.notifier).state++;
                        },
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ),
                    if (_items.isEmpty)
                      EmptyState(
                        title: 'Nada agendado',
                        subtitle: 'Erre na sessão ou no simulado — os tópicos para revisar aparecem aqui.',
                        action: Wrap(
                          spacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            FilledButton(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                context.go('/sessao');
                              },
                              child: const Text('Sessão'),
                            ),
                            FilledButton.tonal(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                context.go('/simulados');
                              },
                              child: const Text('Simulados'),
                            ),
                          ],
                        ),
                      )
                    else
                      StaggeredFadeIn(
                        itemDelay: const Duration(milliseconds: 70),
                        children: [
                          for (var i = 0; i < _items.length; i++)
                            Builder(
                              builder: (_) {
                                final item = _items[i];
                                final subject = item['subject']?.toString() ?? '';
                                final topic = item['topic']?.toString() ?? '';
                                final due = humanDueLabel(item['next_due']?.toString());
                                final days = item['interval_days'];
                                return PlaylistTile(
                                  title: '$subject · $topic',
                                  subtitle: 'Próxima: $due${days != null ? ' · a cada $days dias' : ''}',
                                  badge: 'revisar',
                                  leadingIcon: Icons.replay_rounded,
                                  active: i == selected,
                                  onPlay: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => selected = i);
                                    _openItem(i);
                                  },
                                  secondary: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Marcar feita',
                                    icon: const Icon(Icons.check_circle_outline),
                                    onPressed: () async {
                                      HapticFeedback.lightImpact();
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
                                        HapticFeedback.mediumImpact();
                                        await apiClient.post('/api/gaps/recover', {
                                          'subject': subject,
                                          'topic': topic,
                                        });
                                        ref.read(refreshTickProvider.notifier).state++;
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Tópico para revisar marcado como recuperado (prática).',
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        HapticFeedback.heavyImpact();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                humanApiError(e, fallback: 'Não deu para marcar o tópico para revisar.'),
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
                  ],
                ),
              ),
            ],
          );
        },
    );
  }
}
