import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/widgets/ui/subject_style.dart';
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
  final topicCtrl = TextEditingController();
  bool showBack = false;
  int? currentId;
  /// Ciclo G/AK: default due-only; CTA Fila usa `/flashcards?due=1`.
  late bool dueOnly = widget.dueOnlyInitial;
  bool axesOnly = false;
  String createSubject = 'Biologia';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    frontCtrl.dispose();
    backCtrl.dispose();
    topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (frontCtrl.text.trim().isEmpty || backCtrl.text.trim().isEmpty) return;
    try {
      final topic = topicCtrl.text.trim();
      await apiClient.post('/api/flashcards', {
        'front': frontCtrl.text.trim(),
        'back': backCtrl.text.trim(),
        'subject': createSubject,
        if (topic.isNotEmpty) 'topic': topic,
      });
      frontCtrl.clear();
      backCtrl.clear();
      topicCtrl.clear();
      ref.read(refreshTickProvider.notifier).state++;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cartão salvo.')),
      );
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
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para registrar o cartão.'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = axesOnly
        ? ref.watch(flashcardsAxesProvider)
        : dueOnly
            ? ref.watch(flashcardsProvider)
            : ref.watch(flashcardsAllProvider);
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(builder: (context, box) => ListView(
      padding: PageInsets.of(box.maxWidth),
        children: [
          Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  eyebrow: 'Estudar',
                  title: 'Flashcards',
                  subtitle: axesOnly
                      ? 'Por área · toque para virar'
                      : dueOnly
                          ? 'Só o que é para revisar hoje — toque na carta'
                          : 'Todos os cartões · toque para virar',
                  icon: Icons.style_rounded,
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      TextButton(
                        onPressed: () { HapticFeedback.selectionClick(); setState(() {
                          axesOnly = !axesOnly;
                          if (axesOnly) dueOnly = false;
                          showBack = false;
                          currentId = null;
                        }); },
                        child: Text(axesOnly ? 'Todos tipos' : 'Por área'),
                      ),
                      if (!axesOnly)
                        TextButton(
                          onPressed: () { HapticFeedback.selectionClick(); setState(() {
                            dueOnly = !dueOnly;
                            showBack = false;
                            currentId = null;
                          }); },
                          child: Text(dueOnly ? 'Ver todos' : 'Para hoje'),
                        ),
                    ],
                  ),
                ),
                async.when(
                  loading: () => const SkeletonList(count: 2, lines: 3),
                  error: (e, _) => ErrorState(
                    message: humanApiError(e, fallback: 'Não deu para carregar os cartões.'),
                    onRetry: () => ref.read(refreshTickProvider.notifier).state++,
                  ),
                  data: (items) {
                    final ids = <int>[];
                    for (final raw in items) {
                      final item = Map<String, dynamic>.from(raw as Map);
                      final idRaw = item['id'];
                      final id = idRaw is int ? idRaw : int.tryParse('$idRaw');
                      if (id != null) ids.add(id);
                    }
                    if (items.isEmpty) {
                      return QuietEmpty(
                        message: dueOnly
                            ? 'Nada para revisar agora. Quando errar na sessão, os cartões aparecem aqui.'
                            : 'Nenhum cartão ainda. Estude uma sessão — ao errar, criamos cartões para você.',
                        action: Wrap(
                          spacing: 8,
                          children: [
                            if (dueOnly)
                              FilledButton.tonal(
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => dueOnly = false);
                                },
                                child: const Text('Ver todos'),
                              ),
                            FilledButton.icon(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                context.go('/sessao');
                              },
                              icon: const Icon(Icons.play_arrow_rounded, size: 18),
                              label: const Text('Abrir sessão'),
                            ),
                          ],
                        ),
                      );
                    }
                    return _CardDeckView(
                      items: items,
                      currentId: currentId,
                      showBack: showBack,
                      onFlip: (id) {
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
                      onVisible: (id) {
                        if (currentId == id) return;
                        setState(() {
                          currentId = id;
                          showBack = false;
                        });
                      },
                      onPrev: () {
                        HapticFeedback.selectionClick();
                        final idx = items.indexWhere((r) {
                          final rid = r is Map ? (r['id'] is int ? r['id'] : int.tryParse('${r['id']}')) : null;
                          return rid == currentId;
                        });
                        if (idx > 0) {
                          final prevRaw = items[idx - 1];
                          final prevId = prevRaw is Map ? (prevRaw['id'] is int ? prevRaw['id'] : int.tryParse('${prevRaw['id']}')) : null;
                          setState(() { currentId = prevId; showBack = false; });
                        }
                      },
                      onNext: () {
                        HapticFeedback.selectionClick();
                        final idx = items.indexWhere((r) {
                          final rid = r is Map ? (r['id'] is int ? r['id'] : int.tryParse('${r['id']}')) : null;
                          return rid == currentId;
                        });
                        if (idx >= 0 && idx < items.length - 1) {
                          final nextRaw = items[idx + 1];
                          final nextId = nextRaw is Map ? (nextRaw['id'] is int ? nextRaw['id'] : int.tryParse('${nextRaw['id']}')) : null;
                          setState(() { currentId = nextId; showBack = false; });
                        }
                      },
                      onRemember: (id) { HapticFeedback.selectionClick(); _review(id, true); },
                      onForgot: (id) { HapticFeedback.selectionClick(); _review(id, false); },
                      onDelete: (id) async {
                        HapticFeedback.selectionClick();
                        try {
                          await apiClient.delete('/api/flashcards/$id');
                          ref.read(refreshTickProvider.notifier).state++;
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para apagar o cartão.'))),
                          );
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Criar cartão manual',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
                  ),
                  subtitle: const Text('Matéria + tópico ligam a capa do material'),
                  children: [
                    DropdownMenu<String>(
                      initialSelection: createSubject,
                      label: const Text('Disciplina'),
                      width: double.infinity,
                      onSelected: (v) {
                        if (v == null) return;
                        setState(() => createSubject = v);
                      },
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(value: 'Biologia', label: 'Biologia'),
                        DropdownMenuEntry(value: 'Química', label: 'Química'),
                        DropdownMenuEntry(value: 'Física', label: 'Física'),
                        DropdownMenuEntry(value: 'Matemática', label: 'Matemática'),
                        DropdownMenuEntry(value: 'Língua Portuguesa e Literatura', label: 'Português'),
                        DropdownMenuEntry(value: 'História', label: 'História'),
                        DropdownMenuEntry(value: 'Geografia', label: 'Geografia'),
                        DropdownMenuEntry(value: 'Filosofia', label: 'Filosofia'),
                        DropdownMenuEntry(value: 'Sociologia', label: 'Sociologia'),
                        DropdownMenuEntry(value: 'Inglês', label: 'Inglês'),
                        DropdownMenuEntry(value: 'Espanhol', label: 'Espanhol'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: topicCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Assunto',
                        hintText: 'Ex.: Genética',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: frontCtrl, decoration: const InputDecoration(labelText: 'Frente')),
                    const SizedBox(height: 8),
                    TextField(controller: backCtrl, decoration: const InputDecoration(labelText: 'Verso')),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _create();
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Salvar cartão'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
    ));
  }
}

/// Deck de estudo: uma carta grande no centro, virada 3D suave e autoavaliação.
class _CardDeckView extends StatefulWidget {
  const _CardDeckView({
    required this.items,
    required this.currentId,
    required this.showBack,
    required this.onFlip,
    required this.onVisible,
    required this.onPrev,
    required this.onNext,
    required this.onRemember,
    required this.onForgot,
    required this.onDelete,
  });

  final List<dynamic> items;
  final int? currentId;
  final bool showBack;
  final ValueChanged<int> onFlip;
  final ValueChanged<int> onVisible;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<int> onRemember;
  final ValueChanged<int> onForgot;
  final ValueChanged<int> onDelete;

  @override
  State<_CardDeckView> createState() => _CardDeckViewState();
}

class _CardDeckViewState extends State<_CardDeckView> with SingleTickerProviderStateMixin {
  int _index = 0;
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  int? _idAt(int i) {
    if (i < 0 || i >= widget.items.length) return null;
    final raw = widget.items[i];
    if (raw is! Map) return null;
    return raw['id'] is int ? raw['id'] as int : int.tryParse('${raw['id']}');
  }

  @override
  void initState() {
    super.initState();
    _flip.value = widget.showBack ? 1 : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      _announce();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _flip.dispose();
    super.dispose();
  }

  void _announce() {
    final id = _idAt(_index);
    if (id != null && id != widget.currentId) widget.onVisible(id);
  }

  void _goTo(int i) {
    if (i < 0 || i >= widget.items.length) return;
    setState(() => _index = i);
    _announce();
  }

  @override
  void didUpdateWidget(covariant _CardDeckView old) {
    super.didUpdateWidget(old);
    if (_index >= widget.items.length) _index = widget.items.isEmpty ? 0 : widget.items.length - 1;
    if (widget.showBack) {
      _flip.forward();
    } else {
      _flip.reverse();
    }
    if (widget.currentId == null || widget.currentId != _idAt(_index)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _announce();
      });
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final k = event.logicalKey;
    final id = _idAt(_index);
    if ((k == LogicalKeyboardKey.space || k == LogicalKeyboardKey.enter) && id != null) {
      widget.onFlip(id);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.keyA) {
      _goTo(_index - 1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.keyD) {
      _goTo(_index + 1);
      return KeyEventResult.handled;
    }
    if (id != null && widget.showBack) {
      if (k == LogicalKeyboardKey.digit1 || k == LogicalKeyboardKey.numpad1) {
        widget.onForgot(id);
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.digit2 ||
          k == LogicalKeyboardKey.numpad2 ||
          k == LogicalKeyboardKey.digit3 ||
          k == LogicalKeyboardKey.numpad3) {
        widget.onRemember(id);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final total = widget.items.length;
    final index = _index.clamp(0, total - 1);
    final item = Map<String, dynamic>.from(widget.items[index] as Map);
    final id = _idAt(index);
    final subject = item['subject']?.toString() ?? '';
    final topic = item['topic']?.toString() ?? '';
    final style = subjectVisual(subject);
    final front = item['front']?.toString() ?? '';
    final back = item['back']?.toString() ?? '';

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Cartão ${index + 1} de $total',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface.withOpacity(0.7))),
              const SizedBox(width: kGap12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (index + 1) / total,
                    minHeight: 6,
                    color: style.color,
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: kGap24),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: GestureDetector(
                onTap: id == null ? null : () => widget.onFlip(id),
                child: AnimatedBuilder(
                  animation: _flip,
                  builder: (context, _) {
                    final t = Curves.easeInOutCubic.transform(_flip.value);
                    final angle = t * pi;
                    final showingBack = t > 0.5;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012)
                        ..rotateY(angle),
                      child: Transform(
                        alignment: Alignment.center,
                        // Espelha o verso para o texto não ficar invertido.
                        transform: Matrix4.rotationY(showingBack ? pi : 0),
                        child: _CardFace(
                          style: style,
                          subject: subject,
                          topic: topic,
                          text: showingBack ? back : front,
                          label: showingBack ? 'Resposta' : 'Pergunta',
                          hint: showingBack ? null : 'Toque na carta ou aperte Espaço para virar',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: kGap24),
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: widget.showBack && id != null
                  ? ActionRow(
                      key: const ValueKey('rate'),
                      alignment: WrapAlignment.center,
                      children: [
                        _RateButton(label: 'Errei', hint: '1', color: const Color(0xFFD64545), onTap: () => widget.onForgot(id)),
                        _RateButton(label: 'Difícil', hint: '2', color: const Color(0xFFE59B1F), onTap: () => widget.onRemember(id)),
                        _RateButton(label: 'Fácil', hint: '3', color: const Color(0xFF2E9E5B), onTap: () => widget.onRemember(id)),
                      ],
                    )
                  : ActionRow(
                      key: const ValueKey('flip'),
                      alignment: WrapAlignment.center,
                      children: [
                        AppButton.tertiary(
                          label: 'Anterior',
                          icon: Icons.arrow_back_rounded,
                          onPressed: index > 0 ? () => _goTo(index - 1) : null,
                        ),
                        AppButton.primary(
                          label: 'Virar carta',
                          icon: Icons.flip_rounded,
                          onPressed: id == null ? null : () => widget.onFlip(id),
                        ),
                        AppButton.tertiary(
                          label: 'Próximo',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: index < total - 1 ? () => _goTo(index + 1) : null,
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: kGap8),
          Center(
            child: TextButton.icon(
              onPressed: id == null ? null : () => widget.onDelete(id),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Apagar este cartão'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RateButton extends StatelessWidget {
  const _RateButton({required this.label, required this.hint, required this.color, required this.onTap});

  final String label;
  final String hint;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(120, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text('$label  ($hint)', style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.style,
    required this.subject,
    required this.topic,
    required this.text,
    required this.label,
    this.hint,
  });

  final SubjectVisual style;
  final String subject;
  final String topic;
  final String text;
  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final long = text.length > 160;
    return Container(
      height: 340,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.color.withOpacity(0.35)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: style.soft,
            padding: const EdgeInsets.symmetric(horizontal: kGap20, vertical: kGap12),
            child: Row(
              children: [
                Icon(style.icon, size: 20, color: style.color),
                const SizedBox(width: kGap8),
                Expanded(
                  child: Text(
                    [if (subject.isNotEmpty) subject, if (topic.isNotEmpty) topic].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: style.color),
                  ),
                ),
                Text(label.toUpperCase(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: style.color)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kGap24, vertical: kGap16),
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    text,
                    textAlign: long ? TextAlign.left : TextAlign.center,
                    style: TextStyle(
                      fontSize: long ? 18 : 24,
                      height: 1.45,
                      fontWeight: long ? FontWeight.w500 : FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(bottom: kGap12),
              child: Text(hint!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
            ),
        ],
      ),
    );
  }
}
