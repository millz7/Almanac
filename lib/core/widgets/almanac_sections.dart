import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// The small written label above a passage.
///
/// A section on a paper page looks like this:
///
/// ```
/// KEY THEMES                 <- AlmanacSectionLabel
///
/// content, with room to breathe
///
/// ──────                     <- AlmanacSectionDivider
/// ```
///
/// and deliberately *not* like a Material card with a title bar, a
/// border and a shadow. Grouping on paper is done with a label, some
/// space and a rule; a box is the last resort, not the first.
///
/// The label is a header for a screen reader, because that is exactly
/// what it is.
class AlmanacSectionLabel extends StatelessWidget {
  const AlmanacSectionLabel({super.key, required this.label, this.trailing});

  final String label;

  /// An optional quiet action on the same line — "See all".
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              label,
              style: textTheme.sectionLabel?.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// A full-width hairline, for a division that separates rather than
/// decorates — between the rows of a list, under a line of a table.
///
/// Quieter than [AlmanacSectionDivider], which is the centred short rule
/// between the *passages* of a page. Two rules, two jobs, and a page
/// should rarely need both at once.
///
/// Decorative: a rule has nothing to say to a screen reader.
class AlmanacRule extends StatelessWidget {
  const AlmanacRule({super.key, this.spacing = AppSpacing.md});

  final double spacing;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: spacing),
      child: SizedBox(
        height: 1,
        child: ColoredBox(
          color: context.palette.border.withValues(alpha: 0.45),
        ),
      ),
    ),
  );
}

/// The small print under a value, an illustration or a passage.
///
/// Still real text at a real contrast — "faint" describes where it sits
/// in the hierarchy, never how hard it is to read.
class AlmanacAnnotation extends StatelessWidget {
  const AlmanacAnnotation(this.text, {super.key, this.textAlign});

  final String text;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: textAlign,
    style: Theme.of(context).textTheme.annotation
        ?.copyWith(color: context.palette.textSecondary),
  );
}

/// A passage tinted very slightly into the paper.
///
/// The Almanac's only container. No shadow, no border by default and no
/// raised surface: it is ink laid on the page, not a card floating above
/// it. Use it where grouping genuinely helps comprehension — a value
/// table, a single invitation at the foot of a page — and use a label
/// and a rule everywhere else.
class AlmanacInset extends StatelessWidget {
  const AlmanacInset({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.outlined = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Only when the whole passage is one destination.
  final VoidCallback? onTap;

  /// A hairline around the passage, for the rare case where the tint
  /// alone does not read — a selected option, for instance.
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      side: outlined ? BorderSide(color: palette.border) : BorderSide.none,
    );

    final content = Padding(padding: padding, child: child);

    if (onTap == null) {
      return DecoratedBox(
        decoration: ShapeDecoration(
          color: palette.surfaceElevated,
          shape: shape,
        ),
        child: content,
      );
    }

    return Material(
      color: palette.surfaceElevated,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppDimens.minTouchTarget,
          ),
          child: content,
        ),
      ),
    );
  }
}

/// A value and the word for it: "6:48 am" over "Sunrise".
///
/// The astronomical-value language, defined once, so the Environment's
/// strip, the Moon page and the Cycle wheel's centre all read the same
/// way. The value is what the eye should land on; the label is quiet.
///
/// One semantic node — "Sunrise, 6:48 am" — rather than two fragments.
class AlmanacValue extends StatelessWidget {
  const AlmanacValue({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.spoken,
  });

  final String label;
  final String value;

  /// A small mark above the value. Decorative: the spoken form below
  /// already says everything.
  final Widget? icon;

  /// What a screen reader says. Defaults to "label, value".
  final String? spoken;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label: spoken ?? '$label, $value',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon case final mark?) ...[
            ExcludeSemantics(child: mark),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.valueLabel?.copyWith(color: palette.textSecondary),
          ),
          Text(value, textAlign: TextAlign.center, style: textTheme.valueText),
        ],
      ),
    );
  }
}
