import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth.dart';
import '../data/study_prefs_providers.dart';
import '../data/theme_mode_provider.dart';
import '../theme/app_fonts.dart';
import '../theme/app_theme.dart';
import 'status_widgets.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  /// Menu enxuto do modo foco (Ajustes fica no rodapé).
  static const focusItems = <_NavItem>[
    _NavItem('/dashboard', 'Início', Icons.home_rounded),
    _NavItem('/sessao', 'Sessão guiada', Icons.school_rounded),
    _NavItem('/materiais', 'Materiais', Icons.picture_as_pdf_rounded),
    _NavItem('/flashcards', 'Flashcards', Icons.style_rounded),
    _NavItem('/tutor', 'Tutor IA', Icons.auto_awesome_rounded),
  ];

  /// Rotas permitidas no modo foco (estudo + essenciais; sem plano/domínio/banca).
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
      '/conquistas',
      '/materiais',
      '/estudar',
      '/onboarding',
    ];
    return allowed.any((p) => path == p || path.startsWith('$p/'));
  }

  /// Navegação agrupada. O 1º grupo (o dia) não tem título; Ajustes fica no rodapé.
  static const navGroups = <(String, List<_NavItem>)>[
    ('', [
      _NavItem('/dashboard', 'Início', Icons.home_rounded),
      _NavItem('/sessao', 'Sessão guiada', Icons.school_rounded),
    ]),
    ('Praticar', [
      _NavItem('/questoes', 'Questões', Icons.quiz_outlined),
      _NavItem('/simulados', 'Simulados', Icons.assignment_rounded),
      _NavItem('/redacao', 'Redação', Icons.edit_note_rounded),
      _NavItem('/flashcards', 'Flashcards', Icons.style_rounded),
      _NavItem('/revisoes', 'Revisões', Icons.replay_rounded),
    ]),
    ('Aprender', [
      _NavItem('/materiais', 'Materiais', Icons.picture_as_pdf_rounded),
      _NavItem('/biblioteca', 'Biblioteca', Icons.menu_book_rounded),
      _NavItem('/tutor', 'Tutor IA', Icons.auto_awesome_rounded),
    ]),
    ('Acompanhar', [
      _NavItem('/progresso', 'Progresso', Icons.trending_up_rounded),
      _NavItem('/medicina', 'Domínio', Icons.insights_rounded),
      _NavItem('/banca', 'Banca', Icons.account_balance_outlined),
      _NavItem('/cronograma', 'Cronograma', Icons.calendar_month_outlined),
    ]),
  ];

  static const _ajustes = _NavItem('/configuracoes', 'Ajustes', Icons.settings_rounded);

  /// Abas da barra inferior (janela estreita). A última abre o resto do menu.
  static const mainItems = <_NavItem>[
    _NavItem('/dashboard', 'Início', Icons.home_rounded),
    _NavItem('/sessao', 'Estudar', Icons.school_rounded),
    _NavItem('/questoes', 'Questões', Icons.quiz_outlined),
    _NavItem('/materiais', 'Materiais', Icons.picture_as_pdf_rounded),
    _NavItem('', 'Mais', Icons.menu_rounded),
  ];

  /// Qual aba da barra inferior representa a rota atual.
  static int _bottomIndexFor(String path) {
    bool em(List<String> rotas) => rotas.any((p) => path == p || path.startsWith('$p/'));
    if (em(['/dashboard'])) return 0;
    if (em(['/sessao', '/fila', '/simulados', '/flashcards', '/revisoes', '/redacao', '/adaptativo', '/foco'])) {
      return 1;
    }
    if (em(['/questoes'])) return 2;
    if (em(['/materiais', '/estudar', '/biblioteca', '/aulas'])) return 3;
    return 4;
  }

  static bool _isSelected(String location, String path) =>
      location == path || location.startsWith('$path/');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = ref.watch(focusModeProvider);
    ref.watch(themeModeProvider);
    final countdown = ref.watch(examCountdownProvider);
    final examSyncPending = ref.watch(examDateProvider).syncError != null;
    final location = GoRouterState.of(context).uri.path;

    if (focus && !_focusAllowed(location)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/dashboard');
      });
    }

    final cs = Theme.of(context).colorScheme;
    final bright = Theme.of(context).brightness;
    final groups = focus ? [('Modo foco', focusItems)] : navGroups;

    void go(String path) {
      HapticFeedback.selectionClick();
      context.go(path);
    }

    void toggleTheme() => ref.read(themeModeProvider.notifier).toggle(bright);
    void toggleFocus() => ref.read(focusModeProvider.notifier).setFocus(!focus);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;
        final expanded = constraints.maxWidth >= 1180;

        final body = DecoratedBox(
          decoration: BoxDecoration(gradient: AppTheme.scaffoldGradientFor(bright)),
          child: Column(
            children: [
              // Banners de status mudam raramente — isolam do conteúdo.
              const RepaintBoundary(child: BackendStatusBanner()),
              const RepaintBoundary(child: ExamDateSyncBanner()),
              Expanded(child: child),
            ],
          ),
        );

        if (wide) {
          final rail = AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: expanded ? 232 : 76,
            decoration: BoxDecoration(
              gradient: AppTheme.railGradient(bright),
              border: Border(right: BorderSide(color: cs.outlineVariant.withOpacity(0.7))),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(expanded ? 12 : 10, 16, expanded ? 12 : 10, 8),
                    children: [
                      _BrandHeader(
                        expanded: expanded,
                        countdown: countdown,
                        onSetDate: () => go('/configuracoes'),
                      ),
                      for (final group in groups) ...[
                        if (group.$1.isEmpty)
                          const SizedBox(height: 10)
                        else if (expanded)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                            child: Text(
                              group.$1.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.f55,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
                            child: Divider(height: 1, color: cs.outlineVariant),
                          ),
                        for (final item in group.$2)
                          _NavTile(
                            item: item,
                            expanded: expanded,
                            selected: _isSelected(location, item.path),
                            onTap: () => go(item.path),
                          ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(expanded ? 12 : 10, 8, expanded ? 12 : 10, 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: cs.outlineVariant.withOpacity(0.6))),
                  ),
                  child: _RailFooter(
                    expanded: expanded,
                    location: location,
                    focus: focus,
                    dark: bright == Brightness.dark,
                    settingsBadge: examSyncPending,
                    onSettings: () => go(_ajustes.path),
                    onToggleTheme: toggleTheme,
                    onToggleFocus: toggleFocus,
                  ),
                ),
              ],
            ),
          );

          return Scaffold(
            body: Row(
              children: [
                // Isola repaints do rail (hover/seleção) do conteúdo da rota ativa.
                RepaintBoundary(child: rail),
                Expanded(child: RepaintBoundary(child: body)),
              ],
            ),
          );
        }

        final bottomIndex = _bottomIndexFor(location);
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 16,
            title: Row(
              children: [
                const _BrandMark(size: 32),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    focus ? 'PAES MED · Foco' : 'PAES MED',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              if (countdown.isUpcoming || countdown.isToday)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Center(
                    child: Text(
                      countdown.isToday ? 'Prova hoje' : (countdown.daysLeft == 1 ? '1 dia' : '${countdown.daysLeft} dias'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ).copyWith(fontFeatures: AppFonts.tabular),
                    ),
                  ),
                ),
              IconButton(
                tooltip: 'Tutor IA',
                onPressed: () => go('/tutor'),
                icon: const Icon(Icons.auto_awesome_rounded),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: bottomIndex,
            onDestinationSelected: (value) {
              final item = mainItems[value];
              if (item.path.isEmpty) {
                HapticFeedback.selectionClick();
                _showMoreSheet(
                  context,
                  groups: groups,
                  location: location,
                  focus: focus,
                  dark: bright == Brightness.dark,
                  settingsBadge: examSyncPending,
                  onGo: go,
                  onToggleTheme: toggleTheme,
                  onToggleFocus: toggleFocus,
                );
                return;
              }
              go(item.path);
            },
            destinations: [
              for (final item in mainItems)
                NavigationDestination(
                  icon: item.path == '' && examSyncPending
                      ? Badge(smallSize: 8, child: Icon(item.icon))
                      : Icon(item.icon),
                  label: item.label,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Folha "Mais" do celular: o menu inteiro + tema, foco e sair.
void _showMoreSheet(
  BuildContext context, {
  required List<(String, List<_NavItem>)> groups,
  required String location,
  required bool focus,
  required bool dark,
  required bool settingsBadge,
  required void Function(String) onGo,
  required VoidCallback onToggleTheme,
  required VoidCallback onToggleFocus,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final cs = Theme.of(sheetContext).colorScheme;
      void pick(String path) {
        Navigator.of(sheetContext).pop();
        onGo(path);
      }

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [
              for (final group in groups) ...[
                if (group.$1.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
                    child: Text(
                      group.$1.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.f55,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                for (final item in group.$2)
                  _NavTile(
                    item: item,
                    expanded: true,
                    selected: AppShell._isSelected(location, item.path),
                    onTap: () => pick(item.path),
                  ),
              ],
              const SizedBox(height: 8),
              Divider(height: 1, color: cs.outlineVariant),
              const SizedBox(height: 8),
              _NavTile(
                item: AppShell._ajustes,
                expanded: true,
                selected: AppShell._isSelected(location, AppShell._ajustes.path),
                badge: settingsBadge,
                onTap: () => pick(AppShell._ajustes.path),
              ),
              _NavTile(
                item: _NavItem('', dark ? 'Tema claro' : 'Tema escuro',
                    dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                expanded: true,
                selected: false,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onToggleTheme();
                },
              ),
              _NavTile(
                item: _NavItem('', focus ? 'Sair do modo foco' : 'Modo foco (menu enxuto)',
                    Icons.center_focus_strong_rounded),
                expanded: true,
                selected: false,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onToggleFocus();
                },
              ),
              if (auth.sessao?.exigeLogin ?? false)
                _NavTile(
                  item: _NavItem('', 'Sair · ${auth.sessao!.nomeExibido}', Icons.logout_rounded),
                  expanded: true,
                  selected: false,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    auth.sair();
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// Marca do app (cruz médica num quadrado arredondado).
class _BrandMark extends StatelessWidget {
  const _BrandMark({this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(size * 0.31),
      ),
      child: Icon(Icons.local_hospital_rounded, color: cs.primary, size: size * 0.5),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({
    required this.expanded,
    required this.countdown,
    required this.onSetDate,
  });

  final bool expanded;
  final ExamCountdown countdown;
  final VoidCallback onSetDate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cd = countdown;
    if (!expanded) {
      return Tooltip(
        message: cd.shortLabel,
        child: const Center(child: _BrandMark(size: 40)),
      );
    }

    final contando = cd.isUpcoming || cd.isToday;
    final linha = cd.isToday
        ? 'A prova é hoje'
        : cd.isUpcoming
            ? (cd.daysLeft == 1 ? 'A prova é amanhã' : 'Prova em ${cd.daysLeft} dias')
            : 'Definir a data da prova';

    final countdownRow = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: [
          Icon(
            contando ? Icons.event_rounded : Icons.event_busy_rounded,
            size: 16,
            color: contando ? cs.primary : cs.tertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              linha,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.f85)
                  .copyWith(fontFeatures: AppFonts.tabular),
            ),
          ),
          if (contando) ...[
            const SizedBox(width: 8),
            Text(
              cd.dateLabel,
              style: TextStyle(fontSize: 12, color: cs.onSurface.f55).copyWith(fontFeatures: AppFonts.tabular),
            ),
          ],
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              const _BrandMark(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAES MED',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      'Medicina · UEMA',
                      style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (contando)
          Semantics(label: cd.shortLabel, excludeSemantics: true, child: countdownRow)
        else
          Semantics(
            button: true,
            label: '${cd.shortLabel}. Abrir Ajustes.',
            excludeSemantics: true,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onSetDate,
                borderRadius: BorderRadius.circular(10),
                child: countdownRow,
              ),
            ),
          ),
      ],
    );
  }
}

/// Rodapé do menu: Ajustes + botões de tema, foco e sair.
class _RailFooter extends StatelessWidget {
  const _RailFooter({
    required this.expanded,
    required this.location,
    required this.focus,
    required this.dark,
    required this.settingsBadge,
    required this.onSettings,
    required this.onToggleTheme,
    required this.onToggleFocus,
  });

  final bool expanded;
  final String location;
  final bool focus;
  final bool dark;
  final bool settingsBadge;
  final VoidCallback onSettings;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleFocus;

  @override
  Widget build(BuildContext context) {
    final ajustes = _NavTile(
      item: AppShell._ajustes,
      expanded: expanded,
      selected: AppShell._isSelected(location, AppShell._ajustes.path),
      badge: settingsBadge,
      onTap: onSettings,
    );
    final botoes = <Widget>[
      _RailIconButton(
        icon: dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        tooltip: dark ? 'Mudar para o tema claro' : 'Mudar para o tema escuro',
        onTap: onToggleTheme,
      ),
      _RailIconButton(
        icon: Icons.center_focus_strong_rounded,
        tooltip: focus ? 'Sair do modo foco' : 'Modo foco: deixa só o essencial no menu',
        active: focus,
        onTap: onToggleFocus,
      ),
      // "Sair" fica em Ajustes → Conta: aqui ele espremia o "Ajustes" ("Aju…").
    ];

    if (!expanded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [ajustes, for (final b in botoes) Padding(padding: const EdgeInsets.only(top: 2), child: b)],
      );
    }
    return Row(
      children: [
        Expanded(child: ajustes),
        const SizedBox(width: 4),
        ...botoes,
      ],
    );
  }
}

class _RailIconButton extends StatelessWidget {
  const _RailIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        toggled: active ? true : null,
        label: tooltip,
        excludeSemantics: true,
        child: Material(
          color: active ? cs.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            borderRadius: BorderRadius.circular(10),
            hoverColor: cs.surfaceContainerHigh,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(icon, size: 19, color: active ? cs.primary : cs.onSurface.f72),
            ),
          ),
        ),
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
        ? cs.primaryContainer
        : hovered
            ? cs.surfaceContainerHigh
            : Colors.transparent;

    final tile = Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Semantics(
        button: true,
        label: widget.item.label,
        selected: widget.selected,
        excludeSemantics: true,
        child: MouseRegion(
          onEnter: (_) => setState(() => hovered = true),
          onExit: (_) => setState(() => hovered = false),
          cursor: SystemMouseCursors.click,
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 36,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: widget.expanded ? 12 : 0),
                  child: Row(
                    mainAxisAlignment: widget.expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            widget.item.icon,
                            size: 19,
                            color: widget.selected ? cs.primary : cs.onSurface.f72,
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
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                              color: widget.selected ? cs.onPrimaryContainer : cs.onSurface.withOpacity(0.8),
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
    // Com o rótulo visível o tooltip só repetiria o texto.
    return widget.expanded ? tile : Tooltip(message: widget.item.label, child: tile);
  }
}

class _NavItem {
  const _NavItem(this.path, this.label, this.icon);
  final String path;
  final String label;
  final IconData icon;
}
