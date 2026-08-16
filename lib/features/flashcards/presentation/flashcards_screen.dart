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
                    return Column(
                      children: [
                        // Indicador de progresso: X cartões para revisar
                        if (items.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Icon(Icons.style_outlined, size: 16, color: cs.primary),
                                const SizedBox(width: 8),
                                Text(
                                  '${items.length} cartão${items.length > 1 ? "ões" : ""} para revisar',
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: cs.primary),
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
                                  final accent = Color(subjectColorSeed(subj));
                                  final imgPath = flashcardImageFor(subj, top);
                                  return _DeckCard(
                                    flipped: flipped,
                                    subject: subj,
                                    topic: top,
                                    fromAxes: fromAxes,
                                    frontText: item['front']?.toString() ?? '',
                                    backText: item['back']?.toString() ?? '',
                                    accent: accent,
                                    imagePath: imgPath,
                                    dueLabel: humanDueLabel(item['next_due']?.toString()),
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
                                    onRemember: () { HapticFeedback.selectionClick(); _review(id, true); },
                                    onForgot: () { HapticFeedback.selectionClick(); _review(id, false); },
                                    onDelete: () async {
                                      HapticFeedback.selectionClick();
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
// DeckCard — card estilo baralho com imagem, gradiente e flip 3D
// ============================================================

class _DeckCard extends StatelessWidget {
  const _DeckCard({
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Stack(
        children: [
          // Sombra do "deck" — cartas empilhadas atrás
          if (!flipped) ...[
            Positioned(
              left: 4,
              right: 4,
              top: 3,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            Positioned(
              left: 2,
              right: 2,
              top: 1.5,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
          // Card principal
          _FlipCard(
            flipped: flipped,
            front: _CardFace(
              text: frontText,
              accent: accent,
              imagePath: imagePath,
              subject: subject,
              topic: topic,
              fromAxes: fromAxes,
              isBack: false,
              onTap: onTap,
              dueLabel: dueLabel,
              cs: cs,
            ),
            back: _CardFace(
              text: backText,
              accent: accent,
              imagePath: imagePath,
              subject: subject,
              topic: topic,
              fromAxes: fromAxes,
              isBack: true,
              onTap: onTap,
              dueLabel: dueLabel,
              cs: cs,
              onRemember: onRemember,
              onForgot: onForgot,
              onDelete: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.text,
    required this.accent,
    required this.imagePath,
    required this.subject,
    required this.topic,
    required this.fromAxes,
    required this.isBack,
    required this.onTap,
    required this.dueLabel,
    required this.cs,
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
  final ColorScheme cs;
  final VoidCallback? onRemember;
  final VoidCallback? onForgot;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: isBack ? accent.withOpacity(0.08) : cs.surface,
            border: Border.all(
              color: accent.withOpacity(isBack ? 0.5 : 0.25),
              width: isBack ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Faixa colorida com assunto + imagem
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent,
                        accent.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Imagem de fundo (se houver)
                      if (imagePath != null)
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.35,
                            child: Image.asset(
                              imagePath!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      // Overlay escuro para legibilidade
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Conteúdo da faixa
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isBack ? Icons.lightbulb_rounded : Icons.style_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    subject.isNotEmpty ? subject : 'Flashcard',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.4),
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (fromAxes)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'eixos',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (topic.isNotEmpty)
                              Text(
                                topic,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 2,
                                    ),
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
                ),
                // Corpo do card
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge frente/verso
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: isBack ? accent.withOpacity(0.15) : cs.surfaceContainerHighest.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isBack ? 'VERSO' : 'FRENTE',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isBack ? accent : cs.onSurface.withOpacity(0.5),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (dueLabel.isNotEmpty)
                            Text(
                              dueLabel,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: cs.onSurface.withOpacity(0.4),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Texto principal
                      SelectableText(
                        text,
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
                      // Dica de interação
                      if (!isBack)
                        Row(
                          children: [
                            Icon(Icons.touch_app_rounded, size: 14, color: accent.withOpacity(0.6)),
                            const SizedBox(width: 6),
                            Text(
                              'Toque para revelar o verso',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: accent.withOpacity(0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      // Botões de revisão (só no verso)
                      if (isBack && onRemember != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: onRemember,
                                style: FilledButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: const Text('Lembrei'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: onForgot,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: accent,
                                  side: BorderSide(color: accent.withOpacity(0.4)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Esqueci'),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Apagar',
                              onPressed: onDelete,
                              icon: Icon(Icons.delete_outline, color: cs.onSurface.withOpacity(0.4)),
                            ),
                          ],
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
    );
  }
}
