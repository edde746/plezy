package com.edde746.plezy.playback.mpv

import com.edde746.plezy.log.Log

/**
 * Ambient lighting on one mpv core ([com.edde746.plezy.playback.PlayerEngine.setAmbientLighting]), called on the core's
 * thread with its property writes ([set]) and commands ([command]), each false when mpv refuses it.
 *
 * On: `sub-video-rect-aspect` gets the picture's aspect first, so a libmpv without that option refuses before anything
 * on screen changes; then the shader goes at the end of `glsl-shaders` and only then `keepaspect=no`, so while mpv
 * still letterboxes the shader already reproduces the letterboxed frame and no frame shows the stretched picture
 * without it. Off: the reverse, `keepaspect=yes`, the shader out, `sub-video-rect-aspect=no`. It waits for the
 * picture's aspect ([onVideoParams]) and follows each file's, which only the subtitles need: the shader reads the
 * picture's size every frame. A rebuilt shader list ([afterShadersRebuilt]) gets the shader back at its end.
 */
class MpvAmbientLighting(
    private val set: (name: String, value: String) -> Boolean,
    private val command: (args: List<String>) -> Boolean,
) {
    /** The shader asked for; null for off. */
    private var wanted: String? = null
    /** The shader in mpv's list, while ambient lighting is on there. */
    private var applied: String? = null
    private var aspect: Double? = null
    /** mpv refused `sub-video-rect-aspect`: this libmpv can't place subtitles for it, so it stays off. */
    private var refused = false

    /** Ambient lighting with [shaderPath], or off for null. */
    fun set(shaderPath: String?) {
        if (shaderPath == wanted) return
        wanted = shaderPath
        if (applied != null) disable()
        enable()
    }

    /** The picture's aspect changed ([MpvState.displayAspect]; null while there's no picture). */
    fun onVideoParams(displayAspect: Double?) {
        if (displayAspect == null || displayAspect == aspect) return
        aspect = displayAspect
        if (applied != null) {
            set(SUB_RECT_ASPECT, displayAspect.toString())
        } else {
            enable()
        }
    }

    /** `glsl-shaders` was cleared and refilled with the user's shaders: ambient lighting's goes back at the end. */
    fun afterShadersRebuilt() {
        applied?.let { command(listOf("change-list", "glsl-shaders", "append", it)) }
    }

    private fun enable() {
        val shader = wanted ?: return
        val aspect = aspect ?: return
        if (refused) return
        if (!set(SUB_RECT_ASPECT, aspect.toString())) {
            refused = true
            Log.w(TAG) { "mpv refused $SUB_RECT_ASPECT: ambient lighting stays off" }
            return
        }
        command(listOf("change-list", "glsl-shaders", "append", shader))
        set("keepaspect", "no")
        applied = shader
    }

    private fun disable() {
        val shader = applied ?: return
        set("keepaspect", "yes")
        command(listOf("change-list", "glsl-shaders", "remove", shader))
        set(SUB_RECT_ASPECT, "no")
        applied = null
    }

    private companion object {
        const val TAG = "AmbientLighting"
        const val SUB_RECT_ASPECT = "sub-video-rect-aspect"
    }
}
