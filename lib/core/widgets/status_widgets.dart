import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';

/// Banner mínimo: só alerta se backend morto. Sucesso = linha discreta ou nada.
class BackendStatusBanner extends ConsumerStatefulWidget {
  const BackendStatusBanner({super.key});

  @override
  ConsumerState<BackendStatusBanner> createState() => _BackendStatusBannerState();
}

class _BackendStatusBannerState extends ConsumerState<BackendStatusBanner> {
  bool? online;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      await apiClient.get('/health');
      if (mounted) setState(() => online = true);
    } catch (_) {
      if (mounted) setState(() => online = false);
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
              'Feche e abra de novo pelo ícone PAES MED AI na área de trabalho.',
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
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.28)),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                    ),
              ),
              if (cta != null) ...[const SizedBox(height: 16), cta],
            ],
          ),
        ),
      ),
    );
  }
}
