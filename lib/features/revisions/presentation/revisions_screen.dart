import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/ux_copy.dart';
import '../../../core/widgets/media_reinforcement.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/ui_kit.dart';

class RevisionsScreen extends ConsumerStatefulWidget {
  const RevisionsScreen({super.key});

  @override
  ConsumerState<RevisionsScreen> createState() => _RevisionsScreenState();
}

class _RevisionsScreenState extends ConsumerState<RevisionsScreen> {
  int selected = 0;
  final _focusNode = FocusNode();
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
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

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyR || key == LogicalKeyboardKey.f5) {
      ref.read(refreshTickProvider.notifier).state++;
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyS) {
      context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1');
      return KeyEventResult.handled;
    }
    if (_items.isEmpty) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyJ) {
      _moveSelection(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyK) {
      _moveSelection(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      _openItem(selected);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(revisionsApiProvider);
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      child: async.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const SoftLoader(label: 'Carregando revisões…'),
        error: (e, _) => EmptyState(
          title: 'Revisões indisponíveis',
          subtitle: humanApiError(e, fallback: 'Reabra o app e tente de novo.'),
          action: Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilledButton(
                onPressed: () => ref.read(refreshTickProvider.notifier).state++,
                child: const Text('Tentar de novo'),
              ),
              TextButton(
                onPressed: () => context.go('/sessao'),
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
            children: [
              PageBody(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PageHeader(
                      eyebrow: 'Analisar',
                      title: 'Revisões',
                      subtitle: _items.isEmpty
                          ? 'Os erros viram revisões'
                          : '${_items.length} assunto(s) para reforço',
                      trailing: IconButton(
                        tooltip: 'Atualizar',
                        onPressed: () => ref.read(refreshTickProvider.notifier).state++,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ),
                    if (_items.isEmpty)
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
                    else ...[
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
                      const SizedBox(height: 12),
                      Builder(
                        builder: (_) {
                          final item = _items[selected.clamp(0, _items.length - 1)];
                          final subject = item['subject']?.toString() ?? '';
                          final topic = item['topic']?.toString() ?? '';
                          if (subject.isEmpty || topic.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return MediaReinforcement(
                            subject: subject,
                            topic: topic,
                            compact: true,
                            heading: 'Reforço da revisão selecionada',
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
