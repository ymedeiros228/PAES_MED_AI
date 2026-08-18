import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';

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
  });

  final String filename;
  final String title;
  final String subject;
  final double sizeKb;
  final String url;

  factory PdfItem.fromJson(Map<String, dynamic> j) => PdfItem(
        filename: j['filename'] ?? '',
        title: j['title'] ?? '',
        subject: j['subject'] ?? '',
        sizeKb: (j['size_kb'] ?? 0).toDouble(),
        url: j['url'] ?? '',
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Biblioteca', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPdfs,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de busca
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar material...',
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
          ),

          // Filtro de disciplina — chips horizontais
          if (!_loading && _error == null)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('Todas'),
                      selected: _selectedSubject == null,
                      onSelected: (_) => setState(() => _selectedSubject = null),
                    ),
                  ),
                  ..._availableSubjects.map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(s),
                        selected: _selectedSubject == s,
                        avatar: Icon(_subjectIcons[s] ?? Icons.book, size: 16),
                        onSelected: (_) => setState(() => _selectedSubject = s),
                      ),
                    );
                  }),
                ],
              ),
            ),

          // Conteudo
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorView(error: _error!, onRetry: _loadPdfs)
                    : _filteredPdfs.isEmpty
                        ? _EmptyView(hasPdfs: _allPdfs.isNotEmpty)
                        : _PdfGrid(pdfs: _filteredPdfs),
          ),
        ],
      ),
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
              // Icone PDF
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  color: cs.onPrimaryContainer,
                  size: 22,
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

// ---------------------------------------------------------------------------
// Estados: erro e vazio
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: cs.outline),
            const SizedBox(height: 12),
            Text('Erro ao carregar: $error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.hasPdfs});
  final bool hasPdfs;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hasPdfs ? Icons.search_off : Icons.picture_as_pdf, size: 64, color: cs.outline),
          const SizedBox(height: 16),
          Text(
            hasPdfs ? 'Nenhum material encontrado.' : 'Nenhum PDF disponível.',
            style: TextStyle(color: cs.outline),
          ),
        ],
      ),
    );
  }
}
