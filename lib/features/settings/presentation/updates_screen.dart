import 'dart:io' show exit;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_version.dart';
import '../../../core/widgets/ui_kit.dart';
import '../data/update_provider.dart';
import '../presentation/platform_io.dart' show runNativeUpdater;

class UpdatesScreen extends ConsumerStatefulWidget {
  const UpdatesScreen({super.key});

  @override
  ConsumerState<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends ConsumerState<UpdatesScreen> {
  Future<void> _checkUpdate() async {
    await ref.read(updateProvider.notifier).check();
  }

  Future<void> _openRelease(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Executa o update com dialog de progresso.
  /// Mostra progresso de download em tempo real.
  Future<void> _doUpdate(String url, String version) async {
    final messenger = ScaffoldMessenger.of(context);

    // Dialog de progresso
    var received = 0;
    var total = 0;
    var progressText = 'Baixando instalador...';
    var downloadDone = false;

    final progressNotifier = ValueNotifier<String>(progressText);

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Atualizando'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ValueListenableBuilder<String>(
              valueListenable: progressNotifier,
              builder: (_, text, __) => Text(text, style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: (total > 0) ? (received / total) : null,
            ),
            const SizedBox(height: 8),
            if (total > 0)
              Text(
                '${(received / 1024 / 1024).toStringAsFixed(1)} MB de ${(total / 1024 / 1024).toStringAsFixed(1)} MB',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),
          ],
        ),
      ),
    );

    try {
      final (ok, msg) = await runNativeUpdater(
        url,
        onProgress: (r, t) {
          received = r;
          total = t;
          if (t > 0) {
            final pct = ((r / t) * 100).round();
            progressNotifier.value = 'Baixando... $pct%';
          } else {
            progressNotifier.value = 'Baixando... ${(r / 1024 / 1024).toStringAsFixed(1)} MB';
          }
        },
      );
      downloadDone = true;

      if (mounted) Navigator.pop(context); // fecha dialog de progresso

      if (!ok) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(msg), duration: const Duration(seconds: 8)),
          );
        }
        return;
      }

      // Sucesso: instalador foi lancado.
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Instalador aberto. O app vai fechar agora...'),
            duration: Duration(seconds: 5),
          ),
        );
      }
      // Espera 5s para o instalador abrir (UAC pode demorar).
      await Future.delayed(const Duration(seconds: 5));
      exit(0);
    } catch (e) {
      if (!downloadDone && mounted) Navigator.pop(context);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Erro inesperado: $e'), duration: const Duration(seconds: 8)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final update = ref.watch(updateProvider);
    final local = kAppVersionLabel;

    return Scaffold(
      appBar: AppBar(
        title: Text('Atualizações', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SurfacePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.system_update_rounded, color: cs.primary, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Versão instalada',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'v$local',
                            style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ),
                    if (update.hasUpdate)
                      Chip(
                        backgroundColor: cs.tertiaryContainer,
                        side: BorderSide.none,
                        avatar: Icon(Icons.new_releases_rounded, color: cs.tertiary, size: 18),
                        label: Text(
                          'Nova',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onTertiaryContainer),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                if (update.checking)
                  Row(
                    children: [
                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary)),
                      const SizedBox(width: 12),
                      Text('Verificando atualizações...', style: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.7))),
                    ],
                  )
                else if (update.error != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: cs.errorContainer.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: cs.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(update.error!, style: TextStyle(fontSize: 13, color: cs.onErrorContainer))),
                      ],
                    ),
                  )
                else if (update.hasUpdate)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [cs.tertiaryContainer.withOpacity(0.5), cs.primaryContainer.withOpacity(0.3)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nova versão disponível',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Versão $local → ${update.latestVersion ?? '-'}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        if (update.publishedAt?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Publicada em: ${update.publishedAt}',
                            style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.6)),
                          ),
                        ],
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () async {
                            final url = update.zipUrl;
                            if (url == null || url.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Link da nova versão não encontrado. Abra pelo GitHub.')),
                              );
                              return;
                            }
                            // Dialogo de confirmacao antes de baixar/fechar o app.
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Atualizar agora?'),
                                content: Text(
                                  'O app vai baixar o instalador da versão '
                                  '${update.latestVersion ?? '-'} e fechá-lo '
                                  'automaticamente.\n\n'
                                  'Depois o instalador será aberto — clique '
                                  'Avançar/Instalar para concluir.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Atualizar'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true) return;
                            await _doUpdate(url, update.latestVersion ?? '-');
                          },
                          icon: const Icon(Icons.download_for_offline_rounded),
                          label: const Text('Atualizar agora'),
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: () => _openRelease(update.releaseUrl),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('Baixar manualmente no GitHub'),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: cs.primaryContainer.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Icon(Icons.verified_rounded, color: cs.primary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Você está na versão mais recente.',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onPrimaryContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.tonal(
            onPressed: _checkUpdate,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.refresh_rounded, size: 18),
                SizedBox(width: 8),
                Text('Verificar novamente'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'As atualizações são baixadas do GitHub Releases. Você precisa de conexão com a internet para atualizar.',
            style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.6), height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
