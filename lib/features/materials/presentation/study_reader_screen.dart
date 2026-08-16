import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/api_client.dart';
import '../../ai_tutor/application/ai_tutor_controller.dart';
import '../../ai_tutor/domain/chat_message.dart';

// Conditional imports for web platform view
import 'study_reader_web.dart' if (dart.library.html) 'study_reader_web_html.dart';

// ---------------------------------------------------------------------------
// Tela de Estudo Integrada — Leitor + Tutor IA lado a lado
// ---------------------------------------------------------------------------

class StudyReaderScreen extends ConsumerStatefulWidget {
  const StudyReaderScreen({
    super.key,
    required this.pdfFilename,
    required this.title,
    required this.subject,
    this.topic = '',
  });

  final String pdfFilename;
  final String title;
  final String subject;
  final String topic;

  @override
  ConsumerState<StudyReaderScreen> createState() => _StudyReaderScreenState();
}

class _StudyReaderScreenState extends ConsumerState<StudyReaderScreen> {
  bool _tutorOpen = false;
  final _tutorController = TextEditingController();
  final _tutorScrollController = ScrollController();
  bool _seedApplied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedTutor());
  }

  void _seedTutor() {
    if (_seedApplied || !mounted) return;
    _seedApplied = true;
    // Pre-carrega o tutor com contexto do material
    final msg =
        'Estou estudando "${widget.title}" (${widget.subject}). Pode me ajudar a entender os pontos principais?';
    _tutorController.text = msg;
  }

  @override
  void dispose() {
    _tutorController.dispose();
    _tutorScrollController.dispose();
    super.dispose();
  }

  void _sendTutor() {
    final text = _tutorController.text.trim();
    if (text.isEmpty) return;
    ref.read(aiTutorControllerProvider.notifier).send(text);
    _tutorController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tutorScrollController.hasClients) {
        _tutorScrollController.animateTo(
          _tutorScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String get _pdfUrl {
    final base = apiClient.baseUrl;
    return '$base/api/materials/pdf/${widget.pdfFilename}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Chip(
            label: Text(widget.subject, style: const TextStyle(fontSize: 11)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              _tutorOpen ? Icons.chat_bubble : Icons.chat_bubble_outline,
              color: _tutorOpen ? cs.primary : null,
            ),
            tooltip: _tutorOpen ? 'Fechar tutor' : 'Abrir tutor IA',
            onPressed: () => setState(() => _tutorOpen = !_tutorOpen),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'download') {
                _openExternal();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'download', child: Text('Baixar PDF')),
            ],
          ),
        ],
      ),
      body: isWide ? _buildWideLayout(cs) : _buildNarrowLayout(cs),
    );
  }

  // Layout largo: PDF | Tutor lado a lado
  Widget _buildWideLayout(ColorScheme cs) {
    return Row(
      children: [
        // Leitor PDF
        Expanded(
          flex: _tutorOpen ? 3 : 5,
          child: _PdfViewer(url: _pdfUrl, filename: widget.pdfFilename),
        ),
        if (_tutorOpen) ...[
          Container(width: 1, color: cs.outlineVariant.withOpacity(0.3)),
          Expanded(
            flex: 2,
            child: _TutorPanel(
              controller: _tutorController,
              scrollController: _tutorScrollController,
              onSend: _sendTutor,
              onClose: () => setState(() => _tutorOpen = false),
              subject: widget.subject,
              topic: widget.topic,
            ),
          ),
        ],
      ],
    );
  }

  // Layout estreito: PDF em tela cheia, tutor como bottom sheet
  Widget _buildNarrowLayout(ColorScheme cs) {
    return Stack(
      children: [
        _PdfViewer(url: _pdfUrl, filename: widget.pdfFilename),
        if (_tutorOpen)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: Material(
              elevation: 8,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: _TutorPanel(
                controller: _tutorController,
                scrollController: _tutorScrollController,
                onSend: _sendTutor,
                onClose: () => setState(() => _tutorOpen = false),
                subject: widget.subject,
                topic: widget.topic,
              ),
            ),
          ),
        if (!_tutorOpen)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () => setState(() => _tutorOpen = true),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Tutor IA'),
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
            ),
          ),
      ],
    );
  }

  void _openExternal() async {
    // No desktop, usa o backend para abrir o PDF no visualizador do sistema
    if (!kIsWeb) {
      try {
        await apiClient.post('/api/materials/open-pdf?filename=${Uri.encodeComponent(widget.pdfFilename)}', {});
        return;
      } catch (_) {
        // Fallback: tenta url_launcher
      }
    }
    final uri = Uri.parse(_pdfUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

// ---------------------------------------------------------------------------
// Visualizador de PDF — usa iframe no web
// ---------------------------------------------------------------------------

class _PdfViewer extends StatefulWidget {
  const _PdfViewer({required this.url, this.filename});
  final String url;
  final String? filename;

  @override
  State<_PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<_PdfViewer> {
  String? _viewId;

  @override
  void initState() {
    super.initState();
    _setupView();
  }

  void _setupView() {
    if (kIsWeb) {
      _viewId = 'pdf-viewer-${DateTime.now().millisecondsSinceEpoch}';
      registerPdfView(_viewId!, widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && _viewId != null) {
      return HtmlElementView(viewType: _viewId!);
    }
    // Fallback para desktop/mobile: link para abrir
    return _PdfFallback(url: widget.url, filename: widget.filename);
  }
}

// Fallback para plataformas que nao suportam iframe
class _PdfFallback extends StatefulWidget {
  const _PdfFallback({required this.url, this.filename});
  final String url;
  final String? filename;

  @override
  State<_PdfFallback> createState() => _PdfFallbackState();
}

class _PdfFallbackState extends State<_PdfFallback> {
  bool _opening = false;
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    // Abre automaticamente no desktop
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPdf());
    }
  }

  void _openPdf() async {
    if (_opening || _opened) return;
    setState(() => _opening = true);
    try {
      if (!kIsWeb && widget.filename != null) {
        await apiClient.post('/api/materials/open-pdf?filename=${Uri.encodeComponent(widget.filename!)}', {});
      } else {
        final uri = Uri.parse(widget.url);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (mounted) setState(() { _opening = false; _opened = true; });
    } catch (_) {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cs.primaryContainer.withOpacity(0.15),
            cs.surface,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _opening
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : Icon(Icons.picture_as_pdf, size: 40, color: cs.primary),
              ),
              const SizedBox(height: 20),
              Text(
                _opened ? 'PDF aberto no visualizador' : 'Abrindo PDF...',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                _opened
                    ? 'Se não abriu, clique no botão abaixo'
                    : 'O PDF será aberto no seu visualizador padrão',
                style: TextStyle(color: cs.outline, fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _opening ? null : _openPdf,
                icon: const Icon(Icons.open_in_new),
                label: Text(_opened ? 'Abrir novamente' : 'Abrir PDF'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painel do Tutor IA — chat compacto lateral
// ---------------------------------------------------------------------------

class _TutorPanel extends ConsumerWidget {
  const _TutorPanel({
    required this.controller,
    required this.scrollController,
    required this.onSend,
    required this.onClose,
    required this.subject,
    required this.topic,
  });

  final TextEditingController controller;
  final ScrollController scrollController;
  final VoidCallback onSend;
  final VoidCallback onClose;
  final String subject;
  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(aiTutorControllerProvider);

    ref.listen(aiTutorControllerProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    return Container(
      color: cs.surface,
      child: Column(
        children: [
          // Header do tutor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.3),
              border: Border(bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.3))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: cs.primary,
                  radius: 16,
                  child: Icon(Icons.smart_toy, size: 18, color: cs.onPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tutor IA',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Estudando: $subject',
                        style: TextStyle(fontSize: 11, color: cs.outline),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClose,
                  tooltip: 'Fechar tutor',
                ),
              ],
            ),
          ),

          // Mensagens
          Expanded(
            child: state.messages.isEmpty
                ? _buildWelcome(cs)
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: state.messages.length,
                    itemBuilder: (context, i) => _ChatBubble(
                      message: state.messages[i],
                      isUser: state.messages[i].role == ChatRole.user,
                    ),
                  ),
          ),

          // Indicador de carregamento
          if (state.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                  ),
                  const SizedBox(width: 12),
                  Text('Tutor pensando...', style: TextStyle(fontSize: 12, color: cs.outline)),
                ],
              ),
            ),

          // Erro
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.error!,
                  style: TextStyle(fontSize: 12, color: cs.onErrorContainer),
                ),
              ),
            ),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: cs.outlineVariant.withOpacity(0.3))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: 'Pergunte sobre o material...',
                      hintStyle: TextStyle(fontSize: 13, color: cs.outline),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: cs.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: cs.primary, width: 1.5),
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: state.isLoading ? null : onSend,
                  icon: const Icon(Icons.send, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy, size: 48, color: cs.primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Tutor IA',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Pergunte sobre o que você está estudando.\nO tutor usa sua base de materiais PAES/UEMA.',
              style: TextStyle(fontSize: 13, color: cs.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                _SuggestionChip(
                  label: 'Explique os pontos principais',
                  onTap: () {
                    controller.text = 'Explique os pontos principais de "$subject - $topic".';
                    onSend();
                  },
                ),
                _SuggestionChip(
                  label: 'Faça um resumo',
                  onTap: () {
                    controller.text = 'Faça um resumo de "$subject - $topic".';
                    onSend();
                  },
                ),
                _SuggestionChip(
                  label: 'Quais pegadinhas?',
                  onTap: () {
                    controller.text = 'Quais são as principais pegadinhas de "$subject - $topic" na prova?';
                    onSend();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bolha de chat
// ---------------------------------------------------------------------------

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isUser});
  final ChatMessage message;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: cs.primary,
              radius: 14,
              child: Icon(Icons.smart_toy, size: 16, color: cs.onPrimary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isUser ? cs.onPrimary : cs.onSurface,
                    ),
                  ),
                  if (message.citations.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: [
                        for (final c in message.citations)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              c['title']?.toString() ?? c.toString(),
                              style: TextStyle(fontSize: 10, color: cs.onPrimaryContainer),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chip de sugestao
// ---------------------------------------------------------------------------

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ActionChip(
      label: Text(label, style: TextStyle(fontSize: 12)),
      onPressed: onTap,
      backgroundColor: cs.primaryContainer.withOpacity(0.3),
      side: BorderSide(color: cs.primary.withOpacity(0.2)),
    );
  }
}
