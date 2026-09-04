import 'package:flutter/material.dart';

/// The app's primary call-to-action button.
///
/// A thin, semantic wrapper around [ElevatedButton] so call sites write
/// `PrimaryButton(label: ..., onPressed: ...)` and every primary action in
/// the app automatically shares one visual style, defined once in
/// `app_theme.dart`.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return ElevatedButton(onPressed: onPressed, child: Text(label));
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
