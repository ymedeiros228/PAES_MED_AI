// Peças da "tela de questão" no padrão plataforma de curso, usadas pela
// sessão guiada, simulado, ficha da questão e treino adaptativo.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import 'content_widgets.dart';
import 'layout_tokens.dart';
import 'subject_style.dart';

/// Resultado de uma questão para a trilha de progresso.
enum QuestionMark { pending, answered, correct, wrong }

/// Cabeçalho da questão: "Questão 3 de 10", trilha de pontinhos e chips de
/// disciplina/tópico/fonte. A trilha vira barra contínua quando há muitas questões.
class QuestionHeader extends StatelessWidget {
  const QuestionHeader({
    required this.index,
    required this.total,
    this.marks = const [],
    this.subject = '',
    this.topic,
    this.year,
    this.official,
    this.trailing,
    this.extra,
    super.key,
  });

  /// Índice base 0 da questão atual.
  final int index;
  final int total;

  /// Estado de cada questão (tamanho [total]); vazio = só destaca a atual.
  final List<QuestionMark> marks;
  final String subject;
  final String? topic;
  final int? year;

  /// true = oficial PAES-UEMA, false = treino, null = não mostrar.
  final bool? official;

  /// Texto à direita do título (ex.: "6/8 acertos").
  final String? trailing;
  final String? extra;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shown = total == 0 ? 0 : (index + 1).clamp(1, total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Questão $shown de $total',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: cs.onSurface),
            ),
            const Spacer(),
            if (trailing != null)
              Text(
                trailing!,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.f65),
              ),
          ],
        ),
        const SizedBox(height: 10),
        QuestionTrail(index: index, total: total, marks: marks),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            QuestionMetaChips(subject: subject, topic: topic, year: year, extra: extra),
            if (official != null) SourceBadge(official: official!, year: year),
          ],
        ),
      ],
    );
  }
}

/// Trilha de progresso: um segmento por questão (verde acerto, vermelho erro,
/// cor primária na atual). Com mais de 30 questões vira barra contínua.
class QuestionTrail extends StatelessWidget {
  const QuestionTrail({required this.index, required this.total, this.marks = const [], super.key});

  final int index;
  final int total;
  final List<QuestionMark> marks;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pal = context.palette;
    if (total <= 0) return const SizedBox.shrink();
    if (total > 30) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: (index + 1) / total),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 6),
        ),
      );
    }
    Color colorFor(int i) {
      final m = i < marks.length ? marks[i] : QuestionMark.pending;
      switch (m) {
        case QuestionMark.correct:
          return pal.success;
        case QuestionMark.wrong:
          return cs.error;
        case QuestionMark.answered:
          return cs.primary.f55;
        case QuestionMark.pending:
          return i == index ? cs.primary : cs.surfaceContainerHighest;
      }
    }

    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              height: i == index ? 8 : 6,
              decoration: BoxDecoration(
                color: colorFor(i),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Selo "Oficial PAES 2023" ou "Treino" (questão criada para estudo).
class SourceBadge extends StatelessWidget {
  const SourceBadge({required this.official, this.year, super.key});

  final bool official;
  final int? year;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pal = context.palette;
    final fg = official ? pal.success : cs.tertiary;
    final label = official ? (year != null ? 'Oficial PAES $year' : 'Oficial PAES-UEMA') : 'Treino';
    return Tooltip(
      message: official
          ? 'Questão da prova oficial do PAES-UEMA'
          : 'Questão de treino (não é da prova oficial do PAES-UEMA)',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: fg.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: fg.withOpacity(0.35)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(official ? Icons.verified_rounded : Icons.fitness_center_rounded, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
        ]),
      ),
    );
  }
}

/// Cartão de leitura do enunciado: fundo próprio e faixa lateral na cor da disciplina.
class QuestionReadingCard extends StatelessWidget {
  const QuestionReadingCard({required this.child, this.subject, super.key});

  final Widget child;
  final String? subject;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = subjectVisual(subject).color;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.f60),
      ),
      clipBehavior: Clip.antiAlias,
      // Stack em vez de IntrinsicHeight: o IntrinsicHeight mede errado o
      // SelectableText e o enunciado longo estourava a caixa.
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 18, 22, 18),
            child: child,
          ),
          Positioned(left: 0, top: 0, bottom: 0, width: 5, child: ColoredBox(color: accent)),
        ],
      ),
    );
  }
}

/// Faixa grande de resultado logo após responder. Ao aparecer, rola a tela
/// até ela (senão ficava abaixo da dobra e o aluno não via o resultado).
class AnswerFeedbackBanner extends StatefulWidget {
  const AnswerFeedbackBanner({required this.correct, this.correctIndex, this.detail, this.child, super.key});

  final bool correct;
  final int? correctIndex;

  /// Linha menor abaixo do título (ex.: "Marque o tipo de erro para ver a explicação").
  final String? detail;

  /// Conteúdo extra dentro da faixa (ex.: `ErrorTypePicker`).
  final Widget? child;

  @override
  State<AnswerFeedbackBanner> createState() => _AnswerFeedbackBannerState();
}

class _AnswerFeedbackBannerState extends State<AnswerFeedbackBanner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final correct = widget.correct;
    final detail = widget.detail;
    final cs = Theme.of(context).colorScheme;
    final pal = context.palette;
    final ci = widget.correctIndex;
    final letter = ci != null && ci >= 0 && ci < 5 ? 'ABCDE'[ci] : null;
    final fg = correct ? pal.success : cs.error;
    final bg = correct ? pal.successContainer.f55 : cs.errorContainer.f40;
    final title = correct
        ? 'Mandou bem! Resposta certa.'
        : letter != null
            ? 'Não foi dessa vez. A resposta certa é a $letter.'
            : 'Não foi dessa vez.';
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: fg.withOpacity(0.45), width: 1.3),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
              child: Icon(
                correct ? Icons.check_rounded : Icons.close_rounded,
                color: correct ? pal.onSuccess : cs.onError,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: fg)),
                  if ((detail ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(detail!, style: TextStyle(fontSize: 13, color: cs.onSurface.f72)),
                  ],
                  if (widget.child != null) ...[
                    const SizedBox(height: 12),
                    widget.child!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra de ação fixa no rodapé da questão: dica à esquerda, botões à direita.
class QuestionActionBar extends StatelessWidget {
  const QuestionActionBar({
    required this.primary,
    this.secondary = const [],
    this.hint,
    this.maxWidth = kPageMaxWidth,
    super.key,
  });

  final Widget primary;
  final List<Widget> secondary;
  final String? hint;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant.f60)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Row(
            children: [
              if ((hint ?? '').isNotEmpty)
                Expanded(
                  child: Text(
                    hint!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: cs.onSurface.f60),
                  ),
                )
              else
                const Spacer(),
              for (final s in secondary) ...[s, const SizedBox(width: 8)],
              primary,
            ],
          ),
        ),
      ),
    );
  }
}

/// Diz se uma questão é da prova oficial (mesma regra em todas as telas).
bool isOfficialQuestion(Map<String, dynamic> q) {
  // O backend já calcula `isOfficial`; o resto é para dados antigos sem o campo.
  final flag = q['isOfficial'];
  if (flag is bool) return flag;
  final board = (q['examBoard'] ?? q['exam_board'] ?? '').toString().toUpperCase();
  if (board.isNotEmpty) return board == 'UEMA_PAES';
  final src = (q['source'] ?? '').toString().toLowerCase();
  return src.contains('pdf') || src == 'oficial';
}

/// Atalhos de teclado da questão: 1–5 ou A–E escolhem, Enter confirma, N avança.
/// Ignora as teclas quando o foco está num campo de texto.
class QuestionKeyHandler extends StatefulWidget {
  const QuestionKeyHandler({
    required this.child,
    required this.optionCount,
    this.onSelect,
    this.onEnter,
    this.onNext,
    super.key,
  });

  final Widget child;
  final int optionCount;

  /// null = alternativas travadas (já respondeu).
  final ValueChanged<int>? onSelect;
  final VoidCallback? onEnter;
  final VoidCallback? onNext;

  @override
  State<QuestionKeyHandler> createState() => _QuestionKeyHandlerState();
}

class _QuestionKeyHandlerState extends State<QuestionKeyHandler> {
  final _node = FocusNode(debugLabel: 'question-keys');

  static const _digits = [
    [LogicalKeyboardKey.digit1, LogicalKeyboardKey.numpad1, LogicalKeyboardKey.keyA],
    [LogicalKeyboardKey.digit2, LogicalKeyboardKey.numpad2, LogicalKeyboardKey.keyB],
    [LogicalKeyboardKey.digit3, LogicalKeyboardKey.numpad3, LogicalKeyboardKey.keyC],
    [LogicalKeyboardKey.digit4, LogicalKeyboardKey.numpad4, LogicalKeyboardKey.keyD],
    [LogicalKeyboardKey.digit5, LogicalKeyboardKey.numpad5, LogicalKeyboardKey.keyE],
  ];

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  bool get _typing {
    final ctx = FocusManager.instance.primaryFocus?.context;
    return ctx != null && ctx.widget is EditableText;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _typing) return KeyEventResult.ignored;
    if (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isAltPressed) {
      return KeyEventResult.ignored;
    }
    final k = event.logicalKey;
    // Alguns layouts (ex.: português internacional) e teclados virtuais mandam
    // só o caractere, sem a tecla lógica padrão — por isso olhamos os dois.
    final ch = (event.character ?? '').toLowerCase();
    if (widget.onSelect != null) {
      for (var i = 0; i < widget.optionCount && i < _digits.length; i++) {
        if (_digits[i].contains(k) || ch == '${i + 1}' || ch == 'abcde'[i]) {
          widget.onSelect!(i);
          return KeyEventResult.handled;
        }
      }
    }
    if ((k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) && widget.onEnter != null) {
      widget.onEnter!();
      return KeyEventResult.handled;
    }
    if ((k == LogicalKeyboardKey.keyN || ch == 'n') && widget.onNext != null) {
      widget.onNext!();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // Clicar em qualquer lugar da questão devolve o foco para os atalhos.
    return Focus(
      focusNode: _node,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          if (!_typing) _node.requestFocus();
        },
        child: widget.child,
      ),
    );
  }
}

/// "Por que você errou?" — chips numerados (as teclas 1–5 escolhem).
class ErrorTypePicker extends StatelessWidget {
  const ErrorTypePicker({required this.options, required this.value, required this.onChanged, super.key});

  /// chave → rótulo, na ordem das teclas 1, 2, 3…
  final Map<String, String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final entries = options.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Por que você errou?', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < entries.length; i++)
              ChoiceChip(
                label: Text('${i + 1}  ${entries[i].value}'),
                selected: value == entries[i].key,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  onChanged(entries[i].key);
                },
              ),
          ],
        ),
      ],
    );
  }
}
