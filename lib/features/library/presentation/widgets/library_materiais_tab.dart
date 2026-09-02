import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

/// Tab Materiais — estante enxuta de PDFs de estudo.
class LibraryMateriaisTab extends StatelessWidget {
  const LibraryMateriaisTab({
    required this.pdfsLoaded,
    required this.pdfs,
    super.key,
  });

  final bool pdfsLoaded;
  final List<Map<String, dynamic>> pdfs;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!pdfsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (pdfs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.picture_as_pdf_outlined, size: 56, color: cs.outline),
              const SizedBox(height: 16),
              Text('Nenhum PDF disponível.', style: TextStyle(color: cs.outline, fontSize: 15)),
              const SizedBox(height: 8),
              Text(
                'Os materiais de estudo aparecem aqui automaticamente.',
                style: TextStyle(color: cs.outline.withOpacity(0.6), fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return _MateriaisShelf(pdfs: pdfs);
  }
}

class _MateriaisShelf extends StatefulWidget {
  const _MateriaisShelf({required this.pdfs});
  final List<Map<String, dynamic>> pdfs;

  @override
  State<_MateriaisShelf> createState() => _MateriaisShelfState();
}

class _MateriaisShelfState extends State<_MateriaisShelf> {
  String? _selectedSubject;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    var pdfs = widget.pdfs;
    if (_selectedSubject != null) {
      pdfs = pdfs.where((p) => (p['subject'] ?? '') == _selectedSubject).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      pdfs = pdfs.where((p) {
        final title = (p['title'] ?? '').toString().toLowerCase();
        final subj = (p['subject'] ?? '').toString().toLowerCase();
        return title.contains(q) || subj.contains(q);
      }).toList();
    }
    return pdfs;
  }

  List<String> get _subjects {
    final s = widget.pdfs.map((p) => (p['subject'] ?? 'Outros').toString()).toSet().toList();
    s.sort();
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filtered;
    final totalPdfs = widget.pdfs.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.collections_bookmark_rounded, size: 22, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Materiais de Estudo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface),
                  ),
                  Text(
                    '$totalPdfs PDFs em ${_subjects.length} disciplinas',
                    style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Buscar material...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: const Text('Todas'),
                  selected: _selectedSubject == null,
                  onSelected: (_) => setState(() => _selectedSubject = null),
                ),
              ),
              ..._subjects.map((s) {
                final style = subjectStyle(s);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(s),
                    selected: _selectedSubject == s,
                    avatar: Icon(style.icon, size: 14),
                    onSelected: (_) => setState(() => _selectedSubject = s),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 48, color: cs.outline),
                  const SizedBox(height: 12),
                  Text('Nenhum material encontrado.', style: TextStyle(color: cs.outline)),
                ],
              ),
            ),
          )
        else
          ...filtered.map((pdf) => _MateriaisPdfCard(pdf: pdf)),
      ],
    );
  }
}

class _MateriaisPdfCard extends StatelessWidget {
  const _MateriaisPdfCard({required this.pdf});
  final Map<String, dynamic> pdf;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = pdf['title']?.toString() ?? 'Material';
    final subject = pdf['subject']?.toString() ?? 'Outros';
    final filename = pdf['filename']?.toString() ?? '';
    final sizeKb = (pdf['size_kb'] as num?)?.toDouble() ?? 0;
    final sizeStr = sizeKb > 1024 ? '${(sizeKb / 1024).toStringAsFixed(1)} MB' : '${sizeKb.round()} KB';
    final icon = subjectStyle(subject).icon;

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
          HapticFeedback.selectionClick();
          context.go(Uri(path: '/estudar', queryParameters: {
            'pdf': filename,
            'title': title,
            'subject': subject,
          }).toString());
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: cs.onPrimaryContainer, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(subject, style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 8),
                        Text(sizeStr, style: TextStyle(fontSize: 11, color: cs.outline.withOpacity(0.5))),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: cs.outline.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
