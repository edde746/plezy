package com.edde746.plezy.mpv

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.graphics.PixelFormat
import android.media.AudioAttributes
import android.media.ImageReader
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
import com.edde746.plezy.shared.PlayerDelegate
import com.edde746.plezy.shared.PlayerSurfaceHost
import com.edde746.plezy.shared.SurfacePlayerCore
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
  private val propertyWriterOverride: (suspend (String, String) -> Unit)?,
  initializedForTesting: Boolean
) : SurfaceHolder.Callback,
  SurfacePlayerCore {
  constructor(
    context: Context,
    audioOnly: Boolean = false,
    hardwareDecoding: Boolean = true
  ) : this(context, audioOnly, hardwareDecoding, null, false)

  internal constructor(
    context: Context,
    audioOnly: Boolean,
    propertyWriter: (suspend (String, String) -> Unit)?
  ) : this(context, audioOnly, true, propertyWriter, true)

  companion object {
    private const val TAG = "MpvPlayerCore"

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

  /** The GL vo this session is running, or null for the video plane. Non-null
   * gates off the plane-only machinery: OSD attach, aspect-fitted layout,
   * chain-failure watchdog. Written under [gpuVoReasons]. */
  @Volatile private var activeGpuVoTarget: String? = null

  /** Whether the per-file DV policy is holding hwdec at `no`; the session's
   * own hwdec value is parked in [hwdecBeforeDvReshape] meanwhile. */
  @Volatile private var dvReshapeActive: Boolean = false

  private val hwdecBeforeDvReshape = java.util.concurrent.atomic.AtomicReference<String?>()

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

  /** Hardware sessions render through the fork vo=mediacodec (see
   * [initialVideoOutput]); the OSD surface and video-rect layout exist only
   * there. */
  private val usesMediaCodecVo: Boolean
    get() = !audioOnly && hardwareDecoding
  private var overlayLayoutListener: ViewTreeObserver.OnGlobalLayoutListener? = null

  @Volatile private var disposing: Boolean = false

  @Volatile private var pendingSurface: Surface? = null

  @Volatile private var attachedSurface: Surface? = null
  private var placeholderImageReader: ImageReader? = null

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
  private var pendingVideoOutputDisableJob: Job? = null
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

  private fun ensurePlaceholderSurface() {
    if (placeholderSurface?.isValid == true) return
    placeholderImageReader?.close()
    placeholderImageReader = ImageReader.newInstance(1, 1, PixelFormat.RGBA_8888, 2)
    placeholderSurface = placeholderImageReader?.surface
    Log.d(TAG, "Created MPV placeholder surface")
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
      deferredResumeRequested = false
      synchronized(publicPauseIntentLock) {
        publicPauseIntentGeneration += 1L
        resumeBlockedByPublicPause = false
      }
      videoOutputEpoch = 0L
      pendingVideoOutputDisableJob?.cancel()
      pendingVideoOutputDisableJob = null
      lastAppliedSurfaceSize = null
      lastKnownSurfaceWidth = 0
      lastKnownSurfaceHeight = 0
      // Video-output state, so a re-initialized core does not start stranded
      // off the plane with a stale reason set.
      synchronized(gpuVoReasons) {
        gpuVoReasons.clear()
        activeGpuVoTarget = null
      }
      hwdecBeforeDvReshape.set(null)
      dvReshapeActive = false
      attachedOsdSurface = null
      videoDisplayWidth = 0
      videoDisplayHeight = 0
      videoPanscan = 0f
      videoZoomLog2 = 0f
      currentDvConversionMode = "auto"
      hdrSurfaceDecided = false
      hdrDisplayActive = false
      if (!audioOnly) ensurePlaceholderSurface()

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
          osdSurfaceView = PlayerSurfaceHost.createOsdSurface(activity, osdSurfaceCallback)
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
            p.close()
            onResult(false)
            return@launch
          }

          player = p
          isInitialized = true

          if (!audioOnly) refreshVideoOutput("initialize")

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

  private fun collectEvents(p: MpvPlayer) {
    scope.launch(start = CoroutineStart.UNDISPATCHED) {
      p.eventFlow.collect { event ->
        when (event) {
          is MpvEvent.EndFile -> {
            delegate?.onEvent("end-file", endFileDiagnostics.onEndFile(event))
          }
          is MpvEvent.StartFile -> {
            endFileDiagnostics.onStartFile()
            // The trigger is per-file (an exotic pixel format, a gralloc
            // refusal for that stream), so give the plane back to the next
            // file. A genuine failure re-arms it, costing one switch per bad
            // file instead of the whole session's HDR/10-bit scanout.
            setGpuVoRequirement(GpuVoPolicy.REASON_CHAIN_FAILURE, false)
            delegate?.onEvent("start-file", null)
          }
          is MpvEvent.FileLoaded -> {
            if (usesMediaCodecVo) {
              scope.launch(mpvWriteDispatcher, start = CoroutineStart.ATOMIC) {
                try {
                  applyDvReshapePolicy(p)
                } catch (e: CancellationException) {
                  Log.d(TAG, "Canceled DV routing policy")
                } catch (e: Exception) {
                  Log.w(TAG, "DV routing policy failed", e)
                }
              }
            }
            delegate?.onEvent("file-loaded", null)
          }
          is MpvEvent.PlaybackRestart -> delegate?.onEvent("playback-restart", null)
          else -> {}
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
        delegate?.onPropertyChange(change.name, value)
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
    pendingVideoOutputDisableJob?.cancel()
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
    if (player == null || disposing) return
    detachSurfaceInternal(reason = "surfaceDestroyed")
  }

  // OSD surface (the vo=mediacodec subtitle/OSD plane)

  private val osdSurfaceCallback = object : SurfaceHolder.Callback {
    override fun surfaceCreated(holder: SurfaceHolder) {
      if (disposing) return
      pendingOsdSurface = holder.surface.takeIf { it.isValid }
      Log.d(TAG, "OSD surface created")
      if (player != null && hasAttachedRealSurface()) {
        refreshVideoOutput("osdSurfaceCreated")
      }
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {}

    override fun surfaceDestroyed(holder: SurfaceHolder) {
      Log.d(TAG, "OSD surface destroyed")
      pendingOsdSurface = null
      val wasAttached = attachedOsdSurface != null
      attachedOsdSurface = null
      val p = player ?: return
      if (disposing || !wasAttached) return
      // Ordered against every other mpv write: a detach that overtook the
      // re-attach of a recreated surface would clear the option the attach
      // just set, and nothing re-arms it — subtitles would stay dead for the
      // rest of the session.
      scope.launch(mpvWriteDispatcher) {
        try {
          p.detachOsdSurface()
        } catch (e: Exception) {
          Log.w(TAG, "Failed to detach OSD surface", e)
        }
      }
    }
  }

  /**
   * Hands the OSD Surface to the vo. The vo reads the option when it is
   * created, so this has to run before the `vo` or `wid` write that creates
   * it, never after.
   */
  private fun attachOsdSurfaceIfNeeded(p: MpvPlayer) {
    if (!usesMediaCodecVo || activeGpuVoTarget != null) return
    val osd = pendingOsdSurface?.takeIf { it.isValid } ?: return
    if (osd === attachedOsdSurface) return
    p.attachOsdSurface(osd)
    attachedOsdSurface = osd
    Log.d(TAG, "Attached OSD surface for vo=mediacodec")
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
   * Moves the session to whatever the arbiter last decided.
   *
   * The decision is atomic under [gpuVoReasons], but the write cannot be:
   * it has to leave the lock to reach mpv. Reasons are raised from different
   * threads — per-file DV routing runs on [mpvWriteDispatcher], the gamma,
   * shader and chain-failure observers on the main thread — so the order
   * writes are *enqueued* is not the order decisions were *made*. Rather
   * than trust the target its caller saw, every transition re-reads the
   * current one here, which makes the last write the right one under any
   * interleaving. Serialized on [mpvWriteDispatcher], so the paired main
   * thread work stays in the same order too.
   */
  private fun applyGpuVoTarget() {
    scope.launch(mpvWriteDispatcher, start = CoroutineStart.ATOMIC) {
      val target = synchronized(gpuVoReasons) { activeGpuVoTarget }
      runOnMain {
        if (disposing) return@runOnMain
        if (target == null) {
          osdSurfaceView?.visibility = View.VISIBLE
        } else {
          // The gpu VOs draw their own OSD; a stale subtitle frame must not
          // linger on the overlay plane.
          osdSurfaceView?.visibility = View.GONE
          resetVideoSurfaceToFullContainer()
        }
      }
      try {
        // Before the vo write, which recreates the VO: it reads the OSD
        // surface option at creation.
        val p = player
        if (target == null && p != null) attachOsdSurfaceIfNeeded(p)
        writeProperty("vo", target ?: "mediacodec")
        if (p == null) return@launch
        if (target != null) {
          // A failed conversion chain makes mpv deselect the video track
          // ("Could not initialize video chain" -> vid=no) before the VO
          // switch lands. Re-select the explicit track id: mid-file "auto"
          // resolves to no selection rather than re-running selection.
          if (p.getString("vid").let { it == null || it == "no" }) {
            val videoTrackId = videoTracks(p).firstOrNull()?.optLong("id")
            if (videoTrackId != null) {
              Log.i(TAG, "Re-selecting video track $videoTrackId after chain failure")
              writeProperty("vid", videoTrackId.toString())
            }
          }
        }
        applySurfaceSizeInternal(p, force = true)
        if (target == null) {
          // Refit the surfaces to the aspect rectangle now that the plane
          // owns scaling again (the gpu VOs letterboxed within full
          // containers).
          applyVideoRectLayout()
        }
      } catch (e: CancellationException) {
        Log.d(TAG, "Canceled vo transition write")
      } catch (e: Exception) {
        Log.w(TAG, "Failed to move the video output to ${target ?: "mediacodec"}", e)
      }
    }
  }

  /**
   * Per-file Dolby Vision routing, decided from the bitstream: mpv exports
   * the DOVI configuration record's profile on the track list (never trust
   * server metadata for this — it mis-tags DV routinely). Re-evaluated on
   * every file-loaded, so a following non-P5 file restores hardware decode
   * and returns to the video plane.
   */
  private suspend fun applyDvReshapePolicy(p: MpvPlayer) {
    val profile = selectedVideoDvProfile(p)
    val needs = GpuVoPolicy.needsDvReshaping(
      dvProfile = profile,
      conversionMode = currentDvConversionMode,
      canPlayP5Natively = DoviBridge.canPlayDolbyVisionP5(context)
    )
    if (needs == dvReshapeActive) return
    dvReshapeActive = needs
    if (needs) {
      Log.i(TAG, "DV P5 (bitstream) without native support: software decode + gpu-next reshaping")
      val current = p.getString("hwdec")
      hwdecBeforeDvReshape.set(current ?: "no")
      writeProperty("hwdec", "no")
    } else {
      val restore = hwdecBeforeDvReshape.getAndSet(null)
      if (restore != null && restore != "no") writeProperty("hwdec", restore)
    }
    setGpuVoRequirement(GpuVoPolicy.REASON_DV_RESHAPE, needs)
  }

  /**
   * Selected video track's Dolby Vision profile, or null for non-DV content
   * (mpv omits the field when the bitstream carries no DOVI configuration
   * record).
   */
  private suspend fun selectedVideoDvProfile(p: MpvPlayer): Long? = videoTracks(p).firstOrNull()
    ?.takeIf { it.has("dolby-vision-profile") }
    ?.getLong("dolby-vision-profile")

  /**
   * Observed rather than derived from the hardware-decoding setting because
   * the fallback is decided per file, inside mpv. Why it matters:
   * [GpuVoPolicy.needsSoftwareRender].
   */
  private fun collectDecoderState(p: MpvPlayer) {
    scope.launch(start = CoroutineStart.UNDISPATCHED) {
      p.observeString("hwdec-current").collect { value ->
        setGpuVoRequirement(GpuVoPolicy.REASON_SW_DECODE, GpuVoPolicy.needsSoftwareRender(value))
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
   * The OSD surface is left full-container: the vo builds its `mp_osd_res`
   * from the OSD window's own size, so libass keeps the whole window as its
   * canvas — subtitles sit in the letterbox bars as they did under vo=gpu,
   * and stay on screen when a zoomed image runs past the container.
   */
  private fun applyVideoRectLayout() {
    if (!usesMediaCodecVo || activeGpuVoTarget != null) return
    runOnMain {
      if (disposing) return@runOnMain
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
      surfaceView?.let { view ->
        val lp = view.layoutParams as android.widget.FrameLayout.LayoutParams
        if (lp.width != size.width || lp.height != size.height || lp.gravity != android.view.Gravity.CENTER) {
          lp.width = size.width
          lp.height = size.height
          lp.gravity = android.view.Gravity.CENTER
          view.layoutParams = lp
        }
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

  private fun currentCandidateSurface(): Surface? = surfaceView?.holder?.surface?.takeIf { it.isValid }
    ?: pendingSurface?.takeIf { it.isValid }

  private fun hasAttachedRealSurface(): Boolean = hasAttachedSurface && !attachedToPlaceholder && (attachedSurface?.isValid == true)

  // Audio-only mode has no video output to wait for — playback and resume
  // paths gated on output readiness must always proceed there.
  private fun hasReadyVideoOutput(): Boolean = audioOnly || (hasAttachedRealSurface() && !videoOutputRestoring)

  private fun isCurrentVideoOutputEpoch(epoch: Long): Boolean = !disposing && epoch == videoOutputEpoch

  private fun isVideoOutputRefreshCurrent(epoch: Long): Boolean {
    if (disposing) return false
    if (epoch != videoOutputEpoch) return false
    return hasAttachedRealSurface()
  }

  private fun refreshVideoOutput(reason: String) {
    if (audioOnly || disposing) return

    rememberCurrentSurfaceSize()
    val p = player
    val surface = currentCandidateSurface()
    if (p == null) {
      pendingSurface = surface?.takeIf { it.isValid }
      Log.d(TAG, "refreshVideoOutput($reason): player not ready yet")
      return
    }

    if (surface == null || !surface.isValid) {
      hasAttachedSurface = false
      attachedSurface = null
      attachedToPlaceholder = false
      pendingSurface = null
      lastAppliedSurfaceSize = null
      videoOutputRestoring = true
      Log.d(TAG, "refreshVideoOutput($reason): no valid surface available")
      return
    }

    val refreshEpoch = videoOutputEpoch
    pendingVideoOutputDisableJob?.cancel()
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
            hasAttachedSurface = false
            attachedSurface = null
            attachedToPlaceholder = false
            pendingSurface = null
            lastAppliedSurfaceSize = null
            videoOutputRestoring = true
            Log.d(TAG, "Skipping MPV video output refresh with invalid surface ($reason, epoch=$refreshEpoch)")
            return@withLock
          }

          // An unattached OSD Surface forces a wid re-attach: the VO reads the
          // OSD surface option at creation, and setting wid recreates the VO.
          // Suppressed off the plane, where the GL vo draws its own OSD.
          val osdNeedsAttach = activeGpuVoTarget == null && pendingOsdSurface !== attachedOsdSurface
          val needsAttach = !hasAttachedSurface || attachedSurface !== surface || osdNeedsAttach
          val wasAttachedToPlaceholder = attachedToPlaceholder
          val wasPausedForSurfaceLoss = pausedForSurfaceLoss
          if (needsAttach) {
            attachOsdSurfaceIfNeeded(p)
            p.attachSurface(surface)
            attachedSurface = surface
            hasAttachedSurface = true
            attachedToPlaceholder = false
            pendingSurface = null
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
        Log.w(TAG, "Failed to finalize MPV video output refresh ($reason)", e)
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

  private fun schedulePlaceholderSurfaceAttach(
    p: MpvPlayer,
    reason: String,
    epoch: Long
  ) {
    pendingVideoOutputDisableJob?.cancel()
    pendingVideoOutputDisableJob = scope.launch(Dispatchers.IO) {
      try {
        videoOutputMutex.withLock {
          if (!isCurrentVideoOutputEpoch(epoch)) {
            Log.d(TAG, "Skipping stale MPV placeholder attach ($reason, epoch=$epoch)")
            return@withLock
          }
          publicPauseWriteMutex.withLock {
            val wasPaused = try {
              p.getFlag("pause") == true
            } catch (e: Exception) {
              cachedPaused
            }
            if (!wasPaused) {
              try {
                p.setProperty("pause", true)
                cachedPaused = true
                pausedForSurfaceLoss = true
                Log.d(TAG, "Paused MPV for surface loss ($reason, epoch=$epoch)")
              } catch (e: Exception) {
                pausedForSurfaceLoss = false
                Log.w(TAG, "Failed to pause MPV before placeholder attach ($reason)", e)
              }
            } else {
              pausedForSurfaceLoss = false
            }
          }
          val surface = placeholderSurface?.takeIf { it.isValid } ?: run {
            Log.w(TAG, "No valid MPV placeholder surface available for $reason")
            return@withLock
          }
          p.attachSurface(surface)
          attachedSurface = surface
          hasAttachedSurface = true
          attachedToPlaceholder = true
          lastAppliedSurfaceSize = null
          Log.d(TAG, "Attached MPV placeholder surface ($reason, epoch=$epoch)")
        }
      } catch (e: CancellationException) {
        Log.d(TAG, "Canceled pending MPV placeholder attach ($reason, epoch=$epoch)")
      } catch (e: Exception) {
        Log.w(TAG, "Failed to attach MPV placeholder surface ($reason)", e)
      }
    }
  }

  private fun detachSurfaceInternal(reason: String) {
    val hadAttachedSurface = hasAttachedSurface || attachedSurface != null
    hasAttachedSurface = false
    attachedSurface = null
    attachedToPlaceholder = false
    videoOutputRestoring = true
    lastAppliedSurfaceSize = null
    val detachEpoch = videoOutputEpoch + 1L
    videoOutputEpoch = detachEpoch

    val p = player ?: return
    if (!hadAttachedSurface) {
      Log.d(TAG, "detachSurfaceInternal($reason): no attached surface to clear")
      return
    }

    schedulePlaceholderSurfaceAttach(
      p = p,
      reason = reason,
      epoch = detachEpoch
    )
    Log.d(TAG, "Cleared MPV surface attachment ($reason, epoch=$detachEpoch)")
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

    // While the per-file DV policy holds hwdec at `no`, park writes instead
    // of applying them: a hardware value under gpu-next would lose the RPU
    // side data (and blue-screen the Tegra class, #2010). The parked value
    // is restored when a non-P5 file drops the requirement.
    if (name == "hwdec" && dvReshapeActive) {
      hwdecBeforeDvReshape.set(value)
      onComplete?.invoke(Result.success(Unit))
      return
    }

    val paused = if (name == "pause") normalizePauseValue(value) else null
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
    if (!isInitialized || disposing || args.isEmpty() || !scope.isActive) {
      onComplete?.invoke(false)
      return
    }
    scope.launch(mpvWriteDispatcher) {
      var success = false
      try {
        player?.command(*args)
        success = true
      } catch (e: Exception) {
        Log.w(TAG, "command failed", e)
      } finally {
        withContext(NonCancellable + Dispatchers.Main) {
          onComplete?.invoke(success)
        }
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

    surfaceContainer?.let { container ->
      container.visibility = View.INVISIBLE
      Log.d(TAG, "Hiding surface container during dispose")
    }

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
    pendingVideoOutputDisableJob?.cancel()
    pendingVideoOutputDisableJob = null
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

    surfaceContainer = null
    surfaceView = null
    osdSurfaceView = null
    pendingOsdSurface = null
    attachedOsdSurface = null

    // Remove layout listener synchronously
    overlayLayoutListener?.let { listener ->
      contentView?.viewTreeObserver?.removeOnGlobalLayoutListener(listener)
    }
    overlayLayoutListener = null

    pendingSurface = null
    placeholderSurface?.release()
    placeholderSurface = null
    placeholderImageReader?.close()
    placeholderImageReader = null
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
    pendingVideoOutputDisableJob = null
    isInitialized = false

    // Detach surface and close player on background thread, then remove views
    if (p != null) {
      Thread {
        try {
          // Detach surface BEFORE close to prevent GPU mutex contention with
          // view removal (audio-only never attached one)
          if (!audioOnly) {
            try {
              runBlocking {
                p.setProperty("force-window", "no")
                p.setProperty("vo", "null")
              }
              p.detachSurface()
            } catch (e: Exception) {
              Log.w(TAG, "Failed to detach surface during dispose", e)
            }
          }
          p.close()
        } catch (e: Exception) {
          Log.w(TAG, "MPV close failed", e)
        }
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
