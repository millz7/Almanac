import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/time/calendar_date.dart';
import '../cycle_text.dart';
import 'bleeding_marker.dart';

/// One month, with what the user recorded on it.
///
/// **The factual entry surface.** A tap opens the editor for that day;
/// everything drawn here is something the user put there. Nothing is
/// estimated onto it — a day inside an estimated menstrual span is not
/// drawn as bleeding unless it was recorded.
///
/// The marks are the **same** [BleedingMarkers] specs the wheel and the
/// legend use, at calendar size: spotting visibly smaller than bleeding,
/// heavy identical to bleeding plus one thin ring. There are no
/// calendar-specific symbols and no calendar-specific colours.
///
/// A day 1 adds a small "Day 1" caption **beside** its mark rather than
/// instead of it, so nothing depends on telling two shapes apart, and
/// nothing depends on colour at all: every day states its record in
/// words to a screen reader.
class CycleMonthCalendar extends StatelessWidget {
  const CycleMonthCalendar({
    super.key,
    required this.month,
    required this.today,
    required this.records,
    required this.onOpenDay,
  });

  /// Any date in the month to draw.
  final CalendarDate month;

  final CalendarDate today;

  /// What the user recorded, keyed by day of the month.
  final Map<int, CycleDayRecord> records;

  /// Opens the editor for a date. Not called for a date in the future.
  final ValueChanged<CalendarDate> onOpenDay;

  /// The mark's box inside a day cell.
  static const markerSize = 18.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final first = CalendarDate(month.year, month.month, 1);
    // Monday first, matching the rest of the app's date words.
    final leading = first.weekday - 1;
    final cells = leading + month.daysInMonth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final day in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            // Comfortably over the minimum target at any sensible width.
            childAspectRatio: 0.78,
          ),
          itemCount: cells,
          itemBuilder: (context, index) {
            if (index < leading) return const SizedBox.shrink();
            final date = first.addDays(index - leading);
            return _DayCell(
              date: date,
              record: records[date.day],
              isToday: date == today,
              // A day that has not happened cannot have been noticed.
              onTap: date.isAfter(today) ? null : () => onOpenDay(date),
            );
          },
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.record,
    required this.isToday,
    required this.onTap,
  });

  final CalendarDate date;
  final CycleDayRecord? record;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      button: onTap != null,
      label: CycleText.calendarDayLabel(
        date: date,
        record: record,
        isToday: isToday,
      ),
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: isToday
              ? BorderSide(color: palette.primary, width: 1.5)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: onTap == null
                        ? palette.textSecondary.withValues(alpha: 0.5)
                        : palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: CycleMonthCalendar.markerSize,
                  child: record == null
                      ? null
                      : BleedingMarker(
                          level: record!.level,
                          size: CycleMonthCalendar.markerSize,
                        ),
                ),
                // Beside the mark, never instead of it.
                SizedBox(
                  height: 12,
                  child: (record?.isPeriodStart ?? false)
                      ? Text(
                          CycleText.firstDayShort,
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            color: palette.textSecondary,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
