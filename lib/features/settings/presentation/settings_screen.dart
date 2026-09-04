import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/environment/environment_providers.dart';
import '../../../core/environment/geo_location.dart';
import '../../../core/environment/location_state.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../core/widgets/widgets.dart';

/// Settings: deliberately small.
///
/// One section, because there is one thing the user genuinely needs to be
/// able to correct — their hemisphere — and one thing they may want to
/// change their mind about: location access. It wears the active seasonal
/// palette like every other screen, rather than looking like a list of
/// system switches.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimens.maxContentWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: const [
                SectionHeader(title: 'Location & Region'),
                SizedBox(height: AppSpacing.md),
                _HemisphereSetting(),
                SizedBox(height: AppSpacing.xl),
                _LocationSetting(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lets the user correct the hemisphere they chose during onboarding.
class _HemisphereSetting extends ConsumerStatefulWidget {
  const _HemisphereSetting();

  @override
  ConsumerState<_HemisphereSetting> createState() => _HemisphereSettingState();
}

class _HemisphereSettingState extends ConsumerState<_HemisphereSetting> {
  bool _saving = false;
  bool _failed = false;

  Future<void> _choose(Hemisphere hemisphere) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });

    try {
      await ref
          .read(userSettingsProvider.notifier)
          .selectHemisphere(hemisphere);
      // Nothing to navigate: the environment and theme are watching the
      // setting, so the whole app has already changed season by now.
    } on Object {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chosen = ref.watch(userSettingsProvider).hemisphere;
    final resolved = ref.watch(resolvedHemisphereProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hemisphere', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Which half of the world your seasons follow.',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),

        for (final hemisphere in Hemisphere.values) ...[
          ChoiceCard(
            title: hemisphere.label,
            selected: chosen == hemisphere,
            enabled: !_saving,
            onPressed: () => _choose(hemisphere),
          ),
          if (hemisphere != Hemisphere.values.last)
            const SizedBox(height: AppSpacing.sm),
        ],

        // When a real position disagrees with the stored choice, say so
        // plainly rather than letting the app quietly contradict the user.
        if (resolved.disagreesWithPreference) ...[
          const SizedBox(height: AppSpacing.md),
          _Note(
            icon: Icons.my_location_outlined,
            text:
                'Your location puts you in the '
                '${resolved.hemisphere.label.toLowerCase()}, so seasons are '
                'following that. Your choice above is kept.',
          ),
        ],

        if (_failed) ...[
          const SizedBox(height: AppSpacing.md),
          _Note(
            icon: Icons.error_outline,
            isError: true,
            text: 'That could not be saved on this device. Please try again.',
          ),
        ],
      ],
    );
  }
}

/// Shows where location access stands, and offers the one action that
/// makes sense for that state.
class _LocationSetting extends ConsumerStatefulWidget {
  const _LocationSetting();

  @override
  ConsumerState<_LocationSetting> createState() => _LocationSettingState();
}

class _LocationSettingState extends ConsumerState<_LocationSetting> {
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

/// A quiet inline note.
class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, this.isError = false});

  final IconData icon;
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      liveRegion: isError,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: AppIconSize.sm,
            color: isError ? palette.error : palette.icon,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: textTheme.bodySmall)),
        ],
      ),
    );
  }
}
