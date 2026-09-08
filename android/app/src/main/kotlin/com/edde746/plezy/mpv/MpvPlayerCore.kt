package com.edde746.plezy.mpv

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Surface
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import com.edde746.plezy.exoplayer.DoviBridge
import com.edde746.plezy.libmpv.*
import com.edde746.plezy.shared.AudioFocusManager
import com.edde746.plezy.shared.FrameRateManager
import com.edde746.plezy.shared.GlCapabilities
import com.edde746.plezy.shared.MediaCodecQuery
import com.edde746.plezy.shared.PlayerDelegate
import com.edde746.plezy.shared.PlayerSurfaceHost
import com.edde746.plezy.shared.SurfacePlayerCore
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import kotlinx.coroutines.*
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
/**
 * mpv playback core. Two modes:
 * - Video (default): [context] is the host Activity, which is needed for the
 *   SurfaceView/window hierarchy, display refresh-rate reads and frame-rate
 *   matching.
 * - Audio-only ([audioOnly]): the music core. Built on the application
 *   context (no Activity dependency, so it survives activity teardown);
 *   never creates a surface, view, or frame-rate manager, and mpv is
 *   configured before init to never open a video output (`vid=no`,
 *   `force-window=no`, `audio-display=no`, plus `gapless-audio=weak`).
 */
class MpvPlayerCore private constructor(
  private val context: Context,
  private val audioOnly: Boolean,
  private val hardwareDecoding: Boolean,
  /** Subtitle "Render Resolution" as a fraction of the OSD plane's view size; see [OsdPlanePolicy]. */
  private val osdRenderScale: Float,
  private val initialLogLevel: String,
  private val propertyWriterOverride: (suspend (String, String) -> Unit)?,
  /**
   * Test seam standing in for the native player's command path: returns what
   * [MpvPlayer.command] would (the playlist entry id of a `loadfile`, else
   * null) or throws to reject the command. Null keeps the production rule
   * that a command without a native player fails.
   */
  private val commandRunnerOverride: (suspend (Array<String>) -> Long?)?,
  initializedForTesting: Boolean
) : SurfaceHolder.Callback,
  SurfacePlayerCore {
  constructor(
    context: Context,
    audioOnly: Boolean = false,
    hardwareDecoding: Boolean = true,
    osdRenderScale: Float = 1f,
    initialLogLevel: String = "warn"
  ) : this(context, audioOnly, hardwareDecoding, osdRenderScale, initialLogLevel, null, null, false)

  internal constructor(
    context: Context,
    audioOnly: Boolean,
    propertyWriter: (suspend (String, String) -> Unit)?
  ) : this(context, audioOnly, true, 1f, "warn", propertyWriter, null, true)

  internal constructor(
    context: Context,
    audioOnly: Boolean,
    propertyWriter: (suspend (String, String) -> Unit)?,
    commandRunner: suspend (Array<String>) -> Long?
  ) : this(context, audioOnly, true, 1f, "warn", propertyWriter, commandRunner, true)

  companion object {
    private const val TAG = "MpvPlayerCore"
    private const val SURFACE_HANDOFF_TIMEOUT_MS = 2_000L

    /**
     * The initial `vo` chain, decided by whether this session will hardware-
     * decode.
     *
     * Hardware sessions use the fork vo=mediacodec: decoded buffers go from
     * MediaCodec straight to the compositor with per-frame presentation
     * timestamps - no GLES pass, 10-bit and the decoder's dataspace
     * (HDR10/HLG) intact - and subtitles/OSD render on the sibling OSD
     * surface. The plane takes decoder buffers only and refuses the rest, so
     * a per-file decode fallback moves to a GL vo
     * ([GpuVoPolicy.needsSoftwareRender], with the chain-failure watchdog as
     * the backstop). gpu stays in the chain for preinit failure.
     *
     * Software sessions run gpu,gpu-next: gpu is the battle-tested GLES
     * renderer on the Android device zoo, and with film grain applied by the
     * decoder nothing else on this path needs libplacebo. Dolby Vision RPU
     * reshaping (#1902) is the one exception - it needs gpu-next, and the
     * [GpuVoPolicy.REASON_DV_RESHAPE] observer moves the session there when a
     * DV profile that needs reshaping appears. gpu-next under *hardware*
     * decode is broken on Tegra (samplerExternalOES double declaration
     * rejected by the GLES linker, blue screen on the Shield, #2010);
     * vo=mediacodec sidesteps that entire class by never touching GLES.
     */
    internal fun initialVideoOutput(hardwareDecoding: Boolean): String = if (hardwareDecoding) "mediacodec,gpu" else "gpu,gpu-next"

    /**
     * The `-append` list-option suffixes are not exposed through the property
     * interface, so the app's decoder options replace the whole list. FFmpeg
     * keeps the last duplicate key, so any user mpv.conf entries go first.
     */
    internal fun mergeDecoderOptions(current: String?, ours: String): String = if (current.isNullOrBlank()) ours else "$current,$ours"

    /**
     * Whether content with this transfer is worth an HDR (BT.2020 PQ) GL
     * surface. PQ and HLG both render into a PQ target; everything else -
     * including unknown - stays on the default sRGB surface, which renders
     * every content correctly (HDR arrives tone-mapped, as before).
     */
    internal fun wantsHdrSurface(transfer: String?): Boolean = transfer == "smpte2084" || transfer == "arib-std-b67"
  }

  /** Video-only paths. The plugin always constructs video cores with the
   * host Activity, and audio-only mode never touches these paths. */
  private val activity: Activity
    get() = context as Activity

  private var surfaceView: SurfaceView? = null
  private var osdSurfaceView: SurfaceView? = null
  private var surfaceContainer: android.widget.FrameLayout? = null

  @Volatile private var pendingOsdSurface: Surface? = null

  @Volatile private var attachedOsdSurface: Surface? = null

  /** Active reasons the session must render off the plane. */
  private val gpuVoReasons = LinkedHashSet<String>()

  /** The GL vo requested by the arbiter, or null for the video plane.
   * Written under [gpuVoReasons]. */
  @Volatile private var activeGpuVoTarget: String? = null

  /** Native renderer last installed under [videoOutputMutex]. Surface callbacks
   * must follow its ownership, not a request still waiting for an OSD surface. */
  @Volatile private var appliedGpuVoTarget: String? = null

  /** Per-file reasons holding hwdec at `no` (DV P5 reshaping or unsupported
   * hardware decoding); the session's own hwdec value is parked in
   * [parkedHwdec] while any is active. Written under itself. */
  private val hwdecHoldReasons = LinkedHashSet<String>()

  @Volatile private var hwdecHeld: Boolean = false

  private val parkedHwdec = java.util.concurrent.atomic.AtomicReference<String?>()

  /** Whether the missing `pending-vid` property was logged; hook-serial. */
  private var pendingVidUnavailableLogged = false

  /** mpv option -> the default it carried before the cheap render tier
   * replaced it; empty while the tier is off. See [applyRenderTier]. */
  private val cheapRenderRestore = LinkedHashMap<String, String>()

  @Volatile private var cheapRenderTierActive: Boolean = false

  /** Last `dv-conversion-mode` Dart applied; input to the per-file DV
   * routing policy. */
  @Volatile private var currentDvConversionMode: String = "auto"

  /** Whether this core already decided its GL surface colorspace; set by the
   * first `content-color-transfer` announcement ([applyContentColorTransfer]). */
  @Volatile private var hdrSurfaceDecided: Boolean = false

  /** Whether this session outputs HDR to an HDR-capable display — via the PQ
   * GL surface or the MediaCodec plane's decoder dataspace. Gates the
   * deferred display-mode restore on teardown (see
   * [FrameRateManager.clearVideoFrameRate]). */
  @Volatile private var hdrDisplayActive: Boolean = false

  @Volatile private var videoDisplayWidth: Int = 0

  @Volatile private var videoDisplayHeight: Int = 0

  /** Latest `panscan` (0..1) and `video-zoom` (log2) the app applied. The
   * plane owns scaling, so these are view geometry here; see
   * [applyVideoRectLayout]. */
  @Volatile private var videoPanscan: Float = 0f

  @Volatile private var videoZoomLog2: Float = 0f

  private data class VideoRectUpdate(val epoch: Long, val rect: VideoRectPolicy.Rect)

  /** Latest main-thread layout request; queued writers discard superseded snapshots. */
  private val pendingVideoRectUpdate = AtomicReference<VideoRectUpdate?>()

  /** Hardware sessions render through the fork vo=mediacodec (see
   * [initialVideoOutput]); the OSD surface and video-rect layout exist only
   * there. */
  private val usesMediaCodecVo: Boolean
    get() = !audioOnly && hardwareDecoding
  private var overlayLayoutListener: ViewTreeObserver.OnGlobalLayoutListener? = null

  @Volatile private var disposing: Boolean = false
  private var nativeDisposalComplete: CountDownLatch? = null

  @Volatile private var pendingSurface: Surface? = null

  @Volatile private var attachedSurface: Surface? = null
  private var placeholder: MpvPlaceholderSurface? = null

  @Volatile private var placeholderSurface: Surface? = null

  @Volatile private var lastAppliedSurfaceSize: String? = null

  @Volatile private var lastKnownSurfaceWidth: Int = 0

  @Volatile private var lastKnownSurfaceHeight: Int = 0
  var delegate: PlayerDelegate? = null
  var isInitialized: Boolean = false
    private set

  init {
    if (initializedForTesting) isInitialized = true
  }

  @Volatile private var player: MpvPlayer? = null
  private var scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
  private val endFileDiagnostics = MpvEndFileDiagnostics()

  // mpv writes must stay off the main thread but run in submission order:
  // setupMpvFallback sets vo/ao/hwdec immediately before the loadfile command,
  // and an unordered pool can run loadfile first, leaving mpv with no video
  // output (#1482).
  private val mpvWriteDispatcher = Dispatchers.IO.limitedParallelism(1)

  private var frameRateManager: FrameRateManager? = null
  private val handler = Handler(Looper.getMainLooper())

  // Result-callback marshaling. Separate from [handler], whose queued
  // messages dispose() clears — pending method-channel results must still
  // complete after dispose.
  private val mainHandler = Handler(Looper.getMainLooper())

  /** Same semantics as Activity.runOnUiThread, without needing an Activity. */
  private fun runOnMain(block: () -> Unit) {
    if (Looper.myLooper() == Looper.getMainLooper()) block() else mainHandler.post(block)
  }

  private var audioFocusManager: AudioFocusManager? = null

  @Volatile private var cachedPaused: Boolean = true

  @Volatile private var desiredPaused: Boolean = true

  @Volatile private var pausedForSurfaceLoss: Boolean = false

  @Volatile private var pausedForAudioFocusLoss: Boolean = false

  @Volatile private var hasAttachedSurface: Boolean = false

  @Volatile private var attachedToPlaceholder: Boolean = false

  @Volatile private var videoOutputRestoring: Boolean = false

  @Volatile private var videoOutputFailure: Exception? = null

  @Volatile private var deferredResumeRequested: Boolean = false

  @Volatile private var resumeBlockedByPublicPause: Boolean = false

  private data class PublicPauseIntent(
    val generation: Long,
    val previousBlocked: Boolean,
    val previousDesiredPaused: Boolean
  )

  private val publicPauseIntentLock = Any()
  private var publicPauseIntentGeneration = 0L
  private val publicPauseWriteMutex = Mutex()

  @Volatile private var videoOutputEpoch: Long = 0L
  private val videoOutputMutex = Mutex()
  private var pendingVideoOutputRefreshJob: Job? = null

  private var flutterOverlayApplied = false

  private fun ensureFlutterOverlayOnTop() {
    if (audioOnly || disposing || flutterOverlayApplied) return
    val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
    contentView.post {
      if (disposing || !isInitialized) return@post
      flutterOverlayApplied = PlayerSurfaceHost.ensureFlutterOverlayOnTop(contentView, surfaceContainer)
    }
  }

  @Suppress("DEPRECATION")
  private fun currentDisplayFpsOverride(): String? {
    if (audioOnly) return null
    val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
      activity.display
    } else {
      activity.windowManager.defaultDisplay
    }
    val refreshRate = display?.mode?.refreshRate ?: return null
    if (refreshRate <= 0f) return null
    return refreshRate.toString()
  }

  private fun updateDisplayFpsOverride(p: MpvPlayer, reason: String, onComplete: () -> Unit = {}) {
    val fps = currentDisplayFpsOverride()
    if (fps == null) {
      Log.d(TAG, "Skipping display-fps-override update ($reason): no display rate")
      onComplete()
      return
    }
    if (!scope.isActive) {
      onComplete()
      return
    }

    scope.launch(mpvWriteDispatcher) {
      try {
        p.setProperty("display-fps-override", fps)
        Log.d(TAG, "Updated display-fps-override=$fps ($reason)")
      } catch (e: Exception) {
        Log.w(TAG, "Failed to update display-fps-override ($reason)", e)
      } finally {
        withContext(NonCancellable + Dispatchers.Main) {
          onComplete()
        }
      }
    }
  }

  fun initialize(onResult: (Boolean) -> Unit) {
    if (isInitialized) {
      Log.d(TAG, "Already initialized")
      onResult(true)
      return
    }

    try {
      disposing = false
      endFileDiagnostics.onStartFile()
      cachedPaused = true
      desiredPaused = true
      pausedForSurfaceLoss = false
      pausedForAudioFocusLoss = false
      pendingSurface = null
      attachedSurface = null
      attachedToPlaceholder = false
      hasAttachedSurface = false
      videoOutputRestoring = false
      videoOutputFailure = null
      deferredResumeRequested = false
      synchronized(publicPauseIntentLock) {
        publicPauseIntentGeneration += 1L
        resumeBlockedByPublicPause = false
      }
      videoOutputEpoch = 0L
      lastAppliedSurfaceSize = null
      lastKnownSurfaceWidth = 0
      lastKnownSurfaceHeight = 0
      // Video-output state, so a re-initialized core does not start stranded
      // off the plane with a stale reason set.
      synchronized(gpuVoReasons) {
        gpuVoReasons.clear()
        activeGpuVoTarget = null
      }
      appliedGpuVoTarget = null
      synchronized(hwdecHoldReasons) {
        hwdecHoldReasons.clear()
        hwdecHeld = false
      }
      parkedHwdec.set(null)
      synchronized(cheapRenderRestore) {
        cheapRenderRestore.clear()
        cheapRenderTierActive = false
      }
      attachedOsdSurface = null
      videoDisplayWidth = 0
      videoDisplayHeight = 0
      videoPanscan = 0f
      videoZoomLog2 = 0f
      pendingVideoRectUpdate.set(null)
      currentDvConversionMode = "auto"
      hdrSurfaceDecided = false
      hdrDisplayActive = false

      // Initialize audio focus handling. mpv has none built in, so both modes
      // use the shared manager: pause on (transient) loss, auto-resume on
      // regain when the loss interrupted active playback.
      audioFocusManager = AudioFocusManager(
        context = context,
        handler = handler,
        contentType = if (audioOnly) AudioAttributes.CONTENT_TYPE_MUSIC else AudioAttributes.CONTENT_TYPE_MOVIE,
        onPause = {
          pauseForAudioFocusLoss()
        },
        onResume = {
          resumeAfterAudioFocusGain("audio focus gain")
        },
        isPaused = { desiredPaused }
      )
      if (!audioOnly) {
        frameRateManager = FrameRateManager(
          activity = activity,
          handler = handler,
          log = { emitLog("info", "framerate", it) }
        )

        surfaceContainer = PlayerSurfaceHost.createContainer(activity)
        surfaceView = PlayerSurfaceHost.createVideoSurface(activity, this@MpvPlayerCore)
        surfaceContainer!!.addView(surfaceView)
        if (usesMediaCodecVo) {
          osdSurfaceView = PlayerSurfaceHost.createOsdSurface(activity, osdSurfaceCallback, osdRenderScale)
          surfaceContainer!!.addView(osdSurfaceView)
        }

        val contentView = PlayerSurfaceHost.attachToContent(activity, surfaceContainer!!)
        flutterOverlayApplied = PlayerSurfaceHost.ensureFlutterOverlayOnTop(contentView, surfaceContainer)
        ensureFlutterOverlayOnTop()
        overlayLayoutListener = ViewTreeObserver.OnGlobalLayoutListener {
          ensureFlutterOverlayOnTop()
          val sv = surfaceView
          if (sv != null) applySurfaceSize(sv.width, sv.height)
          applyVideoRectLayout()
        }
        contentView.viewTreeObserver.addOnGlobalLayoutListener(overlayLayoutListener)

        Log.d(TAG, "SurfaceView added to content view")
      }

      scope.launch {
        try {
          if (!audioOnly) {
            // Cancellation must not lose an EGL consumer created on its GL thread.
            withContext(NonCancellable) {
              val created = MpvPlaceholderSurface.create()
              if (disposing) {
                created.close()
              } else {
                placeholder = created
                placeholderSurface = created.surface
              }
            }
          }
          if (disposing) {
            onResult(false)
            return@launch
          }
          val displayFpsOverride = currentDisplayFpsOverride()
          // Both core kinds cap their demuxer cache off the device heap class;
          // rationale on DemuxerBudget. Null (unknown class) keeps mpv defaults.
          val demuxerBudget = DemuxerBudget.forHeapClassMB(
            (context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager)?.largeMemoryClass ?: 0
          )
          val p = MpvPlayer.create(context.applicationContext) {
            setLogLevel(initialLogLevel)
            if (audioOnly) {
              // Pure audio core (all set before mpv_initialize, mirroring the
              // Windows/Linux audio instances): vid=no keeps embedded cover
              // art from ever becoming a video track, force-window and
              // audio-display make sure mpv never opens a video output for
              // it, and gapless-audio splices the pre-armed next playlist
              // entry into the running audio stream.
              setOption("vid", "no")
              setOption("force-window", "no")
              setOption("audio-display", "no")
              setOption("gapless-audio", "weak")
            } else {
              // vo choice is decode-path-dependent; rationale on
              // initialVideoOutput.
              setOption("vo", initialVideoOutput(hardwareDecoding))
              setOption("gpu-context", "android")
              setOption("opengl-es", "yes")
              // Keep AV1 film grain inside the decoder (dav1d). `auto` hands it
              // to any vo claiming VO_CAP_FILM_GRAIN, and gpu-next claims it on
              // GLES where libplacebo's raster grain fallback fetches luma by
              // fragcoord (bottom-up) but chroma by uv: the luma renders
              // upside-down (measured on a Shield Pro; desktop GL is unaffected
              // because grain runs as a compute pass there).
              setOption("vd-lavc-film-grain", "cpu")
              if (displayFpsOverride != null) {
                setOption("display-fps-override", displayFpsOverride)
              }
            }
            if (demuxerBudget != null) {
              setOption("demuxer-max-bytes", demuxerBudget.aheadBytes.toString())
              setOption("demuxer-max-back-bytes", demuxerBudget.backBytes.toString())
            }
            setOption("ao", "audiotrack,opensles")
            // Pause on the last frame at EOF instead of unloading the file, so a
            // seek after the video ends still works (matches Linux/Windows).
            setOption("keep-open", "yes")
            // Plezy only ever opens media-server streams and local files, so
            // mpv's bundled ytdl_hook has nothing to resolve: it costs an
            // on_load hook per open and, on a failed open, spawns yt-dlp with
            // the access token in its argv. mpv decides whether to load the
            // builtin script during mpv_initialize, hence an option here.
            setOption("ytdl", "no")
          }
          if (demuxerBudget != null) {
            Log.d(
              TAG,
              "Demuxer budget: ${demuxerBudget.aheadBytes / (1024 * 1024)}MB ahead, " +
                "${demuxerBudget.backBytes / (1024 * 1024)}MB back"
            )
          }
          if (displayFpsOverride != null) {
            Log.d(TAG, "Initial display-fps-override=$displayFpsOverride")
          }

          if (disposing) {
            // dispose() can win after create's IO block but before this main-thread
            // continuation. Native destruction is blocking, so finish it on IO too.
            withContext(NonCancellable + Dispatchers.IO) {
              p.close()
            }
            onResult(false)
            return@launch
          }

          player = p
          isInitialized = true
          if (usesMediaCodecVo) {
            // Per-file decode routing runs inside mpv's on_preloaded hook:
            // the demuxer has opened the file, no decoder exists yet, and
            // mpv waits for the answer. file-loaded would be too late — the
            // MediaCodec decoder is already created by then (#2065). Nothing
            // is selected yet either, so the track both policies decide for
            // is resolved once here, from mpv's pending selection.
            p.hookHandler = { name ->
              if (name == "on_preloaded" && !disposing) {
                withContext(mpvWriteDispatcher) {
                  val track = pendingVideoTrack(p)
                  applyDvReshapePolicy(p, track)
                  applySoftwareDecodePolicy(p, track)
                }
              }
            }
          }

          if (!audioOnly) refreshVideoOutput("initialize")
          if (!usesMediaCodecVo && !audioOnly) {
            // vo=gpu from the start (hardware decoding off): same tier
            // decision the plane sessions make when they leave the plane.
            scope.launch(mpvWriteDispatcher, start = CoroutineStart.ATOMIC) {
              try {
                applyRenderTier(p, glVoActive = true)
              } catch (e: CancellationException) {
                Log.d(TAG, "Canceled render tier setup")
              } catch (e: Exception) {
                Log.w(TAG, "Render tier setup failed", e)
              }
            }
          }

          // Start collecting events/properties/logs
          collectEvents(p)
          collectPropertyChanges(p)
          collectLogMessages(p)
          if (usesMediaCodecVo) {
            collectVideoDimensions(p)
            collectShaderState(p)
            collectHdrToneMapState(p)
            collectDecoderState(p)
          }

          Log.d(TAG, "Initialized successfully")
          onResult(true)
        } catch (e: Exception) {
          Log.e(TAG, "Failed to initialize native: ${e.message}", e)
          onResult(false)
        }
      }
    } catch (e: Exception) {
      Log.e(TAG, "Failed to initialize: ${e.message}", e)
      onResult(false)
    }
  }

  // Flow collectors

  private fun emitLog(level: String, prefix: String, text: String) {
    delegate?.onEvent(
      "log-message",
      mapOf(
        "prefix" to prefix,
        "level" to level,
        "text" to text
      )
    )
  }

  private fun lifecycleData(
    sourceId: Long?,
    positionSeconds: Double? = null
  ): Map<String, Any>? {
    if (sourceId == null && positionSeconds == null) return null
    return buildMap {
      sourceId?.let { put("sourceId", it) }
      positionSeconds?.let { put("positionSeconds", it) }
    }
  }

  private fun collectEvents(p: MpvPlayer) {
    scope.launch(start = CoroutineStart.UNDISPATCHED) {
      p.eventFlow.collect { event ->
        when (event) {
          is MpvEvent.EndFile -> {
            delegate?.onEvent("end-file", endFileDiagnostics.onEndFile(event))
          }
          is MpvEvent.StartFile -> {
            endFileDiagnostics.onStartFile()
            // Both triggers are per-file (an exotic pixel format, a gralloc
            // refusal, mpv's own decode fallback for that stream), so give
            // the plane back to the next file. A genuine failure re-arms
            // them, costing one switch per bad file instead of the whole
            // session's HDR/10-bit scanout.
            setGpuVoRequirement(GpuVoPolicy.REASON_CHAIN_FAILURE, false)
            setGpuVoRequirement(GpuVoPolicy.REASON_SW_DECODE, false)
            delegate?.onEvent("start-file", lifecycleData(event.sourceId))
          }
          is MpvEvent.FileLoaded -> {
            delegate?.onEvent("file-loaded", lifecycleData(event.sourceId))
          }
          is MpvEvent.PlaybackRestart -> {
            delegate?.onEvent(
              "playback-restart",
              lifecycleData(event.sourceId, event.positionSeconds)
            )
          }
        }
      }
    }
  }

  private fun collectPropertyChanges(p: MpvPlayer) {
    scope.launch(start = CoroutineStart.UNDISPATCHED) {
      p.propertyFlow.collect { change ->
        // Skip None — matches old MPVLib behavior where eventProperty(name)
        // with no value was a no-op. Forwarding null would incorrectly clear
        // track selections (aid/sid) before the file loads.
        if (change is PropertyChange.None) return@collect
        val value: Any? = when (change) {
          is PropertyChange.Flag -> change.value
          is PropertyChange.Int64 -> change.value
          is PropertyChange.Double -> change.value
          is PropertyChange.Str -> change.value
          is PropertyChange.None -> null
        }
        if (change.name == "pause" && change is PropertyChange.Flag) {
          cachedPaused = change.value
        }
        delegate?.onPropertyChange(change.name, value, change.sourceId)
      }
    }
  }

  private fun collectLogMessages(p: MpvPlayer) {
    scope.launch(start = CoroutineStart.UNDISPATCHED) {
      p.logFlow.collect { msg ->
        endFileDiagnostics.onLogMessage(msg)
        // A chain-init failure is the one runtime signal that frames cannot
        // reach the video plane at all (exotic pixel formats, gralloc
        // refusal). mpv is pinned in the fork, so the log line is a stable
        // contract.
        if (usesMediaCodecVo &&
          activeGpuVoTarget == null &&
          msg.prefix.startsWith("cplayer") &&
          msg.text.contains("Could not initialize video chain")
        ) {
          Log.w(TAG, "Video chain init failed under vo=mediacodec; leaving the video plane")
          setGpuVoRequirement(GpuVoPolicy.REASON_CHAIN_FAILURE, true)
        }
        emitLog(msg.level.name.lowercase(), msg.prefix, msg.text)
      }
    }
  }

  // Audio Focus

  override fun requestAudioFocus(): Boolean {
    val granted = audioFocusManager?.requestAudioFocus() ?: false
    if (granted && pausedForAudioFocusLoss) {
      resumeAfterAudioFocusGain("audio focus request granted")
    }
    return granted
  }

  override fun abandonAudioFocus() {
    audioFocusManager?.abandonAudioFocus()
  }

  // SurfaceHolder.Callback

  override fun surfaceCreated(holder: SurfaceHolder) {
    Log.d(TAG, "Surface created")
    if (disposing) return

    val surface = holder.surface
    pendingSurface = surface.takeIf { it.isValid }
    videoOutputEpoch += 1L
    rememberCurrentSurfaceSize()
    if (player == null) {
      Log.d(TAG, "Deferring video output refresh until MPV init completes")
      return
    }

    refreshVideoOutput("surfaceCreated")
  }

  override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
    Log.d(TAG, "Surface changed: ${width}x$height")
    rememberSurfaceSize(width, height)
    refreshVideoOutput("surfaceChanged")
  }

  override fun surfaceDestroyed(holder: SurfaceHolder) {
    Log.d(TAG, "Surface destroyed")
    pendingSurface = null
    if (disposing) {
      awaitNativeDisposal()
      return
    }
    if (player == null) return
    handoffDestroyedSurface("surfaceDestroyed", videoLost = true)
  }

  // OSD surface (the vo=mediacodec subtitle/OSD plane)

  private val osdSurfaceCallback = object : SurfaceHolder.Callback {
    override fun surfaceCreated(holder: SurfaceHolder) {
      if (disposing) return
      pendingOsdSurface = holder.surface.takeIf { it.isValid }
      Log.d(TAG, "OSD surface created")
      videoOutputEpoch += 1L
      if (player != null && currentCandidateSurface() != null) {
        refreshVideoOutput("osdSurfaceCreated")
      }
      if (activeGpuVoTarget != appliedGpuVoTarget) applyGpuVoTarget()
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
      // width/height are buffer pixels, not the OSD view's reference viewport.
      applyVideoRectLayout(force = true)
    }

    override fun surfaceDestroyed(holder: SurfaceHolder) {
      Log.d(TAG, "OSD surface destroyed")
      pendingOsdSurface = null
      if (disposing) {
        awaitNativeDisposal()
        return
      }
      if (player == null) return
      // Rebuild the VO without this plane before Android invalidates it.
      // Keep the video target: hiding the OSD when switching to GPU output
      // is not a loss of the video surface and must not pause playback.
      handoffDestroyedSurface("osdSurfaceDestroyed", videoLost = false)
    }
  }

  private fun collectVideoDimensions(p: MpvPlayer) {
    scope.launch(start = CoroutineStart.UNDISPATCHED) {
      p.observeInt("dwidth").collect { value ->
        val w = value.toInt()
        if (w > 0 && w != videoDisplayWidth) {
          videoDisplayWidth = w
          applyVideoRectLayout()
        }
      }
    }
    scope.launch(start = CoroutineStart.UNDISPATCHED) {
      p.observeInt("dheight").collect { value ->
        val h = value.toInt()
        if (h > 0 && h != videoDisplayHeight) {
          videoDisplayHeight = h
          applyVideoRectLayout()
        }
      }
    }
  }

  /**
   * Arbiter for this session's video output: the active [GpuVoPolicy] reasons
   * decide whether the session runs on the video plane or on a GL vo.
   */
  private fun setGpuVoRequirement(reason: String, active: Boolean) {
    if (!usesMediaCodecVo || disposing) return
    val transition = synchronized(gpuVoReasons) {
      val changed = if (active) gpuVoReasons.add(reason) else gpuVoReasons.remove(reason)
      if (!changed) return
      val desired = GpuVoPolicy.targetFor(gpuVoReasons)
      if (desired == activeGpuVoTarget) return
      val line = "${activeGpuVoTarget ?: "mediacodec"} -> ${desired ?: "mediacodec"} " +
        "(reasons=[${gpuVoReasons.joinToString(",")}])"
      activeGpuVoTarget = desired
      line
    }
    Log.i(TAG, "Video output: $transition")
    applyGpuVoTarget()
  }

  /**
   * Prepare views without holding [videoOutputMutex]: destroying a Surface
   * synchronously waits for that mutex. Return to the plane only after its OSD
   * Surface exists, and hide the outgoing OSD only after native ownership ends.
   * Re-read the arbiter after preparing views so a superseded request cannot
   * install a renderer against another request's surface configuration.
   */
  private fun applyGpuVoTarget() {
    scope.launch(mpvWriteDispatcher, start = CoroutineStart.ATOMIC) {
      try {
        val preparedTarget = withContext(Dispatchers.Main) {
          val target = activeGpuVoTarget
          if (!disposing) {
            if (target == null) {
              osdSurfaceView?.visibility = View.VISIBLE
              if (appliedGpuVoTarget == null) applyVideoRectLayout(force = true)
            } else {
              resetVideoSurfaceToFullContainer()
              if (appliedGpuVoTarget == target) osdSurfaceView?.visibility = View.GONE
            }
          }
          target
        }
        videoOutputMutex.withLock {
          if (disposing || videoOutputFailure != null) return@withLock
          val target = synchronized(gpuVoReasons) { activeGpuVoTarget }
          if (target != preparedTarget || target == appliedGpuVoTarget) return@withLock
          val p = player
          val surface = attachedSurface?.takeIf { it.isValid }
          val osd = if (target == null && !attachedToPlaceholder) pendingOsdSurface?.takeIf { it.isValid } else null
          if (p != null && target == null && !attachedToPlaceholder && osdSurfaceView != null && osd == null) {
            // surfaceCreated will retry; the GPU renderer remains usable.
            return@withLock
          }
          rebuildVideoOutput(p) {
            if (p != null && surface != null) {
              p.attachSurfaces(surface, osd, target ?: "mediacodec")
              attachedOsdSurface = osd
            } else {
              writeProperty("vo", target ?: "mediacodec")
            }
          }
          appliedGpuVoTarget = target
          runOnMain {
            if (!disposing && appliedGpuVoTarget != null && activeGpuVoTarget != null) {
              // The native handoff has already retired the outgoing OSD consumer.
              osdSurfaceView?.visibility = View.GONE
            }
          }
          if (p == null) return@withLock
          applyRenderTier(p, glVoActive = target != null)
          if (target != null) {
            // A failed conversion chain deselects video before this switch.
            // Re-select its explicit id; mid-file "auto" resolves to none.
            if (p.getString("vid").let { it == null || it == "no" }) {
              val videoTrackId = videoTracks(p).firstOrNull()?.optLong("id")
              if (videoTrackId != null) {
                Log.i(TAG, "Re-selecting video track $videoTrackId after chain failure")
                writeProperty("vid", videoTrackId.toString())
              }
            }
          }
          applySurfaceSizeInternal(p, force = true)
          if (target == null) applyVideoRectLayout(force = true)
        }
      } catch (e: CancellationException) {
        Log.d(TAG, "Canceled vo transition write")
      } catch (e: Exception) {
        runOnMain { failVideoOutput("VO transition", e) }
      }
    }
  }

  /**
   * Per-file Dolby Vision routing, decided from the bitstream: mpv exports
   * the DOVI configuration record's profile on the track list (never trust
   * server metadata for this — it mis-tags DV routinely; mpv omits the
   * field when the bitstream carries no record). Re-evaluated on every
   * file, so a following non-P5 file restores hardware decode and returns
   * to the video plane. [track] is the pending video track, see
   * [pendingVideoTrack].
   */
  private suspend fun applyDvReshapePolicy(p: MpvPlayer, track: org.json.JSONObject?) {
    val profile = track?.takeIf { it.has("dolby-vision-profile") }?.getLong("dolby-vision-profile")
    val needs = GpuVoPolicy.needsDvReshaping(
      dvProfile = profile,
      conversionMode = currentDvConversionMode,
      canPlayP5Natively = DoviBridge.canPlayDolbyVisionP5(context)
    )
    if (holdHwdec(p, GpuVoPolicy.REASON_DV_RESHAPE, needs) && needs) {
      Log.i(TAG, "DV P5 (bitstream) without native support: software decode + gpu-next reshaping")
    }
    setGpuVoRequirement(GpuVoPolicy.REASON_DV_RESHAPE, needs)
  }

  /**
   * Route unsupported hardware decoding before decoder initialization:
   * H.264 High 10 without a hardware profile (#2065), and AV1 without a
   * hardware decoder (#2272). Keep the GL requirement for the file, including
   * ambient toggles and surface recreation, rather than waiting for failure
   * or transient `hwdec-current` observations. [track] is the pending video
   * track, see [pendingVideoTrack].
   */
  private suspend fun applySoftwareDecodePolicy(p: MpvPlayer, track: org.json.JSONObject?) {
    val codec = track?.optString("codec")
    val codecProfile = track?.optString("codec-profile")
    val hardwareHigh10 = MediaCodecQuery.hardwareAvcHigh10Support()
    val hardwareAv1 = MediaCodecQuery.hardwareAv1Support()
    Log.d(TAG, "Decode routing: codec=$codec profile=$codecProfile hardwareHigh10=$hardwareHigh10 hardwareAv1=$hardwareAv1")
    val needs = GpuVoPolicy.needsSoftwareDecode(codec, codecProfile, hardwareHigh10, hardwareAv1)
    if (holdHwdec(p, GpuVoPolicy.REASON_CODEC_SW_DECODE, needs) && needs) {
      Log.i(TAG, "$codec profile=$codecProfile without hardware support: native software decode on the GL vo")
    }
    setGpuVoRequirement(GpuVoPolicy.REASON_CODEC_SW_DECODE, needs)
  }

  /**
   * Adds or removes a per-file reason to hold hwdec at `no`. The session's
   * own value is parked on the first reason and restored when the last one
   * drops (Dart writes meanwhile land in the park, see [setProperty]).
   * Returns whether the reason set changed.
   */
  private suspend fun holdHwdec(p: MpvPlayer, reason: String, needs: Boolean): Boolean {
    val transition: Boolean? = synchronized(hwdecHoldReasons) {
      val changed = if (needs) hwdecHoldReasons.add(reason) else hwdecHoldReasons.remove(reason)
      if (!changed) return false
      val held = hwdecHoldReasons.isNotEmpty()
      if (held == hwdecHeld) {
        null
      } else {
        hwdecHeld = held
        held
      }
    }
    when (transition) {
      true -> {
        parkedHwdec.set(p.getString("hwdec") ?: "no")
        writeProperty("hwdec", "no")
      }
      false -> {
        val restore = parkedHwdec.getAndSet(null)
        if (restore != null && restore != "no") writeProperty("hwdec", restore)
      }
      null -> {}
    }
    return true
  }

  /**
   * Moves the render options between mpv's defaults and the cheap tier as
   * the session enters or leaves a GL vo. Why: [GpuVoPolicy.needsCheapRenderTier].
   * Only options still at their mpv default are replaced, so a user's
   * mpv.conf line for any of them wins, and only those are restored.
   * Serialized on [mpvWriteDispatcher] behind the vo write it follows.
   */
  private suspend fun applyRenderTier(p: MpvPlayer, glVoActive: Boolean) {
    val wanted = GpuVoPolicy.needsCheapRenderTier(
      glVoActive = glVoActive,
      textureNorm16 = GlCapabilities.hasTextureNorm16()
    )
    val transition: Boolean = synchronized(cheapRenderRestore) {
      if (wanted == cheapRenderTierActive) return
      cheapRenderTierActive = wanted
      wanted
    }
    if (transition) {
      val replaced = LinkedHashMap<String, String>()
      for ((option, cheap) in GpuVoPolicy.CHEAP_RENDER_OPTIONS) {
        val current = p.getString(option)
        if (!GpuVoPolicy.isDefaultRenderOption(option, current)) {
          Log.d(TAG, "Render tier keeps $option=$current (not the mpv default)")
          continue
        }
        replaced[option] = current!!
        writeProperty(option, cheap)
      }
      synchronized(cheapRenderRestore) { cheapRenderRestore.putAll(replaced) }
      Log.i(TAG, "Cheap render tier (no GL_EXT_texture_norm16): ${replaced.keys.joinToString(",")}")
    } else {
      val restore = synchronized(cheapRenderRestore) { LinkedHashMap(cheapRenderRestore).also { cheapRenderRestore.clear() } }
      for ((option, value) in restore) writeProperty(option, value)
    }
  }

  /**
   * The video track mpv is about to select, resolved inside on_preloaded
   * where nothing is selected yet. `vid=no` and an explicit `vid=N` answer
   * on their own (the hook never re-selects: an explicit choice stays the
   * user's); `auto` asks the fork's `pending-vid`, which runs mpv's own
   * default selection ahead of time. Without that property (a libmpv
   * predating the fork patch) the first track is the only guess left; the
   * gap is logged once so a wrong policy on a multi-video file is traceable.
   * Decision in [GpuVoPolicy.pendingVideoTrackId].
   */
  private suspend fun pendingVideoTrack(p: MpvPlayer): org.json.JSONObject? {
    val tracks = videoTracks(p)
    if (tracks.isEmpty()) return null
    val vid = p.getString("vid")
    val auto = vid == null || vid == "auto"
    val pendingVid = if (auto) p.getString("pending-vid") else null
    if (auto && pendingVid == null && !pendingVidUnavailableLogged) {
      pendingVidUnavailableLogged = true
      Log.w(TAG, "libmpv has no pending-vid property; decode routing assumes the first video track")
    }
    val id = GpuVoPolicy.pendingVideoTrackId(vid, pendingVid, tracks.map { it.optLong("id") })
    Log.d(TAG, "Pending video track: vid=$vid pending-vid=$pendingVid -> ${id ?: "none"} of ${tracks.size}")
    return tracks.firstOrNull { it.optLong("id") == id }
  }

  /**
   * Runs [block] — a surface handoff and/or vo write, each of which makes
   * mpv rebuild the video chain — with the video track parked when
   * [GpuVoPolicy.needsParkedRebuild] says the decoder must not be re-created
   * inside the rebuild. Deselecting closes the decoder synchronously before
   * the rebuild starts; re-selecting afterwards creates the next instance
   * against the finished output. Measured on a Pixel 7: 30 consecutive
   * ambient-lighting and lock/unlock rebuilds without a vendor-service death,
   * where the unparked rebuild killed it on the first try. [p] may be null
   * before init, when there is nothing to park.
   */
  private suspend fun rebuildVideoOutput(p: MpvPlayer?, block: suspend () -> Unit) {
    val vid = if (p != null && needsParkedRebuild(p)) p.getString("vid")?.toLongOrNull() else null
    if (vid == null) {
      block()
      return
    }
    Log.i(TAG, "Parking video track $vid across the output rebuild (BigOcean AV1)")
    writeProperty("vid", "no")
    try {
      block()
    } finally {
      writeProperty("vid", vid.toString())
    }
  }

  private suspend fun needsParkedRebuild(p: MpvPlayer): Boolean {
    if (!MediaCodecQuery.hardwareAv1IsBigOcean()) return false
    return GpuVoPolicy.needsParkedRebuild(
      codec = p.getString("current-tracks/video/codec"),
      hwdec = p.getString("hwdec"),
      bigOceanAv1 = true
    )
  }

  /**
   * Observed rather than derived from the hardware-decoding setting because
   * the fallback is decided per file, inside mpv. Why it matters:
   * [GpuVoPolicy.needsSoftwareRender].
   *
   * Latched per file: the reason is only ever raised here and dropped on the
   * next start-file. mpv's fallback to `mediacodec-copy` or software is a
   * verdict on this stream's hardware path; clearing the reason as soon as a
   * fresh decoder under the GL vo reports `mediacodec` again would send the
   * session back to the plane, whose rebuild re-creates the decoder, which
   * fails the same way — an endless plane/GL oscillation (#2272).
   */
  private fun collectDecoderState(p: MpvPlayer) {
    scope.launch(start = CoroutineStart.UNDISPATCHED) {
      p.observeString("hwdec-current").collect { value ->
        if (GpuVoPolicy.needsSoftwareRender(value)) setGpuVoRequirement(GpuVoPolicy.REASON_SW_DECODE, true)
      }
    }
  }

  /**
   * User shaders need a GL vo; the video plane renders none. Observed
   * natively so Dart's `glsl-shaders` change-list writes (ShaderService,
   * ambient lighting) switch the session live, without a channel contract.
   */
  private fun collectShaderState(p: MpvPlayer) {
    scope.launch(start = CoroutineStart.UNDISPATCHED) {
      p.observeString("glsl-shaders").collect { value ->
        setGpuVoRequirement(GpuVoPolicy.REASON_SHADERS, value.isNotBlank())
      }
    }
  }

  /**
   * Observed from video-params so the reason follows per-file transfer
   * changes, and the display is re-queried per change so an HDMI mode switch
   * mid-session is honoured on the next file. Why it matters:
   * [GpuVoPolicy.needsHdrToneMapping].
   */
  private fun collectHdrToneMapState(p: MpvPlayer) {
    scope.launch(start = CoroutineStart.UNDISPATCHED) {
      p.observeString("video-params/gamma").collect { value ->
        val needsToneMap = GpuVoPolicy.needsHdrToneMapping(
          gamma = value,
          displaySupportsHdr = DoviBridge.displaySupportsHdr(context)
        )
        setGpuVoRequirement(GpuVoPolicy.REASON_HDR_SDR, needsToneMap)
      }
    }
  }

  /** Video tracks from mpv's track list, selected first; empty on any parse failure. */
  private suspend fun videoTracks(p: MpvPlayer): List<org.json.JSONObject> {
    val json = p.getString("track-list") ?: return emptyList()
    return try {
      val tracks = org.json.JSONArray(json)
      (0 until tracks.length())
        .map { tracks.getJSONObject(it) }
        .filter { it.optString("type") == "video" }
        .sortedByDescending { it.optBoolean("selected") }
    } catch (e: Exception) {
      Log.w(TAG, "Failed to parse track-list", e)
      emptyList()
    }
  }

  /**
   * Sizes the video surface to the rectangle the image should occupy, per
   * [VideoRectPolicy], and lets the container clip the overflow.
   *
   * The OSD stays full-container. Publish the laid-out picture bounds in its
   * coordinate space so the VO can scale them to the OSD buffer and derive
   * signed margins without cropping subtitles or reconstructing fit/zoom.
   */
  private fun applyVideoRectLayout(force: Boolean = false) {
    if (!usesMediaCodecVo) return
    runOnMain {
      if (disposing || activeGpuVoTarget != null || appliedGpuVoTarget != null) return@runOnMain
      if (force) pendingVideoRectUpdate.set(null)
      val container = surfaceContainer ?: return@runOnMain
      val size = VideoRectPolicy.sizeFor(
        containerWidth = container.width,
        containerHeight = container.height,
        videoWidth = videoDisplayWidth,
        videoHeight = videoDisplayHeight,
        panscan = videoPanscan,
        videoZoomLog2 = videoZoomLog2
      ) ?: return@runOnMain
      // The guard matters: this runs from an OnGlobalLayoutListener, so an
      // unconditional write would re-trigger layout forever.
      val view = surfaceView ?: return@runOnMain
      val osd = osdSurfaceView ?: return@runOnMain
      val lp = view.layoutParams as android.widget.FrameLayout.LayoutParams
      if (lp.width != size.width || lp.height != size.height || lp.gravity != android.view.Gravity.CENTER) {
        lp.width = size.width
        lp.height = size.height
        lp.gravity = android.view.Gravity.CENTER
        view.layoutParams = lp
        return@runOnMain
      }
      // Wait for Android to apply CENTER's integer rounding, including odd
      // negative overflow. Never publish requested sizes with old positions.
      if (view.isLayoutRequested || osd.isLayoutRequested) return@runOnMain
      val rect = VideoRectPolicy.rectFor(
        osd.width,
        osd.height,
        view.left - osd.left,
        view.top - osd.top,
        view.right - osd.left,
        view.bottom - osd.top
      ) ?: return@runOnMain
      publishVideoRect(rect)
    }
  }

  private fun publishVideoRect(rect: VideoRectPolicy.Rect) {
    val p = player
    if (p == null && propertyWriterOverride == null) return
    val update = VideoRectUpdate(videoOutputEpoch, rect)
    if (pendingVideoRectUpdate.get() == update) return
    pendingVideoRectUpdate.set(update)
    scope.launch(mpvWriteDispatcher) {
      try {
        videoOutputMutex.withLock {
          ensureActive()
          if (pendingVideoRectUpdate.get() !== update ||
            !isCurrentVideoOutputEpoch(update.epoch) ||
            player !== p ||
            activeGpuVoTarget != null
          ) {
            return@withLock
          }
          // The native option invalidates OSD even when playback is paused.
          writeProperty("vo-mediacodec-video-rect", rect.propertyValue())
        }
      } catch (e: CancellationException) {
        pendingVideoRectUpdate.compareAndSet(update, null)
      } catch (e: Exception) {
        pendingVideoRectUpdate.compareAndSet(update, null)
        Log.w(TAG, "Failed to apply video rectangle to MPV", e)
      }
    }
  }

  private fun resetVideoSurfaceToFullContainer() {
    val view = surfaceView ?: return
    val lp = view.layoutParams as android.widget.FrameLayout.LayoutParams
    if (lp.width == android.widget.FrameLayout.LayoutParams.MATCH_PARENT) return
    lp.width = android.widget.FrameLayout.LayoutParams.MATCH_PARENT
    lp.height = android.widget.FrameLayout.LayoutParams.MATCH_PARENT
    lp.gravity = android.view.Gravity.NO_GRAVITY
    view.layoutParams = lp
  }

  private fun rememberSurfaceSize(width: Int, height: Int) {
    if (width <= 0 || height <= 0) return
    lastKnownSurfaceWidth = width
    lastKnownSurfaceHeight = height
  }

  private fun rememberCurrentSurfaceSize() {
    val sv = surfaceView ?: return
    rememberSurfaceSize(sv.width, sv.height)
  }

  // Only callbacks publish usable surfaces. SurfaceHolder.isValid can still
  // be true inside surfaceDestroyed, after we have revoked that surface.
  private fun currentCandidateSurface(): Surface? = pendingSurface?.takeIf { it.isValid }

  private fun hasAttachedRealSurface(): Boolean = hasAttachedSurface && !attachedToPlaceholder && (attachedSurface?.isValid == true)

  // Audio-only mode has no video output to wait for — playback and resume
  // paths gated on output readiness must always proceed there.
  private fun hasReadyVideoOutput(): Boolean = audioOnly || (videoOutputFailure == null && hasAttachedRealSurface() && !videoOutputRestoring)

  private fun isCurrentVideoOutputEpoch(epoch: Long): Boolean = !disposing && videoOutputFailure == null && epoch == videoOutputEpoch

  private fun isVideoOutputRefreshCurrent(epoch: Long): Boolean {
    if (!isCurrentVideoOutputEpoch(epoch)) return false
    return hasAttachedRealSurface()
  }

  private fun refreshVideoOutput(reason: String) {
    if (audioOnly || disposing || videoOutputFailure != null) return

    rememberCurrentSurfaceSize()
    val p = player
    val surface = currentCandidateSurface()
    if (p == null) {
      pendingSurface = surface?.takeIf { it.isValid }
      Log.d(TAG, "refreshVideoOutput($reason): player not ready yet")
      return
    }

    if (surface == null || !surface.isValid) {
      videoOutputRestoring = true
      Log.d(TAG, "refreshVideoOutput($reason): no valid surface available")
      return
    }

    val refreshEpoch = videoOutputEpoch
    videoOutputRestoring = true
    flutterOverlayApplied = false
    ensureFlutterOverlayOnTop()
    Log.d(TAG, "refreshVideoOutput($reason): scheduling async refresh (epoch=$refreshEpoch)")
    pendingVideoOutputRefreshJob = scope.launch(Dispatchers.IO) {
      try {
        videoOutputMutex.withLock {
          if (!isCurrentVideoOutputEpoch(refreshEpoch)) {
            Log.d(TAG, "Skipping stale MPV video output refresh ($reason, epoch=$refreshEpoch)")
            return@withLock
          }
          if (!surface.isValid) {
            videoOutputRestoring = true
            Log.d(TAG, "Skipping MPV video output refresh with invalid surface ($reason, epoch=$refreshEpoch)")
            return@withLock
          }

          val osd = pendingOsdSurface?.takeIf { usesMediaCodecVo && appliedGpuVoTarget == null && it.isValid }
          val needsAttach = !hasAttachedSurface || attachedSurface !== surface || osd !== attachedOsdSurface
          val wasAttachedToPlaceholder = attachedToPlaceholder
          val wasPausedForSurfaceLoss = pausedForSurfaceLoss
          if (needsAttach) {
            rebuildVideoOutput(p) { p.attachSurfaces(surface, osd) }
            attachedOsdSurface = osd
            attachedSurface = surface
            hasAttachedSurface = true
            attachedToPlaceholder = false
            Log.d(TAG, "refreshVideoOutput($reason): attached surface")
          } else {
            Log.d(TAG, "refreshVideoOutput($reason): surface already attached, refreshing surface state")
          }

          if (!isVideoOutputRefreshCurrent(refreshEpoch)) {
            Log.d(TAG, "Skipping stale MPV video output refresh after attach ($reason, epoch=$refreshEpoch)")
            return@withLock
          }
          applySurfaceSizeInternal(p, force = true)
          if (!isVideoOutputRefreshCurrent(refreshEpoch)) {
            Log.d(TAG, "Skipping stale MPV video output refresh after surface size ($reason, epoch=$refreshEpoch)")
            return@withLock
          }
          applyVideoRectLayout(force = needsAttach)
          videoOutputRestoring = false
          applyDeferredResumeIfNeeded(p, reason)
          if (wasPausedForSurfaceLoss) {
            pausedForSurfaceLoss = false
            Log.d(TAG, "Cleared surface-loss pause after $reason")
          }
          if (wasAttachedToPlaceholder) {
            Log.d(TAG, "Restored MPV real surface after placeholder ($reason)")
          }
          Log.d(TAG, "Video output ready after $reason")
        }
      } catch (e: CancellationException) {
        Log.d(TAG, "Canceled pending MPV video output refresh ($reason, epoch=$refreshEpoch)")
      } catch (e: Exception) {
        runOnMain { failVideoOutput("refresh ($reason)", e) }
      }
    }
  }

  private fun applySurfaceSize(width: Int, height: Int) {
    val p = player ?: return
    if (disposing || width <= 0 || height <= 0) return
    rememberSurfaceSize(width, height)
    if (!hasReadyVideoOutput()) return
    scope.launch {
      try {
        applySurfaceSizeInternal(p)
      } catch (e: Exception) {
        Log.w(TAG, "Failed to apply surface size to MPV", e)
      }
    }
  }

  private suspend fun applySurfaceSizeInternal(p: MpvPlayer, force: Boolean = false) {
    if (disposing) return
    val width = lastKnownSurfaceWidth
    val height = lastKnownSurfaceHeight
    if (width <= 0 || height <= 0) return

    val size = "${width}x$height"
    if (!force && size == lastAppliedSurfaceSize) return
    p.setProperty("android-surface-size", size)
    lastAppliedSurfaceSize = size
    Log.d(TAG, "Applied MPV surface size $size${if (force) " (forced)" else ""}")
  }

  /**
   * SurfaceHolder requires consumers to stop using a surface before destruction
   * returns. The worker and GL placeholder never need the main looper to finish.
   * A timeout is a terminal output failure, not permission to mark it ready or
   * release references still held by native code.
   */
  private fun handoffDestroyedSurface(reason: String, videoLost: Boolean) {
    val p = player ?: return
    if (videoOutputFailure != null) return
    videoOutputRestoring = true
    val epoch = videoOutputEpoch + 1L
    videoOutputEpoch = epoch
    val completed = CountDownLatch(1)
    val failure = AtomicReference<Exception?>()
    scope.launch(Dispatchers.IO, start = CoroutineStart.ATOMIC) {
      try {
        videoOutputMutex.withLock {
          if (!isCurrentVideoOutputEpoch(epoch)) return@withLock
          val target = if (videoLost) placeholderSurface else currentCandidateSurface() ?: placeholderSurface
          check(target != null && target.isValid) { "No valid MPV surface for $reason" }
          val isPlaceholder = target === placeholderSurface
          if (isPlaceholder && !attachedToPlaceholder) {
            publicPauseWriteMutex.withLock {
              val wasPaused = p.getFlag("pause") ?: cachedPaused
              if (!wasPaused) {
                p.setProperty("pause", true)
                cachedPaused = true
                pausedForSurfaceLoss = true
              }
            }
          }
          // Revoke both planes when the video disappears. Otherwise retain
          // the currently available video and remove only the destroyed OSD.
          val osd = if (isPlaceholder) {
            null
          } else {
            pendingOsdSurface?.takeIf {
              usesMediaCodecVo && appliedGpuVoTarget == null && it.isValid
            }
          }
          if (attachedSurface !== target || attachedOsdSurface !== osd) {
            rebuildVideoOutput(p) { p.attachSurfaces(target, osd) }
          }
          attachedSurface = target
          attachedOsdSurface = osd
          hasAttachedSurface = true
          attachedToPlaceholder = isPlaceholder
          lastAppliedSurfaceSize = null
          if (!isCurrentVideoOutputEpoch(epoch)) return@withLock
          videoOutputRestoring = isPlaceholder
          if (!isPlaceholder) {
            applySurfaceSizeInternal(p, force = true)
            if (!isCurrentVideoOutputEpoch(epoch)) return@withLock
            applyDeferredResumeIfNeeded(p, reason)
            pausedForSurfaceLoss = false
          }
          Log.d(TAG, "Surface handoff complete ($reason, epoch=$epoch, placeholder=$isPlaceholder)")
        }
      } catch (error: Exception) {
        failure.set(error)
      } finally {
        completed.countDown()
      }
    }
    val acknowledged = try {
      completed.await(SURFACE_HANDOFF_TIMEOUT_MS, TimeUnit.MILLISECONDS)
    } catch (error: InterruptedException) {
      Thread.currentThread().interrupt()
      failure.set(error)
      false
    }
    if (!acknowledged || failure.get() != null) {
      failVideoOutput(reason, failure.get() ?: MpvException("Surface handoff timed out after ${SURFACE_HANDOFF_TIMEOUT_MS}ms"))
    }
  }

  private fun failVideoOutput(reason: String, error: Exception) {
    if (disposing || videoOutputFailure != null) return
    videoOutputFailure = error
    videoOutputEpoch += 1L
    videoOutputRestoring = true
    deferredResumeRequested = false
    Log.e(TAG, "MPV video output failed during $reason", error)
    // Same terminal playback-error envelope as the other Android player.
    // Do not claim that the native call finished or retire its surfaces here.
    delegate?.onEvent(
      "end-file",
      mapOf("reason" to "error", "message" to "Video output failed", "cause" to "$reason: ${error.message}")
    )
  }

  private fun awaitNativeDisposal() {
    val completed = nativeDisposalComplete ?: return
    try {
      if (!completed.await(SURFACE_HANDOFF_TIMEOUT_MS, TimeUnit.MILLISECONDS)) {
        Log.e(TAG, "Native teardown did not release the destroyed surface within ${SURFACE_HANDOFF_TIMEOUT_MS}ms")
      }
    } catch (error: InterruptedException) {
      Thread.currentThread().interrupt()
      Log.e(TAG, "Interrupted waiting for native surface retirement", error)
    }
  }

  private fun normalizePauseValue(value: String): Boolean? = when (value.lowercase()) {
    "yes", "true", "1" -> true
    "no", "false", "0" -> false
    else -> null
  }

  private fun pauseForAudioFocusLoss() {
    val shouldPause = synchronized(publicPauseIntentLock) {
      (!desiredPaused).also { pausedForAudioFocusLoss = it }
    }
    if (!shouldPause) {
      Log.d(TAG, "Skipping audio-focus pause because playback is already desirably paused")
      return
    }

    scope.launch(mpvWriteDispatcher, start = CoroutineStart.ATOMIC) {
      try {
        publicPauseWriteMutex.withLock {
          if (!pausedForAudioFocusLoss || disposing) return@withLock
          writeProperty("pause", "yes")
          cachedPaused = true
        }
      } catch (error: CancellationException) {
        Log.d(TAG, "Canceled audio-focus pause")
      } catch (error: Exception) {
        Log.w(TAG, "Failed to pause on focus loss", error)
      }
    }
  }

  private fun resumeAfterAudioFocusGain(reason: String) {
    val shouldResume = synchronized(publicPauseIntentLock) {
      if (!pausedForAudioFocusLoss) {
        false
      } else {
        pausedForAudioFocusLoss = false
        true
      }
    }
    if (shouldResume) requestAutoResume(reason)
  }

  private fun rollbackFailedPublicPauseIntent(intent: PublicPauseIntent) {
    synchronized(publicPauseIntentLock) {
      if (publicPauseIntentGeneration == intent.generation) {
        resumeBlockedByPublicPause = intent.previousBlocked
        desiredPaused = intent.previousDesiredPaused
      }
    }
  }

  private fun completePublicResumeNoOp(onComplete: ((Result<Unit>) -> Unit)?) {
    runOnMain {
      val completion: Result<Unit> = if (disposing || !isInitialized || !scope.isActive) {
        Result.failure(CancellationException("MPV core unavailable"))
      } else {
        Result.success(Unit)
      }
      onComplete?.invoke(completion)
    }
  }

  private fun requestAutoResume(reason: String) {
    val p = player
    if (p == null && propertyWriterOverride == null) return
    if (disposing) return

    val intentGeneration = synchronized(publicPauseIntentLock) {
      if (resumeBlockedByPublicPause) {
        deferredResumeRequested = false
        Log.d(TAG, "Skipping auto-resume after $reason because playback is explicitly paused")
        return
      }

      if (!hasReadyVideoOutput()) {
        deferredResumeRequested = true
        Log.d(TAG, "Deferring auto-resume after $reason until video output is ready")
        return
      }
      publicPauseIntentGeneration
    }

    scope.launch(mpvWriteDispatcher) {
      try {
        publicPauseWriteMutex.withLock {
          val shouldResume = synchronized(publicPauseIntentLock) {
            !pausedForAudioFocusLoss &&
              !resumeBlockedByPublicPause &&
              publicPauseIntentGeneration == intentGeneration
          }
          if (!shouldResume) {
            Log.d(TAG, "Skipping stale auto-resume after $reason")
            return@withLock
          }
          val isPaused = p?.getFlag("pause") ?: cachedPaused
          if (isPaused) {
            Log.d(TAG, "Auto-resuming playback after $reason")
            if (p != null) {
              p.setProperty("pause", false)
            } else {
              writeProperty("pause", "no")
            }
            cachedPaused = false
          } else {
            Log.d(TAG, "Skipping auto-resume after $reason because playback is already running")
          }
        }
      } catch (e: Exception) {
        Log.w(TAG, "Failed to resume after $reason", e)
      }
    }
  }

  private suspend fun applyDeferredResumeIfNeeded(p: MpvPlayer, reason: String) {
    publicPauseWriteMutex.withLock {
      val shouldResume = synchronized(publicPauseIntentLock) {
        if (!deferredResumeRequested) {
          false
        } else if (pausedForAudioFocusLoss) {
          Log.d(TAG, "Keeping deferred auto-resume pending after $reason until audio focus returns")
          false
        } else if (resumeBlockedByPublicPause) {
          deferredResumeRequested = false
          Log.d(TAG, "Dropping deferred auto-resume after $reason because playback is explicitly paused")
          false
        } else {
          deferredResumeRequested = false
          true
        }
      }
      if (!shouldResume) return@withLock
      if (p.getFlag("pause") == true) {
        Log.d(TAG, "Applying deferred auto-resume after $reason")
        p.setProperty("pause", false)
        cachedPaused = false
      } else {
        Log.d(TAG, "Skipping deferred auto-resume after $reason because playback is already running")
      }
    }
  }

  private suspend fun writeProperty(name: String, value: String) {
    val writer = propertyWriterOverride
    if (writer != null) {
      writer(name, value)
    } else {
      val currentPlayer = player ?: throw CancellationException("MPV player unavailable")
      currentPlayer.setProperty(name, value)
    }
  }

  // Public API
  /**
   * Atomically records the public pause intent applied by the next loadfile
   * operation. The load owns the native state transition, so this deliberately
   * does not enqueue a second pause property write.
   */
  fun setPauseIntentForLoad(paused: Boolean) {
    if (!isInitialized || disposing || !scope.isActive) return

    synchronized(publicPauseIntentLock) {
      publicPauseIntentGeneration += 1L
      desiredPaused = paused
      resumeBlockedByPublicPause = paused
      if (paused) {
        cachedPaused = true
        pausedForSurfaceLoss = false
        pausedForAudioFocusLoss = false
        deferredResumeRequested = false
      } else if (!pausedForSurfaceLoss && !pausedForAudioFocusLoss && !deferredResumeRequested) {
        cachedPaused = false
      }
    }
    Log.d(TAG, "Load pause intent updated: paused=$paused")
  }

  /**
   * `dv-conversion-mode` is an app-level property shared with the ExoPlayer
   * and Apple cores, not an mpv one. It maps onto the fork FFmpeg
   * hevc_mediacodec decoder options, mirroring the ExoPlayer DoviBridge
   * decision tree. Single-layer profiles (5/8) use the Dolby Vision decoder
   * whenever the path is enabled and the decoder advertises the profile.
   */
  private fun applyDvConversionMode(value: String, onComplete: ((Result<Unit>) -> Unit)?) {
    val displayDv = DoviBridge.displaySupportsDolbyVision(context)
    val (dolbyVision, p7Mode) = when (value.trim().lowercase()) {
      "auto" -> if (displayDv) "1" to "auto" else "0" to "strip"
      "disabled", "native" -> "1" to "native"
      "dv81" -> "1" to "convert"
      "hevc", "hevc_strip" -> "1" to "strip"
      else -> {
        onComplete?.invoke(Result.failure(IllegalArgumentException("Invalid DV conversion mode: $value")))
        return
      }
    }
    currentDvConversionMode = value.trim().lowercase()
    Log.i(TAG, "DV conversion mode '$value' (displayDV=$displayDv) -> dolby_vision=$dolbyVision dv_p7_mode=$p7Mode")
    scope.launch(mpvWriteDispatcher, start = CoroutineStart.ATOMIC) {
      val completion = try {
        val ours = "dolby_vision=$dolbyVision,dv_p7_mode=$p7Mode"
        val merged = mergeDecoderOptions(player?.getString("vd-lavc-o"), ours)
        writeProperty("vd-lavc-o", merged)
        Result.success(Unit)
      } catch (error: CancellationException) {
        Result.failure(error)
      } catch (error: Exception) {
        Log.w(TAG, "DV conversion mode write failed")
        Result.failure(error)
      }
      withContext(NonCancellable + Dispatchers.Main) {
        onComplete?.invoke(completion)
      }
    }
  }

  /**
   * `content-color-transfer` is an app-level property: Dart announces the
   * selected stream's transfer (server metadata) before playback so an HDR
   * session can get a BT.2020 PQ 10-bit GL surface instead of tone-mapped
   * SDR. Consumed by whichever android GL context the session ever creates -
   * up front for a software session, or at the fallback transition when a
   * plane session leaves vo=mediacodec (the plane itself carries HDR via the
   * decoder's dataspace and ignores all of this).
   *
   * The first announcement decides for the whole core: the surface colorspace
   * is fixed at EGL-surface creation, and both latched states stay correct
   * for later files (a PQ target renders SDR content correctly, an sRGB
   * surface tone-maps HDR as before) - re-deciding mid-session could pair a
   * live sRGB surface with a PQ render target, which is wrong everywhere.
   */
  private fun applyContentColorTransfer(value: String, onComplete: ((Result<Unit>) -> Unit)?) {
    val transfer = value.trim().lowercase()
    if (hdrSurfaceDecided) {
      onComplete?.invoke(Result.success(Unit))
      return
    }
    hdrSurfaceDecided = true
    val wants = wantsHdrSurface(transfer)
    val displayHdr = wants && DoviBridge.displaySupportsHdr(context)
    // Independent of the GL surface outcome: on the MediaCodec plane the
    // decoder's dataspace carries HDR to the display without a PQ GL surface.
    hdrDisplayActive = displayHdr
    val outputFormat = if (wants) EglHdrCaps.pqOutputFormat() else null
    if (!wants || !displayHdr || outputFormat == null) {
      if (wants) {
        Log.i(TAG, "HDR GL surface unavailable (transfer=$transfer displayHdr=$displayHdr eglFormat=$outputFormat)")
      }
      onComplete?.invoke(Result.success(Unit))
      return
    }
    Log.i(TAG, "HDR GL surface engaged: BT.2020 PQ / $outputFormat for transfer=$transfer")
    scope.launch(mpvWriteDispatcher, start = CoroutineStart.ATOMIC) {
      val completion = try {
        writeProperty("android-surface-colorspace", "bt2020-pq")
        writeProperty("egl-output-format", outputFormat)
        writeProperty("target-trc", "pq")
        writeProperty("target-prim", "bt.2020")
        Result.success(Unit)
      } catch (error: CancellationException) {
        Result.failure(error)
      } catch (error: Exception) {
        Log.w(TAG, "HDR surface property write failed")
        Result.failure(error)
      }
      withContext(NonCancellable + Dispatchers.Main) {
        onComplete?.invoke(completion)
      }
    }
  }

  fun setLogLevel(level: String, onComplete: (Result<Unit>) -> Unit) {
    if (!isInitialized || disposing || !scope.isActive) {
      onComplete(Result.failure(CancellationException("MPV core unavailable")))
      return
    }

    // ATOMIC starts even if dispose cancels a queued write, so its channel
    // result is completed; ensureActive prevents that write reaching JNI.
    scope.launch(mpvWriteDispatcher, start = CoroutineStart.ATOMIC) {
      val outcome = try {
        ensureActive()
        val p = player ?: throw CancellationException("MPV player unavailable")
        p.setLogLevel(level)
        Result.success(Unit)
      } catch (error: Exception) {
        Result.failure(error)
      }
      withContext(NonCancellable + Dispatchers.Main) {
        onComplete(
          if (disposing || !isInitialized) {
            Result.failure(CancellationException("MPV core unavailable"))
          } else {
            outcome
          }
        )
      }
    }
  }

  fun setProperty(name: String, value: String, onComplete: ((Result<Unit>) -> Unit)? = null) {
    if (!isInitialized || disposing || !scope.isActive) {
      onComplete?.invoke(Result.failure(CancellationException("MPV core unavailable")))
      return
    }

    if (name == "dv-conversion-mode") {
      applyDvConversionMode(value, onComplete)
      return
    }

    if (name == "content-color-transfer") {
      applyContentColorTransfer(value, onComplete)
      return
    }

    // View geometry on the plane (see VideoRectPolicy), but both still fall
    // through to mpv, which is what makes them work unchanged on the GL vos.
    if (name == "panscan" || name == "video-zoom") {
      val parsed = value.toFloatOrNull()
      if (parsed != null) {
        if (name == "panscan") videoPanscan = parsed else videoZoomLog2 = parsed
        applyVideoRectLayout()
      }
    }

    // While a per-file policy holds hwdec at `no` (DV P5 reshaping, Hi10
    // without a hardware profile), park writes instead of applying them: a
    // hardware value under gpu-next would lose the RPU side data (and
    // blue-screen the Tegra class, #2010). The parked value is restored when
    // the next file drops the last requirement.
    if (name == "hwdec" && hwdecHeld) {
      parkedHwdec.set(value)
      onComplete?.invoke(Result.success(Unit))
      return
    }

    val paused = if (name == "pause") normalizePauseValue(value) else null
    if (paused == false) {
      videoOutputFailure?.let { error ->
        runOnMain { onComplete?.invoke(Result.failure(error)) }
        return
      }
    }
    val pauseIntent = paused?.let {
      synchronized(publicPauseIntentLock) {
        PublicPauseIntent(
          generation = ++publicPauseIntentGeneration,
          previousBlocked = resumeBlockedByPublicPause,
          previousDesiredPaused = desiredPaused
        ).also {
          resumeBlockedByPublicPause = paused
          desiredPaused = paused
        }
      }
    }

    if (paused == false && pauseIntent != null) {
      val shouldReclaimAudioFocus = synchronized(publicPauseIntentLock) {
        publicPauseIntentGeneration == pauseIntent.generation && pausedForAudioFocusLoss
      }
      if (shouldReclaimAudioFocus) {
        val focusGranted = audioFocusManager?.requestAudioFocus() == true
        if (!focusGranted) {
          Log.w(TAG, "Audio focus request denied; keeping public resume pending")
          completePublicResumeNoOp(onComplete)
          return
        }

        synchronized(publicPauseIntentLock) {
          if (publicPauseIntentGeneration == pauseIntent.generation && pausedForAudioFocusLoss) {
            pausedForAudioFocusLoss = false
          }
        }
      }
    }

    if (paused == false && pauseIntent != null && !hasReadyVideoOutput()) {
      runOnMain {
        if (!isInitialized || disposing || !scope.isActive) {
          onComplete?.invoke(Result.failure(CancellationException("MPV core unavailable")))
          return@runOnMain
        }
        var deferredForSurface = false
        val interruptedAgain = synchronized(publicPauseIntentLock) {
          if (publicPauseIntentGeneration != pauseIntent.generation) {
            false
          } else if (pausedForAudioFocusLoss) {
            true
          } else {
            deferredResumeRequested = true
            deferredForSurface = true
            false
          }
        }
        if (interruptedAgain) {
          Log.d(TAG, "Public resume deferred by a newer audio-focus loss")
          onComplete?.invoke(Result.success(Unit))
        } else {
          if (deferredForSurface) {
            Log.d(TAG, "Deferring public resume until video output is ready")
          }
          onComplete?.invoke(Result.success(Unit))
        }
      }
      return
    }

    scope.launch(mpvWriteDispatcher, start = CoroutineStart.ATOMIC) {
      var interruptedBeforeWrite = false
      val writeResult = try {
        if (pauseIntent == null) {
          writeProperty(name, value)
        } else {
          publicPauseWriteMutex.withLock {
            val shouldWrite = synchronized(publicPauseIntentLock) {
              val isCurrent = publicPauseIntentGeneration == pauseIntent.generation
              if (isCurrent && paused == false && pausedForAudioFocusLoss) {
                interruptedBeforeWrite = true
                false
              } else {
                isCurrent
              }
            }
            if (shouldWrite) writeProperty(name, value)
          }
        }
        if (interruptedBeforeWrite) {
          Log.d(TAG, "Public resume write skipped after a newer audio-focus loss")
        }
        Result.success(Unit)
      } catch (error: CancellationException) {
        Result.failure(error)
      } catch (error: Exception) {
        Log.w(TAG, "MPV property write failed")
        Result.failure(error)
      }

      if (writeResult.isFailure && pauseIntent != null) {
        rollbackFailedPublicPauseIntent(pauseIntent)
      }

      withContext(NonCancellable + Dispatchers.Main) {
        val completion = if (disposing || !isInitialized) {
          Result.failure(CancellationException("MPV core unavailable"))
        } else {
          writeResult
        }
        val isCurrent = pauseIntent == null ||
          synchronized(publicPauseIntentLock) {
            publicPauseIntentGeneration == pauseIntent.generation
          }
        if (isCurrent && completion.isSuccess && !interruptedBeforeWrite) {
          if (paused == true) {
            cachedPaused = true
            pausedForSurfaceLoss = false
            deferredResumeRequested = false
            Log.d(TAG, "Public pause state updated: paused=true")
          } else if (paused == false) {
            cachedPaused = false
            pausedForSurfaceLoss = false
            deferredResumeRequested = false
            Log.d(TAG, "Public pause state updated: paused=false")
          }
        }
        onComplete?.invoke(completion)
      }
    }
  }

  fun getProperty(name: String): String? {
    if (Looper.myLooper() == Looper.getMainLooper()) {
      Log.w(TAG, "Refusing synchronous getProperty($name) on the main thread")
      return null
    }
    return getPropertyBlocking(name)
  }

  private fun getPropertyBlocking(name: String): String? {
    if (!isInitialized || disposing) return null
    return try {
      runBlocking(Dispatchers.IO) { player?.getString(name) }
    } catch (e: Exception) {
      null
    }
  }

  fun getPropertyAsync(name: String, onResult: (String?) -> Unit) {
    if (!isInitialized || disposing) {
      onResult(null)
      return
    }

    Thread {
      val value = getPropertyBlocking(name)
      runOnMain {
        onResult(if (!disposing && isInitialized) value else null)
      }
    }.start()
  }

  /**
   * Returns MPV stats in the same key format used by the performance overlay.
   * This method performs synchronous native property reads and must not be
   * called on Android's main thread.
   */
  fun getStats(): Map<String, Any?> {
    if (Looper.myLooper() == Looper.getMainLooper()) {
      Log.w(TAG, "Refusing synchronous getStats() on the main thread")
      return mapOf("playerType" to "mpv")
    }

    val hasVideo = getProperty("video-params/w") != null

    val stats = mutableMapOf<String, Any?>(
      "playerType" to "mpv",
      "video-codec" to getProperty("video-codec"),
      "video-params/w" to getProperty("video-params/w"),
      "video-params/h" to getProperty("video-params/h"),
      "videoWidth" to getProperty("dwidth"),
      "videoHeight" to getProperty("dheight"),
      "container-fps" to getProperty("container-fps"),
      "estimated-vf-fps" to getProperty("estimated-vf-fps"),
      "video-bitrate" to getProperty("video-bitrate"),
      "hwdec-current" to getProperty("hwdec-current"),
      "current-vo" to getProperty("current-vo"),
      "audio-codec-name" to getProperty("audio-codec-name"),
      "audio-params/samplerate" to getProperty("audio-params/samplerate"),
      "audio-params/hr-channels" to getProperty("audio-params/hr-channels"),
      "audio-params/format" to getProperty("audio-params/format"),
      "current-tracks/audio/demux-samplerate" to getProperty("current-tracks/audio/demux-samplerate"),
      "current-tracks/audio/demux-channel-count" to getProperty("current-tracks/audio/demux-channel-count"),
      "audio-bitrate" to getProperty("audio-bitrate"),
      "total-avsync-change" to getProperty("total-avsync-change"),
      "cache-used" to getProperty("cache-used"),
      "demuxer-max-bytes" to getProperty("demuxer-max-bytes"),
      "cache-speed" to getProperty("cache-speed"),
      "frame-drop-count" to getProperty("frame-drop-count"),
      "decoder-frame-drop-count" to getProperty("decoder-frame-drop-count"),
      "demuxer-cache-duration" to getProperty("demuxer-cache-duration")
    )

    if (hasVideo) {
      stats["display-fps"] = getProperty("display-fps")
      stats["video-params/pixelformat"] = getProperty("video-params/pixelformat")
      stats["video-params/hw-pixelformat"] = getProperty("video-params/hw-pixelformat")
      stats["video-params/colormatrix"] = getProperty("video-params/colormatrix")
      stats["video-params/primaries"] = getProperty("video-params/primaries")
      stats["video-params/gamma"] = getProperty("video-params/gamma")
      stats["video-params/max-luma"] = getProperty("video-params/max-luma")
      stats["video-params/min-luma"] = getProperty("video-params/min-luma")
      stats["video-params/max-cll"] = getProperty("video-params/max-cll")
      stats["video-params/max-fall"] = getProperty("video-params/max-fall")
      stats["video-params/aspect-name"] = getProperty("video-params/aspect-name")
      stats["video-params/rotate"] = getProperty("video-params/rotate")
    }

    return stats
  }

  fun observeProperty(name: String, format: String) {
    val p = player ?: return
    if (!isInitialized) return
    val fmt = when (format) {
      "double" -> PropertyFormat.Double
      "flag" -> PropertyFormat.Flag
      "string" -> PropertyFormat.String
      else -> PropertyFormat.None
    }
    p.observeProperty(name, fmt)
  }

  fun command(args: Array<String>, onComplete: ((Boolean) -> Unit)? = null) {
    commandForSource(args) { onComplete?.invoke(it.isSuccess) }
  }

  /**
   * Runs an mpv command on the ordered writer. Completes on the main thread with the playlist
   * entry id a `loadfile` created (null for every other command), or with the failure mpv
   * reported — a rejected load never starts a source, so it must not be reported as one.
   */
  fun commandForSource(args: Array<String>, onComplete: (Result<Long?>) -> Unit) {
    if (!isInitialized || disposing || args.isEmpty() || !scope.isActive) {
      onComplete(Result.failure(IllegalStateException("MPV player unavailable")))
      return
    }
    scope.launch(mpvWriteDispatcher) {
      val outcome: Result<Long?> = try {
        val runner = commandRunnerOverride
        if (runner != null) {
          Result.success(runner(args))
        } else {
          val p = player ?: throw IllegalStateException("MPV player unavailable")
          Result.success(p.command(*args))
        }
      } catch (e: Exception) {
        Log.w(TAG, "command failed", e)
        Result.failure(e)
      }
      withContext(NonCancellable + Dispatchers.Main) {
        onComplete(outcome)
      }
    }
  }

  override fun setVisible(visible: Boolean) {
    // Audio-only: no render layer to show or hide — tolerated no-op.
    if (audioOnly || disposing) return
    runOnMain {
      if (disposing) return@runOnMain
      surfaceContainer?.visibility = if (visible) View.VISIBLE else View.INVISIBLE
      if (visible) {
        flutterOverlayApplied = false
        ensureFlutterOverlayOnTop()
        rememberCurrentSurfaceSize()
        val surface = currentCandidateSurface()
        if (surface != null) {
          pendingSurface = surface
          refreshVideoOutput("setVisible")
        } else {
          val sv = surfaceView
          if (sv != null) {
            applySurfaceSize(sv.width, sv.height)
          }
        }
      }
      Log.d(TAG, "setVisible($visible)")
    }
  }

  override fun onPipModeChanged(isInPipMode: Boolean) {
    // MPV handles aspect ratio internally via its own surface management
  }

  override fun updateFrame() {
    // Audio-only: no surface to refresh — tolerated no-op.
    if (audioOnly || disposing) return
    runOnMain {
      if (disposing) return@runOnMain
      flutterOverlayApplied = false
      ensureFlutterOverlayOnTop()
      rememberCurrentSurfaceSize()
      val p = player
      if (p == null) {
        Log.d(TAG, "updateFrame(): skipping Android MPV surface refresh because player is not ready")
        return@runOnMain
      }
      if (!hasReadyVideoOutput()) {
        val surface = currentCandidateSurface()
        if (surface != null) {
          pendingSurface = surface
          refreshVideoOutput("updateFrame")
        } else {
          Log.d(TAG, "updateFrame(): skipping Android MPV surface refresh because no surface is attached")
        }
        return@runOnMain
      }
      scope.launch {
        try {
          applySurfaceSizeInternal(p, force = true)
        } catch (e: Exception) {
          Log.w(TAG, "Failed to update Android MPV surface frame", e)
        }
      }
    }
  }

  // Frame Rate Matching

  override fun setVideoFrameRate(
    fps: Float,
    videoDurationMs: Long,
    extraDelayMs: Long,
    videoWidth: Int,
    videoHeight: Int,
    matchResolution: Boolean,
    onComplete: (switched: Boolean) -> Unit
  ) {
    val mgr = frameRateManager
    if (mgr == null) {
      onComplete(false)
      return
    }
    mgr.setVideoFrameRate(fps, videoDurationMs, extraDelayMs, videoWidth, videoHeight, matchResolution) { switched ->
      player?.let {
        updateDisplayFpsOverride(it, "frame rate switch, switched=$switched") {
          onComplete(switched)
        }
      } ?: onComplete(switched)
    }
  }

  override fun clearVideoFrameRate() {
    frameRateManager?.clearVideoFrameRate(hdrActive = hdrDisplayActive)
  }

  // Cleanup

  fun dispose(onComplete: (() -> Unit)? = null) {
    if (disposing) {
      onComplete?.invoke()
      return
    }
    disposing = true
    check(Looper.myLooper() == Looper.getMainLooper())
    Log.d(TAG, "Disposing")

    val disposalComplete = CountDownLatch(1)
    nativeDisposalComplete = disposalComplete
    // Hiding a SurfaceView destroys its surface. Keep the views visible until
    // native teardown retires both consumers; Flutter's overlay stays above.

    handler.removeCallbacksAndMessages(null)

    // Clean up frame rate and audio focus.
    // releasePending (not clearVideoFrameRate): symmetric with ExoPlayerCore —
    // dispose only releases the listener/pending future. Restoring the
    // display mode is the explicit Dart-side clearVideoFrameRate's job.
    frameRateManager?.releasePending()
    frameRateManager = null
    audioFocusManager?.release()
    audioFocusManager = null

    // Cancel all coroutines
    scope.cancel()
    pendingVideoOutputRefreshJob?.cancel()
    pendingVideoOutputRefreshJob = null

    // Clear surface state flags (no native calls on main thread to avoid ANR)
    val p = player
    if (p != null) {
      hasAttachedSurface = false
      attachedSurface = null
      pausedForSurfaceLoss = false
      attachedToPlaceholder = false
      videoOutputRestoring = false
      lastAppliedSurfaceSize = null
      videoOutputEpoch += 1L
    }

    // Capture locals for deferred cleanup (audio-only has no views)
    val sv = surfaceView
    val osdSv = osdSurfaceView
    val container = surfaceContainer
    val contentView = if (audioOnly) null else activity.findViewById<ViewGroup>(android.R.id.content)
    val retiringPlaceholder = placeholder

    surfaceContainer = null
    surfaceView = null
    osdSurfaceView = null
    pendingOsdSurface = null
    attachedOsdSurface = null
    pendingVideoRectUpdate.set(null)

    // Remove layout listener synchronously
    overlayLayoutListener?.let { listener ->
      contentView?.viewTreeObserver?.removeOnGlobalLayoutListener(listener)
    }
    overlayLayoutListener = null

    pendingSurface = null
    placeholderSurface = null
    placeholder = null
    pausedForSurfaceLoss = false
    pausedForAudioFocusLoss = false
    attachedToPlaceholder = false
    videoOutputRestoring = false
    deferredResumeRequested = false
    synchronized(publicPauseIntentLock) {
      publicPauseIntentGeneration += 1L
      resumeBlockedByPublicPause = false
      desiredPaused = true
    }
    videoOutputEpoch = 0L
    isInitialized = false

    // Close the player on a background thread, then release surfaces and remove views.
    if (p != null) {
      Thread {
        try {
          // Native close blocks through decoder and VO teardown. Keep both the
          // SurfaceView surfaces and any attached placeholder alive until it returns.
          p.close()
        } catch (e: Exception) {
          Log.w(TAG, "MPV close failed", e)
        }
        disposalComplete.countDown()
        retiringPlaceholder?.close()
        player = null
        Log.d(TAG, "Disposed (native)")
        Handler(Looper.getMainLooper()).post {
          sv?.holder?.removeCallback(this)
          osdSv?.holder?.removeCallback(osdSurfaceCallback)
          if (container?.parent != null) {
            contentView?.removeView(container)
          }
          onComplete?.invoke()
        }
      }.start()
    } else {
      // No player — safe to remove views immediately
      disposalComplete.countDown()
      retiringPlaceholder?.close()
      Handler(Looper.getMainLooper()).postAtFrontOfQueue {
        sv?.holder?.removeCallback(this)
        osdSv?.holder?.removeCallback(osdSurfaceCallback)
        if (container?.parent != null) {
          contentView?.removeView(container)
        }
      }
      onComplete?.invoke()
    }

    // Reset scope for potential re-initialization
    scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
  }
}
