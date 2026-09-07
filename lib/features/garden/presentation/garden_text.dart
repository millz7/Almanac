import '../../../core/time/date_words.dart';
import '../domain/garden_guide.dart';

/// Everything the Garden says.
///
/// Gathered in one file like the Environment's and the Cookbook's
/// wording, and for a sharper reason here: this feature gives gardening
/// advice, and the line between a suggestion and an instruction is a
/// matter of phrasing. The app knows the month and a broad climate band.
/// It cannot see the soil, the frost pocket, the wind, or the plant. So
/// nothing here tells anybody what to do, and nothing claims a plant is
/// ready.
///
/// `garden_content_test.dart` reads every string in this file and every
/// line of the plant book.
abstract final class GardenText {
  static const title = 'Garden';

  /// The landing chapters.
  static const myGarden = 'My Garden';

  static const sowIntro = 'What you could sow';
  static const plantIntro = 'What you could plant out';
  static const tendIntro = 'What may want attention';
  static const harvestIntro = 'What may be ready';
  static const pruneIntro = 'What is often pruned around now';

  /// What each chapter is for, on the landing page.
  static String cardDescription(GardenAction action) => switch (action) {
    GardenAction.sow => 'Seeds worth considering this month.',
    GardenAction.plant => 'Seedlings and dormant plants to put out.',
    GardenAction.tend => 'Small jobs for the plants you have.',
    GardenAction.harvest => 'What in your garden may be ready.',
    GardenAction.prune => 'Cuts that are usually made around now.',
  };

  static const myGardenDescription = 'What you actually grow.';

  /// The honest limit of what the app knows, said on the landing page.
  static const precisionNote =
      'Based on your general area and the time of year. Local conditions '
      'can shift planting and harvest times.';

  /// Said when there is no location to work from.
  static const noLocationNote =
      'Location is off, so these suggestions are broader.';

  // Empty states.
  static const nothingToSow =
      'Nothing in the plant book has a sowing window for your current guide '
      'right now.';
  static const nothingToPlant =
      'Nothing in the plant book has a planting window for your current '
      'guide right now.';
  static const nothingToTend =
      'Nothing in your garden is asking for attention right now.';
  static const nothingToHarvest =
      'Nothing in your garden is showing a harvest window right now.';
  static const nothingToPrune =
      'Nothing in your garden is showing a pruning window right now.';
  static const gardenEmpty = 'Tell your Almanac what you\'re growing.';
  static const gardenEmptyNote =
      'Once it knows what you have, Tend, Harvest and Prune become yours '
      'rather than general advice.';
  static const seeThePlantBook = 'See the seasonal plant book';

  // My Garden.
  static const addExisting = 'Add something already growing';
  static const addToMyGarden = 'Add to My Garden';
  static const added = 'Added to My Garden.';
  static const inMyGarden = 'In My Garden';
  static const howIsItGrowing = 'How is it in your garden?';
  static const whenSown = 'When did you sow or plant it?';
  static const addSowingDate = 'Add a sowing date';
  static const addPlantingDate = 'Add a planting date';
  static const changeDate = 'Change the date';
  static const forgetDate = 'Forget the date';
  static const dateUnknown = 'No date recorded';
  static const back = 'Back';
  static const whatToKnow = 'What to know';
  static const relevantBecause = 'Relevant now because';

  // Removing.
  static const removeTitle = 'Remove from My Garden?';
  static const removeBody = 'This only removes it from your Almanac.';
  static const clearTitle = 'Clear My Garden?';
  static const clearBody =
      'Everything you have told the Almanac you grow will be removed from '
      'this device.';
  static const clearAll = 'Clear My Garden';
  static const remove = 'Remove';
  static const keep = 'Keep';
  static const saveFailed = 'That could not be saved on this device.';

  /// Where the garden lives. Said on the screen, not only in a report.
  static const privacyNote =
      'My Garden is kept on this device only. Nothing is sent anywhere.';

  /// "September · Temperate New Zealand" — the line under the title.
  static String context(GardeningGuide guide, int month) =>
      '${monthName(month)} · ${guide.region.label}';

  /// "Remove rosemary from My Garden?"
  static String removeQuestion(PlantDefinition plant) =>
      'Remove ${plant.name.toLowerCase()} from My Garden?';

  /// "Tomato. Established. In your garden." — a My Garden entry, spoken.
  static String entryLabel(PlantDefinition plant, GardenPlant entry) =>
      '${plant.name}. ${entry.state.label}. In your garden.';

  /// "Sown 12 September", or that the date is unknown.
  static String dateLine(GardenPlant entry) {
    if (entry.sownOn case final sown?) return 'Sown ${formatShortDate(sown)}';
    if (entry.plantedOn case final planted?) {
      return 'Planted ${formatShortDate(planted)}';
    }
    return dateUnknown;
  }

  /// A suggestion, spoken: "Tomato. Vegetable. May be ready to harvest."
  static String suggestionLabel(GardenSuggestion suggestion) =>
      [suggestion.plant.spokenName, actionPhrase(suggestion)].join(' ');

  /// How a suggestion is summarised in a list.
  ///
  /// Cautious by construction: a harvest "may be ready", a pruning is
  /// what is "typically" done, and the app never says a plant *is*
  /// anything.
  static String actionPhrase(GardenSuggestion suggestion) {
    final rule = suggestion.rule;
    return switch (rule.action) {
      GardenAction.sow => rule.method!.label,
      GardenAction.plant => 'Can be planted out now.',
      GardenAction.tend => '${rule.tend!.label}.',
      GardenAction.harvest => 'May be ready to harvest.',
      GardenAction.prune => 'Typically pruned around this time.',
    };
  }

  /// The heading for one action's section on a plant's page.
  static String sectionTitle(GardenAction action) => action.label;

  static String intro(GardenAction action) => switch (action) {
    GardenAction.sow => sowIntro,
    GardenAction.plant => plantIntro,
    GardenAction.tend => tendIntro,
    GardenAction.harvest => harvestIntro,
    GardenAction.prune => pruneIntro,
  };

  static String emptyFor(GardenAction action) => switch (action) {
    GardenAction.sow => nothingToSow,
    GardenAction.plant => nothingToPlant,
    GardenAction.tend => nothingToTend,
    GardenAction.harvest => nothingToHarvest,
    GardenAction.prune => nothingToPrune,
  };

  /// Everything fixed in this file, for the content test to read.
  static List<String> get everythingSaid => [
    title,
    myGarden,
    myGardenDescription,
    precisionNote,
    noLocationNote,
    nothingToSow,
    nothingToPlant,
    nothingToTend,
    nothingToHarvest,
    nothingToPrune,
    gardenEmpty,
    gardenEmptyNote,
    seeThePlantBook,
    addExisting,
    addToMyGarden,
    added,
    inMyGarden,
    howIsItGrowing,
    whenSown,
    addSowingDate,
    addPlantingDate,
    changeDate,
    forgetDate,
    dateUnknown,
    back,
    whatToKnow,
    relevantBecause,
    removeTitle,
    removeBody,
    clearTitle,
    clearBody,
    clearAll,
    remove,
    keep,
    saveFailed,
    privacyNote,
    for (final action in GardenAction.values) ...[
      action.label,
      cardDescription(action),
      intro(action),
      emptyFor(action),
    ],
    for (final region in GardeningRegion.values) region.label,
    for (final method in SowingMethod.values) method.label,
    for (final tend in TendAction.values) tend.label,
    for (final state in EstablishmentState.values) ...[
      state.label,
      state.question,
    ],
  ];
}
