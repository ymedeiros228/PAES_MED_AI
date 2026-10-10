/// Tokens do design system PAES — importe `ui_kit.dart` nas features.
///
/// Espaçamento em escala 4/8. Cantos: controle 10 · botão 12 · painel 16 · hero 20.
library;

import 'package:flutter/material.dart';

// ─── Largura e respiro de página ─────────────────────────────────────
/// Largura máxima do conteúdo das telas (desktop largo fica centralizado).
const kPageMaxWidth = 1200.0;

/// Largura confortável para leitura (enunciado, teoria, redação, chat).
const kReadingMaxWidth = 760.0;

/// Margem lateral mínima por faixa de largura (ver [pageGutterFor]).
const kPageGutterCompact = 16.0;
const kPageGutter = 24.0;
const kPageGutterWide = 32.0;

/// Padding padrão das telas (compat). Prefira `PageScaffold`/`PageBody`,
/// que calculam o respiro lateral pela largura disponível.
const kPagePadding = EdgeInsets.fromLTRB(kPageGutterWide, 24, kPageGutterWide, 48);

/// Margem lateral responsiva para a largura disponível.
double pageGutterFor(double width) {
  if (width < 600) return kPageGutterCompact;
  if (width < 1000) return kPageGutter;
  return kPageGutterWide;
}

// ─── Cantos ──────────────────────────────────────────────────────────
const kRadiusMicro = 4.0;
const kRadiusControl = 10.0;
const kRadiusButton = 12.0;
const kRadiusPanel = 16.0;
const kRadiusPanelSoft = 16.0;
const kRadiusHighlight = 20.0;

// ─── Espaçamento (escala 4/8) ────────────────────────────────────────
const kGap2 = 2.0;
const kGap4 = 4.0;
const kGap6 = 6.0;
const kGap8 = 8.0;
const kGap12 = 12.0;
const kGap16 = 16.0;
const kGap20 = 20.0;
const kGap24 = 24.0;
const kGap32 = 32.0;
const kGap40 = 40.0;
const kGap48 = 48.0;

// ─── Movimento ───────────────────────────────────────────────────────
/// Durações padrão — curtas para o app parecer rápido.
class AppMotion {
  AppMotion._();
  static const fast = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 180);
  static const slow = Duration(milliseconds: 260);
  static const curve = Curves.easeOutCubic;

  /// `true` quando o sistema pede menos animação (acessibilidade).
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
