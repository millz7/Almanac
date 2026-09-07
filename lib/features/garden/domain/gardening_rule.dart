import 'package:flutter/foundation.dart';

import 'gardening_region.dart';

/// A run of calendar months, inclusive, which may wrap the new year.
///
/// `MonthWindow(9, 3)` is September to March — the shape most sowing
/// windows have in the southern hemisphere, and the reason this is a
/// type rather than a pair of ints.
@immutable
class MonthWindow {
  const MonthWindow(this.from, this.to)
    : assert(from >= 1 && from <= 12, 'from is a month'),
      assert(to >= 1 && to <= 12, 'to is a month');

  /// A single month.
  const MonthWindow.only(int month) : from = month, to = month;

  /// The whole year, for advice that is not seasonal.
  static const year = MonthWindow(1, 12);

  final int from;
  final int to;

  /// Whether the window runs through the new year.
  bool get wraps => to < from;

  /// How many months it covers.
  int get length => wraps ? (12 - from + 1) + to : to - from + 1;

  bool contains(int month) =>
      wraps ? month >= from || month <= to : month >= from && month <= to;

  /// The same window moved by [months], wrapping the year.
  MonthWindow shifted(int months) =>
      MonthWindow(_wrapMonth(from + months), _wrapMonth(to + months));

  /// The window as this region sees it.
  ///
  /// Every rule in the plant book is written for temperate New Zealand;
  /// each region says how far it sits from that baseline. See
  /// [GardeningRegion.monthOffset].
  MonthWindow forRegion(GardeningRegion region) =>
      region.monthOffset == 0 ? this : shifted(region.monthOffset);

  static int _wrapMonth(int month) => ((month - 1) % 12 + 12) % 12 + 1;

  @override
  bool operator ==(Object other) =>
      other is MonthWindow && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => from == to ? '$from' : '$from-$to';
}

/// The five things a gardener does that this feature knows about.
enum GardenAction {
  sow('Sow'),
  plant('Plant'),
  tend('Tend'),
  harvest('Harvest'),
  prune('Prune');

  const GardenAction(this.label);

  final String label;

  /// Whether the recommendation only makes sense for something the user
  /// actually grows.
  ///
  /// Sowing and planting are discovery — the whole plant book is open to
  /// browse. Tending, harvesting and pruning are about a real plant in a
  /// real garden, so they are drawn from My Garden and nothing else.
  bool get isPersonal => this == tend || this == harvest || this == prune;
}

/// Where a seed goes.
///
/// Kept distinct because the difference matters: in a cool spring the
/// same plant may be six weeks away outdoors and ready to start on a
/// windowsill.
enum SowingMethod {
  outdoors('Sow outdoors', 'outdoors'),
  underCover('Sow under cover', 'under cover'),
  either('Sow under cover or outdoors', 'under cover or outdoors');

  const SowingMethod(this.label, this.phrase);

  final String label;
  final String phrase;
}

/// The kinds of attention a plant can want.
///
/// Only the ones the initial dataset has dependable rules for. A short
/// trustworthy list beats a long vague one.
enum TendAction {
  support('Support'),
  thin('Thin'),
  mulch('Mulch'),
  feed('Feed'),
  deadhead('Deadhead'),
  divide('Divide'),
  frostProtect('Protect from frost');

  const TendAction(this.label);

  final String label;
}

/// How far along something in the garden is.
///
/// Recorded by the user, never inferred: the app cannot see the plant.
enum EstablishmentState {
  /// Sown, and not yet up.
  sown('Recently sown', 'Sown'),

  /// A seedling, or something planted out recently.
  seedling('Seedling or recently planted', 'Seedling'),

  /// Settled in, and has been for a while.
  established('Established', 'Established');

  const EstablishmentState(this.question, this.label);

  /// How the state is offered when adding a plant.
  final String question;

  /// How it is shown afterwards.
  final String label;

  /// Whether this state has reached at least [other].
  bool isAtLeast(EstablishmentState other) => index >= other.index;
}

/// One piece of gardening guidance: what to do, when, and where.
///
/// Structured on purpose. The window, the action, the method and the
/// state a plant has to have reached are all data, so the guide engine
/// can reason about them and the wording is assembled at the edge. The
/// only free text is [guidance] and [caution], which are the sentences a
/// gardener reads.
@immutable
class GardeningRule {
  const GardeningRule({
    required this.action,
    required this.window,
    required this.guidance,
    this.method,
    this.tend,
    this.regions = allGardeningRegions,
    this.requires,
    this.minWeeksFromSowing,
    this.caution,
    this.shiftsWithRegion = true,
  });

  /// Sowing always says where the seed goes, so the constructor makes
  /// [method] mandatory rather than leaving it to be forgotten.
  const GardeningRule.sow({
    required this.window,
    required this.method,
    required this.guidance,
    this.regions = allGardeningRegions,
    this.caution,
    this.shiftsWithRegion = true,
  }) : action = GardenAction.sow,
       tend = null,
       requires = null,
       minWeeksFromSowing = null;

  /// Planting or transplanting out.
  const GardeningRule.plant({
    required this.window,
    required this.guidance,
    this.regions = allGardeningRegions,
    this.requires,
    this.caution,
    this.shiftsWithRegion = true,
  }) : action = GardenAction.plant,
       method = null,
       tend = null,
       minWeeksFromSowing = null;

  /// Attention for something already growing, so it always names the
  /// kind of attention and the state the plant has to have reached.
  const GardeningRule.tend({
    required this.window,
    required TendAction this.tend,
    required this.guidance,
    required EstablishmentState this.requires,
    this.regions = allGardeningRegions,
    this.caution,
    this.shiftsWithRegion = true,
  }) : action = GardenAction.tend,
       method = null,
       minWeeksFromSowing = null;

  const GardeningRule.harvest({
    required this.window,
    required this.guidance,
    this.regions = allGardeningRegions,
    this.requires,
    this.minWeeksFromSowing,
    this.caution,
    this.shiftsWithRegion = true,
  }) : action = GardenAction.harvest,
       method = null,
       tend = null;

  /// Pruning carries a caution as a matter of course: the wrong month
  /// costs a season's flowers or fruit.
  const GardeningRule.prune({
    required this.window,
    required this.guidance,
    required String this.caution,
    this.regions = allGardeningRegions,
    this.requires = EstablishmentState.established,
    this.shiftsWithRegion = true,
  }) : action = GardenAction.prune,
       method = null,
       tend = null,
       minWeeksFromSowing = null;

  final GardenAction action;

  /// When, in temperate New Zealand months. Shifted per region unless
  /// [shiftsWithRegion] is false.
  final MonthWindow window;

  /// One short sentence. Written as something to consider, never as an
  /// instruction: see `garden_content_test.dart`.
  final String guidance;

  /// For sowing rules: under cover, outdoors, or either.
  final SowingMethod? method;

  /// For tending rules: which kind of attention.
  final TendAction? tend;

  /// Which regions this applies in at all.
  ///
  /// Not every plant is worth the trouble everywhere — kumara wants a
  /// long warm summer — and leaving a region out says so honestly
  /// instead of shifting a window into a season that will not deliver.
  final Set<GardeningRegion> regions;

  /// The state a plant must have reached for this to be relevant.
  ///
  /// Pruning an established shrub is one thing; pruning a seedling is
  /// another. Personalised rules use this so nothing is suggested for a
  /// plant that is not ready for it.
  final EstablishmentState? requires;

  /// A broad minimum age, in weeks from sowing.
  ///
  /// Applied **only when the user has recorded a sowing date**. The app
  /// cannot see the plant, so with no date this is simply not checked
  /// and the calendar window carries the recommendation on its own.
  /// These are broad — "not before about ten weeks" — never a claim
  /// about a particular plant's maturity.
  final int? minWeeksFromSowing;

  /// A qualification the gardener should read before acting. Pruning
  /// rules almost always have one.
  final String? caution;

  /// Whether the window moves with the region.
  ///
  /// False for advice anchored to the calendar rather than to the
  /// season: garlic goes in around the shortest day and comes out around
  /// the longest wherever in the country you are.
  final bool shiftsWithRegion;

  bool appliesIn(GardeningRegion region) => regions.contains(region);

  /// The window as [region] sees it.
  MonthWindow windowIn(GardeningRegion region) =>
      shiftsWithRegion ? window.forRegion(region) : window;

  bool isRelevantIn(GardeningRegion region, int month) =>
      appliesIn(region) && windowIn(region).contains(month);

  @override
  String toString() => 'GardeningRule(${action.name} $window)';
}

/// Every region, which is what most rules apply to.
const allGardeningRegions = {
  GardeningRegion.nzNorthern,
  GardeningRegion.nzCentral,
  GardeningRegion.nzSouthern,
  GardeningRegion.genericSouthern,
  GardeningRegion.genericNorthern,
};

/// Everywhere except the cooler south: for plants that want a longer,
/// warmer summer than the far south reliably gives.
const warmerRegions = {
  GardeningRegion.nzNorthern,
  GardeningRegion.nzCentral,
  GardeningRegion.genericSouthern,
  GardeningRegion.genericNorthern,
};

/// The warm north only, for subtropical fruit.
const subtropicalRegions = {GardeningRegion.nzNorthern};
