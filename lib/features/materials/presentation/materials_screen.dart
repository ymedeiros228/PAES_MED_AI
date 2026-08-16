import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';

// ---------------------------------------------------------------------------
// Modelos
// ---------------------------------------------------------------------------

class SyllabusEntry {
  SyllabusEntry({
    required this.id,
    required this.subject,
    required this.topic,
    required this.subtopic,
    required this.weight,
    required this.hasMaterial,
    this.materialTitle,
  });

  final String id;
  final String subject;
  final String topic;
  final String subtopic;
  final double weight;
  final bool hasMaterial;
  final String? materialTitle;

  factory SyllabusEntry.fromJson(Map<String, dynamic> j) => SyllabusEntry(
        id: j['id'] ?? '',
        subject: j['subject'] ?? '',
        topic: j['topic'] ?? '',
        subtopic: j['subtopic'] ?? '',
        weight: (j['weight'] ?? 1.0).toDouble(),
        hasMaterial: (j['has_material'] ?? 0) == 1,
        materialTitle: j['material_title'],
      );
}

class StudyMaterial {
  StudyMaterial({
    required this.id,
    required this.subject,
    required this.topic,
    required this.subtopic,
    required this.title,
    required this.content,
    required this.images,
    this.wikiUrl,
    this.generatedAt,
  });

  final String id;
  final String subject;
  final String topic;
  final String subtopic;
  final String title;
  final Map<String, dynamic> content;
  final List<Map<String, dynamic>> images;
  final String? wikiUrl;
  final String? generatedAt;

  factory StudyMaterial.fromJson(Map<String, dynamic> j) => StudyMaterial(
        id: j['id'] ?? '',
        subject: j['subject'] ?? '',
        topic: j['topic'] ?? '',
        subtopic: j['subtopic'] ?? '',
        title: j['title'] ?? '',
        content: (j['content'] as Map<String, dynamic>?) ?? {},
        images: (j['images'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
        wikiUrl: j['wiki_url'],
        generatedAt: j['generated_at'],
      );
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final syllabusProvider = StateNotifierProvider<SyllabusNotifier, AsyncValue<List<SyllabusEntry>>>(
  (ref) => SyllabusNotifier(),
);

class SyllabusNotifier extends StateNotifier<AsyncValue<List<SyllabusEntry>>> {
  SyllabusNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load({String? subject}) async {
    state = const AsyncValue.loading();
    try {
      final query = subject != null ? {'subject': subject} : null;
      final data = await apiClient.get('/api/materials/syllabus', query);
      final list = (data as List<dynamic>)
          .map((e) => SyllabusEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(list);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// ---------------------------------------------------------------------------
// Tela principal — Lista de Materiais por disciplina
// ---------------------------------------------------------------------------

class MaterialsScreen extends ConsumerStatefulWidget {
  const MaterialsScreen({super.key, this.initialSubject});

  final String? initialSubject;

  @override
  ConsumerState<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends ConsumerState<MaterialsScreen> {
  String? _selectedSubject;
  String? _expandedTopic;

  static const _subjects = [
    'Biologia',
    'Química',
    'Física',
    'Matemática',
    'Português',
    'Inglês',
    'Espanhol',
    'História',
    'Geografia',
    'Filosofia',
    'Sociologia',
  ];

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
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final syllabus = ref.watch(syllabusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Materiais de Estudo', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PdfListScreen())),
            tooltip: 'PDFs disponíveis',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(syllabusProvider.notifier).load(subject: _selectedSubject),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtro de disciplina — chips horizontais
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
            FilterChip(
              label: const Text('Todas'),
              selected: _selectedSubject == null,
              onSelected: (_) {
                setState(() => _selectedSubject = null);
                ref.read(syllabusProvider.notifier).load();
              },
            ),
            ..._subjects.map((s) {
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FilterChip(
                  label: Text(s),
                  selected: _selectedSubject == s,
                  avatar: Icon(_subjectIcons[s], size: 16),
                  onSelected: (_) {
                    setState(() => _selectedSubject = s);
                    ref.read(syllabusProvider.notifier).load(subject: s);
                  },
                ),
              );
            }),
              ],
            ),
          ),

          // Conteúdo
          Expanded(
            child: syllabus.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off, size: 48, color: cs.outline),
                      const SizedBox(height: 12),
                      Text('Erro ao carregar: ${humanApiError(e)}'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => ref.read(syllabusProvider.notifier).load(subject: _selectedSubject),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Text('Nenhum tópico encontrado.', style: TextStyle(color: cs.outline)),
                  );
                }
                // Agrupa por topic
                final byTopic = <String, List<SyllabusEntry>>{};
                for (final e in entries) {
                  byTopic.putIfAbsent(e.topic, () => []).add(e);
                }
                final topics = byTopic.keys.toList();

                // Estatísticas
                final total = entries.length;
                final generated = entries.where((e) => e.hasMaterial).length;
                final pct = total > 0 ? (generated / total * 100).round() : 0;

                return Column(
                  children: [
                    // Barra de progresso
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: cs.surfaceContainerHighest.withOpacity(0.3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$generated de $total materiais prontos ($pct%)',
                                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: total > 0 ? generated / total : 0,
                                    minHeight: 6,
                                    backgroundColor: cs.surfaceContainerHighest,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Lista
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: topics.length,
                        itemBuilder: (context, i) {
                          final topic = topics[i];
                          final items = byTopic[topic]!;
                          final isExpanded = _expandedTopic == topic;
                          final topicGenerated = items.where((e) => e.hasMaterial).length;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ExpansionTile(
                              initiallyExpanded: isExpanded,
                              onExpansionChanged: (v) => setState(() => _expandedTopic = v ? topic : null),
                              title: Text(topic, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '$topicGenerated/${items.length} prontos',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: topicGenerated == items.length
                                      ? cs.primary
                                      : cs.outline,
                                ),
                              ),
                              leading: Icon(
                                topicGenerated == items.length ? Icons.check_circle : Icons.folder_outlined,
                                color: topicGenerated == items.length ? cs.primary : cs.outline,
                              ),
                              children: items.map((e) => _SyllabusTile(entry: e)).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tile individual — mostra subtópico + botão gerar/abrir
// ---------------------------------------------------------------------------

class _SyllabusTile extends ConsumerStatefulWidget {
  const _SyllabusTile({required this.entry});
  final SyllabusEntry entry;

  @override
  ConsumerState<_SyllabusTile> createState() => _SyllabusTileState();
}

class _SyllabusTileState extends ConsumerState<_SyllabusTile> {
  bool _generating = false;
  String? _error;

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      await apiClient.post('/api/materials/generate', {
        'subject': widget.entry.subject,
        'topic': widget.entry.topic,
        'subtopic': widget.entry.subtopic.isNotEmpty ? widget.entry.subtopic : null,
        'force': false,
      });
      // Recarrega syllabus
      if (mounted) {
        await ref.read(syllabusProvider.notifier).load();
        setState(() => _generating = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generating = false;
          _error = humanApiError(e);
        });
      }
    }
  }

  Future<void> _openMaterial() async {
    final query = <String, String>{};
    query['subject'] = widget.entry.subject;
    query['topic'] = widget.entry.topic;
    if (widget.entry.subtopic.isNotEmpty) query['subtopic'] = widget.entry.subtopic;

    try {
      final data = await apiClient.get('/api/materials/${widget.entry.subject}/${widget.entry.topic}', query);
      if (mounted) {
        final material = StudyMaterial.fromJson(data);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MaterialReaderScreen(material: material)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${humanApiError(e)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final e = widget.entry;

    return ListTile(
      dense: true,
      leading: Icon(
        e.hasMaterial ? Icons.picture_as_pdf : Icons.note_add,
        size: 20,
        color: e.hasMaterial ? cs.primary : cs.outline,
      ),
      title: Text(
        e.subtopic.isNotEmpty ? e.subtopic : e.topic,
        style: TextStyle(fontSize: 14),
      ),
      trailing: _generating
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : e.hasMaterial
              ? TextButton.icon(
                  onPressed: _openMaterial,
                  icon: const Icon(Icons.read_more, size: 18),
                  label: const Text('Abrir'),
                )
              : TextButton.icon(
                  onPressed: _generate,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Gerar'),
                ),
      subtitle: _error != null
          ? Text(_error!, style: TextStyle(fontSize: 11, color: cs.error))
          : e.hasMaterial
              ? Text('Pronto', style: TextStyle(fontSize: 11, color: cs.primary))
              : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Leitor de Material — mostra teoria + imagens da Wikipedia
// ---------------------------------------------------------------------------

class MaterialReaderScreen extends StatelessWidget {
  const MaterialReaderScreen({super.key, required this.material});
  final StudyMaterial material;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final content = material.content;

    return Scaffold(
      appBar: AppBar(
        title: Text(material.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          if (material.wikiUrl != null)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () => _openUrl(context, material.wikiUrl!),
              tooltip: 'Ver na Wikipedia',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Badge disciplina + tópico
          Wrap(
            spacing: 8,
            children: [
              Chip(
                label: Text(material.subject, style: const TextStyle(fontSize: 12)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Chip(
                label: Text(material.topic, style: const TextStyle(fontSize: 12)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              if (material.subtopic.isNotEmpty)
                Chip(
                  label: Text(material.subtopic, style: const TextStyle(fontSize: 12)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Imagem principal (se houver)
          if (material.images.isNotEmpty) ...[
            _ImageCard(image: material.images.first),
            const SizedBox(height: 16),
          ],

          // Introdução
          if (content['introducao'] != null) ...[
            Text(
              'Introdução',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              content['introducao'] as String,
              style: TextStyle(fontSize: 15, height: 1.6, color: cs.onSurface.withOpacity(0.85)),
            ),
            const SizedBox(height: 24),
          ],

          // Seções
          if (content['secoes'] != null) ...[
            for (final sec in (content['secoes'] as List<dynamic>))
              _SectionCard(section: sec as Map<String, dynamic>),
          ],

          // Imagens adicionais intercaladas
          if (material.images.length > 1) ...[
            const SizedBox(height: 16),
            Text('Imagens', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: material.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => _ThumbCard(image: material.images[i]),
              ),
            ),
          ],

          // Resumo
          if (content['resumo'] != null) ...[
            const SizedBox(height: 24),
            _InfoCard(
              title: 'Resumo',
              icon: Icons.summarize,
              child: Text(
                content['resumo'] as String,
                style: TextStyle(fontSize: 14, height: 1.6, color: cs.onSurface.withOpacity(0.85)),
              ),
            ),
          ],

          // Dicas
          if (content['dicas'] != null && (content['dicas'] as List).isNotEmpty) ...[
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Dicas para a prova',
              icon: Icons.lightbulb,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final dica in (content['dicas'] as List<dynamic>))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check, size: 16, color: cs.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(dica as String, style: const TextStyle(fontSize: 14, height: 1.5))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Pegadinhas
          if (content['pegadinhas'] != null && (content['pegadinhas'] as List).isNotEmpty) ...[
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Pegadinhas comuns',
              icon: Icons.warning_amber,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final peg in (content['pegadinhas'] as List<dynamic>))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.priority_high, size: 16, color: cs.error),
                          const SizedBox(width: 8),
                          Expanded(child: Text(peg as String, style: const TextStyle(fontSize: 14, height: 1.5))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Tópicos relacionados
          if (content['relacionado'] != null && (content['relacionado'] as List).isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final rel in (content['relacionado'] as List<dynamic>))
                  ActionChip(
                    label: Text(rel as String, style: const TextStyle(fontSize: 12)),
                    onPressed: () {},
                  ),
              ],
            ),
          ],

          const SizedBox(height: 32),

          // Ações
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.go(Uri(path: '/sessao', queryParameters: {
                    'subject': material.subject,
                    'topic': material.topic,
                  }).toString()),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Praticar questões'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go(Uri(path: '/tutor', queryParameters: {
                    'subject': material.subject,
                    'topic': material.topic,
                  }).toString()),
                  icon: const Icon(Icons.smart_toy),
                  label: const Text('Tutor IA'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _openUrl(BuildContext context, String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Abrindo: $url'), duration: const Duration(seconds: 2)),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets auxiliares
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});
  final Map<String, dynamic> section;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = section['titulo'] as String? ?? '';
    final conteudo = section['conteudo'] as String? ?? '';
    final exemplo = section['exemplo'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            conteudo,
            style: TextStyle(fontSize: 15, height: 1.6, color: cs.onSurface.withOpacity(0.85)),
          ),
          if (exemplo != null && exemplo.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.primary.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.school, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      exemplo,
                      style: TextStyle(fontSize: 14, height: 1.5, color: cs.onSurface.withOpacity(0.8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({required this.image});
  final Map<String, dynamic> image;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = (image['url'] as String?) ?? (image['thumb'] as String?);
    final caption = image['caption'] as String? ?? '';

    if (url == null || url.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Image.network(
            url,
            width: double.infinity,
            height: 220,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              height: 120,
              color: cs.surfaceContainerHighest,
              child: Center(child: Icon(Icons.broken_image, size: 40, color: cs.outline)),
            ),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator(value: progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1))),
              );
            },
          ),
          if (caption.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
                child: Text(
                  caption,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThumbCard extends StatelessWidget {
  const _ThumbCard({required this.image});
  final Map<String, dynamic> image;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = (image['thumb'] as String?) ?? (image['url'] as String?);

    if (url == null || url.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _FullImageScreen(image: image)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 160,
          height: 160,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 160,
            height: 160,
            color: cs.surfaceContainerHighest,
            child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
          ),
        ),
      ),
    );
  }
}

class _FullImageScreen extends StatelessWidget {
  const _FullImageScreen({required this.image});
  final Map<String, dynamic> image;

  @override
  Widget build(BuildContext context) {
    final url = (image['url'] as String?) ?? (image['thumb'] as String?);
    final caption = image['caption'] as String? ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: InteractiveViewer(
          child: url != null
              ? Image.network(url, fit: BoxFit.contain)
              : const Icon(Icons.broken_image, size: 64, color: Colors.white54),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tela: Lista de PDFs disponíveis
// ---------------------------------------------------------------------------

class PdfListScreen extends ConsumerStatefulWidget {
  const PdfListScreen({super.key});

  @override
  ConsumerState<PdfListScreen> createState() => _PdfListScreenState();
}

class _PdfListScreenState extends ConsumerState<PdfListScreen> {
  List<Map<String, dynamic>> _pdfs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPdfs();
  }

  Future<void> _loadPdfs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await apiClient.get('/api/materials/pdfs/list');
      final list = (res as List).cast<Map<String, dynamic>>();
      setState(() {
        _pdfs = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = humanApiError(e);
        _loading = false;
      });
    }
  }

  String _buildUrl(String endpoint) {
    final base = apiClient.baseUrl;
    return '$base$endpoint';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('PDFs Disponíveis', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPdfs,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off, size: 48, color: cs.outline),
                      const SizedBox(height: 12),
                      Text('Erro: $_error'),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _loadPdfs, child: const Text('Tentar novamente')),
                    ],
                  ),
                )
              : _pdfs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.picture_as_pdf, size: 64, color: cs.outline),
                          const SizedBox(height: 16),
                          Text('Nenhum PDF disponível ainda.', style: TextStyle(color: cs.outline)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pdfs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final pdf = _pdfs[i];
                        final title = pdf['title'] as String;
                        final subject = pdf['subject'] as String;
                        final sizeKb = pdf['size_kb'] as double;
                        final urlPath = pdf['url'] as String;

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.picture_as_pdf, color: cs.onPrimaryContainer),
                            ),
                            title: Text(
                              title,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Wrap(
                                spacing: 8,
                                children: [
                                  Chip(
                                    label: Text(subject, style: const TextStyle(fontSize: 11)),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  Text('${sizeKb.toStringAsFixed(0)} KB',
                                      style: TextStyle(fontSize: 12, color: cs.outline)),
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.menu_book, size: 20),
                                  tooltip: 'Estudar com Tutor IA',
                                  color: cs.primary,
                                  onPressed: () {
                                    context.go(Uri(path: '/estudar', queryParameters: {
                                      'pdf': pdf['filename'] ?? '',
                                      'title': title,
                                      'subject': subject,
                                    }).toString());
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.download, size: 20),
                                  tooltip: 'Baixar PDF',
                                  onPressed: () async {
                                    final fullUrl = _buildUrl(urlPath);
                                    if (await canLaunchUrl(Uri.parse(fullUrl))) {
                                      await launchUrl(Uri.parse(fullUrl),
                                          mode: LaunchMode.externalApplication);
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Não foi possível abrir: $fullUrl')),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
