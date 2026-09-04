import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

/// The Rhythms tab: placeholder for moon phases, seasons, the Wheel of
/// the Year and optional cycle tracking, none of which is implemented yet.
class RhythmsScreen extends StatelessWidget {
  const RhythmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderScreen(
      title: 'Rhythms',
      icon: Icons.brightness_3_outlined,
      message:
          'The moon, the seasons and the Wheel of the Year will live here.',
    );
  }
}
