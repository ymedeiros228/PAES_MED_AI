import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/ux_copy.dart';
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
  final focusNode = FocusNode();
  bool showBack = false;
  int? currentId;
  /// Ciclo G/AK: default due-only; CTA Fila usa `/flashcards?due=1`.
  late bool dueOnly = widget.dueOnlyInitial;
  bool axesOnly = false;
  List<int> _itemIds = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    frontCtrl.dispose();
    backCtrl.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _ensureCardsFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final primary = FocusManager.instance.primaryFocus;
      if (primary != null && primary.context?.widget is EditableText) return;
      focusNode.requestFocus();
    });
  }

  Future<void> _create() async {
    if (frontCtrl.text.trim().isEmpty || backCtrl.text.trim().isEmpty) return;
    try {
      await apiClient.post('/api/flashcards', {
        'front': frontCtrl.text.trim(),
        'back': backCtrl.text.trim(),
      });
      frontCtrl.clear();
      backCtrl.clear();
      ref.read(refreshTickProvider.notifier).state++;
      _ensureCardsFocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para salvar o cartão.'))),
      );
    }
  }

  Future<void> _review(int id, bool remembered) async {
    // Haptic feedback ao revisar cartão
    HapticFeedback.lightImpact();
    try {
      await apiClient.post('/api/flashcards/$id/review', {'remembered': remembered});
      setState(() {
        showBack = false;
        currentId = null;
      });
      ref.read(refreshTickProvider.notifier).state++;
      _ensureCardsFocus();
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para registrar o cartão.'))),
      );
    }
  }

  void _flipTop() {
    if (_itemIds.isEmpty) return;
    final id = currentId ?? _itemIds.first;
    HapticFeedback.selectionClick();
    setState(() {
      if (currentId == id) {
        showBack = !showBack;
      } else {
        currentId = id;
        showBack = true;
      }
    });
    _ensureCardsFocus();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final primary = FocusManager.instance.primaryFocus;
    if (primary != null && primary.context?.widget is EditableText) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyR ||
        event.logicalKey == LogicalKeyboardKey.f5) {
      ref.read(refreshTickProvider.notifier).state++;
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyS) {
      context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1');
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      _flipTop();
      return KeyEventResult.handled;
    }
    final top = currentId ?? (_itemIds.isNotEmpty ? _itemIds.first : null);
    if (top == null) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.keyL ||
        event.logicalKey == LogicalKeyboardKey.digit1 ||
        event.logicalKey == LogicalKeyboardKey.numpad1) {
      _review(top, true);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyE ||
        event.logicalKey == LogicalKeyboardKey.digit2 ||
        event.logicalKey == LogicalKeyboardKey.numpad2) {
      _review(top, false);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final async = axesOnly
        ? ref.watch(flashcardsAxesProvider)
        : dueOnly
            ? ref.watch(flashcardsProvider)
            : ref.watch(flashcardsAllProvider);
    final cs = Theme.of(context).colorScheme;

    return Focus(
      focusNode: focusNode,
      onKeyEvent: _onKey,
      child: ListView(
        children: [
          PageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  eyebrow: 'Estudar',
                  title: 'Cartões',
                  subtitle: axesOnly
                      ? 'Só eixos de resolução · toque para virar'
                      : dueOnly
                          ? 'Só o que é para revisar hoje'
                          : 'Todos os cartões · toque para virar',
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
                          child: Text(dueOnly ? 'Ver todos' : 'Só para revisar'),
                        ),
                    ],
                  ),
                ),
                async.when(
                  loading: () => const SkeletonList(count: 4, lines: 2),
                  error: (e, _) => QuietEmpty(
                    message: humanApiError(e, fallback: 'Não deu para carregar os cartões.'),
                    action: Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => ref.read(refreshTickProvider.notifier).state++,
                          child: const Text('Tentar'),
                        ),
                        TextButton(
                          onPressed: () => context.go('/sessao'),
                          child: const Text('Sessão'),
                        ),
                      ],
                    ),
                  ),
                  data: (items) {
                    final ids = <int>[];
                    for (final raw in items) {
                      final item = Map<String, dynamic>.from(raw as Map);
                      final idRaw = item['id'];
                      final id = idRaw is int ? idRaw : int.tryParse('$idRaw');
                      if (id != null) ids.add(id);
                    }
                    _itemIds = ids;
                    if (items.isEmpty) {
                      return EmptyState(
                        title: dueOnly ? 'Nada para revisar agora' : 'Nenhum cartão ainda',
                        subtitle: dueOnly
                            ? 'Quando errar na sessão, os cartões aparecem aqui. Ou veja todos.'
                            : 'Estude uma sessão: ao errar, criamos cartões para você.',
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
                        // Indicador de progresso: X cartões para revisar
                        if (items.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Icon(Icons.style_outlined, size: 16, color: cs.primary),
                                const SizedBox(width: 6),
                                Text(
                                  '${items.length} cartão${items.length > 1 ? "ões" : ""} para revisar',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: cs.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        StaggeredFadeIn(
                          itemDelay: const Duration(milliseconds: 60),
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
                                          const Chip(
                                            label: Text('eixos'),
                                            visualDensity: VisualDensity.compact,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            padding: EdgeInsets.zero,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          if (currentId == id) {
                                            showBack = !showBack;
                                          } else {
                                            currentId = id;
                                            showBack = false;
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(kRadiusButton),
                                      child: FlipCard3D(
                                        flipped: flipped,
                                        front: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: cs.surfaceContainerHigh.f38,
                                            borderRadius: BorderRadius.circular(kRadiusButton),
                                            border: Border.all(
                                              color: cs.outlineVariant.f38,
                                            ),
                                          ),
                                          width: double.infinity,
                                          child: Text(
                                            item['front']?.toString() ?? '',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  height: 1.4,
                                                ),
                                          ),
                                        ),
                                        back: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: cs.primaryContainer.f38,
                                            borderRadius: BorderRadius.circular(kRadiusButton),
                                            border: Border.all(
                                              color: cs.primary.f38,
                                            ),
                                          ),
                                          width: double.infinity,
                                          child: Text(
                                            item['back']?.toString() ?? '',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  height: 1.4,
                                                  color: cs.onPrimaryContainer,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      flipped
                                          ? 'Toque / Space · L lembrei · E esqueci · próxima: ${humanDueLabel(item['next_due']?.toString())}'
                                          : 'Toque / Space para revelar · próxima: ${humanDueLabel(item['next_due']?.toString())}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: cs.onSurface.f55,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        FilledButton.tonalIcon(
                                          onPressed: () => _review(id, true),
                                          icon: const Icon(Icons.check_rounded, size: 18),
                                          label: const Text('Lembrei (L)'),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed: () => _review(id, false),
                                          icon: const Icon(Icons.refresh_rounded, size: 18),
                                          label: const Text('Esqueci (E)'),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          tooltip: 'Apagar',
                                          onPressed: () async {
                                            try {
                                              await apiClient.delete('/api/flashcards/$id');
                                              ref.read(refreshTickProvider.notifier).state++;
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    humanApiError(e, fallback: 'Não deu para apagar o cartão.'),
                                                  ),
                                                ),
                                              );
                                            }
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
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('Criar cartão manual', style: Theme.of(context).textTheme.titleSmall),
                  children: [
                    TextField(controller: frontCtrl, decoration: const InputDecoration(labelText: 'Frente')),
                    const SizedBox(height: 8),
                    TextField(controller: backCtrl, decoration: const InputDecoration(labelText: 'Verso')),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(onPressed: _create, child: const Text('Salvar cartão')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
