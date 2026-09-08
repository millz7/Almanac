import 'package:flutter/foundation.dart';

import '../../../core/environment/geo_location.dart';
import '../../../core/environment/location_state.dart';

/// Whether the Nature Book has a guide for where somebody is.
///
/// **Why this is two states and not a set of regions.** Gardening bands
/// are about climate — frost dates and season length — and they shift a
/// planting window by a month. What lives where is a different question
/// entirely, and a much harder one: kererū are nationwide, pōhutukawa is
/// naturally northern, and the line between them is not a latitude. The
/// bundled content is the common ground — species most people anywhere
/// in New Zealand can meet — so the honest model is "the guide covers
/// this, or it does not". Inventing ecological subregions from coarse
/// location would be inventing precision, and reusing
/// `GardeningRegion` would be borrowing a concept that does not mean
/// what it needs to mean here.
enum NatureCoverage {
  /// The bundled New Zealand guide applies.
  newZealand('New Zealand guide'),

  /// Somewhere the book has no guide for — either a position outside its
  /// coverage, or no position at all. Observations still work
  /// everywhere; only the suggestions are withheld.
  unsupported('No regional guide yet');

  const NatureCoverage(this.label);

  final String label;

  bool get isSupported => this == newZealand;
}

/// How the coverage was decided.
///
/// There are only two ways, because there is only one signal that can
/// decide this: a position, or the absence of one.
enum NatureCoverageSource {
  /// A position the user shared was compared with the book's coverage.
  location,

  /// No position was resolved, so no regional guide could be chosen.
  /// Not a weaker guide — no guide.
  noLocation,
}

/// Which guide the Nature Log is using, and how it knows.
@immutable
class NatureGuide {
  const NatureGuide({required this.coverage, required this.source});

  final NatureCoverage coverage;
  final NatureCoverageSource source;

  bool get isSupported => coverage.isSupported;

  /// Whether the reason there is no guide is simply that the app does
  /// not know where the user is — worth saying out loud, because it is
  /// the one case they could change if they wanted to.
  ///
  /// The screens say it once, quietly. They do not ask for location.
  bool get isUnlocated => source == NatureCoverageSource.noLocation;

  /// The one place location becomes a guide.
  ///
  /// A shared position inside New Zealand gets the New Zealand guide;
  /// one outside it gets none, because the book has no content for
  /// there. **With no position, there is no guide** — and deliberately
  /// no hemisphere fallback.
  ///
  /// A hemisphere is enough to know the astronomical season: it is what
  /// the Environment, the Cookbook and the Garden use, and it is a fact
  /// about the sun. It is not enough to choose an ecological species
  /// guide. Somebody in Australia, Chile or South Africa can choose the
  /// southern hemisphere and decline location, and offering them New
  /// Zealand's birds would be claiming to know something the app has
  /// not been told. So the hemisphere is not a parameter here — not
  /// merely unused, but absent, so it cannot quietly become one again.
  ///
  /// Either way the user can record observations, and either way the
  /// whole Nature Book stays browsable. Nothing here gates that:
  /// reading a reference catalogue is a different act from being told
  /// its species are around you now.
  static NatureGuide resolve({required LocationState location}) {
    if (location.location case final position?) {
      return NatureGuide(
        coverage: _isInNewZealand(position)
            ? NatureCoverage.newZealand
            : NatureCoverage.unsupported,
        source: NatureCoverageSource.location,
      );
    }

    return const NatureGuide(
      coverage: NatureCoverage.unsupported,
      source: NatureCoverageSource.noLocation,
    );
  }

  /// A generous box around New Zealand, including the Chathams and
  /// Stewart Island.
  ///
  /// Deliberately a box rather than a coastline: this decides which
  /// broad guide to offer, not where a border is, and the worst case is
  /// that somebody at sea is offered New Zealand's birds.
  static bool _isInNewZealand(GeoLocation position) =>
      position.latitude <= -34 &&
      position.latitude >= -47.5 &&
      position.longitude >= 166 &&
      position.longitude <= 179.5;

  @override
  bool operator ==(Object other) =>
      other is NatureGuide &&
      other.coverage == coverage &&
      other.source == source;

  @override
  int get hashCode => Object.hash(coverage, source);

  @override
  String toString() => 'NatureGuide(${coverage.name} via ${source.name})';
}
