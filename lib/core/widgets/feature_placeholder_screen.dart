import 'package:flutter/material.dart';

import 'app_scaffold.dart';
import 'empty_state.dart';

/// A full "not built yet" tab screen: a title plus a single [EmptyState].
///
/// Used by every feature the user can add to their Almanac — none of
/// which is built yet — so each one reads as a considered part of the app
/// rather than a bare stub, without duplicating the same scaffold +
/// empty-state boilerplate in every feature.
class FeaturePlaceholderScreen extends StatelessWidget {
  const FeaturePlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final String message;

  /// Shown beside the title — in practice the control that opens the
  /// user's Almanac, so it is reachable from every feature and not only
  /// from the Environment.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      trailing: trailing,
      body: [EmptyState(icon: icon, title: 'Coming soon', message: message)],
    );
  }
}
