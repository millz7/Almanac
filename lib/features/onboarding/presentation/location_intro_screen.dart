import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/environment/environment_providers.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../core/widgets/widgets.dart';

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
    'Tides on your stretch of coast',
    "The season's nature near you",
    'Flora and fauna to look out for',
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

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimens.maxContentWidth,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Connect with your surroundings',
                      style: textTheme.displaySmall,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'If you allow location access, we can show you what the '
                    'world is doing right where you are:',
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  for (final benefit in _benefits)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.circle,
                            size: AppSpacing.sm,
                            color: palette.primary,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(benefit, style: textTheme.bodyLarge),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'The seasons will follow your hemisphere either way, and '
                    'your location is only ever read on your device.',
                    style: textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xl),

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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
