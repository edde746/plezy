package com.edde746.plezy.mpv

/**
 * Tells the app that libmpv and its FFmpeg libraries are in the process: called on the player's thread each time an mpv
 * instance has been created (the libraries load with the first). The app drops the crash reporter's cached list of
 * loaded native libraries here, so a native crash in them names their debug images.
 */
object MpvNativeLibraries {
    @Volatile
    var onLoaded: (() -> Unit)? = null

    internal fun loaded() {
        onLoaded?.invoke()
    }
}
