import 'package:flutter/material.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui_kit.dart';

/// Leitura do material DENTRO do app: renderiza o `content_json` estruturado
/// (título, introdução, seções, resumo, dicas, pegadinhas) com tipografia de leitura.
///
/// Se o material não tiver texto estruturado, chama [fallback] (abre o PDF).
class MaterialReaderView extends StatefulWidget {
  const MaterialReaderView({
    super.key,
    required this.pdfFilename,
    required this.fallback,
    required this.onOpenPdf,
    this.subject = '',
  });

  final String subject;
  final String pdfFilename;
  final Widget fallback;
  final VoidCallback onOpenPdf;

  @override
  State<MaterialReaderView> createState() => _MaterialReaderViewState();
}

class _MaterialReaderViewState extends State<MaterialReaderView> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _content;
  List<Map<String, dynamic>> _images = const [];
  bool _semTexto = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _semTexto = false;
    });
    try {
      final res = await apiClient.get(
          '/api/materials/by-pdf/${Uri.encodeComponent(widget.pdfFilename)}');
      final map = (res as Map).cast<String, dynamic>();
      final content = map['content'];
      final images = map['images'];
      if (!mounted) return;
      final c = content is Map ? content.cast<String, dynamic>() : null;
      final vazio = c == null ||
          (c['secoes'] is! List || (c['secoes'] as List).isEmpty) &&
              ((c['introducao'] ?? '').toString().trim().isEmpty);
      setState(() {
        _content = c;
        _images = images is List
            ? images.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
            : const [];
        _semTexto = vazio;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = humanApiError(e);
      // 404 = sem texto estruturado para esse PDF: cai para o PDF.
      final semMaterial = msg.toLowerCase().contains('não encontrado') ||
          msg.contains('404');
      setState(() {
        _loading = false;
        if (semMaterial) {
          _semTexto = true;
        } else {
          _error = msg;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(kGap24),
        child: SkeletonList(count: 4, lines: 3),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kGap24),
          child: ErrorState(
            message: _error!,
            onRetry: _load,
            secondary: AppButton.secondary(
              label: 'Abrir PDF original',
              icon: Icons.picture_as_pdf_rounded,
              onPressed: widget.onOpenPdf,
            ),
          ),
        ),
      );
    }
    if (_semTexto || _content == null) return widget.fallback;
    return _ReaderContent(
      content: _content!,
      images: _images,
      onOpenPdf: widget.onOpenPdf,
      subject: widget.subject,
    );
  }
}

class _ReaderContent extends StatefulWidget {
  const _ReaderContent({
    required this.content,
    required this.images,
    required this.onOpenPdf,
    required this.subject,
  });

  final String subject;
  final Map<String, dynamic> content;
  final List<Map<String, dynamic>> images;
  final VoidCallback onOpenPdf;

  @override
  State<_ReaderContent> createState() => _ReaderContentState();
}

class _ReaderContentState extends State<_ReaderContent> {
  final _scroll = ScrollController();
  final _keys = <GlobalKey>[];
  double _progresso = 0;

  Map<String, dynamic> get content => widget.content;
  List<Map<String, dynamic>> get images => widget.images;
  VoidCallback get onOpenPdf => widget.onOpenPdf;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      final v = max <= 0 ? 0.0 : (_scroll.offset / max).clamp(0.0, 1.0);
      if ((v - _progresso).abs() > 0.005) setState(() => _progresso = v);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _irPara(int i) {
    final ctx = _keys[i].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  /// Tempo estimado de leitura (cerca de 180 palavras por minuto).
  int _minutos() {
    final texto = StringBuffer('${content['introducao'] ?? ''}');
    for (final sec in (content['secoes'] as List? ?? const [])) {
      if (sec is Map) texto.write(' ${sec['conteudo'] ?? ''} ${sec['exemplo'] ?? ''}');
    }
    final palavras = texto.toString().split(RegExp(r'\s+')).length;
    return (palavras / 180).ceil().clamp(1, 99);
  }

  List<String> _lista(dynamic v) {
    if (v is! List) return const [];
    return v
        .map((e) {
          if (e is Map) {
            return (e['texto'] ?? e['titulo'] ?? e.values.join(' — ')).toString();
          }
          return e.toString();
        })
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final titulo = (content['titulo'] ?? '').toString();
    final intro = (content['introducao'] ?? '').toString();
    final secoes = content['secoes'] is List
        ? (content['secoes'] as List).whereType<Map>().toList()
        : <Map>[];
    final resumo = (content['resumo'] ?? '').toString();
    final dicas = _lista(content['dicas']);
    final pegadinhas = _lista(content['pegadinhas']);
    final relacionado = _lista(content['relacionado']);

    while (_keys.length < secoes.length) {
      _keys.add(GlobalKey());
    }
    final estilo = subjectStyle(widget.subject);
    return LayoutBuilder(
      builder: (context, k) {
        final largo = k.maxWidth > 1100;
        final leitura = SelectionArea(
          child: ListView(
            controller: _scroll,
            padding: PageInsets.of(largo ? k.maxWidth - 280 : k.maxWidth,
                maxWidth: kReadingMaxWidth + 120),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: kReadingMaxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(kGap20),
                        decoration: BoxDecoration(
                          color: estilo.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(estilo.icon, color: estilo.color, size: 40),
                            const SizedBox(width: kGap16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.subject.isNotEmpty)
                                    Text(widget.subject,
                                        style: context.text.labelLarge
                                            ?.copyWith(color: estilo.color)),
                                  if (titulo.isNotEmpty)
                                    Text(titulo, style: context.text.headlineSmall),
                                  Text('Leitura de ${_minutos()} min',
                                      style: context.text.bodySmall?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant)),
                                ],
                              ),
                            ),
                            const SizedBox(width: kGap12),
                            AppButton.secondary(
                              label: 'Abrir PDF original',
                              icon: Icons.picture_as_pdf_rounded,
                              size: AppButtonSize.small,
                              onPressed: onOpenPdf,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: kGap20),
                      if (intro.trim().isNotEmpty) ..._blocos(context, intro, lead: true),
                      if (images.isNotEmpty) ...[
                        const SizedBox(height: kGap16),
                        for (final img in images) _Imagem(img: img),
                      ],
                      for (var i = 0; i < secoes.length; i++) ...[
                        const SizedBox(height: kGap24),
                        Text(
                          (secoes[i]['titulo'] ?? 'Seção ${i + 1}').toString(),
                          key: _keys[i],
                          style: context.text.titleLarge,
                        ),
                        const SizedBox(height: kGap8),
                        ..._blocos(context, (secoes[i]['conteudo'] ?? '').toString()),
                        if ((secoes[i]['exemplo'] ?? '').toString().trim().isNotEmpty)
                          _Destaque(
                            titulo: 'Exemplo',
                            icon: Icons.lightbulb_outline_rounded,
                            tone: AppTone.info,
                            itens: [(secoes[i]['exemplo']).toString()],
                          ),
                      ],
                      if (resumo.trim().isNotEmpty)
                        _Destaque(
                          titulo: 'Resumo',
                          icon: Icons.summarize_rounded,
                          tone: AppTone.primary,
                          itens: [resumo],
                        ),
                      if (dicas.isNotEmpty)
                        _Destaque(
                          titulo: 'Dicas de prova',
                          icon: Icons.tips_and_updates_rounded,
                          tone: AppTone.success,
                          itens: dicas,
                        ),
                      if (pegadinhas.isNotEmpty)
                        _Destaque(
                          titulo: 'Cuidado com as pegadinhas',
                          icon: Icons.warning_amber_rounded,
                          tone: AppTone.warning,
                          itens: pegadinhas,
                        ),
                      if (relacionado.isNotEmpty) ...[
                        const SizedBox(height: kGap24),
                        Text('Assuntos relacionados', style: context.text.titleMedium),
                        const SizedBox(height: kGap8),
                        Wrap(
                          spacing: kGap8,
                          runSpacing: kGap8,
                          children: [for (final r in relacionado) AppChip(label: r)],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
        final barra = LinearProgressIndicator(
          value: _progresso,
          minHeight: 3,
          color: estilo.color,
          backgroundColor: Colors.transparent,
        );
        final sumario = SizedBox(
          width: 280,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(kGap8, kGap24, kGap16, kGap24),
            children: [
              Text('Nesta aula', style: context.text.titleSmall),
              const SizedBox(height: kGap8),
              for (var i = 0; i < secoes.length; i++)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _irPara(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: Text(
                      (secoes[i]['titulo'] ?? 'Seção ${i + 1}').toString(),
                      style: context.text.bodyMedium,
                    ),
                  ),
                ),
            ],
          ),
        );
        return Column(
          children: [
            barra,
            Expanded(
              child: largo && secoes.length > 1
                  ? Row(children: [Expanded(child: leitura), sumario])
                  : leitura,
            ),
          ],
        );
      },
    );
  }

  /// Quebra o texto em parágrafos, listas e subtítulos (linhas em CAIXA ALTA com ":").
  List<Widget> _blocos(BuildContext context, String texto, {bool lead = false}) {
    final cs = Theme.of(context).colorScheme;
    final base = (lead ? context.text.titleMedium : context.text.bodyLarge)
        ?.copyWith(height: 1.65, color: cs.onSurface);
    final widgets = <Widget>[];
    final numerada = RegExp(r'^(\d+[\.\)])\s+(.*)$');
    for (final bruta in texto.split('\n')) {
      final linha = bruta.trim();
      if (linha.isEmpty) {
        widgets.add(const SizedBox(height: kGap8));
        continue;
      }
      final marcador = RegExp(r'^[-•*]\s+(.*)$').firstMatch(linha);
      final num = numerada.firstMatch(linha);
      if (marcador != null) {
        widgets.add(_Item(simbolo: '•', texto: marcador.group(1)!, estilo: base));
      } else if (num != null) {
        widgets.add(_Item(simbolo: num.group(1)!, texto: num.group(2)!, estilo: base));
      } else if (_ehSubtitulo(linha)) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: kGap12, bottom: kGap4),
          child: Text(_capitalizar(linha.replaceAll(RegExp(r':$'), '')),
              style: context.text.titleSmall?.copyWith(color: cs.primary)),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: kGap4),
          child: Text(linha, style: base),
        ));
      }
    }
    return widgets;
  }

  bool _ehSubtitulo(String s) {
    if (!s.endsWith(':') || s.length > 60) return false;
    final letras = s.replaceAll(RegExp(r'[^A-Za-zÀ-ú]'), '');
    return letras.isNotEmpty && letras == letras.toUpperCase();
  }

  String _capitalizar(String s) {
    final t = s.toLowerCase();
    return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.simbolo, required this.texto, this.estilo});
  final String simbolo;
  final String texto;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: kGap8, bottom: kGap4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 28, child: Text(simbolo, style: estilo)),
          Expanded(child: Text(texto, style: estilo)),
        ],
      ),
    );
  }
}

class _Destaque extends StatelessWidget {
  const _Destaque({
    required this.titulo,
    required this.icon,
    required this.tone,
    required this.itens,
  });
  final String titulo;
  final IconData icon;
  final AppTone tone;
  final List<String> itens;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: kGap20),
      child: AppCard(
        title: titulo,
        icon: icon,
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final i in itens)
              Padding(
                padding: const EdgeInsets.only(bottom: kGap8),
                child: Text(i,
                    style: context.text.bodyLarge?.copyWith(height: 1.6)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Imagem extends StatelessWidget {
  const _Imagem({required this.img});
  final Map<String, dynamic> img;

  @override
  Widget build(BuildContext context) {
    final url = (img['url'] ?? img['thumbnail'] ?? '').toString();
    if (url.isEmpty) return const SizedBox.shrink();
    final legenda = (img['caption'] ?? img['legenda'] ?? img['title'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: kGap16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url.startsWith('http') ? url : '${apiClient.baseUrl}$url',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          if (legenda.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: kGap4),
              child: Text(legenda,
                  style: context.text.bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }
}
