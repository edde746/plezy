package com.edde746.plezy

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.app.AppOpsManager
import android.app.PictureInPictureParams
import android.content.Context
import android.content.res.Configuration
import android.util.Log
import android.util.Rational
import android.view.KeyEvent
import android.view.ViewGroup
import android.view.inputmethod.InputMethodManager
import android.widget.FrameLayout
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterShellArgs
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.android.TransparencyMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.edde746.plezy.exoplayer.ExoPlayerPlugin
import com.edde746.plezy.mpv.MpvPlayerPlugin
import com.edde746.plezy.shared.ThemeHelper
import com.edde746.plezy.watchnext.WatchNextPlugin
import java.io.File

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "MainActivity"
        var usingSkia = false
    }

    private val PIP_CHANNEL = "com.plezy/pip"
    private val EXTERNAL_PLAYER_CHANNEL = "com.plezy/external_player"
    private val THEME_CHANNEL = "com.plezy/theme"
    private var watchNextPlugin: WatchNextPlugin? = null

    // Auto PiP state
    private var autoPipReady = false
    private var autoPipWidth: Int = 16
    private var autoPipHeight: Int = 9

    private fun isAndroidTvDevice(): Boolean {
        return packageManager.hasSystemFeature("android.software.leanback")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // Apply persisted theme color to the window background before anything
        // else renders.  This prevents a white flash between the native splash
        // screen and Flutter's first frame for non-default themes (e.g. OLED).
        val prefs = getSharedPreferences("plezy_prefs", Context.MODE_PRIVATE)
        val savedTheme = prefs.getString("splash_theme", null)
        ThemeHelper.themeColor(savedTheme)?.let { window.decorView.setBackgroundColor(it) }

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

    override fun getFlutterShellArgs(): FlutterShellArgs {
        val args = super.getFlutterShellArgs()
        usingSkia = shouldDisableImpeller()
        if (usingSkia) args.add("--enable-impeller=false")
        return args
    }

    private fun shouldDisableImpeller(): Boolean {
        // Android TV devices — weaker GPUs, less Impeller testing
        if (packageManager.hasSystemFeature("android.software.leanback")) return true
        // Google Tensor SoC (Mali GPU) — Pixel 6+
        // SOC_MODEL may return marketing name ("Tensor G2") or internal ID ("GS201")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val soc = Build.SOC_MODEL
            if (soc.startsWith("Tensor", ignoreCase = true) ||
                soc.startsWith("GS", ignoreCase = true)) return true
        }
        // NVIDIA Tegra (Shield TV)
        if (Build.MANUFACTURER.equals("NVIDIA", ignoreCase = true)) return true
        // Huawei/HONOR Kirin SoCs use Mali GPUs
        if (Build.MANUFACTURER.equals("Huawei", ignoreCase = true) ||
            Build.MANUFACTURER.equals("HONOR", ignoreCase = true)) return true
        return false
    }

    override fun getRenderMode(): RenderMode = RenderMode.surface

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
                "getRenderer" -> result.success(if (usingSkia) "Skia" else "Impeller")
                "setSplashTheme" -> {
                    val mode = call.argument<String>("mode")

                    // Persist for next cold start & update window background now
                    getSharedPreferences("plezy_prefs", Context.MODE_PRIVATE)
                        .edit().putString("splash_theme", mode).apply()
                    ThemeHelper.themeColor(mode)?.let { window.decorView.setBackgroundColor(it) }

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
                    result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !isAndroidTvDevice())
                }
                "enter" -> {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                        result.success(mapOf("success" to false, "errorCode" to "android_version"))
                        return@setMethodCallHandler
                    }

                    if (isAndroidTvDevice()) {
                        result.success(mapOf("success" to false, "errorCode" to "not_supported"))
                        return@setMethodCallHandler
                    }

                    if (!isPipPermissionGranted()) {
                        result.success(mapOf("success" to false, "errorCode" to "permission_disabled"))
                        return@setMethodCallHandler
                    }

                    try {
                        val width = call.argument<Int>("width") ?: 16
                        val height = call.argument<Int>("height") ?: 9
                        val params = buildPipParams(width, height)
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
                }
                "setAutoPipReady" -> {
                    if (isAndroidTvDevice()) {
                        autoPipReady = false
                        result.success(true)
                        return@setMethodCallHandler
                    }

                    autoPipReady = call.argument<Boolean>("ready") ?: false
                    autoPipWidth = call.argument<Int>("width") ?: 16
                    autoPipHeight = call.argument<Int>("height") ?: 9

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        try {
                            val params = buildPipParams(autoPipWidth, autoPipHeight, autoEnterEnabled = autoPipReady)
                            setPictureInPictureParams(params)
                        } catch (e: Exception) {
                            Log.w(TAG, "Failed to set auto-PiP params", e)
                        }
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean,newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        flutterEngine?.let { engine ->
            MethodChannel(engine.dartExecutor.binaryMessenger, PIP_CHANNEL).invokeMethod("onPipChanged", isInPictureInPictureMode)
            engine.plugins.get(ExoPlayerPlugin::class.java)?.let { plugin ->
                (plugin as? ExoPlayerPlugin)?.onPipModeChanged(isInPictureInPictureMode)
            }
        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        // Auto PiP for API 26-30 (API 31+ uses setAutoEnterEnabled)
        if (!isAndroidTvDevice() &&
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            Build.VERSION.SDK_INT < Build.VERSION_CODES.S &&
            autoPipReady && isPipPermissionGranted()) {
            try {
                // Notify Flutter to prepare video filter before PiP
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, PIP_CHANNEL).invokeMethod("onAutoPipEntering", null)
                }
                val params = buildPipParams(autoPipWidth, autoPipHeight)
                enterPictureInPictureMode(params)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to enter auto-PiP", e)
            }
        }
    }

    private fun isPipPermissionGranted(): Boolean {
        val appOpsManager = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        return appOpsManager.checkOpNoThrow(
            AppOpsManager.OPSTR_PICTURE_IN_PICTURE,
            applicationInfo.uid,
            packageName
        ) == AppOpsManager.MODE_ALLOWED
    }

    private fun buildPipParams(width: Int, height: Int, autoEnterEnabled: Boolean? = null): PictureInPictureParams {
        val (w, h) = if (width <= 0 || height <= 0) {
            Pair(16, 9)
        } else {
            val ratio = width.toFloat() / height.toFloat()
            when {
                ratio < 1f / 2.39f -> Pair(100, 239)
                ratio > 2.39f -> Pair(239, 100)
                else -> Pair(width, height)
            }
        }
        val builder = PictureInPictureParams.Builder()
            .setAspectRatio(Rational(w, h))
        if (autoEnterEnabled != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setAutoEnterEnabled(autoEnterEnabled)
        }
        return builder.build()
    }
}
