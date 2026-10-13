package com.edde746.plezy.exoplayer

import androidx.annotation.OptIn
import androidx.media3.common.Timeline
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.LoadControl
import androidx.media3.exoplayer.analytics.PlayerId
import androidx.media3.exoplayer.source.MediaSource
import androidx.media3.exoplayer.source.TrackGroupArray
import androidx.media3.exoplayer.trackselection.ExoTrackSelection
import androidx.media3.exoplayer.upstream.Allocator

/**
 * A [LoadControl] that remembers whether it last said playback may start.
 *
 * The buffering stall watchdog ([BufferingStallPolicy]) needs to tell apart a player that is
 * buffering because the load control is holding it back — an ordinary rebuffer, not its business —
 * from one the load control has released that still refuses to move, which is the failure it exists
 * to catch.
 *
 * Re-deriving that condition cannot be done faithfully: `DefaultLoadControl.shouldStartPlayback`
 * releases playback on buffered *playout* duration (media duration divided by playback speed) or,
 * with `prioritizeTimeOverSizeThresholds` disabled, as soon as its byte target is full — which on a
 * high bitrate stream happens well below any duration bar, and depends on allocator accounting that
 * no public API exposes. So ask the object ExoPlayer asks, and record its answer.
 *
 * Note what this does *not* reach: `ExoPlayerImplInternal.shouldTransitionToReadyState` returns
 * early when the renderers are not ready, so it never asks at all in the case the watchdog was
 * written for — a renderer stuck forever. [BufferingStallPolicy] therefore also takes
 * `Player.isLoading`, which stays observable throughout.
 *
 * Every member is forwarded explicitly, and that is not a style choice: Kotlin's `by` delegation
 * only generates forwarders for *abstract* interface members, so a Java interface like this one —
 * where all but `getAllocator` carry default implementations that throw
 * `IllegalStateException("... not implemented")` — would inherit those throwing defaults and blow up
 * inside `ExoPlayer.Builder.build()`. [ObservingLoadControlTest] builds a real player through this
 * wrapper so a media3 upgrade that adds another such method fails a test rather than a device.
 */
@OptIn(UnstableApi::class)
class ObservingLoadControl(
  private val delegate: LoadControl,
  private val targetBufferBytes: Int = 0,
  private val onRebuffering: (() -> Unit)? = null
) : LoadControl {

  /**
   * The delegate's most recent verdict, or null if it has not been asked since [reset].
   *
   * ExoPlayer asks on every playback-loop iteration while buffering, so a reader running on the
   * watchdog's schedule sees a current answer; null only means "not yet asked".
   */
  @Volatile
  var startPlaybackVerdict: Boolean? = null
    private set

  /**
   * True while the loader is being held back after hitting [targetBufferBytes] until allocated
   * bytes drain to [LoadControlPolicy.byteCapResumeThresholdBytes].
   */
  @Volatile
  var holdingForByteCap: Boolean = false
    private set

  @Volatile
  private var wasRebuffering: Boolean = false

  @Volatile
  private var lastPlayerId: PlayerId? = null

  /** Forgets the recorded verdict, for a watchdog arming a fresh buffering window. */
  fun reset() {
    startPlaybackVerdict = null
    holdingForByteCap = false
    wasRebuffering = false
  }

  /** Current bytes allocated for the active player, or null when no player is prepared. */
  fun allocatedBytes(): Int? {
    val playerId = lastPlayerId ?: return null
    return try {
      delegate.getAllocator(playerId).totalBytesAllocated
    } catch (_: Exception) {
      null
    }
  }

  // The Parameters overloads are the ones ExoPlayer 1.10 calls; the older signatures are deprecated
  // shims that route through them.
  override fun shouldStartPlayback(parameters: LoadControl.Parameters): Boolean {
    lastPlayerId = parameters.playerId
    val verdict = delegate.shouldStartPlayback(parameters)
    startPlaybackVerdict = verdict
    return verdict
  }

  override fun shouldContinueLoading(parameters: LoadControl.Parameters): Boolean {
    lastPlayerId = parameters.playerId
    if (parameters.rebuffering) {
      holdingForByteCap = false
      if (!wasRebuffering) {
        wasRebuffering = true
        onRebuffering?.invoke()
      }
    } else {
      wasRebuffering = false
    }

    val delegateVerdict = delegate.shouldContinueLoading(parameters)
    if (targetBufferBytes <= 0) return delegateVerdict

    val allocatedBytes = try {
      delegate.getAllocator(parameters.playerId).totalBytesAllocated
    } catch (_: Exception) {
      return delegateVerdict
    }

    if (!delegateVerdict) {
      if (allocatedBytes >= targetBufferBytes) {
        holdingForByteCap = true
      }
      return false
    }

    if (holdingForByteCap) {
      val hold = LoadControlPolicy.shouldHoldBackForByteCap(
        targetBufferBytes = targetBufferBytes,
        allocatedBytes = allocatedBytes,
        bufferedDurationUs = parameters.bufferedDurationUs,
        playbackSpeed = parameters.playbackSpeed,
        rebuffering = parameters.rebuffering
      )
      if (hold) return false
      holdingForByteCap = false
    }

    return true
  }

  override fun shouldContinuePreloading(
    playerId: PlayerId,
    timeline: Timeline,
    mediaPeriodId: MediaSource.MediaPeriodId,
    bufferedDurationUs: Long
  ): Boolean = delegate.shouldContinuePreloading(playerId, timeline, mediaPeriodId, bufferedDurationUs)

  override fun onPrepared(playerId: PlayerId) {
    lastPlayerId = playerId
    holdingForByteCap = false
    wasRebuffering = false
    delegate.onPrepared(playerId)
  }

  override fun onTracksSelected(
    parameters: LoadControl.Parameters,
    trackGroups: TrackGroupArray,
    trackSelections: Array<out ExoTrackSelection>
  ) = delegate.onTracksSelected(parameters, trackGroups, trackSelections)

  override fun onStopped(playerId: PlayerId) {
    holdingForByteCap = false
    wasRebuffering = false
    delegate.onStopped(playerId)
  }

  override fun onReleased(playerId: PlayerId) {
    holdingForByteCap = false
    wasRebuffering = false
    if (lastPlayerId == playerId) lastPlayerId = null
    delegate.onReleased(playerId)
  }

  override fun getAllocator(playerId: PlayerId): Allocator = delegate.getAllocator(playerId)

  override fun getBackBufferDurationUs(playerId: PlayerId): Long = delegate.getBackBufferDurationUs(playerId)

  override fun retainBackBufferFromKeyframe(playerId: PlayerId): Boolean = delegate.retainBackBufferFromKeyframe(playerId)
}
