import 'dart:math';
import 'dart:ui';
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
// _CardDeckView — carrossel horizontal estilo Netflix
// PageView com peek das cartas vizinhas + indicador de progresso
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
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.52);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CardDeckView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentId != null) {
      final idx = widget.items.indexWhere((r) {
        if (r is! Map) return false;
        final id = r['id'] is int ? r['id'] : int.tryParse('${r['id']}');
        return id == widget.currentId;
      });
      if (idx >= 0 && idx != _currentIndex) {
        _currentIndex = idx;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.animateToPage(
              idx,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final total = widget.items.length;

    // Dados da carta virada (para o overlay de zoom)
    Map<String, dynamic>? flippedItem;
    if (widget.showBack && widget.currentId != null) {
      for (final r in widget.items) {
        if (r is! Map) continue;
        final id = r['id'] is int ? r['id'] : int.tryParse('${r['id']}');
        if (id == widget.currentId) {
          flippedItem = Map<String, dynamic>.from(r);
          break;
        }
      }
    }
    final isFlippedValid = flippedItem != null && flippedItem.isNotEmpty;

    return Stack(
      children: [
        // Conteúdo normal (carrossel)
        Column(
          children: [
            // Indicador de progresso "2 / 300"
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${_currentIndex + 1} / $total',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ),
            ),
            // Barra de progresso
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? (_currentIndex + 1) / total : 0,
                  minHeight: 4,
                  backgroundColor: cs.surfaceContainerHighest,
                  color: cs.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Carrossel PageView estilo Netflix — card vertical retrato
            SizedBox(
              height: 540,
              child: PageView.builder(
                controller: _pageController,
                itemCount: total,
                onPageChanged: (index) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final raw = widget.items[index];
                  final item = Map<String, dynamic>.from(raw as Map);
                  final id = item['id'] is int ? item['id'] : int.tryParse('${item['id']}');
                  if (id == null) return const SizedBox.shrink();

                  final subj = item['subject']?.toString() ?? '';
                  final top = item['topic']?.toString() ?? '';
                  final src = item['source']?.toString() ?? '';
                  final fromAxes = item['fromAxes'] == true || src.startsWith('axis:');
                  final accent = Color(subjectColorSeed(subj));
                  final flipped = widget.showBack && widget.currentId == id;

                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double scale = 1.0;
                      if (_pageController.position.haveDimensions) {
                        final page = _pageController.page ?? _currentIndex.toDouble();
                        final diff = (index - page).abs();
                        scale = (1 - diff * 0.12).clamp(0.78, 1.0);
                      }
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Center(
                      child: SizedBox(
                        width: 280,
                        child: _GameCard(
                          flipped: flipped,
                          subject: subj,
                          topic: top,
                          fromAxes: fromAxes,
                          frontText: item['front']?.toString() ?? '',
                          backText: item['back']?.toString() ?? '',
                          accent: accent,
                          dueLabel: humanDueLabel(item['next_due']?.toString()),
                          onTap: () => widget.onFlip(id),
                          onRemember: () => widget.onRemember(id),
                          onForgot: () => widget.onForgot(id),
                          onDelete: () => widget.onDelete(id),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Indicadores de ponto (estilo Netflix dots)
            if (total <= 12)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(total, (i) {
                  final active = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? cs.primary : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
          ],
        ),
        // === OVERLAY: zoom + blur quando a carta está virada ===
        if (isFlippedValid)
          _ZoomBlurOverlay(
            item: flippedItem,
            onTap: () => widget.onFlip(widget.currentId!),
            onRemember: () => widget.onRemember(widget.currentId!),
            onForgot: () => widget.onForgot(widget.currentId!),
            onDelete: () => widget.onDelete(widget.currentId!),
          ),
      ],
    );
  }
}

// ============================================================
// _GameCard — carta estilo TCG com herói gradiente + ícone
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
            left: 12,
            right: 12,
            top: 10,
            child: Container(
              height: 480,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            left: 6,
            right: 6,
            top: 5,
            child: Container(
              height: 480,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
        _FlipCard(
          flipped: flipped,
          front: _GameCardFace(
            text: frontText,
            subject: subject,
            topic: topic,
            fromAxes: fromAxes,
            isBack: false,
            onTap: onTap,
            dueLabel: dueLabel,
          ),
          back: _GameCardFace(
            text: backText,
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
    final accent = Color(subjectColorSeed(subject));
    final gradColors = subjectGradient(subject);
    final icon = subjectIcon(subject);
    final emoji = subjectEmoji(subject);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: cs.surface,
            border: Border.all(color: accent.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // === HERÓI: gradiente + ícone grande + emoji ===
                Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradColors,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Ícone grande de fundo (decorativo)
                          Positioned(
                            right: -30,
                            top: -15,
                            child: Icon(
                              icon,
                              size: 180,
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          // Emoji grande centralizado
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 64),
                                ),
                                const SizedBox(height: 6),
                                Icon(
                                  isBack ? Icons.lightbulb_rounded : Icons.style_rounded,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Overlay gradiente inferior para legibilidade
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Badge FRENTE/VERSO (canto superior esquerdo)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
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
                    // Badge EIXOS (canto superior direito)
                    if (fromAxes)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'EIXOS',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Nome da matéria + tópico (rodapé do herói)
                    Positioned(
                      bottom: 8,
                      left: 14,
                      right: 14,
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
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [accent, accent.withOpacity(0.3), accent],
                    ),
                  ),
                ),
                // === CORPO DA CARTA ===
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Texto principal
                        Flexible(
                          child: SingleChildScrollView(
                            child: SelectableText(
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
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Próxima revisão
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
                                    minimumSize: const Size.fromHeight(44),
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
                                    minimumSize: const Size.fromHeight(44),
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
                          const SizedBox(height: 6),
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
                          const SizedBox(height: 6),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// _ZoomBlurOverlay — overlay com blur + carta expandida
// Mostra o verso da carta em tela cheia com desfoque no fundo
// ============================================================

class _ZoomBlurOverlay extends StatefulWidget {
  const _ZoomBlurOverlay({
    required this.item,
    required this.onTap,
    required this.onRemember,
    required this.onForgot,
    required this.onDelete,
  });

  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final VoidCallback onRemember;
  final VoidCallback onForgot;
  final VoidCallback onDelete;

  @override
  State<_ZoomBlurOverlay> createState() => _ZoomBlurOverlayState();
}

class _ZoomBlurOverlayState extends State<_ZoomBlurOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _blur;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _blur = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final item = widget.item;
    final subj = item['subject']?.toString() ?? '';
    final top = item['topic']?.toString() ?? '';
    final src = item['source']?.toString() ?? '';
    final fromAxes = item['fromAxes'] == true || src.startsWith('axis:');
    final accent = Color(subjectColorSeed(subj));
    final gradColors = subjectGradient(subj);
    final icon = subjectIcon(subj);
    final emoji = subjectEmoji(subj);
    final backText = item['back']?.toString() ?? '';
    final dueLabel = humanDueLabel(item['next_due']?.toString());

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Fundo desfocado
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 8 * _blur.value,
                  sigmaY: 8 * _blur.value,
                ),
                child: Container(
                  color: Colors.black.withOpacity(0.5 * _opacity.value),
                ),
              ),
            ),
            // Carta expandida centralizada
            Center(
              child: Transform.scale(
                scale: _scale.value,
                child: Opacity(
                  opacity: _opacity.value,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onTap,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: cs.surface,
                            border: Border.all(color: accent, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(0.4),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // === HERÓI ===
                                Stack(
                                  children: [
                                    Container(
                                      height: 180,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: gradColors,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            right: -30,
                                            top: -15,
                                            child: Icon(
                                              icon,
                                              size: 200,
                                              color: Colors.white.withOpacity(0.08),
                                            ),
                                          ),
                                          Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(emoji, style: const TextStyle(fontSize: 60)),
                                                const SizedBox(height: 6),
                                                Icon(
                                                  Icons.lightbulb_rounded,
                                                  color: Colors.white.withOpacity(0.7),
                                                  size: 28,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 70,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.6),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                                        ),
                                        child: Text(
                                          'VERSO',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (fromAxes)
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade700.withOpacity(0.85),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                                              const SizedBox(width: 4),
                                              Text(
                                                'EIXOS',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      bottom: 10,
                                      left: 16,
                                      right: 16,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            subj.isNotEmpty ? subj : 'Flashcard',
                                            style: GoogleFonts.poppins(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              shadows: [
                                                Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 4),
                                              ],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (top.isNotEmpty)
                                            Text(
                                              top,
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
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
                                  height: 5,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [accent, accent.withOpacity(0.3), accent],
                                    ),
                                  ),
                                ),
                                // === CORPO EXPANDIDO (sem scroll) ===
                                Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SelectableText(
                                          backText,
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurface,
                                            height: 1.55,
                                          ),
                                          contextMenuBuilder: (context, editableTextState) =>
                                              AdaptiveTextSelectionToolbar.editableText(
                                            editableTextState: editableTextState,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        if (dueLabel.isNotEmpty)
                                          Row(
                                            children: [
                                              Icon(Icons.schedule_rounded, size: 13, color: cs.onSurface.withOpacity(0.3)),
                                              const SizedBox(width: 4),
                                              Text(
                                                dueLabel,
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: cs.onSurface.withOpacity(0.4),
                                                ),
                                              ),
                                            ],
                                          ),
                                        const SizedBox(height: 14),
                                        // Botões de ação
                                        Row(
                                          children: [
                                            Expanded(
                                              child: FilledButton.icon(
                                                onPressed: () {
                                                  HapticFeedback.selectionClick();
                                                  widget.onRemember();
                                                },
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: accent,
                                                  foregroundColor: Colors.white,
                                                  minimumSize: const Size.fromHeight(48),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                ),
                                                icon: const Icon(Icons.check_rounded, size: 22),
                                                label: Text(
                                                  'Lembrei',
                                                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () {
                                                  HapticFeedback.selectionClick();
                                                  widget.onForgot();
                                                },
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: accent,
                                                  minimumSize: const Size.fromHeight(48),
                                                  side: BorderSide(color: accent.withOpacity(0.4), width: 1.5),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                ),
                                                icon: const Icon(Icons.refresh_rounded, size: 22),
                                                label: Text(
                                                  'Esqueci',
                                                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            TextButton.icon(
                                              onPressed: () {
                                                HapticFeedback.selectionClick();
                                                widget.onDelete();
                                              },
                                              icon: Icon(Icons.delete_outline, size: 16, color: cs.onSurface.withOpacity(0.35)),
                                              label: Text(
                                                'Apagar',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: cs.onSurface.withOpacity(0.35),
                                                ),
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.touch_app_rounded, size: 14, color: accent.withOpacity(0.5)),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Toque para fechar',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: accent.withOpacity(0.6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
