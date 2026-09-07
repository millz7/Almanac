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

  /// Somewhere the book has no guide for. Observations still work
  /// everywhere; only the suggestions are withheld.
  unsupported('No regional guide yet');

  const NatureCoverage(this.label);

  final String label;

  bool get isSupported => this == newZealand;
}

/// How the coverage was decided.
enum NatureCoverageSource {
  /// From a position the user shared.
  location,

  /// From the hemisphere they chose, with no position. A weaker signal,
  /// and the screens say so.
  hemisphere,
}

/// Which guide the Nature Log is using, and how it knows.
@immutable
class NatureGuide {
  const NatureGuide({required this.coverage, required this.source});

  final NatureCoverage coverage;
  final NatureCoverageSource source;

  bool get isSupported => coverage.isSupported;

  /// Whether the guide is being offered on the strength of a hemisphere
  /// rather than a position — which is worth saying out loud, because a
  /// New Zealand guide is a guess for anybody else in the south.
  bool get isUnconfirmed =>
      isSupported && source == NatureCoverageSource.hemisphere;

  /// The one place location becomes a guide.
  ///
  /// A shared position inside New Zealand gets the New Zealand guide;
  /// one outside it gets none, because the book has no content for
  /// there. With no position at all the hemisphere is the only signal
  /// available: the southern hemisphere is offered the New Zealand guide
  /// **marked as unconfirmed**, and the northern hemisphere is not
  /// offered it at all, since New Zealand species in a Vermont spring
  /// would be nonsense.
  ///
  /// Either way the user can record observations. Nothing here gates
  /// that.
  static NatureGuide resolve({
    required LocationState location,
    required Hemisphere hemisphere,
  }) {
    if (location.location case final position?) {
      return NatureGuide(
        coverage: _isInNewZealand(position)
            ? NatureCoverage.newZealand
            : NatureCoverage.unsupported,
        source: NatureCoverageSource.location,
      );
    }

    return NatureGuide(
      coverage: hemisphere == Hemisphere.southern
          ? NatureCoverage.newZealand
          : NatureCoverage.unsupported,
      source: NatureCoverageSource.hemisphere,
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
