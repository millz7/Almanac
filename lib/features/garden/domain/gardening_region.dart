import 'package:flutter/foundation.dart';

import '../../../core/environment/geo_location.dart';

/// A broad gardening climate band.
///
/// **Why this exists.** A latitude and a longitude are not a gardening
/// recommendation. What a gardener needs is the band of climate they are
/// in — roughly when their frosts end, how long their summer is — and
/// that is a much coarser thing than a coordinate. Putting an explicit
/// region in the middle keeps the app honest: the guidance is written
/// against a band, not against a point on a map.
///
/// **The New Zealand bands.** The app is being built with New Zealand
/// use in mind, and the three bands below are the ones NZ gardening
/// references consistently use — the warm frost-light north, the
/// temperate middle, and the cooler south — separated by latitude
/// because latitude is the only thing coarse location can honestly tell
/// us. See [GardeningRegion.forLocation] for the boundaries and
/// `README.md` for the method.
///
/// **What is deliberately missing.** NZ guides often add an inland/cold
/// band for Central Otago and the high country. That band is defined by
/// *elevation and shelter*, not latitude: Alexandra and Dunedin sit at
/// the same latitude and garden a month apart. The app has coarse
/// location and no elevation, so inventing that band would be inventing
/// precision. It is left out, and the cool-south guidance is written
/// conservatively enough to be a reasonable starting point there.
///
/// **The generic guides** are for someone who has told the app their
/// hemisphere but not their location. They are broader still, and the
/// screens say so.
enum GardeningRegion {
  /// Northland, Auckland, Coromandel, Bay of Plenty. Frosts are light or
  /// absent near the coast; the season starts early and runs late.
  nzNorthern('Warm northern New Zealand', -1),

  /// Waikato, Taranaki, Hawke's Bay, Manawatu, Wellington, and the top
  /// of the South Island. The temperate middle, and the baseline every
  /// rule in the plant book is written against.
  nzCentral('Temperate New Zealand', 0),

  /// Most of the South Island. Later springs, earlier autumns.
  nzSouthern('Cooler southern New Zealand', 1),

  /// Somebody in the southern hemisphere who has not shared a location.
  genericSouthern('General Southern Hemisphere guide', 0),

  /// The same horticultural year, half a year across. See
  /// [monthOffset].
  genericNorthern('General Northern Hemisphere guide', 6);

  const GardeningRegion(this.label, this.monthOffset);

  /// How the region is named on screen.
  final String label;

  /// How many months this region's windows sit from the temperate New
  /// Zealand baseline every rule is written against.
  ///
  /// This is how NZ gardening advice is actually phrased — "a month
  /// earlier in the far north, a month later in the south" — and it
  /// keeps one set of windows rather than three sets that can drift
  /// apart.
  ///
  /// The northern hemisphere is the same horticultural year moved by six
  /// months: a temperate southern August is a temperate northern
  /// February. It is a broad equivalence, which is exactly what a guide
  /// labelled "general" should be, and rules anchored to the calendar
  /// rather than to the season opt out of shifting entirely (see
  /// `GardeningRule.shiftsWithRegion`).
  final int monthOffset;

  /// Whether this is a real place-based band or the broader
  /// hemisphere-wide guide.
  bool get isLocationBacked =>
      this != genericSouthern && this != genericNorthern;

  /// The band a position falls in.
  ///
  /// Inside New Zealand — the bounding box below — this returns one of
  /// the three NZ bands, split at 38°S and 42°S:
  ///
  /// * north of 38°S is the warm north (Northland through the Bay of
  ///   Plenty),
  /// * 38°S to 42°S is the temperate middle (Taranaki and Hawke's Bay
  ///   down through Wellington, and across to Nelson and Marlborough),
  /// * south of 42°S is the cooler south.
  ///
  /// Anywhere else on Earth, the app does not have a regional model yet,
  /// so it degrades honestly to the generic guide for that hemisphere
  /// rather than pretending New Zealand's calendar applies.
  static GardeningRegion forLocation(GeoLocation location) {
    if (!_isInNewZealand(location)) return forHemisphere(location.hemisphere);

    if (location.latitude > -38) return nzNorthern;
    if (location.latitude > -42) return nzCentral;
    return nzSouthern;
  }

  /// The guide for somebody who has shared a hemisphere and nothing
  /// more.
  static GardeningRegion forHemisphere(Hemisphere hemisphere) =>
      switch (hemisphere) {
        Hemisphere.southern => genericSouthern,
        Hemisphere.northern => genericNorthern,
      };

  /// A generous box around New Zealand, including the Chatham Islands to
  /// the east and Stewart Island to the south.
  ///
  /// Deliberately a box rather than a coastline: the app is deciding
  /// which broad guide to offer, not drawing a border, and a box cannot
  /// be wrong in a way that matters — the worst case is that somebody in
  /// the Tasman Sea gets New Zealand's calendar.
  static bool _isInNewZealand(GeoLocation location) =>
      location.latitude <= -34 &&
      location.latitude >= -47.5 &&
      location.longitude >= 166 &&
      location.longitude <= 179.5;
}

/// Which guide the Garden is using, and how sure it is.
///
/// Carried together so a screen can say "based on your general area" or
/// "location is off, so these suggestions are broader" from one value
/// instead of re-deriving it.
@immutable
class GardeningGuide {
  const GardeningGuide({required this.region, required this.source});

  final GardeningRegion region;
  final GuideSource source;

  /// Whether this came from a real position.
  bool get isLocationBacked => source == GuideSource.location;

  @override
  bool operator ==(Object other) =>
      other is GardeningGuide &&
      other.region == region &&
      other.source == source;

  @override
  int get hashCode => Object.hash(region, source);

  @override
  String toString() => 'GardeningGuide(${region.name} via ${source.name})';
}

/// Where the guide came from.
enum GuideSource {
  /// From coordinates the user shared. Still only a broad band.
  location,

  /// From the hemisphere the user chose. Broader again.
  hemisphere,
}
