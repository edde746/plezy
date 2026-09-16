package com.edde746.plezy.shared

import android.util.Log

/**
 * Runtime gate for the players' native debug logging.
 *
 * `android.util.Log.d` is not stripped from a release APK, and Kotlin builds the interpolated
 * message at the call site before the call runs, so an ungated trace on a surface, audio-focus, or
 * property callback costs real work on every user's device and fills their logcat. Debug traces go
 * through [d], whose inline message lambda is never evaluated while the gate is shut.
 *
 * The gate follows the app's "Debug Logging" setting: Dart pushes the mpv log level down at
 * `initialize` and over `setLogLevel`, and a verbose level opens this too. It is process-wide
 * because the shared player helpers are reached from both player backends.
 */
object PlayerDebugLog {
  @Volatile var enabled: Boolean = false

  /** Whether an mpv log level as delivered by Dart means the user asked for verbose diagnostics. */
  fun isVerbose(level: String?): Boolean = level == "v" || level == "debug" || level == "trace"

  /** Applies a Dart-supplied mpv log level to the gate. */
  fun applyLogLevel(level: String?) {
    enabled = isVerbose(level)
  }

  inline fun d(tag: String, message: () -> String) {
    if (enabled) Log.d(tag, message())
  }

  inline fun d(tag: String, throwable: Throwable?, message: () -> String) {
    if (enabled) Log.d(tag, message(), throwable)
  }
}
