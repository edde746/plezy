package com.edde746.plezy.mpv.video

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.edde746.plezy.mpv.WaylandSession
import com.edde746.plezy.mpv.core.MpvCore
import com.edde746.plezy.playback.HardwareDecoder
import java.awt.Component
import java.awt.Container
import java.awt.Window

/**
 * Where mpv's video goes on this OS. The engine drives it from its mpv thread; the UI side comes from
 * [Content] and [attach].
 *
 * Order: [attach] (UI, once the window shows) → `onReady` → [options] → mpv_initialize → [bind] → `onVideoReady` →
 * loadfile … [unbind] → [awaitUnbound] → mpv_terminate_destroy, which never runs while the host still uses the core.
 */
internal interface VideoHost {
    /**
     * Hooks the host into [window] (UI thread). Returns false while the window's canvas does not exist yet, so the
     * caller retries; after returning true it calls [onReady] (any thread) once [options] can be read. Idempotent.
     */
    fun attach(window: Window, onReady: () -> Unit): Boolean

    /** mpv options the host needs before mpv_initialize (`vo`, `wid`, …). */
    fun options(): Map<String, String>

    /** The hardware decoder mpv can use on this host's video output; the engine applies each file's `hwdec`. */
    val hardwareDecoder: HardwareDecoder

    /**
     * Called on the mpv thread after mpv_initialize. Calls [onVideoReady] (any thread) with null once a file may be
     * loaded, or with the reason video cannot work; and with the reason once more should video stop working later,
     * while bound. The engine fails the playback, and every later load, with it.
     */
    fun bind(core: MpvCore, onVideoReady: (error: String?) -> Unit)

    /** Called on the mpv thread once its event loop has stopped: the host lets go of [core] ([awaitUnbound]). */
    fun unbind(core: MpvCore)

    /**
     * Blocks, off the mpv thread, until the host no longer touches the core [unbind] let go of. True once
     * mpv_terminate_destroy may run; false when it never may (Linux: the video plane's thread stuck in a driver call
     * with mpv's render context still on the core, so both are left alive rather than freed under it).
     */
    fun awaitUnbound(): Boolean

    /** Frees UI-side resources; the host is unusable afterwards. */
    fun close()

    /** mpv reports the source's `video-params` (its JSON; null while there is no video), on the mpv thread. */
    fun videoParams(json: String?) = Unit

    /** A file started playing or a seek landed (mpv's playback-restart), on the mpv thread. */
    fun playbackRestarted() = Unit

    /**
     * Whether mpv may present HDR ([MpvPlayerEngine.setHdrOutput]), when the host owns that decision (the Wayland plane);
     * false leaves it to the engine.
     */
    fun setHdrOutput(enabled: Boolean): Boolean = false

    /**
     * Whether the output can carry HDR at all ([MpvPlayerEngine.setHdrOutput] refuses HDR otherwise, and the player
     * offers no HDR switch): mpv's own
     * output on Windows can; the Wayland plane where the compositor describes HDR and the plane took a 10-bit surface.
     */
    val carriesHdr: Boolean get() = true

    /** The Wayland plane's tone mapping: mpv's to the output's peak ([player]), or the compositor's. */
    fun setToneMapping(player: Boolean) = Unit

    /** The host's state for diagnostics and test reports. */
    fun stats(): Map<String, Any?> = emptyMap()

    /** The Compose element standing for the video: transparent where the video shows through it. */
    @Composable
    fun Content(modifier: Modifier)

    companion object {
        fun forCurrentOs(): VideoHost {
            val os = System.getProperty("os.name")
            return when {
                os.startsWith("Windows") -> Win32VideoHost()
                os.startsWith("Linux") -> if (WaylandSession.active) WaylandVideoHost() else UnsupportedVideoHost(UnsupportedVideoHost.X11_SESSION)
                else -> error("No desktop video host for $os (macOS uses the native Swift player)")
            }
        }
    }
}

private fun Class<*>.isNamed(name: String) = generateSequence(this) { it.superclass }.any { it.name == name }

/** First component in [root]'s tree whose class (or a superclass) is [className]. */
internal fun findComponent(root: Component, className: String): Component? {
    if (root.javaClass.isNamed(className)) return root
    if (root is Container) for (child in root.components) findComponent(child, className)?.let { return it }
    return null
}
