import 'tide.dart';

/// How close two extrema are allowed to be before they are treated as
/// the same real event rather than two separate ones.
///
/// A real semidiurnal tide's high and low are roughly six hours apart,
/// and two highs roughly twelve; three hours is comfortably below the
/// shortest real gap while still well above the one-hour sampling
/// interval, so only something that could not be a genuine turning
/// point gets merged away.
const kTideMinExtremaSeparation = Duration(hours: 3);

/// The smallest height change, in metres, worth calling a turning point.
///
/// Below this a "wiggle" in the modelled curve reads as numerical noise
/// rather than a real high or low — a real tide's range is very rarely
/// under half a metre, so five centimetres is a conservative floor.
const kTideMinProminenceMetres = 0.05;

/// How close "now" has to be to a known extreme before the tide reads as
/// [TideDirection.nearHigh] or [TideDirection.nearLow] rather than
/// plainly rising or falling.
///
/// Chosen so the label changes only in the genuinely flat stretch either
/// side of a turning point — not for the whole hour either side of it —
/// while still being wider than the one-hour sample spacing.
const kTideNearExtremeWindow = Duration(minutes: 45);

/// Finds every high and low in [samples].
///
/// **A local maximum where the trend turns rising → falling is a high; a
/// local minimum where it turns falling → rising is a low.** Only
/// interior samples can ever be a turning point — the first and last
/// sample of the fetched window are never reported as one, because there
/// is no data beyond the window to show whether the trend really
/// reversed there or the window simply ended mid-slope.
///
/// **Two passes clean up what a raw scan finds.** [minProminenceMetres]
/// discards a wiggle too small in height to be a real tide rather than
/// model noise, repeatedly merging away the smallest adjacent high/low
/// pair until every remaining one clears the threshold. [minSeparation]
/// then discards anything still too close in time to its neighbour to be
/// a second genuine event, keeping the more extreme of the two. Neither
/// pass invents a reading: both only ever remove or keep samples that
/// were already found in the raw scan.
List<TideExtreme> extractTideExtrema(
  List<TideSample> samples, {
  Duration minSeparation = kTideMinExtremaSeparation,
  double minProminenceMetres = kTideMinProminenceMetres,
}) {
  if (samples.length < 3) return const [];

  final raw = <TideExtreme>[];
  for (var i = 1; i < samples.length - 1; i++) {
    final previous = samples[i - 1].heightMetres;
    final current = samples[i].heightMetres;
    final next = samples[i + 1].heightMetres;
    if (current > previous && current >= next) {
      raw.add(
        TideExtreme(
          type: TideExtremeType.high,
          time: samples[i].time,
          heightMetres: current,
        ),
      );
    } else if (current < previous && current <= next) {
      raw.add(
        TideExtreme(
          type: TideExtremeType.low,
          time: samples[i].time,
          heightMetres: current,
        ),
      );
    }
  }
  if (raw.isEmpty) return const [];

  final pruned = _pruneByProminence(raw, minProminenceMetres);
  return _enforceSeparation(pruned, minSeparation);
}

/// Repeatedly merges away the smallest-amplitude adjacent high/low pair
/// until every remaining adjacent pair's height difference clears
/// [minProminence]. Merging a pair can leave the same kind of extreme on
/// both sides of the gap — a tiny false high sitting between two real
/// lows, say — in which case only the more extreme of the two survives,
/// since they were always one continuous low interrupted by noise.
List<TideExtreme> _pruneByProminence(
  List<TideExtreme> candidates,
  double minProminence,
) {
  final list = List<TideExtreme>.from(candidates);

  while (list.length > 1) {
    var smallestIndex = 0;
    var smallestAmplitude = double.infinity;
    for (var i = 0; i < list.length - 1; i++) {
      final amplitude = (list[i].heightMetres - list[i + 1].heightMetres).abs();
      if (amplitude < smallestAmplitude) {
        smallestAmplitude = amplitude;
        smallestIndex = i;
      }
    }
    if (smallestAmplitude >= minProminence) break;

    list.removeRange(smallestIndex, smallestIndex + 2);

    final left = smallestIndex - 1;
    final right = smallestIndex;
    if (left >= 0 &&
        right < list.length &&
        list[left].type == list[right].type) {
      final keepLeft = list[left].type == TideExtremeType.high
          ? list[left].heightMetres >= list[right].heightMetres
          : list[left].heightMetres <= list[right].heightMetres;
      list.removeAt(keepLeft ? right : left);
    }
  }

  return list;
}

/// Repeatedly merges away the closest-together adjacent pair of extrema
/// until every remaining adjacent pair is at least [minSeparation] apart,
/// keeping the more extreme of any pair that was too close.
List<TideExtreme> _enforceSeparation(
  List<TideExtreme> extrema,
  Duration minSeparation,
) {
  final list = List<TideExtreme>.from(extrema);

  while (list.length > 1) {
    var closestIndex = 0;
    var closestGap = list[1].time.difference(list[0].time);
    for (var i = 1; i < list.length - 1; i++) {
      final gap = list[i + 1].time.difference(list[i].time);
      if (gap < closestGap) {
        closestGap = gap;
        closestIndex = i;
      }
    }
    if (closestGap >= minSeparation) break;

    final a = list[closestIndex];
    final b = list[closestIndex + 1];
    // Same kind of extreme this close together: keep the more extreme
    // reading. A high and a low this close together should already have
    // been caught by the prominence pass above — reaching this case at
    // all means something stranger is going on in the data, so the
    // simplest honest answer is to trust the earlier reading and drop
    // the second.
    final keepA = a.type != b.type
        ? true
        : (a.type == TideExtremeType.high
              ? a.heightMetres >= b.heightMetres
              : a.heightMetres <= b.heightMetres);
    list.removeAt(closestIndex + (keepA ? 1 : 0));
  }

  return list;
}

/// Where the tide is heading at [instant].
///
/// **Near a known turning point, the direction is the turning point
/// itself** — [TideDirection.nearHigh] or [TideDirection.nearLow] —
/// rather than "rising" or "falling", which would overstate how much is
/// actually changing in the near-flat stretch around a genuine high or
/// low. "Near" means within [nearWindow] of an extreme's time; see
/// [kTideNearExtremeWindow].
///
/// **Away from a turning point, direction comes from the neighbouring
/// samples' slope** — the reading at or just before [instant] compared
/// with the one just after — never from which event is listed next,
/// which the extrema list alone cannot answer once the neighbouring
/// events have both been consumed.
TideDirection tideDirectionAt(
  List<TideSample> samples,
  DateTime instant, {
  List<TideExtreme>? extrema,
  Duration nearWindow = kTideNearExtremeWindow,
}) {
  if (samples.length < 2) return TideDirection.unknown;

  final resolvedExtrema = extrema ?? extractTideExtrema(samples);
  final at = instant.toUtc();

  TideExtreme? nearest;
  Duration? nearestGap;
  for (final extreme in resolvedExtrema) {
    final gap = extreme.time.toUtc().difference(at).abs();
    if (nearestGap == null || gap < nearestGap) {
      nearestGap = gap;
      nearest = extreme;
    }
  }
  if (nearest != null && nearestGap! <= nearWindow) {
    return nearest.type == TideExtremeType.high
        ? TideDirection.nearHigh
        : TideDirection.nearLow;
  }

  TideSample? before;
  TideSample? after;
  for (final sample in samples) {
    final time = sample.time.toUtc();
    if (!time.isAfter(at)) {
      before = sample;
    } else {
      after = sample;
      break;
    }
  }
  if (before == null || after == null) return TideDirection.unknown;
  if (after.heightMetres > before.heightMetres) return TideDirection.rising;
  if (after.heightMetres < before.heightMetres) return TideDirection.falling;
  return TideDirection.unknown;
}

/// The next [type] of extreme strictly after [instant], or null when
/// none is left in the fetched window.
TideExtreme? nextTideExtreme(
  List<TideExtreme> extrema,
  DateTime instant,
  TideExtremeType type,
) {
  final at = instant.toUtc();
  for (final extreme in extrema) {
    if (extreme.type == type && extreme.time.toUtc().isAfter(at)) {
      return extreme;
    }
  }
  return null;
}
