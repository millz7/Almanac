/// Spacing tokens. The interface should breathe — prefer the larger steps
/// over cramming content together, and use these instead of hard-coded
/// padding/gap values throughout the app.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

/// Corner-radius tokens. Larger, softer radii read as organic rather than
/// as rigid dashboard cards.
abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 20;
  static const double lg = 28;
  static const double pill = 999;
}

/// Elevation tokens, kept low and used sparingly — depth should come from
/// colour and spacing before shadow.
abstract final class AppElevation {
  static const double none = 0;
  static const double low = 1;
  static const double medium = 3;
  static const double high = 6;
}

/// Animation duration and curve tokens.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}

/// Icon-size tokens.
abstract final class AppIconSize {
  static const double sm = 18;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 48;
}

/// Shared component dimensions.
abstract final class AppDimens {
  /// Minimum touch target size for accessibility (WCAG 2.5.5 / Material).
  static const double minTouchTarget = 48;
  static const double buttonHeight = 56;
  static const double navBarHeight = 72;
  static const double maxContentWidth = 640;
}
