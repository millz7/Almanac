import 'package:flutter/material.dart';

/// The app's one yes-or-no question, in the plain dialog every chapter
/// of the book uses: removing something, clearing a log, leaving a form.
///
/// One implementation, hardened once:
///
/// * **One at a time.** While a question is on screen a second request
///   is answered "no" at once, so a double tap on Remove or Cancel can
///   never stack two dialogs.
/// * **Answered once.** An answer button does nothing once its dialog is
///   already closing, so a second tap during the closing animation
///   cannot pop the page underneath.
/// * **Dismissing is "no".** Tapping outside or pressing system Back
///   keeps whatever was about to be removed or left.
abstract final class Confirm {
  static bool _asking = false;

  static Future<bool> ask(
    BuildContext context, {
    required String title,
    required String body,
    required String yes,
    required String no,
  }) async {
    if (_asking) return false;
    _asking = true;
    try {
      final answer = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            ConfirmAnswer(label: yes, value: true),
            ConfirmAnswer(label: no, value: false),
          ],
        ),
      );
      return answer ?? false;
    } finally {
      _asking = false;
    }
  }
}

/// One answer in a dialog: closes it with [value], once.
///
/// Public so the Garden's "how far along is it?" question — a choice
/// rather than a yes-or-no — gets the same once-only behaviour.
class ConfirmAnswer<T> extends StatelessWidget {
  const ConfirmAnswer({super.key, required this.label, required this.value});

  final String label;
  final T value;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => closeOnce(context, value),
    child: Text(label),
  );

  /// Pops the dialog [context] belongs to — but only while that dialog
  /// is still the top route.
  static void closeOnce<T>(BuildContext context, T value) {
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;
    Navigator.of(context).pop(value);
  }
}
