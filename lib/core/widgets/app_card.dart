import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// A passage grouped on the page.
///
/// Since Step 17 this is the same thing as [AlmanacInset] with a little
/// more padding: the theme's card colour is the *inset* ground, the
/// radius is small, and there is no shadow, no border and no surface
/// tint. A card in this app is ink laid on the paper, never a sheet
/// floating above it.
///
/// Reach for a label, some space and a rule first. Use this only where
/// grouping genuinely aids comprehension, and wrap it in [onTap] only
/// when the whole passage is one destination.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
    );

    final content = Container(
      padding: padding,
      decoration: ShapeDecoration(
        color: color ?? theme.cardTheme.color,
        shape: shape,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}
