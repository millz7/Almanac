import 'package:flutter/foundation.dart';

import '../../../app/theme/app_theme.dart';

/// The seven centres this feature describes, from the base upwards.
///
/// Seven, and only these seven: the count and the order are the ones most
/// commonly referenced, and both are fixed by
/// `chakra_content_test.dart`.
enum ChakraId { root, sacral, solarPlexus, heart, throat, thirdEye, crown }

/// One chakra, as a piece of content.
///
/// Everything the app says about a chakra lives here, so the screens
/// consume data rather than seven hand-written pages, and so the wording
/// can be checked in one place — there is a test that reads every string
/// in the catalogue looking for anything that sounds like a medical
/// claim.
///
/// Note what this is *not*. Nothing here is presented as a fact about the
/// body. Each entry is a traditional association, and the screens say so
/// in those words.
@immutable
class Chakra {
  const Chakra({
    required this.id,
    required this.name,
    required this.sanskrit,
    required this.hue,
    required this.place,
    required this.associations,
    required this.prompt,
    required this.points,
    required this.position,
  });

  final ChakraId id;

  /// The English name, e.g. "Solar Plexus".
  final String name;

  /// The Sanskrit name in plain transliteration, e.g. "Manipura".
  ///
  /// Deliberately without diacritics — see `chakra_content_test.dart`,
  /// which pins the transliterations to ASCII so no font in the app has
  /// to carry the marks to render a name correctly.
  final String sanskrit;

  /// The traditional colour. Carries the *word* as well as the hue, so
  /// the colour is never the only way to tell one chakra from another.
  final ChakraHue hue;

  /// Where it is traditionally placed on the body, e.g. "the throat".
  /// Written to follow "Traditionally placed at ...".
  final String place;

  /// Three traditional associations, in order, e.g.
  /// `['grounding', 'stability', 'belonging']`.
  ///
  /// Three is not enforced by the constructor — `List.length` is not
  /// available in a constant expression, and these are all `const` — so
  /// `chakra_content_test.dart` holds the shape instead.
  final List<String> associations;

  /// A quiet question. Not a test, and there is no right answer.
  final String prompt;

  /// How many points its drawn symbol carries.
  ///
  /// The traditional petal counts where they can be drawn — four for the
  /// Root, sixteen for the Throat, two for the Third Eye. The Crown's
  /// thousand petals cannot be, so it is drawn as a full ring, which is
  /// the same idea at a size a screen can hold.
  final int points;

  /// Its place in the sequence from the base, 1 to 7. Used for ordering
  /// and for the wording "third of seven", never as a score.
  final int position;

  /// "grounding, stability and belonging"
  String get associationPhrase =>
      '${associations.take(associations.length - 1).join(', ')} '
      'and ${associations.last}';

  /// "Traditionally associated with grounding, stability and belonging."
  String get traditionSentence =>
      'Traditionally associated with $associationPhrase.';

  /// What a screen reader hears in place of the drawn point:
  /// "Root chakra. Traditionally associated with grounding, stability and
  /// belonging."
  String get semanticLabel => '$name chakra. $traditionSentence';

  @override
  String toString() => 'Chakra(${id.name})';
}
