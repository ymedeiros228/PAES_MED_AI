import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'layout_tokens.dart';
import 'subject_style.dart';

/// Enunciado de questão em parágrafos legíveis (texto selecionável).
/// Detecta mudança de parágrafo (ponto final + maiúscula) e espaça.
class StatementView extends StatelessWidget {
  const StatementView({
    required this.text,
    this.maxLines,
    this.framed = true,
    super.key,
  });

  final String text;
  final int? maxLines;

  /// false = sem fundo/borda próprios (quando já está dentro de um cartão).
  final bool framed;

  /// Divide o texto em parágrafos por pontos finais seguidos de maiúscula.
  /// Preserva citações e abreviações comuns (Sr., Dr., etc.).
  List<String> _splitParagraphs(String raw) {
    if (raw.isEmpty) return [raw];
    // Adiciona \n\n após ponto final seguido de espaço + maiúscula
    // Mas não após abreviações comuns
    final abbr = RegExp(
      r'\b(?:Sr|Sra|Dr|Dra|Prof|Profa|Art|Ed|Ex|p|pp|vol|fig|tab|al|cf|op|cit)\.\s*$',
      caseSensitive: false,
    );
    final paragraphBreak = RegExp(r'(?<=[.!?])\s+(?=[A-ZÀ-Ý""\[])');
    final parts = raw.split(paragraphBreak);
    // Filtra abreviações: se o parágrafo anterior termina com abreviação,
    // junta com o próximo
    final merged = <String>[];
    for (var i = 0; i < parts.length; i++) {
      if (merged.isNotEmpty && abbr.hasMatch(merged.last.trim())) {
        merged[merged.length - 1] = '${merged.last} ${parts[i]}';
      } else {
        merged.add(parts[i]);
      }
    }
    return merged.where((p) => p.trim().isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final paragraphs = _splitParagraphs(text);

    // Mesma fonte do app, corpo de leitura 16.5 com entrelinha 1.6
    final statementStyle = TextStyle(
      fontSize: 16.5,
      height: 1.6,
      color: cs.onSurface,
    );

    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kReadingMaxWidth),
        child: _card(cs, paragraphs, statementStyle),
      ),
    );
  }

  Widget _card(ColorScheme cs, List<String> paragraphs, TextStyle statementStyle) {
    if (paragraphs.length <= 1) {
      // Texto curto: SelectableText simples em container
      return Container(
        width: double.infinity,
        padding: framed ? const EdgeInsets.symmetric(horizontal: 22, vertical: 20) : EdgeInsets.zero,
        decoration: framed
            ? BoxDecoration(
                color: cs.surfaceContainerHigh.f38,
                borderRadius: BorderRadius.circular(kRadiusPanel),
                border: Border.all(color: cs.outlineVariant.f38),
              )
            : null,
        child: SelectableText(
          text,
          style: statementStyle,
          contextMenuBuilder: (context, editableTextState) =>
              AdaptiveTextSelectionToolbar.editableText(
            editableTextState: editableTextState,
          ),
        ),
      );
    }

    // Múltiplos parágrafos: container com cada parágrafo separado
    return Container(
      width: double.infinity,
      padding: framed ? const EdgeInsets.symmetric(horizontal: 22, vertical: 20) : EdgeInsets.zero,
      decoration: framed
          ? BoxDecoration(
              color: cs.surfaceContainerHigh.f38,
              borderRadius: BorderRadius.circular(kRadiusPanel),
              border: Border.all(color: cs.outlineVariant.f38),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < paragraphs.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            SelectableText(
              paragraphs[i],
              style: statementStyle,
              contextMenuBuilder: (context, editableTextState) =>
                  AdaptiveTextSelectionToolbar.editableText(
                editableTextState: editableTextState,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chips de contexto da questão: disciplina (cor própria), tópico e ano.
class QuestionMetaChips extends StatelessWidget {
  const QuestionMetaChips({
    required this.subject,
    this.topic,
    this.year,
    this.extra,
    super.key,
  });

  final String subject;
  final String? topic;
  final int? year;
  final String? extra;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final v = subjectVisual(subject);
    Widget pill(String text, Color bg, Color fg, {IconData? icon}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 5)],
            Flexible(
              child: Text(text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
            ),
          ]),
        );
    return Wrap(spacing: 8, runSpacing: 6, children: [
      if (subject.isNotEmpty) pill(subject, v.soft, v.color, icon: v.icon),
      if ((topic ?? '').isNotEmpty)
        pill(topic!, cs.surfaceContainerHigh, cs.onSurfaceVariant),
      if (year != null) pill('$year', cs.surfaceContainerHigh, cs.onSurfaceVariant),
      if ((extra ?? '').isNotEmpty) pill(extra!, cs.surfaceContainerHigh, cs.onSurfaceVariant),
    ]);
  }
}
