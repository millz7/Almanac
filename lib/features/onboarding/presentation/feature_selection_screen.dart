import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/features/feature_registry.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../core/widgets/widgets.dart';
import 'onboarding_page.dart';

/// The last question: what would you like in your Almanac?
///
/// Multi-select, and choosing nothing is allowed — someone who only wants
/// to look at the sky gets an app that only shows them the sky. The
/// Environment is not on the list because it is not a choice; it is what
/// the app is.
///
/// The chosen features are held in local state and written once, on
/// Continue, so ticking six boxes is one save rather than six.
class FeatureSelectionScreen extends ConsumerStatefulWidget {
  const FeatureSelectionScreen({super.key});

  @override
  ConsumerState<FeatureSelectionScreen> createState() =>
      _FeatureSelectionScreenState();
}

class _FeatureSelectionScreenState
    extends ConsumerState<FeatureSelectionScreen> {
  late Set<FeatureId> _chosen;
  bool _busy = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // Seeded from whatever is stored, so a save that failed last time
    // does not silently lose the ticks.
    _chosen = {...ref.read(userSettingsProvider).features};
  }

  void _toggle(FeatureId id) => setState(() {
    _failed = false;
    if (!_chosen.remove(id)) _chosen.add(id);
  });

  Future<void> _finish() async {
    setState(() {
      _busy = true;
      _failed = false;
    });

    try {
      final settings = ref.read(userSettingsProvider.notifier);
      await settings.setFeatures(_chosen);
      // Written last, so setup is only "done" once the choices are safely
      // stored. Routing follows this flag.
      await settings.completeOnboarding();
    } on Object {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return OnboardingPage(
      heading: 'What would you like in your Almanac?',
      supporting:
          'Choose the parts you are interested in. Each one becomes its own '
          'place at the bottom of the screen, and you can add or remove them '
          'whenever you like.',
      children: [
        for (final feature in FeatureRegistry.optional) ...[
          ChoiceCard(
            title: feature.name,
            description: feature.description,
            icon: feature.icon,
            selected: _chosen.contains(feature.id),
            enabled: !_busy,
            onPressed: () => _toggle(feature.id),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: _chosen.isEmpty ? 'Just the Environment' : 'Continue',
          onPressed: _busy ? null : _finish,
        ),

        if (_failed) ...[
          const SizedBox(height: AppSpacing.md),
          OnboardingSaveFailed(
            message:
                'Your choices could not be saved on this device. Please try '
                'again.',
            onRetry: _busy ? null : () => setState(() => _failed = false),
          ),
        ],

        const SizedBox(height: AppSpacing.lg),
        Text(
          'The Environment — the season, sky, sun and moon — is always '
          'here.',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}
