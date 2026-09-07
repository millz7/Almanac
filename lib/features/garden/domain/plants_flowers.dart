import 'gardening_region.dart';
import 'gardening_rule.dart';
import 'plant.dart';

/// The flower shelf. Mostly annuals sown where they are to grow, with a
/// couple of perennials that ask for pruning.
abstract final class FlowerPlants {
  static const all = <PlantDefinition>[
    PlantDefinition(
      id: 'sunflower',
      name: 'Sunflower',
      category: PlantCategory.flower,
      form: PlantForm.flower,
      lifecycle: Lifecycle.annual,
      description:
          'Fast, tall and cheerful. The seed heads feed birds long '
          'after the flower is over.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(10, 12),
          method: SowingMethod.outdoors,
          guidance: 'Sow direct where they are to flower.',
        ),
        GardeningRule.tend(
          window: MonthWindow(12, 2),
          tend: TendAction.support,
          requires: EstablishmentState.seedling,
          guidance: 'Stake the tall kinds before they lean.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'marigold',
      name: 'Marigold',
      category: PlantCategory.flower,
      form: PlantForm.flower,
      lifecycle: Lifecycle.annual,
      description:
          'Undemanding and long-flowering. Often planted among '
          'vegetables.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(9, 12),
          method: SowingMethod.either,
          guidance: 'Sow in trays or direct; they come up quickly.',
        ),
        GardeningRule.tend(
          window: MonthWindow(12, 3),
          tend: TendAction.deadhead,
          requires: EstablishmentState.seedling,
          guidance: 'Pinch off spent flowers to keep more coming.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'cosmos',
      name: 'Cosmos',
      category: PlantCategory.flower,
      form: PlantForm.flower,
      lifecycle: Lifecycle.annual,
      description:
          'Tall, airy and generous. Poor soil gives more flowers '
          'and less leaf.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(10, 12),
          method: SowingMethod.outdoors,
          guidance: 'Sow direct once the soil has warmed.',
        ),
        GardeningRule.tend(
          window: MonthWindow(1, 3),
          tend: TendAction.deadhead,
          requires: EstablishmentState.seedling,
          guidance: 'Cut spent stems back to a leaf joint.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'zinnia',
      name: 'Zinnia',
      category: PlantCategory.flower,
      form: PlantForm.flower,
      lifecycle: Lifecycle.annual,
      description:
          'Loves heat and cutting. Dislikes cold, wet feet and '
          'being transplanted late.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(9, 10),
          method: SowingMethod.underCover,
          guidance: 'Sow in pots to plant out after frosts.',
        ),
        GardeningRule.sow(
          window: MonthWindow(11, 12),
          method: SowingMethod.outdoors,
          guidance: 'Sow direct into warm soil.',
        ),
        GardeningRule.tend(
          window: MonthWindow(1, 3),
          tend: TendAction.deadhead,
          requires: EstablishmentState.seedling,
          guidance:
              'Cut flowers often; it is the best deadheading there '
              'is.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'sweet-pea',
      name: 'Sweet pea',
      category: PlantCategory.flower,
      form: PlantForm.climber,
      lifecycle: Lifecycle.annual,
      description:
          'Sown in autumn for the earliest, strongest plants. Pick '
          'hard or it stops.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(3, 5),
          method: SowingMethod.outdoors,
          guidance: 'An autumn sowing makes the sturdiest plants.',
        ),
        GardeningRule.sow(
          window: MonthWindow(8, 9),
          method: SowingMethod.either,
          guidance: 'A spring sowing catches up quickly.',
        ),
        GardeningRule.tend(
          window: MonthWindow(9, 11),
          tend: TendAction.support,
          requires: EstablishmentState.seedling,
          guidance: 'Give them netting or twigs to climb early.',
        ),
        GardeningRule.tend(
          window: MonthWindow(10, 1),
          tend: TendAction.deadhead,
          requires: EstablishmentState.seedling,
          guidance:
              'Pick every open flower; a single seed pod slows the '
              'whole plant.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'nasturtium',
      name: 'Nasturtium',
      category: PlantCategory.flower,
      form: PlantForm.climber,
      lifecycle: Lifecycle.annual,
      description:
          'Sprawls happily in poor soil, and the leaves and '
          'flowers are edible.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(9, 12),
          method: SowingMethod.outdoors,
          guidance: 'Push the big seeds straight into the ground.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(11, 4),
          minWeeksFromSowing: 8,
          guidance: 'Pick young leaves and flowers for salads.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'calendula',
      name: 'Calendula',
      category: PlantCategory.flower,
      form: PlantForm.flower,
      lifecycle: Lifecycle.annual,
      description:
          'Flowers for months and seeds itself about. Petals are '
          'edible.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(8, 3),
          method: SowingMethod.outdoors,
          guidance: 'Sow direct; it is not fussy.',
        ),
        GardeningRule.tend(
          window: MonthWindow(10, 4),
          tend: TendAction.deadhead,
          requires: EstablishmentState.seedling,
          guidance: 'Deadhead to keep it flowering, or let a few set seed.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'poppy',
      name: 'Poppy',
      category: PlantCategory.flower,
      form: PlantForm.flower,
      lifecycle: Lifecycle.annual,
      description:
          'Hates being moved, so sow it where you want it and thin '
          'rather than transplant.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(3, 5),
          method: SowingMethod.outdoors,
          guidance: 'Scatter thinly on raked soil and barely cover.',
        ),
        GardeningRule.sow(
          window: MonthWindow(8, 9),
          method: SowingMethod.outdoors,
          guidance: 'A spring sowing flowers a little later.',
        ),
        GardeningRule.tend(
          window: MonthWindow(5, 10),
          tend: TendAction.thin,
          requires: EstablishmentState.seedling,
          guidance: 'Thin the seedlings; crowded poppies stay small.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'lavender',
      name: 'Lavender',
      category: PlantCategory.flower,
      form: PlantForm.shrub,
      lifecycle: Lifecycle.perennial,
      description:
          'Wants sun, drought and drainage. Kept trimmed, it lasts '
          'for years; left alone, it goes woody.',
      rules: [
        GardeningRule.plant(
          window: MonthWindow(9, 11),
          guidance: 'Plant in full sun with sharp drainage.',
        ),
        GardeningRule.prune(
          window: MonthWindow(2, 3),
          guidance: 'Trim back by about a third once flowering is over.',
          caution:
              'Never cut into bare old wood — it will not reshoot. '
              'Always leave green growth below the cut.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'dahlia',
      name: 'Dahlia',
      category: PlantCategory.flower,
      form: PlantForm.flower,
      lifecycle: Lifecycle.perennial,
      description:
          'Grown from tubers, and the more you cut the more it '
          'flowers.',
      rules: [
        GardeningRule.plant(
          window: MonthWindow(9, 11),
          guidance: 'Plant tubers once the frosts have finished.',
        ),
        GardeningRule.tend(
          window: MonthWindow(12, 2),
          tend: TendAction.support,
          requires: EstablishmentState.seedling,
          guidance: 'Stake the taller kinds before the buds open.',
        ),
        GardeningRule.tend(
          window: MonthWindow(1, 4),
          tend: TendAction.deadhead,
          requires: EstablishmentState.seedling,
          guidance:
              'Cut spent flowers back to a bud; it keeps them going '
              'to the frost.',
        ),
        GardeningRule.tend(
          window: MonthWindow(5, 6),
          tend: TendAction.frostProtect,
          requires: EstablishmentState.established,
          regions: {
            GardeningRegion.nzSouthern,
            GardeningRegion.genericSouthern,
            GardeningRegion.genericNorthern,
          },
          guidance:
              'Once the tops have blackened, mulch deeply or lift the '
              'tubers for winter.',
        ),
      ],
    ),
  ];
}
