import 'package:flutter/material.dart';

/// A small heading used to introduce a group of content within a screen,
/// e.g. "This week" above a row of cards. Distinct from [AppScaffold]'s
/// page-level title.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});

  final String title;

  /// Optional trailing action, e.g. a "See all" text button.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: textTheme.titleMedium,
            semanticsLabel: title,
          ),
        ),
        ?action,
      ],
    );
  }
}
