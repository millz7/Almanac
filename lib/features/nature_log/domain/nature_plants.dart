import 'nature_item.dart';

/// Plants worth noticing rather than plants to grow — the Garden's plant
/// book is the other one. These are the trees and shrubs that mark the
/// year in New Zealand.
abstract final class NaturePlants {
  static const all = <NatureItem>[
    NatureItem(
      id: 'kowhai',
      primaryName: 'Kōwhai',
      category: NatureCategory.plant,
      form: NatureMarkForm.flower,
      scientificName: 'Sophora species',
      description:
          'Hanging yellow flowers on bare or thinly leafed '
          'branches. Tūī and korimako work them heavily.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.flowering,
          window: MonthWindow(8, 11),
          text: 'Often flowering through spring.',
        ),
      ],
    ),
    NatureItem(
      id: 'pohutukawa',
      primaryName: 'Pōhutukawa',
      category: NatureCategory.plant,
      form: NatureMarkForm.flower,
      scientificName: 'Metrosideros excelsa',
      description:
          'Coastal, wide-spreading, with crimson brush flowers. '
          'Naturally northern, and widely planted further south.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.flowering,
          window: MonthWindow(11, 1),
          text: 'Often flowering around midsummer.',
        ),
      ],
    ),
    NatureItem(
      id: 'manuka',
      primaryName: 'Mānuka',
      category: NatureCategory.plant,
      form: NatureMarkForm.flower,
      scientificName: 'Leptospermum scoparium',
      description:
          'Small white flowers and short prickly leaves. Often the '
          'first woody plant back on cleared ground.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.flowering,
          window: MonthWindow(9, 12),
          text: 'Often flowering from spring into early summer.',
        ),
      ],
    ),
    NatureItem(
      id: 'kanuka',
      primaryName: 'Kānuka',
      category: NatureCategory.plant,
      form: NatureMarkForm.leaf,
      scientificName: 'Kunzea species',
      description:
          'Taller than mānuka with softer leaves and smaller '
          'flowers in clusters. The bark peels in long strips.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.flowering,
          window: MonthWindow(11, 2),
          text: 'Often flowering a little after mānuka.',
        ),
      ],
    ),
    NatureItem(
      id: 'harakeke',
      primaryName: 'Harakeke',
      alternateName: 'Flax',
      category: NatureCategory.plant,
      form: NatureMarkForm.leaf,
      scientificName: 'Phormium tenax',
      description:
          'Long upright leaves in a fan, with tall dark flower '
          'stalks. Nectar birds work the flowers.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.flowering,
          window: MonthWindow(11, 1),
          text: 'Often flowering in early summer.',
        ),
      ],
    ),
    NatureItem(
      id: 'ti-kouka',
      primaryName: 'Tī kōuka',
      alternateName: 'Cabbage tree',
      category: NatureCategory.plant,
      form: NatureMarkForm.leaf,
      scientificName: 'Cordyline australis',
      description:
          'A bare trunk topped with a head of long narrow leaves, '
          'and heavy sprays of scented cream flowers.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.flowering,
          window: MonthWindow(10, 12),
          text: 'Often flowering heavily in late spring.',
        ),
      ],
    ),
    NatureItem(
      id: 'kawakawa',
      primaryName: 'Kawakawa',
      category: NatureCategory.plant,
      form: NatureMarkForm.leaf,
      scientificName: 'Piper excelsum',
      description:
          'Heart-shaped leaves, usually full of holes from the '
          'kawakawa looper caterpillar.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.fruiting,
          window: MonthWindow(1, 4),
          text: 'Often carrying orange fruiting spikes in late summer.',
        ),
      ],
    ),
    NatureItem(
      id: 'mahoe',
      primaryName: 'Māhoe',
      alternateName: 'Whiteywood',
      category: NatureCategory.plant,
      form: NatureMarkForm.leaf,
      scientificName: 'Melicytus ramiflorus',
      description:
          'Pale, blotched bark and toothed leaves. The small '
          'purple fruit sit tight against the branches.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.fruiting,
          window: MonthWindow(1, 4),
          text: 'Often fruiting along the branches in late summer.',
        ),
      ],
    ),
    NatureItem(
      id: 'rata',
      primaryName: 'Rātā',
      category: NatureCategory.plant,
      form: NatureMarkForm.flower,
      scientificName: 'Metrosideros species',
      description:
          'Related to pōhutukawa, and flowering inland and in '
          'forest rather than on the coast.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.flowering,
          window: MonthWindow(12, 2),
          text: 'Often flowering in high summer.',
        ),
      ],
    ),
    NatureItem(
      id: 'ponga',
      primaryName: 'Ponga',
      alternateName: 'Silver fern',
      category: NatureCategory.plant,
      form: NatureMarkForm.leaf,
      scientificName: 'Alsophila dealbata',
      description:
          'A tree fern with silver-white undersides to the fronds. '
          'New fronds uncurl as koru.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(9, 12),
          text: 'New fronds often uncurling through spring.',
        ),
      ],
    ),
    NatureItem(
      id: 'nikau',
      primaryName: 'Nīkau',
      category: NatureCategory.plant,
      form: NatureMarkForm.leaf,
      scientificName: 'Rhopalostylis sapida',
      description:
          'The southernmost palm in the world. A smooth green '
          'trunk with a bulge below the fronds.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.fruiting,
          window: MonthWindow(2, 6),
          text: 'Often carrying red fruit that kererū feed on.',
        ),
      ],
    ),
    NatureItem(
      id: 'karaka',
      primaryName: 'Karaka',
      category: NatureCategory.plant,
      form: NatureMarkForm.leaf,
      scientificName: 'Corynocarpus laevigatus',
      description:
          'Thick, glossy dark leaves and heavy orange fruit. Common '
          'near old coastal settlements.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.fruiting,
          window: MonthWindow(1, 4),
          text: 'Often fruiting in late summer.',
        ),
      ],
    ),
    NatureItem(
      id: 'clematis',
      primaryName: 'Puawānanga',
      alternateName: 'Native clematis',
      category: NatureCategory.plant,
      form: NatureMarkForm.flower,
      scientificName: 'Clematis paniculata',
      description:
          'A climber that carries sheets of white flowers high in '
          'the canopy, usually seen from below.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.flowering,
          window: MonthWindow(8, 10),
          text: 'Often flowering white through the canopy in early spring.',
        ),
      ],
    ),
    NatureItem(
      id: 'gorse',
      primaryName: 'Gorse',
      category: NatureCategory.plant,
      form: NatureMarkForm.flower,
      scientificName: 'Ulex europaeus',
      description:
          'Spiny and yellow-flowered on roadsides and rough '
          'ground. Introduced, and hard to miss.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.flowering,
          window: MonthWindow(7, 11),
          text: 'Often flowering strongly through late winter and spring.',
        ),
      ],
    ),
    NatureItem(
      id: 'blackberry-wild',
      primaryName: 'Blackberry',
      category: NatureCategory.plant,
      form: NatureMarkForm.leaf,
      scientificName: 'Rubus fruticosus',
      description:
          'Arching prickly canes along fence lines and tracks. '
          'Introduced, and widespread.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.fruiting,
          window: MonthWindow(1, 4),
          text: 'Often fruiting along tracks in late summer.',
        ),
      ],
    ),
  ];
}
