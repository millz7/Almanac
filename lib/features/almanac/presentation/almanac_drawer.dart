import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../core/widgets/widgets.dart';
import 'widgets/feature_setting.dart';
import 'widgets/hemisphere_setting.dart';
import 'widgets/location_setting.dart';
import 'widgets/maramataka_setting.dart';
import 'widgets/name_setting.dart';

/// The user's own Almanac: their name, their part of the world, and what
/// they have chosen to keep in it.
///
/// A panel that slides in from the top right rather than a tab, because
/// this is not a place in the app — it is the cover of the book. There is
/// deliberately no "Settings" heading anywhere in it.
///
/// Everything here is reused rather than reimplemented: the hemisphere
/// and location controls are the same widgets the standalone settings
/// screen used before this replaced it, so there is one implementation of
/// the permission flow and one of the hemisphere rules.
class AlmanacDrawer extends ConsumerWidget {
  const AlmanacDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(almanacTitleProvider);

    return Drawer(
      // The cover of the book, so it is the book's paper — not the
      // season's surface, and not a settings panel's grey.
      backgroundColor: AlmanacPaper.ground,
      shape: const RoundedRectangleBorder(),
      // Wide enough to hold a switch and its description without
      // everything wrapping, and capped so it never fills a tablet.
      width: AppDimens.maxContentWidth * 0.72,
      child: AlmanacPaperSurface(
        // A fresh context here, taken from inside the paper theme rather
        // than the one the drawer was built with. The title and its rule
        // are painted with it, so they read in the Almanac's own paper
        // ink even when the Environment behind the drawer is in a night
        // state — never in whatever foreground that night palette chose
        // for its own, much darker, ground.
        child: Builder(
          builder: (context) {
            final palette = context.palette;
            final textTheme = Theme.of(context).textTheme;

            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                children: [
                  Semantics(
                    header: true,
                    child: Text(title, style: textTheme.pageTitle),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ExcludeSemantics(
                    child: SizedBox(
                      width: 48,
                      height: 1,
                      child: ColoredBox(color: palette.border),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const AlmanacAnnotation(
                    'Yours alone, and kept on this device.',
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  const AlmanacSectionLabel(label: 'Profile'),
                  const SizedBox(height: AppSpacing.md),
                  const NameSetting(),

                  const AlmanacRule(spacing: AppSpacing.lg),
                  const AlmanacSectionLabel(label: 'Location & Region'),
                  const SizedBox(height: AppSpacing.md),
                  const HemisphereSetting(),
                  const SizedBox(height: AppSpacing.xl),
                  const LocationSetting(),

                  const AlmanacRule(spacing: AppSpacing.lg),
                  const FeatureSetting(),

                  const AlmanacRule(spacing: AppSpacing.lg),
                  const AlmanacSectionLabel(label: 'Preferences'),
                  const SizedBox(height: AppSpacing.md),
                  const MaramatakaSetting(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
