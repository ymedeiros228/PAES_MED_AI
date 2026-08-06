import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/data/study_prefs_providers.dart';
import '../../../core/data/theme_mode_provider.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../library/presentation/ingest_review_screen.dart';

/// Ajustes: o que o aluno usa no topo; oficina em Avançado.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Map<String, dynamic>? health;
  Map<String, dynamic>? lastBackup;
  String? msg;
  String kind = 'prova';
  late final TextEditingController examCtrl;
  List<dynamic> backups = [];

  @override
  void initState() {
    super.initState();
    examCtrl = TextEditingController(text: ref.read(examDateProvider));
    _health();
    _backups();
    _lastBackup();
  }

  @override
  void dispose() {
    examCtrl.dispose();
    super.dispose();
  }

  Future<void> _health() async {
    try {
      final data = await apiClient.get('/health');
      setState(() => health = Map<String, dynamic>.from(data as Map));
    } catch (e) {
      setState(() => health = {'status': 'offline', 'error': e.toString()});
    }
  }

  Future<void> _backups() async {
    try {
      final data = await apiClient.get('/api/backups');
      setState(() => backups = data as List);
    } catch (_) {}
  }

  Future<void> _lastBackup() async {
    try {
      final data = await apiClient.get('/api/backup/last');
      setState(() => lastBackup = Map<String, dynamic>.from(data as Map));
    } catch (_) {
      setState(() => lastBackup = null);
    }
  }

  Future<void> _backup() async {
    try {
      final data = await apiClient.post('/api/backup', {});
      final map = Map<String, dynamic>.from(data as Map);
      final verify = map['verify'] is Map ? Map<String, dynamic>.from(map['verify'] as Map) : null;
      final ok = map['ok'] == true && (verify == null || verify['ok'] == true);
      final prefix = verify?['sha256Prefix']?.toString() ?? '';
      final members = verify?['members'];
      final files = (verify?['files'] as List?)?.join(', ') ?? '';
      setState(() {
        msg = ok
            ? 'Backup OK${prefix.isNotEmpty ? ' · $prefix' : ''}'
                '${members != null ? ' · $members arquivos' : ''}'
                '${files.isNotEmpty ? ' ($files)' : ''}'
            : 'Backup feito, mas verify falhou.';
      });
      await _backups();
      await _lastBackup();
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Falha no backup.'));
    }
  }

  Future<void> _restore(String name) async {
    try {
      await apiClient.post('/api/backup/restore?folderName=${Uri.encodeComponent(name)}', {});
      ref.read(refreshTickProvider.notifier).state++;
      setState(() => msg = 'Restaurado.');
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Falha ao restaurar.'));
    }
  }

  Future<void> _reindex() async {
    try {
      await apiClient.post('/api/rag/reindex', {});
      setState(() => msg = 'Índice atualizado.');
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Falha no índice.'));
    }
  }

  Future<void> _professorBatch() async {
    try {
      final data = await apiClient.post('/api/professor/batch-fill', {'limit': 40});
      setState(() => msg = 'Rascunhos: ${(data as Map)['updated'] ?? 0}');
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Falha no lote.'));
    }
  }

  Future<void> _reprocess() async {
    try {
      final data = await apiClient.post('/api/library/reprocess', {});
      final map = Map<String, dynamic>.from(data as Map);
      setState(() => msg = map['message']?.toString() ?? 'Base reprocessada.');
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Falha ao recalcular a base local.'));
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null || result.files.single.path == null) return;
    setState(() => msg = 'Lendo PDF…');
    try {
      final data = await apiClient.postMultipart(
        '/api/ingest/pdf?kind=$kind&subject=Geral',
        fileField: 'file',
        filePath: result.files.single.path!,
        filename: result.files.single.name,
      );
      final map = Map<String, dynamic>.from(data as Map);
      final qs = (map['questions'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final previewId = map['previewId']?.toString();
      if (previewId != null && qs.isNotEmpty && mounted) {
        context.push(
          '/biblioteca/revisao',
          extra: IngestReviewArgs(
            year: (map['year'] as int?) ?? DateTime.now().year,
            previewId: previewId,
            questions: qs,
            meta: map,
          ),
        );
        setState(() => msg = null);
        return;
      }
      setState(() => msg = 'Sem questões — use a Biblioteca.');
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Erro ao ler PDF.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final focus = ref.watch(focusModeProvider);
    final exam = ref.watch(examDateProvider);
    if (examCtrl.text != exam && exam.isNotEmpty && !examCtrl.selection.isValid) {
      examCtrl.text = exam;
    }
    final online = health?['status'] == 'ok';

    return ListView(
      children: [
        PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: 'Conta',
                title: 'Ajustes',
                subtitle: 'Preferências do dia a dia',
              ),

              SectionLabel('Sobre'),
              SurfacePanel(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAES MED AI · 1.0.0+13',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'App local de treino para PAES UEMA Medicina.\n'
                      '• Offline-first — dados no seu PC\n'
                      '• Não inventa % de aprovação nem prova oficial ausente\n'
                      '• Catálogo de reforço (vídeo/leitura) não é edital da banca',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              SectionLabel('Aparência'),
              _ThemeModePicker(mode: ref.watch(themeModeProvider)),

              const SizedBox(height: 16),
              SectionLabel('Estudo'),
              SurfacePanel(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Modo foco'),
                      subtitle: const Text('Esconde telas extras. Atalho F'),
                      value: focus,
                      onChanged: (v) => ref.read(focusModeProvider.notifier).setFocus(v),
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Data da prova',
                        hintText: 'AAAA-MM-DD',
                      ),
                      controller: examCtrl,
                      onSubmitted: (v) => ref.read(examDateProvider.notifier).setDate(v.trim()),
                      onChanged: (v) {
                        if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v.trim())) {
                          ref.read(examDateProvider.notifier).setDate(v.trim());
                        }
                      },
                    ),
                    if (ref.watch(examDateProvider.notifier).daysUntilExam != null) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          () {
                            final d = ref.watch(examDateProvider.notifier).daysUntilExam!;
                            if (d < 0) return 'Prova: $d dias atrás (data local)';
                            if (d == 0) return 'Prova: é hoje (treino local)';
                            return 'Prova em $d dia(s) · contagem local';
                          }(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),
              SectionLabel('Seus dados'),
              SurfacePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(online ? Icons.check_circle : Icons.error_outline, color: Theme.of(context).colorScheme.primary),
                      title: Text(online ? 'Tudo certo nesta máquina' : 'App sem conexão local'),
                      subtitle: Text(
                        online
                            ? '${health?['officialCount'] ?? 0} questões oficiais · ${(health?['questions'] ?? '—')} no total'
                            : 'Reabra pelo ícone da área de trabalho',
                      ),
                      trailing: IconButton(onPressed: _health, icon: const Icon(Icons.refresh_rounded)),
                    ),
                    if (online && health?['curation'] is Map)
                      Builder(
                        builder: (_) {
                          final c = Map<String, dynamic>.from(health!['curation'] as Map);
                          final floorOk = c['naturezaFloorOk'] == true;
                          final msg = c['message']?.toString() ?? '';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              floorOk ? Icons.biotech_outlined : Icons.warning_amber_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(floorOk ? 'Natureza estável' : 'Natureza precisa de floor'),
                            subtitle: Text(
                              msg.isEmpty
                                  ? 'real ${c['realCount'] ?? '—'} · cross ${c['crossDomainCount'] ?? '—'}'
                                  : msg,
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: focus
                                ? Tooltip(
                                    message: 'Desligue F (modo foco) para abrir Domínio',
                                    child: TextButton(
                                      onPressed: null,
                                      child: const Text('Domínio'),
                                    ),
                                  )
                                : TextButton(
                                    onPressed: () => context.go('/medicina'),
                                    child: const Text('Domínio'),
                                  ),
                          );
                        },
                      ),
                    const Divider(height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Biblioteca de provas'),
                      subtitle: const Text('Onde entram PDFs oficiais'),
                      trailing: TextButton(onPressed: () => context.go('/biblioteca'), child: const Text('Abrir')),
                    ),
                    FilledButton.tonal(
                      onPressed: _backup,
                      child: const Text('Salvar cópia de segurança'),
                    ),
                    if (lastBackup != null) ...[
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Icon(
                          lastBackup!['ok'] == true ? Icons.verified_outlined : Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          lastBackup!['ok'] == true
                              ? 'Último backup verificado'
                              : 'Nenhum backup verificado',
                        ),
                        subtitle: Text(
                          () {
                            if (lastBackup!['ok'] != true) {
                              return lastBackup!['message']?.toString() ?? 'Salve uma cópia acima.';
                            }
                            final at = lastBackup!['at']?.toString() ?? '—';
                            final v = lastBackup!['verify'] is Map
                                ? Map<String, dynamic>.from(lastBackup!['verify'] as Map)
                                : <String, dynamic>{};
                            final sha = v['sha256Prefix']?.toString() ?? '';
                            return '$at${sha.isNotEmpty ? ' · $sha' : ''}';
                          }(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                    if (backups.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Restaurar', style: Theme.of(context).textTheme.titleSmall),
                      for (final b in backups.take(5))
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text((b as Map)['name']?.toString() ?? ''),
                          trailing: TextButton(
                            onPressed: () async {
                              final name = b['name']?.toString() ?? '';
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Restaurar?'),
                                  content: const Text('Substitui o progresso atual por esta cópia.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restaurar')),
                                  ],
                                ),
                              );
                              if (ok == true) await _restore(name);
                            },
                            child: const Text('Restaurar'),
                          ),
                        ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 8),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Avançado', style: Theme.of(context).textTheme.titleSmall),
                subtitle: const Text('Mídia · oficina · índices · paths'),
                children: [
                  SectionLabel('Mídia', hint: 'Sugestões na Fila (não é edital)'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tutor com IA online'),
                    subtitle: Text(
                      health?['openai_configured'] == true
                          ? 'Chave configurada'
                          : 'Sem chave — tutor só com material local',
                    ),
                    value: health?['openai_configured'] == true && ref.watch(tutorOnlinePrefProvider),
                    onChanged: health?['openai_configured'] == true
                        ? (v) => ref.read(tutorOnlinePrefProvider.notifier).setEnabled(v)
                        : null,
                  ),
                  FutureBuilder(
                    future: apiClient.get('/api/media/prefs'),
                    builder: (context, snap) {
                      final prefs = snap.hasData && snap.data is Map
                          ? Map<String, dynamic>.from(snap.data as Map)
                          : <String, dynamic>{};
                      final suggest = prefs['suggestVideos'] != false;
                      final suggestArt = prefs['suggestArticles'] != false;
                      final yt = prefs['youtubeConfigured'] == true ||
                          health?['youtube_configured'] == true;
                      final serper = prefs['serperConfigured'] == true ||
                          health?['serper_configured'] == true;
                      return Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Sugerir vídeos na Fila'),
                            subtitle: Text(
                              yt
                                  ? 'YouTube no .env + catálogo local (não é edital UEMA)'
                                  : 'Catálogo local · YOUTUBE_API_KEY no .env é opcional',
                            ),
                            value: suggest,
                            onChanged: (v) async {
                              try {
                                await apiClient.post('/api/media/prefs', {'suggestVideos': v});
                                setState(() {});
                              } catch (e) {
                                setState(
                                  () => msg = humanApiError(e, fallback: 'Não deu para salvar preferência.'),
                                );
                              }
                            },
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Sugerir artigos na Fila'),
                            subtitle: Text(
                              serper
                                  ? 'Serper no .env + catálogo local (não é edital UEMA)'
                                  : 'Catálogo local · SERPER_API_KEY no .env é opcional',
                            ),
                            value: suggestArt,
                            onChanged: (v) async {
                              try {
                                await apiClient.post('/api/media/prefs', {'suggestArticles': v});
                                setState(() {});
                              } catch (e) {
                                setState(
                                  () => msg = humanApiError(e, fallback: 'Não deu para salvar preferência.'),
                                );
                              }
                            },
                          ),
                          FutureBuilder(
                            future: apiClient.get('/api/media/opens', {'limit': '8'}),
                            builder: (context, openSnap) {
                              if (!openSnap.hasData || openSnap.data is! Map) {
                                return const SizedBox.shrink();
                              }
                              final om = Map<String, dynamic>.from(openSnap.data as Map);
                              final items =
                                  (om['items'] as List? ?? []).whereType<Map>().toList();
                              if (items.isEmpty) return const SizedBox.shrink();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text('Últimas aberturas de mídia'),
                                    subtitle: Text('local · não é progresso de banca'),
                                  ),
                                  for (final raw in items.take(6))
                                    ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        raw['title']?.toString() ??
                                            raw['url']?.toString() ??
                                            'item',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        [
                                          raw['kind']?.toString() ?? '',
                                          raw['at']?.toString() ?? '',
                                        ].where((s) => s.isNotEmpty).join(' · '),
                                      ),
                                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                                      onTap: () async {
                                        final u = raw['url']?.toString() ?? '';
                                        if (u.isEmpty) return;
                                        try {
                                          await apiClient.post('/api/media/open', {
                                            'url': u,
                                            'kind': raw['kind']?.toString(),
                                            'title': raw['title']?.toString(),
                                            'subject': raw['subject']?.toString(),
                                            'topic': raw['topic']?.toString(),
                                          });
                                        } catch (e) {
                                          setState(
                                            () => msg = humanApiError(
                                              e,
                                              fallback: 'Não deu para abrir o material.',
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  SectionLabel('Oficina', hint: 'PDF, aprovação, rascunhos'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Importar PDF aqui'),
                    subtitle: Text('Tipo: $kind — o habitual é Biblioteca'),
                    trailing: FilledButton.tonal(onPressed: _pickPdf, child: const Text('Escolher')),
                  ),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final k in ['prova', 'gabarito', 'edital'])
                        ChoiceChip(
                          label: Text(k),
                          selected: kind == k,
                          onSelected: (_) => setState(() => kind = k),
                        ),
                    ],
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Aprovar questões geradas'),
                    trailing: focus
                        ? Tooltip(
                            message: 'Desligue F (modo foco) para aprovar',
                            child: FilledButton.tonal(
                              onPressed: null,
                              child: const Text('Abrir'),
                            ),
                          )
                        : FilledButton.tonal(
                            onPressed: () => context.go('/aprovacao'),
                            child: const Text('Abrir'),
                          ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Lote de rascunhos (professor)'),
                    trailing: FilledButton.tonal(onPressed: _professorBatch, child: const Text('Rodar')),
                  ),
                  SectionLabel('Índices', hint: 'RAG e recálculo local'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Reindexar material local'),
                    trailing: FilledButton.tonal(onPressed: _reindex, child: const Text('Rodar')),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Recalcular base local'),
                    subtitle: const Text('POST reprocess — frequência/perfil na leitura'),
                    trailing: FilledButton.tonal(onPressed: _reprocess, child: const Text('Rodar')),
                  ),
                  SectionLabel('Paths', hint: 'Onde ficam os dados'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pasta de dados'),
                    subtitle: Text(health?['dataDir']?.toString() ?? '—', style: const TextStyle(fontSize: 11)),
                  ),
                ],
              ),
              if (msg != null) ...[
                const SizedBox(height: 12),
                Text(msg!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeModePicker extends ConsumerWidget {
  const _ThemeModePicker({required this.mode});
  final ThemeMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = <(ThemeMode, String, IconData)>[
      (ThemeMode.system, 'Sistema', Icons.brightness_auto_rounded),
      (ThemeMode.light, 'Claro', Icons.light_mode_rounded),
      (ThemeMode.dark, 'Escuro', Icons.dark_mode_rounded),
    ];
    return SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tema', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Também na barra lateral ou Ctrl+T',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          SegmentedButton<ThemeMode>(
            segments: [
              for (final o in options)
                ButtonSegment(
                  value: o.$1,
                  label: Text(o.$2),
                  icon: Icon(o.$3, size: 16),
                ),
            ],
            selected: {mode},
            onSelectionChanged: (s) {
              ref.read(themeModeProvider.notifier).setMode(s.first);
            },
          ),
        ],
      ),
    );
  }
}
