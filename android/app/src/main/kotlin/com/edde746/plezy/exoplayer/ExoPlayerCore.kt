package com.edde746.plezy.exoplayer

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.SurfaceView
import android.view.TextureView
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.widget.FrameLayout
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.TrackGroup
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.Tracks
import androidx.media3.common.VideoSize
import androidx.media3.common.text.Cue
import androidx.media3.common.text.CueGroup
import androidx.media3.common.util.UnstableApi
import androidx.media3.common.util.Util
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.HttpDataSource
import androidx.media3.datasource.cronet.CronetDataSource
import androidx.media3.exoplayer.DecoderReuseEvaluation
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.RenderersFactory
import androidx.media3.exoplayer.analytics.AnalyticsListener
import androidx.media3.exoplayer.audio.AudioCapabilities
import androidx.media3.exoplayer.audio.AudioSink
import androidx.media3.exoplayer.mediacodec.MediaCodecSelector
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.source.ProgressiveMediaSource
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.extractor.DefaultExtractorsFactory
import androidx.media3.extractor.mkv.MatroskaExtractor
import androidx.media3.extractor.mp4.FragmentedMp4Extractor
import androidx.media3.extractor.mp4.Mp4Extractor
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.CaptionStyleCompat
import androidx.media3.ui.SubtitleView
import com.edde746.plezy.shared.AudioFocusManager
import com.edde746.plezy.shared.DeviceQuirks
import com.edde746.plezy.shared.FlutterOverlayHelper
import com.edde746.plezy.shared.FrameRateManager
import io.github.peerless2012.ass.media.AssHandler
import io.github.peerless2012.ass.media.parser.AssSubtitleParserFactory
import io.github.peerless2012.ass.media.type.AssRenderType
import io.github.peerless2012.ass.media.widget.AssSubtitleSurfaceView
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicLong
import org.chromium.net.CronetEngine

interface ExoPlayerDelegate : com.edde746.plezy.shared.PlayerDelegate {

  /**
   * Called when ExoPlayer encounters a format it cannot play.
   * The plugin should handle fallback to MPV.
   * @return true if fallback was handled, false to emit error event to Flutter
   */
  fun onFormatUnsupported(
    uri: String,
    headers: Map<String, String>?,
    positionMs: Long,
    errorMessage: String
  ): Boolean = false
}

@OptIn(UnstableApi::class)
class ExoPlayerCore(private val activity: Activity) : Player.Listener {

  companion object {
    private const val TAG = "ExoPlayerCore"

    private const val WATCHDOG_CHECK_INTERVAL_MS = 1000L
    private const val WATCHDOG_TIMEOUT_MS = 8000L
    private const val DECODER_HANG_TIMEOUT_MS = 5000L
    private const val FPS_SAMPLE_COUNT = 8

    // Codec capability caches — codec support doesn't change at runtime
    private val hwAudioDecoderCache = HashMap<String, Boolean>()
    private val tunneledPlaybackCache = HashMap<String, Boolean>()

    private var assGlCrashHandlerInstalled = false

    private var cronetEngine: CronetEngine? = null
    private fun getCronetEngine(context: Context): CronetEngine = cronetEngine ?: synchronized(this) {
      cronetEngine ?: CronetEngine.Builder(context.applicationContext)
        .enableHttp2(true)
        .enableQuic(true)
        .build()
        .also { cronetEngine = it }
    }
    private val cronetExecutor by lazy { Executors.newSingleThreadExecutor() }
  }

  private var surfaceView: SurfaceView? = null
  private var surfaceContainer: FrameLayout? = null
  private var videoAspectContainer: AspectRatioFrameLayout? = null
  private var subtitleView: SubtitleView? = null
  private var assHandler: AssHandler? = null
  private var overlayLayoutListener: ViewTreeObserver.OnGlobalLayoutListener? = null
  private var lastVideoSize: VideoSize? = null
  private var exoPlayer: ExoPlayer? = null
  private var renderersFactory: PlezyRenderersFactory? = null
  private val subtitleDelayUs = AtomicLong(0L)
  private var httpDataSourceFactory: HttpDataSource.Factory? = null
  private var dataSourceFactory: DefaultDataSource.Factory? = null
  private var trackSelector: DefaultTrackSelector? = null
  private var tunnelingUserEnabled: Boolean = true
  private var tunnelingDisabledForAudioCodec: Boolean = false
  private var tunnelingDisabledForVideoCodec: Boolean = false
  private var tunnelingDisabledForDecodedTrueHdPcm: Boolean = false
  private val tunnelingDisabledForCodec: Boolean
    get() = tunnelingDisabledForAudioCodec || tunnelingDisabledForVideoCodec || tunnelingDisabledForDecodedTrueHdPcm
  private var currentTunneledPlayback: Boolean = false
  private var lastSeekable: Boolean? = null

  @Volatile private var disposing: Boolean = false
  private var pendingStartPositionMs: Long = 0L
  private var pendingPlayWhenReady: Boolean? = null

  // Frame watchdog: detects black screen (audio plays but 0 video frames rendered)
  private var frameWatchdogRunnable: Runnable? = null
  private var frameWatchdogStartTime: Long = 0L

  // Decoder hang detection: tracks gap between decoder init and first rendered frame
  private var decoderHangRunnable: Runnable? = null
  private var decoderInitName: String? = null
  private var audioDecoderInitName: String? = null
  private var loggedEwasteEac3Workaround: Boolean = false
  private var lastTrueHdDirectOutputLogKey: String? = null
  private var loggedDecodedTrueHdTunnelingGuard: Boolean = false
  private var firstFrameRendered: Boolean = false
  var delegate: ExoPlayerDelegate? = null
  var debugLoggingEnabled: Boolean = false
  var isInitialized: Boolean = false
    private set

  // Frame rate matching
  private var frameRateManager: FrameRateManager? = null
  private val handler = Handler(Looper.getMainLooper())

  // FPS detection from frame timestamps (fallback when Format.frameRate is NO_VALUE)
  @Volatile private var detectedFrameRate: Float = -1f
  private val fpsTimestamps = LongArray(FPS_SAMPLE_COUNT)

  @Volatile private var fpsTimestampCount = 0

  // Audio focus
  private var audioFocusManager: AudioFocusManager? = null

  // Track state for event emission
  private var lastPosition: Long = 0

  /** Position to use for fallback: max of current position and pending start position. */
  private val effectivePosition: Long get() = maxOf(lastPosition, pendingStartPositionMs)
  private var lastDuration: Long = 0
  private var lastBufferedPosition: Long = 0
  private var positionUpdateRunnable: Runnable? = null

  // External subtitles added dynamically
  private val externalSubtitles = mutableListOf<MediaItem.SubtitleConfiguration>()
  private val externalSubtitleUris = mutableListOf<String>()
  private var currentMediaUri: String? = null
  private var currentHeaders: Map<String, String>? = null
  private var currentMediaIsLive: Boolean = false
  private var currentVisible: Boolean = false
  private var selectedAudioTrackId: String? = null
  private var selectedSubtitleTrackId: String? = null
  private val audioTrackGroupMap = mutableMapOf<String, TrackGroup>()
  private val subtitleTrackGroupMap = mutableMapOf<String, TrackGroup>()
  private var pendingDvTrackRestore: PendingTrackRestore? = null

  private data class PendingTrackRestore(
    val audio: TrackRestoreIdentity?,
    val subtitle: TrackRestoreIdentity?,
    val subtitleDisabled: Boolean
  )

  private data class TrackRestoreIdentity(
    val type: Int,
    val groupIndex: Int,
    val trackIndex: Int,
    val formatId: String?,
    val label: String?,
    val language: String?,
    val sampleMimeType: String?,
    val codecs: String?,
    val channelCount: Int,
    val sampleRate: Int,
    val selectionFlags: Int
  )

  private data class TrackRestoreMatch(
    val group: Tracks.Group,
    val trackGroup: TrackGroup,
    val trackIndex: Int,
    val format: Format,
    val score: Int
  )

  private fun emitLog(level: String, prefix: String, message: String) {
    when (level) {
      "error" -> Log.e(TAG, "[$prefix] $message")
      "warn" -> Log.w(TAG, "[$prefix] $message")
      "info" -> Log.i(TAG, "[$prefix] $message")
      else -> Log.d(TAG, "[$prefix] $message")
    }
    if (debugLoggingEnabled || level == "error" || level == "warn") {
      delegate?.onEvent(
        "log-message",
        mapOf(
          "prefix" to prefix,
          "level" to level,
          "text" to message
        )
      )
    }
  }

  private fun redactUri(uri: String): String {
    return try {
      val parsed = Uri.parse(uri)
      val params = parsed.queryParameterNames
      if (params.isEmpty()) return uri
      val builder = parsed.buildUpon().clearQuery()
      for (name in params) {
        val lower = name.lowercase()
        if (lower.contains("token") || lower.contains("key") || lower.contains("auth")) {
          builder.appendQueryParameter(name, "[REDACTED]")
        } else {
          builder.appendQueryParameter(name, parsed.getQueryParameter(name))
        }
      }
      builder.build().toString()
    } catch (_: Exception) {
      uri
    }
  }

  private fun ensureFlutterOverlayOnTop() {
    if (disposing) return
    val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
    contentView.post {
      if (disposing || !isInitialized) return@post
      val container = FlutterOverlayHelper.findFlutterContainer(contentView, surfaceContainer)
        ?: return@post
      // Fires on every layout pass via OnGlobalLayoutListener; skip when the
      // container is already at the front to avoid recursing the view tree
      // and re-writing compositionOrder each time.
      if (contentView.getChildAt(contentView.childCount - 1) === container) return@post
      FlutterOverlayHelper.configureFlutterZOrder(contentView, container, compositionOrder = 1)
    }
  }

  private fun configureSubtitleOverlaySurface() {
    subtitleView?.post {
      val count = subtitleView?.childCount ?: 0
      for (i in 0 until count) {
        val child = subtitleView?.getChildAt(i)
        if (child is SurfaceView) {
          child.setZOrderOnTop(false)
          child.setZOrderMediaOverlay(true)
          child.holder.setFormat(PixelFormat.TRANSLUCENT)
          FlutterOverlayHelper.applyCompositionOrder(child, -1)
        } else if (child is TextureView) {
          child.isOpaque = false
        }
      }
    }
  }

  // DV conversion state
  private var dvMode: DvConversionMode = DvConversionMode.DISABLED
  private var debugDvModeOverride: DvConversionMode? = null
  private var dv7RetryAttempted = false

  @Volatile private var activeDoviMkvWrapper: DoviExtractorWrapper? = null

  @Volatile private var activeDoviMp4Wrapper: DoviExtractorWrapper? = null

  private fun getConfiguredDvMode(): DvConversionMode = debugDvModeOverride ?: DoviBridge.getConversionMode()

  fun initialize(bufferSizeBytes: Int? = null, tunnelingEnabled: Boolean = true): Boolean {
    if (isInitialized) {
      Log.d(TAG, "Already initialized")
      return true
    }

    tunnelingUserEnabled = tunnelingEnabled
    this.dvMode = getConfiguredDvMode()
    Log.i(
      TAG,
      "DV conversion: mode=$dvMode, bridge=${DoviBridge.isAvailable()}, " +
        "deviceDV7=${DoviBridge.deviceSupportsDvProfile7}, deviceDV8=${DoviBridge.deviceSupportsDvProfile8}"
    )
    disposing = false

    try {
      audioFocusManager = AudioFocusManager(
        context = activity,
        handler = handler,
        onPause = { if (isInitialized) exoPlayer?.pause() },
        onResume = { if (isInitialized) exoPlayer?.play() },
        isPaused = { exoPlayer?.isPlaying != true },
        log = { emitLog("debug", "audio", it) }
      )
      frameRateManager = FrameRateManager(
        activity = activity,
        handler = handler,
        log = { emitLog("info", "framerate", it) }
      )

      // Create FrameLayout container for video (clips overflow for ZOOM crop mode)
      surfaceContainer = FrameLayout(activity).apply {
        layoutParams = ViewGroup.LayoutParams(
          ViewGroup.LayoutParams.MATCH_PARENT,
          ViewGroup.LayoutParams.MATCH_PARENT
        )
        setBackgroundColor(Color.BLACK)
        clipChildren = true
      }

      // AspectRatioFrameLayout drives FIT/ZOOM/FILL via Media3's resizeMode.
      // Centered inside the container; in ZOOM mode it measures larger than
      // the container and the parent's clipChildren crops the overflow.
      videoAspectContainer = AspectRatioFrameLayout(activity).apply {
        layoutParams = FrameLayout.LayoutParams(
          FrameLayout.LayoutParams.MATCH_PARENT,
          FrameLayout.LayoutParams.MATCH_PARENT
        ).apply {
          gravity = Gravity.CENTER
        }
        resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
      }

      // Create SurfaceView for video rendering (fills the ARFL)
      surfaceView = SurfaceView(activity).apply {
        layoutParams = FrameLayout.LayoutParams(
          FrameLayout.LayoutParams.MATCH_PARENT,
          FrameLayout.LayoutParams.MATCH_PARENT
        )
        holder.addCallback(surfaceCallback)
        setZOrderOnTop(false)
        setZOrderMediaOverlay(false)
        FlutterOverlayHelper.applyCompositionOrder(this, -2)
      }

      videoAspectContainer!!.addView(surfaceView)
      surfaceContainer!!.addView(videoAspectContainer)

      // Create SubtitleView - added to surfaceContainer above video
      // With OVERLAY_OPEN_GL mode, libass-android adds AssSubtitleTextureView as a child
      // which renders ASS subtitles with full styling using GPU texture composition
      subtitleView = SubtitleView(activity).apply {
        layoutParams = FrameLayout.LayoutParams(
          FrameLayout.LayoutParams.MATCH_PARENT,
          FrameLayout.LayoutParams.MATCH_PARENT
        )
      }
      // Add SubtitleView to surfaceContainer (above video SurfaceView)
      // Flutter renders on top of entire surfaceContainer, keeping subtitles below UI
      surfaceContainer!!.addView(subtitleView)
      Log.d(TAG, "SubtitleView created and added to surfaceContainer")

      val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
      contentView.addView(surfaceContainer, 0)

      // Find FlutterView and configure z-order. compositionOrder maps directly to
      // SurfaceView mSubLayer on API 36+: negative values are hole-punched behind
      // the parent canvas, non-negative are composited above. Media3's
      // CanvasSubtitleOutput renders SRT/VTT/SDH text on the parent canvas, so the
      // video and libass surfaces must be negative for non-ASS subs to be visible.
      // Stack (back → front): video (-2) → libass overlay (-1) → parent canvas
      // (CanvasSubtitleOutput) → Flutter UI (+1). Pre-36 falls back to legacy buckets.
      FlutterOverlayHelper.findFlutterContainer(contentView, surfaceContainer)?.let { container ->
        FlutterOverlayHelper.configureFlutterZOrder(contentView, container, compositionOrder = 1)
      }

      ensureFlutterOverlayOnTop()
      overlayLayoutListener = ViewTreeObserver.OnGlobalLayoutListener {
        ensureFlutterOverlayOnTop()
        // Recalculate surface size on layout change (orientation/PiP transitions)
        lastVideoSize?.let { vs ->
          if (vs.width > 0 && vs.height > 0) {
            updateSurfaceViewSize(vs.width, vs.height, vs.pixelWidthHeightRatio)
          }
        }
      }
      contentView.viewTreeObserver.addOnGlobalLayoutListener(overlayLayoutListener)

      Log.d(TAG, "SurfaceView added to content view")

      // Create track selector with text tracks enabled
      trackSelector = DefaultTrackSelector(activity).apply {
        setParameters(
          buildUponParameters()
            // Recover passthrough when HDMI capabilities flap (Shield refresh-rate / AVR link drop):
            // the sink temporarily falls back to PCM, and this flag lets the selector re-pick the
            // encoded audio track when capabilities come back. See androidx/media#2258.
            .setAllowInvalidateSelectionsOnRendererCapabilitiesChange(true)
            .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, false)
            .setPreferredTextLanguage("en")
        )
      }

      // Create ExoPlayer with FFmpeg audio decoder fallback
      val audioAttributes = buildMovieAudioAttributes()

      // Use DefaultRenderersFactory with FFmpeg fallback for unsupported or blocked audio codecs.
      val renderersFactory = PlezyRenderersFactory(activity).apply {
        audioDiagnosticsLogger = { level, prefix, message -> emitLog(level, prefix, message) }
        shouldBlockDirectTrueHd = { format -> this@ExoPlayerCore.shouldBlockDirectTrueHd(format, "sink support") }
        onAudioCapabilitiesChanged = { updateAudioDecoderPolicy("audio capabilities changed") }
        setEnableDecoderFallback(true)
        setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_ON)
        setMediaCodecSelector { mimeType, requiresSecureDecoder, requiresTunnelingDecoder ->
          if (shouldForceAppAudioDecoder(mimeType)) {
            emptyList()
          } else {
            MediaCodecSelector.DEFAULT.getDecoderInfos(
              mimeType,
              requiresSecureDecoder,
              requiresTunnelingDecoder
            )
          }
        }
      }
      this.renderersFactory = renderersFactory
      updateAudioDecoderPolicy("initialize")

      // Cronet DataSource for HTTP/2 multiplexing — all range requests share one connection
      httpDataSourceFactory = CronetDataSource.Factory(getCronetEngine(activity), cronetExecutor)
        .setConnectionTimeoutMs(15_000)
        .setReadTimeoutMs(10_000)
      dataSourceFactory = DefaultDataSource.Factory(activity, httpDataSourceFactory!!)
      val extractorsFactory = DefaultExtractorsFactory()

      // Inline buildWithAssSupport to retain AssHandler reference for font scale control.
      // OVERLAY_OPEN_GL uses TextureView which follows normal View hierarchy z-ordering,
      // preventing hardware overlay promotion issues on devices like Nvidia Shield.
      Log.d(TAG, "SubtitleView childCount before ASS setup: ${subtitleView?.childCount}")

      val renderType = AssRenderType.OVERLAY_OPEN_GL
      val handler = AssHandler(renderType)
      assHandler = handler

      val assParserFactory = AssSubtitleParserFactory(handler)

      // Wrap extractors: replace MatroskaExtractor with ASS+DV variant,
      // wrap MP4 extractors with DV converter when enabled.
      // Reads this.dvMode each time (not captured) so DV7→8.1 retry can
      // change mode and reload without reinitializing the player.
      val wrappedExtractorsFactory = androidx.media3.extractor.ExtractorsFactory {
        val currentDvMode = this.dvMode
        val doviEnabled = currentDvMode != DvConversionMode.DISABLED
        extractorsFactory.createExtractors().map { extractor ->
          when {
            extractor is MatroskaExtractor -> {
              val assExtractor = ZlibMatroskaExtractor(assParserFactory, handler)
              val inner = if (doviEnabled) {
                DoviExtractorWrapper(assExtractor, currentDvMode) { level, prefix, message ->
                  emitLog(level, prefix, message)
                }.also {
                  activeDoviMkvWrapper = it
                }
              } else {
                assExtractor
              }
              // Wrap with approximate seeking for MKV files without Cues
              CuelessSeekExtractorWrapper(inner)
            }
            doviEnabled && (extractor is Mp4Extractor || extractor is FragmentedMp4Extractor) -> {
              DoviExtractorWrapper(extractor, currentDvMode) { level, prefix, message ->
                emitLog(level, prefix, message)
              }.also {
                activeDoviMp4Wrapper = it
              }
            }
            else -> extractor
          }
        }.toTypedArray()
      }

      val mediaSourceFactory = DefaultMediaSourceFactory(dataSourceFactory!!, wrappedExtractorsFactory)
        .setSubtitleParserFactory(assParserFactory)

      // Wrap text renderers with subtitle delay support
      val wrappedRenderersFactory = RenderersFactory { eventHandler, videoListener, audioListener, textOutput, metadataOutput ->
        renderersFactory.createRenderers(eventHandler, videoListener, audioListener, textOutput, metadataOutput)
          .map { if (it.trackType == C.TRACK_TYPE_TEXT) SubtitleDelayRenderer(it, subtitleDelayUs) else it }
          .toTypedArray()
      }

      // Compute memory-aware buffer limits to prevent CCodec OOM crashes
      val activityManager = activity.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
      val memoryInfo = ActivityManager.MemoryInfo()
      activityManager.getMemoryInfo(memoryInfo)
      val availableMB = memoryInfo.availMem / (1024 * 1024)

      val targetBufferBytes = if (bufferSizeBytes != null && bufferSizeBytes > 0) {
        bufferSizeBytes
      } else {
        // Scale buffer to available memory to reduce hardware decoder pressure.
        // Larger buffers reduce oscillation frequency at high bitrates (50-100Mbps).
        when {
          availableMB <= 512 -> 30 * 1024 * 1024
          availableMB <= 1024 -> 80 * 1024 * 1024
          availableMB <= 2048 -> 120 * 1024 * 1024
          else -> 200 * 1024 * 1024
        }
      }

      val loadControl = DefaultLoadControl.Builder().apply {
        setTargetBufferBytes(targetBufferBytes)
        setPrioritizeTimeOverSizeThresholds(false)
        if (availableMB <= 2048) {
          setBufferDurationsMs(15_000, 50_000, 1_000, 5_000)
        } else {
          setBufferDurationsMs(30_000, 60_000, 1_000, 5_000)
        }
      }.build()
      emitLog("info", "init", "Buffer: ${targetBufferBytes / 1024 / 1024}MB limit, available=${availableMB}MB, tunneling=$tunnelingUserEnabled, dataSource=Cronet")

      exoPlayer = ExoPlayer.Builder(activity)
        .setTrackSelector(trackSelector!!)
        .setLoadControl(loadControl)
        .setAudioAttributes(audioAttributes, false) // We handle audio focus manually
        .setMediaSourceFactory(mediaSourceFactory)
        .setRenderersFactory(wrappedRenderersFactory)
        .build()

      // Add ASS overlay view to SubtitleView for OVERLAY modes.
      // We use AssSubtitleSurfaceView directly (not AssSubtitleView) so we get a
      // SurfaceFlinger-layer-backed overlay that eglPresentationTimeANDROID can
      // vsync-pin. Z-order: video SurfaceView (-2) < this MediaOverlay-flagged
      // SurfaceView (-1) < parent canvas < Flutter SurfaceView (+1) in the window.
      //
      // Inserted at child index 0 so the SurfaceView's transparent punch runs BEFORE
      // SubtitleView's built-in CanvasSubtitleOutput child renders non-ASS cues.
      // Appending would punch away already-drawn SRT/VTT text.
      var assSubtitleSurfaceView: AssSubtitleSurfaceView? = null
      subtitleView?.let { sv ->
        val assView = AssSubtitleSurfaceView(sv.context, handler)
        assSubtitleSurfaceView = assView
        sv.addView(
          assView,
          0,
          FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
          )
        )
      }

      // Initialize handler (registers as Player.Listener, creates Handler).
      // AssHandler.init calls player.setVideoFrameMetadataListener internally, but
      // our own setVideoFrameMetadataListener below would overwrite it (ExoPlayer
      // only keeps one listener). Skip AssHandler's wiring and invoke
      // assView.requestRender directly from the listener below.
      handler.init(exoPlayer!!)

      // Suppress ass-media GL thread crash when EGL init partially fails (e.g. Tegra).
      // AssRender.onSurfaceDestroyed() accesses uninitialized glProgram lateinit property
      // during error cleanup, which is a bug in the library. The render thread dying only
      // affects ASS subtitle GPU rendering; non-ASS subtitles are unaffected.
      if (!assGlCrashHandlerInstalled) {
        assGlCrashHandlerInstalled = true
        val previousHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
          if (thread.name.contains("AssTexRenderThread") &&
            throwable is UninitializedPropertyAccessException
          ) {
            Log.e(TAG, "ASS GL thread crash suppressed (EGL init failure)", throwable)
          } else {
            previousHandler?.uncaughtException(thread, throwable)
          }
        }
      }

      exoPlayer!!.addListener(this)
      exoPlayer!!.addAnalyticsListener(decoderHangListener)
      exoPlayer!!.setVideoFrameMetadataListener { presentationTimeUs, releaseTimeNs, _, _ ->
        // ASS bypasses Media3's text renderer, so apply sub-delay before libass renders.
        assSubtitleSurfaceView?.requestRender(presentationTimeUs - subtitleDelayUs.get(), releaseTimeNs)
        val count = fpsTimestampCount
        if (count < FPS_SAMPLE_COUNT) {
          fpsTimestamps[count] = presentationTimeUs
          fpsTimestampCount = count + 1
          if (count + 1 == FPS_SAMPLE_COUNT) {
            detectedFrameRate = computeFrameRate(fpsTimestamps)
            Log.d(TAG, "Detected frame rate: $detectedFrameRate fps")
          }
        }
      }
      surfaceView?.let { exoPlayer!!.setVideoSurfaceView(it) }

      Log.d(TAG, "SubtitleView childCount after ASS setup: ${subtitleView?.childCount}")
      configureSubtitleOverlaySurface()

      // Debug: Log SubtitleView child hierarchy
      subtitleView?.post {
        Log.d(TAG, "SubtitleView post-layout: width=${subtitleView?.width}, height=${subtitleView?.height}, childCount=${subtitleView?.childCount}")
        for (i in 0 until (subtitleView?.childCount ?: 0)) {
          val child = subtitleView?.getChildAt(i)
          Log.d(TAG, "  Child $i: ${child?.javaClass?.simpleName}, w=${child?.width}, h=${child?.height}, visibility=${child?.visibility}")
        }
      }

      // Start position update loop
      startPositionUpdates()

      isInitialized = true
      Log.d(TAG, "Initialized successfully")
      return true
    } catch (e: Exception) {
      Log.e(TAG, "Failed to initialize: ${e.message}", e)
      return false
    }
  }

  private val surfaceCallback = object : android.view.SurfaceHolder.Callback {
    override fun surfaceCreated(holder: android.view.SurfaceHolder) {
      if (disposing) return
      emitLog("debug", "surface", "Created")
      ensureFlutterOverlayOnTop()
    }

    override fun surfaceChanged(holder: android.view.SurfaceHolder, format: Int, width: Int, height: Int) {
      emitLog("debug", "surface", "Changed: ${width}x$height")
    }

    override fun surfaceDestroyed(holder: android.view.SurfaceHolder) {
      emitLog("debug", "surface", "Destroyed")
    }
  }

  private fun startPositionUpdates() {
    positionUpdateRunnable = object : Runnable {
      override fun run() {
        if (isInitialized && exoPlayer != null) {
          val player = exoPlayer!!
          val currentPosition = player.currentPosition
          val duration = player.duration
          val bufferedPosition = player.bufferedPosition

          // Emit position changes (every 250ms update)
          if (currentPosition != lastPosition) {
            lastPosition = currentPosition
            delegate?.onPropertyChange("time-pos", currentPosition / 1000.0)
          }

          // Emit duration changes
          if (duration != lastDuration && duration != C.TIME_UNSET) {
            lastDuration = duration
            delegate?.onPropertyChange("duration", duration / 1000.0)
          }

          // Emit buffer changes
          if (bufferedPosition != lastBufferedPosition && bufferedPosition != C.TIME_UNSET) {
            lastBufferedPosition = bufferedPosition
            delegate?.onPropertyChange("demuxer-cache-time", bufferedPosition / 1000.0)
          }

          handler.postDelayed(this, 250)
        }
      }
    }
    handler.post(positionUpdateRunnable!!)
  }

  private fun stopPositionUpdates() {
    positionUpdateRunnable?.let { handler.removeCallbacks(it) }
    positionUpdateRunnable = null
  }

  private fun resetPlaybackProgress(startPositionMs: Long) {
    lastPosition = startPositionMs
    lastDuration = 0L
    lastBufferedPosition = 0L
    delegate?.onPropertyChange("time-pos", startPositionMs / 1000.0)
    delegate?.onPropertyChange("duration", 0.0)
    delegate?.onPropertyChange("demuxer-cache-time", 0.0)
    delegate?.onPropertyChange("eof-reached", false)
  }

  private fun emitSeekable(seekable: Boolean, force: Boolean = false) {
    if (!force && lastSeekable == seekable) return
    lastSeekable = seekable
    delegate?.onPropertyChange("seekable", seekable)
  }

  private fun emitCurrentSeekable(force: Boolean = false) {
    val player = exoPlayer
    val seekable = player?.isCurrentMediaItemSeekable == true && !currentMediaIsLive
    emitSeekable(seekable, force)
  }

  // Player.Listener

  override fun onCues(cueGroup: CueGroup) {
    // With OVERLAY_CANVAS mode, ASS subtitles are rendered directly by AssSubtitleView
    // This callback is for non-ASS subtitles (SRT, VTT, etc.)
    val incoming = cueGroup.cues
    val outgoing = stackUnpositionedCues(incoming)
    if (incoming.isNotEmpty()) {
      Log.d(
        TAG,
        "onCues: received ${incoming.size} cues (non-ASS)" +
          if (outgoing !== incoming) " — stacked" else ""
      )
    }
    subtitleView?.setCues(outgoing)
  }

  // SRT carries no per-cue positioning, so SubripParser emits cues with
  // lineType = TYPE_UNSET. SubtitlePainter then renders every such cue at the
  // same default bottom-anchored position, causing visible overlap when more
  // than one is active. Reassign line numbers from the bottom up so concurrent
  // unpositioned cues stack instead. Workaround for
  // https://github.com/androidx/media/issues/2237; can be removed once
  // https://github.com/androidx/media/pull/3151 lands and we upgrade Media3.
  private fun stackUnpositionedCues(cues: List<Cue>): List<Cue> {
    if (cues.size < 2) return cues
    val toStack = cues.indices.filter {
      cues[it].lineType == Cue.TYPE_UNSET && cues[it].text != null
    }
    if (toStack.size < 2) return cues
    val rebuilt = cues.toMutableList()
    var nextRow = -1
    // Reverse so the last cue in the group lands on row -1 (bottom).
    for (idx in toStack.reversed()) {
      val cue = cues[idx]
      rebuilt[idx] = cue.buildUpon()
        .setLine(nextRow.toFloat(), Cue.LINE_TYPE_NUMBER)
        .setLineAnchor(Cue.ANCHOR_TYPE_END)
        .build()
      val rowsConsumed = (cue.text?.toString()?.count { it == '\n' } ?: 0) + 1
      nextRow -= rowsConsumed
    }
    return rebuilt
  }

  override fun onIsPlayingChanged(isPlaying: Boolean) {
    Log.d(TAG, "onIsPlayingChanged: $isPlaying")
    if (isPlaying) pendingPlayWhenReady = null
    delegate?.onPropertyChange("pause", !isPlaying)
  }

  override fun onPlaybackStateChanged(state: Int) {
    val stateStr = when (state) {
      Player.STATE_IDLE -> "idle"
      Player.STATE_BUFFERING -> "buffering"
      Player.STATE_READY -> "ready"
      Player.STATE_ENDED -> "ended"
      else -> "unknown"
    }
    emitLog("debug", "state", stateStr)
    emitCurrentSeekable()

    when (state) {
      Player.STATE_BUFFERING -> {
        delegate?.onPropertyChange("paused-for-cache", true)
      }
      Player.STATE_READY -> {
        // Restore start position if it was lost during track reselection
        // (e.g. tunneling state change in onTracksChanged triggers renderer teardown)
        if (pendingStartPositionMs > 0L) {
          val currentPos = exoPlayer?.currentPosition ?: 0L
          if (currentPos < 1000L) {
            emitLog("warn", "state", "Position lost (at ${currentPos}ms, expected ${pendingStartPositionMs}ms) — restoring")
            exoPlayer?.seekTo(pendingStartPositionMs)
          }
          pendingStartPositionMs = 0L
        }
        val pendingPlay = pendingPlayWhenReady
        val currentPlayWhenReady = exoPlayer?.playWhenReady
        if (pendingPlay != null && currentPlayWhenReady != pendingPlay) {
          emitLog("warn", "state", "playWhenReady lost (now $currentPlayWhenReady, expected $pendingPlay) — restoring")
          exoPlayer?.playWhenReady = pendingPlay
        }
        delegate?.onPropertyChange("paused-for-cache", false)
        delegate?.onEvent("playback-restart", null)
        emitTrackList()

        // Start frame watchdog to detect black screen (HDR tunneling issue)
        startFrameWatchdog()
      }
      Player.STATE_ENDED -> {
        stopFrameWatchdog()
        delegate?.onPropertyChange("eof-reached", true)
        delegate?.onEvent("end-file", mapOf("reason" to "eof"))
      }
    }
  }

  override fun onTracksChanged(tracks: Tracks) {
    Log.d(TAG, "onTracksChanged")
    // Detect video track present but deselected (unsupported codec — plays audio only)
    val hasAnyVideoGroup = tracks.groups.any { it.type == C.TRACK_TYPE_VIDEO }
    val hasSelectedVideo = tracks.groups.any { it.type == C.TRACK_TYPE_VIDEO && it.isSelected }
    if (hasAnyVideoGroup && !hasSelectedVideo && currentMediaUri != null) {
      // Try DV conversion before falling to MPV
      if (retryWithDvConversion("video track not selected")) return
      emitLog("warn", "fallback", "Video track present but not selected (unsupported codec)")
      delegate?.onFormatUnsupported(
        uri = currentMediaUri!!,
        headers = currentHeaders,
        positionMs = effectivePosition,
        errorMessage = "Video track present but no decoder available"
      )
      return
    }

    if (restorePendingDvTrackSelection(tracks)) return

    // Log selected video and audio track details
    val videoGroup = tracks.groups.firstOrNull { it.type == C.TRACK_TYPE_VIDEO && it.isSelected }
    val audioGroup = tracks.groups.firstOrNull { it.type == C.TRACK_TYPE_AUDIO && it.isSelected }
    if (videoGroup != null) {
      val vf = videoGroup.mediaTrackGroup.getFormat(0)
      val hdr = vf.colorInfo?.let { ci ->
        val transfer = ci.colorTransfer
        if (transfer != null && transfer != 0) " HDR(transfer=$transfer)" else ""
      } ?: ""
      emitLog("info", "tracks", "Video: ${vf.codecs} ${vf.width}x${vf.height}$hdr")
    }
    if (audioGroup != null) {
      val af = audioGroup.mediaTrackGroup.getFormat(0)
      emitLog("info", "tracks", "Audio: ${formatAudioSummary(af)}")
      if (af.sampleMimeType == MimeTypes.AUDIO_TRUEHD) {
        updateAudioDecoderPolicy("tracks changed", af)
      }
    }

    evaluateAudioCodecForTunneling()
    evaluateVideoCodecForTunneling()
    updateTunnelingState("tracks changed")
    emitTrackList()
  }

  override fun onPlayerError(error: PlaybackException) {
    // Log full exception chain unminified — R8 mangles simpleName but not toString/message
    val causeChain = buildString {
      var t: Throwable? = error.cause
      while (t != null) {
        if (isNotEmpty()) append(" → ")
        append("${t.javaClass.name}: ${t.message}")
        t = t.cause
      }
    }
    emitLog("error", "player", "Error code=${error.errorCode}: ${error.message}, cause=${causeChain.ifEmpty { "none" }}")
    stopFrameWatchdog()
    cancelDecoderHangCheck()
    emitSeekable(false, force = true)

    // If native DV7 failed, retry with conversion before falling to MPV
    if (error.errorCode in 4001..4005 && retryWithDvConversion("decoder error ${error.errorCode}")) return

    // Server returned HTTP 500 — typically a shared-user bandwidth/transcoding limit
    // set by the server owner. MPV will hit the same rejection, so skip the fallback.
    // Keep the "server-http-500" tag in sync with PlayerError.serverHttp500 in Dart.
    val isHttp500 =
      causeChain.contains("Response code: 500") ||
        (error.message?.contains("Response code: 500") == true)
    if (isHttp500) {
      Log.w(TAG, "Server returned HTTP 500 - skipping MPV fallback (unrecoverable until server-side change)")
      delegate?.onEvent(
        "end-file",
        mapOf(
          "reason" to "error",
          "message" to (error.message ?: "HTTP 500"),
          "cause" to "server-http-500"
        )
      )
      return
    }

    if (currentMediaUri != null) {
      Log.w(TAG, "ExoPlayer error (code ${error.errorCode}) - attempting fallback to MPV")
      val handled = delegate?.onFormatUnsupported(
        uri = currentMediaUri!!,
        headers = currentHeaders,
        positionMs = effectivePosition,
        errorMessage = error.message ?: "Unknown error"
      ) ?: false

      if (handled) return
    }

    delegate?.onEvent(
      "end-file",
      mapOf(
        "reason" to "error",
        "message" to (error.message ?: "Unknown error")
      )
    )
  }

  /**
   * When native DV7 decoding fails (device falsely advertises DV7 support),
   * upgrade to DV7→8.1 conversion or HEVC strip and reload the media.
   * Returns true if retry was initiated.
   */
  private fun retryWithDvConversion(reason: String): Boolean {
    if (dv7RetryAttempted) return false
    if (debugDvModeOverride == DvConversionMode.DISABLED) return false
    if (dvMode != DvConversionMode.DISABLED) return false
    if (!DoviBridge.isAvailable()) return false
    if (currentMediaUri == null) return false

    dv7RetryAttempted = true
    val newMode = DoviBridge.getDv7FallbackMode()
    dvMode = newMode
    Log.i(TAG, "Native DV7 playback failed ($reason), retrying with $newMode")
    emitLog("info", "dv-fallback", "DV7 native failed ($reason), retrying as $newMode")

    return reloadCurrentMediaForDvMode()
  }

  override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
    Log.d(TAG, "onMediaItemTransition: ${mediaItem?.mediaId}, reason: $reason")
    delegate?.onEvent("file-loaded", null)
    delegate?.onPropertyChange("eof-reached", false)
    emitCurrentSeekable(force = true)
  }

  override fun onVideoSizeChanged(videoSize: VideoSize) {
    Log.d(TAG, "Video size changed: ${videoSize.width}x${videoSize.height}, ratio: ${videoSize.pixelWidthHeightRatio}")
    lastVideoSize = videoSize
    updateSurfaceViewSize(videoSize.width, videoSize.height, videoSize.pixelWidthHeightRatio)
  }

  private fun updateSurfaceViewSize(videoWidth: Int, videoHeight: Int, pixelRatio: Float) {
    if (disposing) return
    if (videoWidth == 0 || videoHeight == 0) return

    val videoAspect = (videoWidth * pixelRatio) / videoHeight
    activity.runOnUiThread {
      videoAspectContainer?.setAspectRatio(videoAspect)
    }
    updateSubtitleViewSize(videoWidth, videoHeight, pixelRatio)
  }

  private fun updateSubtitleViewSize(videoWidth: Int, videoHeight: Int, pixelRatio: Float) {
    if (disposing) return
    if (videoWidth == 0 || videoHeight == 0) return

    val subtitle = subtitleView ?: return
    val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
    val containerWidth = contentView.width
    val containerHeight = contentView.height
    if (containerWidth == 0 || containerHeight == 0) return

    // In cover/stretch modes subtitles stay at container size so they never get
    // cropped or distorted. In letterbox mode they follow the video rect so they
    // anchor to the bottom of the video (matching MPV's default sub positioning).
    val isLetterbox = videoAspectContainer?.resizeMode == AspectRatioFrameLayout.RESIZE_MODE_FIT
    val (subWidth, subHeight) = if (isLetterbox) {
      val videoAspect = (videoWidth * pixelRatio) / videoHeight
      val containerAspect = containerWidth.toFloat() / containerHeight
      if (videoAspect > containerAspect) {
        containerWidth to (containerWidth / videoAspect).toInt()
      } else {
        (containerHeight * videoAspect).toInt() to containerHeight
      }
    } else {
      containerWidth to containerHeight
    }

    activity.runOnUiThread {
      subtitle.layoutParams = FrameLayout.LayoutParams(subWidth, subHeight).apply {
        gravity = Gravity.CENTER
      }
      subtitle.requestLayout()
    }
  }

  private fun boxFitModeToResizeMode(mode: Int): Int = when (mode) {
    1 -> AspectRatioFrameLayout.RESIZE_MODE_ZOOM
    2 -> AspectRatioFrameLayout.RESIZE_MODE_FILL
    else -> AspectRatioFrameLayout.RESIZE_MODE_FIT
  }

  fun setBoxFitMode(mode: Int) {
    if (disposing) return
    activity.runOnUiThread {
      videoAspectContainer?.resizeMode = boxFitModeToResizeMode(mode.coerceIn(0, 2))
      lastVideoSize?.let { vs ->
        if (vs.width > 0 && vs.height > 0) {
          updateSubtitleViewSize(vs.width, vs.height, vs.pixelWidthHeightRatio)
        }
      }
    }
  }

  private fun emitTrackList() {
    val player = exoPlayer ?: return
    val tracks = player.currentTracks

    val trackList = mutableListOf<Map<String, Any?>>()
    audioTrackGroupMap.clear()
    subtitleTrackGroupMap.clear()

    // Group tracks by type and use group index as track ID (matching select functions)
    val audioGroups = tracks.groups.filter { it.type == C.TRACK_TYPE_AUDIO }
    val textGroups = tracks.groups.filter { it.type == C.TRACK_TYPE_TEXT }
    val videoGroups = tracks.groups.filter { it.type == C.TRACK_TYPE_VIDEO }

    var selectedAudioId: String? = null
    var selectedSubId: String? = null

    // Process audio tracks
    audioGroups.forEachIndexed { groupIndex, group ->
      val trackGroup = group.mediaTrackGroup
      // Use first format in group as the representative track
      val format = trackGroup.getFormat(0)
      val trackId = "${C.TRACK_TYPE_AUDIO}_$groupIndex"
      audioTrackGroupMap[trackId] = trackGroup
      val isSelected = group.isSelected

      val track = mutableMapOf<String, Any?>(
        "type" to "audio",
        "id" to trackId,
        "title" to format.label,
        "lang" to format.language,
        "codec" to format.codecs,
        "default" to (format.selectionFlags and C.SELECTION_FLAG_DEFAULT != 0),
        "selected" to isSelected,
        "demux-channel-count" to format.channelCount,
        "demux-samplerate" to format.sampleRate
      )
      trackList.add(track)

      if (isSelected) {
        selectedAudioId = trackId
      }
    }

    // Process subtitle tracks (embedded + side-loaded external)
    Log.d(TAG, "emitTrackList: found ${textGroups.size} subtitle track groups")
    textGroups.forEachIndexed { groupIndex, group ->
      val trackGroup = group.mediaTrackGroup
      val format = trackGroup.getFormat(0)
      val trackId = "${C.TRACK_TYPE_TEXT}_$groupIndex"
      subtitleTrackGroupMap[trackId] = trackGroup
      val isSelected = group.isSelected

      // Detect external (side-loaded) subtitle by the ID prefix set in open()
      val isExternal = format.id?.startsWith("external_") == true
      val externalIndex = if (isExternal) format.id?.removePrefix("external_")?.toIntOrNull() else null
      val externalUri = externalIndex?.takeIf { it in externalSubtitleUris.indices }?.let { externalSubtitleUris[it] }

      Log.d(TAG, "Subtitle track $groupIndex: codec=${format.codecs}, lang=${format.language}, selected=$isSelected, external=$isExternal")

      val track = mutableMapOf<String, Any?>(
        "type" to "sub",
        "id" to trackId,
        "title" to format.label,
        "lang" to format.language,
        "codec" to format.codecs,
        "default" to (format.selectionFlags and C.SELECTION_FLAG_DEFAULT != 0),
        "forced" to (format.selectionFlags and C.SELECTION_FLAG_FORCED != 0),
        "selected" to isSelected,
        "external" to isExternal,
        "external-filename" to externalUri
      )
      trackList.add(track)

      if (isSelected) {
        selectedSubId = trackId
      }
    }

    // Process video tracks (for completeness, typically only one)
    videoGroups.forEachIndexed { groupIndex, group ->
      val trackGroup = group.mediaTrackGroup
      val format = trackGroup.getFormat(0)
      val trackId = "${C.TRACK_TYPE_VIDEO}_$groupIndex"

      val track = mutableMapOf<String, Any?>(
        "type" to "video",
        "id" to trackId,
        "title" to format.label,
        "lang" to format.language,
        "codec" to format.codecs,
        "default" to (format.selectionFlags and C.SELECTION_FLAG_DEFAULT != 0),
        "selected" to group.isSelected
      )
      trackList.add(track)
    }

    // Emit selected track IDs
    if (selectedAudioId != null) {
      selectedAudioTrackId = selectedAudioId
      delegate?.onPropertyChange("aid", selectedAudioId)
    }

    if (selectedSubId != null) {
      selectedSubtitleTrackId = selectedSubId
      delegate?.onPropertyChange("sid", selectedSubId)
    } else if (textGroups.isNotEmpty()) {
      selectedSubtitleTrackId = "no"
      delegate?.onPropertyChange("sid", "no")
    }

    delegate?.onPropertyChange("track-list", trackList)
  }

  private fun captureDvTrackRestore(): PendingTrackRestore? {
    val tracks = exoPlayer?.currentTracks ?: return null
    val audio = captureSelectedTrackIdentity(tracks, C.TRACK_TYPE_AUDIO)
      ?: captureMappedTrackIdentity(selectedAudioTrackId, audioTrackGroupMap, C.TRACK_TYPE_AUDIO)
    val subtitle = captureSelectedTrackIdentity(tracks, C.TRACK_TYPE_TEXT)
      ?: captureMappedTrackIdentity(selectedSubtitleTrackId, subtitleTrackGroupMap, C.TRACK_TYPE_TEXT)
    val subtitleDisabled = subtitle == null && selectedSubtitleTrackId == "no"

    if (audio == null && subtitle == null && !subtitleDisabled) return null
    return PendingTrackRestore(audio, subtitle, subtitleDisabled)
  }

  private fun captureSelectedTrackIdentity(tracks: Tracks, type: Int): TrackRestoreIdentity? {
    var typeGroupIndex = 0
    for (group in tracks.groups) {
      if (group.type != type) continue
      val trackIndex = selectedTrackIndex(group)
      if (trackIndex != null) {
        return buildTrackRestoreIdentity(type, typeGroupIndex, trackIndex, group.mediaTrackGroup.getFormat(trackIndex))
      }
      typeGroupIndex++
    }
    return null
  }

  private fun captureMappedTrackIdentity(
    trackId: String?,
    trackMap: Map<String, TrackGroup>,
    type: Int
  ): TrackRestoreIdentity? {
    if (trackId == null || trackId == "no") return null
    val trackGroup = trackMap[trackId] ?: return null
    if (trackGroup.length == 0) return null
    val groupIndex = trackId.substringAfter('_', "").toIntOrNull() ?: -1
    return buildTrackRestoreIdentity(type, groupIndex, 0, trackGroup.getFormat(0))
  }

  private fun selectedTrackIndex(group: Tracks.Group): Int? {
    if (!group.isSelected) return null
    for (trackIndex in 0 until group.mediaTrackGroup.length) {
      if (group.isTrackSelected(trackIndex)) return trackIndex
    }
    return if (group.mediaTrackGroup.length > 0) 0 else null
  }

  private fun buildTrackRestoreIdentity(
    type: Int,
    groupIndex: Int,
    trackIndex: Int,
    format: Format
  ): TrackRestoreIdentity = TrackRestoreIdentity(
    type = type,
    groupIndex = groupIndex,
    trackIndex = trackIndex,
    formatId = normalizedText(format.id),
    label = normalizedText(format.label),
    language = normalizedLanguage(format.language),
    sampleMimeType = normalizedText(format.sampleMimeType),
    codecs = normalizedText(format.codecs),
    channelCount = format.channelCount,
    sampleRate = format.sampleRate,
    selectionFlags = format.selectionFlags
  )

  private fun restorePendingDvTrackSelection(tracks: Tracks): Boolean {
    val pending = pendingDvTrackRestore ?: return false
    if (trackSelector == null) return false
    if (shouldWaitForDvRestoreTracks(pending, tracks)) return true
    pendingDvTrackRestore = null

    val audioMatch = pending.audio?.let { findTrackRestoreMatch(tracks, it) }
    val subtitleMatch = pending.subtitle?.let { findTrackRestoreMatch(tracks, it) }
    val hasSelectedText = tracks.groups.any { it.type == C.TRACK_TYPE_TEXT && it.isSelected }
    var selectionWillChange = false
    var appliedRestore = false
    var audioOverride: TrackSelectionOverride? = null
    var textOverride: TrackSelectionOverride? = null
    var clearTextOverrides = false
    var textDisabled: Boolean? = null

    if (pending.audio != null) {
      if (audioMatch != null) {
        audioOverride = TrackSelectionOverride(audioMatch.trackGroup, audioMatch.trackIndex)
        selectionWillChange = selectionWillChange || !audioMatch.isSelected()
        appliedRestore = true
        emitLog("info", "track-restore", "Restoring audio after DV reload: ${pending.audio.describe()} -> ${audioMatch.format.describeTrackFormat()} score=${audioMatch.score}")
      } else {
        emitLog("warn", "track-restore", "Could not restore audio after DV reload: ${pending.audio.describe()}")
      }
    }

    if (pending.subtitleDisabled) {
      clearTextOverrides = true
      textDisabled = true
      selectionWillChange = selectionWillChange || hasSelectedText
      appliedRestore = true
      emitLog("info", "track-restore", "Restoring subtitles off after DV reload")
    } else if (pending.subtitle != null) {
      if (subtitleMatch != null) {
        textOverride = TrackSelectionOverride(subtitleMatch.trackGroup, subtitleMatch.trackIndex)
        textDisabled = false
        selectionWillChange = selectionWillChange || !subtitleMatch.isSelected()
        appliedRestore = true
        emitLog("info", "track-restore", "Restoring subtitle after DV reload: ${pending.subtitle.describe()} -> ${subtitleMatch.format.describeTrackFormat()} score=${subtitleMatch.score}")
      } else {
        emitLog("warn", "track-restore", "Could not restore subtitle after DV reload: ${pending.subtitle.describe()}")
      }
    }

    if (appliedRestore) {
      audioMatch?.let { updateAudioCodecForTunneling(it.format) }
      evaluateVideoCodecForTunneling()
      applyTrackSelectorPolicy(
        reason = "DV track restore",
        forceSelector = true,
        audioOverride = audioOverride,
        audioDisabled = if (audioOverride != null) false else null,
        clearTextOverrides = clearTextOverrides,
        textOverride = textOverride,
        textDisabled = textDisabled
      )
    }
    return selectionWillChange
  }

  private fun shouldWaitForDvRestoreTracks(pending: PendingTrackRestore, tracks: Tracks): Boolean {
    val hasAudioGroups = tracks.groups.any { it.type == C.TRACK_TYPE_AUDIO }
    val hasTextGroups = tracks.groups.any { it.type == C.TRACK_TYPE_TEXT }
    return (pending.audio != null && !hasAudioGroups) ||
      (pending.subtitle != null && !hasTextGroups)
  }

  private fun findTrackRestoreMatch(tracks: Tracks, identity: TrackRestoreIdentity): TrackRestoreMatch? {
    var bestMatch: TrackRestoreMatch? = null
    var typeGroupIndex = 0
    for (group in tracks.groups) {
      if (group.type != identity.type) continue
      val trackGroup = group.mediaTrackGroup
      for (trackIndex in 0 until trackGroup.length) {
        val format = trackGroup.getFormat(trackIndex)
        val score = scoreTrackRestoreMatch(identity, format, typeGroupIndex, trackIndex)
        if (bestMatch == null || score > bestMatch.score) {
          bestMatch = TrackRestoreMatch(group, trackGroup, trackIndex, format, score)
        }
      }
      typeGroupIndex++
    }

    val minimumScore = if (identity.type == C.TRACK_TYPE_AUDIO) 35 else 30
    return bestMatch?.takeIf { it.score >= minimumScore }
  }

  private fun scoreTrackRestoreMatch(
    identity: TrackRestoreIdentity,
    format: Format,
    groupIndex: Int,
    trackIndex: Int
  ): Int {
    var score = 0
    val candidateId = normalizedText(format.id)
    if (identity.formatId != null && candidateId != null) {
      score += if (identity.formatId == candidateId) 100 else -15
    }
    val candidateLabel = normalizedText(format.label)
    if (identity.label != null && candidateLabel != null && identity.label == candidateLabel) score += 40
    val candidateLanguage = normalizedLanguage(format.language)
    if (identity.language != null && candidateLanguage != null && identity.language == candidateLanguage) score += 30
    val candidateMime = normalizedText(format.sampleMimeType)
    if (identity.sampleMimeType != null && candidateMime != null && identity.sampleMimeType == candidateMime) score += 12
    val candidateCodecs = normalizedText(format.codecs)
    if (identity.codecs != null && candidateCodecs != null && identity.codecs == candidateCodecs) score += 8
    if (identity.channelCount != Format.NO_VALUE && identity.channelCount == format.channelCount) score += 6
    if (identity.sampleRate != Format.NO_VALUE && identity.sampleRate == format.sampleRate) score += 4
    if (identity.selectionFlags == format.selectionFlags) score += 3
    if (identity.groupIndex == groupIndex) score += 20
    if (identity.trackIndex == trackIndex) score += 5
    return score
  }

  private fun TrackRestoreMatch.isSelected(): Boolean = group.isSelected && group.isTrackSelected(trackIndex)

  private fun TrackRestoreIdentity.describe(): String {
    val parts = mutableListOf<String>()
    language?.let { parts.add("lang=$it") }
    label?.let { parts.add("label=$it") }
    sampleMimeType?.let { parts.add("mime=$it") }
    codecs?.let { parts.add("codecs=$it") }
    if (channelCount != Format.NO_VALUE) parts.add("channels=$channelCount")
    if (sampleRate != Format.NO_VALUE) parts.add("rate=$sampleRate")
    formatId?.let { parts.add("id=$it") }
    parts.add("group=$groupIndex")
    return parts.joinToString(",")
  }

  private fun Format.describeTrackFormat(): String {
    val parts = mutableListOf<String>()
    normalizedLanguage(language)?.let { parts.add("lang=$it") }
    normalizedText(label)?.let { parts.add("label=$it") }
    normalizedText(sampleMimeType)?.let { parts.add("mime=$it") }
    normalizedText(codecs)?.let { parts.add("codecs=$it") }
    if (channelCount != Format.NO_VALUE) parts.add("channels=$channelCount")
    if (sampleRate != Format.NO_VALUE) parts.add("rate=$sampleRate")
    normalizedText(id)?.let { parts.add("id=$it") }
    return parts.joinToString(",")
  }

  private fun normalizedText(value: String?): String? = value?.trim()?.takeIf { it.isNotEmpty() }

  private fun normalizedLanguage(value: String?): String? = normalizedText(value)?.lowercase()?.takeUnless { it == "und" }

  // Tunneling control — disabled when audio playback cannot use the platform tunneled pipeline.

  private data class TrueHdDirectOutputDecision(
    val blockDirectOutput: Boolean,
    val platformProbe: String,
    val media3Probe: String,
    val routeSummary: String
  )

  private fun shouldBlockDirectTrueHd(format: Format, reason: String): Boolean {
    val decision = evaluateTrueHdDirectOutput(format)
    logTrueHdDirectOutputDecision(reason, format, decision)
    return decision.blockDirectOutput
  }

  private fun updateAudioDecoderPolicy(reason: String, format: Format? = null) {
    if (format != null && format.sampleMimeType != MimeTypes.AUDIO_TRUEHD) return
    val decision = evaluateTrueHdDirectOutput(format)
    logTrueHdDirectOutputDecision(reason, format, decision)
  }

  private fun shouldForceAppAudioDecoder(mimeType: String): Boolean {
    if (mimeType == MimeTypes.AUDIO_FLAC) return true
    if (DeviceQuirks.isEWaste && isEac3MimeType(mimeType)) {
      if (!loggedEwasteEac3Workaround) {
        loggedEwasteEac3Workaround = true
        emitLog("info", "decoder", "Using app decoder for E-AC3 on this device")
      }
      return true
    }
    return false
  }

  private fun evaluateTrueHdDirectOutput(format: Format?): TrueHdDirectOutputDecision {
    val probeFormat = trueHdProbeFormat(format)
    val audioAttributes = buildMovieAudioAttributes()
    val platformAttributes = audioAttributes.getPlatformAudioAttributes()

    var platformSupported: Boolean? = null
    val platformProbe = try {
      when {
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU -> {
          val platformFormat = buildTrueHdAudioFormat(probeFormat)
          val support = AudioManager.getDirectPlaybackSupport(platformFormat, platformAttributes)
          val bitstream = (support and AudioManager.DIRECT_PLAYBACK_BITSTREAM_SUPPORTED) != 0
          platformSupported = bitstream
          "api=${Build.VERSION.SDK_INT}, direct=${describeDirectPlaybackSupport(support)}, bitstream=$bitstream"
        }
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> {
          val platformFormat = buildTrueHdAudioFormat(probeFormat)
          val direct = isDirectPlaybackSupportedApi29(platformFormat, platformAttributes)
          platformSupported = direct
          "api=${Build.VERSION.SDK_INT}, direct=$direct"
        }
        else -> "api=${Build.VERSION.SDK_INT}, direct=unknown"
      }
    } catch (e: Exception) {
      "api=${Build.VERSION.SDK_INT}, direct=error(${e.javaClass.simpleName}: ${e.message})"
    }

    var media3Supported: Boolean? = null
    val media3Probe = try {
      media3Supported = AudioCapabilities
        .getCapabilities(activity, audioAttributes, null)
        .isPassthroughPlaybackSupported(probeFormat, audioAttributes)
      "media3Passthrough=$media3Supported"
    } catch (e: Exception) {
      "media3Passthrough=error(${e.javaClass.simpleName}: ${e.message})"
    }

    val blockDirectOutput = when {
      Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && platformSupported != null -> !platformSupported
      media3Supported != null -> !media3Supported
      platformSupported != null -> !platformSupported
      else -> false
    }

    return TrueHdDirectOutputDecision(
      blockDirectOutput = blockDirectOutput,
      platformProbe = platformProbe,
      media3Probe = media3Probe,
      routeSummary = summarizeAudioOutputRoutes(audioAttributes)
    )
  }

  private fun logTrueHdDirectOutputDecision(reason: String, format: Format?, decision: TrueHdDirectOutputDecision) {
    val key = listOf(
      decision.blockDirectOutput,
      decision.platformProbe,
      decision.media3Probe,
      decision.routeSummary,
      format?.id,
      format?.channelCount,
      format?.sampleRate
    ).joinToString("|")
    if (key == lastTrueHdDirectOutputLogKey) return
    lastTrueHdDirectOutputLogKey = key

    emitLog(
      "info",
      "audio",
      "TrueHD direct output ${if (decision.blockDirectOutput) "disabled (decoded PCM fallback)" else "allowed"} " +
        "(reason=$reason, format=${formatAudioSummary(trueHdProbeFormat(format))}, " +
        "${decision.platformProbe}, ${decision.media3Probe}, route=${decision.routeSummary})"
    )
  }

  private fun trueHdProbeFormat(format: Format?): Format = if (format?.sampleMimeType == MimeTypes.AUDIO_TRUEHD) {
    format
  } else {
    Format.Builder()
      .setSampleMimeType(MimeTypes.AUDIO_TRUEHD)
      .setChannelCount(8)
      .setSampleRate(48_000)
      .build()
  }

  private fun buildMovieAudioAttributes(): androidx.media3.common.AudioAttributes = androidx.media3.common.AudioAttributes.Builder()
    .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
    .setUsage(C.USAGE_MEDIA)
    .build()

  private fun buildTrueHdAudioFormat(format: Format): AudioFormat {
    val channelCount = if (format.channelCount > 0) format.channelCount else 8
    val channelMask = Util.getAudioTrackChannelConfig(channelCount).takeIf { it != 0 }
      ?: AudioFormat.CHANNEL_OUT_7POINT1_SURROUND
    val sampleRate = if (format.sampleRate > 0) format.sampleRate else 48_000
    return AudioFormat.Builder()
      .setEncoding(AudioFormat.ENCODING_DOLBY_TRUEHD)
      .setChannelMask(channelMask)
      .setSampleRate(sampleRate)
      .build()
  }

  @Suppress("DEPRECATION")
  private fun isDirectPlaybackSupportedApi29(
    audioFormat: AudioFormat,
    audioAttributes: android.media.AudioAttributes
  ): Boolean = AudioTrack.isDirectPlaybackSupported(audioFormat, audioAttributes)

  private fun describeDirectPlaybackSupport(support: Int): String {
    if (support == AudioManager.DIRECT_PLAYBACK_NOT_SUPPORTED) return "none"
    val parts = mutableListOf<String>()
    if ((support and AudioManager.DIRECT_PLAYBACK_BITSTREAM_SUPPORTED) != 0) parts.add("bitstream")
    if ((support and AudioManager.DIRECT_PLAYBACK_OFFLOAD_SUPPORTED) != 0) parts.add("offload")
    if ((support and AudioManager.DIRECT_PLAYBACK_OFFLOAD_GAPLESS_SUPPORTED) != 0) parts.add("offload-gapless")
    if (parts.isEmpty()) parts.add("0x${support.toString(16)}")
    return parts.joinToString("+")
  }

  private fun summarizeAudioOutputRoutes(audioAttributes: androidx.media3.common.AudioAttributes): String = try {
    val audioManager = activity.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    val routedDevices = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      audioManager.getAudioDevicesForAttributes(audioAttributes.getPlatformAudioAttributes())
    } else {
      emptyList()
    }
    val devices = if (routedDevices.isNotEmpty()) {
      routedDevices
    } else {
      audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS).toList()
    }
    val source = if (routedDevices.isNotEmpty()) "routed" else "outputs"
    if (devices.isEmpty()) {
      "$source=none"
    } else {
      val extra = if (devices.size > 3) ";+${devices.size - 3}" else ""
      "$source=${devices.take(3).joinToString(";") { describeAudioDevice(it) }}$extra"
    }
  } catch (e: Exception) {
    "error(${e.javaClass.simpleName}: ${e.message})"
  }

  private fun describeAudioDevice(device: AudioDeviceInfo): String {
    val encodings = device.encodings.takeIf { it.isNotEmpty() }
      ?.joinToString("|") { audioEncodingName(it) }
      ?: "any/unknown"
    val channels = device.channelCounts.takeIf { it.isNotEmpty() }
      ?.joinToString("|")
      ?: "unknown"
    val name = device.productName?.toString()?.take(32) ?: "unknown"
    return "${audioDeviceTypeName(device.type)}($name,enc=$encodings,ch=$channels)"
  }

  private fun audioEncodingName(encoding: Int): String = when (encoding) {
    AudioFormat.ENCODING_PCM_16BIT -> "pcm16"
    AudioFormat.ENCODING_PCM_FLOAT -> "pcm-float"
    AudioFormat.ENCODING_AC3 -> "ac3"
    AudioFormat.ENCODING_E_AC3 -> "eac3"
    AudioFormat.ENCODING_E_AC3_JOC -> "eac3-joc"
    AudioFormat.ENCODING_DTS -> "dts"
    AudioFormat.ENCODING_DTS_HD -> "dts-hd"
    AudioFormat.ENCODING_DOLBY_TRUEHD -> "truehd"
    else -> encoding.toString()
  }

  private fun audioDeviceTypeName(type: Int): String = when (type) {
    AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> "speaker"
    AudioDeviceInfo.TYPE_HDMI -> "hdmi"
    AudioDeviceInfo.TYPE_HDMI_ARC -> "hdmi-arc"
    AudioDeviceInfo.TYPE_HDMI_EARC -> "hdmi-earc"
    AudioDeviceInfo.TYPE_LINE_DIGITAL -> "line-digital"
    AudioDeviceInfo.TYPE_LINE_ANALOG -> "line-analog"
    AudioDeviceInfo.TYPE_USB_DEVICE -> "usb-device"
    AudioDeviceInfo.TYPE_USB_HEADSET -> "usb-headset"
    AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> "bt-a2dp"
    AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> "bt-sco"
    AudioDeviceInfo.TYPE_UNKNOWN -> "unknown"
    else -> "type-$type"
  }

  private fun isEac3MimeType(mimeType: String): Boolean = mimeType == MimeTypes.AUDIO_E_AC3 || mimeType == MimeTypes.AUDIO_E_AC3_JOC

  private fun hasHardwareAudioDecoder(mimeType: String): Boolean {
    // Keep tunneling decisions aligned with the MediaCodecSelector exclusions.
    if (shouldForceAppAudioDecoder(mimeType)) return false
    hwAudioDecoderCache[mimeType]?.let { return it }
    val result = try {
      val codecList = android.media.MediaCodecList(android.media.MediaCodecList.REGULAR_CODECS)
      var found = false
      for (info in codecList.codecInfos) {
        if (info.isEncoder) continue
        for (type in info.supportedTypes) {
          if (type.equals(mimeType, ignoreCase = true)) {
            val name = info.name
            if (!name.startsWith("OMX.google.") &&
              !name.startsWith("c2.android.") &&
              !name.contains(".sw.") &&
              !name.startsWith("c2.ffmpeg.")
            ) {
              Log.d(TAG, "Found hardware audio decoder for $mimeType: $name")
              found = true
              break
            }
          }
        }
        if (found) break
      }
      if (!found) Log.d(TAG, "No hardware audio decoder for $mimeType — app decoder may handle it")
      found
    } catch (e: Exception) {
      Log.w(TAG, "Failed to query audio decoders for $mimeType: ${e.message}")
      false
    }
    hwAudioDecoderCache[mimeType] = result
    return result
  }

  private fun videoCodecSupportsTunneledPlayback(mimeType: String): Boolean {
    tunneledPlaybackCache[mimeType]?.let { return it }
    val result = try {
      val codecList = android.media.MediaCodecList(android.media.MediaCodecList.REGULAR_CODECS)
      var supported = false
      for (info in codecList.codecInfos) {
        if (info.isEncoder) continue
        for (type in info.supportedTypes) {
          if (type.equals(mimeType, ignoreCase = true)) {
            val name = info.name
            if (name.startsWith("OMX.google.") ||
              name.startsWith("c2.android.") ||
              name.contains(".sw.") ||
              name.startsWith("c2.ffmpeg.")
            ) {
              continue // Skip software decoders
            }
            val caps = info.getCapabilitiesForType(type)
            if (caps.isFeatureSupported(android.media.MediaCodecInfo.CodecCapabilities.FEATURE_TunneledPlayback)) {
              Log.d(TAG, "Hardware video decoder $name supports tunneled playback for $mimeType")
              supported = true
              break
            } else {
              Log.d(TAG, "Hardware video decoder $name does NOT support tunneled playback for $mimeType")
            }
          }
        }
        if (supported) break
      }
      supported
    } catch (e: Exception) {
      Log.w(TAG, "Failed to query video decoders for tunneling support ($mimeType): ${e.message}")
      false
    }
    tunneledPlaybackCache[mimeType] = result
    return result
  }

  private fun evaluateVideoCodecForTunneling() {
    val player = exoPlayer ?: return
    val selectedVideoGroup = player.currentTracks.groups.firstOrNull {
      it.type == C.TRACK_TYPE_VIDEO && it.isSelected
    } ?: return

    val format = selectedVideoGroup.mediaTrackGroup.getFormat(0)
    val mimeType = format.sampleMimeType ?: return

    val newDisabled = !videoCodecSupportsTunneledPlayback(mimeType)
    if (newDisabled != tunnelingDisabledForVideoCodec) {
      tunnelingDisabledForVideoCodec = newDisabled
      emitLog("info", "tunneling", "Video codec ${format.codecs} ($mimeType): tunneling ${if (newDisabled) "DISABLED (no tunneling support)" else "enabled"}")
    }
  }

  private fun updateTunnelingState(reason: String, forceSelector: Boolean = false) {
    applyTrackSelectorPolicy(reason = reason, forceSelector = forceSelector)
  }

  private fun applyTrackSelectorPolicy(
    reason: String,
    forceSelector: Boolean = false,
    clearAudioOverrides: Boolean = false,
    clearTextOverrides: Boolean = false,
    audioOverride: TrackSelectionOverride? = null,
    textOverride: TrackSelectionOverride? = null,
    audioDisabled: Boolean? = null,
    textDisabled: Boolean? = null
  ) {
    val selector = trackSelector ?: return
    val builder = selector.buildUponParameters()
    var selectorChanged = forceSelector

    if (clearAudioOverrides) {
      builder.clearOverridesOfType(C.TRACK_TYPE_AUDIO)
      selectorChanged = true
    }
    if (clearTextOverrides) {
      builder.clearOverridesOfType(C.TRACK_TYPE_TEXT)
      selectorChanged = true
    }
    if (audioOverride != null) {
      builder.setOverrideForType(audioOverride)
      selectorChanged = true
    }
    if (textOverride != null) {
      builder.setOverrideForType(textOverride)
      selectorChanged = true
    }
    if (audioDisabled != null) {
      builder.setTrackTypeDisabled(C.TRACK_TYPE_AUDIO, audioDisabled)
      selectorChanged = true
    }
    if (textDisabled != null) {
      builder.setTrackTypeDisabled(C.TRACK_TYPE_TEXT, textDisabled)
      selectorChanged = true
    }

    val shouldTunnel = calculateTunnelingEnabled() ?: return
    selectorChanged = updateCurrentTunnelingState(reason, shouldTunnel) || selectorChanged
    builder.setTunnelingEnabled(shouldTunnel)
    if (selectorChanged) selector.parameters = builder.build()
  }

  private fun calculateTunnelingEnabled(): Boolean? {
    val player = exoPlayer ?: return null
    val audioDelayActive = (renderersFactory?.audioDelayUs?.get() ?: 0L) != 0L
    return tunnelingUserEnabled && (player.playbackParameters.speed == 1f) && !tunnelingDisabledForCodec && !audioDelayActive
  }

  private fun updateCurrentTunnelingState(reason: String, shouldTunnel: Boolean): Boolean {
    if (shouldTunnel == currentTunneledPlayback) return false
    currentTunneledPlayback = shouldTunnel
    val speed = exoPlayer?.playbackParameters?.speed ?: 1f
    val audioDelayActive = (renderersFactory?.audioDelayUs?.get() ?: 0L) != 0L
    emitLog("info", "tunneling", "Toggling tunneling=$shouldTunnel (reason=$reason, user=$tunnelingUserEnabled, speed=$speed, audioCodecDisabled=$tunnelingDisabledForAudioCodec, videoCodecDisabled=$tunnelingDisabledForVideoCodec, decodedTrueHdPcmDisabled=$tunnelingDisabledForDecodedTrueHdPcm, audioDelay=$audioDelayActive)")
    return true
  }

  private fun evaluateAudioCodecForTunneling() {
    val player = exoPlayer ?: return
    val selectedAudioGroup = player.currentTracks.groups.firstOrNull {
      it.type == C.TRACK_TYPE_AUDIO && it.isSelected
    } ?: return

    val format = selectedAudioGroup.mediaTrackGroup.getFormat(0)
    updateAudioCodecForTunneling(format)
  }

  private fun updateAudioCodecForTunneling(format: Format) {
    val mimeType = format.sampleMimeType ?: return
    if (mimeType != MimeTypes.AUDIO_TRUEHD) {
      tunnelingDisabledForDecodedTrueHdPcm = false
    }

    val newDisabled = !hasHardwareAudioDecoder(mimeType)
    if (newDisabled != tunnelingDisabledForAudioCodec) {
      tunnelingDisabledForAudioCodec = newDisabled
      emitLog("info", "tunneling", "Audio codec ${format.codecs} ($mimeType): tunneling ${if (newDisabled) "DISABLED (no hw decoder)" else "enabled"}")
    }
  }

  private fun buildMediaItem(uri: String): MediaItem {
    val mediaItemBuilder = MediaItem.Builder()
      .setUri(uri)

    if (externalSubtitles.isNotEmpty()) {
      mediaItemBuilder.setSubtitleConfigurations(externalSubtitles.toList())
    }

    return mediaItemBuilder.build()
  }

  private fun selectedAudioFormat(): Format? {
    val player = exoPlayer ?: return null
    val selectedAudioGroup = player.currentTracks.groups.firstOrNull {
      it.type == C.TRACK_TYPE_AUDIO && it.isSelected
    } ?: return null
    return selectedAudioGroup.mediaTrackGroup.getFormat(0)
  }

  private fun isPcmEncoding(encoding: Int): Boolean = when (encoding) {
    AudioFormat.ENCODING_PCM_8BIT,
    AudioFormat.ENCODING_PCM_16BIT,
    AudioFormat.ENCODING_PCM_FLOAT,
    AudioFormat.ENCODING_PCM_24BIT_PACKED,
    AudioFormat.ENCODING_PCM_32BIT -> true
    else -> false
  }

  private fun formatAudioSummary(format: Format): String {
    val parts = mutableListOf<String>()
    parts.add("mime=${format.sampleMimeType ?: "unknown"}")
    parts.add("codec=${format.codecs ?: "unknown"}")
    parts.add("channels=${format.channelCount}")
    parts.add("sampleRate=${format.sampleRate}")
    format.id?.let { parts.add("id=$it") }
    format.label?.let { parts.add("label=$it") }
    format.language?.let { parts.add("lang=$it") }
    return parts.joinToString(", ")
  }

  // Decoder hang detection via AnalyticsListener:
  // Tracks the gap between onVideoDecoderInitialized and onRenderedFirstFrame.
  // If the decoder is initialized and fed input but never produces output, it's hung
  // (e.g. DV profile 7 on PowerVR GPUs that accept the format but never decode).

  private val decoderHangListener = object : AnalyticsListener {
    override fun onVideoDecoderInitialized(
      eventTime: AnalyticsListener.EventTime,
      decoderName: String,
      initializationDurationMs: Long
    ) {
      decoderInitName = decoderName
      firstFrameRendered = false
      emitLog("debug", "decoder-hang", "Decoder initialized: $decoderName (${initializationDurationMs}ms)")
      startDecoderHangCheck(decoderName)
    }

    override fun onAudioDecoderInitialized(
      eventTime: AnalyticsListener.EventTime,
      decoderName: String,
      initializationDurationMs: Long
    ) {
      audioDecoderInitName = decoderName
      emitLog("info", "audio", "Decoder initialized: $decoderName (${initializationDurationMs}ms)")
    }

    override fun onAudioInputFormatChanged(
      eventTime: AnalyticsListener.EventTime,
      format: Format,
      decoderReuseEvaluation: DecoderReuseEvaluation?
    ) {
      emitLog("info", "audio", "Input format: ${formatAudioSummary(format)}")
      if (format.sampleMimeType == MimeTypes.AUDIO_TRUEHD) {
        updateAudioDecoderPolicy("input format", format)
      }
    }

    override fun onAudioPositionAdvancing(
      eventTime: AnalyticsListener.EventTime,
      playoutStartSystemTimeMs: Long
    ) {
      emitLog("debug", "audio", "Position advancing: playoutStart=$playoutStartSystemTimeMs")
    }

    override fun onAudioUnderrun(
      eventTime: AnalyticsListener.EventTime,
      bufferSize: Int,
      bufferSizeMs: Long,
      elapsedSinceLastFeedMs: Long
    ) {
      emitLog(
        "warn",
        "audio",
        "Underrun: buffer=${bufferSize}B, bufferMs=$bufferSizeMs, elapsedSinceLastFeedMs=$elapsedSinceLastFeedMs"
      )
    }

    override fun onAudioSinkError(eventTime: AnalyticsListener.EventTime, audioSinkError: Exception) {
      emitLog("warn", "audio", "Sink error: ${audioSinkError.javaClass.name}: ${audioSinkError.message}")
    }

    override fun onAudioCodecError(eventTime: AnalyticsListener.EventTime, audioCodecError: Exception) {
      emitLog("warn", "audio", "Codec error: ${audioCodecError.javaClass.name}: ${audioCodecError.message}")
    }

    override fun onAudioTrackInitialized(
      eventTime: AnalyticsListener.EventTime,
      audioTrackConfig: AudioSink.AudioTrackConfig
    ) {
      emitLog(
        "info",
        "audio",
        "AudioTrack initialized: encoding=${audioTrackConfig.encoding}, sampleRate=${audioTrackConfig.sampleRate}, " +
          "channelConfig=0x${audioTrackConfig.channelConfig.toString(16)}, buffer=${audioTrackConfig.bufferSize}B, " +
          "tunneling=${audioTrackConfig.tunneling}, offload=${audioTrackConfig.offload}"
      )
      val audioFormat = selectedAudioFormat()
      if (audioFormat?.sampleMimeType == MimeTypes.AUDIO_TRUEHD) {
        if (audioTrackConfig.tunneling && isPcmEncoding(audioTrackConfig.encoding)) {
          if (!loggedDecodedTrueHdTunnelingGuard) {
            loggedDecodedTrueHdTunnelingGuard = true
            emitLog("warn", "audio", "Decoded TrueHD PCM initialized with tunneling=true; forcing tunneling off")
          }
          tunnelingDisabledForDecodedTrueHdPcm = true
          updateTunnelingState("decoded TrueHD PCM tunneling guard", forceSelector = true)
        } else if (!isPcmEncoding(audioTrackConfig.encoding) && tunnelingDisabledForDecodedTrueHdPcm) {
          tunnelingDisabledForDecodedTrueHdPcm = false
          updateTunnelingState("encoded TrueHD output initialized", forceSelector = true)
        }
      }
    }

    override fun onAudioTrackReleased(
      eventTime: AnalyticsListener.EventTime,
      audioTrackConfig: AudioSink.AudioTrackConfig
    ) {
      emitLog(
        "debug",
        "audio",
        "AudioTrack released: encoding=${audioTrackConfig.encoding}, sampleRate=${audioTrackConfig.sampleRate}, " +
          "channelConfig=0x${audioTrackConfig.channelConfig.toString(16)}, buffer=${audioTrackConfig.bufferSize}B"
      )
    }

    override fun onVolumeChanged(eventTime: AnalyticsListener.EventTime, volume: Float) {
      emitLog("debug", "audio", "Volume changed: $volume")
    }

    override fun onRenderedFirstFrame(
      eventTime: AnalyticsListener.EventTime,
      output: Any,
      renderTimeMs: Long
    ) {
      firstFrameRendered = true
      cancelDecoderHangCheck()
      emitLog("debug", "decoder-hang", "First frame rendered — decoder OK")
      // STATE_READY fires when the player has enough buffered to start, but
      // the first frame may not be on screen yet (decoder init + keyframe
      // decode). The MPV-parity `playback-restart` event consumers (Dart
      // first-frame detection, frame-rate matching) want the moment the
      // pixel actually hits the screen, which is here.
      delegate?.onEvent("playback-restart", null)
    }
  }

  private fun startDecoderHangCheck(decoderName: String) {
    cancelDecoderHangCheck()
    if (currentMediaUri == null) return
    decoderHangRunnable = Runnable {
      if (firstFrameRendered) return@Runnable
      val uri = currentMediaUri ?: return@Runnable
      val player = exoPlayer ?: return@Runnable

      // Confirm via DecoderCounters: input queued but no output produced
      val counters = player.videoDecoderCounters
      val inputQueued = counters?.queuedInputBufferCount ?: 0
      val outputTotal = (counters?.renderedOutputBufferCount ?: 0) +
        (counters?.skippedOutputBufferCount ?: 0) +
        (counters?.droppedBufferCount ?: 0)

      if (inputQueued > 0 && outputTotal == 0) {
        emitLog("warn", "fallback", "Decoder hang: $decoderName queued $inputQueued buffers, 0 output after ${DECODER_HANG_TIMEOUT_MS}ms")
        stopFrameWatchdog()
        cancelDecoderHangCheck()
        if (retryWithDvConversion("decoder hang: $decoderName")) return@Runnable
        delegate?.onFormatUnsupported(
          uri = uri,
          headers = currentHeaders,
          positionMs = effectivePosition,
          errorMessage = "Decoder hang: $decoderName accepted input but produced no output"
        )
      }
    }
    handler.postDelayed(decoderHangRunnable!!, DECODER_HANG_TIMEOUT_MS)
  }

  private fun cancelDecoderHangCheck() {
    decoderHangRunnable?.let { handler.removeCallbacks(it) }
    decoderHangRunnable = null
  }

  // Frame watchdog: detects when ExoPlayer plays audio but renders 0 video frames
  // (common with HDR tunneling on unsupported devices — black screen, no error)

  private fun startFrameWatchdog() {
    stopFrameWatchdog()
    emitLog("debug", "watchdog", "Started (timeout=${WATCHDOG_TIMEOUT_MS}ms)")
    frameWatchdogStartTime = System.currentTimeMillis()
    frameWatchdogRunnable = object : Runnable {
      override fun run() {
        val player = exoPlayer ?: return
        val renderedFrames = player.videoDecoderCounters?.renderedOutputBufferCount ?: 0

        if (renderedFrames > 0) {
          emitLog("debug", "watchdog", "$renderedFrames frames rendered, cleared")
          stopFrameWatchdog()
          return
        }

        val elapsed = System.currentTimeMillis() - frameWatchdogStartTime

        // Check if we have a video track selected
        val hasVideoTrack = player.currentTracks.groups.any {
          it.type == C.TRACK_TYPE_VIDEO && it.isSelected
        }
        val hasAnyVideoGroup = player.currentTracks.groups.any {
          it.type == C.TRACK_TYPE_VIDEO
        }

        // Secondary safety net: video track exists but was deselected (unsupported codec)
        if (hasAnyVideoGroup && !hasVideoTrack) {
          emitLog("warn", "watchdog", "Video track deselected — triggering fallback")
          stopFrameWatchdog()
          if (retryWithDvConversion("watchdog: video track deselected")) return
          val uri = currentMediaUri ?: return
          delegate?.onFormatUnsupported(
            uri = uri,
            headers = currentHeaders,
            positionMs = player.currentPosition,
            errorMessage = "Video track present but no decoder available"
          )
          return
        }

        if (elapsed >= WATCHDOG_TIMEOUT_MS && player.isPlaying && hasVideoTrack) {
          emitLog("warn", "watchdog", "0 frames rendered after ${elapsed}ms — triggering fallback")
          stopFrameWatchdog()
          if (retryWithDvConversion("watchdog: black screen after ${elapsed}ms")) return
          // Trigger fallback via the same delegate path as player errors
          val uri = currentMediaUri ?: return
          delegate?.onFormatUnsupported(
            uri = uri,
            headers = currentHeaders,
            positionMs = player.currentPosition,
            errorMessage = "Black screen detected: 0 video frames rendered after ${elapsed}ms"
          )
          return
        }

        handler.postDelayed(this, WATCHDOG_CHECK_INTERVAL_MS)
      }
    }
    handler.postDelayed(frameWatchdogRunnable!!, WATCHDOG_CHECK_INTERVAL_MS)
  }

  private fun stopFrameWatchdog() {
    frameWatchdogRunnable?.let { handler.removeCallbacks(it) }
    frameWatchdogRunnable = null
  }

  // Public API

  fun open(
    uri: String,
    headers: Map<String, String>?,
    startPositionMs: Long,
    autoPlay: Boolean,
    isLive: Boolean = false,
    externalSubtitleList: List<Map<String, String?>>? = null
  ) {
    if (!isInitialized) return

    stopFrameWatchdog()
    cancelDecoderHangCheck()

    // Reset FPS detection for new content
    detectedFrameRate = -1f
    fpsTimestampCount = 0

    // Reset DV7 retry flag when opening a different file
    if (uri != currentMediaUri) {
      dv7RetryAttempted = false
    }

    decoderInitName = null
    audioDecoderInitName = null
    loggedDecodedTrueHdTunnelingGuard = false
    updateAudioDecoderPolicy("open")
    currentMediaUri = uri
    currentHeaders = headers
    currentMediaIsLive = isLive
    resetPlaybackProgress(startPositionMs)

    // Apply auth/custom headers to the HTTP DataSource for this session
    httpDataSourceFactory?.setDefaultRequestProperties(
      if (!headers.isNullOrEmpty()) headers else emptyMap()
    )

    externalSubtitles.clear()
    externalSubtitleUris.clear()
    audioTrackGroupMap.clear()
    subtitleTrackGroupMap.clear()
    selectedAudioTrackId = null
    selectedSubtitleTrackId = null
    pendingDvTrackRestore = null

    // Build external subtitle configurations (attached to MediaItem before prepare)
    externalSubtitleList?.forEachIndexed { index, sub ->
      val subUri = sub["uri"] ?: return@forEachIndexed
      val config = MediaItem.SubtitleConfiguration.Builder(Uri.parse(subUri))
        .setId("external_$index")
        .setLabel(sub["title"] ?: "External")
        .setLanguage(sub["language"])
        .setMimeType(sub["mimeType"] ?: detectSubtitleMimeType(subUri))
        .build()
      externalSubtitles.add(config)
      externalSubtitleUris.add(subUri)
    }
    tunnelingDisabledForAudioCodec = false
    tunnelingDisabledForVideoCodec = false
    tunnelingDisabledForDecodedTrueHdPcm = false
    currentTunneledPlayback = false
    pendingStartPositionMs = startPositionMs
    pendingPlayWhenReady = autoPlay
    applyTrackSelectorPolicy(
      reason = "open",
      forceSelector = true,
      clearAudioOverrides = true,
      clearTextOverrides = true
    )
    emitSeekable(false, force = true)

    if (isLive) {
      // Live MKV streams lack Cues (seek index). FLAG_DISABLE_SEEK_FOR_CUES tells
      // MatroskaExtractor to not seek for them, treating the stream as unseekable
      // so data flows immediately without hanging.
      // Headers already applied to httpDataSourceFactory above.
      val extractorsFactory = androidx.media3.extractor.ExtractorsFactory {
        arrayOf(MatroskaExtractor(MatroskaExtractor.FLAG_DISABLE_SEEK_FOR_CUES))
      }

      val mediaSource = ProgressiveMediaSource.Factory(dataSourceFactory!!, extractorsFactory)
        .createMediaSource(MediaItem.fromUri(uri))

      exoPlayer?.apply {
        setMediaSource(mediaSource, startPositionMs)
        prepare()
        playWhenReady = autoPlay
      }

      emitLog("info", "media", "Opened live: ${redactUri(uri)}, startPosition: ${startPositionMs}ms, autoPlay: $autoPlay, sessionTunneling=$currentTunneledPlayback")
      return
    }

    val mediaItem = buildMediaItem(uri)

    exoPlayer?.apply {
      setMediaItem(mediaItem, startPositionMs)
      prepare()
      playWhenReady = autoPlay
    }

    emitLog("info", "media", "Opened: ${redactUri(uri)}, startPosition: ${startPositionMs}ms, autoPlay: $autoPlay, sessionTunneling=$currentTunneledPlayback, userTunneling=$tunnelingUserEnabled")
  }

  fun setAudioDelay(seconds: Double) {
    renderersFactory?.audioDelayUs?.set((seconds * 1_000_000).toLong())
    updateTunnelingState("audio-delay")
  }

  fun setSubtitleDelay(seconds: Double) {
    subtitleDelayUs.set((seconds * 1_000_000).toLong())
  }

  fun setDebugDvConversionMode(mode: String): Boolean {
    val override = when (mode.trim().lowercase()) {
      "auto" -> null
      "disabled", "native" -> DvConversionMode.DISABLED
      "dv81", "p8", "p7_to_p8", "p7-to-p8" -> DvConversionMode.DV81
      "hevc", "hevc_strip", "p7_to_hevc", "p7-to-hevc" -> DvConversionMode.HEVC_STRIP
      else -> return false
    }

    debugDvModeOverride = override
    dvMode = getConfiguredDvMode()
    dv7RetryAttempted = override != null
    activeDoviMkvWrapper = null
    activeDoviMp4Wrapper = null
    val debugMode = override?.name ?: "AUTO"
    emitLog("info", "dv-debug", "Debug DV conversion mode set to $debugMode (active=$dvMode)")
    reloadCurrentMediaForDvMode()
    return true
  }

  private fun reloadCurrentMediaForDvMode(): Boolean {
    val player = exoPlayer ?: return false
    val uri = currentMediaUri ?: return false
    if (currentMediaIsLive) return false

    val savedPosition = maxOf(player.currentPosition, lastPosition, pendingStartPositionMs)
    val savedPlayWhenReady = player.playWhenReady
    pendingDvTrackRestore = captureDvTrackRestore()?.also { restore ->
      emitLog(
        "info",
        "track-restore",
        "Saved selection before DV reload: audio=${restore.audio?.describe() ?: "none"}, " +
          "subtitle=${restore.subtitle?.describe() ?: if (restore.subtitleDisabled) "off" else "none"}"
      )
    }
    pendingStartPositionMs = savedPosition
    pendingPlayWhenReady = savedPlayWhenReady
    decoderInitName = null
    audioDecoderInitName = null
    detectedFrameRate = -1f
    fpsTimestampCount = 0
    firstFrameRendered = false
    activeDoviMkvWrapper = null
    activeDoviMp4Wrapper = null
    stopFrameWatchdog()
    cancelDecoderHangCheck()

    applyTrackSelectorPolicy(
      reason = "DV reload",
      forceSelector = true,
      clearAudioOverrides = true,
      clearTextOverrides = true
    )

    val mediaItem = buildMediaItem(uri)
    player.setMediaItem(mediaItem, savedPosition)
    player.prepare()
    player.playWhenReady = savedPlayWhenReady
    emitLog("info", "dv-debug", "Reloaded media for DV mode $dvMode at ${savedPosition}ms")
    return true
  }

  fun play() {
    pendingPlayWhenReady = null
    exoPlayer?.play()
  }

  fun pause() {
    pendingPlayWhenReady = null
    exoPlayer?.pause()
  }

  fun stop() {
    stopFrameWatchdog()
    cancelDecoderHangCheck()
    exoPlayer?.stop()
    emitSeekable(false, force = true)
    setVisible(false)
  }

  fun seekTo(positionMs: Long) {
    val player = exoPlayer ?: return
    val durationMs = player.duration
    val clampedPositionMs = if (!currentMediaIsLive && durationMs != C.TIME_UNSET && durationMs > 0L) {
      positionMs.coerceIn(0L, durationMs)
    } else {
      positionMs.coerceAtLeast(0L)
    }
    player.seekTo(clampedPositionMs)
    lastPosition = clampedPositionMs
    delegate?.onPropertyChange("time-pos", clampedPositionMs / 1000.0)
  }

  fun setVolume(volume: Float) {
    exoPlayer?.volume = volume.coerceIn(0f, 1f)
    delegate?.onPropertyChange("volume", (volume * 100).toDouble())
  }

  fun setPlaybackSpeed(speed: Float) {
    val clampedSpeed = speed.coerceIn(0.25f, 4f)
    exoPlayer?.setPlaybackSpeed(clampedSpeed)
    updateTunnelingState("speed changed")
    delegate?.onPropertyChange("speed", speed.toDouble())
  }

  fun selectAudioTrack(trackId: String) {
    val trackGroup = audioTrackGroupMap[trackId] ?: return
    val format = trackGroup.getFormat(0)
    updateAudioCodecForTunneling(format)

    applyTrackSelectorPolicy(
      reason = "audio track selected",
      audioOverride = TrackSelectionOverride(trackGroup, 0),
      audioDisabled = false
    )

    selectedAudioTrackId = trackId
    delegate?.onPropertyChange("aid", trackId)
  }

  fun selectSubtitleTrack(trackId: String?) {
    if (trackId == null || trackId == "no") {
      selectedSubtitleTrackId = "no"
      applyTrackSelectorPolicy(
        reason = "subtitle disabled",
        textDisabled = true
      )
      delegate?.onPropertyChange("sid", "no")
      return
    }

    val trackGroup = subtitleTrackGroupMap[trackId] ?: return
    selectedSubtitleTrackId = trackId
    applyTrackSelectorPolicy(
      reason = "subtitle track selected",
      textOverride = TrackSelectionOverride(trackGroup, 0),
      textDisabled = false
    )
    delegate?.onPropertyChange("sid", trackId)
  }

  fun addSubtitleTrack(uri: String, title: String?, language: String?, mimeType: String?, select: Boolean) {
    val existingIndex = externalSubtitleUris.indexOf(uri)
    val isNew = existingIndex < 0
    val index = if (isNew) externalSubtitles.size else existingIndex
    val formatId = "external_$index"

    if (isNew) {
      // SELECTION_FLAG_DEFAULT marks this as the preferred text track so ExoPlayer's
      // natural selection picks it on prepare. Avoids pinning the selector to a
      // specific TrackGroup override — if the URL 404s (e.g. stale Plex stream key),
      // ExoPlayer falls back to another available track (e.g. embedded SRT) instead
      // of leaving text disabled.
      val selectionFlags = if (select) C.SELECTION_FLAG_DEFAULT else 0
      val subtitleConfig = MediaItem.SubtitleConfiguration.Builder(Uri.parse(uri))
        .setId(formatId)
        .setLabel(title ?: "External")
        .setLanguage(language)
        .setMimeType(mimeType ?: detectSubtitleMimeType(uri))
        .setSelectionFlags(selectionFlags)
        .build()
      externalSubtitles.add(subtitleConfig)
      externalSubtitleUris.add(uri)
    }

    // Media3 only picks up MediaItem.SubtitleConfiguration at prepare() time
    // (tracking issue androidx/media #1649). When the caller wants this subtitle
    // activated immediately (e.g. after OpenSubtitles download), rebuild the
    // MediaItem and re-prepare with the position preserved.
    val player = exoPlayer
    val mediaUri = currentMediaUri
    if (select && player != null && mediaUri != null && !currentMediaIsLive) {
      if (isNew) {
        val savedPosition = player.currentPosition
        val savedPlayWhenReady = player.playWhenReady

        // Clear any stale text-type override (pointing at a pre-reload TrackGroup)
        // and re-enable the text type — mirrors the reset done in open(). Without
        // this, a previously-selected sub's override would either block the new
        // DEFAULT-flagged sub from winning or, if the new sub fails to load, keep
        // the text renderer stuck with no selection.
        applyTrackSelectorPolicy(
          reason = "external subtitle reload",
          clearTextOverrides = true,
          textDisabled = false
        )
        selectedSubtitleTrackId = null

        val mediaItem = buildMediaItem(mediaUri)
        player.setMediaItem(mediaItem, savedPosition)
        player.prepare()
        player.playWhenReady = savedPlayWhenReady
      } else {
        // Already attached — select the existing track via override.
        val trackId = subtitleTrackGroupMap.entries
          .firstOrNull { (_, group) -> group.getFormat(0).id == formatId }
          ?.key
        if (trackId != null) {
          selectSubtitleTrack(trackId)
        }
      }
    }

    if (isNew) emitTrackList()
  }

  private fun detectSubtitleMimeType(uri: String): String {
    // Strip query params before checking extension (Plex URLs have ?X-Plex-Token=...)
    val path = Uri.parse(uri).path?.lowercase() ?: uri.lowercase()
    return when {
      path.endsWith(".srt") -> MimeTypes.APPLICATION_SUBRIP
      path.endsWith(".ass") || path.endsWith(".ssa") -> MimeTypes.TEXT_SSA
      path.endsWith(".vtt") -> MimeTypes.TEXT_VTT
      path.endsWith(".ttml") -> MimeTypes.APPLICATION_TTML
      else -> MimeTypes.APPLICATION_SUBRIP
    }
  }

  fun setVisible(visible: Boolean) {
    if (disposing) return
    currentVisible = visible
    activity.runOnUiThread {
      if (disposing) return@runOnUiThread
      surfaceContainer?.visibility = if (visible) View.VISIBLE else View.INVISIBLE
      // subtitleView is inside surfaceContainer, inherits visibility
      Log.d(TAG, "setVisible($visible)")
    }
  }

  fun setSubtitleStyle(
    fontSize: Float,
    textColor: String,
    borderSize: Float,
    borderColor: String,
    bgColor: String,
    bgOpacity: Int,
    subtitlePosition: Int = 100,
    bold: Boolean = false,
    italic: Boolean = false
  ) {
    activity.runOnUiThread {
      // 1. Non-ASS subtitles: CaptionStyleCompat on SubtitleView
      val fgColor = Color.parseColor(textColor)
      val bgAlpha = (bgOpacity * 255 / 100)
      val bgColorInt = Color.parseColor(bgColor).let {
        Color.argb(bgAlpha, Color.red(it), Color.green(it), Color.blue(it))
      }
      val edgeColor = Color.parseColor(borderColor)
      val edgeType = if (borderSize > 0) {
        CaptionStyleCompat.EDGE_TYPE_OUTLINE
      } else {
        CaptionStyleCompat.EDGE_TYPE_NONE
      }

      val typefaceStyle = when {
        bold && italic -> Typeface.BOLD_ITALIC
        bold -> Typeface.BOLD
        italic -> Typeface.ITALIC
        else -> Typeface.NORMAL
      }
      val typeface = if (typefaceStyle != Typeface.NORMAL) {
        Typeface.create(Typeface.DEFAULT, typefaceStyle)
      } else {
        null
      }

      val style = CaptionStyleCompat(
        fgColor,
        bgColorInt,
        Color.TRANSPARENT,
        edgeType,
        edgeColor,
        typeface
      )
      subtitleView?.setStyle(style)
      // Font size: MPV sub-font-size is scaled pixels at 720p height
      // Convert to fractional size (0.0-1.0 relative to view height)
      val fraction = fontSize / 720f
      subtitleView?.setFractionalTextSize(fraction)

      // Subtitle position: adjust gravity and bottom padding
      val clampedPosition = subtitlePosition.coerceIn(0, 100)
      val gravity = when {
        clampedPosition <= 33 -> Gravity.TOP
        clampedPosition <= 66 -> Gravity.CENTER
        else -> Gravity.BOTTOM
      }
      (subtitleView?.layoutParams as? FrameLayout.LayoutParams)?.let { params ->
        params.gravity = gravity or Gravity.CENTER_HORIZONTAL
        subtitleView?.layoutParams = params
      }
      // Fine-grained positioning within bottom region via bottom padding fraction
      if (clampedPosition > 66) {
        val bottomFraction = (100 - clampedPosition) / 100f
        subtitleView?.setBottomPaddingFraction(bottomFraction)
      } else {
        subtitleView?.setBottomPaddingFraction(0f)
      }

      // 2. ASS subtitles: font scale via libass
      // MPV default sub-font-size is 38
      val defaultSize = 38f
      val scale = fontSize / defaultSize
      try {
        assHandler?.render?.setFontScale(scale)
      } catch (e: Exception) {
        Log.w(TAG, "Failed to set ASS font scale: ${e.message}")
      }

      Log.d(TAG, "setSubtitleStyle: fontSize=$fontSize, textColor=$textColor, borderSize=$borderSize, bgOpacity=$bgOpacity, position=$subtitlePosition, bold=$bold, italic=$italic, assScale=$scale")
    }
  }

  fun onPipModeChanged(isInPipMode: Boolean) {
    if (disposing) return
    activity.runOnUiThread {
      if (disposing) return@runOnUiThread
      // Force recalculation of surface size based on new container dimensions
      // Use a slight delay to allow the window to resize first
      handler.postDelayed({
        if (disposing) return@postDelayed
        val videoSize = exoPlayer?.videoSize
        if (videoSize != null && videoSize.width > 0 && videoSize.height > 0) {
          updateSurfaceViewSize(videoSize.width, videoSize.height, videoSize.pixelWidthHeightRatio)
        }
      }, 100)
    }
  }

  fun updateFrame() {
    if (disposing) return
    activity.runOnUiThread {
      if (disposing) return@runOnUiThread
      ensureFlutterOverlayOnTop()
      lastVideoSize?.let { videoSize ->
        if (videoSize.width > 0 && videoSize.height > 0) {
          updateSurfaceViewSize(videoSize.width, videoSize.height, videoSize.pixelWidthHeightRatio)
        }
      }
    }
  }

  // Audio Focus

  fun requestAudioFocus(): Boolean = audioFocusManager?.requestAudioFocus() ?: false

  fun abandonAudioFocus() {
    audioFocusManager?.abandonAudioFocus()
  }

  // Frame Rate Matching

  fun setVideoFrameRate(
    fps: Float,
    videoDurationMs: Long,
    extraDelayMs: Long,
    onComplete: (switched: Boolean) -> Unit
  ) {
    val mgr = frameRateManager
    if (mgr == null) {
      onComplete(false)
      return
    }
    mgr.setVideoFrameRate(fps, videoDurationMs, surfaceView?.holder?.surface, extraDelayMs, onComplete)
  }

  fun clearVideoFrameRate() {
    frameRateManager?.clearVideoFrameRate()
  }

  private fun computeFrameRate(timestamps: LongArray): Float {
    val deltas = (1 until FPS_SAMPLE_COUNT).map { timestamps[it] - timestamps[it - 1] }.filter { it > 0 }
    if (deltas.isEmpty()) return -1f
    val medianDelta = deltas.sorted()[deltas.size / 2]
    val rawFps = 1_000_000.0 / medianDelta
    return normalizeFrameRate(rawFps)
  }

  private fun normalizeFrameRate(fps: Double): Float {
    val knownRates = doubleArrayOf(23.976, 24.0, 25.0, 29.97, 30.0, 48.0, 50.0, 59.94, 60.0)
    val nearest = knownRates.minByOrNull { kotlin.math.abs(it - fps) } ?: fps
    return if (kotlin.math.abs(nearest - fps) < 0.5) nearest.toFloat() else fps.toFloat()
  }

  // Stats

  fun getStats(): Map<String, Any?> {
    val player = exoPlayer ?: return emptyMap()
    val videoFormat = player.videoFormat
    val audioFormat = player.audioFormat

    // Get decoder info from the format's codecs field and check if hardware accelerated
    val videoDecoderInfo = getVideoDecoderInfo(videoFormat)

    return mapOf(
      // Video metrics
      "videoCodec" to videoFormat?.codecs,
      "videoMimeType" to videoFormat?.sampleMimeType,
      "videoWidth" to videoFormat?.width,
      "videoHeight" to videoFormat?.height,
      "videoFps" to (videoFormat?.frameRate?.takeIf { it > 0 } ?: detectedFrameRate.takeIf { it > 0 }),
      "videoBitrate" to videoFormat?.bitrate,
      "videoDecoderName" to (decoderInitName ?: videoDecoderInfo),
      "videoDroppedFrames" to player.videoDecoderCounters?.droppedBufferCount,
      "videoRenderedFrames" to player.videoDecoderCounters?.renderedOutputBufferCount,
      // Color info
      "colorSpace" to videoFormat?.colorInfo?.colorSpace,
      "colorRange" to videoFormat?.colorInfo?.colorRange,
      "colorTransfer" to videoFormat?.colorInfo?.colorTransfer,
      "hdrStaticInfo" to (videoFormat?.colorInfo?.hdrStaticInfo != null),
      // Audio metrics
      "audioCodec" to audioFormat?.codecs,
      "audioMimeType" to audioFormat?.sampleMimeType,
      "audioSampleRate" to audioFormat?.sampleRate,
      "audioChannels" to audioFormat?.channelCount,
      "audioBitrate" to audioFormat?.bitrate,
      "audioDecoderName" to audioDecoderInitName,
      // Tunneling
      "tunneledPlayback" to currentTunneledPlayback,
      "tunnelingStatus" to getTunnelingStatus(player),
      // Buffer metrics
      "bufferedPositionMs" to player.bufferedPosition,
      "currentPositionMs" to player.currentPosition,
      "totalBufferedDurationMs" to player.totalBufferedDuration,
      // Playback state
      "playbackSpeed" to player.playbackParameters.speed,
      "isPlaying" to player.isPlaying,
      "playbackState" to player.playbackState,
      // DV conversion (query extractor's track output, which is set during extraction)
      *(
        activeDoviMkvWrapper?.doviTrackOutput
          ?: activeDoviMp4Wrapper?.doviTrackOutput
        ).let { dovi ->
        arrayOf(
          "dvConversionActive" to (dovi?.conversionActive == true),
          "dvConversionMode" to dvMode.name,
          "dvConversionDebugMode" to (debugDvModeOverride?.name ?: "AUTO"),
          "dvStrippedInitNals" to (dovi?.strippedInitNalCount ?: 0L),
          "dvStrippedNals" to (dovi?.strippedNalCount ?: 0L),
          "dvConvertedRpus" to (dovi?.convertedRpuCount ?: 0L),
          "dvRpuConversionFailures" to (dovi?.rpuConversionFailureCount ?: 0L),
          "dvRpuOutputTooSmall" to (dovi?.rpuOutputTooSmallCount ?: 0L),
          "dvAvgRpuConversionUs" to (dovi?.averageRpuConversionTimeUs ?: 0L),
          "dvAvgSampleProcessingUs" to (dovi?.averageSampleProcessingTimeUs ?: 0L)
        )
      }
    )
  }

  private fun getVideoDecoderInfo(videoFormat: androidx.media3.common.Format?): String? {
    if (videoFormat == null) return null
    val mimeType = videoFormat.sampleMimeType ?: return null

    // Check available decoders for this mime type
    try {
      val codecList = android.media.MediaCodecList(android.media.MediaCodecList.ALL_CODECS)
      for (info in codecList.codecInfos) {
        if (info.isEncoder) continue
        for (type in info.supportedTypes) {
          if (type.equals(mimeType, ignoreCase = true)) {
            // Return the first hardware decoder found, or software if none
            val name = info.name
            if (!name.startsWith("OMX.google.") && !name.contains(".sw.")) {
              return name // Hardware decoder
            }
          }
        }
      }
      // Fallback - assume software if no HW decoder found
      return "Software"
    } catch (e: Exception) {
      return null
    }
  }

  private fun getTunnelingStatus(player: ExoPlayer): String {
    if (currentTunneledPlayback) return "Active"
    if (!tunnelingUserEnabled) return "Disabled by user"
    if (player.playbackParameters.speed != 1f) return "Off (speed ≠ 1×)"
    if (tunnelingDisabledForDecodedTrueHdPcm) return "Off (decoded TrueHD PCM)"
    if (tunnelingDisabledForVideoCodec) return "Off (video codec unsupported)"
    if (tunnelingDisabledForAudioCodec) return "Off (no HW audio decoder)"
    return "Off"
  }

  fun triggerFallback() {
    val uri = currentMediaUri ?: return
    val pos = exoPlayer?.currentPosition ?: 0L
    delegate?.onFormatUnsupported(uri, currentHeaders, pos, "debug: manual fallback trigger")
  }

  // Cleanup

  fun dispose() {
    if (disposing) return
    disposing = true
    check(Looper.myLooper() == Looper.getMainLooper())
    Log.d(TAG, "Disposing")

    stopFrameWatchdog()
    cancelDecoderHangCheck()
    stopPositionUpdates()
    handler.removeCallbacksAndMessages(null)
    // releasePending (not clearVideoFrameRate): on the ExoPlayer→MPV fallback
    // path, dispose runs after the rate switch has been applied — clearing
    // preferredDisplayModeId here would renegotiate HDMI back to default
    // before MPV's surface comes up. Explicit user-leave still calls
    // clearVideoFrameRate via Dart (video_player_screen.dart).
    frameRateManager?.releasePending()
    frameRateManager = null
    audioFocusManager?.release()
    audioFocusManager = null

    decoderInitName = null
    audioDecoderInitName = null
    tunnelingDisabledForAudioCodec = false
    tunnelingDisabledForVideoCodec = false
    tunnelingDisabledForDecodedTrueHdPcm = false
    currentTunneledPlayback = false
    pendingStartPositionMs = 0L
    pendingPlayWhenReady = null
    currentMediaIsLive = false
    currentVisible = false
    emitSeekable(false, force = true)
    selectedAudioTrackId = null
    selectedSubtitleTrackId = null
    pendingDvTrackRestore = null
    audioTrackGroupMap.clear()
    subtitleTrackGroupMap.clear()
    exoPlayer?.clearVideoSurface()
    exoPlayer?.removeListener(this)
    exoPlayer?.release()
    exoPlayer = null
    renderersFactory = null
    trackSelector = null
    httpDataSourceFactory = null
    dataSourceFactory = null
    assHandler?.release()
    assHandler = null

    // Capture locals for deferred cleanup
    val cb = surfaceCallback
    val sv = surfaceView
    val container = surfaceContainer
    val contentView = activity.findViewById<ViewGroup>(android.R.id.content)

    // Synchronous ownership invalidation — stale code can no longer
    // reach surface state through instance fields.
    surfaceContainer = null
    videoAspectContainer = null
    surfaceView = null
    subtitleView = null

    // Remove layout listener synchronously
    overlayLayoutListener?.let { listener ->
      contentView.viewTreeObserver.removeOnGlobalLayoutListener(listener)
    }
    overlayLayoutListener = null

    isInitialized = false

    // Deferred view removal only — uses captured locals.
    // postAtFrontOfQueue as defense-in-depth: orders removal before
    // queued initialize messages.
    Handler(Looper.getMainLooper()).postAtFrontOfQueue {
      sv?.holder?.removeCallback(cb)
      if (container?.parent != null) {
        contentView.removeView(container)
      }
    }

    Log.d(TAG, "Disposed")
  }
}
