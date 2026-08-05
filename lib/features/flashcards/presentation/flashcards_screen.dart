import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/providers.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/ui_kit.dart';

class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key, this.dueOnlyInitial = true});

  /// Query `?due=1` force due; `?due=0` mostra todos.
  final bool dueOnlyInitial;

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  final frontCtrl = TextEditingController();
  final backCtrl = TextEditingController();
  bool showBack = false;
  int? currentId;
  /// Ciclo G/AK: default due-only; CTA Fila usa `/flashcards?due=1`.
  late bool dueOnly = widget.dueOnlyInitial;
  bool axesOnly = false;

  @override
  void dispose() {
    frontCtrl.dispose();
    backCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (frontCtrl.text.trim().isEmpty || backCtrl.text.trim().isEmpty) return;
    await apiClient.post('/api/flashcards', {
      'front': frontCtrl.text.trim(),
      'back': backCtrl.text.trim(),
    });
    frontCtrl.clear();
    backCtrl.clear();
    ref.read(refreshTickProvider.notifier).state++;
  }

  Future<void> _review(int id, bool remembered) async {
    await apiClient.post('/api/flashcards/$id/review', {'remembered': remembered});
    setState(() {
      showBack = false;
      currentId = null;
    });
    ref.read(refreshTickProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context) {
    final async = axesOnly
        ? ref.watch(flashcardsAxesProvider)
        : dueOnly
            ? ref.watch(flashcardsProvider)
            : ref.watch(flashcardsAllProvider);
    final cs = Theme.of(context).colorScheme;

    return ListView(
      children: [
        PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: 'Estudar',
                title: 'Cards',
                subtitle: axesOnly
                    ? 'Só cards de eixos (resolução) · treino local'
                    : dueOnly
                        ? 'Só cards due hoje · toque para virar'
                        : 'Todos os cards · próximo due no rodapé',
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        axesOnly = !axesOnly;
                        if (axesOnly) dueOnly = false;
                        showBack = false;
                        currentId = null;
                      }),
                      child: Text(axesOnly ? 'Todos tipos' : 'Só eixos'),
                    ),
                    if (!axesOnly)
                      TextButton(
                        onPressed: () => setState(() {
                          dueOnly = !dueOnly;
                          showBack = false;
                          currentId = null;
                        }),
                        child: Text(dueOnly ? 'Ver todos' : 'Só due'),
                      ),
                  ],
                ),
              ),
              async.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => QuietEmpty(
                  message: 'Não deu para carregar os cards.',
                  action: TextButton(
                    onPressed: () => ref.read(refreshTickProvider.notifier).state++,
                    child: const Text('Tentar'),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return EmptyState(
                      title: dueOnly ? 'Nenhum card due' : 'Nenhum card ainda',
                      subtitle: dueOnly
                          ? 'Fila de revisão vazia — errou na sessão? Volte amanhã ou veja todos.'
                          : 'Erre na sessão, importe uma aula ou crie um manualmente abaixo.',
                      action: Wrap(
                        spacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          if (dueOnly)
                            FilledButton.tonal(
                              onPressed: () => setState(() => dueOnly = false),
                              child: const Text('Ver todos'),
                            ),
                          FilledButton(onPressed: () => context.go('/sessao'), child: const Text('Sessão')),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final raw in items)
                        Builder(
                          builder: (_) {
                            final item = Map<String, dynamic>.from(raw as Map);
                            final idRaw = item['id'];
                            final id = idRaw is int ? idRaw : int.tryParse('$idRaw');
                            if (id == null) return const SizedBox.shrink();
                            final flipped = showBack && currentId == id;
                            final subj = item['subject']?.toString() ?? '';
                            final top = item['topic']?.toString() ?? '';
                            final src = item['source']?.toString() ?? '';
                            final fromAxes = item['fromAxes'] == true || src.startsWith('axis:');
                            return SurfacePanel(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (subj.isNotEmpty || top.isNotEmpty)
                                        Expanded(
                                          child: Text(
                                            [subj, top].where((e) => e.isNotEmpty).join(' · '),
                                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                  color: cs.primary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        )
                                      else
                                        const Spacer(),
                                      if (fromAxes)
                                        Chip(
                                          label: const Text('eixos'),
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          padding: EdgeInsets.zero,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => setState(() {
                                      if (currentId == id) {
                                        showBack = !showBack;
                                      } else {
                                        currentId = id;
                                        showBack = false;
                                      }
                                    }),
                                    child: Text(
                                      flipped
                                          ? (item['back']?.toString() ?? '')
                                          : (item['front']?.toString() ?? ''),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.35),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    flipped
                                        ? 'Toque para voltar · Próxima: ${item['next_due'] ?? '—'}'
                                        : 'Toque para revelar · Próxima: ${item['next_due'] ?? '—'}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: cs.onSurface.withOpacity(0.55),
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      FilledButton.tonal(
                                        onPressed: () => _review(id, true),
                                        child: const Text('Lembrei'),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        onPressed: () => _review(id, false),
                                        child: const Text('Esqueci'),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        tooltip: 'Apagar',
                                        onPressed: () async {
                                          await apiClient.delete('/api/flashcards/$id');
                                          ref.read(refreshTickProvider.notifier).state++;
                                        },
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Criar card manual', style: Theme.of(context).textTheme.titleSmall),
                children: [
                  TextField(controller: frontCtrl, decoration: const InputDecoration(labelText: 'Frente')),
                  const SizedBox(height: 8),
                  TextField(controller: backCtrl, decoration: const InputDecoration(labelText: 'Verso')),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(onPressed: _create, child: const Text('Salvar card')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
