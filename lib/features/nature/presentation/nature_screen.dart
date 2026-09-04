import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

/// The Nature tab: placeholder for flora, fauna and nature checklists,
/// none of which is implemented yet.
class NatureScreen extends StatelessWidget {
  const NatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderScreen(
      title: 'Nature',
      icon: Icons.forest_outlined,
      message: "What's growing, blooming and moving around you will live here.",
    );
  }
}
