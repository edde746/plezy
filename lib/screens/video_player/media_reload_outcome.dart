/// Outcome of the player screen's in-place media reload.
enum MediaReloadOutcome {
  /// An entry guard refused the attempt (live screen, unmounted, another
  /// transition in flight). Nothing was touched; safe to retry later.
  rejected,

  /// A newer playback attempt took ownership mid-reload; its outcome
  /// governs what is on screen now.
  superseded,

  /// The replacement media opened and its session committed. A post-open
  /// step may still have failed (tracks/services were rewired in the
  /// catch), but the network stream is fresh.
  opened,

  /// The reload failed before the replacement opened: the previous session
  /// is still committed, the eagerly-set identity was rolled back, and the
  /// old (possibly dead — #1520) stream is still loaded.
  failed,
}
