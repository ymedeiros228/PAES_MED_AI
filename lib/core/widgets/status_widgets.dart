import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import '../data/api_error.dart';
import '../data/study_prefs_providers.dart';
import '../theme/app_fonts.dart';
import '../theme/app_theme.dart';

/// Banner mínimo: só alerta se backend morto. Sucesso = linha discreta ou nada.
/// Auto-retry a cada 10s quando offline — recupera sem precisar de botão.
class BackendStatusBanner extends ConsumerStatefulWidget {
  const BackendStatusBanner({super.key});

  @override
  ConsumerState<BackendStatusBanner> createState() => _BackendStatusBannerState();
}

class _BackendStatusBannerState extends ConsumerState<BackendStatusBanner> {
  bool? online;
  String? lastError;
  Timer? _retryTimer;
  int _retrySeconds = 10;

  @override
  void initState() {
    super.initState();
    // Da um tempo para o backend iniciar antes de checar
    Future.delayed(const Duration(seconds: 2), _check);
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _startAutoRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _retrySeconds--);
      if (_retrySeconds <= 0) {
        t.cancel();
        _check();
      }
    });
  }

  Future<void> _check() async {
    try {
      await apiClient.get('/health');
      if (mounted) {
        setState(() {
          online = true;
          lastError = null;
        });
        _retryTimer?.cancel();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          online = false;
          lastError = humanApiError(e, fallback: 'Aplicativo sem internet.');
          _retrySeconds = 10;
        });
        _startAutoRetry();
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
              style: TextStyle(color: cs.onErrorContainer.f90, fontSize: 12),
            ),
            trailing: FilledButton(
              onPressed: _check,
              child: Text(_retrySeconds > 0 ? 'Tentar ($_retrySeconds)' : 'Tentar'),
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

/// Estado vazio (tela/aba sem conteúdo ainda) com ação opcional.
///
/// ```dart
/// EmptyState(
///   icon: Icons.style_outlined,
///   title: 'Nenhum flashcard ainda',
///   subtitle: 'Erre uma questão na sessão e o card nasce sozinho.',
///   actionLabel: 'Abrir sessão',
///   onAction: () => context.go('/sessao'),
/// )
/// ```
/// Para falhas de carregamento use `ErrorState` (tem "Tentar de novo").
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.subtitle,
    this.action,
    this.actionLabel,
    this.onAction,
    this.icon,
    super.key,
  });
  final String title;
  final String subtitle;
  final Widget? action;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

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
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon ?? Icons.auto_stories_outlined,
                    size: 28,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: AppFonts.display(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.f72,
                    height: 1.55,
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
