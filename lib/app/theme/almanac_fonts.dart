/// The typefaces the Almanac is set in — and the one place a bundled
/// face gets plugged in.
///
/// ## Why this file exists
///
/// Until Step 17 the app called `GoogleFonts.frauncesTextTheme()` and
/// `GoogleFonts.interTextTheme()`. That package resolves a face by
/// **downloading it from fonts.gstatic.com on first use** unless the
/// `.ttf` files are also bundled as assets and runtime fetching is
/// switched off. Neither was true here: there was no `assets/fonts/`
/// directory and no `GoogleFonts.config.allowRuntimeFetching = false`.
///
/// So the running app made a network request, to a third party, carrying
/// the device's IP — in an app whose whole architecture is "no network,
/// no analytics, nothing leaves the device". `almanac_text_roles.dart`
/// even claimed in prose that "fonts are never downloaded at runtime".
/// The prose was right about the intent and wrong about the code.
///
/// The dependency is gone. Nothing here reaches the network, and there
/// is a test that greps `pubspec.yaml` and `lib/` to keep it that way.
///
/// ## What the app is set in now
///
/// Two families, named semantically rather than by brand, so a face can
/// be swapped without touching a single screen:
///
/// - [display] — titles, dates, the moon's phase name. A serif stack:
///   the warmest, most editorial thing available without shipping a
///   font file.
/// - [text] — body copy, values, controls, navigation. The platform's
///   own UI face, which is the most readable text on any given device
///   and the one already hinted for its screen.
///
/// Both are expressed as **fallback lists with no primary family**, so
/// the engine walks the list and lands on whatever the platform actually
/// has. A name that does not exist on a platform costs nothing.
///
/// ## The slot for a bundled face
///
/// The references are set in a fine handwritten script. Shipping one is
/// a three-line change and no code change at all:
///
/// 1. put the licensed `.ttf`/`.otf` files in `assets/fonts/`;
/// 2. declare them in `pubspec.yaml` under `flutter: fonts:` with the
///    family name, e.g. `AlmanacDisplay`;
/// 3. set [bundledDisplay] (and/or [bundledText]) to that family name.
///
/// Everything downstream — every title, every label, every test — picks
/// it up, because nothing downstream names a typeface. An OFL-licensed
/// face is the obvious choice; it must be *bundled*, never fetched.
///
/// The script face deliberately belongs to [display] only. Body copy
/// stays in the platform text face whatever happens: readability is not
/// something the Almanac trades for character.
abstract final class AlmanacFonts {
  /// Set this to a bundled family name to change the app's display face.
  /// Null means "use the platform serif stack below".
  static const String? bundledDisplay = null;

  /// Set this to a bundled family name to change the app's text face.
  /// Null means "use the platform's own UI face".
  static const String? bundledText = null;

  /// The display family, or null for the fallback stack.
  static const String? display = bundledDisplay;

  /// The text family, or null for the platform default.
  static const String? text = bundledText;

  /// Serif candidates, best first. Georgia and Iowan Old Style exist on
  /// Apple platforms, Noto Serif on Android; `serif` is the generic
  /// family every engine understands and is the real backstop.
  static const List<String> displayFallback = [
    'Georgia',
    'Iowan Old Style',
    'Noto Serif',
    'Times New Roman',
    'serif',
  ];

  /// Nothing named: the platform UI face (Roboto, SF) is already the
  /// right answer, and naming one would make the other platform worse.
  static const List<String> textFallback = [];
}
