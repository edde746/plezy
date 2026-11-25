package com.edde746.plezy

import com.edde746.plezy.log.Log
import io.sentry.Sentry
import io.sentry.android.core.SentryAndroidOptions

/**
 * sentry-native lists the process's loaded native libraries (its debug images) the first time an event asks for them
 * and keeps that list. A native crash in a library loaded later, as libmpv and its FFmpeg libraries are by the first
 * player, then names no debug image for those frames and no uploaded symbol file matches them. Dropping the list once
 * they are loaded ([com.edde746.plezy.mpv.MpvNativeLibraries]) makes the next event read the process's mappings again.
 */
internal object NativeModuleCache {
    private const val TAG = "crash"

    fun invalidate() {
        // Not SentryAndroidOptions while crash reporting hasn't started Sentry (or never will).
        val options = Sentry.getCurrentScopes().options as? SentryAndroidOptions ?: return
        try {
            options.debugImagesLoader.clearDebugImages()
        } catch (e: Throwable) {
            Log.w(TAG, e) { "could not clear the native module cache" }
        }
    }
}
