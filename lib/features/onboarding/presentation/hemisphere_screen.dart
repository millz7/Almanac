import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/environment/geo_location.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../core/widgets/widgets.dart';
import 'onboarding_page.dart';

/// The first thing the app ever asks.
///
/// One question, two answers, no forms. The screen wears whatever
/// seasonal palette is currently active, so onboarding already looks like
/// the app rather than like a setup wizard — and the moment a hemisphere
/// is chosen the palette changes to that hemisphere's real season.
class HemisphereScreen extends ConsumerStatefulWidget {
  const HemisphereScreen({super.key});

  @override
  ConsumerState<HemisphereScreen> createState() => _HemisphereScreenState();
}

class _HemisphereScreenState extends ConsumerState<HemisphereScreen> {
  /// Which choice is mid-save, if any. Used to disable both options so a
  /// double tap cannot race.
  Hemisphere? _saving;
  bool _failed = false;

  Future<void> _choose(Hemisphere hemisphere) async {
    setState(() {
      _saving = hemisphere;
      _failed = false;
    });

    try {
      await ref
          .read(userSettingsProvider.notifier)
          .selectHemisphere(hemisphere);
      // Routing reacts to the saved setting, so there is nothing to
      // navigate to here.
    } on Object {
      // The choice was not saved, so the app must not behave as if it
      // was. Stay put and offer another go.
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final busy = _saving != null;

    return OnboardingPage(
      heading: 'Where are you in the world?',
      supporting:
          'We use your hemisphere to follow the seasons where you live.',
      children: [
        for (final hemisphere in Hemisphere.values) ...[
          ChoiceCard(
            title: hemisphere.label,
            description: _descriptionFor(hemisphere),
            icon: _iconFor(hemisphere),
            selected: _saving == hemisphere,
            enabled: !busy,
            onPressed: () => _choose(hemisphere),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        if (_failed) ...[
          const SizedBox(height: AppSpacing.md),
          OnboardingSaveFailed(
            message:
                'Your choice could not be stored on this device. Please try '
                'again.',
            onRetry: busy ? null : () => setState(() => _failed = false),
          ),
        ],

        const SizedBox(height: AppSpacing.lg),
        Text('You can change this later.', style: textTheme.bodySmall),
      ],
    );
  }

  /// Grounding examples rather than latitudes — the point is that someone
  /// recognises their own part of the world, not that they know a number.
  String _descriptionFor(Hemisphere hemisphere) => switch (hemisphere) {
    Hemisphere.northern => 'Europe, North America, most of Asia',
    Hemisphere.southern =>
      'Australia, New Zealand, southern Africa, '
          'most of South America',
  };

  IconData _iconFor(Hemisphere hemisphere) => switch (hemisphere) {
    Hemisphere.northern => Icons.north_outlined,
    Hemisphere.southern => Icons.south_outlined,
  };
}
