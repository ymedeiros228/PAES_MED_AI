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
                            final messenger = ScaffoldMessenger.of(context);
                            final url = update.zipUrl;
                            if (url == null || url.isEmpty) {
                              messenger.showSnackBar(
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

                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Baixando instalador... aguarde.'),
                                duration: Duration(seconds: 5),
                              ),
                            );
                            final (ok, msg) = await runNativeUpdater(url);
                            if (!ok) {
                              messenger.showSnackBar(
                                SnackBar(content: Text(msg), duration: const Duration(seconds: 6)),
                              );
                            } else {
                              // Sucesso: o instalador foi lancado diretamente.
                              // O Inno Setup vai fechar o app via CloseApplications.
                              // Damos um tempinho e fechamos para liberar os arquivos.
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Instalador aberto. O app vai fechar agora...'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                              await Future.delayed(const Duration(seconds: 2));
                              exit(0);
                            }
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
