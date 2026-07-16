package com.edde746.plezy.libass.media

import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.Format
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.MimeTypes.TEXT_SSA
import androidx.media3.common.Player.Listener
import androidx.media3.common.Tracks
import androidx.media3.common.VideoSize
import androidx.media3.common.util.Size
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.video.VideoFrameMetadataListener
import com.edde746.plezy.libass.Ass
import com.edde746.plezy.libass.AssRender
import com.edde746.plezy.libass.AssTrack
import com.edde746.plezy.libass.media.parser.AssHeaderParser
import com.edde746.plezy.libass.media.widget.AssAtlasPipelineConfig

/**
 * Handles ASS subtitle rendering and integration with ExoPlayer.
 *
 * This class listens to ExoPlayer events and manages the creation, selection, and rendering of ASS
 * subtitle tracks. Rendering always happens on a GL overlay surface (atlas pipeline) — the
 * libass frame is the overlay surface, not the video.
 */
@OptIn(UnstableApi::class)
class AssHandler(
  val config: AssHandlerConfig = AssHandlerConfig()
) : Listener {

  /** The ASS instance used for creating tracks and renderers. This is lazy to avoid loading
   * libass if the played media does not have ASS tracks. */
  private val assDelegate = lazy { Ass() }
  val ass by assDelegate

  /** The current ASS renderer. It's created as soon as a ASS track is detected. */
  var render: AssRender? = null
    private set

  /**
   * AssRender changed callback
   */
  var renderCallback: ((AssRender?) -> Unit)? = null

  /** The currently selected ASS track. */
  var track: AssTrack? = null
    private set

  /** The available ASS tracks in the current media. */
  private val availableTracks = mutableMapOf<String, AssTrack>()

  /** Fonts encountered before any ASS track was created. Flushed in [createTrack]. */
  private val pendingFonts = mutableListOf<Pair<String, ByteArray>>()

  /** The size of the video track. */
  var videoSize = Size.ZERO
    private set

  /** The size of the surface on which subtitles are rendered. */
  var surfaceSize = Size.ZERO
    private set

  /**
   * True once an overlay widget reported its surface size via [setOverlaySurfaceSize].
   * From then on the Player.Listener surface size (= the video output surface, which
   * may differ from the subtitle overlay once the overlay is parented elsewhere) is
   * ignored as a frame-size source.
   */
  private var overlaySizeFromWidget = false

  /** mpv-style margins of the video rect within the frame: top, bottom, left, right. */
  private var margins: IntArray? = null

  /** mpv's sub-ass-force-margins: anchor non-positioned events to the visible frame. */
  private var useMargins = false

  /**
   * Per-video-frame callback. Fired by ExoPlayer just before MediaCodec releases the frame
   * to the output surface. Carries the exact PTS of the frame and the System.nanoTime()
   * domain target release time, so subtitle renderers can align composition to the same
   * display vsync as the video.
   *
   * - [presentationTimeUs] is track-relative microseconds matching the subtitle track's PTS.
   * - [releaseTimeNs] may be [androidx.media3.common.C.TIME_UNSET] in rare paths.
   *
   * Invoked on the playback thread.
   */
  var videoFrameCallback: ((presentationTimeUs: Long, releaseTimeNs: Long) -> Unit)? = null

  private val videoFrameMetadataListener = VideoFrameMetadataListener { pts, releaseNs, _, _ ->
    videoFrameCallback?.invoke(pts, releaseNs)
  }

  private var player: ExoPlayer? = null

  /** The current selected ass format. */
  private var format: Format? = null

  /**
   * Initializes the handler with the provided ExoPlayer instance.
   * @param player The ExoPlayer instance to attach to.
   */
  fun init(player: ExoPlayer) {
    this.player = player
    player.addListener(this)
    player.setVideoFrameMetadataListener(videoFrameMetadataListener)
  }

  /**
   * Handles transitions between media items in the player and resets everything to the initial
   * state.
   */
  override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
    super.onMediaItemTransition(mediaItem, reason)
    Log.i("AssHandler", "onMediaItemTransition: item = $mediaItem, reason = $reason")
    resetMediaState(releaseNative = true)
  }

  private fun resetMediaState(releaseNative: Boolean) {
    val oldRender = render
    val oldTracks = availableTracks.values.toList()

    render = null
    track = null
    format = null
    availableTracks.clear()
    pendingFonts.clear()
    videoSize = Size.ZERO
    renderCallback?.invoke(null)

    if (releaseNative) {
      oldRender?.release()
      oldTracks.forEach { it.release() }
    }
  }

  /**
   * Handles changes to the tracks available in the current media.
   * Configures the selected ASS track if available.
   * @param tracks The selected tracks.
   */
  override fun onTracksChanged(tracks: Tracks) {
    Log.i("AssHandler", "onTracksChanged $tracks")

    val selectedVideoTrack = getSelectedVideoTrack(tracks)
    if (selectedVideoTrack != null) {
      setVideoSize(selectedVideoTrack.width, selectedVideoTrack.height)
    }

    format = getSelectedAssTrack(tracks)
    if (format == null) {
      Log.i("AssHandler", "subtitle track disabled")
      track = null
      render?.setTrack(null)
      return
    }

    updateTrack()
  }

  private fun updateTrack() {
    val track = availableTracks.firstNotNullOfOrNull {
      // When media without external subtitles, format id will not change.
      // When media with external subtitles, format will become like 1:1 .
      // So to compat both situation, we extract the actual id after the colon.
      if (format?.id?.substringAfter(":") == it.key) {
        it.value
      } else {
        null
      }
    }
    if (track == null || this.track == track) return

    Log.i("AssHandler", "subtitle track changed to $format")
    this.track = track
    val render = requireNotNull(render)
    applyRenderState(render)
    render.setTrack(track)
  }

  /**
   * (Re)applies sizing and margin state to [render]. Called whenever a render is
   * (re)created or the selected track changes, so renderer state survives both.
   */
  private fun applyRenderState(render: AssRender) {
    // Storage (script/video authoring size) stays full-res; only the frame and
    // margins follow RENDER_SCALE so the raster shrinks while layout is unchanged.
    if (videoSize.isValid) render.setStorageSize(videoSize.width, videoSize.height)
    when {
      surfaceSize.isValid -> render.setFrameSize(scaledForRender(surfaceSize.width), scaledForRender(surfaceSize.height))
      // Fallback frame until the overlay surface reports its size.
      videoSize.isValid -> render.setFrameSize(scaledForRender(videoSize.width), scaledForRender(videoSize.height))
    }
    margins?.let { m -> render.setMargins(scaledForRender(m[0]), scaledForRender(m[1]), scaledForRender(m[2]), scaledForRender(m[3])) }
    render.setUseMargins(useMargins)
  }

  /**
   * Handles changes to the surface size for video playback.
   * Notifies the callback if the size has changed.
   * @param width The new width of the surface.
   * @param height The new height of the surface.
   */
  override fun onSurfaceSizeChanged(width: Int, height: Int) {
    super.onSurfaceSizeChanged(width, height)
    Log.i("AssHandler", "onSurfaceSizeChanged: width = $width, height = $height")
    // The video output surface is only a frame-size proxy until an overlay widget
    // reports its own size — they diverge when the overlay isn't video-rect-sized.
    if (overlaySizeFromWidget) return
    if (surfaceSize.width == width && surfaceSize.height == height) return
    surfaceSize = Size(width, height)
  }

  /**
   * Reports the subtitle overlay widget's actual surface size — the authoritative
   * libass frame size for OVERLAY render types.
   */
  fun setOverlaySurfaceSize(width: Int, height: Int) {
    overlaySizeFromWidget = true
    if (surfaceSize.width == width && surfaceSize.height == height) return
    Log.i("AssHandler", "setOverlaySurfaceSize: width = $width, height = $height")
    surfaceSize = Size(width, height)
    render?.setFrameSize(scaledForRender(width), scaledForRender(height))
  }

  /**
   * Sets mpv-style frame margins: the offsets of the video dst rect within the libass
   * frame ([setOverlaySurfaceSize]); negative when the video extends beyond the frame.
   * Applied to the current render and re-applied whenever a render is (re)created.
   */
  fun setMargins(top: Int, bottom: Int, left: Int, right: Int) {
    margins = intArrayOf(top, bottom, left, right)
    render?.setMargins(scaledForRender(top), scaledForRender(bottom), scaledForRender(left), scaledForRender(right))
  }

  /** Frame/margin extents go to libass at the overlay's render resolution; the GL
   *  side scales the result back up. Identity unless RENDER_SCALE < 1. */
  private fun scaledForRender(px: Int): Int = AssAtlasPipelineConfig.scaledForRender(px)

  /** mpv's sub-ass-force-margins: anchor non-positioned events to the visible frame. */
  fun setUseMargins(use: Boolean) {
    useMargins = use
    render?.setUseMargins(use)
  }

  override fun onVideoSizeChanged(videoSize: VideoSize) {
    super.onVideoSizeChanged(videoSize)
    this.videoSize = Size(videoSize.width, videoSize.height)
    Log.i("AssHandler", "onVideoSizeChanged: width = ${videoSize.width}, height = ${videoSize.height}")
  }

  /**
   * Updates the video size for the ASS renderer. Called as soon as the video size is known in
   * order to properly render subtitles.
   * @param width The width of the video.
   * @param height The height of the video.
   */
  fun setVideoSize(width: Int, height: Int) {
    Log.i("AssHandler", "setVideoSize: width = $width, height = $height")
    videoSize = Size(width, height)
  }

  /**
   * Returns true if the current media has ASS tracks, false otherwise.
   */
  fun hasTracks(): Boolean = availableTracks.isNotEmpty()

  /**
   * Adds a font to the ASS library. If no tracks have been created yet, the font is buffered
   * and will be added when the first track is created via [createTrack].
   */
  @Synchronized
  fun addFont(name: String, data: ByteArray) {
    if (hasTracks()) {
      ass.addFont(name, data)
    } else {
      pendingFonts.add(name to data)
    }
  }

  /**
   * Creates a new ASS track from the given format and saves it in the [availableTracks].
   * The renderer and libass are also created if needed.
   * @param format The format of the ASS track.
   * @return The created ASS track.
   */
  @Synchronized
  fun createTrack(format: Format): AssTrack {
    Log.i("AssHandler", "createTrack: format = $format")
    // Ensure the renderer is created before creating tracks.
    createRenderIfNeeded()

    // Flush any fonts that were buffered before the first track was created.
    if (pendingFonts.isNotEmpty()) {
      for ((name, data) in pendingFonts) {
        ass.addFont(name, data)
      }
      pendingFonts.clear()
    }

    val track = ass.createTrack()
    if (format.initializationData.size > 0) {
      val header = AssHeaderParser.parse(format)
      track.readBuffer(header)
    }
    availableTracks[format.id!!] = track

    updateTrack()

    return track
  }

  /**
   * Ensures the ASS renderer is created if it does not already exist.
   */
  private fun createRenderIfNeeded() {
    if (render != null) return
    Log.i("AssHandler", "createRender (cacheSize: ${config.cacheSize}MB, glyphSize: ${config.glyphSize})")
    render = ass.createRender().also { render ->
      render.setCacheLimit(config.glyphSize, config.cacheSize)
      applyRenderState(render)
    }
    renderCallback?.invoke(render)
  }

  /**
   * Reads a dialogue into the track of the given [trackId].
   * Thread-safe: AssTrack.readChunk internally acquires the shared libass lock.
   */
  fun readTrackDialogue(
    trackId: String?,
    start: Long,
    duration: Long,
    data: ByteArray,
    offset: Int = 0,
    length: Int = data.size
  ) {
    val t = availableTracks[trackId] ?: return
    t.readChunk(start, duration, data, offset, length)
  }

  /**
   * Retrieves the selected video track, if any.
   */
  private fun getSelectedVideoTrack(tracks: Tracks): Format? = tracks.groups.find { group ->
    if (group.isSelected) {
      (0 until group.length).any { index ->
        val track = group.getTrackFormat(index)
        MimeTypes.isVideo(track.sampleMimeType)
      }
    } else {
      false
    }
  }?.getTrackFormat(0)

  /**
   * Retrieves the ID of the selected ASS track, if any.
   * @param tracks The selected tracks.
   * @return The ID of the selected ASS track, or null if none.
   */
  private fun getSelectedAssTrack(tracks: Tracks): Format? = tracks.groups.find { group ->
    if (group.isSelected) {
      (0 until group.length).any { index ->
        val track = group.getTrackFormat(index)
        track.sampleMimeType == TEXT_SSA || track.codecs == TEXT_SSA
      }
    } else {
      false
    }
  }?.getTrackFormat(0)

  /**
   * Releases all native resources held by this handler.
   */
  fun release() {
    videoFrameCallback = null
    player?.clearVideoFrameMetadataListener(videoFrameMetadataListener)
    player = null
    resetMediaState(releaseNative = true)
    if (assDelegate.isInitialized()) {
      ass.release()
    }
  }

  /**
   * Checks if the size is valid (both width and height are greater than 0).
   */
  private val Size.isValid
    get() = width > 0 && height > 0

  companion object {
    /**
     * Sets the global libass overlay render scale (fraction of the surface resolution; 1.0 = no
     * downscale). Cheaper raster for the render-bound tail on weak GPUs, at some sharpness. Set
     * before/at playback init — [AssAtlasPipelineConfig.scaledForRender] reads it on the next
     * frame-size apply (overlay surface create / size change), so it takes effect from playback.
     */
    fun setRenderScale(scale: Float) {
      AssAtlasPipelineConfig.renderScale = scale.coerceIn(0.2f, 1.0f)
    }
  }
}
