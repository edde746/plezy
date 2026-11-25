package com.edde746.plezy.mpv

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Rect
import android.os.Build
import android.view.Gravity
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.widget.FrameLayout
import com.edde746.mpv.VideoRectPolicy
import com.edde746.plezy.playback.VideoFit
import com.edde746.plezy.playback.VideoLayout

/**
 * The video host for [MpvPlayerEngine]: a video SurfaceView and, above it, the
 * transparent `vo=mediacodec` subtitle/OSD SurfaceView (media-overlay z-order). Both are below-window surfaces, so
 * whatever the window draws — Compose, when this is hosted in an `AndroidView` — composites above them with no
 * z-order changes.
 *
 * On the video plane the video SurfaceView is sized to the picture as the engine's [VideoLayout] lays it out
 * ([VideoRectPolicy]: fitted, cropped to fill, zoomed) and centred, the overflow clipped by the window; the OSD plane
 * stays full size and learns the picture's (signed) bounds. Under a GL vo mpv lays the picture out itself, so the video
 * SurfaceView fills the view and the OSD plane is hidden.
 *
 * Main thread only. Bind the engine with [setEngine] before or after the Surfaces exist, and leave it bound through
 * [MpvPlayerEngine.release]: a `surfaceDestroyed` that arrives after the release then still waits for the engine's
 * teardown to move mpv off the Surface.
 *
 * The engine's [SurfaceHints] (HDR headroom) go on the video SurfaceView. The OSD plane's buffer is the engine's share
 * of the view's size ([MpvPlayerEngine.osdRenderScale], [OsdPlanePolicy]): mpv draws subtitles at the buffer's size
 * and the compositor scales the plane up.
 */
class MpvVideoView(context: Context) : FrameLayout(context) {
    private val videoView = SurfaceView(context)
    private val osdView = SurfaceView(context)
    private var engine: MpvPlayerEngine? = null

    private var videoSurfaceReady = false
    private var videoSurfaceWidth = 0
    private var videoSurfaceHeight = 0
    private var osdSurfaceReady = false

    private var videoWidth = 0
    private var videoHeight = 0
    private var gpuVo = false
    private var hints = SurfaceHints.NONE
    private var layout = VideoLayout.DEFAULT
    private var osdFixedSize: OsdPlanePolicy.Size? = null

    /**
     * Called when the picture's size (mpv's display size, `dwidth`×`dheight`) changes, and once it is laid out, so a
     * picture-in-picture window can follow its aspect ratio and bounds ([pictureBoundsInWindow]).
     */
    var onPictureChanged: ((width: Int, height: Int) -> Unit)? = null

    // What the bound engine tells its view ([MpvPlayerEngine.bindHost]), from any thread; applied on the main thread.

    /** mpv's display size of the picture (`dwidth`/`dheight`). */
    internal fun onVideoSize(width: Int, height: Int) {
        post {
            if (width == videoWidth && height == videoHeight) return@post
            videoWidth = width
            videoHeight = height
            requestLayout()
        }
    }

    /** Whether a GL vo (true) or the video plane (false) is presenting. */
    internal fun onGpuVo(active: Boolean) {
        post {
            if (active == gpuVo && osdView.visibility == (if (active) GONE else VISIBLE)) return@post
            gpuVo = active
            // Hiding the plane destroys its Surface; the engine retires it first (detachOsdSurface).
            osdView.visibility = if (active) GONE else VISIBLE
            requestLayout()
        }
    }

    /** What the video Surface asks of the display ([MpvPlayerEngine.setHdrOutput]). */
    internal fun onSurfaceHints(hints: SurfaceHints) {
        post {
            if (hints == this.hints) return@post
            this.hints = hints
            applyHints()
        }
    }

    /** How the picture is laid out on the plane ([MpvPlayerEngine.setVideoLayout]). */
    internal fun onVideoLayout(layout: VideoLayout) {
        post {
            if (layout == this.layout) return@post
            this.layout = layout
            requestLayout()
        }
    }

    init {
        setBackgroundColor(Color.BLACK)
        videoView.layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT, Gravity.CENTER)
        videoView.holder.addCallback(object : SurfaceHolder.Callback {
            override fun surfaceCreated(holder: SurfaceHolder) {
                videoSurfaceReady = true
                engine?.attachSurface(holder.surface)
            }

            override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
                videoSurfaceWidth = width
                videoSurfaceHeight = height
                engine?.setSurfaceSize(width, height)
            }

            override fun surfaceDestroyed(holder: SurfaceHolder) {
                videoSurfaceReady = false
                engine?.detachSurface()
            }
        })
        osdView.layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
        osdView.holder.setFormat(PixelFormat.TRANSLUCENT)
        osdView.setZOrderMediaOverlay(true)
        osdView.holder.addCallback(object : SurfaceHolder.Callback {
            override fun surfaceCreated(holder: SurfaceHolder) {
                osdSurfaceReady = true
                engine?.attachOsdSurface(holder.surface)
            }

            override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) = Unit

            override fun surfaceDestroyed(holder: SurfaceHolder) {
                osdSurfaceReady = false
                engine?.detachOsdSurface()
            }
        })
        addView(videoView)
        addView(osdView)
    }

    /** Binds [engine], handing it the Surfaces that already exist; the previous engine lets go of them first. */
    fun setEngine(engine: MpvPlayerEngine?) {
        val previous = this.engine
        if (previous === engine) return
        if (previous != null) {
            previous.bindHost(null)
            if (osdSurfaceReady) previous.detachOsdSurface()
            if (videoSurfaceReady) previous.detachSurface()
        }
        this.engine = engine
        if (engine == null) return
        engine.bindHost(this)
        applyOsdRenderScale()
        if (width > 0 && height > 0) engine.setViewportSize(width, height)
        if (videoSurfaceReady) {
            engine.attachSurface(videoView.holder.surface)
            engine.setSurfaceSize(videoSurfaceWidth, videoSurfaceHeight)
        }
        if (osdSurfaceReady) engine.attachOsdSurface(osdView.holder.surface)
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        engine?.setViewportSize(w, h)
        applyOsdRenderScale()
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        if (gpuVo) return
        val size = VideoRectPolicy.sizeFor(
            measuredWidth,
            measuredHeight,
            videoWidth,
            videoHeight,
            panscan = if (layout.fit == VideoFit.COVER) 1f else 0f,
            videoZoomLog2 = layout.videoZoom.toFloat(),
        ) ?: return
        videoView.measure(
            MeasureSpec.makeMeasureSpec(size.width, MeasureSpec.EXACTLY),
            MeasureSpec.makeMeasureSpec(size.height, MeasureSpec.EXACTLY),
        )
    }

    /**
     * Where the whole picture is in the window, fitted, whatever the player's crop or zoom (a picture-in-picture window
     * shows it whole): the video plane's bounds at that fit, or under a GL vo (which letterboxes inside the full view)
     * the fitted picture's; null before the picture's size is known.
     */
    fun pictureBoundsInWindow(): Rect? {
        val size = VideoRectPolicy.sizeFor(width, height, videoWidth, videoHeight) ?: return null
        val origin = IntArray(2).also(::getLocationInWindow)
        val left = origin[0] + (width - size.width) / 2
        val top = origin[1] + (height - size.height) / 2
        return Rect(left, top, left + size.width, top + size.height)
    }

    /** The OSD plane's buffer at the bound engine's render scale of the view's size, or the view's own. */
    private fun applyOsdRenderScale() {
        val size = OsdPlanePolicy.fixedSizeFor(width, height, engine?.osdRenderScale ?: 1.0)
        if (size == osdFixedSize) return
        osdFixedSize = size
        if (size != null) osdView.holder.setFixedSize(size.width, size.height) else osdView.holder.setSizeFromLayout()
    }

    private fun applyHints() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
            // 1 (no headroom above SDR white): the compositor tone-maps HDR video; 0: the system's choice.
            videoView.setDesiredHdrHeadroom(if (hints.sdr) 1f else 0f)
        }
    }

    override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
        super.onLayout(changed, left, top, right, bottom)
        if (videoWidth > 0 && videoHeight > 0) onPictureChanged?.invoke(videoWidth, videoHeight)
        if (gpuVo) return
        VideoRectPolicy.rectFor(
            osdView.width,
            osdView.height,
            videoView.left - osdView.left,
            videoView.top - osdView.top,
            videoView.right - osdView.left,
            videoView.bottom - osdView.top,
        )?.let { engine?.setVideoRect(it) }
    }
}
