import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// The standard page scaffold for a top-level tab screen.
///
/// Gives every screen the same generous horizontal padding, a scrollable
/// body, and a consistent large editorial [title] — so new feature
/// screens automatically match the rest of the app instead of each
/// re-implementing spacing and headers.
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

  /// Optional widget shown next to the title, e.g. a settings icon button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: textTheme.displaySmall),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(subtitle!, style: textTheme.bodyMedium),
                          ],
                        ],
                      ),
                    ),
                    ?trailing,
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
    );
  }
}
