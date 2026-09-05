import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';

/// The shared shape of every onboarding screen.
///
/// One heading, one paragraph, then whatever the screen is asking for.
/// Extracted so the four screens cannot drift apart, and so each of them
/// inherits the same generous measure, the same scrolling behaviour at
/// large text sizes, and the active seasonal palette — onboarding already
/// looks like the app rather than like a setup wizard.
///
/// No progress dots and no step counter: this is four short questions,
/// not a form to endure.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.heading,
    required this.supporting,
    required this.children,
  });

  final String heading;
  final String supporting;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
                    child: Text(heading, style: textTheme.displaySmall),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(supporting, style: textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.xl),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when an answer could not be written to disk.
///
/// Onboarding deliberately does not continue as though a save worked: the
/// whole point of these questions is that the answers are remembered.
class OnboardingSaveFailed extends StatelessWidget {
  const OnboardingSaveFailed({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      liveRegion: true,
      child: AppCard(
        color: palette.surfaceElevated,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: palette.error,
              size: AppIconSize.md,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("That didn't save", style: textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(message, style: textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
