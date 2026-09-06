import '../../../app/theme/app_theme.dart';
import 'chakra.dart';

export 'chakra.dart';

/// The seven chakras, and the words the feature frames them with.
///
/// Static data, read by the screens. Adding an eighth would be a change
/// here and nowhere else — and there is a test saying not to.
abstract final class ChakraCatalogue {
  /// How the feature introduces itself.
  ///
  /// The framing matters more than anything else on the screen: this is a
  /// traditional map, offered as a way of pausing, and the app says that
  /// plainly rather than implying it is describing the body.
  static const introduction =
      'In some traditions, seven centres are described along the body. '
      'They are not measurements of anything. They are a way of pausing, '
      'one at a time.';

  /// What the app promises about anything written in a reflection.
  static const reflectionNote =
      'Anything you write stays on this device. It is kept while the '
      'Almanac is open and is not stored between visits.';

  static const root = Chakra(
    id: ChakraId.root,
    name: 'Root',
    sanskrit: 'Muladhara',
    hue: ChakraHue.red,
    place: 'the base of the body',
    associations: ['grounding', 'stability', 'belonging'],
    prompt: 'What helps you feel grounded today?',
    points: 4,
    position: 1,
  );

  static const sacral = Chakra(
    id: ChakraId.sacral,
    name: 'Sacral',
    sanskrit: 'Svadhisthana',
    hue: ChakraHue.orange,
    place: 'the lower belly',
    associations: ['creativity', 'feeling', 'flow'],
    prompt: 'What feels alive in you today?',
    points: 6,
    position: 2,
  );

  static const solarPlexus = Chakra(
    id: ChakraId.solarPlexus,
    name: 'Solar Plexus',
    sanskrit: 'Manipura',
    hue: ChakraHue.yellow,
    place: 'the upper belly',
    associations: ['personal agency', 'confidence', 'will'],
    prompt: 'Where could you trust yourself a little more?',
    points: 10,
    position: 3,
  );

  static const heart = Chakra(
    id: ChakraId.heart,
    name: 'Heart',
    sanskrit: 'Anahata',
    hue: ChakraHue.green,
    place: 'the centre of the chest',
    associations: ['compassion', 'connection', 'openness'],
    prompt: 'What deserves your tenderness today?',
    points: 12,
    position: 4,
  );

  static const throat = Chakra(
    id: ChakraId.throat,
    name: 'Throat',
    sanskrit: 'Vishuddha',
    hue: ChakraHue.blue,
    place: 'the throat',
    associations: ['expression', 'truth', 'communication'],
    prompt: 'What wants to be expressed?',
    points: 16,
    position: 5,
  );

  static const thirdEye = Chakra(
    id: ChakraId.thirdEye,
    name: 'Third Eye',
    sanskrit: 'Ajna',
    hue: ChakraHue.indigo,
    place: 'the brow',
    associations: ['insight', 'awareness', 'intuition'],
    prompt: 'What are you noticing beneath the surface?',
    points: 2,
    position: 6,
  );

  static const crown = Chakra(
    id: ChakraId.crown,
    name: 'Crown',
    sanskrit: 'Sahasrara',
    hue: ChakraHue.violet,
    place: 'the crown of the head',
    associations: ['contemplation', 'connection', 'transcendence'],
    prompt: 'What feels bigger than you today?',
    points: 24,
    position: 7,
  );

  /// In traditional order, from the base upwards.
  ///
  /// The overview walks this list backwards, because it is drawn on a
  /// body and the head is at the top of a body.
  static const all = <Chakra>[
    root,
    sacral,
    solarPlexus,
    heart,
    throat,
    thirdEye,
    crown,
  ];

  static Chakra byId(ChakraId id) => all.firstWhere((c) => c.id == id);
}
