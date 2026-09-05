import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// A quiet inline note.
class InlineNote extends StatelessWidget {
  const InlineNote({
    super.key,
    required this.icon,
    required this.text,
    this.isError = false,
  });

  final IconData icon;
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      liveRegion: isError,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: AppIconSize.sm,
            color: isError ? palette.error : palette.icon,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: textTheme.bodySmall)),
        ],
      ),
    );
  }
}
