import 'package:flutter/foundation.dart';

/// A run of calendar months, inclusive, which may wrap the new year.
///
/// `MonthWindow(9, 3)` is September to March — the shape most southern
/// hemisphere seasonal windows have, and the reason this is a type
/// rather than a pair of ints.
///
/// Lives in `core/time/` because two features now reason in months: the
/// Garden's sowing and pruning windows, and the Nature Log's "worth
/// looking for around now". It knows nothing about either of them.
@immutable
class MonthWindow {
  const MonthWindow(this.from, this.to)
    : assert(from >= 1 && from <= 12, 'from is a month'),
      assert(to >= 1 && to <= 12, 'to is a month');

  /// A single month.
  const MonthWindow.only(int month) : from = month, to = month;

  /// The whole year, for advice that is not seasonal.
  static const year = MonthWindow(1, 12);

  final int from;
  final int to;

  /// Whether the window runs through the new year.
  bool get wraps => to < from;

  /// How many months it covers.
  int get length => wraps ? (12 - from + 1) + to : to - from + 1;

  bool contains(int month) =>
      wraps ? month >= from || month <= to : month >= from && month <= to;

  /// The same window moved by [months], wrapping the year.
  MonthWindow shifted(int months) =>
      MonthWindow(_wrapMonth(from + months), _wrapMonth(to + months));

  static int _wrapMonth(int month) => ((month - 1) % 12 + 12) % 12 + 1;

  @override
  bool operator ==(Object other) =>
      other is MonthWindow && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => from == to ? '$from' : '$from-$to';
}
