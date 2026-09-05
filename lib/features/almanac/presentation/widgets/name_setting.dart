import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/settings/settings_providers.dart';
import 'inline_note.dart';

/// Lets the user set, change or remove the name on their Almanac.
///
/// The name is used for exactly one thing — the title of this panel — and
/// clearing the field is a real answer, not an error: an empty name means
/// "Your Almanac" again. Nothing is validated beyond trimming, because
/// telling somebody their own name is unacceptable would be a strange
/// thing for this app to do.
class NameSetting extends ConsumerStatefulWidget {
  const NameSetting({super.key});

  @override
  ConsumerState<NameSetting> createState() => _NameSettingState();
}

class _NameSettingState extends ConsumerState<NameSetting> {
  late final TextEditingController _controller;
  bool _saving = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(userSettingsProvider).name ?? '',
    )..addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() => _failed = false);

  /// What is stored, for comparison with what has been typed.
  String get _saved => ref.watch(userSettingsProvider).name ?? '';

  bool get _dirty => _controller.text.trim() != _saved;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _failed = false;
    });

    try {
      await ref.read(userSettingsProvider.notifier).setName(_controller.text);
    } on Object {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Name', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Only used to name your Almanac. It stays on this device.',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),

        TextField(
          controller: _controller,
          enabled: !_saving,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          maxLength: UserSettingsController.maxNameLength,
          decoration: const InputDecoration(
            labelText: 'Your name',
            hintText: 'Leave empty for "Your Almanac"',
            // The counter would be the only number on a very quiet
            // screen, and the limit is generous enough not to need
            // announcing.
            counterText: '',
          ),
          onSubmitted: (_) {
            if (_dirty) _save();
          },
        ),
        const SizedBox(height: AppSpacing.sm),

        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _dirty && !_saving ? _save : null,
            child: Text(
              _controller.text.trim().isEmpty && _saved.isNotEmpty
                  ? 'Remove name'
                  : 'Save name',
            ),
          ),
        ),

        if (_failed) ...[
          const SizedBox(height: AppSpacing.sm),
          const InlineNote(
            icon: Icons.error_outline,
            isError: true,
            text: 'That could not be saved on this device. Please try again.',
          ),
        ],
      ],
    );
  }
}
