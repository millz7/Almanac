import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

/// The Food tab: placeholder for seasonal food guidance and user-created
/// recipes, none of which is implemented yet.
class FoodScreen extends StatelessWidget {
  const FoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderScreen(
      title: 'Food',
      icon: Icons.eco_outlined,
      message: 'Seasonal food guidance and your own recipes will live here.',
    );
  }
}
