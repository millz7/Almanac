import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'almanac_paper_surface.dart';

/// One page of the Almanac.
///
/// **ENVIRONMENT IS OUTSIDE. DETAIL PAGES ARE THE BOOK.** This is the
/// book half: the shared scaffold every inner page is written on, so a
/// recipe, a plant, a moon and a cycle are recognisably pages of the
/// same notebook rather than eight screens that happen to be in one app.
///
/// What it guarantees, once, for all of them:
///
/// - the paper ground, in every season and at every hour, via
///   [AlmanacPaperSurface];
/// - the same page margins, and content capped at
///   [AppDimens.maxContentWidth] so a tablet gets a book column rather
///   than a stretched line;
/// - one back affordance — words, at the top left, above the fold,
///   never a bare glyph and never below a long page;
/// - the title centred under it with a short rule beneath, which is the
///   composition the Moon reference establishes;
/// - safe-area handling and generous bottom breathing room;
/// - no clipping at 2× text: nothing here is a fixed height, the header
///   wraps, and there is a test.
///
/// It is deliberately small. A screen with genuinely unusual needs — the
/// Environment's landscape, an immersive breathing session — should not
/// be forced through it; the point of a scaffold is the eighty per cent
/// that is genuinely the same.
class AlmanacPage extends StatelessWidget {
  const AlmanacPage({
    super.key,
    required this.title,
    required this.children,
    this.eyebrow,
    this.onBack,
    this.backLabel = 'Back',
    this.trailing,
    this.centreTitle = true,
  });

  /// The name of the page: "The Moon", "Cycle".
  final String title;

  /// An optional small line above the title — a date, a month, a season.
  final String? eyebrow;

  /// The page's content, laid out in a column with consistent spacing
  /// between the items.
  final List<Widget> children;

  /// The way back. Null means this page is a destination in its own
  /// right and has no back affordance.
  final VoidCallback? onBack;

  /// The words on the way back, so a page can say where it goes.
  final String backLabel;

  /// The page's one top-right control — in practice the Almanac button.
  /// Taken as a widget rather than imported, because `core/` does not
  /// reach up into `app/`.
  final Widget? trailing;

  /// Page titles are centred by default, as in the reference. A page
  /// whose title belongs in a reading column can set this false.
  final bool centreTitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return AlmanacPaperSurface(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimens.maxContentWidth,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (onBack != null || trailing != null)
                      _PageControls(
                        onBack: onBack,
                        backLabel: backLabel,
                        trailing: trailing,
                      ),

                    if (eyebrow case final line?) ...[
                      Text(
                        line,
                        textAlign: centreTitle
                            ? TextAlign.center
                            : TextAlign.start,
                        style: textTheme.eyebrow?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],

                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        textAlign: centreTitle
                            ? TextAlign.center
                            : TextAlign.start,
                        style: textTheme.pageTitle,
                      ),
                    ),

                    // The short rule under a page title: the reference's
                    // one piece of punctuation, and the thing that makes
                    // a title read as printed rather than as an app bar.
                    const SizedBox(height: AppSpacing.md),
                    _TitleRule(centred: centreTitle),
                    const SizedBox(height: AppSpacing.xl),

                    for (final (index, child) in children.indexed) ...[
                      if (index > 0) const SizedBox(height: AppSpacing.lg),
                      child,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The back affordance and the page's one top-right control.
///
/// A row that becomes a column of its own accord at large text sizes is
/// over-engineering; instead the back label is [Flexible] and wraps, and
/// the trailing control keeps its size. Nothing is clipped either way.
class _PageControls extends StatelessWidget {
  const _PageControls({
    required this.onBack,
    required this.backLabel,
    required this.trailing,
  });

  final VoidCallback? onBack;
  final String backLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          if (onBack case final back?)
            Flexible(
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: back,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    foregroundColor: palette.textPrimary,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chevron_left,
                        size: AppIconSize.md,
                        color: palette.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(backLabel, style: textTheme.controlLabel),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// The hairline under a page title. Decorative — the title above it is
/// already a header for a screen reader.
class _TitleRule extends StatelessWidget {
  const _TitleRule({required this.centred});

  final bool centred;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Align(
      alignment: centred ? Alignment.center : Alignment.centerLeft,
      child: SizedBox(
        width: 48,
        height: 1,
        child: ColoredBox(color: context.palette.border),
      ),
    ),
  );
}
