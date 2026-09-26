import 'package:flutter/widgets.dart';

import 'confirm.dart';

/// The one question the app asks before throwing typed words away.
///
/// Shared, so a half-written recipe and a half-written observation are
/// asked about in the same words, in the same plain dialog the rest of
/// the book uses — and so there is one implementation to keep right.
abstract final class UnsavedChanges {
  static const title = 'Leave without saving?';
  static const body = 'What you have written here will not be kept.';
  static const leave = 'Leave';
  static const keepEditing = 'Keep editing';

  /// True when the user chose to leave. Dismissing the dialog — tapping
  /// outside it, or system Back — keeps editing, which loses nothing.
  static Future<bool> confirmLeave(BuildContext context) => Confirm.ask(
    context,
    title: title,
    body: body,
    yes: leave,
    no: keepEditing,
  );
}
