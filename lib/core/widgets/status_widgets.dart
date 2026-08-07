import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import '../data/api_error.dart';
import '../data/study_prefs_providers.dart';

/// Banner mínimo: só alerta se backend morto. Sucesso = linha discreta ou nada.
class BackendStatusBanner extends ConsumerStatefulWidget {
  const BackendStatusBanner({super.key});

  @override
  ConsumerState<BackendStatusBanner> createState() => _BackendStatusBannerState();
}

class _BackendStatusBannerState extends ConsumerState<BackendStatusBanner> {
  bool? online;
  String? lastError;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      await apiClient.get('/health');
      if (mounted) setState(() {
        online = true;
        lastError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          online = false;
          lastError = humanApiError(e, fallback: 'API local offline.');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Online e estável: some (não polui o estudo).
    if (online == true) return const SizedBox.shrink();
    if (online == false) {
      return Material(
        color: cs.errorContainer,
        child: SafeArea(
          bottom: false,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.wifi_off_rounded, color: cs.error),
            title: Text(
              'Sem conexão local',
              style: TextStyle(color: cs.onErrorContainer, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              lastError ??
                  'Feche e abra de novo pelo ícone PAES MED AI · Hoje pode ter sessão salva.',
              style: TextStyle(color: cs.onErrorContainer.withOpacity(0.9), fontSize: 12),
            ),
            trailing: FilledButton(
              onPressed: _check,
              child: const Text('Tentar'),
            ),
          ),
        ),
      );
    }
    return LinearProgressIndicator(
      minHeight: 2,
      color: cs.primary,
      backgroundColor: cs.surfaceContainerHighest,
    );
  }
}

/// Data da prova salva localmente mas não sincronizou com a API (Ciclo GK).
class ExamDateSyncBanner extends ConsumerWidget {
  const ExamDateSyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncError = ref.watch(examDateProvider).syncError;
    if (syncError == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.tertiaryContainer,
      child: SafeArea(
        bottom: false,
        child: ListTile(
          dense: true,
          leading: Icon(Icons.sync_problem_rounded, color: cs.onTertiaryContainer),
          title: Text(
            'Data da prova não sincronizou',
            style: TextStyle(color: cs.onTertiaryContainer, fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            syncError,
            style: TextStyle(color: cs.onTertiaryContainer.withOpacity(0.9), fontSize: 12),
          ),
          trailing: TextButton(
            onPressed: () => ref.read(examDateProvider.notifier).retrySync(),
            child: const Text('Atualizar'),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.subtitle,
    this.action,
    this.actionLabel,
    this.onAction,
    super.key,
  });
  final String title;
  final String subtitle;
  final Widget? action;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cta = action ??
        (actionLabel != null && onAction != null
            ? FilledButton(onPressed: onAction, child: Text(actionLabel!))
            : null);
    final labelParts = <String>[title, subtitle];
    if (actionLabel != null) labelParts.add(actionLabel!);
    return Semantics(
      label: labelParts.join('. '),
      button: cta != null,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withOpacity(0.65),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_stories_outlined,
                    size: 34,
                    color: cs.primary.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.65),
                        height: 1.4,
                      ),
                ),
                if (cta != null) ...[const SizedBox(height: 20), cta],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
