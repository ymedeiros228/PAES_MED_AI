import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../data/study_prefs_providers.dart';
import '../data/theme_mode_provider.dart';
import '../theme/app_theme.dart';
import 'status_widgets.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const focusItems = <_NavItem>[
    _NavItem('/dashboard', 'Hoje', Icons.home_rounded),
    _NavItem('/sessao', 'Sessão', Icons.timer_rounded),
    _NavItem('/fila', 'Fila', Icons.playlist_play_rounded),
    _NavItem('/flashcards', 'Cards', Icons.style_rounded),
    _NavItem('/biblioteca', 'Biblioteca', Icons.menu_book_rounded),
    _NavItem('/tutor', 'Tutor', Icons.auto_awesome_rounded),
    _NavItem('/configuracoes', 'Ajustes', Icons.settings_rounded),
  ];

  /// Rotas avançadas: em modo foco redirecionam ao Hoje.
  static const _focusHostile = <String>{
    '/aprovacao',
    '/banca',
    '/aulas',
    '/cronograma',
    '/medicina',
  };

  /// Rotas de estudo permitidas no foco (além da rail).
  static bool _focusAllowed(String path) {
    const allowed = <String>[
      '/dashboard',
      '/sessao',
      '/fila',
      '/flashcards',
      '/biblioteca',
      '/tutor',
      '/configuracoes',
      '/questoes',
      '/simulados',
      '/revisoes',
      '/adaptativo',
      '/redacao',
      '/progresso',
      '/onboarding',
    ];
    return allowed.any((p) => path == p || path.startsWith('$p/'));
  }

  List<_NavGroup> _groups({required int officialCount}) {
    return [
      const _NavGroup('Estudar', [
        _NavItem('/dashboard', 'Hoje', Icons.home_rounded),
        _NavItem('/sessao', 'Sessão', Icons.timer_rounded),
        _NavItem('/fila', 'Fila', Icons.playlist_play_rounded),
        _NavItem('/questoes', 'Questões', Icons.quiz_rounded),
        _NavItem('/simulados', 'Simulados', Icons.bolt_rounded),
        _NavItem('/cronograma', 'Plano', Icons.calendar_month_rounded),
        _NavItem('/flashcards', 'Cards', Icons.style_rounded),
        _NavItem('/tutor', 'Tutor', Icons.auto_awesome_rounded),
      ]),
      const _NavGroup('Analisar', [
        _NavItem('/progresso', 'Progresso', Icons.terrain_rounded),
        _NavItem('/medicina', 'Domínio', Icons.local_hospital_rounded),
        _NavItem('/banca', 'Banca', Icons.analytics_rounded),
        _NavItem('/revisoes', 'Revisões', Icons.replay_circle_filled_rounded),
      ]),
      const _NavGroup('Conteúdo', [
        _NavItem('/biblioteca', 'Biblioteca', Icons.menu_book_rounded),
        _NavItem('/aulas', 'Aulas', Icons.video_library_rounded),
        _NavItem('/redacao', 'Redação', Icons.edit_note_rounded),
        _NavItem('/adaptativo', 'Treino', Icons.psychology_rounded),
      ]),
      const _NavGroup('Conta', [
        _NavItem('/configuracoes', 'Ajustes', Icons.settings_rounded),
      ]),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = ref.watch(focusModeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final examDays = ref.watch(examDateProvider.notifier).daysUntilExam;
    final examSyncPending = ref.watch(examDateProvider).syncError != null;
    final location = GoRouterState.of(context).uri.path;
    final dash = ref.watch(dashboardProvider);
    final officialCount = dash.maybeWhen(
      data: (d) {
        final basis = d['statsBasis'];
        if (basis is Map) return (basis['officialCount'] as int?) ?? 0;
        return (d['officialCount'] as int?) ?? 0;
      },
      orElse: () => 0,
    );

    final activeGroups = focus
        ? [const _NavGroup('Foco', focusItems)]
        : _groups(officialCount: officialCount);

    final items = [for (final g in activeGroups) ...g.items];
    var index = items.indexWhere((item) => location == item.path || location.startsWith('${item.path}/'));
    if (index < 0) index = 0;

    if (focus &&
        (_focusHostile.any((p) => location == p || location.startsWith('$p/')) ||
            !_focusAllowed(location))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/dashboard');
      });
    }

    final cs = Theme.of(context).colorScheme;
    final bright = Theme.of(context).brightness;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF): () {
          ref.read(focusModeProvider.notifier).setFocus(!focus);
        },
        const SingleActivator(LogicalKeyboardKey.keyT, control: true): () {
          ref.read(themeModeProvider.notifier).cycle();
        },
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1000;
            final expanded = constraints.maxWidth >= 1180;

            final rail = AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: expanded ? 236 : 84,
              decoration: BoxDecoration(
                gradient: AppTheme.railGradient(bright),
                border: Border(right: BorderSide(color: cs.outlineVariant.withOpacity(0.7))),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
                      children: [
                        _BrandHeader(
                          expanded: expanded,
                          focus: focus,
                          examDays: examDays,
                          examSyncPending: examSyncPending,
                        ),
                        const SizedBox(height: 18),
                        for (final group in activeGroups) ...[
                          if (expanded)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
                              child: Text(
                                group.label.toUpperCase(),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: cs.onSurface.withOpacity(0.38),
                                      letterSpacing: 1.4,
                                    ),
                              ),
                            ),
                          for (final item in group.items)
                            _NavTile(
                              item: item,
                              expanded: expanded,
                              selected: location == item.path || location.startsWith('${item.path}/'),
                              badge: item.path == '/configuracoes' && examSyncPending,
                              onTap: () => context.go(item.path),
                            ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
                    child: Column(
                      children: [
                        _RailControl(
                          expanded: expanded,
                          icon: focus ? Icons.visibility_rounded : Icons.center_focus_strong_rounded,
                          label: focus ? 'Foco ligado' : 'Foco',
                          active: focus,
                          onTap: () => ref.read(focusModeProvider.notifier).setFocus(!focus),
                        ),
                        const SizedBox(height: 6),
                        _RailControl(
                          expanded: expanded,
                          icon: themeNotifier.icon,
                          label: themeNotifier.label,
                          active: themeMode != ThemeMode.system,
                          onTap: () => themeNotifier.cycle(),
                        ),
                        if (expanded) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Tecla F: modo foco',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: cs.onSurface.withOpacity(0.42),
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );

            final body = DecoratedBox(
              decoration: BoxDecoration(gradient: AppTheme.scaffoldGradientFor(bright)),
              child: Column(
                children: [
                  const BackendStatusBanner(),
                  const ExamDateSyncBanner(),
                  Expanded(child: child),
                ],
              ),
            );

            if (wide) {
              return Scaffold(
                body: Row(
                  children: [
                    rail,
                    Expanded(child: body),
                  ],
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(focus ? 'PAES · Foco' : 'PAES MED AI'),
                    if (examSyncPending)
                      Text(
                        'Data da prova pendente',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.tertiary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                  ],
                ),
                actions: [
                  if (examSyncPending)
                    IconButton(
                      tooltip: 'Sincronizar data da prova',
                      onPressed: () => ref.read(examDateProvider.notifier).retrySync(),
                      icon: Badge(
                        smallSize: 8,
                        child: const Icon(Icons.sync_problem_rounded),
                      ),
                    ),
                  IconButton(
                    tooltip: 'Tema (${themeNotifier.label}) · Ctrl+T',
                    onPressed: () => themeNotifier.cycle(),
                    icon: Icon(themeNotifier.icon),
                  ),
                  IconButton(
                    tooltip: focus ? 'Sair do foco' : 'Modo foco',
                    onPressed: () => ref.read(focusModeProvider.notifier).setFocus(!focus),
                    icon: Icon(focus ? Icons.visibility_rounded : Icons.center_focus_strong_rounded),
                  ),
                  IconButton(
                    tooltip: 'Ir ao Tutor',
                    onPressed: () => context.go('/tutor'),
                    icon: const Icon(Icons.auto_awesome_rounded),
                  ),
                  PopupMenuButton<String>(
                    tooltip: examSyncPending ? 'Menu · data da prova pendente' : 'Menu',
                    onSelected: context.go,
                    icon: examSyncPending
                        ? Badge(
                            smallSize: 8,
                            child: const Icon(Icons.menu_rounded),
                          )
                        : const Icon(Icons.menu_rounded),
                    itemBuilder: (_) => [
                      for (final item in items)
                        PopupMenuItem(
                          value: item.path,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.path == '/configuracoes' && examSyncPending
                                      ? '${item.label} · data da prova pendente'
                                      : item.label,
                                ),
                              ),
                              if (item.path == '/configuracoes' && examSyncPending)
                                Icon(Icons.circle, size: 8, color: cs.tertiary),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              body: body,
              bottomNavigationBar: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (examSyncPending)
                    Material(
                      color: cs.tertiaryContainer.withOpacity(0.85),
                      child: SafeArea(
                        top: false,
                        child: ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: Icon(Icons.sync_problem_rounded, size: 18, color: cs.onTertiaryContainer),
                          title: Text(
                            'Data da prova não sincronizou',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: cs.onTertiaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          trailing: TextButton(
                            onPressed: () => context.go('/configuracoes'),
                            child: const Text('Ajustes'),
                          ),
                        ),
                      ),
                    ),
                  NavigationBar(
                    selectedIndex: index.clamp(0, (items.length - 1).clamp(0, 4)),
                    onDestinationSelected: (value) =>
                        context.go(items[value.clamp(0, items.length - 1)].path),
                    destinations: [
                      for (final item in items.take(5))
                        NavigationDestination(
                          icon: Icon(item.icon),
                          label: item.label,
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({
    required this.expanded,
    required this.focus,
    required this.examDays,
    required this.examSyncPending,
  });

  final bool expanded;
  final bool focus;
  final int? examDays;
  final bool examSyncPending;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!expanded) {
      return Center(
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.local_hospital_rounded, color: cs.primary, size: 22),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.local_hospital_rounded, color: cs.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAES MED',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                    ),
                    Text(
                      focus ? 'Modo foco' : 'Medicina · UEMA',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (examSyncPending) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.sync_problem_rounded, size: 14, color: cs.tertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Data da prova pendente',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ],
          if (examDays != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                examDays! >= 0 ? '$examDays dias para a prova' : 'Data da prova passou',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.item,
    required this.expanded,
    required this.selected,
    required this.onTap,
    this.badge = false,
  });

  final _NavItem item;
  final bool expanded;
  final bool selected;
  final VoidCallback onTap;
  final bool badge;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = widget.selected
        ? cs.primaryContainer.withOpacity(0.85)
        : hovered
            ? cs.surfaceContainerHigh.withOpacity(0.6)
            : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: widget.item.label,
        child: Semantics(
          button: true,
          label: widget.item.label,
          selected: widget.selected,
          child: MouseRegion(
            onEnter: (_) => setState(() => hovered = true),
            onExit: (_) => setState(() => hovered = false),
            child: Material(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: widget.selected
                        ? Border(
                            left: BorderSide(color: cs.primary, width: 3),
                          )
                        : null,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: widget.expanded ? 12 : 0),
                  child: Row(
                    mainAxisAlignment: widget.expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            widget.item.icon,
                            size: 22,
                            color: widget.selected ? cs.primary : cs.onSurface.withOpacity(0.55),
                          ),
                          if (widget.badge)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: cs.tertiary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: cs.surface, width: 1),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (widget.expanded) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                                  color: widget.selected
                                      ? cs.onPrimaryContainer
                                      : cs.onSurface.withOpacity(0.78),
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RailControl extends StatelessWidget {
  const _RailControl({
    required this.expanded,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final bool expanded;
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: active ? cs.primaryContainer.withOpacity(0.55) : cs.surfaceContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 42,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(icon, size: 20, color: cs.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              label,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Icon(icon, size: 20, color: cs.primary),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavGroup {
  const _NavGroup(this.label, this.items);
  final String label;
  final List<_NavItem> items;
}

class _NavItem {
  const _NavItem(this.path, this.label, this.icon);
  final String path;
  final String label;
  final IconData icon;
}
