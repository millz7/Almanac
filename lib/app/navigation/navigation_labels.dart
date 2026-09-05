import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/features/feature_registry.dart';
import '../theme/app_theme.dart';

/// Which set of labels the navigation bar is showing, and how it is laid
/// out to fit them.
@immutable
class NavigationLayout {
  const NavigationLayout({
    required this.useShortLabels,
    required this.scrollable,
    required this.itemWidth,
    required this.height,
  });

  /// True when the bar has fallen back to each feature's deliberate short
  /// name — "Nature" for Nature Log — because the full names would not
  /// fit. Never a truncation: the app has no ellipsis anywhere in its
  /// navigation.
  final bool useShortLabels;

  /// True when even the short names will not fit across the width, so the
  /// bar scrolls sideways instead. Every destination is still present and
  /// still directly reachable; nothing is hidden behind a "more".
  final bool scrollable;

  final double itemWidth;

  /// The bar's height, which grows with the text scale so a label at
  /// twice the size still has room rather than being clipped.
  final double height;

  /// The label to show for a feature under this layout.
  String labelFor(FeatureDefinition feature) =>
      useShortLabels ? feature.shortName : feature.name;

  @override
  String toString() =>
      'NavigationLayout(${useShortLabels ? 'short' : 'full'}'
      '${scrollable ? ', scrolling' : ''}, '
      'item ${itemWidth.toStringAsFixed(1)}×${height.toStringAsFixed(1)})';
}

/// Room either side of a label inside its navigation item.
///
/// Tight on purpose. The item's *width* is still floored at
/// [AppDimens.minTouchTarget], so trimming this does not make anything
/// harder to tap — it only decides how soon a full Almanac has to start
/// scrolling. At this value eight destinations with their short names fit
/// across a typical modern phone; at a roomier value they would not.
const kNavigationLabelPadding = AppSpacing.xs;

/// Space above the icon and below the label.
const _verticalPadding = 6.0;

/// Vertical padding of the pill drawn behind the selected icon.
const _pillPadding = 2.0;

/// Decides how the bar should present [destinations] in [available] width.
///
/// Measures the real labels at the real text scale rather than guessing
/// from a character count, because that is the only way to promise there
/// will never be an ellipsis — a promise that has to hold at 200% text
/// size and in whatever font the theme is using, not just in the design
/// mock.
///
/// The order of preference is: full names across the width, then short
/// names across the width, then short names in a strip that scrolls.
/// Touch targets never shrink below [AppDimens.minTouchTarget] at any
/// stage, so a crowded bar becomes scrollable rather than fiddly.
NavigationLayout resolveNavigationLayout({
  required List<FeatureDefinition> destinations,
  required double available,
  required TextStyle style,
  required TextScaler textScaler,
}) {
  double widestLabel({required bool short}) => destinations
      .map(
        (feature) => _measureLabel(
          short ? feature.shortName : feature.name,
          style,
          textScaler,
        ).width,
      )
      .reduce(math.max);

  // Any label will do for the height: they are all one line in the same
  // style, so they are all the same height.
  final labelHeight = _measureLabel('Ag', style, textScaler).height;
  final height = math.max(
    AppDimens.navBarHeight,
    _verticalPadding * 2 +
        AppIconSize.md +
        _pillPadding * 2 +
        AppSpacing.xs +
        labelHeight,
  );

  for (final short in [false, true]) {
    final needed = math.max(
      widestLabel(short: short) + kNavigationLabelPadding * 2,
      AppDimens.minTouchTarget,
    );
    if (needed * destinations.length <= available) {
      return NavigationLayout(
        useShortLabels: short,
        scrollable: false,
        // Share the width out evenly, which is at least `needed` each.
        itemWidth: available / destinations.length,
        height: height,
      );
    }
  }

  return NavigationLayout(
    useShortLabels: true,
    scrollable: true,
    itemWidth: math.max(
      widestLabel(short: true) + kNavigationLabelPadding * 2,
      AppDimens.minTouchTarget,
    ),
    height: height,
  );
}

Size _measureLabel(String label, TextStyle style, TextScaler textScaler) {
  final painter = TextPainter(
    text: TextSpan(text: label, style: style),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
    maxLines: 1,
  )..layout();
  return painter.size;
}
