/// Barrel do design system PAES — importe SÓ `ui_kit.dart` nas features.
///
/// Peças principais:
/// - Layout: `PageScaffold`, `PageHeader`, `PageHero`, `PageBody` (compat),
///   `ContentWidth`, `PageInsets`, `SectionHeader`, `SectionLabel`, `ActionRow`.
/// - Superfícies: `AppCard` (clicável ou não), `SurfacePanel`, `SectionCard`.
/// - Ações: `AppButton.primary/tonal/secondary/tertiary/danger`.
/// - Status: `AppChip` (+ `AppTone`), `HonestBadge`, `DeltaChip`.
/// - Estados: `EmptyState`, `ErrorState`, `QuietEmpty`, `CompactStatus`,
///   `SkeletonPage/List/Card/ListTile/Box`, `SoftLoader`.
/// - Métricas: `StatTile`, `StatGrid`, `StatsStrip`.
/// - Prova: `ExamCountdownCard` (+ `examCountdownProvider` em core/data).
/// Importe também `core/theme/app_theme.dart` (cores, `context.palette`)
/// e `core/widgets/status_widgets.dart` (`EmptyState`) quando precisar.
/// - Tokens: layout_tokens.dart (kGap*, kRadius*, kPageMaxWidth, AppMotion)
///   e `context.palette` / `context.text` em app_theme.dart.
library;

export 'ui/app_components.dart';
export 'ui/constellation_map.dart';
export 'ui/content_widgets.dart';
export 'ui/exam_countdown.dart';
export 'ui/gamification_effects.dart';
export 'ui/layout_tokens.dart';
export 'ui/layout_widgets.dart';
export 'ui/list_widgets.dart';
export 'ui/loading_skeletons.dart';
export 'ui/micro_interactions.dart';
export 'ui/question_widgets.dart';
export 'ui/quiet_empty.dart';
export 'ui/session_widgets.dart';
export 'ui/stats_widgets.dart';
export 'ui/surface_panel.dart';
