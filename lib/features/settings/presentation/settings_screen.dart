import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Conditional import: dart:io so existe em desktop/mobile, nao na web
import 'platform_io.dart' if (dart.library.html) 'platform_io_web.dart' show isWindows, launchUpdater, readVersionFile;
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/app_version.dart';
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
  Map<String, dynamic>? aiConfig;
  Map<String, dynamic>? lastBackup;
  String? msg;
  String? aiMsg;
  String? backupListError;
  String kind = 'prova';
  late final TextEditingController examCtrl;
  List<dynamic> backups = [];
  late final TextEditingController geminiKeyCtrl;
  late final TextEditingController groqKeyCtrl;
  late final TextEditingController openRouterKeyCtrl;
  late final TextEditingController openAiKeyCtrl;
  bool aiConfigLoading = true;
  bool aiBusy = false;

  @override
  void initState() {
    super.initState();
    examCtrl = TextEditingController(text: ref.read(examDateProvider).date);
    geminiKeyCtrl = TextEditingController();
    groqKeyCtrl = TextEditingController();
    openRouterKeyCtrl = TextEditingController();
    openAiKeyCtrl = TextEditingController();
    _health();
    _loadAiConfig();
    _backups();
    _lastBackup();
  }

  @override
  void dispose() {
    examCtrl.dispose();
    geminiKeyCtrl.dispose();
    groqKeyCtrl.dispose();
    openRouterKeyCtrl.dispose();
    openAiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _health() async {
    try {
      final data = await apiClient.get('/health');
      setState(() => health = Map<String, dynamic>.from(data as Map));
    } catch (e) {
      setState(() => health = {'status': 'offline', 'error': humanApiError(e)});
    }
  }

  Future<void> _loadAiConfig() async {
    if (mounted) setState(() => aiConfigLoading = true);
    try {
      final data = await apiClient.get('/api/ai/config');
      if (!mounted) return;
      setState(() {
        aiConfig = Map<String, dynamic>.from(data as Map);
        aiConfigLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        aiConfig = null;
        aiConfigLoading = false;
        aiMsg = humanApiError(e, fallback: 'Não foi possível ler o estado da IA.');
      });
    }
  }

  Future<void> _configureAi(String provider) async {
    final controller = switch (provider) {
      'gemini' => geminiKeyCtrl,
      'groq' => groqKeyCtrl,
      'openrouter' => openRouterKeyCtrl,
      _ => openAiKeyCtrl,
    };
    final key = controller.text.trim();
    if (key.isEmpty) {
      setState(() => aiMsg = 'Cole a chave do provedor para validar.');
      return;
    }
    setState(() {
      aiBusy = true;
      aiMsg = null;
    });
    try {
      final data = await apiClient.post('/api/ai/config', {
        'provider': provider,
        'apiKey': key,
      });
      final map = Map<String, dynamic>.from(data as Map);
      controller.clear();
      setState(() => aiMsg = map['message']?.toString() ?? 'Provedor configurado.');
      await _loadAiConfig();
    } catch (e) {
      setState(() => aiMsg = humanApiError(e, fallback: 'Não foi possível validar a chave.'));
    } finally {
      if (mounted) setState(() => aiBusy = false);
    }
  }

  Future<void> _testAi(String provider) async {
    setState(() {
      aiBusy = true;
      aiMsg = null;
    });
    try {
      final data = await apiClient.post('/api/ai/test', {'provider': provider});
      final map = Map<String, dynamic>.from(data as Map);
      setState(() => aiMsg = map['message']?.toString() ?? 'Teste concluído.');
      await _loadAiConfig();
    } catch (e) {
      setState(() => aiMsg = humanApiError(e, fallback: 'Não foi possível testar a IA.'));
    } finally {
      if (mounted) setState(() => aiBusy = false);
    }
  }

  Future<void> _backups() async {
    try {
      final data = await apiClient.get('/api/backups');
      setState(() {
        backups = data as List;
        backupListError = null;
      });
    } catch (e) {
      setState(() {
        backups = [];
        backupListError = humanApiError(e, fallback: 'Não foi possível listar backups.');
      });
    }
  }

  Future<void> _lastBackup() async {
    try {
      final data = await apiClient.get('/api/backup/last');
      setState(() {
        lastBackup = Map<String, dynamic>.from(data as Map);
      });
    } catch (e) {
      setState(() {
        lastBackup = null;
        backupListError ??= humanApiError(e, fallback: 'Status do último backup indisponível.');
      });
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
      setState(() => msg = 'Base de estudos atualizada.');
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Falha ao atualizar base de estudos.'));
    }
  }

  Future<void> _professorBatch() async {
    try {
      final data = await apiClient.post('/api/professor/batch-fill', {'limit': 40});
      setState(() => msg = 'Rascunhos: ${(data as Map)['updated'] ?? 0}');
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Falha no lote de rascunhos.'));
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
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    setState(() => msg = 'Lendo PDF…');
    try {
      final dynamic data;
      if (kIsWeb || file.bytes != null) {
        // Web: FilePicker retorna bytes, não path
        data = await apiClient.postMultipartBytes(
          '/api/ingest/pdf?kind=$kind&subject=Geral',
          fileField: 'file',
          fileBytes: file.bytes!,
          filename: file.name,
        );
      } else {
        data = await apiClient.postMultipart(
          '/api/ingest/pdf?kind=$kind&subject=Geral',
          fileField: 'file',
          filePath: file.path!,
          filename: file.name,
        );
      }
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
    final examState = ref.watch(examDateProvider);
    final exam = examState.date;
    if (examCtrl.text != exam && exam.isNotEmpty && !examCtrl.selection.isValid) {
      examCtrl.text = exam;
    }
    final online = health?['status'] == 'ok';

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: 'Conta',
                title: 'Ajustes',
                subtitle: 'Personalize sua experiência de estudo',
              ),

              SectionLabel('Perfil'),
              SurfacePanel(
                margin: const EdgeInsets.only(bottom: 16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.f35,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primaryContainer,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.local_hospital_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'PAES MED AI',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Theme.of(context).colorScheme.primaryContainer,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_outlined,
                                size: 14,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                kAppVersionLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Plataforma de estudos para PAES UEMA Medicina.\n'
                      '• Funciona sem internet — dados no seu computador\n'
                      '• Usa apenas questões oficiais reais\n'
                      '• Tutor IA com seu material de estudo',
                      style: GoogleFonts.inter(fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (_) {
                        final (buildIdentity, desktopBuild) = readVersionFile();
                        final displayIdentity = buildIdentity.isNotEmpty ? buildIdentity : kAppVersionLabel;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (desktopBuild)
                              Chip(
                                avatar: Icon(
                                  Icons.desktop_windows_outlined,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                label: Text('Versão desktop · $displayIdentity'),
                                visualDensity: VisualDensity.compact,
                              )
                            else if (kIsWeb)
                              Chip(
                                avatar: Icon(
                                  Icons.language_outlined,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                label: Text('Versão web · $displayIdentity'),
                                visualDensity: VisualDensity.compact,
                              )
                            else
                              Text(
                                defaultTargetPlatform == TargetPlatform.windows
                                    ? 'Versão Windows · modo desenvolvimento'
                                    : 'Versão de estudo',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface.f72,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const Divider(height: 20),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Icon(Icons.center_focus_strong_rounded, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Modo foco'),
                      subtitle: const Text('Esconde telas extras'),
                      value: focus,
                      onChanged: (v) {
                        HapticFeedback.lightImpact();
                        ref.read(focusModeProvider.notifier).setFocus(v);
                      },
                    ),
                    const Divider(height: 20),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Data da prova',
                        hintText: 'AAAA-MM-DD',
                        prefixIcon: Icon(Icons.event_rounded),
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
                            if (d < 0) return 'Prova: \$d dias atrás';
                            if (d == 0) return 'Prova: é hoje!';
                            return 'Prova em \$d dia(s)';
                          }(),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.5,
                            color: Theme.of(context).colorScheme.onSurface.f72,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SectionLabel('Aparência'),
              _ThemeModePicker(mode: ref.watch(themeModeProvider)),

              const SizedBox(height: 16),
              SectionLabel('IA', hint: 'Cole sua chave e teste'),
              SurfacePanel(
                child: Builder(
                  builder: (context) {
                    if (aiConfigLoading) {
                      return const SkeletonList(count: 2, lines: 2);
                    }
                    if (aiConfig == null) {
                      return CompactStatus(
                        message: aiMsg ?? 'Tutor IA indisponível no momento.',
                        icon: Icons.sync_problem_outlined,
                      );
                    }
                    final active = aiConfig!['activeProvider']?.toString();
                    final activeModel = aiConfig!['activeModel']?.toString();
                    final geminiConfigured = aiConfig!['geminiConfigured'] == true;
                    final groqConfigured = aiConfig!['groqConfigured'] == true;
                    final openRouterConfigured = aiConfig!['openrouterConfigured'] == true;
                    final openAiConfigured = aiConfig!['openaiConfigured'] == true;
                    final providerNames = {
                      'gemini': 'Gemini',
                      'groq': 'Groq',
                      'openrouter': 'OpenRouter',
                      'openai': 'OpenAI',
                    };
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                active == null
                                    ? 'Nenhum provedor ativo'
                                    : 'Ativo: ${providerNames[active] ?? active}'
                                        '${activeModel == null ? '' : ' · $activeModel'}',
                                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Atualizar estado dos provedores',
                              onPressed: aiBusy ? null : _loadAiConfig,
                              icon: const Icon(Icons.refresh_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        CompactStatus(
                          message: geminiConfigured
                              ? 'Gemini configurado · ${aiConfig!['geminiKeyLast4'] ?? 'chave mascarada'}'
                              : 'Gemini sem chave configurada.',
                          icon: geminiConfigured
                              ? Icons.check_circle_outline
                              : Icons.radio_button_unchecked,
                        ),
                        CompactStatus(
                          message: groqConfigured
                              ? 'Groq configurado · ${aiConfig!['groqKeyLast4'] ?? 'chave mascarada'}'
                              : 'Groq sem chave configurada.',
                          icon: groqConfigured
                              ? Icons.check_circle_outline
                              : Icons.radio_button_unchecked,
                        ),
                        CompactStatus(
                          message: openRouterConfigured
                              ? 'OpenRouter configurado · ${aiConfig!['openrouterKeyLast4'] ?? 'chave mascarada'}'
                              : 'OpenRouter sem chave configurada.',
                          icon: openRouterConfigured
                              ? Icons.check_circle_outline
                              : Icons.radio_button_unchecked,
                        ),
                        CompactStatus(
                          message: openAiConfigured
                              ? 'OpenAI configurado · ${aiConfig!['openaiKeyLast4'] ?? 'chave mascarada'}'
                              : 'OpenAI sem chave configurada.',
                          icon: openAiConfigured
                              ? Icons.check_circle_outline
                              : Icons.radio_button_unchecked,
                        ),
                        const SizedBox(height: 8),
                        _AiProviderEditor(
                          name: 'Chave do Gemini',
                          hint: 'Cole a chave do Google AI Studio',
                          controller: geminiKeyCtrl,
                          configured: geminiConfigured,
                          status: aiConfig!['geminiStatus']?.toString(),
                          busy: aiBusy,
                          onSave: () => _configureAi('gemini'),
                          onTest: () => _testAi('gemini'),
                        ),
                        const SizedBox(height: 12),
                        _AiProviderEditor(
                          name: 'Chave do Groq',
                          hint: 'Gere em console.groq.com',
                          controller: groqKeyCtrl,
                          configured: groqConfigured,
                          status: aiConfig!['groqStatus']?.toString(),
                          busy: aiBusy,
                          onSave: () => _configureAi('groq'),
                          onTest: () => _testAi('groq'),
                        ),
                        const SizedBox(height: 12),
                        _AiProviderEditor(
                          name: 'Chave do OpenRouter',
                          hint: 'Gere em openrouter.ai/settings/keys',
                          controller: openRouterKeyCtrl,
                          configured: openRouterConfigured,
                          status: aiConfig!['openrouterStatus']?.toString(),
                          busy: aiBusy,
                          onSave: () => _configureAi('openrouter'),
                          onTest: () => _testAi('openrouter'),
                        ),
                        const SizedBox(height: 12),
                        _AiProviderEditor(
                          name: 'OpenAI',
                          hint: 'Gere em platform.openai.com',
                          controller: openAiKeyCtrl,
                          configured: openAiConfigured,
                          status: aiConfig!['openaiStatus']?.toString(),
                          busy: aiBusy,
                          onSave: () => _configureAi('openai'),
                          onTest: () => _testAi('openai'),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'As chaves ficam somente neste computador, fora das cópias de segurança e do repositório.',
                          style: GoogleFonts.inter(fontSize: 13, height: 1.5),
                        ),
                        if (aiBusy)
                          const CompactStatus(
                            message: 'Validando com o provedor…',
                            icon: Icons.hourglass_empty_rounded,
                          ),
                        if (aiMsg != null && !aiBusy)
                          CompactStatus(
                            message: aiMsg!,
                            icon: Icons.info_outline_rounded,
                          ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Avançado', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                subtitle: const Text('Backup, atualização, ferramentas e pastas'),
                children: [
                  SectionLabel('Backup e dados'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(online ? Icons.check_circle : Icons.error_outline, color: online ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error),
                    title: Text(online ? 'Tudo certo' : 'Sem conexão'),
                    subtitle: Text(
                      online
                          ? '${health?['officialCount'] ?? 0} questões oficiais · ${(health?['questions'] ?? '—')} no total'
                          : health?['error']?.toString() ?? 'Reabra pelo ícone da área de trabalho',
                    ),
                    trailing: IconButton(
                      tooltip: 'Verificar conexão',
                      onPressed: () { HapticFeedback.selectionClick(); _health(); },
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ),
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.backup_rounded, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Backup automático'),
                    subtitle: Text(lastBackup?['name']?.toString() ?? lastBackup?['date']?.toString() ?? 'Nenhum backup ainda'),
                    trailing: FilledButton.tonal(onPressed: _backup, child: const Text('Fazer agora')),
                  ),
                  if (backups.isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.restore_rounded, color: Theme.of(context).colorScheme.tertiary),
                      title: const Text('Restaurar cópia'),
                      subtitle: Text('${backups.length} cópia(s) disponível(is)'),
                      trailing: DropdownButton<String>(
                        value: null,
                        hint: const Text('Escolher'),
                        items: backups.map((b) => DropdownMenuItem<String>(value: b.toString(), child: Text(b.toString()))).toList(),
                        onChanged: (name) async {
                          if (name == null) return;
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Restaurar cópia de segurança?'),
                              content: Text('Isto substitui seus dados atuais pelos de $name.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restaurar')),
                              ],
                            ),
                          );
                          if (ok == true) await _restore(name);
                        },
                      ),
                    ),
                  if (isWindows && !kIsWeb) ...[
                    const Divider(height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.system_update_rounded, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Atualizar PAES MED AI'),
                      subtitle: const Text('Baixa a última versão do GitHub'),
                      trailing: FilledButton.tonal(onPressed: launchUpdater, child: const Text('Atualizar')),
                    ),
                  ],
                  SectionLabel('Ferramentas', hint: 'PDF, questões e índices'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.picture_as_pdf_outlined, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Importar PDF'),
                    subtitle: Text('Tipo: $kind — use a Biblioteca para importar'),
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
                    leading: Icon(Icons.fact_check_outlined, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Aprovar questões geradas'),
                    trailing: focus
                        ? Tooltip(
                            message: 'Desligue o modo foco para aprovar',
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
                    leading: Icon(Icons.edit_document, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Gerar questões automaticamente'),
                    trailing: FilledButton.tonal(onPressed: _professorBatch, child: const Text('Executar')),
                  ),
                  SectionLabel('Índices', hint: 'Busca e estatísticas'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Reindexar material'),
                    trailing: FilledButton.tonal(onPressed: _reindex, child: const Text('Executar')),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.analytics_outlined, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Recalcular estatísticas'),
                    subtitle: const Text('Frequência e perfil das questões'),
                    trailing: FilledButton.tonal(onPressed: _reprocess, child: const Text('Executar')),
                  ),
                  SectionLabel('Pastas', hint: 'Onde ficam os dados'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.folder_outlined, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Pasta de dados'),
                    subtitle: Text(
                      health?['dataDir']?.toString() ?? '—',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (msg != null) ...[
                const SizedBox(height: 12),
                Text(msg!, style: GoogleFonts.inter(fontSize: 13, height: 1.5)),
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
          Row(
            children: [
              Icon(Icons.palette_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Tema', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Escolha claro, escuro ou automático. Atalho: Ctrl+T',
            style: GoogleFonts.inter(fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
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

class _AiProviderEditor extends StatelessWidget {
  const _AiProviderEditor({
    required this.name,
    required this.hint,
    required this.controller,
    required this.configured,
    required this.status,
    required this.busy,
    required this.onSave,
    required this.onTest,
  });

  final String name;
  final String hint;
  final TextEditingController controller;
  final bool configured;
  final String? status;
  final bool busy;
  final VoidCallback onSave;
  final VoidCallback onTest;

  String get _statusText {
    switch (status) {
      case 'working':
        return 'Funcionando';
      case 'quota':
        return 'Cota esgotada';
      case 'key_rejected':
        return 'Chave recusada';
      case 'connection':
        return 'Sem conexão com o provedor';
      case 'unavailable':
        return 'Provedor indisponível';
      case 'configured':
        return 'Chave cadastrada, ainda não testada';
      default:
        return configured ? 'Chave cadastrada, ainda não testada' : 'Não configurada';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ok = status == 'working';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              ok ? Icons.check_circle_outline : Icons.radio_button_unchecked,
              size: 20,
              color: ok ? Theme.of(context).colorScheme.primary : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$name · $_statusText',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: 'Chave $name',
            hintText: hint,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: busy ? null : onSave,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salvar e validar'),
            ),
            OutlinedButton.icon(
              onPressed: busy || !configured ? null : onTest,
              icon: const Icon(Icons.network_check_outlined),
              label: const Text('Validar chave salva'),
            ),
          ],
        ),
      ],
    );
  }
}
