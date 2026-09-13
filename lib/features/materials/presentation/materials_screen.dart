import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
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
  });

  final String filename;
  final String title;
  final String subject;
  final double sizeKb;
  final String url;
  final String? coverUrl;

  factory PdfItem.fromJson(Map<String, dynamic> j) => PdfItem(
        filename: j['filename'] ?? '',
        title: j['title'] ?? '',
        subject: j['subject'] ?? '',
        sizeKb: (j['size_kb'] ?? 0).toDouble(),
        url: j['url'] ?? '',
        coverUrl: j['coverUrl']?.toString(),
      );
}

// ---------------------------------------------------------------------------
// Tela principal — Biblioteca de Materiais (apenas PDFs existentes)
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

  static const _subjectIcons = {
    'Biologia': Icons.biotech,
    'Química': Icons.science,
    'Física': Icons.speed,
    'Matemática': Icons.calculate,
    'Português': Icons.menu_book,
    'Inglês': Icons.language,
    'Espanhol': Icons.translate,
    'História': Icons.history_edu,
    'Geografia': Icons.public,
    'Filosofia': Icons.psychology,
    'Sociologia': Icons.groups,
  };

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
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = humanApiError(e);
        _loading = false;
      });
    }
  }

  List<PdfItem> get _filteredPdfs {
    var pdfs = _allPdfs;
    if (_selectedSubject != null) {
      pdfs = pdfs.where((p) => p.subject == _selectedSubject).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      pdfs = pdfs.where((p) => p.title.toLowerCase().contains(q) || p.subject.toLowerCase().contains(q)).toList();
    }
    return pdfs;
  }

  List<String> get _availableSubjects {
    final subjects = _allPdfs.map((p) => p.subject).toSet().toList();
    subjects.sort();
    return subjects;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filteredPdfs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageBody(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: 'Estudar',
                title: 'Materiais',
                subtitle: _loading
                    ? 'Carregando PDFs locais…'
                    : filtered.isEmpty
                        ? 'PDFs oficiais e de treino na pasta local'
                        : '${filtered.length} material(is) · toque em Estudar',
                icon: Icons.picture_as_pdf_rounded,
                trailing: IconButton(
                  tooltip: 'Atualizar',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _loadPdfs();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar material…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              if (!_loading && _error == null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('Todas'),
                          selected: _selectedSubject == null,
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedSubject = null);
                          },
                        ),
                      ),
                      ..._availableSubjects.map((s) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(s),
                            selected: _selectedSubject == s,
                            avatar: Icon(_subjectIcons[s] ?? Icons.book, size: 16),
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedSubject = s);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                  children: const [
                    SkeletonListTile(),
                    SizedBox(height: 8),
                    SkeletonListTile(),
                    SizedBox(height: 8),
                    SkeletonListTile(),
                    SizedBox(height: 8),
                    SkeletonListTile(),
                  ],
                )
              : _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(28),
                      child: QuietEmpty(
                        message: _error!,
                        action: FilledButton(
                          onPressed: _loadPdfs,
                          child: const Text('Tentar novamente'),
                        ),
                      ),
                    )
                  : filtered.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(28),
                          child: QuietEmpty(
                            message: _allPdfs.isNotEmpty
                                ? 'Nada neste filtro — limpe a busca ou escolha outra disciplina.'
                                : 'Nenhum PDF na pasta local. Gere ou copie materiais para data/materiais.',
                            action: _allPdfs.isNotEmpty
                                ? TextButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                        _selectedSubject = null;
                                      });
                                    },
                                    child: const Text('Limpar filtros'),
                                  )
                                : TextButton(
                                    onPressed: () => context.go('/biblioteca'),
                                    child: const Text('Biblioteca'),
                                  ),
                          ),
                        )
                      : _PdfGrid(pdfs: filtered),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Grid de PDFs
// ---------------------------------------------------------------------------

class _PdfGrid extends StatelessWidget {
  const _PdfGrid({required this.pdfs});
  final List<PdfItem> pdfs;

  @override
  Widget build(BuildContext context) {
    // Agrupa por disciplina
    final bySubject = <String, List<PdfItem>>{};
    for (final p in pdfs) {
      bySubject.putIfAbsent(p.subject, () => []).add(p);
    }
    final subjects = bySubject.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: subjects.length,
      itemBuilder: (context, i) {
        final subject = subjects[i];
        final items = bySubject[subject]!;
        return _SubjectSection(subject: subject, items: items);
      },
    );
  }
}

class _SubjectSection extends StatelessWidget {
  const _SubjectSection({required this.subject, required this.items});
  final String subject;
  final List<PdfItem> items;

  static const _icons = {
    'Biologia': Icons.biotech,
    'Química': Icons.science,
    'Física': Icons.speed,
    'Matemática': Icons.calculate,
    'Português': Icons.menu_book,
    'Inglês': Icons.language,
    'Espanhol': Icons.translate,
    'História': Icons.history_edu,
    'Geografia': Icons.public,
    'Filosofia': Icons.psychology,
    'Sociologia': Icons.groups,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final icon = _icons[subject] ?? Icons.book;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                subject,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${items.length}',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        ...items.map((pdf) => _PdfCard(pdf: pdf)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _PdfCard extends StatelessWidget {
  const _PdfCard({required this.pdf});
  final PdfItem pdf;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.go(Uri(path: '/estudar', queryParameters: {
            'pdf': pdf.filename,
            'title': pdf.title,
            'subject': pdf.subject,
          }).toString());
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Capa do material (ou ícone PDF)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 48,
                  height: 64,
                  child: pdf.coverUrl != null && pdf.coverUrl!.isNotEmpty
                      ? Image.network(
                          '${apiClient.baseUrl}${pdf.coverUrl}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => ColoredBox(
                            color: cs.primaryContainer,
                            child: Icon(
                              Icons.picture_as_pdf,
                              color: cs.onPrimaryContainer,
                              size: 22,
                            ),
                          ),
                        )
                      : ColoredBox(
                          color: cs.primaryContainer,
                          child: Icon(
                            Icons.picture_as_pdf,
                            color: cs.onPrimaryContainer,
                            size: 22,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              // Titulo + tamanho
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pdf.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(pdf.sizeKb / 1024).toStringAsFixed(1)} MB',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.outline,
                      ),
                    ),
                  ],
                ),
              ),
              // Botao Estudar
              FilledButton.tonal(
                onPressed: () {
                  context.go(Uri(path: '/estudar', queryParameters: {
                    'pdf': pdf.filename,
                    'title': pdf.title,
                    'subject': pdf.subject,
                  }).toString());
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.menu_book, size: 18),
                    SizedBox(width: 6),
                    Text('Estudar'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
