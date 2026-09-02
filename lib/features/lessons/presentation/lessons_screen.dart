import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/widgets/keyboard_shortcuts.dart';
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
  void initState() {
    super.initState();
  }

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
      setState(() => status = humanApiError(e, fallback: 'Não deu para salvar a aula.'));
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _uploadAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    // Web: FilePicker retorna bytes, não path
    if (!kIsWeb && file.path == null) return;
    if (kIsWeb && file.bytes == null) return;
    setState(() {
      busy = true;
      status = 'Enviando áudio…';
    });
    try {
      final dynamic data;
      if (kIsWeb || file.bytes != null) {
        data = await apiClient.postMultipartBytes(
          '/api/lessons/from-audio',
          fileField: 'file',
          fileBytes: file.bytes!,
          filename: file.name,
          fields: {'title': titleCtrl.text.trim()},
        );
      } else {
        data = await apiClient.postMultipart(
          '/api/lessons/from-audio',
          fileField: 'file',
          filePath: file.path!,
          filename: file.name,
          fields: {'title': titleCtrl.text.trim()},
        );
      }
      ref.read(refreshTickProvider.notifier).state++;
      setState(() {
        lastLesson = data is Map ? Map<String, dynamic>.from(data) : null;
        status = lastLesson?['message']?.toString() ?? 'Áudio processado.';
      });
    } catch (e) {
      setState(() => status = humanApiError(e, fallback: 'Não deu para processar o áudio.'));
    } finally {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessons = ref.watch(lessonsProvider);
    final cs = Theme.of(context).colorScheme;

    return CtrlEnterScope(
      enabled: !busy && transcriptCtrl.text.trim().length >= 80,
      onSubmit: _submitText,
      child: ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: 'Conteúdo',
                title: 'Aulas',
                subtitle: 'Suas anotações e links de referência',
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
                        hintText: 'Vídeos como referência',
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
                        labelText: 'Transcrição',
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
                          onPressed: busy || transcriptCtrl.text.trim().length < 80
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  _submitText();
                                },
                          icon: busy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome_rounded),
                          label: Text(busy ? 'Processando…' : 'Estruturar legenda'),
                        ),
                        OutlinedButton.icon(
                          onPressed: busy ? null : () {
                            HapticFeedback.selectionClick();
                            _uploadAudio();
                          },
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
                          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                        ),
                      ),
                    if (status != null) ...[
                      const SizedBox(height: 8),
                      Text(status!, style: TextStyle(fontSize: 13, color: cs.primary, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
              if (lastLesson != null) ...[
                SectionLabel('Última importação'),
                SurfacePanel(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: cs.primaryContainer.f35,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${lastLesson!['subject']} · ${lastLesson!['topic']}',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onPrimaryContainer),
                      ),
                      if (lastLesson!['summary'] != null) ...[
                        const SizedBox(height: 8),
                        Text('${lastLesson!['summary']}'),
                      ],
                      if (lastLesson!['macetes'] != null) ...[
                        const SizedBox(height: 8),
                        SelectableText('Macete: ${lastLesson!['macetes']}', style: TextStyle(fontSize: 13, height: 1.5, color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.9))),
                      ],
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: () => context.go(
                          '/adaptativo?subject=${Uri.encodeComponent('${lastLesson!['subject']}')}'
                          '&topic=${Uri.encodeComponent('${lastLesson!['topic']}')}',
                        ),
                        child: const Text('Treinar este tópico'),
                      ),
                    ],
                  ),
                ),
              ],
              SectionLabel('Suas aulas'),
              lessons.when(
                loading: () => const SkeletonList(count: 3, lines: 2),
                error: (e, _) => QuietEmpty(
                  message: humanApiError(e, fallback: 'Lista indisponível.'),
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
                                            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
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
    ),
    );
  }
}
