import 'dart:async';
import 'dart:io' show File, Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

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
  Map<String, dynamic>? lastBackup;
  Map<String, dynamic>? backupSummary;
  Map<String, dynamic>? backupCleanupPlan;
  String? msg;
  String? backupListError;
  String kind = 'prova';
  late final TextEditingController examCtrl;
  List<dynamic> backups = [];
  final _focusNode = FocusNode();

  bool _textFieldFocused() {
    final primary = FocusManager.instance.primaryFocus;
    return primary != null && primary.context?.widget is EditableText;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _textFieldFocused()) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyR || key == LogicalKeyboardKey.f5) {
      _health();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyB) {
      _backup();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void initState() {
    super.initState();
    examCtrl = TextEditingController(text: ref.read(examDateProvider).date);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
    _health();
    _backups();
    _lastBackup();
    _backupSummary();
    _backupCleanupPlan();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    examCtrl.dispose();
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

  bool _tutorModelConfigured(Map<String, dynamic>? h) {
    if (h == null) return false;
    if (h['openai_configured'] == true || h['ollama_configured'] == true) return true;
    final t = h['tutor'];
    if (t is Map && t['configured'] == true) return true;
    return false;
  }

  String _tutorOnlineSubtitle(Map<String, dynamic>? h) {
    if (!_tutorModelConfigured(h)) {
      return 'Sem modelo no .env — tutor local ensina com edital/questões. '
          'OPENAI_API_KEY ou OLLAMA_HOST em backend/.env';
    }
    final t = h?['tutor'];
    final tutorMap = t is Map ? Map<String, dynamic>.from(t) : null;
    final p = tutorMap?['provider']?.toString() ?? 'openai';
    final m = tutorMap?['model']?.toString() ?? h?['model']?.toString() ?? '—';
    return 'Modelo ativo: $p · $m (desligue para forçar local)';
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

  Future<void> _backupSummary() async {
    try {
      final data = await apiClient.get('/api/backups/summary');
      setState(() {
        backupSummary = Map<String, dynamic>.from(data as Map);
      });
    } catch (_) {
      setState(() => backupSummary = null);
    }
  }

  Future<void> _backupCleanupPlan({int keep = 10}) async {
    try {
      final data = await apiClient.get('/api/backups/cleanup-plan', {'keep': '$keep'});
      setState(() {
        backupCleanupPlan = Map<String, dynamic>.from(data as Map);
      });
    } catch (_) {
      setState(() => backupCleanupPlan = null);
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
      await _backupSummary();
      await _backupCleanupPlan();
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Falha no backup.'));
    }
  }

  String _formatMb(dynamic value) {
    final n = value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
    if (n == null) return '—';
    if (n >= 1024) return '${(n / 1024).toStringAsFixed(1)} GB';
    return '${n.toStringAsFixed(n >= 10 ? 0 : 1)} MB';
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
    final examState = ref.watch(examDateProvider);
    final exam = examState.date;
    if (examCtrl.text != exam && exam.isNotEmpty && !examCtrl.selection.isValid) {
      examCtrl.text = exam;
    }
    final online = health?['status'] == 'ok';

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      child: ListView(
      children: [
        PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: 'Conta',
                title: 'Ajustes',
                subtitle: 'Preferências · atalho B = backup',
              ),

              SectionLabel('Sobre'),
              SurfacePanel(
                margin: const EdgeInsets.only(bottom: 16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'PAES MED AI',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
                      'App local de treino para PAES UEMA Medicina.\n'
                      '• Offline-first — dados no seu PC\n'
                      '• Não inventa % de aprovação nem prova oficial ausente\n'
                      '• Catálogo de reforço (vídeo/leitura) não é edital da banca',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Builder(
                      builder: (_) {
                        final isWin = !kIsWeb && Platform.isWindows;
                        var desktopBuild = false;
                        if (isWin) {
                          try {
                            final exe = Platform.resolvedExecutable;
                            final dir = p.dirname(exe);
                            // dist layout: .../app/paes_med_ai.exe → ../VERSION.txt
                            final sibling = File(p.join(p.dirname(dir), 'VERSION.txt'));
                            final same = File(p.join(dir, 'VERSION.txt'));
                            desktopBuild = sibling.existsSync() || same.existsSync();
                          } catch (_) {}
                        }
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
                                label: const Text('Desktop build · pack Windows'),
                                visualDensity: VisualDensity.compact,
                              )
                            else
                              Text(
                                isWin
                                    ? 'Build Windows · modo desenvolvimento (flutter run)'
                                    : 'Build de estudo',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              'Notas desta versão: conforto de sessão/fila, Relevo em Progresso, '
                              'e redação com missões (treino local · não banca).',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.62),
                                  ),
                            ),
                          ],
                        );
                      },
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
                    if (exam.isNotEmpty &&
                        RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(exam) &&
                        ref.watch(examDateProvider.notifier).daysUntilExam == null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Data inválida — use AAAA-MM-DD válido.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                    ],
                    if (examState.hydrateNote != null && exam.isEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        examState.hydrateNote!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                      ),
                    ],
                    if (examState.syncError != null) ...[
                      const SizedBox(height: 8),
                      QuietEmpty(
                        message: examState.syncError!,
                        action: TextButton(
                          onPressed: () => unawaited(ref.read(examDateProvider.notifier).retrySync()),
                          child: const Text('Sincronizar'),
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
                            : health?['error']?.toString() ?? 'Reabra pelo ícone da área de trabalho',
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
                            title: Text(
                              floorOk
                                  ? 'Base de Natureza em dia'
                                  : 'Base de Natureza ainda fraca',
                            ),
                            subtitle: Text(
                              msg.isEmpty
                                  ? 'oficiais ${c['realCount'] ?? '—'} · transversais ${c['crossDomainCount'] ?? '—'}'
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
                      child: const Text('Salvar cópia de segurança (B)'),
                    ),
                    if (backupListError != null) ...[
                      const SizedBox(height: 8),
                      QuietEmpty(
                        message: backupListError!,
                        action: TextButton(
                          onPressed: () {
                            _backups();
                            _lastBackup();
                            _backupSummary();
                            _backupCleanupPlan();
                          },
                          child: const Text('Tentar'),
                        ),
                      ),
                    ],
                    if (backupSummary != null) ...[
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final summary = backupSummary!;
                          final warning = summary['warning']?.toString();
                          final count = summary['count']?.toString() ?? '0';
                          final dirs = summary['dirs']?.toString() ?? '0';
                          final zips = summary['zips']?.toString() ?? '0';
                          final size = _formatMb(summary['mb']);
                          final cs = Theme.of(context).colorScheme;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: Icon(
                              warning == null ? Icons.folder_zip_outlined : Icons.warning_amber_rounded,
                              color: warning == null ? cs.primary : cs.error,
                            ),
                            title: Text('$count backups · $size'),
                            subtitle: Text(
                              warning ?? '$zips zips · $dirs pastas antigas',
                              style: TextStyle(
                                fontSize: 12,
                                color: warning == null ? null : cs.error,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    if (backupCleanupPlan != null && (backupCleanupPlan!['removeCount'] is num)) ...[
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final plan = backupCleanupPlan!;
                          final removeCount = plan['removeCount'] is num ? (plan['removeCount'] as num).toInt() : 0;
                          if (removeCount <= 0) return const SizedBox.shrink();
                          final keep = plan['keep']?.toString() ?? '10';
                          final reclaim = _formatMb(plan['reclaimMb']);
                          final command = plan['command']?.toString() ?? '';
                          final cs = Theme.of(context).colorScheme;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: Icon(Icons.cleaning_services_outlined, color: cs.tertiary),
                            title: Text('Limpeza segura: liberar até $reclaim'),
                            subtitle: Text(
                              'Mantendo $keep backups recentes, $removeCount antigo(s) seriam removidos. '
                              '${command.isNotEmpty ? command : 'Use o script em tools.'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: TextButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: command));
                                setState(() => msg = 'Comando de limpeza copiado.');
                              },
                              child: const Text('Copiar'),
                            ),
                          );
                        },
                      ),
                    ],
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
                            return at;
                          }(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                    if (backups.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Restaurar', style: Theme.of(context).textTheme.titleSmall),
                      for (final raw in backups.take(5))
                        Builder(
                          builder: (context) {
                            final b = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
                            final verify = b['verify'] is Map ? Map<String, dynamic>.from(b['verify'] as Map) : null;
                            final sizeMb = b['bytes'] is num ? (b['bytes'] as num) / (1024 * 1024) : null;
                            final detail = [
                              b['kind']?.toString(),
                              if (sizeMb != null) _formatMb(sizeMb),
                              if (verify?['members'] != null) '${verify!['members']} arquivos',
                            ].where((v) => v != null && v.toString().isNotEmpty).join(' · ');
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(b['name']?.toString() ?? ''),
                              subtitle: detail.isEmpty ? null : Text(detail, style: const TextStyle(fontSize: 12)),
                              trailing: TextButton(
                                onPressed: () async {
                                  final name = b['name']?.toString() ?? '';
                                  final sha = verify?['sha256Prefix']?.toString() ?? '';
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Restaurar backup?'),
                                      content: Text(
                                        'Substitui o progresso atual por:\n\n$name'
                                        '${sha.isNotEmpty ? '\n\nCódigo de verificação (avançado): $sha' : ''}'
                                        '\n\nSó confirme se tiver certeza.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Restaurar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok == true) await _restore(name);
                                },
                                child: const Text('Restaurar'),
                              ),
                            );
                          },
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
                    subtitle: Text(_tutorOnlineSubtitle(health)),
                    value: _tutorModelConfigured(health) && ref.watch(tutorOnlinePrefProvider),
                    onChanged: _tutorModelConfigured(health)
                        ? (v) => ref.read(tutorOnlinePrefProvider.notifier).setEnabled(v)
                        : null,
                  ),
                  SurfacePanel(
                    margin: const EdgeInsets.only(bottom: 12),
                    soft: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Como ativar o modelo',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '1) Em backend/.env: OPENAI_API_KEY=… (ou OLLAMA_HOST=http://127.0.0.1:11434).\n'
                          '2) Opcional: OPENAI_BASE_URL (proxy/Groq/LM Studio) e OPENAI_MODEL / OLLAMA_MODEL.\n'
                          '3) Reinicie a API · aqui em Ajustes ligue “Tutor com IA online”.\n'
                          'Sem chave o tutor local continua ensinando com edital/questões (não inventa gabarito oficial).',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
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
                  SectionLabel('Pastas', hint: 'Onde ficam os dados'),
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
    ),
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
