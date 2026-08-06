package com.edde746.plezy.exoplayer

/**
 * Decision logic for the buffering stall watchdog (#1790).
 *
 * A renderer that can never become ready pins ExoPlayer in `STATE_BUFFERING` with a full buffer
 * and a frozen clock. The reported case is an `AudioTrack` that fails to initialize: media3 logs a
 * sink error, keeps retrying, and — when its process-wide pending-release accounting has been
 * knocked out of balance — never converts the failure into a `PlaybackException`. Nothing else
 * notices. The frame watchdog wants `STATE_READY` and zero rendered frames, the decoder-hang check
 * is cancelled by the first frame, [ResumeStallPolicy] needs `isPlaying` and deliberately treats a
 * frozen clock as "not a decoder stall", [EndOfStreamPolicy] needs the position past the duration,
 * and media3's own stuck-buffering detector needs an *empty* buffer. So the user sits on a spinner
 * with no error and no way out.
 *
 * This watchdog covers exactly that hole: buffering, intending to play, holding data, and not
 * moving. A starved buffer is left alone — that is an ordinary network stall and the loader is the
 * right thing to wait for.
 */
internal object BufferingStallPolicy {

  /** Poll interval while buffering. */
  const val CHECK_INTERVAL_MS = 2_000L

  /**
   * How long a buffering player may hold enough data to start and still not move before it is
   * called stalled. Long enough to sit out a slow decoder handover or a track reselection, short
   * enough that a user has not yet given up and force-quit.
   *
   * Only time spent above [MIN_BUFFER_AHEAD_MS] counts: a rebuffer that takes a minute to refill
   * is the loader doing its job, and the clock restarts once it is done.
   */
  const val STALL_TIMEOUT_MS = 12_000L

  /** Position movement that counts as progress rather than clock jitter. */
  const val PROGRESS_EPSILON_MS = 250L

  /**
   * Media buffered ahead of the position before a motionless player is anomalous at all.
   *
   * A fallback bar, used only until media3 has answered for itself (see [evaluate]). It has to
   * clear `DefaultLoadControl`'s own play-start bar with room to spare, or the watchdog would
   * indict the player for obeying it: below [LoadControlPolicy.BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS]
   * the load control deliberately keeps playback in `STATE_BUFFERING`, and the two evaluate on
   * independent schedules.
   *
   * Measured in playout time, not media time, because `shouldStartPlayback` divides buffered media
   * duration by the playback speed: at 2x the same bar needs twice the media, and comparing raw
   * media duration would call a legitimately rebuffering fast-forward stalled.
   */
  const val MIN_BUFFER_AHEAD_MS = LoadControlPolicy.BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS + 2_000L

  enum class Verdict {
    /** The position moved; re-baseline and keep watching. */
    HEALTHY,

    /** Enough data to start, not moving, but not for long enough yet. */
    WAITING,

    /** Not moving because there is not yet enough to play. An ordinary rebuffer; not ours. */
    STARVED,

    /** Enough data to start, playback is wanted, and nothing has moved. */
    STALLED
  }

  /**
   * Every signal here can only ever *permit* an indictment; none of them vetoes one, because a
   * signal that can go stale would otherwise wedge this watchdog shut in exactly the failure it
   * exists to catch.
   *
   * [loadControlReady] is media3's own `shouldStartPlayback` verdict when it has given one, which is
   * the most faithful answer available — but it is only asked while the renderers report ready, and
   * a renderer that never becomes ready is that failure. A `false` recorded before the renderer got
   * stuck would never be revised, so it is treated as no answer rather than as a denial.
   *
   * [loading] false means the load control stopped asking for data, whether because its duration
   * thresholds are met or because its byte target is full. On a high bitrate stream that byte cap is
   * reached well below [MIN_BUFFER_AHEAD_MS] (see [LoadControlPolicy]), and without this signal a
   * genuinely stuck player there would look like an ordinary rebuffer forever. A network stall is
   * the opposite: the loader keeps wanting data it cannot get, so [loading] stays true and none of
   * the three signals fires.
   */
  fun evaluate(
    elapsedMs: Long,
    baselinePositionMs: Long,
    currentPositionMs: Long,
    bufferedPositionMs: Long,
    playbackSpeed: Float = 1f,
    loadControlReady: Boolean? = null,
    loading: Boolean = true
  ): Verdict {
    val speed = if (playbackSpeed > 0f) playbackSpeed else 1f
    val bufferedPlayoutMs = ((bufferedPositionMs - currentPositionMs) / speed).toLong()
    val readyToPlay = loadControlReady == true || !loading || bufferedPlayoutMs >= MIN_BUFFER_AHEAD_MS
    return when {
      currentPositionMs - baselinePositionMs >= PROGRESS_EPSILON_MS -> Verdict.HEALTHY
      !readyToPlay -> Verdict.STARVED
      elapsedMs < STALL_TIMEOUT_MS -> Verdict.WAITING
      else -> Verdict.STALLED
    }
  }

  /**
   * Whether [verdict] means the elapsed stall clock was measuring something the watchdog is not
   * responsible for, and must restart.
   *
   * Without this a long rebuffer accrues the whole timeout while starved, and the first poll after
   * the buffer refills reports a stall that never happened.
   */
  fun resetsStallClock(verdict: Verdict): Boolean = verdict == Verdict.HEALTHY || verdict == Verdict.STARVED
}
