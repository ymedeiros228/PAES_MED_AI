import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../theme/app_theme.dart';
import 'layout_tokens.dart';
import 'subject_style.dart';

/// Enunciado de questão em parágrafos legíveis (texto selecionável).
/// Detecta mudança de parágrafo (ponto final + maiúscula) e espaça.
/// Questão oficial importada da prova já vem em blocos (linha em branco entre eles),
/// com figuras `[[img:figuras/...]]`, tabelas markdown e créditos "Fonte: ...";
/// nesse caso o texto de apoio ([passage]) aparece antes, recolhível.
class StatementView extends StatelessWidget {
  const StatementView({
    required this.text,
    this.passage,
    this.maxLines,
    this.framed = true,
    super.key,
  });

  final String text;
  final String? passage;
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
    final apoio = passage?.trim() ?? '';
    if (apoio.isNotEmpty || _estruturado(text)) {
      return Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kReadingMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (apoio.isNotEmpty) ...[
                _TextoDeApoio(texto: apoio),
                const SizedBox(height: 18),
              ],
              _BlocosDoTexto(texto: text),
            ],
          ),
        ),
      );
    }
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

bool _estruturado(String t) => t.contains('[[img:') || t.contains('\n\n') || t.contains('\n|');

/// Texto de apoio da questão oficial (o "Texto I" da prova), aberto por padrão.
class _TextoDeApoio extends StatefulWidget {
  const _TextoDeApoio({required this.texto});

  final String texto;

  @override
  State<_TextoDeApoio> createState() => _TextoDeApoioState();
}

class _TextoDeApoioState extends State<_TextoDeApoio> {
  bool _aberto = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.f38,
        borderRadius: BorderRadius.circular(kRadiusPanel),
        border: Border.all(color: cs.outlineVariant.f38),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(kRadiusPanel),
            onTap: () => setState(() => _aberto = !_aberto),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(children: [
                Icon(Icons.menu_book_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Texto de apoio',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: cs.primary)),
                ),
                Icon(_aberto ? Icons.expand_less : Icons.expand_more, color: cs.onSurfaceVariant),
              ]),
            ),
          ),
          if (_aberto)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _BlocosDoTexto(texto: widget.texto, tamanho: 15.5),
            ),
        ],
      ),
    );
  }
}

/// Blocos separados por linha em branco: parágrafo, figura, tabela ou crédito.
/// Quebra de linha simples dentro do bloco é mantida (versos de poema, listas).
class _BlocosDoTexto extends StatelessWidget {
  const _BlocosDoTexto({required this.texto, this.tamanho = 16.5});

  final String texto;
  final double tamanho;

  static final _img = RegExp(r'\[\[img:([^\]]+)\]\]');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final corpo = TextStyle(fontSize: tamanho, height: 1.6, color: cs.onSurface);
    final blocos = <Widget>[];
    // figura no meio do parágrafo também vira bloco próprio
    final normalizado = texto.replaceAllMapped(_img, (m) => '\n\n${m[0]}\n\n');
    for (final bruto in normalizado.split(RegExp(r'\n\s*\n'))) {
      final b = bruto.trim();
      if (b.isEmpty) continue;
      final img = _img.firstMatch(b);
      if (img != null && img[0] == b) {
        blocos.add(_FiguraDaProva(caminho: img[1]!));
      } else if (b.startsWith('|')) {
        blocos.add(_TabelaMarkdown(texto: b, tamanho: tamanho - 1.5));
      } else if (b.split('\n').every((l) => l.startsWith('Fonte:'))) {
        blocos.add(SelectableText(
          b,
          style: TextStyle(fontSize: 12, height: 1.4, color: cs.onSurfaceVariant, fontStyle: FontStyle.italic),
        ));
      } else {
        blocos.add(SelectableText(b, style: corpo));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocos.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          blocos[i],
        ],
      ],
    );
  }
}

/// Figura recortada da prova original (WebP em /data/figuras). Toque amplia.
class _FiguraDaProva extends StatelessWidget {
  const _FiguraDaProva({required this.caminho});

  final String caminho;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = '${apiClient.baseUrl}/data/$caminho';
    Widget imagem() => Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progresso) => progresso == null
              ? child
              : const SizedBox(height: 160, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          errorBuilder: (context, _, __) => Container(
            height: 90,
            alignment: Alignment.center,
            color: cs.surfaceContainerHighest,
            child: Text('Figura indisponível', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          ),
        );
    return Center(
      child: GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) => Dialog(
            insetPadding: const EdgeInsets.all(12),
            backgroundColor: Colors.white,
            child: Stack(children: [
              InteractiveViewer(maxScale: 5, child: Padding(padding: const EdgeInsets.all(8), child: imagem())),
              Positioned(
                right: 4,
                top: 4,
                child: IconButton.filledTonal(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
            ]),
          ),
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.zoomIn,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              // fundo branco: figura de prova é feita para papel, inclusive no tema escuro
              child: ColoredBox(color: Colors.white, child: imagem()),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tabela em markdown (| a | b |) vinda da prova; rola na horizontal no celular.
class _TabelaMarkdown extends StatelessWidget {
  const _TabelaMarkdown({required this.texto, required this.tamanho});

  final String texto;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final linhas = texto
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.startsWith('|') && !RegExp(r'^\|[\s:|-]+\|?$').hasMatch(l))
        .map((l) {
      var c = l.substring(1);
      if (c.endsWith('|')) c = c.substring(0, c.length - 1);
      return c.split('|').map((x) => x.trim()).toList();
    }).toList();
    if (linhas.isEmpty) return const SizedBox.shrink();
    final colunas = linhas.map((l) => l.length).reduce((a, b) => a > b ? a : b);
    final borda = BorderSide(color: cs.outlineVariant);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder(
          top: borda,
          bottom: borda,
          left: borda,
          right: borda,
          horizontalInside: borda,
          verticalInside: borda,
        ),
        children: [
          for (var r = 0; r < linhas.length; r++)
            TableRow(
              decoration: r == 0 ? BoxDecoration(color: cs.surfaceContainerHighest) : null,
              children: [
                for (var c = 0; c < colunas; c++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: Text(
                        c < linhas[r].length ? linhas[r][c] : '',
                        style: TextStyle(
                          fontSize: tamanho,
                          height: 1.4,
                          color: cs.onSurface,
                          fontWeight: r == 0 ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
