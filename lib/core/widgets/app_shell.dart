import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  List<_NavGroup> _groups() {
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

    // Não assinar dashboardProvider na shell: contagem de oficiais era dead-weight
    // e re-disparava o endpoint pesado em toda navegação / rebuild da rail.
    final activeGroups = focus
        ? [const _NavGroup('Foco', focusItems)]
        : _groups();

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
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              width: expanded ? 248 : 88,
              decoration: BoxDecoration(
                gradient: AppTheme.railGradient(bright),
                border: Border(
                  right: BorderSide(color: Colors.white.withOpacity(0.06)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.22),
                    blurRadius: 24,
                    offset: const Offset(4, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 22, 12, 8),
                      children: [
                        _BrandHeader(
                          expanded: expanded,
                          focus: focus,
                          examDays: examDays,
                          examSyncPending: examSyncPending,
                        ),
                        const SizedBox(height: 22),
                        for (final group in activeGroups) ...[
                          if (expanded)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                              child: Text(
                                group.label.toUpperCase(),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppTheme.railMuted.withOpacity(0.75),
                                      letterSpacing: 1.8,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
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
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
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
                          const SizedBox(height: 12),
                          Text(
                            'F foco · Ctrl+T tema',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.railMuted.withOpacity(0.7),
                                  fontSize: 10.5,
                                  letterSpacing: 0.3,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );

            final body = Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: AppTheme.scaffoldGradientFor(bright)),
                  ),
                ),
                // Glow atmosférico (canto) — presença de plataforma
                Positioned(
                  top: -120,
                  right: -80,
                  child: IgnorePointer(
                    child: Container(
                      width: 340,
                      height: 340,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            cs.primary.withOpacity(bright == Brightness.dark ? 0.12 : 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -100,
                  left: 40,
                  child: IgnorePointer(
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.navy.withOpacity(bright == Brightness.dark ? 0.25 : 0.04),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    const BackendStatusBanner(),
                    const ExamDateSyncBanner(),
                    Expanded(child: child),
                  ],
                ),
              ],
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
    if (!expanded) {
      return Center(
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1FA887), Color(0xFF0C7A63)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.teal.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 22),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1FA887), Color(0xFF0C7A63)],
                  ),
                ),
                child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAES MED',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: AppTheme.railText,
                            fontFamily: 'Georgia',
                            fontSize: 17,
                          ),
                    ),
                    Text(
                      focus ? 'Modo foco' : 'Studio · UEMA',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.teal,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (examSyncPending) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.sync_problem_rounded, size: 14, color: AppTheme.warning),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Data da prova pendente',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.warning,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ],
          if (examDays != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Text(
                examDays! >= 0 ? '$examDays dias para a prova' : 'Data da prova passou',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.railText.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                    ),
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
    final bg = widget.selected
        ? AppTheme.teal.withOpacity(0.16)
        : hovered
            ? Colors.white.withOpacity(0.06)
            : Colors.transparent;
    final iconColor = widget.selected
        ? const Color(0xFF3ED4B0)
        : AppTheme.railMuted.withOpacity(hovered ? 0.95 : 0.75);

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
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  height: 46,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                    border: widget.selected
                        ? Border.all(color: AppTheme.teal.withOpacity(0.28))
                        : null,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: widget.expanded ? 12 : 0),
                  child: Row(
                    mainAxisAlignment:
                        widget.expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                    children: [
                      if (widget.selected && widget.expanded)
                        Container(
                          width: 3,
                          height: 22,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3ED4B0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )
                      else if (widget.expanded)
                        const SizedBox(width: 13),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(widget.item.icon, size: 22, color: iconColor),
                          if (widget.badge)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppTheme.warning,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.railInk, width: 1),
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
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: widget.selected
                                      ? AppTheme.railText
                                      : AppTheme.railMuted.withOpacity(0.92),
                                  fontWeight:
                                      widget.selected ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 13.2,
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
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: active
              ? AppTheme.teal.withOpacity(0.18)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 42,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(icon, size: 20, color: const Color(0xFF3ED4B0)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              label,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppTheme.railText,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Icon(icon, size: 20, color: const Color(0xFF3ED4B0)),
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
