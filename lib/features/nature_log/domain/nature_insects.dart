import 'nature_item.dart';

/// Insects most people meet in a garden or on a walk.
abstract final class NatureInsects {
  static const all = <NatureItem>[
    NatureItem(
      id: 'bumblebee',
      primaryName: 'Bumblebee',
      category: NatureCategory.insect,
      form: NatureMarkForm.insect,
      scientificName: 'Bombus species',
      description:
          'Large, furry and loud. Out in cooler and duller weather '
          'than honey bees will fly in.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(9, 3),
          text: 'Often the first bee about on a cool spring morning.',
        ),
      ],
    ),
    NatureItem(
      id: 'honey-bee',
      primaryName: 'Honey bee',
      category: NatureCategory.insect,
      form: NatureMarkForm.insect,
      scientificName: 'Apis mellifera',
      description:
          'Smaller and slimmer than a bumblebee, and usually '
          'working a single kind of flower at a time.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(10, 3),
          text: 'Often busiest on warm still days in summer.',
        ),
      ],
    ),
    NatureItem(
      id: 'monarch',
      primaryName: 'Monarch butterfly',
      alternateName: 'Kākahu',
      category: NatureCategory.insect,
      form: NatureMarkForm.butterfly,
      scientificName: 'Danaus plexippus',
      description:
          'Large, orange and black, with a slow gliding flight. '
          'The caterpillars feed on swan plants.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(12, 4),
          text: 'Often about from midsummer into autumn.',
        ),
      ],
    ),
    NatureItem(
      id: 'red-admiral',
      primaryName: 'Kahukura',
      alternateName: 'Red admiral',
      category: NatureCategory.insect,
      form: NatureMarkForm.butterfly,
      scientificName: 'Vanessa gonerilla',
      description:
          'Black with red bands and white spots. The caterpillars '
          'feed on native nettle.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(11, 3),
          text: 'Often basking on tracks and warm ground in summer.',
        ),
      ],
    ),
    NatureItem(
      id: 'copper-butterfly',
      primaryName: 'Pepe para riki',
      alternateName: 'Common copper',
      category: NatureCategory.insect,
      form: NatureMarkForm.butterfly,
      scientificName: 'Lycaena species',
      description:
          'Small and coppery, usually low down near pōhuehue and '
          'other scrambling plants.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(11, 3),
          text: 'Often low over scrub and rough ground in summer.',
        ),
      ],
    ),
    NatureItem(
      id: 'cicada',
      primaryName: 'Kihikihi',
      alternateName: 'Cicada',
      category: NatureCategory.insect,
      form: NatureMarkForm.insect,
      scientificName: 'Amphipsalta and Kikihia species',
      description:
          'Heard far more often than seen. The empty nymph cases '
          'stay stuck to trunks and fences.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.song,
          window: MonthWindow(12, 3),
          text: 'Worth listening for on hot afternoons.',
        ),
      ],
    ),
    NatureItem(
      id: 'dragonfly',
      primaryName: 'Kapokapowai',
      alternateName: 'Dragonfly',
      category: NatureCategory.insect,
      form: NatureMarkForm.insect,
      scientificName: 'Odonata',
      description:
          'Fast and hovering, near still water. Damselflies are '
          'the finer ones that rest with wings folded.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(11, 3),
          text: 'Often hunting over ponds and slow water in summer.',
        ),
      ],
    ),
    NatureItem(
      id: 'praying-mantis',
      primaryName: 'Rō',
      alternateName: 'Praying mantis',
      category: NatureCategory.insect,
      form: NatureMarkForm.insect,
      scientificName: 'Orthodera novaezealandiae',
      description:
          'Green, angular and slow-moving, with a blue patch '
          'inside the front legs on the native one.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(1, 4),
          text: 'Often full-grown and easiest to spot in late summer.',
        ),
      ],
    ),
    NatureItem(
      id: 'ladybird',
      primaryName: 'Ladybird',
      category: NatureCategory.insect,
      form: NatureMarkForm.insect,
      scientificName: 'Coccinellidae',
      description:
          'Small and domed. Both the adults and the odd-looking '
          'larvae eat aphids.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(10, 3),
          text: 'Often on new growth where aphids have gathered.',
        ),
      ],
    ),
    NatureItem(
      id: 'weta',
      primaryName: 'Wētā',
      category: NatureCategory.insect,
      form: NatureMarkForm.insect,
      scientificName: 'Anostostomatidae',
      description:
          'Nocturnal, long-legged and armoured. Usually found by '
          'daylight tucked into a hole or under bark.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(11, 3),
          text: 'Often more active on warm nights.',
        ),
      ],
    ),
    NatureItem(
      id: 'huhu-beetle',
      primaryName: 'Huhu beetle',
      alternateName: 'Pepe-te-muimui',
      category: NatureCategory.insect,
      form: NatureMarkForm.insect,
      scientificName: 'Prionoplus reticularis',
      description:
          'A large brown longhorn beetle that flies clumsily into '
          'lit windows on summer evenings.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(11, 2),
          text: 'Often at lit windows on warm summer nights.',
        ),
      ],
    ),
  ];
}
