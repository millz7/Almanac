import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/environment/environment_providers.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../core/widgets/widgets.dart';
import 'onboarding_page.dart';

/// Explains what location would be used for, then lets the user decide.
///
/// Shown once, after the hemisphere choice. Declining is a first-class
/// outcome: the app already knows the user's hemisphere, so the seasons
/// work either way, and nothing here pressures them. Whichever they
/// choose, the app records that the explanation has been given and does
/// not ask again on its own.
class LocationIntroScreen extends ConsumerStatefulWidget {
  const LocationIntroScreen({super.key});

  @override
  ConsumerState<LocationIntroScreen> createState() =>
      _LocationIntroScreenState();
}

class _LocationIntroScreenState extends ConsumerState<LocationIntroScreen> {
  bool _busy = false;

  /// What location would eventually unlock. Deliberately phrased as
  /// things the app could show, not things the user is missing out on.
  static const _benefits = <String>[
    'Sunrise and sunset where you are',
    'How much daylight your day actually has',
    "The season's nature near you",
    'Tides on your stretch of coast',
  ];

  Future<void> _allow() async {
    setState(() => _busy = true);
    // The permission dialog is the platform's; whatever the user answers,
    // the app carries on. A refusal is not an error.
    await ref.read(locationStateProvider.notifier).requestAccess();
    await _finish();
  }

  Future<void> _notNow() async {
    setState(() => _busy = true);
    await _finish();
  }

  /// Records that the introduction has been shown, which is what moves
  /// onboarding on. If it cannot be saved the user is not trapped here:
  /// they keep their hemisphere and reach the app anyway, and the
  /// explanation may simply appear again next launch.
  Future<void> _finish() async {
    try {
      await ref.read(userSettingsProvider.notifier).markLocationIntroSeen();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "We couldn't remember that. You may see this screen again.",
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return OnboardingPage(
      heading: 'Let your Almanac follow the world around you',
      supporting:
          'With location, the app can show you what the world is doing right '
          'where you are:',
      children: [
        for (final benefit in _benefits)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: AppSpacing.sm, color: palette.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(benefit, style: textTheme.bodyLarge)),
              ],
            ),
          ),

        const SizedBox(height: AppSpacing.md),
        Text(
          'Your position is read on this device, never sent anywhere, and '
          'never shown to you as coordinates. No history of it is kept. '
          'The seasons follow your hemisphere either way.',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xl),

        // Nothing has been requested yet. Android is only asked once the
        // user presses this, never on arriving at the screen.
        PrimaryButton(
          label: 'Allow Location',
          onPressed: _busy ? null : _allow,
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: _busy ? null : _notNow,
          child: const Text('Not Now'),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'You can turn this on whenever you like.',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}
