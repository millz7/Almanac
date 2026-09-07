import 'nature_item.dart';

/// Birds most people in New Zealand can actually put a name to, or would
/// like to be able to.
///
/// Native and introduced together, without comment: a blackbird in the
/// garden is as real an observation as a tūī, and the book is for
/// noticing rather than for sorting anybody's garden into good and bad.
abstract final class NatureBirds {
  static const all = <NatureItem>[
    NatureItem(
      id: 'tui',
      primaryName: 'Tūī',
      category: NatureCategory.bird,
      form: NatureMarkForm.bird,
      scientificName: 'Prosthemadera novaeseelandiae',
      description:
          'Dark and iridescent, with a white tuft at the throat. '
          'Noisy in flight, and often heard before it is seen.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(8, 11),
          text: 'Often busy around flowering kōwhai in spring.',
        ),
        NatureNote(
          kind: NatureNoteKind.song,
          window: MonthWindow(8, 1),
          text:
              'Worth listening for: clicks and wheezes between the '
              'clearer notes.',
        ),
      ],
    ),
    NatureItem(
      id: 'kereru',
      primaryName: 'Kererū',
      alternateName: 'Wood pigeon',
      category: NatureCategory.bird,
      form: NatureMarkForm.bird,
      scientificName: 'Hemiphaga novaeseelandiae',
      description:
          'Large, heavy and unmistakable in flight. The wingbeat '
          'carries further than the bird looks like it should.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(2, 5),
          text: 'Often feeding in fruiting trees through autumn.',
        ),
      ],
    ),
    NatureItem(
      id: 'piwakawaka',
      primaryName: 'Pīwakawaka',
      alternateName: 'Fantail',
      category: NatureCategory.bird,
      form: NatureMarkForm.bird,
      scientificName: 'Rhipidura fuliginosa',
      description:
          'Small, restless, and given to following people about — '
          'it is after the insects you disturb.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(9, 3),
          text: 'Often about in gardens through the warmer months.',
        ),
      ],
    ),
    NatureItem(
      id: 'riroriro',
      primaryName: 'Riroriro',
      alternateName: 'Grey warbler',
      category: NatureCategory.bird,
      form: NatureMarkForm.bird,
      scientificName: 'Gerygone igata',
      description:
          'Tiny, grey and rarely still. The long trilling song is '
          'far easier to find than the bird.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.song,
          window: MonthWindow(7, 12),
          text: 'Worth listening for: a long rising and falling trill.',
        ),
      ],
    ),
    NatureItem(
      id: 'tauhou',
      primaryName: 'Tauhou',
      alternateName: 'Silvereye',
      category: NatureCategory.bird,
      form: NatureMarkForm.bird,
      scientificName: 'Zosterops lateralis',
      description:
          'Small and olive-green with a white ring around the eye. '
          'Usually in loose, chattering groups.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(5, 8),
          text: 'Often in larger groups around gardens in winter.',
        ),
      ],
    ),
    NatureItem(
      id: 'korimako',
      primaryName: 'Korimako',
      alternateName: 'Bellbird',
      category: NatureCategory.bird,
      form: NatureMarkForm.bird,
      scientificName: 'Anthornis melanura',
      description:
          'Olive-green and quick, with a clear ringing call. Often '
          'in the same flowering trees as tūī.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.song,
          window: MonthWindow(8, 12),
          text: 'Worth listening for at first light in spring.',
        ),
      ],
    ),
    NatureItem(
      id: 'pukeko',
      primaryName: 'Pūkeko',
      category: NatureCategory.bird,
      form: NatureMarkForm.bird,
      scientificName: 'Porphyrio melanotus',
      description:
          'Deep blue with a red bill and long legs. Common on wet '
          'paddocks and roadside margins.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(9, 12),
          text: 'Often seen with chicks in late spring.',
        ),
      ],
    ),
    NatureItem(
      id: 'kotare',
      primaryName: 'Kōtare',
      alternateName: 'Kingfisher',
      category: NatureCategory.bird,
      form: NatureMarkForm.bird,
      scientificName: 'Todiramphus sanctus',
      description:
          'Blue-green above, buff below, and usually perched very '
          'still on a wire or branch.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(3, 8),
          text: 'Often nearer the coast and estuaries over winter.',
        ),
      ],
    ),
    NatureItem(
      id: 'welcome-swallow',
      primaryName: 'Welcome swallow',
      alternateName: 'Warou',
      category: NatureCategory.bird,
      form: NatureMarkForm.bird,
      scientificName: 'Hirundo neoxena',
      description:
          'Fast and low over water and open ground, with a forked '
          'tail and a rusty throat.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(10, 2),
          text: 'Often hunting insects low over water on warm evenings.',
        ),
      ],
    ),
    NatureItem(
      id: 'blackbird',
      primaryName: 'Blackbird',
      category: NatureCategory.bird,
      form: NatureMarkForm.bird,
      scientificName: 'Turdus merula',
      description:
          'The male is black with an orange bill; the female is '
          'brown. A common and confident garden bird.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.song,
          window: MonthWindow(8, 12),
          text: 'Worth listening for from a high perch at dusk.',
        ),
      ],
    ),
    NatureItem(
      id: 'song-thrush',
      primaryName: 'Song thrush',
      category: NatureCategory.bird,
      form: NatureMarkForm.bird,
      scientificName: 'Turdus philomelos',
      description:
          'Brown above and spotted below. Often seen working over '
          'lawns and leaf litter.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.song,
          window: MonthWindow(8, 12),
          text: 'Worth listening for: short phrases, each repeated.',
        ),
      ],
    ),
    NatureItem(
      id: 'house-sparrow',
      primaryName: 'House sparrow',
      category: NatureCategory.bird,
      form: NatureMarkForm.bird,
      scientificName: 'Passer domesticus',
      description:
          'Small, brown and everywhere people are. Easy to overlook '
          'and worth a proper look.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(9, 1),
          text: 'Often carrying nesting material around buildings.',
        ),
      ],
    ),
    NatureItem(
      id: 'starling',
      primaryName: 'Starling',
      category: NatureCategory.bird,
      form: NatureMarkForm.bird,
      scientificName: 'Sturnus vulgaris',
      description:
          'Glossy and speckled, walking rather than hopping. Often '
          'in large evening flocks.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(3, 7),
          text: 'Often gathering in large flocks before dusk.',
        ),
      ],
    ),
    NatureItem(
      id: 'red-billed-gull',
      primaryName: 'Tarāpunga',
      alternateName: 'Red-billed gull',
      category: NatureCategory.bird,
      form: NatureMarkForm.bird,
      scientificName: 'Chroicocephalus scopulinus',
      description: 'The smaller coastal gull, with a red bill and legs.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(10, 2),
          text: 'Often noisy around coastal colonies in summer.',
        ),
      ],
    ),
    NatureItem(
      id: 'black-backed-gull',
      primaryName: 'Karoro',
      alternateName: 'Black-backed gull',
      category: NatureCategory.bird,
      form: NatureMarkForm.bird,
      scientificName: 'Larus dominicanus',
      description:
          'The large gull, black across the back and wings. Young '
          'birds are mottled brown for their first few years.',
      notes: [],
    ),
    NatureItem(
      id: 'paradise-shelduck',
      primaryName: 'Pūtangitangi',
      alternateName: 'Paradise shelduck',
      category: NatureCategory.bird,
      form: NatureMarkForm.bird,
      scientificName: 'Tadorna variegata',
      description:
          'Usually in pairs on open paddocks. The female has the '
          'white head.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(8, 12),
          text: 'Often in pairs on open ground through spring.',
        ),
      ],
    ),
  ];
}
