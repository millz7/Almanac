import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

/// The Wellbeing tab: placeholder for breathing, mindfulness, yoga and
/// chakra content, none of which is implemented yet.
class WellbeingScreen extends StatelessWidget {
  const WellbeingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderScreen(
      title: 'Wellbeing',
      icon: Icons.self_improvement_outlined,
      message: 'Mindful breathing, yoga and chakra practices will live here.',
    );
  }
}
