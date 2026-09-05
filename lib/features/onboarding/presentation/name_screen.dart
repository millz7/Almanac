import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../core/widgets/widgets.dart';
import 'onboarding_page.dart';

/// The first thing the app asks, and the least important.
///
/// The name is used for one thing: the title of the user's own Almanac.
/// So skipping is offered as plainly as answering, and no account, sign-in
/// or verification exists anywhere near this screen.
class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key});

  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  bool _failed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Saves whatever is in the field — including nothing, which is what
  /// "Skip" does. Either way the question counts as asked and setup moves
  /// on; routing follows the saved setting, so there is nothing to
  /// navigate to here.
  Future<void> _finish({required bool keepName}) async {
    setState(() {
      _busy = true;
      _failed = false;
    });

    try {
      await ref
          .read(userSettingsProvider.notifier)
          .setName(keepName ? _controller.text : null);
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
      heading: 'What should we call you?',
      supporting:
          'Only to give your Almanac a name. It stays on this device, it is '
          'never sent anywhere, and you can skip it.',
      children: [
        TextField(
          controller: _controller,
          enabled: !_busy,
          autofocus: false,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          maxLength: UserSettingsController.maxNameLength,
          decoration: const InputDecoration(
            labelText: 'Your name',
            counterText: '',
          ),
          onSubmitted: (_) => _finish(keepName: true),
        ),
        const SizedBox(height: AppSpacing.xl),

        PrimaryButton(
          label: 'Continue',
          onPressed: _busy ? null : () => _finish(keepName: true),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Skipping is a real answer, so it is a plain, visible control
        // rather than something to hunt for.
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _busy ? null : () => _finish(keepName: false),
            child: const Text('Skip'),
          ),
        ),

        if (_failed) ...[
          const SizedBox(height: AppSpacing.md),
          OnboardingSaveFailed(
            message:
                'That could not be saved on this device. Please try again.',
            onRetry: _busy ? null : () => setState(() => _failed = false),
          ),
        ],

        const SizedBox(height: AppSpacing.lg),
        Text(
          'You can change or remove this later.',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}
