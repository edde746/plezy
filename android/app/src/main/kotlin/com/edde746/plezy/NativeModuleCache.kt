package com.edde746.plezy

import android.util.Log
import io.sentry.Sentry
import io.sentry.android.core.SentryAndroidOptions

/**
 * sentry-native caches the process's loaded-library list the first time
 * anything asks for debug images; sentry_flutter does so for every Dart error
 * event. A native crash in a library loaded after that, such as libmpv and its
 * FFmpeg libraries opened by the first player, then carries no debug image for
 * those frames, so no uploaded symbol file can ever match them. Dropping the
 * cache once such libraries are loaded makes the next event re-read the
 * process's mappings.
 */
internal object NativeModuleCache {
  private const val TAG = "NativeModuleCache"

  fun invalidate() {
    // Not SentryAndroidOptions when crash reporting never initialized Sentry.
    val options = Sentry.getCurrentScopes().options as? SentryAndroidOptions ?: return
    try {
      options.debugImagesLoader.clearDebugImages()
    } catch (e: Throwable) {
      Log.w(TAG, "Could not clear Sentry's native module cache", e)
    }
  }
}
