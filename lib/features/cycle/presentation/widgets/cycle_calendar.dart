import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/time/calendar_date.dart';
import '../../../../core/time/date_words.dart';
import '../cycle_text.dart';

/// What a day in the calendar is marked as.
enum DayMark {
  /// Nothing recorded and nothing estimated.
  plain,

  /// A date the user recorded. Drawn filled.
  recorded,

  /// A date the arithmetic estimated. Drawn as a ring of dashes — a
  /// different *shape*, not a different colour, so the distinction
  /// survives without colour vision, and it is said in words in the
  /// legend and in every one of these cells' semantics.
  estimated,
}

/// The smallest a day cell is allowed to be.
const _minCell = AppDimens.minTouchTarget;

/// One month, with the recorded and estimated days marked.
///
/// Deliberately hand-built from the app's own date type rather than
/// pulling in a calendar package: it is a seven-column grid, and a
/// package would bring its own aesthetic, its own date handling and its
/// own opinions about time zones.
class CycleCalendar extends StatelessWidget {
  const CycleCalendar({
    super.key,
    required this.month,
    required this.today,
    required this.recorded,
    required this.estimated,
    required this.onPrevious,
    required this.onNext,
    required this.onTapRecorded,
  });

  /// Any date in the month being shown.
  final CalendarDate month;
  final CalendarDate today;

  /// Dates the user recorded, and dates derived from them.
  final Set<CalendarDate> recorded;
  final Set<CalendarDate> estimated;

  final VoidCallback onPrevious;
  final VoidCallback onNext;

  /// Only recorded dates can be opened: an estimate is not a thing to
  /// edit, and pretending otherwise would blur the whole distinction.
  final ValueChanged<CalendarDate> onTapRecorded;

  DayMark _markFor(CalendarDate date) {
    if (recorded.contains(date)) return DayMark.recorded;
    if (estimated.contains(date)) return DayMark.estimated;
    return DayMark.plain;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final first = month.firstOfMonth;
    // Monday first, as the rest of the app's week is.
    final leadingBlanks = first.weekday - 1;
    final cells = leadingBlanks + first.daysInMonth;
    final rows = (cells / 7).ceil();

    // A day cell grows with the text inside it, and the grid scrolls
    // sideways rather than squeezing the numbers — the same rule the
    // navigation bar follows, and the reason nothing here is ever
    // truncated.
    final scaler = MediaQuery.textScalerOf(context);
    final cell = math.max(_minCell, scaler.scale(20) * 1.8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
              tooltip: CycleText.previousMonth,
            ),
            Expanded(
              child: Text(
                formatMonth(first),
                textAlign: TextAlign.center,
                style: textTheme.titleMedium,
              ),
            ),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
              tooltip: CycleText.nextMonth,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        LayoutBuilder(
          builder: (context, constraints) {
            final width = cell * 7;
            final grid = SizedBox(
              width: width,
              child: Column(
                children: [
                  Row(
                    children: [
                      for (var weekday = 1; weekday <= 7; weekday++)
                        SizedBox(
                          width: cell,
                          child: Text(
                            weekdayName(weekday).substring(0, 1),
                            textAlign: TextAlign.center,
                            style: textTheme.labelMedium,
                            semanticsLabel: weekdayName(weekday),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  for (var row = 0; row < rows; row++)
                    Row(
                      children: [
                        for (var column = 0; column < 7; column++)
                          _cellAt(
                            index: row * 7 + column - leadingBlanks,
                            month: first,
                            size: cell,
                          ),
                      ],
                    ),
                ],
              ),
            );

            if (width <= constraints.maxWidth) return grid;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: grid,
            );
          },
        ),

        const SizedBox(height: AppSpacing.md),
        const _Legend(),
      ],
    );
  }

  Widget _cellAt({
    required int index,
    required CalendarDate month,
    required double size,
  }) {
    if (index < 0 || index >= month.daysInMonth) {
      return SizedBox(width: size, height: size);
    }

    final date = CalendarDate(month.year, month.month, index + 1);
    final mark = _markFor(date);

    return _DayCell(
      date: date,
      mark: mark,
      isToday: date == today,
      size: size,
      onTap: mark == DayMark.recorded ? () => onTapRecorded(date) : null,
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.mark,
    required this.isToday,
    required this.size,
    required this.onTap,
  });

  final CalendarDate date;
  final DayMark mark;
  final bool isToday;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    final label = switch (mark) {
      DayMark.recorded => CycleText.recordedDateLabel(date, isToday: isToday),
      DayMark.estimated => CycleText.estimatedDateLabel(date, isToday: isToday),
      DayMark.plain => CycleText.plainDateLabel(date, isToday: isToday),
    };

    final number = Text(
      '${date.day}',
      textAlign: TextAlign.center,
      style: textTheme.bodyMedium?.copyWith(
        color: mark == DayMark.recorded
            ? palette.onPrimary
            : palette.textPrimary,
        fontWeight: mark == DayMark.plain ? null : FontWeight.w600,
      ),
    );

    final content = SizedBox(
      width: size,
      height: size,
      child: Center(
        child: CustomPaint(
          painter: _MarkPainter(
            mark: mark,
            isToday: isToday,
            filled: palette.primary,
            outline: palette.icon,
            todayRing: palette.border,
          ),
          child: SizedBox(
            width: size - AppSpacing.sm,
            height: size - AppSpacing.sm,
            child: Center(child: number),
          ),
        ),
      ),
    );

    return Semantics(
      // A node of its own, so every day in the grid is something a
      // screen reader can land on and read — not only the ones that
      // happen to be buttons.
      container: true,
      label: label,
      button: onTap != null,
      excludeSemantics: true,
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(onTap: onTap, child: content),
            ),
    );
  }
}

/// Draws the mark behind a day number: a filled disc for a recorded
/// date, a ring of dashes for an estimated one, and a thin plain ring
/// for today.
class _MarkPainter extends CustomPainter {
  const _MarkPainter({
    required this.mark,
    required this.isToday,
    required this.filled,
    required this.outline,
    required this.todayRing,
  });

  final DayMark mark;
  final bool isToday;
  final Color filled;
  final Color outline;
  final Color todayRing;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;

    if (isToday) {
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = todayRing,
      );
    }

    switch (mark) {
      case DayMark.plain:
        return;
      case DayMark.recorded:
        canvas.drawCircle(centre, radius - 1, Paint()..color = filled);
      case DayMark.estimated:
        // Twelve short arcs: a dotted ring, which reads as provisional
        // at a glance and does not depend on its colour to do so.
        const dashes = 12;
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.4
          ..color = outline;
        final rect = Rect.fromCircle(center: centre, radius: radius - 1);
        for (var i = 0; i < dashes; i++) {
          final from = i * 2 * math.pi / dashes;
          canvas.drawArc(rect, from, math.pi / dashes, false, paint);
        }
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.mark != mark ||
      old.isToday != isToday ||
      old.filled != filled ||
      old.outline != outline;
}

/// What the two marks mean, in words. The distinction is never left to
/// the drawing alone.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      children: [
        for (final (mark, text) in [
          (DayMark.recorded, CycleText.recordedLegend),
          (DayMark.estimated, CycleText.estimatedLegend),
        ])
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LegendMark(mark: mark),
              const SizedBox(width: AppSpacing.sm),
              // Flexible so the words wrap at a large text size rather
              // than running off the side of the legend.
              Flexible(child: Text(text, style: textTheme.bodySmall)),
            ],
          ),
      ],
    );
  }
}

class _LegendMark extends StatelessWidget {
  const _LegendMark({required this.mark});

  final DayMark mark;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ExcludeSemantics(
      child: SizedBox(
        width: 18,
        height: 18,
        child: CustomPaint(
          painter: _MarkPainter(
            mark: mark,
            isToday: false,
            filled: palette.primary,
            outline: palette.icon,
            todayRing: palette.border,
          ),
        ),
      ),
    );
  }
}
