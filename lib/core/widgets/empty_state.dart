import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// A tasteful "nothing here yet" state.
///
/// Used by placeholder and not-yet-implemented screens so they read as an
/// intentional part of the design rather than a broken or empty page.
/// [icon] stands in for a future custom illustration — swap it for an
/// `Image.asset` once illustrations exist, without changing call sites.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          // A drawn mark rather than a filled badge: a thin ring on the
          // paper, in the same language as the doorway's arrow.
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.6),
              ),
            ),
            child: Icon(
              icon,
              size: AppIconSize.lg,
              color: theme.colorScheme.onSurfaceVariant,
              semanticLabel: title,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.chapterTitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}
