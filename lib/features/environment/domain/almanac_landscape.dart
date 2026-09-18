import 'dart:ui';

/// **THE LANDSCAPE IS ONE PLACE. THE GEOMETRY STAYS FIXED; THE
/// ENVIRONMENT CHANGES.**
///
/// The Almanac looks out at a single lake, from a single spot on its
/// bank, all year round. In January and in July a viewer must be able to
/// point at the same hill. This file is that place, and it is the only
/// description of it in the app.
///
/// ## What is here, and what is deliberately not
///
/// Here: the shapes of the land and water. Mountains, hills, headlands,
/// islands, the shoreline, the horizon, the near bank, and the anchors
/// the sun and the foreground hang from.
///
/// Not here, and enforced by a test that greps this file: the words
/// `Season`, `Daylight`, `DayPhase`, `Color`, `Palette`. **Nothing in
/// this file knows what time of year it is or what colour anything is.**
/// That is what makes the rule provable rather than promised: there is no
/// parameter a future edit could branch a winter mountain on without
/// first importing something this file is not allowed to import.
///
/// Season and light live in `LandscapeAppearance`, which carries a
/// [LandscapeForm] rather than making one — so a test can take the form
/// out of all eight appearances and assert they are the same object.
///
/// ## Coordinates
///
/// Everything is **normalised to a unit square**: x and y run 0…1 across
/// the scene, y downwards. No pixel appears anywhere in this file, so the
/// same scene is the same shape on a small phone and on a tablet. See
/// [LandscapeForm.project] for how it reaches the canvas, and the
/// README/visual-language note on why the band keeps a fixed aspect
/// ratio rather than being stretched to whatever height is going.
abstract final class AlmanacLandscape {
  /// Where the water meets the sky. Everything above is air.
  static const horizon = 0.455;

  /// Where the near bank begins, and the water stops.
  static const nearBank = 0.780;

  /// The far mountain range, drawn as one filled silhouette.
  ///
  /// A polyline across the whole width, starting and ending at the
  /// horizon so the fill closes cleanly against the water.
  static const farRange = <Offset>[
    Offset(0.00, 0.455),
    Offset(0.05, 0.408),
    Offset(0.13, 0.356),
    Offset(0.19, 0.383),
    Offset(0.26, 0.330),
    Offset(0.33, 0.372),
    Offset(0.40, 0.345),
    Offset(0.47, 0.300),
    Offset(0.55, 0.352),
    Offset(0.62, 0.318),
    Offset(0.70, 0.365),
    Offset(0.78, 0.330),
    Offset(0.86, 0.379),
    Offset(0.93, 0.350),
    Offset(1.00, 0.398),
  ];

  /// The nearer range in front of it: lower, and offset so the peaks of
  /// the two never line up.
  static const nearRange = <Offset>[
    Offset(0.00, 0.455),
    Offset(0.08, 0.430),
    Offset(0.17, 0.397),
    Offset(0.24, 0.420),
    Offset(0.32, 0.392),
    Offset(0.41, 0.424),
    Offset(0.50, 0.404),
    Offset(0.58, 0.430),
    Offset(0.66, 0.398),
    Offset(0.74, 0.428),
    Offset(0.83, 0.405),
    Offset(0.91, 0.432),
    Offset(1.00, 0.418),
  ];

  /// The wooded shore on the left, running down to the water.
  static const leftHeadland = <Offset>[
    Offset(0.00, 0.455),
    Offset(0.07, 0.462),
    Offset(0.15, 0.474),
    Offset(0.23, 0.492),
    Offset(0.29, 0.520),
    Offset(0.31, 0.556),
    Offset(0.26, 0.574),
    Offset(0.16, 0.583),
    Offset(0.00, 0.588),
  ];

  /// And the answering shore on the right, which carries the lake's far
  /// arm out of frame.
  static const rightHeadland = <Offset>[
    Offset(1.00, 0.455),
    Offset(0.92, 0.466),
    Offset(0.83, 0.481),
    Offset(0.74, 0.497),
    Offset(0.68, 0.517),
    Offset(0.70, 0.545),
    Offset(0.78, 0.566),
    Offset(0.89, 0.578),
    Offset(1.00, 0.584),
  ];

  /// The right bank's lower spur, the piece of land the water curls
  /// around before the near bank takes over.
  static const rightSpur = <Offset>[
    Offset(1.00, 0.612),
    Offset(0.90, 0.622),
    Offset(0.80, 0.642),
    Offset(0.74, 0.668),
    Offset(0.77, 0.700),
    Offset(0.86, 0.722),
    Offset(1.00, 0.735),
  ];

  /// The islands, in the middle distance. Three, of three different
  /// sizes, because two would read as a pair and four as a pattern.
  static const islands = <List<Offset>>[
    [
      Offset(0.44, 0.556),
      Offset(0.48, 0.545),
      Offset(0.54, 0.543),
      Offset(0.59, 0.551),
      Offset(0.61, 0.562),
      Offset(0.55, 0.570),
      Offset(0.47, 0.568),
    ],
    [
      Offset(0.63, 0.534),
      Offset(0.66, 0.527),
      Offset(0.70, 0.530),
      Offset(0.71, 0.539),
      Offset(0.67, 0.544),
    ],
    [
      Offset(0.33, 0.522),
      Offset(0.36, 0.516),
      Offset(0.40, 0.519),
      Offset(0.41, 0.526),
      Offset(0.37, 0.530),
    ],
  ];

  /// The near bank the viewer is standing on: the bottom of the picture,
  /// and the ground every seasonal plant grows out of.
  static const bank = <Offset>[
    Offset(0.00, 0.812),
    Offset(0.14, 0.790),
    Offset(0.30, 0.783),
    Offset(0.48, 0.789),
    Offset(0.66, 0.781),
    Offset(0.82, 0.792),
    Offset(1.00, 0.780),
  ];

  /// The boulder on the bank — one fixed landmark at human scale, so the
  /// foreground is recognisably the same spot and not merely the same
  /// horizon.
  static const boulder = <Offset>[
    Offset(0.40, 0.876),
    Offset(0.425, 0.846),
    Offset(0.466, 0.834),
    Offset(0.512, 0.845),
    Offset(0.536, 0.872),
    Offset(0.530, 0.900),
    Offset(0.430, 0.902),
  ];

  /// Where each foreground plant stands, and how tall it is relative to
  /// the scene.
  ///
  /// Fixed: the *plants* change with the season, the *places they grow*
  /// do not. A summer that moved its flowers would be a different bank.
  ///
  /// `(x, groundY, height, lean)` — lean is a small horizontal drift at
  /// the tip, so a row of stems does not read as a fence.
  static const plantings = <(double, double, double, double)>[
    (0.035, 0.806, 0.250, -0.035),
    (0.085, 0.818, 0.180, 0.020),
    (0.140, 0.800, 0.215, -0.018),
    (0.205, 0.812, 0.150, 0.026),
    (0.265, 0.796, 0.196, -0.024),
    (0.320, 0.822, 0.132, 0.015),
    (0.600, 0.808, 0.142, -0.020),
    (0.655, 0.795, 0.205, 0.030),
    (0.720, 0.816, 0.160, -0.016),
    (0.790, 0.798, 0.232, 0.022),
    (0.865, 0.812, 0.178, -0.028),
    (0.940, 0.795, 0.262, 0.032),
  ];

  /// The overhanging branch in the top-left corner, which every reference
  /// has and which frames the view.
  ///
  /// `(x, y)` control points of the bough. What grows on it — blossom,
  /// leaves, bare twigs — is the season's business.
  static const bough = <Offset>[
    Offset(-0.02, 0.055),
    Offset(0.09, 0.090),
    Offset(0.17, 0.150),
    Offset(0.22, 0.232),
  ];

  /// The scene's one shared form. There is exactly one, and it takes no
  /// arguments.
  static const form = LandscapeForm._();
}

/// The fixed shape of the place, as a value.
///
/// Deliberately a value type with real equality: the geometry test takes
/// the form out of all eight appearances and asserts they are equal, so
/// a future `if (season == winter)` in the wrong place fails a test
/// rather than shipping.
///
/// It has no fields, because there is nothing about the form to vary —
/// which is the strongest statement of the rule the type system allows.
class LandscapeForm {
  const LandscapeForm._();

  /// Maps a normalised point onto a canvas of [size].
  ///
  /// A plain multiply, which is only correct because the band the scene
  /// is painted into keeps a fixed aspect ratio. See
  /// `AlmanacLandscapeView`.
  static Offset project(Offset point, Size size) =>
      Offset(point.dx * size.width, point.dy * size.height);

  /// A closed silhouette: the polyline, then down to [floor] and back.
  Path ridge(List<Offset> points, Size size, {double floor = 1.0}) {
    final path = Path()..moveTo(0, size.height * floor);
    for (final point in points) {
      final projected = project(point, size);
      path.lineTo(projected.dx, projected.dy);
    }
    return path
      ..lineTo(size.width, size.height * floor)
      ..close();
  }

  /// A closed shape through [points], smoothed so a coastline does not
  /// read as a polygon.
  ///
  /// Quadratic segments through the midpoints: cheap, deterministic, and
  /// enough to take the corners off. No randomness anywhere — the same
  /// bank is the same bank on every build, and a test can rely on it.
  Path smoothed(List<Offset> points, Size size, {bool close = true}) {
    final path = Path();
    if (points.isEmpty) return path;

    final projected = [for (final point in points) project(point, size)];
    path.moveTo(projected.first.dx, projected.first.dy);

    for (var i = 0; i < projected.length - 1; i++) {
      final current = projected[i];
      final next = projected[i + 1];
      path.quadraticBezierTo(
        current.dx,
        current.dy,
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
    }

    final last = projected.last;
    path.lineTo(last.dx, last.dy);
    if (close) path.close();
    return path;
  }

  /// The water: from the horizon down to the near bank, full width. The
  /// headlands and the bank are painted over it, which is what gives the
  /// lake its shape without a second outline to keep in step.
  Rect water(Size size) => Rect.fromLTRB(
    0,
    size.height * AlmanacLandscape.horizon,
    size.width,
    size.height * AlmanacLandscape.nearBank,
  );

  /// The sky, above the horizon.
  Rect sky(Size size) =>
      Rect.fromLTRB(0, 0, size.width, size.height * AlmanacLandscape.horizon);

  /// The near bank, closed to the bottom of the scene.
  Path bank(Size size) {
    final path = smoothed(AlmanacLandscape.bank, size, close: false);
    return path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool operator ==(Object other) => other is LandscapeForm;

  @override
  int get hashCode => (LandscapeForm).hashCode;

  @override
  String toString() => 'LandscapeForm(one place)';
}
