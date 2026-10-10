import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/ux_copy.dart';
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

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(revisionsApiProvider);
    return async.when(
        loading: () => const SkeletonPage(),
        error: (e, _) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ErrorState(
              title: 'Revisões indisponíveis',
              message: humanApiError(e, fallback: 'Não deu para carregar as revisões.'),
              onRetry: () {
                HapticFeedback.selectionClick();
                ref.read(refreshTickProvider.notifier).state++;
              },
              secondary: AppButton.tertiary(label: 'Ir para a sessão', onPressed: () => context.go('/sessao')),
            ),
          ),
        ),
        data: (items) {
          _items = [for (final raw in items) Map<String, dynamic>.from(raw as Map)];
          if (selected >= _items.length && _items.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => selected = _items.length - 1);
            });
          }
          return LayoutBuilder(builder: (context, box) => ListView(
            padding: PageInsets.of(box.maxWidth),
            children: [
              Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PageHeader(
                      eyebrow: 'Reforço',
                      title: 'Revisões',
                      subtitle: _items.isEmpty
                          ? 'Os tópicos que você errou aparecem aqui'
                          : '${_items.length} assunto(s) para reforçar agora',
                      icon: Icons.replay_rounded,
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
                      QuietEmpty(
                        message: 'Nada agendado. Erre na sessão ou no simulado — os tópicos para revisar aparecem aqui.',
                        action: AppButton.primary(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            context.go('/sessao');
                          },
                          icon: Icons.play_arrow_rounded,
                          label: 'Abrir sessão',
                        ),
                      )
                    else ...[
                      ActionRow(children: [
                        AppButton.primary(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            setState(() => selected = 0);
                            _openItem(0);
                          },
                          icon: Icons.play_arrow_rounded,
                          label: 'Revisar agora',
                        ),
                      ]),
                      const SizedBox(height: 12),
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
                                  secondary: IconButton(
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
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
            ],
          ));
        },
    );
  }
}
