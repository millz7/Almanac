import 'package:flutter/material.dart';

import '../../core/features/feature_registry.dart';
import '../theme/app_theme.dart';
import 'navigation_labels.dart';

/// The app's bottom navigation: the Environment, followed by whichever
/// features the user has put in their Almanac.
///
/// Custom rather than Material's [NavigationBar] for one reason: with
/// every feature chosen there are eight destinations, and Material's bar
/// solves that by shrinking the labels until they truncate. This app does
/// not truncate. It picks a shorter *word* the designer chose — "Nature"
/// for Nature Log — and if even those will not fit, the bar scrolls
/// sideways with every destination still present and still full-size to
/// tap. There is no "more", no "explore" and nothing hidden.
///
/// The visible label may be the short one; the accessibility label is
/// always the full name.
class AlmanacNavigationBar extends StatefulWidget {
  const AlmanacNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  /// In the order they appear: the Environment first, then the user's
  /// chosen features in registry order.
  final List<FeatureDefinition> destinations;

  /// Index into [destinations], or -1 when the current screen is not one
  /// of them.
  final int selectedIndex;

  final ValueChanged<int> onDestinationSelected;

  @override
  State<AlmanacNavigationBar> createState() => _AlmanacNavigationBarState();
}

class _AlmanacNavigationBarState extends State<AlmanacNavigationBar> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(AlmanacNavigationBar old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) _revealSelected();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Brings the selected destination into view when the bar is scrolling.
  ///
  /// Without this, tapping the last of eight tabs on a narrow phone and
  /// coming back later would leave the current tab off the side of the
  /// screen — which would undo the promise that every destination stays
  /// directly reachable. The items are all the same width, so the offset
  /// is arithmetic; no keys or measurements needed.
  void _revealSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final position = _scrollController.position;
      final viewport = position.viewportDimension;
      final itemWidth =
          (position.maxScrollExtent + viewport) / widget.destinations.length;
      final target =
          itemWidth * widget.selectedIndex - (viewport - itemWidth) / 2;

      _scrollController.animateTo(
        target.clamp(0, position.maxScrollExtent),
        duration: AppMotion.medium,
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // The navigation role, not a raw Material slot: 13pt, because this
    // is a primary control and 10pt navigation text is the thing the
    // short labels exist to avoid.
    final style = Theme.of(context).textTheme.navigationLabel!;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        // A hairline rather than a shadow: the app's depth comes from
        // colour and space, and this bar has to sit convincingly under
        // both a painted landscape and a paper page.
        border: Border(
          top: BorderSide(color: palette.border.withValues(alpha: 0.6)),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = resolveNavigationLayout(
              destinations: widget.destinations,
              available: constraints.maxWidth,
              style: style,
              textScaler: MediaQuery.textScalerOf(context),
            );

            final items = [
              for (final (index, feature) in widget.destinations.indexed)
                _NavigationItem(
                  feature: feature,
                  label: layout.labelFor(feature),
                  labelStyle: style,
                  selected: index == widget.selectedIndex,
                  width: layout.itemWidth,
                  height: layout.height,
                  onTap: () => widget.onDestinationSelected(index),
                ),
            ];

            return SizedBox(
              height: layout.height,
              child: layout.scrollable
                  ? ListView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      children: items,
                    )
                  : Row(children: items),
            );
          },
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.feature,
    required this.label,
    required this.labelStyle,
    required this.selected,
    required this.width,
    required this.height,
    required this.onTap,
  });

  final FeatureDefinition feature;
  final String label;
  final TextStyle labelStyle;
  final bool selected;
  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      button: true,
      selected: selected,
      // Always the full name, even when the visible label is "Chak".
      label: feature.name,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // The selected state is carried by three things — a small
              // rule above the destination, a filled rather than an
              // outlined icon, and the ink — so it never rests on colour
              // alone. The rule is a bookmark ribbon rather than the
              // Material pill: on an illustrated bar a filled capsule
              // reads as a control panel dropped over the page.
              ExcludeSemantics(
                child: SizedBox(
                  width: 20,
                  height: 2,
                  child: ColoredBox(
                    color: selected ? palette.primary : Colors.transparent,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Icon(
                selected ? feature.selectedIcon : feature.icon,
                size: AppIconSize.md,
                color: selected ? palette.primary : palette.textSecondary,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: labelStyle.copyWith(
                  color: selected ? palette.primary : palette.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                softWrap: false,
                // Clip, never ellipsis. The layout has already measured
                // this label and made room for it, so this should not be
                // reachable — but if it ever is, a hard edge is honest
                // and a "..." is not.
                overflow: TextOverflow.clip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
