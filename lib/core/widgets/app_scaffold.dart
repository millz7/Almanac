import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// The standard page scaffold for a top-level tab screen.
///
/// The chapter opening of the book: the same page margins, the same
/// title treatment with its short rule beneath, the same scrolling and
/// the same bottom breathing room, so a new feature screen matches the
/// rest of the Almanac without re-implementing any of it.
///
/// It is the sibling of `AlmanacPage`, which is the same composition for
/// a page *inside* a feature — one with a way back. Both put the title
/// in the display face over a hairline; the difference is only that a
/// chapter opening has no Back.
///
/// The body stays a lazy [SliverList]: several of these pages are long,
/// and building all of a Garden's chapters to show the first two would
/// be a real cost for a visual nicety.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.trailing,
  });

  /// The screen's large heading, e.g. a date or a feature name.
  final String title;

  /// An optional short line under the title, e.g. a date or place name.
  final String? subtitle;

  /// The scrollable content of the screen.
  final List<Widget> body;

  /// Optional widget shown next to the title, e.g. the Almanac button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimens.maxContentWidth,
            ),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: textTheme.pageTitle),
                                  if (subtitle != null) ...[
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      subtitle!,
                                      style: textTheme.bodyQuiet?.copyWith(
                                        color: palette.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            ?trailing,
                          ],
                        ),
                        // The hairline under a chapter title. Decorative:
                        // the title above it is the heading.
                        const SizedBox(height: AppSpacing.md),
                        ExcludeSemantics(
                          child: SizedBox(
                            width: 48,
                            height: 1,
                            child: ColoredBox(color: palette.border),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: body.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.lg),
                    itemBuilder: (_, index) => body[index],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
