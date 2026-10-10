import 'package:flutter/material.dart';

import '../../theme/app_fonts.dart';
import '../../theme/app_theme.dart';
import 'layout_tokens.dart';
import 'layout_widgets.dart';
import 'surface_panel.dart';

// ═════════════════════════════════════════════════════════════════════
// Botões
// ═════════════════════════════════════════════════════════════════════

enum AppButtonVariant {
  /// Ação principal da tela (1 por área). Preenchido teal.
  primary,

  /// Ação secundária de peso médio. Preenchido suave (tonal).
  tonal,

  /// Ação alternativa. Contorno.
  secondary,

  /// Ação de baixo peso (link, "Ver tudo", "Cancelar"). Só texto.
  tertiary,

  /// Ação destrutiva (apagar, descartar).
  danger,
}

enum AppButtonSize { small, medium, large }

/// Botão do design system. Tamanho natural (NÃO estica dentro de ListView);
/// use `expand: true` para ocupar a largura toda.
///
/// ```dart
/// AppButton.primary(label: 'Começar sessão', icon: Icons.play_arrow_rounded, onPressed: _start)
/// AppButton.secondary(label: 'Pular', onPressed: _skip)
/// AppButton.tertiary(label: 'Ver tudo', onPressed: _all)
/// AppButton.danger(label: 'Descartar', onPressed: _discard)
/// AppButton(label: 'Salvar', loading: saving, onPressed: _save)
/// ```
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.loading = false,
    this.expand = false,
    this.tooltip,
    this.autofocus = false,
    super.key,
  });

  const AppButton.primary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = AppButtonSize.medium,
    this.loading = false,
    this.expand = false,
    this.tooltip,
    this.autofocus = false,
    super.key,
  }) : variant = AppButtonVariant.primary;

  const AppButton.tonal({
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = AppButtonSize.medium,
    this.loading = false,
    this.expand = false,
    this.tooltip,
    this.autofocus = false,
    super.key,
  }) : variant = AppButtonVariant.tonal;

  const AppButton.secondary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = AppButtonSize.medium,
    this.loading = false,
    this.expand = false,
    this.tooltip,
    this.autofocus = false,
    super.key,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.tertiary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = AppButtonSize.medium,
    this.loading = false,
    this.expand = false,
    this.tooltip,
    this.autofocus = false,
    super.key,
  }) : variant = AppButtonVariant.tertiary;

  const AppButton.danger({
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = AppButtonSize.medium,
    this.loading = false,
    this.expand = false,
    this.tooltip,
    this.autofocus = false,
    super.key,
  }) : variant = AppButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final AppButtonVariant variant;
  final AppButtonSize size;

  /// Mostra um indicador no lugar do ícone e desabilita o clique.
  final bool loading;

  /// `true` = ocupa toda a largura disponível.
  final bool expand;
  final String? tooltip;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (minH, padH, fontSize, iconSize) = switch (size) {
      AppButtonSize.small => (36.0, 14.0, 13.0, 16.0),
      AppButtonSize.medium => (44.0, 20.0, 14.0, 18.0),
      AppButtonSize.large => (52.0, 24.0, 15.0, 20.0),
    };
    final sizeStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(minH, minH)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: variant == AppButtonVariant.tertiary ? padH - 6 : padH,
          vertical: 0,
        ),
      ),
      textStyle: WidgetStatePropertyAll(
        AppFonts.body(fontSize: fontSize, fontWeight: FontWeight.w600, height: 1.2),
      ),
      iconSize: WidgetStatePropertyAll(iconSize),
    );

    final busy = loading;
    final effectiveOnPressed = busy ? null : onPressed;
    final fg = switch (variant) {
      AppButtonVariant.primary => cs.onPrimary,
      AppButtonVariant.tonal => cs.onSecondaryContainer,
      AppButtonVariant.danger => cs.onError,
      AppButtonVariant.secondary => cs.onSurface,
      AppButtonVariant.tertiary => cs.primary,
    };
    final Widget? leading = busy
        ? SizedBox(
            width: iconSize - 2,
            height: iconSize - 2,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg.withOpacity(0.8)),
          )
        : (icon != null ? Icon(icon, size: iconSize) : null);

    final labelWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading, const SizedBox(width: kGap8)],
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: kGap6),
          Icon(trailingIcon, size: iconSize),
        ],
      ],
    );

    Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: effectiveOnPressed,
          autofocus: autofocus,
          style: sizeStyle,
          child: labelWidget,
        ),
      AppButtonVariant.tonal => FilledButton.tonal(
          onPressed: effectiveOnPressed,
          autofocus: autofocus,
          style: sizeStyle,
          child: labelWidget,
        ),
      AppButtonVariant.danger => FilledButton(
          onPressed: effectiveOnPressed,
          autofocus: autofocus,
          style: sizeStyle.merge(
            FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
          ),
          child: labelWidget,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: effectiveOnPressed,
          autofocus: autofocus,
          style: sizeStyle,
          child: labelWidget,
        ),
      AppButtonVariant.tertiary => TextButton(
          onPressed: effectiveOnPressed,
          autofocus: autofocus,
          style: sizeStyle,
          child: labelWidget,
        ),
    };

    if (busy) {
      button = Semantics(label: '$label — carregando', child: button);
    }
    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    // Align com fatores 1: em pais "tight" (ListView, Column stretch) o botão
    // mantém o tamanho natural e fica à esquerda em vez de esticar.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: button,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Card
// ═════════════════════════════════════════════════════════════════════

/// Card/painel do design system, opcionalmente clicável (hover, foco de
/// teclado e pressed visíveis). Pode montar um cabeçalho padrão.
///
/// ```dart
/// AppCard(child: Text('...'))
/// AppCard(
///   icon: Icons.style_rounded,
///   title: 'Flashcards',
///   subtitle: '12 para revisar hoje',
///   trailing: Icon(Icons.chevron_right_rounded),
///   onTap: () => context.go('/flashcards'),
/// )
/// AppCard(title: 'Desempenho', action: AppButton.tertiary(label: 'Detalhes', onPressed: _x), child: Chart())
/// ```
class AppCard extends StatefulWidget {
  const AppCard({
    this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
    this.action,
    this.onTap,
    this.selected = false,
    this.color,
    this.padding = const EdgeInsets.all(kGap20),
    this.margin = EdgeInsets.zero,
    this.semanticLabel,
    super.key,
  });

  final Widget? child;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;

  /// Widget à direita do cabeçalho (ex.: chevron, chip de status).
  final Widget? trailing;

  /// Ação à direita do cabeçalho (ex.: AppButton.tertiary).
  final Widget? action;
  final VoidCallback? onTap;

  /// Destaque persistente (item escolhido).
  final bool selected;
  final Color? color;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final String? semanticLabel;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final interactive = widget.onTap != null;
    final hasHeader = widget.title != null || widget.icon != null;

    final header = hasHeader
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (widget.iconColor ?? cs.primary).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(kRadiusControl),
                  ),
                  child: Icon(widget.icon, size: 20, color: widget.iconColor ?? cs.primary),
                ),
                const SizedBox(width: kGap12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.title != null)
                      Text(
                        widget.title!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                          height: 1.35,
                        ),
                      ),
                    if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: kGap2),
                        child: Text(
                          widget.subtitle!,
                          style: TextStyle(fontSize: 13, color: cs.onSurface.f72, height: 1.45),
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.action != null) ...[const SizedBox(width: kGap12), widget.action!],
              if (widget.trailing != null) ...[const SizedBox(width: kGap8), widget.trailing!],
            ],
          )
        : null;

    final content = header == null
        ? (widget.child ?? const SizedBox.shrink())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              header,
              if (widget.child != null) ...[const SizedBox(height: kGap16), widget.child!],
            ],
          );

    final borderColor = _focus
        ? cs.primary
        : widget.selected
            ? cs.primary.withOpacity(0.7)
            : (_hover && interactive ? cs.outline : cs.outlineVariant);
    final bg = widget.color ??
        (widget.selected
            ? Color.alphaBlend(cs.primary.withOpacity(0.08), cs.surface)
            : (_hover && interactive ? Color.alphaBlend(cs.onSurface.withOpacity(0.025), cs.surface) : cs.surface));

    final decorated = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.curve,
      margin: widget.margin,
      decoration: SurfacePanel.panelDecoration(
        context,
        color: bg,
        borderColor: borderColor,
      ).copyWith(
        border: Border.all(color: borderColor, width: _focus ? 2 : 1),
      ),
      child: interactive
          ? Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: widget.onTap,
                onHover: (h) => setState(() => _hover = h),
                onFocusChange: (f) => setState(() => _focus = f),
                borderRadius: BorderRadius.circular(kRadiusPanel),
                focusColor: Colors.transparent,
                child: Padding(padding: widget.padding, child: content),
              ),
            )
          : Padding(padding: widget.padding, child: content),
    );

    if (!interactive) return decorated;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: MouseRegion(cursor: SystemMouseCursors.click, child: decorated),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Chip
// ═════════════════════════════════════════════════════════════════════

enum AppTone { neutral, primary, success, warning, danger, info }

/// Cores (fundo, texto) de um tom semântico — use para badges próprios.
(Color bg, Color fg) toneColors(BuildContext context, AppTone tone) {
  final cs = Theme.of(context).colorScheme;
  final p = context.palette;
  return switch (tone) {
    AppTone.neutral => (cs.surfaceContainerHigh, cs.onSurface.withOpacity(0.85)),
    AppTone.primary => (cs.primaryContainer, cs.onPrimaryContainer),
    AppTone.success => (p.successContainer, p.onSuccessContainer),
    AppTone.warning => (p.warningContainer, p.onWarningContainer),
    AppTone.danger => (cs.errorContainer, cs.onErrorContainer),
    AppTone.info => (p.infoContainer, p.onInfoContainer),
  };
}

/// Chip/badge do design system: estático (status) ou clicável (filtro).
///
/// ```dart
/// AppChip(label: 'Oficial UEMA', tone: AppTone.primary, icon: Icons.verified_rounded)
/// AppChip(label: 'Biologia', selected: filter == 'bio', onTap: () => setFilter('bio'))
/// AppChip(label: '3 erros', tone: AppTone.danger, dense: true)
/// ```
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    this.icon,
    this.tone = AppTone.neutral,
    this.selected = false,
    this.onTap,
    this.dense = false,
    this.tooltip,
    super.key,
  });

  final String label;
  final IconData? icon;
  final AppTone tone;

  /// Para chips de filtro: destaca com o tom primary e mostra ✓.
  final bool selected;
  final VoidCallback? onTap;
  final bool dense;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final interactive = onTap != null;
    final (bg, fg) = selected
        ? (cs.primaryContainer, cs.onPrimaryContainer)
        : (interactive && tone == AppTone.neutral
            ? (Colors.transparent, cs.onSurface.withOpacity(0.85))
            : toneColors(context, tone));
    final border = selected
        ? cs.primary.withOpacity(0.6)
        : (interactive ? cs.outline : Colors.transparent);
    final h = dense ? 24.0 : (interactive ? 34.0 : 28.0);
    final fontSize = dense ? 11.5 : 12.5;
    final leadingIcon = selected && interactive ? Icons.check_rounded : icon;

    Widget chip = Material(
      color: bg,
      shape: StadiumBorder(side: BorderSide(color: border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: h,
          padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: dense ? 13 : 15, color: fg),
                const SizedBox(width: kGap4),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: fg,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (interactive) {
      chip = Semantics(button: true, selected: selected, child: chip);
    }
    if (tooltip != null) chip = Tooltip(message: tooltip!, child: chip);
    return chip;
  }
}

// ═════════════════════════════════════════════════════════════════════
// Estado de erro
// ═════════════════════════════════════════════════════════════════════

/// Estado de erro com "Tentar de novo".
/// - padrão: bloco centralizado (tela/aba inteira falhou);
/// - `compact: true`: faixa dentro da página (uma seção falhou).
///
/// ```dart
/// error: (e, _) => ErrorState(
///   message: humanApiError(e, fallback: 'Não deu para carregar as questões.'),
///   onRetry: () => ref.invalidate(questionsProvider),
/// )
/// ErrorState(compact: true, message: 'Falhou ao salvar o checkpoint.', onRetry: _save)
/// ```
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.message,
    this.title = 'Algo não carregou',
    this.onRetry,
    this.retryLabel = 'Tentar de novo',
    this.secondary,
    this.compact = false,
    this.icon = Icons.cloud_off_rounded,
    super.key,
  });

  final String message;
  final String title;
  final VoidCallback? onRetry;
  final String retryLabel;

  /// Ação extra (ex.: AppButton.tertiary(label: 'Voltar ao início')).
  final Widget? secondary;
  final bool compact;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (compact) {
      return Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(kGap16, kGap12, kGap12, kGap12),
          decoration: BoxDecoration(
            color: cs.errorContainer.withOpacity(0.55),
            borderRadius: BorderRadius.circular(kRadiusButton),
            border: Border.all(color: cs.error.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, size: 20, color: cs.error),
              const SizedBox(width: kGap12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(fontSize: 13.5, color: cs.onSurface, height: 1.45),
                ),
              ),
              if (secondary != null) ...[const SizedBox(width: kGap8), secondary!],
              if (onRetry != null) ...[
                const SizedBox(width: kGap8),
                AppButton.secondary(
                  label: retryLabel,
                  icon: Icons.refresh_rounded,
                  size: AppButtonSize.small,
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Semantics(
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(kGap32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(kRadiusButton),
                  ),
                  child: Icon(icon, color: cs.onErrorContainer, size: 24),
                ),
                const SizedBox(height: kGap16),
                Text(
                  title,
                  style: AppFonts.display(fontSize: 20, fontWeight: FontWeight.w600, color: cs.onSurface),
                ),
                const SizedBox(height: kGap8),
                Text(
                  message,
                  style: TextStyle(fontSize: 14, color: cs.onSurface.f72, height: 1.55),
                ),
                if (onRetry != null || secondary != null) ...[
                  const SizedBox(height: kGap20),
                  ActionRow(
                    children: [
                      if (onRetry != null)
                        AppButton.primary(
                          label: retryLabel,
                          icon: Icons.refresh_rounded,
                          onPressed: onRetry,
                        ),
                      if (secondary != null) secondary!,
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Stat tile
// ═════════════════════════════════════════════════════════════════════

/// Métrica única: rótulo, valor grande, dica e variação opcional.
///
/// ```dart
/// StatTile(label: 'Acerto', value: '78%', icon: Icons.gps_fixed_rounded, delta: '+4 pts', deltaPositive: true)
/// StatGrid(children: [StatTile(...), StatTile(...), StatTile(...)])
/// ```
class StatTile extends StatelessWidget {
  const StatTile({
    required this.label,
    required this.value,
    this.icon,
    this.hint,
    this.delta,
    this.deltaPositive,
    this.tone = AppTone.primary,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? hint;

  /// Variação (ex.: '+4 pts'); cor pela [deltaPositive] (null = neutra).
  final String? delta;
  final bool? deltaPositive;
  final AppTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = context.palette;
    final (toneBg, toneFg) = toneColors(context, tone);
    final deltaColor = deltaPositive == null
        ? cs.onSurface.f72
        : (deltaPositive! ? p.success : cs.error);
    return Semantics(
      label: '$label: $value${delta != null ? ', $delta' : ''}',
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(kGap16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: toneBg, borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, size: 16, color: toneFg),
                  ),
                  const SizedBox(width: kGap8),
                ],
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface.f72),
                  ),
                ),
              ],
            ),
            const SizedBox(height: kGap12),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.display(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
                height: 1.1,
                letterSpacing: -0.5,
              ).copyWith(fontFeatures: AppFonts.tabular),
            ),
            if (delta != null || hint != null) ...[
              const SizedBox(height: kGap6),
              Text.rich(
                TextSpan(
                  children: [
                    if (delta != null)
                      TextSpan(
                        text: delta,
                        style: TextStyle(color: deltaColor, fontWeight: FontWeight.w600),
                      ),
                    if (delta != null && hint != null) const TextSpan(text: '  ·  '),
                    if (hint != null) TextSpan(text: hint),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: cs.onSurface.f72, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Grade responsiva de [StatTile]s (ou qualquer card de mesma importância).
class StatGrid extends StatelessWidget {
  const StatGrid({
    required this.children,
    this.minTileWidth = 200,
    this.spacing = kGap12,
    this.maxColumns = 4,
    super.key,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double spacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        var cols = ((w + spacing) / (minTileWidth + spacing)).floor().clamp(1, maxColumns);
        if (cols > children.length && children.isNotEmpty) cols = children.length;
        final tileW = (w - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: tileW.floorToDouble(), child: child),
          ],
        );
      },
    );
  }
}
