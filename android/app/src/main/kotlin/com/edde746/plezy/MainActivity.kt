package com.edde746.plezy

import android.app.ActivityManager
import android.app.AppOpsManager
import android.app.PictureInPictureParams
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.graphics.SurfaceTexture
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.Rational
import android.view.InputDevice
import android.view.KeyEvent
import android.view.TextureView
import android.view.ViewGroup
import android.view.WindowInsets
import android.view.inputmethod.InputMethodManager
import android.widget.FrameLayout
import androidx.core.content.FileProvider
import com.edde746.plezy.exoplayer.ExoPlayerPlugin
import com.edde746.plezy.mpv.MpvPlayerPlugin
import com.edde746.plezy.shared.DeviceQuirks
import com.edde746.plezy.shared.ThemeHelper
import com.edde746.plezy.watchnext.WatchNextPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterTextureView
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.android.TransparencyMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterShellArgs
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

  companion object {
    private const val TAG = "MainActivity"
    var usingSkia = false
  }

  private val PIP_CHANNEL = "com.plezy/pip"
  private val EXTERNAL_PLAYER_CHANNEL = "com.plezy/external_player"
  private val THEME_CHANNEL = "com.plezy/theme"
  private val DEVICE_CHANNEL = "com.plezy/device"
  private val TEXT_INPUT_CHANNEL = "com.plezy/text_input"
  private val APP_EXIT_CHANNEL = "com.plezy/app_exit"
  private val APP_FOREGROUND_CHANNEL = "com.plezy/app_foreground"
  private var watchNextPlugin: WatchNextPlugin? = null
  private var nativeTextInputFocused = false

  // Auto PiP state
  private var autoPipReady = false
  private var autoPipWidth: Int = 16
  private var autoPipHeight: Int = 9

  private fun isAndroidTvDevice(): Boolean = getAndroidTvDetection()["isTv"] as Boolean

  private fun isImeVisible(): Boolean {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return false
    return window.decorView.rootWindowInsets?.isVisible(WindowInsets.Type.ime()) == true
  }

  private fun keyActionName(action: Int): String = when (action) {
    KeyEvent.ACTION_DOWN -> "down"
    KeyEvent.ACTION_UP -> "up"
    KeyEvent.ACTION_MULTIPLE -> "multiple"
    else -> "unknown($action)"
  }

  private fun sourceNames(source: Int): String {
    val names = mutableListOf<String>()
    if ((source and InputDevice.SOURCE_KEYBOARD) == InputDevice.SOURCE_KEYBOARD) names.add("keyboard")
    if ((source and InputDevice.SOURCE_DPAD) == InputDevice.SOURCE_DPAD) names.add("dpad")
    if ((source and InputDevice.SOURCE_GAMEPAD) == InputDevice.SOURCE_GAMEPAD) names.add("gamepad")
    if ((source and InputDevice.SOURCE_JOYSTICK) == InputDevice.SOURCE_JOYSTICK) names.add("joystick")
    if ((source and InputDevice.SOURCE_TOUCHSCREEN) == InputDevice.SOURCE_TOUCHSCREEN) names.add("touchscreen")
    if ((source and InputDevice.SOURCE_MOUSE) == InputDevice.SOURCE_MOUSE) names.add("mouse")
    return names.ifEmpty { listOf("unknown") }.joinToString("+")
  }

  private fun isDpadKeyCode(keyCode: Int): Boolean = when (keyCode) {
    KeyEvent.KEYCODE_DPAD_UP,
    KeyEvent.KEYCODE_DPAD_DOWN,
    KeyEvent.KEYCODE_DPAD_LEFT,
    KeyEvent.KEYCODE_DPAD_RIGHT,
    KeyEvent.KEYCODE_DPAD_CENTER,
    KeyEvent.KEYCODE_BACK,
    KeyEvent.KEYCODE_ENTER,
    KeyEvent.KEYCODE_NUMPAD_ENTER -> true
    else -> false
  }

  private fun describeDevice(event: KeyEvent): String {
    val device = event.device ?: return "device=null deviceId=${event.deviceId}"
    return "deviceId=${event.deviceId} name=${device.name} vendor=${device.vendorId} product=${device.productId} " +
      "keyboardType=${device.keyboardType} sources=0x${Integer.toHexString(device.sources)}[${sourceNames(device.sources)}]"
  }

  private fun describeKeyEvent(event: KeyEvent): String = "action=${keyActionName(event.action)} key=${KeyEvent.keyCodeToString(event.keyCode)}(${event.keyCode}) " +
    "scan=${event.scanCode} repeat=${event.repeatCount} source=0x${Integer.toHexString(event.source)}[${sourceNames(event.source)}] " +
    "flags=0x${Integer.toHexString(event.flags)} meta=0x${Integer.toHexString(event.metaState)} ${describeDevice(event)}"

  private fun describeImeState(): String {
    val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
    val focus = currentFocus
    return "nativeTextInputFocused=$nativeTextInputFocused imeVisible=${isImeVisible()} " +
      "acceptingText=${imm.isAcceptingText} activeDecor=${imm.isActive(window.decorView)} " +
      "decorHasFocus=${window.decorView.hasFocus()} currentFocus=${focus?.javaClass?.name} " +
      "currentFocusHasFocus=${focus?.hasFocus()} currentFocusFocused=${focus?.isFocused}"
  }

  private fun shouldForwardDpadBeforeIme(): Boolean {
    val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
    val forward = !nativeTextInputFocused && !isImeVisible() && !imm.isAcceptingText
    Log.i(TAG, "TextInputDiag shouldForwardDpadBeforeIme=$forward ${describeImeState()}")
    return forward
  }

  private fun getAndroidTvDetection(): Map<String, Any> {
    val pm = packageManager
    val uiModeType = resources.configuration.uiMode and Configuration.UI_MODE_TYPE_MASK
    val isTelevisionUiMode = uiModeType == Configuration.UI_MODE_TYPE_TELEVISION

    @Suppress("DEPRECATION")
    val hasTelevisionFeature = pm.hasSystemFeature(PackageManager.FEATURE_TELEVISION)
    val hasLeanback = pm.hasSystemFeature(PackageManager.FEATURE_LEANBACK)
    val hasFireTvFeature = pm.hasSystemFeature("amazon.hardware.fire_tv")
    val hasTouchscreen = pm.hasSystemFeature(PackageManager.FEATURE_TOUCHSCREEN)
    val hasFakeTouch = pm.hasSystemFeature(PackageManager.FEATURE_FAKETOUCH)

    val reasons = mutableListOf<String>()
    if (isTelevisionUiMode) reasons.add("ui_mode_television")
    if (hasTelevisionFeature) reasons.add("television_feature")
    if (hasLeanback) reasons.add("leanback")
    if (hasFireTvFeature) reasons.add("fire_tv")
    if (!hasTouchscreen) reasons.add("no_touchscreen")

    return mapOf(
      "isTv" to reasons.isNotEmpty(),
      "reasons" to reasons,
      "isTelevisionUiMode" to isTelevisionUiMode,
      "hasTelevisionFeature" to hasTelevisionFeature,
      "hasLeanback" to hasLeanback,
      "hasFireTvFeature" to hasFireTvFeature,
      "hasTouchscreen" to hasTouchscreen,
      "hasFakeTouch" to hasFakeTouch,
      "manufacturer" to Build.MANUFACTURER,
      "model" to Build.MODEL
    )
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
        if (isDpadKeyCode(event.keyCode)) {
          Log.i(TAG, "TextInputDiag preIme received ${describeKeyEvent(event)} ${describeImeState()}")
        }
        when (event.keyCode) {
          KeyEvent.KEYCODE_DPAD_UP,
          KeyEvent.KEYCODE_DPAD_DOWN,
          KeyEvent.KEYCODE_DPAD_LEFT,
          KeyEvent.KEYCODE_DPAD_RIGHT,
          KeyEvent.KEYCODE_DPAD_CENTER -> {
            if (shouldForwardDpadBeforeIme()) {
              Log.i(TAG, "TextInputDiag preIme forwarding-to-Flutter-and-consuming ${describeKeyEvent(event)}")
              super.dispatchKeyEvent(event)
              return true
            }
            Log.i(TAG, "TextInputDiag preIme letting-IME-handle ${describeKeyEvent(event)}")
          }
        }
        val handled = super.dispatchKeyEventPreIme(event)
        if (isDpadKeyCode(event.keyCode)) {
          Log.i(TAG, "TextInputDiag preIme superResult=$handled ${describeKeyEvent(event)} ${describeImeState()}")
        }
        return handled
      }
    }
    while (content.childCount > 0) {
      val child = content.getChildAt(0)
      content.removeViewAt(0)
      wrapper.addView(child)
    }
    content.addView(
      wrapper,
      ViewGroup.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        ViewGroup.LayoutParams.MATCH_PARENT
      )
    )

    // Handle Watch Next deep link from initial launch
    handleWatchNextIntent(intent)
  }

  override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    // Handle Watch Next deep link when app is already running
    handleWatchNextIntent(intent)
  }

  override fun dispatchKeyEvent(event: KeyEvent): Boolean {
    if (isDpadKeyCode(event.keyCode)) {
      Log.i(TAG, "TextInputDiag activity.dispatchKeyEvent before ${describeKeyEvent(event)} ${describeImeState()}")
    }
    val handled = super.dispatchKeyEvent(event)
    if (isDpadKeyCode(event.keyCode)) {
      Log.i(TAG, "TextInputDiag activity.dispatchKeyEvent after handled=$handled ${describeKeyEvent(event)} ${describeImeState()}")
    }
    return handled
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
    if (isAndroidTvDevice()) return true
    if (DeviceQuirks.isEWaste) return true
    // NVIDIA Tegra (Shield TV)
    if (Build.MANUFACTURER.equals("NVIDIA", ignoreCase = true)) return true
    // Huawei/HONOR Kirin SoCs use Mali GPUs
    if (Build.MANUFACTURER.equals("Huawei", ignoreCase = true) ||
      Build.MANUFACTURER.equals("HONOR", ignoreCase = true)
    ) {
      return true
    }
    return false
  }

  override fun getRenderMode(): RenderMode {
    // Keep Flutter in the normal View hierarchy so video/subtitle SurfaceViews
    // remain the only native composition layers. This restores the pre-1.35.0
    // behavior and avoids compositor regressions with Dolby Vision playback.
    return RenderMode.texture
  }

  override fun getTransparencyMode(): TransparencyMode {
    // Keep Flutter transparent so video/subtitles are visible below.
    return TransparencyMode.transparent
  }

  override fun onFlutterTextureViewCreated(flutterTextureView: FlutterTextureView) {
    val original = flutterTextureView.surfaceTextureListener ?: return
    val handler = Handler(Looper.getMainLooper())
    var pendingResize: Runnable? = null
    var lastWidth = 0
    var lastHeight = 0

    flutterTextureView.surfaceTextureListener = object : TextureView.SurfaceTextureListener {
      override fun onSurfaceTextureAvailable(surface: SurfaceTexture, width: Int, height: Int) {
        original.onSurfaceTextureAvailable(surface, width, height)
      }

      override fun onSurfaceTextureSizeChanged(surface: SurfaceTexture, width: Int, height: Int) {
        if (width == lastWidth && height == lastHeight) return
        lastWidth = width
        lastHeight = height
        pendingResize?.let { handler.removeCallbacks(it) }
        pendingResize = Runnable {
          if (flutterTextureView.isAvailable) {
            original.onSurfaceTextureSizeChanged(surface, width, height)
          }
        }
        handler.postDelayed(pendingResize!!, 100)
      }

      override fun onSurfaceTextureUpdated(surface: SurfaceTexture) {
        original.onSurfaceTextureUpdated(surface)
      }

      override fun onSurfaceTextureDestroyed(surface: SurfaceTexture): Boolean {
        pendingResize?.let { handler.removeCallbacks(it) }
        pendingResize = null
        lastWidth = 0
        lastHeight = 0
        return original.onSurfaceTextureDestroyed(surface)
      }
    }
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    flutterEngine.plugins.add(MpvPlayerPlugin())
    flutterEngine.plugins.add(ExoPlayerPlugin())

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CHANNEL).setMethodCallHandler { call, result ->
      when (call.method) {
        "getTvDetection" -> result.success(getAndroidTvDetection())
        else -> result.notImplemented()
      }
    }

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TEXT_INPUT_CHANNEL).setMethodCallHandler { call, result ->
      when (call.method) {
        "setNativeTextInputFocused" -> {
          val oldValue = nativeTextInputFocused
          nativeTextInputFocused = call.arguments as? Boolean ?: false
          Log.i(
            TAG,
            "TextInputDiag methodChannel setNativeTextInputFocused old=$oldValue new=$nativeTextInputFocused ${describeImeState()}"
          )
          result.success(null)
        }
        else -> result.notImplemented()
      }
    }

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_EXIT_CHANNEL).setMethodCallHandler { call, result ->
      when (call.method) {
        "requestExit" -> {
          result.success(true)
          window.decorView.post {
            finishAndRemoveTask()
          }
        }
        else -> result.notImplemented()
      }
    }

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_FOREGROUND_CHANNEL).setMethodCallHandler { call, result ->
      when (call.method) {
        "requestForeground" -> result.success(requestForeground())
        else -> result.notImplemented()
      }
    }

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

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PIP_CHANNEL).setMethodCallHandler { call, result ->
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

  private fun requestForeground(): Boolean = try {
    val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
    activityManager.moveTaskToFront(taskId, 0)
    true
  } catch (e: Exception) {
    Log.w(TAG, "Failed to move task to foreground", e)
    try {
      val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
        addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
        addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
      }
      if (launchIntent != null) {
        startActivity(launchIntent)
        true
      } else {
        false
      }
    } catch (launchError: Exception) {
      Log.w(TAG, "Failed to start foreground activity", launchError)
      false
    }
  }

  override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
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
      autoPipReady &&
      isPipPermissionGranted()
    ) {
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
