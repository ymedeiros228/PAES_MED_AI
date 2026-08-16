import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/widgets/flashcard_images.dart';
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
  bool showBack = false;
  int? currentId;
  /// Ciclo G/AK: default due-only; CTA Fila usa `/flashcards?due=1`.
  late bool dueOnly = widget.dueOnlyInitial;
  bool axesOnly = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    frontCtrl.dispose();
    backCtrl.dispose();
    super.dispose();
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

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
        children: [
          PageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  eyebrow: 'Estudar',
                  title: 'Flashcards',
                  subtitle: axesOnly
                      ? 'Por área · toque para virar'
                      : dueOnly
                          ? 'Só o que é para revisar hoje'
                          : 'Todos os cartões · toque para virar',
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
                  loading: () => const SkeletonList(count: 4, lines: 2),
                  error: (e, _) => QuietEmpty(
                    message: humanApiError(e, fallback: 'Não deu para carregar os cartões.'),
                    action: Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () { HapticFeedback.selectionClick(); ref.read(refreshTickProvider.notifier).state++; },
                          child: const Text('Tentar'),
                        ),
                        TextButton(
                          onPressed: () { HapticFeedback.selectionClick(); context.go('/sessao'); },
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
                    if (items.isEmpty) {
                      return EmptyState(
                        icon: Icons.style_outlined,
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
                                onPressed: () { HapticFeedback.selectionClick(); setState(() => dueOnly = false); },
                                child: const Text('Ver todos'),
                              ),
                            FilledButton(onPressed: () { HapticFeedback.selectionClick(); context.go('/sessao'); }, child: const Text('Sessão')),
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
                  title: Text('Criar cartão manual', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  children: [
                    TextField(controller: frontCtrl, decoration: const InputDecoration(labelText: 'Frente')),
                    const SizedBox(height: 8),
                    TextField(controller: backCtrl, decoration: const InputDecoration(labelText: 'Verso')),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(onPressed: () { HapticFeedback.selectionClick(); _create(); }, child: const Text('Salvar cartão')),
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

class _FlipCard extends StatefulWidget {
  const _FlipCard({required this.front, required this.back, required this.flipped});

  final Widget front;
  final Widget back;
  final bool flipped;

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    if (widget.flipped) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant _FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flipped != widget.flipped) {
      if (widget.flipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final angle = _animation.value * pi;
        final showFront = angle < 0.5 * pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: showFront
              ? widget.front
              : Transform.flip(
                  flipX: true,
                  child: widget.back,
                ),
        );
      },
    );
  }
}

// ============================================================
// _CardDeckView — carrossel de cartas estilo jogo de TCG
// Mostra 1 carta centralizada com prev/next e contador
// ============================================================

class _CardDeckView extends StatefulWidget {
  const _CardDeckView({
    required this.items,
    required this.currentId,
    required this.showBack,
    required this.onFlip,
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
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<int> onRemember;
  final ValueChanged<int> onForgot;
  final ValueChanged<int> onDelete;

  @override
  State<_CardDeckView> createState() => _CardDeckViewState();
}

class _CardDeckViewState extends State<_CardDeckView> {
  int _currentIndex = 0;

  @override
  void didUpdateWidget(covariant _CardDeckView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sincronizar currentIndex com currentId
    if (widget.currentId != null) {
      final idx = widget.items.indexWhere((r) {
        if (r is! Map) return false;
        final id = r['id'] is int ? r['id'] : int.tryParse('${r['id']}');
        return id == widget.currentId;
      });
      if (idx >= 0) _currentIndex = idx;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (widget.items.isEmpty) return const SizedBox.shrink();

    // Garantir que currentIndex é válido
    if (_currentIndex >= widget.items.length) _currentIndex = 0;
    final raw = widget.items[_currentIndex];
    final item = Map<String, dynamic>.from(raw as Map);
    final id = item['id'] is int ? item['id'] : int.tryParse('${item['id']}');
    if (id == null) return const SizedBox.shrink();

    final subj = item['subject']?.toString() ?? '';
    final top = item['topic']?.toString() ?? '';
    final src = item['source']?.toString() ?? '';
    final fromAxes = item['fromAxes'] == true || src.startsWith('axis:');
    final accent = Color(subjectColorSeed(subj));
    final imgPath = flashcardImageFor(subj, top);
    final flipped = widget.showBack && widget.currentId == id;
    final total = widget.items.length;
    final pos = _currentIndex + 1;

    return Column(
      children: [
        // Contador de cartas
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.style_rounded, size: 16, color: accent),
                    const SizedBox(width: 6),
                    Text(
                      '$pos / $total',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Carta centralizada
        Center(
          child: SizedBox(
            width: 340,
            child: _GameCard(
              flipped: flipped,
              subject: subj,
              topic: top,
              fromAxes: fromAxes,
              frontText: item['front']?.toString() ?? '',
              backText: item['back']?.toString() ?? '',
              accent: accent,
              imagePath: imgPath,
              dueLabel: humanDueLabel(item['next_due']?.toString()),
              onTap: () => widget.onFlip(id),
              onRemember: () => widget.onRemember(id),
              onForgot: () => widget.onForgot(id),
              onDelete: () => widget.onDelete(id),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Navegação prev/next
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filled(
              onPressed: _currentIndex > 0 ? widget.onPrev : null,
              icon: const Icon(Icons.navigate_before_rounded),
              style: IconButton.styleFrom(backgroundColor: cs.surfaceContainerHighest),
            ),
            const SizedBox(width: 24),
            Text(
              _currentIndex > 0 ? 'Anterior' : 'Início',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: cs.onSurface.withOpacity(0.4),
              ),
            ),
            const SizedBox(width: 24),
            IconButton.filled(
              onPressed: _currentIndex < total - 1 ? widget.onNext : null,
              icon: const Icon(Icons.navigate_next_rounded),
              style: IconButton.styleFrom(backgroundColor: cs.surfaceContainerHighest),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// _GameCard — carta estilo TCG (Clash Royale / Hearthstone)
// ============================================================

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.flipped,
    required this.subject,
    required this.topic,
    required this.fromAxes,
    required this.frontText,
    required this.backText,
    required this.accent,
    required this.imagePath,
    required this.dueLabel,
    required this.onTap,
    required this.onRemember,
    required this.onForgot,
    required this.onDelete,
  });

  final bool flipped;
  final String subject;
  final String topic;
  final bool fromAxes;
  final String frontText;
  final String backText;
  final Color accent;
  final String? imagePath;
  final String dueLabel;
  final VoidCallback onTap;
  final VoidCallback onRemember;
  final VoidCallback onForgot;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Cartas empilhadas atrás (efeito deck)
        if (!flipped) ...[
          Positioned(
            left: 8,
            right: 8,
            top: 6,
            child: Container(
              height: 380,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            left: 4,
            right: 4,
            top: 3,
            child: Container(
              height: 380,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
        // Card principal
        _FlipCard(
          flipped: flipped,
          front: _GameCardFace(
            text: frontText,
            accent: accent,
            imagePath: imagePath,
            subject: subject,
            topic: topic,
            fromAxes: fromAxes,
            isBack: false,
            onTap: onTap,
            dueLabel: dueLabel,
          ),
          back: _GameCardFace(
            text: backText,
            accent: accent,
            imagePath: imagePath,
            subject: subject,
            topic: topic,
            fromAxes: fromAxes,
            isBack: true,
            onTap: onTap,
            dueLabel: dueLabel,
            onRemember: onRemember,
            onForgot: onForgot,
            onDelete: onDelete,
          ),
        ),
      ],
    );
  }
}

class _GameCardFace extends StatelessWidget {
  const _GameCardFace({
    required this.text,
    required this.accent,
    required this.imagePath,
    required this.subject,
    required this.topic,
    required this.fromAxes,
    required this.isBack,
    required this.onTap,
    required this.dueLabel,
    this.onRemember,
    this.onForgot,
    this.onDelete,
  });

  final String text;
  final Color accent;
  final String? imagePath;
  final String subject;
  final String topic;
  final bool fromAxes;
  final bool isBack;
  final VoidCallback onTap;
  final String dueLabel;
  final VoidCallback? onRemember;
  final VoidCallback? onForgot;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Cor "raridade" baseada na matéria
    final rarityGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [accent, accent.withOpacity(0.6)],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent, width: 3),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              color: cs.surface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // === HEADER com imagem (estilo retrato de carta) ===
                  Stack(
                    children: [
                      // Imagem de fundo
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: rarityGradient,
                        ),
                        child: imagePath != null
                            ? Image.asset(
                                imagePath!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Icon(
                                    isBack ? Icons.lightbulb_rounded : Icons.style_rounded,
                                    color: Colors.white.withOpacity(0.5),
                                    size: 48,
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  isBack ? Icons.lightbulb_rounded : Icons.style_rounded,
                                  color: Colors.white.withOpacity(0.5),
                                  size: 48,
                                ),
                              ),
                      ),
                      // Overlay gradiente para legibilidade
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.1),
                                Colors.black.withOpacity(0.5),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Badge de raridade (canto superior esquerdo)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                          ),
                          child: Text(
                            isBack ? 'VERSO' : 'FRENTE',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      // Badge "eixos" (canto superior direito)
                      if (fromAxes)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 12, color: Colors.white),
                                const SizedBox(width: 3),
                                Text(
                                  'EIXOS',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Nome da matéria (canto inferior)
                      Positioned(
                        bottom: 6,
                        left: 10,
                        right: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              subject.isNotEmpty ? subject : 'Flashcard',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                shadows: [
                                  Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 4),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (topic.isNotEmpty)
                              Text(
                                topic,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.85),
                                  shadows: [
                                    Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 3),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // === BARRA DE RARIDADE ===
                  Container(
                    height: 4,
                    decoration: BoxDecoration(gradient: rarityGradient),
                  ),
                  // === CORPO DA CARTA ===
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Texto principal
                        SelectableText(
                          text,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                            height: 1.5,
                          ),
                          contextMenuBuilder: (context, editableTextState) =>
                              AdaptiveTextSelectionToolbar.editableText(
                            editableTextState: editableTextState,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Dica / próxima revisão
                        if (dueLabel.isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded, size: 12, color: cs.onSurface.withOpacity(0.3)),
                              const SizedBox(width: 4),
                              Text(
                                dueLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: cs.onSurface.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        // Botões de ação (só no verso)
                        if (isBack && onRemember != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: onRemember,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: accent,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(42),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.check_rounded, size: 20),
                                  label: Text(
                                    'Lembrei',
                                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: onForgot,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: accent,
                                    minimumSize: const Size.fromHeight(42),
                                    side: BorderSide(color: accent.withOpacity(0.4), width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.refresh_rounded, size: 20),
                                  label: Text(
                                    'Esqueci',
                                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton.icon(
                              onPressed: onDelete,
                              icon: Icon(Icons.delete_outline, size: 16, color: cs.onSurface.withOpacity(0.35)),
                              label: Text(
                                'Apagar cartão',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: cs.onSurface.withOpacity(0.35),
                                ),
                              ),
                            ),
                          ),
                        ],
                        // Dica de flip (só na frente)
                        if (!isBack) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.touch_app_rounded, size: 14, color: accent.withOpacity(0.5)),
                                const SizedBox(width: 6),
                                Text(
                                  'Toque para virar a carta',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: accent.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

