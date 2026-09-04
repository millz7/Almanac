import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// A soft, low-decoration surface for grouping content.
///
/// Uses the theme's card colour and a generous rounded radius so it reads
/// as an integrated part of the page rather than a bordered dashboard
/// widget. Wrap it in [onTap] only when the whole card is a single
/// tappable destination.
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
      borderRadius: BorderRadius.circular(AppRadius.lg),
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
