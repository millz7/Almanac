import 'calendar_date.dart';

/// Month and weekday names, and the two date formats the app writes out.
///
/// English only, like the rest of the app's copy. Kept here rather than
/// inside a feature because a date-only type and the words for it belong
/// together — and because the alternative is a fourth private copy of the
/// list of months.
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

/// "Tuesday", for a weekday number 1–7 as [DateTime] counts them.
String weekdayName(int weekday) => _weekdays[weekday - 1];

/// "July", for a month number 1–12.
String monthName(int month) => _months[month - 1];

/// "Tuesday 15 July" — how the app says a date in a sentence.
String formatDate(CalendarDate date) =>
    '${weekdayName(date.weekday)} ${date.day} ${monthName(date.month)}';

/// "15 July" — the same date without the weekday, for lists and grids
/// where the weekday is already obvious from the layout.
String formatShortDate(CalendarDate date) =>
    '${date.day} ${monthName(date.month)}';

/// "July 2025" — a calendar's heading.
String formatMonth(CalendarDate date) =>
    '${monthName(date.month)} ${date.year}';
