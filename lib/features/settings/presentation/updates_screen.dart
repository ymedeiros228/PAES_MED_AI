import 'dart:io' show exit;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_version.dart';
import '../../../core/theme/app_theme.dart';
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
  Future<void> _doUpdate(String url, String version) async {
    final messenger = ScaffoldMessenger.of(context);

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

      if (mounted) Navigator.pop(context);

      if (!ok) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(msg), duration: const Duration(seconds: 8)),
          );
        }
        return;
      }

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Instalador aberto. O app vai fechar agora...'),
            duration: Duration(seconds: 5),
          ),
        );
      }
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

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: 'Utilidades',
                title: 'Atualizações',
                subtitle: 'Versão instalada v$local',
                icon: Icons.system_update_rounded,
                trailing: update.hasUpdate
                    ? Chip(
                        backgroundColor: cs.tertiaryContainer,
                        side: BorderSide.none,
                        avatar: Icon(Icons.new_releases_rounded, color: cs.tertiary, size: 18),
                        label: Text(
                          'Nova',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: cs.onTertiaryContainer,
                          ),
                        ),
                      )
                    : null,
              ),
              if (update.checking)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (update.error != null)
                QuietEmpty(
                  message: update.error!,
                  action: TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _checkUpdate();
                    },
                    child: const Text('Tentar de novo'),
                  ),
                )
              else if (update.hasUpdate)
                SurfacePanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Nova versão disponível',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'v$local → ${update.latestVersion ?? '-'}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                      ),
                      if (update.publishedAt?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Publicada em: ${update.publishedAt}',
                          style: TextStyle(fontSize: 12, color: cs.onSurface.f72),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () async {
                          final url = update.zipUrl;
                          if (url == null || url.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Link da nova versão não encontrado. Abra pelo GitHub.'),
                              ),
                            );
                            return;
                          }
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
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _openRelease(update.releaseUrl),
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('Baixar no GitHub'),
                      ),
                    ],
                  ),
                )
              else
                QuietEmpty(
                  message: 'Você está em dia — versão mais recente instalada.',
                  action: FilledButton.tonalIcon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _checkUpdate();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Verificar novamente'),
                  ),
                ),
              if (!update.checking && update.error == null && update.hasUpdate) ...[
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: _checkUpdate,
                  child: const Text('Verificar novamente'),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Atualizações vêm do GitHub Releases. É preciso internet para baixar.',
                style: TextStyle(fontSize: 12, color: cs.onSurface.f72, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
