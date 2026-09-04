import 'package:flutter/material.dart';

import 'app_scaffold.dart';
import 'empty_state.dart';

/// A full "not built yet" tab screen: a title plus a single [EmptyState].
///
/// Used by every top-level tab (other than Today, which has its own
/// richer layout) so each one reads as a considered part of the app
/// rather than a bare stub, without duplicating the same scaffold +
/// empty-state boilerplate in every feature.
class FeaturePlaceholderScreen extends StatelessWidget {
  const FeaturePlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
  });

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      body: [EmptyState(icon: icon, title: 'Coming soon', message: message)],
    );
  }
}
