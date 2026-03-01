package com.edde746.plezy

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.app.AppOpsManager
import android.app.PictureInPictureParams
import android.content.Context
import android.content.res.Configuration
import android.util.Rational
import android.view.KeyEvent
import android.view.ViewGroup
import android.view.inputmethod.InputMethodManager
import android.widget.FrameLayout
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.android.TransparencyMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.edde746.plezy.exoplayer.ExoPlayerPlugin
import com.edde746.plezy.mpv.MpvPlayerPlugin
import com.edde746.plezy.watchnext.WatchNextPlugin
import java.io.File

class MainActivity : FlutterActivity() {

    private val PIP_CHANNEL = "app.plezy/pip"
    private val EXTERNAL_PLAYER_CHANNEL = "app.plezy/external_player"
    private val THEME_CHANNEL = "app.plezy/theme"
    private var watchNextPlugin: WatchNextPlugin? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // Apply persisted theme color to the window background before anything
        // else renders.  This prevents a white flash between the native splash
        // screen and Flutter's first frame for non-default themes (e.g. OLED).
        val prefs = getSharedPreferences("plezy_prefs", Context.MODE_PRIVATE)
        val savedTheme = prefs.getString("splash_theme", null)
        if (savedTheme != null) {
            val color = when (savedTheme) {
                "oled" -> android.graphics.Color.BLACK
                "dark" -> android.graphics.Color.parseColor("#0E0F12")
                "light" -> android.graphics.Color.parseColor("#F7F7F8")
                else -> null
            }
            if (color != null) {
                window.decorView.setBackgroundColor(color)
            }
        }

        super.onCreate(savedInstanceState)

        // Disable the Android splash screen fade-out animation to avoid
        // a flicker before Flutter draws its first frame.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { splashScreenView -> splashScreenView.remove() }
        }

        // Disable Android's default focus highlight ring that appears when using
        // D-pad navigation so the Flutter UI can render its own focus state.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            window.decorView.defaultFocusHighlightEnabled = false
        }

        // Wrap the content view in a layout that intercepts DPAD key events
        // before the IME input stage, which can consume DPAD direction events
        // from virtual remotes before they reach Flutter's key handler.
        val content = findViewById<ViewGroup>(android.R.id.content)
        val wrapper = object : FrameLayout(this) {
            override fun dispatchKeyEventPreIme(event: KeyEvent): Boolean {
                when (event.keyCode) {
                    KeyEvent.KEYCODE_DPAD_UP,
                    KeyEvent.KEYCODE_DPAD_DOWN,
                    KeyEvent.KEYCODE_DPAD_LEFT,
                    KeyEvent.KEYCODE_DPAD_RIGHT,
                    KeyEvent.KEYCODE_DPAD_CENTER -> {
                        val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
                        if (!imm.isAcceptingText) {
                            super.dispatchKeyEvent(event)
                            return true
                        }
                    }
                }
                return super.dispatchKeyEventPreIme(event)
            }
        }
        while (content.childCount > 0) {
            val child = content.getChildAt(0)
            content.removeViewAt(0)
            wrapper.addView(child)
        }
        content.addView(wrapper, ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT))

        // Handle Watch Next deep link from initial launch
        handleWatchNextIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle Watch Next deep link when app is already running
        handleWatchNextIntent(intent)
    }

    private fun handleWatchNextIntent(intent: Intent?) {
        val contentId = WatchNextPlugin.handleIntent(intent)
        if (contentId != null) {
            // Notify the plugin to send event to Flutter
            watchNextPlugin?.notifyDeepLink(contentId)
        }
    }

    override fun getRenderMode(): RenderMode {
        // Use TextureView so Flutter doesn't occupy a SurfaceView layer.
        // This allows the libass subtitle SurfaceView to sit between video and Flutter UI.
        return RenderMode.texture
    }

    override fun getTransparencyMode(): TransparencyMode {
        // Keep Flutter transparent so video/subtitles are visible below.
        return TransparencyMode.transparent
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(MpvPlayerPlugin())
        flutterEngine.plugins.add(ExoPlayerPlugin())

        // External player: open local video files with proper content:// URIs
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EXTERNAL_PLAYER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openVideo" -> {
                    val filePath = call.argument<String>("filePath")
                    val packageName = call.argument<String>("package")

                    if (filePath == null) {
                        result.error("INVALID_ARGUMENT", "filePath is required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val uri: Uri
                        val grantRead: Boolean

                        if (filePath.startsWith("http://") || filePath.startsWith("https://")) {
                            uri = Uri.parse(filePath)
                            grantRead = false
                        } else if (filePath.startsWith("content://")) {
                            uri = Uri.parse(filePath)
                            grantRead = true
                        } else {
                            val path = if (filePath.startsWith("file://")) filePath.removePrefix("file://") else filePath
                            uri = FileProvider.getUriForFile(this, "com.edde746.plezy.fileprovider", File(path))
                            grantRead = true
                        }

                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "video/*")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            if (grantRead) {
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            if (packageName != null) {
                                setPackage(packageName)
                            }
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: android.content.ActivityNotFoundException) {
                        result.error("APP_NOT_FOUND", "No app found for package: $packageName", null)
                    } catch (e: Exception) {
                        result.error("LAUNCH_FAILED", e.message ?: e.javaClass.simpleName, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Splash screen theme: persist user's chosen theme for next launch (API 31+)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, THEME_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setSplashTheme" -> {
                    val mode = call.argument<String>("mode")

                    // Persist for next cold start & update window background now
                    getSharedPreferences("plezy_prefs", Context.MODE_PRIVATE)
                        .edit().putString("splash_theme", mode).apply()
                    val color = when (mode) {
                        "oled" -> android.graphics.Color.BLACK
                        "dark" -> android.graphics.Color.parseColor("#0E0F12")
                        "light" -> android.graphics.Color.parseColor("#F7F7F8")
                        else -> null
                    }
                    if (color != null) {
                        window.decorView.setBackgroundColor(color)
                    }

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val themeId = when (mode) {
                            "dark" -> R.style.SplashTheme_Dark
                            "oled" -> R.style.SplashTheme_Oled
                            "light" -> R.style.SplashTheme_Light
                            "system" -> android.content.res.Resources.ID_NULL
                            else -> android.content.res.Resources.ID_NULL
                        }
                        splashScreen.setSplashScreenTheme(themeId)
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Register Watch Next plugin and keep reference for deep link handling
        watchNextPlugin = WatchNextPlugin()
        flutterEngine.plugins.add(watchNextPlugin!!)

        MethodChannel( flutterEngine.dartExecutor.binaryMessenger, PIP_CHANNEL ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> {
                    result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                }
                "enter" -> {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                        result.success(mapOf("success" to false, "errorCode" to "android_version"))
                        return@setMethodCallHandler
                    }

                    // Check if PiP permission is granted via AppOpsManager
                    val appOpsManager = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
                    val pipAllowed = appOpsManager.checkOpNoThrow(
                        AppOpsManager.OPSTR_PICTURE_IN_PICTURE,
                        applicationInfo.uid,
                        packageName
                    ) == AppOpsManager.MODE_ALLOWED

                    if (!pipAllowed) {
                        result.success(mapOf("success" to false, "errorCode" to "permission_disabled"))
                        return@setMethodCallHandler
                    }

                    try {
                        val width = call.argument<Int>("width") ?: 16
                        val height = call.argument<Int>("height") ?: 9

                        // Android PiP requires aspect ratio between 0.418410 (5:12) and 2.39 (12:5)
                        val ratio = width.toFloat() / height.toFloat()
                        val clampedWidth: Int
                        val clampedHeight: Int

                        when {
                            ratio < 0.42f -> {
                                // Too tall - clamp to minimum ratio (5:12)
                                clampedWidth = 5
                                clampedHeight = 12
                            }
                            ratio > 2.39f -> {
                                // Too wide - clamp to maximum ratio (12:5)
                                clampedWidth = 12
                                clampedHeight = 5
                            }
                            else -> {
                                clampedWidth = width
                                clampedHeight = height
                            }
                        }

                        val params = PictureInPictureParams.Builder()
                            .setAspectRatio(Rational(clampedWidth, clampedHeight))
                            .build()
                        val success = enterPictureInPictureMode(params)
                        if (success) {
                            result.success(mapOf("success" to true))
                        } else {
                            result.success(mapOf("success" to false, "errorCode" to "failed"))
                        }
                    } catch (e: IllegalStateException) {
                        result.success(mapOf("success" to false, "errorCode" to "not_supported"))
                    } catch (e: Exception) {
                        result.success(mapOf("success" to false, "errorCode" to "unknown", "errorMessage" to (e.message ?: "Unknown error")))
                    }
                } else -> result.notImplemented()
            }
        }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean,newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        MethodChannel( flutterEngine!!.dartExecutor.binaryMessenger, PIP_CHANNEL ).invokeMethod( "onPipChanged" , isInPictureInPictureMode)

        // Notify ExoPlayer plugin to resize video surface for PiP
        flutterEngine?.plugins?.get(ExoPlayerPlugin::class.java)?.let { plugin ->
            (plugin as? ExoPlayerPlugin)?.onPipModeChanged(isInPictureInPictureMode)
        }
    }
}
