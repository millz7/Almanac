/// The eight festivals of the modern Pagan Wheel of the Year, in wheel
/// order — each the same distance around the circle from the last.
///
/// **Why this lives in `core/context/` rather than in the Wheel of the
/// Year feature.** The same shape as `CyclePhase`: several features now
/// speak about a festival — Wheel works out which one is current, and
/// the Cookbook, Meditation, Yoga, Garden and Nature Log each answer for
/// what they would offer around it. The vocabulary is shared and typed
/// so it cannot drift between them; the *meaning* each feature attaches
/// to a festival stays with that feature. Wheel owns the festival
/// content itself (`lib/features/wheel/domain/festival.dart`).
///
/// The order below is the order the wheel is drawn in and is the same
/// for both hemispheres — winter always gives way to the first stirrings
/// of spring, whichever hemisphere is experiencing it. Only the
/// calendar date attached to each one changes with hemisphere; see
/// `FestivalCalendar`.
enum FestivalId {
  yule('Yule'),
  imbolc('Imbolc'),
  ostara('Ostara'),
  beltane('Beltane'),
  litha('Litha'),
  lughnasadh('Lughnasadh'),
  mabon('Mabon'),
  samhain('Samhain');

  const FestivalId(this.label);

  /// The festival's name, e.g. "Beltane".
  final String label;

  /// The festival that follows this one around the wheel.
  FestivalId get next =>
      FestivalId.values[(index + 1) % FestivalId.values.length];

  /// Reads a festival back from storage, returning null for anything
  /// unrecognised.
  static FestivalId? tryParse(String stored) {
    for (final id in FestivalId.values) {
      if (id.name == stored) return id;
    }
    return null;
  }
}
