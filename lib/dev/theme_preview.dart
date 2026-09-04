import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/environment/season.dart';

/// A forced season/time combination, for previewing the theme during
/// development.
@immutable
class ThemePreviewSelection {
  const ThemePreviewSelection({required this.season, required this.isNight});

  final Season season;
  final bool isNight;

  /// Preview jumps straight to full day or full night rather than sitting
  /// mid-twilight, so each designed palette can be inspected exactly as
  /// authored.
  double get daylight => isNight ? 0 : 1;

  String get label => '${season.label} ${isNight ? 'Night' : 'Day'}';

  ThemePreviewSelection copyWith({Season? season, bool? isNight}) =>
      ThemePreviewSelection(
        season: season ?? this.season,
        isNight: isNight ?? this.isNight,
      );
}

/// DEVELOPMENT ONLY — overrides the automatic seasonal theme.
///
/// This is deliberately not a user setting and there is no UI for it in the
/// production experience: the app always determines the season and the time
/// of day from the real world. It exists so the eight designed palettes can
/// be inspected without waiting months for the weather to change.
///
/// Every mutation is gated on [kDebugMode], so a release build cannot be
/// pushed into an overridden state even if something calls these methods.
class ThemePreviewController extends Notifier<ThemePreviewSelection?> {
  @override
  ThemePreviewSelection? build() => null;

  /// Whether previewing is possible at all. False in release builds.
  static bool get isAvailable => kDebugMode;

  void select(ThemePreviewSelection selection) {
    if (!isAvailable) return;
    state = selection;
  }

  void selectSeason(Season season) {
    if (!isAvailable) return;
    state =
        (state ??
                const ThemePreviewSelection(
                  season: Season.summer,
                  isNight: false,
                ))
            .copyWith(season: season);
  }

  void selectNight({required bool isNight}) {
    if (!isAvailable) return;
    state =
        (state ??
                const ThemePreviewSelection(
                  season: Season.summer,
                  isNight: false,
                ))
            .copyWith(isNight: isNight);
  }

  /// Hands control back to the real world.
  void clear() => state = null;
}

/// Null means "use the real environment", which is always the case in
/// release builds.
final themePreviewProvider =
    NotifierProvider<ThemePreviewController, ThemePreviewSelection?>(
      ThemePreviewController.new,
    );
