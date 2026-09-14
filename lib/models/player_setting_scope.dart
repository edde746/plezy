/// Where a player-sheet change (playback speed, shader preset, aspect ratio,
/// sync offsets) is persisted and re-applied from.
///
/// The scope governs writes: a change made during playback is stored at the
/// configured scope. Resolution at playback start consults only the configured
/// scope's entry for the current item, then falls back to the global pref, so
/// values saved under a previously configured scope become inert rather than
/// shadowing the current regime.
enum PlayerSettingScope {
  /// Never persist: the change applies for the session only.
  off,

  /// One value everywhere (the pre-existing behavior).
  global,

  /// One value per library (e.g. Anime4K for an anime library).
  library,

  /// One value per show or movie.
  title,
}
