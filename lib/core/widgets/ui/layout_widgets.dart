import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_fonts.dart';
import '../../theme/app_theme.dart';
import 'layout_tokens.dart';

/// Calcula o padding de uma página: respiro lateral responsivo e conteúdo
/// centralizado com largura máxima — a área de rolagem continua ocupando a
/// largura toda (roda do mouse funciona em qualquer ponto da tela).
///
/// ```dart
/// LayoutBuilder(builder: (context, c) => ListView(
///   padding: PageInsets.of(c.maxWidth),
///   children: [...],
/// ));
/// ```
class PageInsets {
  PageInsets._();

  /// Respiro lateral para a largura [width] com conteúdo limitado a [maxWidth]
  /// (o [maxWidth] inclui o respiro mínimo — igual ao `PageBody`).
  static double horizontal(double width, {double maxWidth = kPageMaxWidth}) {
    final gutter = pageGutterFor(width);
    if (!width.isFinite) return gutter;
    return math.max(gutter, (width - maxWidth) / 2 + gutter);
  }

  static EdgeInsets of(
    double width, {
    double maxWidth = kPageMaxWidth,
    double top = kGap24,
    double bottom = kGap48,
  }) {
    final h = horizontal(width, maxWidth: maxWidth);
    return EdgeInsets.fromLTRB(h, top, h, bottom);
  }
}

/// Página padrão rolável: cabeçalho (eyebrow/título/subtítulo/ações), hero
/// opcional e conteúdo — tudo alinhado na mesma coluna de [maxWidth].
///
/// Use em TODA tela nova. Os filhos são construídos sob demanda (SliverList).
///
/// ```dart
/// PageScaffold(
///   eyebrow: 'Banco',
///   title: 'Questões',
///   subtitle: 'Filtre e abra uma questão.',
///   icon: Icons.quiz_rounded,
///   actions: [AppButton.primary(label: 'Abrir sessão', icon: Icons.play_arrow_rounded, onPressed: _go)],
///   children: [
///     SectionHeader(title: 'Recentes'),
///     AppCard(child: ...),
///   ],
/// )
/// ```
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    this.title,
    this.eyebrow,
    this.subtitle,
    this.icon,
    this.badge,
    this.actions = const [],
    this.header,
    this.hero,
    this.children = const [],
    this.child,
    this.maxWidth = kPageMaxWidth,
    this.top = kGap24,
    this.bottom = kGap48,
    this.gap = 0,
    this.controller,
    this.bottomBar,
    super.key,
  });

  final String? title;
  final String? eyebrow;
  final String? subtitle;
  final IconData? icon;
  final String? badge;

  /// Botões do cabeçalho (à direita no desktop, abaixo do título no estreito).
  final List<Widget> actions;

  /// Cabeçalho customizado — substitui o `PageHeader` gerado por title/eyebrow.
  final Widget? header;

  /// Bloco de destaque logo abaixo do cabeçalho (ex.: `PageHero`), mesma largura do conteúdo.
  final Widget? hero;

  final List<Widget> children;

  /// Alternativa a [children] para um único filho.
  final Widget? child;

  final double maxWidth;
  final double top;
  final double bottom;

  /// Espaço vertical automático entre os filhos (0 = cada filho controla).
  final double gap;
  final ScrollController? controller;

  /// Barra fixa no rodapé (ex.: ações de um formulário), centralizada na mesma largura.
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      if (header != null)
        header!
      else if (title != null)
        PageHeader(
          title: title!,
          eyebrow: eyebrow,
          subtitle: subtitle,
          icon: icon,
          badge: badge,
          actions: actions,
        ),
      if (hero != null) ...[hero!, const SizedBox(height: kGap24)],
      if (child != null) child!,
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0 && gap > 0) SizedBox(height: gap),
        children[i],
      ],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = PageInsets.of(
          constraints.maxWidth,
          maxWidth: maxWidth,
          top: top,
          bottom: bottom,
        );
        final scroll = CustomScrollView(
          controller: controller,
          slivers: [
            SliverPadding(
              padding: insets,
              sliver: SliverList(delegate: SliverChildListDelegate(items)),
            ),
          ],
        );
        if (bottomBar == null) return scroll;
        final cs = Theme.of(context).colorScheme;
        return Column(
          children: [
            Expanded(child: scroll),
            DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(top: BorderSide(color: cs.outlineVariant)),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(insets.left, kGap12, insets.right, kGap12),
                child: bottomBar,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Centraliza um conteúdo NÃO rolável na largura padrão (ex.: barra de
/// filtros fixa acima de uma lista). Para páginas roláveis use [PageScaffold].
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    required this.child,
    this.maxWidth = kPageMaxWidth,
    this.vertical = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  /// Padding vertical extra (top/bottom). O horizontal é calculado.
  final EdgeInsets vertical;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final h = PageInsets.horizontal(c.maxWidth, maxWidth: maxWidth);
        return Padding(
          padding: EdgeInsets.fromLTRB(h, vertical.top, h, vertical.bottom),
          child: child,
        );
      },
    );
  }
}

/// Corpo de página (compat) — centraliza [child] com largura máxima.
/// Com o padding padrão, o respiro lateral se ajusta à largura da janela.
/// Para telas novas prefira [PageScaffold].
class PageBody extends StatelessWidget {
  const PageBody({
    required this.child,
    this.padding = kPagePadding,
    this.maxWidth = kPageMaxWidth,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    var effective = padding;
    if (identical(padding, kPagePadding) || padding == kPagePadding) {
      final g = pageGutterFor(MediaQuery.sizeOf(context).width);
      effective = EdgeInsets.fromLTRB(g, padding.top, g, padding.bottom);
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: effective, child: child),
      ),
    );
  }
}

/// Cabeçalho de página: eyebrow (contexto) · título · subtítulo · ações.
///
/// ```dart
/// PageHeader(eyebrow: 'Estudo', title: 'Flashcards', subtitle: '12 para revisar hoje',
///   actions: [AppButton.secondary(label: 'Novo', icon: Icons.add, onPressed: _new)])
/// ```
class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.trailing,
    this.actions = const [],
    this.badge,
    this.icon,
    super.key,
  });

  final String title;

  /// Não é desenhado: o título fala sozinho (sem rótulo em cima dele).
  final String? eyebrow;
  final String? subtitle;

  /// Widget à direita (compat). Para vários botões use [actions].
  final Widget? trailing;

  /// Botões de ação à direita (quebram linha no estreito).
  final List<Widget> actions;

  /// Badge contextual ao lado do título (ex: "oficial", "treino", contador).
  final String? badge;

  /// Ícone opcional em um quadrado suave à esquerda do título.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titleRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(kRadiusButton),
            ),
            child: Icon(icon, size: 22, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: kGap12),
        ],
        Flexible(
          child: Text(
            title,
            style: AppFonts.display(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              color: cs.onSurface,
              height: 1.2,
            ),
          ),
        ),
        if (badge != null && badge!.isNotEmpty) ...[
          const SizedBox(width: kGap12),
          _HeaderBadge(label: badge!),
        ],
      ],
    );
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleRow,
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: kGap8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Text(
              subtitle!,
              style: TextStyle(fontSize: 15, color: cs.onSurface.f72, height: 1.5),
            ),
          ),
        ],
      ],
    );
    final allActions = <Widget>[...actions, if (trailing != null) trailing!];
    return Padding(
      padding: const EdgeInsets.only(bottom: kGap24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (allActions.isEmpty) return heading;
          final actionWrap = Wrap(
            spacing: kGap8,
            runSpacing: kGap8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: allActions,
          );
          final compact = constraints.maxWidth < 640;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [heading, const SizedBox(height: kGap12), actionWrap],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: heading),
              const SizedBox(width: kGap16),
              actionWrap,
            ],
          );
        },
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cs.onPrimaryContainer,
        ),
      ),
    );
  }
}

/// Cabeçalho de seção dentro da página: título + subtítulo + ação à direita.
///
/// ```dart
/// SectionHeader(title: 'Para revisar', subtitle: '3 lacunas abertas',
///   action: AppButton.tertiary(label: 'Ver tudo', onPressed: _all))
/// ```
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.subtitle,
    this.action,
    this.icon,
    this.padding = const EdgeInsets.only(top: kGap24, bottom: kGap12),
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final IconData? icon;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Semantics(
        header: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: cs.primary),
              const SizedBox(width: kGap8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                      letterSpacing: -0.2,
                      height: 1.3,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: kGap2),
                      child: Text(
                        subtitle!,
                        style: TextStyle(fontSize: 13, color: cs.onSurface.f72, height: 1.45),
                      ),
                    ),
                ],
              ),
            ),
            if (action != null) ...[const SizedBox(width: kGap12), action!],
          ],
        ),
      ),
    );
  }
}

/// Rótulo de seção (compat — versão compacta do [SectionHeader]).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {this.hint, this.chip, super.key});
  final String label;
  final String? hint;
  final String? chip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: kGap12, bottom: kGap12),
      child: Semantics(
        header: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                      letterSpacing: -0.1,
                      height: 1.3,
                    ),
                  ),
                ),
                if (chip != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: cs.tertiaryContainer,
                    ),
                    child: Text(
                      chip!,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: cs.onTertiaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            if (hint != null)
              Padding(
                padding: const EdgeInsets.only(top: kGap2),
                child: Text(
                  hint!,
                  style: TextStyle(fontSize: 13, color: cs.onSurface.f72, height: 1.45),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bloco de destaque com o gradiente da marca (Início, resultados, etc.).
/// Texto e ícones dentro ficam brancos automaticamente.
///
/// ```dart
/// PageHero(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
///   Text('12', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w700)),
///   Text('dias para a prova'),
/// ]))
/// ```
class PageHero extends StatelessWidget {
  const PageHero({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(kGap32, kGap32, kGap32, kGap32),
    this.gradient,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final width = MediaQuery.sizeOf(context).width;
    final pad = width < 600 ? const EdgeInsets.all(kGap20) : padding;
    return Container(
      width: double.infinity,
      padding: pad,
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.heroGradient(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(kRadiusHighlight),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: palette.heroForeground),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: palette.heroForeground),
          child: child,
        ),
      ),
    );
  }
}

/// Linha de botões alinhada à esquerda que quebra linha quando falta espaço.
/// Use em listas (ListView/PageScaffold) para os botões NÃO esticarem.
///
/// ```dart
/// ActionRow(children: [
///   AppButton.primary(label: 'Começar', onPressed: _start),
///   AppButton.secondary(label: 'Depois', onPressed: _later),
/// ])
/// ```
class ActionRow extends StatelessWidget {
  const ActionRow({
    required this.children,
    this.spacing = kGap8,
    this.alignment = WrapAlignment.start,
    super.key,
  });

  final List<Widget> children;
  final double spacing;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: kGap8,
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}
