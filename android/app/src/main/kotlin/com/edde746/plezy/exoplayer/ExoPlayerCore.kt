package com.edde746.plezy.exoplayer

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.Surface
import android.view.SurfaceView
import android.view.TextureView
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.view.WindowManager
import android.widget.FrameLayout
import androidx.annotation.OptIn
import androidx.annotation.RequiresApi
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.text.CueGroup
import androidx.media3.common.TrackGroup
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.Tracks
import androidx.media3.common.VideoSize
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.extractor.DefaultExtractorsFactory
import androidx.media3.ui.CaptionStyleCompat
import androidx.media3.ui.SubtitleView
import io.github.peerless2012.ass.media.kt.buildWithAssSupport
import io.github.peerless2012.ass.media.type.AssRenderType
import java.math.BigDecimal
import java.math.RoundingMode

interface ExoPlayerDelegate {
    fun onPropertyChange(name: String, value: Any?)
    fun onEvent(name: String, data: Map<String, Any>?)

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
        private const val SHORT_VIDEO_LENGTH_MS = 300000L // 5 minutes
    }

    private var surfaceView: SurfaceView? = null
    private var surfaceContainer: FrameLayout? = null
    private var subtitleView: SubtitleView? = null
    private var overlayLayoutListener: ViewTreeObserver.OnGlobalLayoutListener? = null
    private var exoPlayer: ExoPlayer? = null
    private var trackSelector: DefaultTrackSelector? = null
    var delegate: ExoPlayerDelegate? = null
    var isInitialized: Boolean = false
        private set

    // Frame rate matching
    private var currentVideoFps: Float = 0f
    private var displayListener: DisplayManager.DisplayListener? = null
    private val handler = Handler(Looper.getMainLooper())

    // Audio focus
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private var hasAudioFocus: Boolean = false
    private var wasPlayingBeforeFocusLoss: Boolean = false

    // Track state for event emission
    private var lastPosition: Long = 0
    private var lastDuration: Long = 0
    private var lastBufferedPosition: Long = 0
    private var positionUpdateRunnable: Runnable? = null

    // External subtitles added dynamically
    private val externalSubtitles = mutableListOf<MediaItem.SubtitleConfiguration>()
    private var currentMediaUri: String? = null
    private var currentHeaders: Map<String, String>? = null

    private val audioFocusChangeListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
        when (focusChange) {
            AudioManager.AUDIOFOCUS_GAIN -> {
                Log.d(TAG, "Audio focus gained")
                hasAudioFocus = true
                if (wasPlayingBeforeFocusLoss && isInitialized) {
                    exoPlayer?.play()
                    wasPlayingBeforeFocusLoss = false
                }
            }
            AudioManager.AUDIOFOCUS_LOSS -> {
                Log.d(TAG, "Audio focus lost permanently")
                hasAudioFocus = false
                if (isInitialized) {
                    wasPlayingBeforeFocusLoss = exoPlayer?.isPlaying == true
                    exoPlayer?.pause()
                }
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT,
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                Log.d(TAG, "Audio focus lost transiently")
                hasAudioFocus = false
                if (isInitialized) {
                    wasPlayingBeforeFocusLoss = exoPlayer?.isPlaying == true
                    exoPlayer?.pause()
                }
            }
        }
    }

    private fun ensureFlutterOverlayOnTop() {
        val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
        contentView.post {
            var flutterContainer: ViewGroup? = null

            for (i in 0 until contentView.childCount) {
                val child = contentView.getChildAt(i)
                if (child is ViewGroup && child.javaClass.name.contains("FlutterView")) {
                    flutterContainer = child
                    break
                }
            }

            if (flutterContainer == null) {
                for (i in contentView.childCount - 1 downTo 0) {
                    val child = contentView.getChildAt(i)
                    if (child is ViewGroup && child != surfaceContainer && child.childCount > 0) {
                        flutterContainer = child
                        break
                    }
                }
            }

            flutterContainer?.let { container ->
                contentView.bringChildToFront(container)
                for (j in 0 until container.childCount) {
                    val flutterChild = container.getChildAt(j)
                    if (flutterChild is SurfaceView) {
                        // Don't use setZOrderOnTop - let Flutter render in normal view order
                        // This allows SubtitleView (added via addContentView) to render above
                        flutterChild.setZOrderOnTop(false)
                        flutterChild.setZOrderMediaOverlay(true)
                        flutterChild.holder.setFormat(PixelFormat.TRANSLUCENT)
                        break
                    } else if (flutterChild is TextureView) {
                        flutterChild.isOpaque = false
                        break
                    }
                }
            }

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
                } else if (child is TextureView) {
                    child.isOpaque = false
                }
            }
        }
    }

    fun initialize(): Boolean {
        if (isInitialized) {
            Log.d(TAG, "Already initialized")
            return true
        }

        try {
            audioManager = activity.getSystemService(Context.AUDIO_SERVICE) as AudioManager

            // Create FrameLayout container for video (enables centering for aspect ratio)
            surfaceContainer = FrameLayout(activity).apply {
                layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
                setBackgroundColor(Color.BLACK)
            }

            // Create SurfaceView for video rendering
            surfaceView = SurfaceView(activity).apply {
                layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                ).apply {
                    gravity = Gravity.CENTER
                }
                holder.addCallback(surfaceCallback)
                setZOrderOnTop(false)
                setZOrderMediaOverlay(false)
            }

            surfaceContainer!!.addView(surfaceView)

            // Create SubtitleView - will be added to surfaceContainer above video
            // With OVERLAY_CANVAS mode, libass-android adds AssSubtitleView as a child
            // which renders ASS subtitles with full styling
            subtitleView = SubtitleView(activity).apply {
                layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                )
            }
            Log.d(TAG, "SubtitleView created")

            val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
            contentView.addView(surfaceContainer, 0)

            // Find FlutterView and configure z-order
            // Video SurfaceView is at the bottom (setZOrderOnTop=false, setZOrderMediaOverlay=false)
            // Flutter SurfaceView uses setZOrderMediaOverlay to render above video
            // SubtitleView will be added to surfaceContainer so Flutter stays on top
            for (i in 0 until contentView.childCount) {
                val child = contentView.getChildAt(i)
                if (child is ViewGroup && child.javaClass.name.contains("FlutterView")) {
                    contentView.bringChildToFront(child)
                    for (j in 0 until child.childCount) {
                        val flutterChild = child.getChildAt(j)
                        if (flutterChild is SurfaceView) {
                            // Use setZOrderMediaOverlay instead of setZOrderOnTop
                            // This puts Flutter above video but below normal views
                            flutterChild.setZOrderOnTop(false)
                            flutterChild.setZOrderMediaOverlay(true)
                            flutterChild.holder.setFormat(PixelFormat.TRANSLUCENT)
                            break
                        }
                    }
                    break
                }
            }

            // Add SubtitleView just below FlutterView so it stays above video but below Flutter UI
            var flutterViewIndex: Int? = null
            for (i in 0 until contentView.childCount) {
                val child = contentView.getChildAt(i)
                if (child is ViewGroup && child.javaClass.name.contains("FlutterView")) {
                    flutterViewIndex = i
                    break
                }
            }
            if (flutterViewIndex != null) {
                contentView.addView(subtitleView, flutterViewIndex)
                Log.d(TAG, "SubtitleView added below FlutterView at index $flutterViewIndex")
            } else {
                contentView.addView(subtitleView)
                Log.d(TAG, "SubtitleView added to contentView (FlutterView not found)")
            }
            ensureFlutterOverlayOnTop()
            overlayLayoutListener = ViewTreeObserver.OnGlobalLayoutListener {
                ensureFlutterOverlayOnTop()
            }
            contentView.viewTreeObserver.addOnGlobalLayoutListener(overlayLayoutListener)

            Log.d(TAG, "SurfaceView added to content view")

            // Create track selector with text tracks enabled
            trackSelector = DefaultTrackSelector(activity).apply {
                setParameters(
                    buildUponParameters()
                        .setTunnelingEnabled(true)
                        .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, false)
                        .setPreferredTextLanguage("en")
                )
            }

            // Create ExoPlayer with FFmpeg audio decoder fallback
            val audioAttributes = androidx.media3.common.AudioAttributes.Builder()
                .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
                .setUsage(C.USAGE_MEDIA)
                .build()

            // Use DefaultRenderersFactory with FFmpeg fallback for unsupported audio codecs
            val renderersFactory = DefaultRenderersFactory(activity).apply {
                // Enable decoder fallback - if MediaCodec fails, try FFmpeg
                setEnableDecoderFallback(true)
                // Use FFmpeg decoders as fallback (not preferred over native)
                setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_ON)
            }

            // Create factories for buildWithAssSupport (like AndroidTV-FireTV)
            val dataSourceFactory = DefaultDataSource.Factory(activity)
            val extractorsFactory = DefaultExtractorsFactory()

            // Use buildWithAssSupport with OVERLAY_CANVAS mode for proper libass rendering
            // This renders ASS subtitles with full styling via AssSubtitleView
            Log.d(TAG, "SubtitleView childCount before buildWithAssSupport: ${subtitleView?.childCount}")
            exoPlayer = ExoPlayer.Builder(activity)
                .setTrackSelector(trackSelector!!)
                .setAudioAttributes(audioAttributes, false) // We handle audio focus manually
                .buildWithAssSupport(
                    context = activity,
                    renderType = AssRenderType.OVERLAY_CANVAS,  // Use OVERLAY mode for libass styling
                    subtitleView = subtitleView,
                    dataSourceFactory = dataSourceFactory,
                    extractorsFactory = extractorsFactory,
                    renderersFactory = renderersFactory
                )
                .also { player ->
                    player.addListener(this)
                    surfaceView?.let { player.setVideoSurfaceView(it) }
                }
            Log.d(TAG, "SubtitleView childCount after buildWithAssSupport: ${subtitleView?.childCount}")
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
            Log.d(TAG, "Surface created")
            ensureFlutterOverlayOnTop()
        }

        override fun surfaceChanged(holder: android.view.SurfaceHolder, format: Int, width: Int, height: Int) {
            Log.d(TAG, "Surface changed: ${width}x${height}")
        }

        override fun surfaceDestroyed(holder: android.view.SurfaceHolder) {
            Log.d(TAG, "Surface destroyed")
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

    // Player.Listener

    override fun onCues(cueGroup: CueGroup) {
        // With OVERLAY_CANVAS mode, ASS subtitles are rendered directly by AssSubtitleView
        // This callback is for non-ASS subtitles (SRT, VTT, etc.)
        if (cueGroup.cues.isNotEmpty()) {
            Log.d(TAG, "onCues: received ${cueGroup.cues.size} cues (non-ASS)")
        }
        subtitleView?.setCues(cueGroup.cues)
    }

    override fun onIsPlayingChanged(isPlaying: Boolean) {
        Log.d(TAG, "onIsPlayingChanged: $isPlaying")
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
        Log.d(TAG, "onPlaybackStateChanged: $stateStr")

        when (state) {
            Player.STATE_BUFFERING -> {
                delegate?.onPropertyChange("paused-for-cache", true)
            }
            Player.STATE_READY -> {
                delegate?.onPropertyChange("paused-for-cache", false)
                delegate?.onEvent("playback-restart", null)
                emitTrackList()
            }
            Player.STATE_ENDED -> {
                delegate?.onPropertyChange("eof-reached", true)
                delegate?.onEvent("end-file", mapOf("reason" to "eof"))
            }
        }
    }

    override fun onTracksChanged(tracks: Tracks) {
        Log.d(TAG, "onTracksChanged")
        emitTrackList()
    }

    override fun onPlayerError(error: PlaybackException) {
        Log.e(TAG, "Player error: ${error.message}", error)

        // Detect format/codec unsupported errors
        val isFormatUnsupported = when {
            error.errorCode == PlaybackException.ERROR_CODE_DECODING_FAILED -> true
            error.errorCode == PlaybackException.ERROR_CODE_DECODER_INIT_FAILED -> true
            error.errorCode == PlaybackException.ERROR_CODE_DECODER_QUERY_FAILED -> true
            error.cause?.message?.contains("EXCEEDS_CAPABILITIES") == true -> true
            error.cause?.message?.contains("MediaCodec") == true -> true
            else -> false
        }

        if (isFormatUnsupported && currentMediaUri != null) {
            Log.w(TAG, "Format unsupported - attempting fallback to MPV")
            val handled = delegate?.onFormatUnsupported(
                uri = currentMediaUri!!,
                headers = currentHeaders,
                positionMs = lastPosition,
                errorMessage = error.message ?: "Unknown format error"
            ) ?: false

            if (handled) {
                // Fallback was handled by the plugin, don't emit error
                return
            }
        }

        // Fallback not handled or not a format error - emit error event
        delegate?.onEvent("end-file", mapOf(
            "reason" to "error",
            "message" to (error.message ?: "Unknown error")
        ))
    }

    override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
        Log.d(TAG, "onMediaItemTransition: ${mediaItem?.mediaId}, reason: $reason")
        delegate?.onEvent("file-loaded", null)
        delegate?.onPropertyChange("eof-reached", false)
    }

    override fun onVideoSizeChanged(videoSize: VideoSize) {
        Log.d(TAG, "Video size changed: ${videoSize.width}x${videoSize.height}, ratio: ${videoSize.pixelWidthHeightRatio}")
        updateSurfaceViewSize(videoSize.width, videoSize.height, videoSize.pixelWidthHeightRatio)
    }

    private fun updateSurfaceViewSize(videoWidth: Int, videoHeight: Int, pixelRatio: Float) {
        if (videoWidth == 0 || videoHeight == 0) return

        val surface = surfaceView ?: return
        val subtitle = subtitleView
        val contentView = activity.findViewById<ViewGroup>(android.R.id.content)

        val containerWidth = contentView.width
        val containerHeight = contentView.height
        if (containerWidth == 0 || containerHeight == 0) return

        // Calculate video aspect ratio (accounting for non-square pixels)
        val videoAspect = (videoWidth * pixelRatio) / videoHeight
        val containerAspect = containerWidth.toFloat() / containerHeight

        val (newWidth, newHeight) = if (videoAspect > containerAspect) {
            // Video is wider - fit to width, letterbox top/bottom
            containerWidth to (containerWidth / videoAspect).toInt()
        } else {
            // Video is taller - fit to height, pillarbox left/right
            (containerHeight * videoAspect).toInt() to containerHeight
        }

        activity.runOnUiThread {
            surface.layoutParams = FrameLayout.LayoutParams(newWidth, newHeight).apply {
                gravity = Gravity.CENTER
            }
            surface.requestLayout()
            subtitle?.let { sv ->
                sv.layoutParams = FrameLayout.LayoutParams(newWidth, newHeight).apply {
                    gravity = Gravity.CENTER
                }
                sv.requestLayout()
            }
        }
    }

    private fun emitTrackList() {
        val player = exoPlayer ?: return
        val tracks = player.currentTracks

        val trackList = mutableListOf<Map<String, Any?>>()

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

        // Process subtitle tracks
        Log.d(TAG, "emitTrackList: found ${textGroups.size} subtitle track groups")
        textGroups.forEachIndexed { groupIndex, group ->
            val trackGroup = group.mediaTrackGroup
            val format = trackGroup.getFormat(0)
            val trackId = "${C.TRACK_TYPE_TEXT}_$groupIndex"
            val isSelected = group.isSelected

            Log.d(TAG, "Subtitle track $groupIndex: codec=${format.codecs}, lang=${format.language}, selected=$isSelected")

            val track = mutableMapOf<String, Any?>(
                "type" to "sub",
                "id" to trackId,
                "title" to format.label,
                "lang" to format.language,
                "codec" to format.codecs,
                "default" to (format.selectionFlags and C.SELECTION_FLAG_DEFAULT != 0),
                "selected" to isSelected,
                "external" to false
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
        selectedAudioId?.let { delegate?.onPropertyChange("aid", it) }
        if (selectedSubId != null) {
            delegate?.onPropertyChange("sid", selectedSubId)
        } else if (textGroups.isNotEmpty()) {
            // No subtitle selected
            delegate?.onPropertyChange("sid", "no")
        }

        // Add external subtitles to track list
        externalSubtitles.forEachIndexed { index, subtitle ->
            val extTrackId = "ext_sub_$index"
            trackList.add(mapOf(
                "type" to "sub",
                "id" to extTrackId,
                "title" to (subtitle.label ?: "External"),
                "lang" to subtitle.language,
                "codec" to subtitle.mimeType,
                "default" to false,
                "external" to true,
                "external-filename" to subtitle.uri.toString()
            ))
        }

        delegate?.onPropertyChange("track-list", trackList)
    }

    // Public API

    fun open(uri: String, headers: Map<String, String>?, startPositionMs: Long, autoPlay: Boolean) {
        if (!isInitialized) return

        currentMediaUri = uri
        currentHeaders = headers
        externalSubtitles.clear()

        val mediaItemBuilder = MediaItem.Builder()
            .setUri(uri)

        // Add headers if provided
        if (!headers.isNullOrEmpty()) {
            val dataSourceFactory = androidx.media3.datasource.DefaultHttpDataSource.Factory()
                .setDefaultRequestProperties(headers)
            // Note: For proper header support, we'd need to configure this at player level
            // For now, headers are handled via URL parameters if needed
        }

        val mediaItem = mediaItemBuilder.build()

        exoPlayer?.apply {
            setMediaItem(mediaItem, startPositionMs)
            prepare()
            playWhenReady = autoPlay
        }

        Log.d(TAG, "Opened: $uri, startPosition: ${startPositionMs}ms, autoPlay: $autoPlay")
    }

    fun play() {
        exoPlayer?.play()
    }

    fun pause() {
        exoPlayer?.pause()
    }

    fun stop() {
        exoPlayer?.stop()
        setVisible(false)
    }

    fun seekTo(positionMs: Long) {
        exoPlayer?.seekTo(positionMs)
    }

    fun setVolume(volume: Float) {
        exoPlayer?.volume = volume.coerceIn(0f, 1f)
        delegate?.onPropertyChange("volume", (volume * 100).toDouble())
    }

    fun setPlaybackSpeed(speed: Float) {
        exoPlayer?.setPlaybackSpeed(speed.coerceIn(0.25f, 4f))
        delegate?.onPropertyChange("speed", speed.toDouble())
    }

    fun selectAudioTrack(trackId: String) {
        val player = exoPlayer ?: return
        val selector = trackSelector ?: return

        // Parse track ID (format: "type_index")
        val parts = trackId.split("_")
        if (parts.size < 2) return

        val trackIndex = parts[1].toIntOrNull() ?: return

        val audioGroups = player.currentTracks.groups.filter { it.type == C.TRACK_TYPE_AUDIO }
        if (trackIndex >= 0 && trackIndex < audioGroups.size) {
            val group = audioGroups[trackIndex]
            selector.parameters = selector.buildUponParameters()
                .setOverrideForType(TrackSelectionOverride(group.mediaTrackGroup, 0))
                .setTrackTypeDisabled(C.TRACK_TYPE_AUDIO, false)
                .build()

            delegate?.onPropertyChange("aid", trackId)
        }
    }

    fun selectSubtitleTrack(trackId: String?) {
        val player = exoPlayer ?: return
        val selector = trackSelector ?: return

        if (trackId == null || trackId == "no") {
            // Disable subtitles
            selector.parameters = selector.buildUponParameters()
                .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true)
                .build()
            delegate?.onPropertyChange("sid", "no")
            return
        }

        // Check if external subtitle
        if (trackId.startsWith("ext_sub_")) {
            val index = trackId.removePrefix("ext_sub_").toIntOrNull() ?: return
            if (index >= 0 && index < externalSubtitles.size) {
                // Reload media with selected external subtitle
                reloadWithExternalSubtitle(index)
                return
            }
        }

        // Parse track ID for embedded subtitles
        val parts = trackId.split("_")
        if (parts.size < 2) return

        val trackIndex = parts[1].toIntOrNull() ?: return

        val textGroups = player.currentTracks.groups.filter { it.type == C.TRACK_TYPE_TEXT }
        if (trackIndex >= 0 && trackIndex < textGroups.size) {
            val group = textGroups[trackIndex]
            selector.parameters = selector.buildUponParameters()
                .setOverrideForType(TrackSelectionOverride(group.mediaTrackGroup, 0))
                .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, false)
                .build()

            delegate?.onPropertyChange("sid", trackId)
        }
    }

    private fun reloadWithExternalSubtitle(subtitleIndex: Int) {
        val uri = currentMediaUri ?: return
        val player = exoPlayer ?: return

        val currentPosition = player.currentPosition
        val wasPlaying = player.isPlaying

        val mediaItemBuilder = MediaItem.Builder()
            .setUri(uri)

        // Add the selected external subtitle
        if (subtitleIndex >= 0 && subtitleIndex < externalSubtitles.size) {
            val subtitle = externalSubtitles[subtitleIndex]
            mediaItemBuilder.setSubtitleConfigurations(listOf(subtitle))
        }

        val mediaItem = mediaItemBuilder.build()

        player.setMediaItem(mediaItem, currentPosition)
        player.prepare()
        player.playWhenReady = wasPlaying

        delegate?.onPropertyChange("sid", "ext_sub_$subtitleIndex")
    }

    fun addSubtitleTrack(uri: String, title: String?, language: String?, mimeType: String?, select: Boolean) {
        val subtitleConfig = MediaItem.SubtitleConfiguration.Builder(Uri.parse(uri))
            .setLabel(title ?: "External")
            .setLanguage(language)
            .setMimeType(mimeType ?: detectSubtitleMimeType(uri))
            .setSelectionFlags(if (select) C.SELECTION_FLAG_DEFAULT else 0)
            .build()

        externalSubtitles.add(subtitleConfig)

        // Emit updated track list
        emitTrackList()

        if (select) {
            selectSubtitleTrack("ext_sub_${externalSubtitles.size - 1}")
        }
    }

    private fun detectSubtitleMimeType(uri: String): String {
        val lowerUri = uri.lowercase()
        return when {
            lowerUri.endsWith(".srt") -> MimeTypes.APPLICATION_SUBRIP
            lowerUri.endsWith(".ass") || lowerUri.endsWith(".ssa") -> MimeTypes.TEXT_SSA
            lowerUri.endsWith(".vtt") -> MimeTypes.TEXT_VTT
            lowerUri.endsWith(".ttml") -> MimeTypes.APPLICATION_TTML
            else -> MimeTypes.APPLICATION_SUBRIP
        }
    }

    fun setVisible(visible: Boolean) {
        activity.runOnUiThread {
            surfaceContainer?.visibility = if (visible) View.VISIBLE else View.INVISIBLE
            // subtitleView is inside surfaceContainer, inherits visibility
            Log.d(TAG, "setVisible($visible)")
        }
    }

    // Audio Focus

    fun requestAudioFocus(): Boolean {
        val am = audioManager ?: return false

        Log.d(TAG, "Requesting audio focus")

        val result = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MOVIE)
                        .build()
                )
                .setOnAudioFocusChangeListener(audioFocusChangeListener, handler)
                .setWillPauseWhenDucked(true)
                .build()

            audioFocusRequest = focusRequest
            am.requestAudioFocus(focusRequest)
        } else {
            @Suppress("DEPRECATION")
            am.requestAudioFocus(
                audioFocusChangeListener,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN
            )
        }

        hasAudioFocus = (result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED)
        Log.d(TAG, "Audio focus request result: $result, granted: $hasAudioFocus")
        return hasAudioFocus
    }

    fun abandonAudioFocus() {
        val am = audioManager ?: return

        Log.d(TAG, "Abandoning audio focus")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { am.abandonAudioFocusRequest(it) }
            audioFocusRequest = null
        } else {
            @Suppress("DEPRECATION")
            am.abandonAudioFocus(audioFocusChangeListener)
        }

        hasAudioFocus = false
        wasPlayingBeforeFocusLoss = false
    }

    // Frame Rate Matching

    private fun getDisplayManager(): DisplayManager {
        return activity.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
    }

    fun setVideoFrameRate(fps: Float, videoDurationMs: Long) {
        currentVideoFps = fps
        if (fps <= 0f) {
            Log.d(TAG, "setVideoFrameRate: Invalid fps ($fps), skipping")
            return
        }

        val surface = surfaceView?.holder?.surface
        if (surface == null) {
            Log.d(TAG, "setVideoFrameRate: Surface not available")
            return
        }

        Log.d(TAG, "setVideoFrameRate: fps=$fps, duration=${videoDurationMs}ms, API=${Build.VERSION.SDK_INT}")

        when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> setFrameRateS(fps, surface, videoDurationMs)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> setFrameRateR(fps, surface)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> setFrameRateM(fps)
        }
    }

    fun clearVideoFrameRate() {
        Log.d(TAG, "clearVideoFrameRate")
        currentVideoFps = 0f
        displayListener?.let {
            getDisplayManager().unregisterDisplayListener(it)
            displayListener = null
        }
    }

    private fun registerDisplayListener() {
        displayListener?.let {
            getDisplayManager().unregisterDisplayListener(it)
        }

        displayListener = object : DisplayManager.DisplayListener {
            override fun onDisplayAdded(displayId: Int) = Unit
            override fun onDisplayRemoved(displayId: Int) = Unit
            override fun onDisplayChanged(displayId: Int) {
                handler.postDelayed({
                    if (exoPlayer?.isPlaying == false && wasPlayingBeforeFocusLoss) {
                        Log.d(TAG, "Display changed, resuming playback")
                        exoPlayer?.play()
                    }
                }, 2000L)
                getDisplayManager().unregisterDisplayListener(this)
                displayListener = null
            }
        }
        getDisplayManager().registerDisplayListener(displayListener, handler)
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun setFrameRateR(fps: Float, surface: Surface) {
        Log.d(TAG, "setFrameRateR: Setting frame rate to $fps")
        surface.setFrameRate(fps, Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE)
        registerDisplayListener()
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private fun setFrameRateS(fps: Float, surface: Surface, videoDurationMs: Long) {
        Log.d(TAG, "setFrameRateS: fps=$fps, duration=${videoDurationMs}ms")

        if (videoDurationMs < SHORT_VIDEO_LENGTH_MS) {
            Log.d(TAG, "Short video, using seamless-only switching")
            surface.setFrameRate(
                fps,
                Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE,
                Surface.CHANGE_FRAME_RATE_ONLY_IF_SEAMLESS
            )
            return
        }

        var seamless = false
        activity.display?.mode?.alternativeRefreshRates?.let { refreshRates ->
            for (rate in refreshRates) {
                if (fps.toString().startsWith(rate.toString()) ||
                    rate.toString().startsWith(fps.toString()) ||
                    rate % fps == 0f) {
                    seamless = true
                    break
                }
            }
        }

        if (seamless) {
            Log.d(TAG, "Seamless switch available, using CHANGE_FRAME_RATE_ALWAYS")
            surface.setFrameRate(
                fps,
                Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE,
                Surface.CHANGE_FRAME_RATE_ALWAYS
            )
            registerDisplayListener()
        } else {
            val userPreference = getDisplayManager().matchContentFrameRateUserPreference
            if (userPreference == DisplayManager.MATCH_CONTENT_FRAMERATE_ALWAYS) {
                Log.d(TAG, "User preference allows non-seamless switch")
                surface.setFrameRate(
                    fps,
                    Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE,
                    Surface.CHANGE_FRAME_RATE_ALWAYS
                )
                registerDisplayListener()
            } else {
                Log.d(TAG, "Non-seamless switch not allowed, using seamless-only")
                surface.setFrameRate(
                    fps,
                    Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE,
                    Surface.CHANGE_FRAME_RATE_ONLY_IF_SEAMLESS
                )
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun setFrameRateM(fps: Float) {
        Log.d(TAG, "setFrameRateM: fps=$fps")
        val wm = activity.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        @Suppress("DEPRECATION")
        val display = wm.defaultDisplay ?: return

        display.supportedModes?.let { supportedModes ->
            val currentMode = display.mode
            var modeToUse = currentMode

            for (mode in supportedModes) {
                if (mode.physicalHeight != currentMode.physicalHeight ||
                    mode.physicalWidth != currentMode.physicalWidth) {
                    continue
                }

                if (BigDecimal(fps.toString()).setScale(1, RoundingMode.FLOOR) ==
                    BigDecimal(mode.refreshRate.toString()).setScale(1, RoundingMode.FLOOR)) {
                    modeToUse = mode
                    break
                } else if (mode.refreshRate % fps == 0f) {
                    modeToUse = mode
                    break
                }
            }

            if (modeToUse != currentMode) {
                Log.d(TAG, "Switching to mode ${modeToUse.modeId} (${modeToUse.refreshRate}Hz)")
                activity.window?.attributes?.let { attrs ->
                    attrs.preferredDisplayModeId = modeToUse.modeId
                    activity.window?.attributes = attrs
                }
                registerDisplayListener()
            }
        }
    }

    // Cleanup

    fun dispose() {
        Log.d(TAG, "Disposing")

        stopPositionUpdates()
        clearVideoFrameRate()
        abandonAudioFocus()
        audioManager = null

        exoPlayer?.removeListener(this)
        exoPlayer?.release()
        exoPlayer = null
        trackSelector = null

        surfaceView?.holder?.removeCallback(surfaceCallback)
        overlayLayoutListener?.let { listener ->
            val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
            contentView.viewTreeObserver.removeOnGlobalLayoutListener(listener)
        }

        val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
        surfaceContainer?.let { contentView.removeView(it) }
        subtitleView?.let { contentView.removeView(it) }
        surfaceContainer = null
        surfaceView = null
        subtitleView = null

        isInitialized = false
        Log.d(TAG, "Disposed")
    }
}
