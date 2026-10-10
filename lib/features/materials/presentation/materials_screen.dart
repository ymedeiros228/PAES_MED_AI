import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/ui_kit.dart';

// ---------------------------------------------------------------------------
// Modelo
// ---------------------------------------------------------------------------

class PdfItem {
  PdfItem({
    required this.filename,
    required this.title,
    required this.subject,
    required this.sizeKb,
    required this.url,
    this.coverUrl,
    this.topic = '',
    this.hasContent = false,
  });

  final String filename;
  final String title;
  final String subject;
  final double sizeKb;
  final String url;
  final String? coverUrl;
  final String topic;

  /// O backend tem o texto estruturado (leitura dentro do app).
  final bool hasContent;

  factory PdfItem.fromJson(Map<String, dynamic> j) => PdfItem(
        filename: j['filename'] ?? '',
        title: j['title'] ?? '',
        subject: j['subject'] ?? '',
        sizeKb: (j['size_kb'] ?? 0).toDouble(),
        url: j['url'] ?? '',
        coverUrl: j['coverUrl']?.toString(),
        topic: (j['topic'] ?? '').toString(),
        hasContent: j['hasContent'] == true,
      );
}

// ---------------------------------------------------------------------------
// Tela principal — Materiais de estudo
// ---------------------------------------------------------------------------

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key, this.initialSubject});

  final String? initialSubject;

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  String? _selectedSubject;
  List<PdfItem> _allPdfs = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.initialSubject;
    _loadPdfs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPdfs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await apiClient.get('/api/materials/pdf-list');
      final list = (res as List).cast<Map<String, dynamic>>();
      _allPdfs = list.map((j) => PdfItem.fromJson(j)).toList();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = humanApiError(e);
          _loading = false;
        });
      }
    }
  }

  List<PdfItem> get _filteredPdfs {
    var pdfs = _allPdfs;
    if (_selectedSubject != null) {
      pdfs = pdfs.where((p) => p.subject == _selectedSubject).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      pdfs = pdfs
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.subject.toLowerCase().contains(q) ||
              p.topic.toLowerCase().contains(q))
          .toList();
    }
    return pdfs;
  }

  List<String> get _availableSubjects {
    final subjects = _allPdfs.map((p) => p.subject).toSet().toList();
    subjects.sort();
    return subjects;
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedSubject = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPdfs;

    Widget body;
    if (_loading) {
      body = const SkeletonList(count: 5);
    } else if (_error != null) {
      body = ErrorState(message: _error!, onRetry: _loadPdfs);
    } else if (filtered.isEmpty) {
      body = EmptyState(
        icon: Icons.menu_book_rounded,
        title: _allPdfs.isNotEmpty ? 'Nada encontrado' : 'Nenhum material ainda',
        subtitle: _allPdfs.isNotEmpty
            ? 'Limpe a busca ou escolha outra disciplina.'
            : 'Os materiais de estudo aparecem aqui quando estiverem na pasta do app.',
        actionLabel: _allPdfs.isNotEmpty ? 'Limpar filtros' : null,
        onAction: _allPdfs.isNotEmpty ? _clearFilters : null,
      );
    } else {
      body = _SubjectSections(pdfs: filtered);
    }

    return PageScaffold(
      eyebrow: 'Estudar',
      title: 'Materiais',
      subtitle: _loading
          ? 'Carregando seus materiais…'
          : '${_allPdfs.length} materiais de estudo · escolha um e toque em Estudar',
      icon: Icons.menu_book_rounded,
      actions: [
        AppButton.tertiary(
          label: 'Atualizar',
          icon: Icons.refresh_rounded,
          onPressed: () {
            HapticFeedback.selectionClick();
            _loadPdfs();
          },
        ),
      ],
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar material…',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    tooltip: 'Limpar busca',
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
        if (!_loading && _error == null) ...[
          const SizedBox(height: kGap12),
          // Wrap: as disciplinas quebram de linha em vez de serem cortadas.
          Wrap(
            spacing: kGap8,
            runSpacing: kGap8,
            children: [
              AppChip(
                label: 'Todas',
                selected: _selectedSubject == null,
                onTap: () => setState(() => _selectedSubject = null),
              ),
              for (final s in _availableSubjects)
                AppChip(
                  label: s,
                  icon: subjectStyle(s).icon,
                  selected: _selectedSubject == s,
                  onTap: () => setState(() => _selectedSubject = s),
                ),
            ],
          ),
        ],
        const SizedBox(height: kGap20),
        body,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Seções por disciplina
// ---------------------------------------------------------------------------

class _SubjectSections extends StatelessWidget {
  const _SubjectSections({required this.pdfs});
  final List<PdfItem> pdfs;

  @override
  Widget build(BuildContext context) {
    final bySubject = <String, List<PdfItem>>{};
    for (final p in pdfs) {
      bySubject.putIfAbsent(p.subject, () => []).add(p);
    }
    final subjects = bySubject.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final subject in subjects) ...[
          SectionHeader(
            title: '$subject · ${bySubject[subject]!.length}',
            icon: subjectStyle(subject).icon,
          ),
          const SizedBox(height: kGap8),
          for (final pdf in bySubject[subject]!) _PdfCard(pdf: pdf),
          const SizedBox(height: kGap16),
        ],
      ],
    );
  }
}

void _openStudy(BuildContext context, PdfItem pdf) {
  context.go(Uri(path: '/estudar', queryParameters: {
    'pdf': pdf.filename,
    'title': pdf.title,
    'subject': pdf.subject,
    if (pdf.topic.isNotEmpty) 'topic': pdf.topic,
  }).toString());
}

class _PdfCard extends StatelessWidget {
  const _PdfCard({required this.pdf});
  final PdfItem pdf;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = subjectStyle(pdf.subject);
    final hasCover = pdf.coverUrl != null && pdf.coverUrl!.isNotEmpty;
    // Capa repetida/genérica já vem sem URL do backend: cartão da disciplina.
    final fallback = ColoredBox(
      color: style.color.withOpacity(0.16),
      child: Icon(style.icon, color: style.color, size: 26),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: kGap8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: kGap16, vertical: kGap12),
        onTap: () => _openStudy(context, pdf),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 48,
                height: 64,
                child: hasCover
                    ? Image.network(
                        '${apiClient.baseUrl}${pdf.coverUrl}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => fallback,
                      )
                    : fallback,
              ),
            ),
            const SizedBox(width: kGap16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pdf.title,
                    style: context.text.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: kGap4),
                  Text(
                    pdf.topic.isNotEmpty && pdf.topic != pdf.title
                        ? '${pdf.subject} · ${pdf.topic}'
                        : pdf.subject,
                    style: context.text.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: kGap12),
            AppButton.tonal(
              label: 'Estudar',
              icon: Icons.menu_book,
              size: AppButtonSize.small,
              onPressed: () => _openStudy(context, pdf),
            ),
          ],
        ),
      ),
    );
  }
}
