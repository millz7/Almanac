import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/environment/environment_providers.dart';
import '../../../../core/environment/location_state.dart';
import '../../../../core/widgets/widgets.dart';

/// Shows where location access stands, and offers the one action that
/// makes sense for that state.
class LocationSetting extends ConsumerStatefulWidget {
  const LocationSetting({super.key});

  @override
  ConsumerState<LocationSetting> createState() => LocationSettingState();
}

class LocationSettingState extends ConsumerState<LocationSetting> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(locationStateProvider);
    final controller = ref.read(locationStateProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Location access', style: textTheme.bodyLarge),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Status is carried by the words, not by colour alone.
                  Text(_statusLabel(state), style: textTheme.labelLarge),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(_explanation(state), style: textTheme.bodySmall),

              if (state case LocationAvailable(:final accuracyMetres)
                  when accuracyMetres != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Accurate to about ${accuracyMetres.round()} m, which is '
                  'plenty for sunrise and sunset.',
                  style: textTheme.bodySmall,
                ),
              ],

              const SizedBox(height: AppSpacing.md),
              ..._actionsFor(state, controller),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),
        Text(
          'Your location is only ever read on this device. It is never '
          'sent anywhere and no history of it is kept.',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }

  String _statusLabel(LocationState state) => switch (state) {
    LocationAvailable() => 'Allowed',
    LocationPermissionNotRequested() => 'Not enabled',
    LocationPermissionDenied() => 'Not enabled',
    LocationPermissionPermanentlyDenied() => 'Blocked',
    LocationUnavailable() => 'Unavailable',
  };

  String _explanation(LocationState state) => switch (state) {
    LocationAvailable() =>
      'Sunrise and sunset are calculated for where you are.',
    LocationPermissionNotRequested() =>
      'Seasons follow your hemisphere. Add location for sunrise and '
          'sunset where you actually are.',
    LocationPermissionDenied() =>
      'That is fine — the app works from your hemisphere. You can turn '
          'location on whenever you like.',
    LocationPermissionPermanentlyDenied() =>
      'Location is blocked for this app in your device settings. The app '
          'keeps working from your hemisphere.',
    LocationUnavailable() =>
      'Your position could not be read just now. The app keeps working '
          'from your hemisphere.',
  };

  List<Widget> _actionsFor(LocationState state, LocationController controller) {
    if (_busy) {
      return const [
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: AppIconSize.md,
            height: AppIconSize.md,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ];
    }

    return switch (state) {
      // Nothing to grant; offer a fresh reading for someone who has moved.
      LocationAvailable() => [
        OutlinedButton(
          onPressed: () => _run(() => controller.refresh(force: true)),
          child: const Text('Update my location'),
        ),
      ],
      // Android will no longer prompt, so send them to the only place
      // that can change it.
      LocationPermissionPermanentlyDenied() => [
        PrimaryButton(
          label: 'Open app settings',
          onPressed: () => _run(controller.openSystemSettings),
        ),
      ],
      LocationPermissionNotRequested() ||
      LocationPermissionDenied() ||
      LocationUnavailable() => [
        PrimaryButton(
          label: 'Enable Location',
          onPressed: () => _run(controller.requestAccess),
        ),
      ],
    };
  }
}
