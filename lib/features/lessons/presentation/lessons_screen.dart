import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/widgets/ui_kit.dart';

class LessonsScreen extends ConsumerStatefulWidget {
  const LessonsScreen({super.key});

  @override
  ConsumerState<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends ConsumerState<LessonsScreen> {
  final titleCtrl = TextEditingController(text: 'Aula importada');
  final transcriptCtrl = TextEditingController();
  final linkCtrl = TextEditingController();
  final transcriptFocus = FocusNode();
  String? status;
  bool busy = false;
  Map<String, dynamic>? lastLesson;

  @override
  void dispose() {
    titleCtrl.dispose();
    transcriptCtrl.dispose();
    linkCtrl.dispose();
    transcriptFocus.dispose();
    super.dispose();
  }

  Future<void> _submitText() async {
    setState(() {
      busy = true;
      status = null;
    });
    try {
      final data = await apiClient.post('/api/lessons/from-text', {
        'title': titleCtrl.text.trim(),
        'transcript': transcriptCtrl.text.trim(),
        'sourceType': 'legenda',
        'sourceRef': linkCtrl.text.trim().isEmpty ? null : linkCtrl.text.trim(),
      });
      ref.read(refreshTickProvider.notifier).state++;
      setState(() {
        lastLesson = Map<String, dynamic>.from(data as Map);
        status = 'Aula salva · ${lastLesson!['subject']} / ${lastLesson!['topic']}';
        transcriptCtrl.clear();
      });
    } catch (e) {
      setState(() => status = humanApiError(e, fallback: 'Não deu para salvar a aula. Tente de novo.'));
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _uploadAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result == null || result.files.single.path == null) return;
    setState(() {
      busy = true;
      status = 'Enviando áudio…';
    });
    try {
      final path = result.files.single.path!;
      final data = await apiClient.postMultipart(
        '/api/lessons/from-audio',
        fileField: 'file',
        filePath: path,
        filename: result.files.single.name,
        fields: {'title': titleCtrl.text.trim()},
      );
      ref.read(refreshTickProvider.notifier).state++;
      setState(() {
        lastLesson = data is Map ? Map<String, dynamic>.from(data) : null;
        status = lastLesson?['message']?.toString() ?? 'Áudio processado.';
      });
    } catch (e) {
      setState(() => status = humanApiError(e, fallback: 'Não deu para processar o áudio. Tente de novo.'));
    } finally {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessons = ref.watch(lessonsProvider);
    final cs = Theme.of(context).colorScheme;

    return ListView(
      children: [
        PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(
                eyebrow: 'Conteúdo',
                title: 'Aulas',
                subtitle: 'Cole a legenda e ligue ao edital — link do YouTube é só referência',
              ),
              SurfacePanel(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Título'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: linkCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Link (opcional)',
                        hintText: 'YouTube só como referência',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: transcriptCtrl,
                      focusNode: transcriptFocus,
                      minLines: 8,
                      maxLines: 14,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Legenda / transcrição',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: busy || transcriptCtrl.text.trim().length < 80 ? null : _submitText,
                          icon: const Icon(Icons.auto_awesome_rounded),
                          label: Text(busy ? 'Processando…' : 'Estruturar legenda'),
                        ),
                        OutlinedButton.icon(
                          onPressed: busy ? null : _uploadAudio,
                          icon: const Icon(Icons.mic_none_rounded),
                          label: const Text('Áudio'),
                        ),
                      ],
                    ),
                    if (transcriptCtrl.text.trim().isNotEmpty && transcriptCtrl.text.trim().length < 80)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Cole pelo menos ~80 caracteres de legenda.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withOpacity(0.55),
                              ),
                        ),
                      ),
                    if (status != null) ...[
                      const SizedBox(height: 8),
                      Text(status!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.primary)),
                    ],
                  ],
                ),
              ),
              if (lastLesson != null) ...[
                SectionLabel('Última importação'),
                SurfacePanel(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: cs.primaryContainer.withOpacity(0.35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${lastLesson!['subject']} · ${lastLesson!['topic']}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (lastLesson!['summary'] != null) ...[
                        const SizedBox(height: 6),
                        Text('${lastLesson!['summary']}'),
                      ],
                      if (lastLesson!['macetes'] != null) ...[
                        const SizedBox(height: 6),
                        Text('Macete: ${lastLesson!['macetes']}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonal(
                            onPressed: () => context.go(
                              '/adaptativo?subject=${Uri.encodeComponent('${lastLesson!['subject']}')}'
                              '&topic=${Uri.encodeComponent('${lastLesson!['topic']}')}',
                            ),
                            child: const Text('Treinar este tópico'),
                          ),
                          OutlinedButton(
                            onPressed: () => context.go(
                              '/tutor?subject=${Uri.encodeComponent('${lastLesson!['subject']}')}'
                              '&topic=${Uri.encodeComponent('${lastLesson!['topic']}')}',
                            ),
                            child: const Text('Tutor'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              SectionLabel('Suas aulas'),
              lessons.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => QuietEmpty(
                  message: 'Lista indisponível.',
                  action: TextButton(
                    onPressed: () => ref.read(refreshTickProvider.notifier).state++,
                    child: const Text('Tentar'),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return QuietEmpty(
                      message: 'Nenhuma aula ainda — cole uma legenda acima.',
                      action: TextButton(
                        onPressed: () => transcriptFocus.requestFocus(),
                        child: const Text('Cole acima'),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final raw in items)
                        Builder(
                          builder: (_) {
                            final item = Map<String, dynamic>.from(raw as Map);
                            return ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              title: Text(item['title']?.toString() ?? 'Aula'),
                              subtitle: Text('${item['subject']} · ${item['topic']}'),
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (item['summary'] != null) Text('${item['summary']}'),
                                        if (item['incidenceNote'] != null)
                                          Text(
                                            '${item['incidenceNote']}',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        const SizedBox(height: 8),
                                        FilledButton.tonal(
                                          onPressed: () => context.go(
                                            '/adaptativo?subject=${Uri.encodeComponent('${item['subject']}')}'
                                            '&topic=${Uri.encodeComponent('${item['topic']}')}',
                                          ),
                                          child: const Text('Estudar'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
