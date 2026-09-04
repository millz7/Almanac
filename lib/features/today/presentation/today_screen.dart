import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _formatToday(DateTime date) {
  final weekday = _weekdays[date.weekday - 1];
  final month = _months[date.month - 1];
  return '$weekday ${date.day} $month';
}

/// The Today tab.
///
/// This is a placeholder: it does not show sunrise, moon, tide or weather
/// data, because none of that is implemented yet. It only establishes the
/// visual language — typography, spacing, cards and hierarchy — that the
/// real Today screen will be built inside later. The date shown is real
/// (today's actual date), not fabricated content.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = _formatToday(DateTime.now());

    return AppScaffold(
      title: 'Today',
      subtitle: today,
      body: [
        const EmptyState(
          icon: Icons.eco_outlined,
          title: 'Your day, gently gathered',
          message:
              "Sunrise, moon phase, tides and the season's rhythm will "
              'appear here once this screen knows where you are.',
        ),
        const SectionHeader(title: "What's coming here"),
        const _ComingSoonGrid(),
      ],
    );
  }
}

class _ComingSoonGrid extends StatelessWidget {
  const _ComingSoonGrid();

  static const _items = [
    (icon: Icons.wb_twilight_outlined, label: 'Sun & moon'),
    (icon: Icons.waves_outlined, label: 'Tides'),
    (icon: Icons.park_outlined, label: 'Season'),
    (icon: Icons.spa_outlined, label: 'Suggestions'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 2.4,
      ),
      itemBuilder: (context, index) {
        final item = _items[index];
        final theme = Theme.of(context);
        return AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: theme.colorScheme.primary,
                size: AppIconSize.md,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(item.label, style: theme.textTheme.titleSmall),
              ),
            ],
          ),
        );
      },
    );
  }
}
