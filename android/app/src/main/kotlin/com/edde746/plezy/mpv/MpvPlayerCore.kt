package com.edde746.plezy.mpv

import android.app.Activity
import android.graphics.Color
import android.graphics.PixelFormat
import android.util.Log
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.view.TextureView
import dev.jdtech.mpv.MPVLib

interface MpvPlayerDelegate {
    fun onPropertyChange(name: String, value: Any?)
    fun onEvent(name: String, data: Map<String, Any>?)
}

class MpvPlayerCore(private val activity: Activity) :
    SurfaceHolder.Callback,
    MPVLib.EventObserver {

    companion object {
        private const val TAG = "MpvPlayerCore"
    }

    private var surfaceView: SurfaceView? = null
    private var overlayLayoutListener: ViewTreeObserver.OnGlobalLayoutListener? =
        null
    private var voInUse: String = "gpu"
    var delegate: MpvPlayerDelegate? = null
    var isInitialized: Boolean = false
        private set

    private fun ensureFlutterOverlayOnTop() {
        val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
        contentView.post {
            var flutterContainer: ViewGroup? = null

            // First pass: look for FlutterView by name (debug builds)
            for (i in 0 until contentView.childCount) {
                val child = contentView.getChildAt(i)
                if (child is ViewGroup && child.javaClass.name.contains("FlutterView")) {
                    flutterContainer = child
                    break
                }
            }

            // Fallback for release (FlutterView may be obfuscated): pick the last ViewGroup
            // that is not our mpv SurfaceView and has children.
            if (flutterContainer == null) {
                for (i in contentView.childCount - 1 downTo 0) {
                    val child = contentView.getChildAt(i)
                    if (child is ViewGroup && child != surfaceView?.parent && child.childCount > 0) {
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
                        flutterChild.setZOrderOnTop(true)
                        flutterChild.setZOrderMediaOverlay(true)
                        flutterChild.holder.setFormat(PixelFormat.TRANSLUCENT)
                        break
                    } else if (flutterChild is TextureView) {
                        // TextureView uses alpha composition; ensure it stays above.
                        flutterChild.isOpaque = false
                        break
                    }
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
            // Create SurfaceView for video rendering
            surfaceView = SurfaceView(activity).apply {
                layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
                setBackgroundColor(Color.BLACK)
                // Keep video composited in the normal view hierarchy (avoid hardware overlay promotion)
                // so Flutter controls reliably draw above it in release builds.
                alpha = 0.999f
                holder.addCallback(this@MpvPlayerCore)

                // Critical: Ensure SurfaceView renders BEHIND Flutter's view
                setZOrderOnTop(false)
                setZOrderMediaOverlay(false)
            }

            // Insert SurfaceView at bottom of view hierarchy (behind Flutter)
            val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
            contentView.addView(surfaceView, 0)

            // Find FlutterView and its internal FlutterSurfaceView, set it on top
            for (i in 0 until contentView.childCount) {
                val child = contentView.getChildAt(i)
                if (child is ViewGroup && child.javaClass.name.contains("FlutterView")) {
                    contentView.bringChildToFront(child)
                    // Look inside FlutterView for FlutterSurfaceView
                    for (j in 0 until child.childCount) {
                        val flutterChild = child.getChildAt(j)
                        if (flutterChild is SurfaceView) {
                            // Put Flutter in media overlay layer (above our video which is in normal layer)
                            flutterChild.setZOrderOnTop(true)
                            flutterChild.setZOrderMediaOverlay(true)
                            flutterChild.holder.setFormat(PixelFormat.TRANSLUCENT)
                            break
                        }
                    }
                    break
                }
            }
            // Repeat after layout settles to catch late-added Flutter surfaces (release builds)
            ensureFlutterOverlayOnTop()
            overlayLayoutListener = ViewTreeObserver.OnGlobalLayoutListener {
                ensureFlutterOverlayOnTop()
            }
            contentView.viewTreeObserver.addOnGlobalLayoutListener(overlayLayoutListener)

            Log.d(TAG, "SurfaceView added to content view")

            // Initialize MPVLib
            MPVLib.create(activity.applicationContext)

            // Configure MPV defaults
            setupMpvDefaults()

            // Initialize MPV
            MPVLib.init()

            // Register event observer
            MPVLib.addObserver(this)

            isInitialized = true
            Log.d(TAG, "Initialized successfully")
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize: ${e.message}", e)
            return false
        }
    }

    private fun setupMpvDefaults() {
        // Video output configuration
        MPVLib.setOptionString("vo", "gpu")
        MPVLib.setOptionString("gpu-context", "android")
        // hwdec is set from Flutter via setProperty based on user preference

        // Audio configuration
        MPVLib.setOptionString("ao", "audiotrack")
    }

    // SurfaceHolder.Callback

    override fun surfaceCreated(holder: SurfaceHolder) {
        Log.d(TAG, "Surface created")
        MPVLib.attachSurface(holder.surface)
        MPVLib.setOptionString("force-window", "yes")
        // Restore video output after surface is available
        MPVLib.setPropertyString("vo", voInUse)
        // Reassert overlay order whenever the surface is recreated
        ensureFlutterOverlayOnTop()
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
        Log.d(TAG, "Surface changed: ${width}x${height}")
        MPVLib.setPropertyString("android-surface-size", "${width}x${height}")
    }

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        Log.d(TAG, "Surface destroyed")
        // Disable video output before detaching (like mpv-android)
        MPVLib.setPropertyString("vo", "null")
        MPVLib.setOptionString("force-window", "no")
        MPVLib.detachSurface()
    }

    // MPVLib.EventObserver

    override fun eventProperty(property: String) {
        // No value provided
    }

    override fun eventProperty(property: String, value: Long) {
        activity.runOnUiThread {
            delegate?.onPropertyChange(property, value)
        }
    }

    override fun eventProperty(property: String, value: Double) {
        activity.runOnUiThread {
            delegate?.onPropertyChange(property, value)
        }
    }

    override fun eventProperty(property: String, value: Boolean) {
        activity.runOnUiThread {
            delegate?.onPropertyChange(property, value)
        }
    }

    override fun eventProperty(property: String, value: String) {
        activity.runOnUiThread {
            delegate?.onPropertyChange(property, value)
        }
    }

    override fun event(eventId: Int) {
        val eventName = when (eventId) {
            MPVLib.MPV_EVENT_FILE_LOADED -> "file-loaded"
            MPVLib.MPV_EVENT_END_FILE -> "end-file"
            MPVLib.MPV_EVENT_PLAYBACK_RESTART -> "playback-restart"
            else -> null
        }
        eventName?.let { name ->
            activity.runOnUiThread {
                delegate?.onEvent(name, null)
            }
        }
    }

    // Public API

    fun setProperty(name: String, value: String) {
        if (!isInitialized) return
        MPVLib.setPropertyString(name, value)
    }

    fun getProperty(name: String): String? {
        if (!isInitialized) return null
        return try {
            MPVLib.getPropertyString(name)
        } catch (e: Exception) {
            null
        }
    }

    fun observeProperty(name: String, format: String) {
        if (!isInitialized) return

        val mpvFormat = when (format) {
            "double" -> MPVLib.MPV_FORMAT_DOUBLE
            "flag" -> MPVLib.MPV_FORMAT_FLAG
            "string" -> MPVLib.MPV_FORMAT_STRING
            "node" -> MPVLib.MPV_FORMAT_NODE
            else -> MPVLib.MPV_FORMAT_NONE
        }
        MPVLib.observeProperty(name, mpvFormat)
    }

    fun command(args: Array<String>) {
        if (!isInitialized || args.isEmpty()) return
        MPVLib.command(args)
    }

    fun setVisible(visible: Boolean) {
        activity.runOnUiThread {
            surfaceView?.visibility = if (visible) View.VISIBLE else View.INVISIBLE
            Log.d(TAG, "setVisible($visible)")
        }
    }

    // Cleanup

    fun dispose() {
        Log.d(TAG, "Disposing")

        MPVLib.removeObserver(this)

        surfaceView?.holder?.removeCallback(this)
        overlayLayoutListener?.let { listener ->
            val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
            contentView.viewTreeObserver.removeOnGlobalLayoutListener(listener)
        }

        val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
        surfaceView?.let { contentView.removeView(it) }
        surfaceView = null

        MPVLib.destroy()
        isInitialized = false

        Log.d(TAG, "Disposed")
    }
}
