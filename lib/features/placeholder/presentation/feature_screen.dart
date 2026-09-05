import 'package:flutter/material.dart';

import '../../../app/almanac_button.dart';
import '../../../core/features/feature_registry.dart';
import '../../../core/widgets/widgets.dart';

/// The screen for a feature that has been chosen but not yet built.
///
/// One screen for all of them, driven entirely by the feature's own
/// [FeatureDefinition], so the seven features in the registry do not need
/// seven near-identical files — and building a real feature later means
/// replacing one registry route, not deleting a stub.
///
/// It makes plain which feature it is (its own name, its own icon, its
/// own sentence) without pretending to be the feature.
class FeatureScreen extends StatelessWidget {
  const FeatureScreen({super.key, required this.feature});

  final FeatureDefinition feature;

  @override
  Widget build(BuildContext context) {
    return FeaturePlaceholderScreen(
      title: feature.name,
      icon: feature.icon,
      message: feature.placeholderMessage,
      trailing: const AlmanacButton(),
    );
  }
}
