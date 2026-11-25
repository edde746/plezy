package com.edde746.plezy.playback

import com.edde746.plezy.log.Log
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

/**
 * Ambient lighting: the bars beside a picture that doesn't fill the screen show a blurred, dimmed glow of the picture
 * instead of black. mpv draws it: its shader ([AmbientLightingShader]) runs last, after the user shaders, while mpv
 * scales the picture to the whole output (`keepaspect=no`) for the shader to place it back at its own aspect
 * ([PlayerEngine.setAmbientLighting]). Only mpv runs it (its GPU outputs, and libplacebo on Apple's display layer).
 *
 * The player store holds one per player where the device runs shaders and calls it as the viewer acts:
 * - [toggle] from the options' switch; it turns the shader off and the picture back to Fit while it turns on;
 * - [onFirstFrame] at each file's first frame: the stored setting ([saved], which the store keeps up to date) comes
 *   back at the first one only, so a change of fit or zoom that turned it off in this player stays;
 * - [suspend] when the fit or the zoom changes (the picture no longer letterboxed as the shader draws it): off, the
 *   stored setting as it is;
 * - [offForShader] when a shader preset other than Off starts: off, and stored off;
 * - [enterPictureInPicture] and [exitPictureInPicture] around picture in picture, which shows no bars.
 * [persist] stores the viewer's choice (`ambient_lighting`). [scope] writes the shader's file. Call it on the main
 * thread.
 */
class AmbientLightingController(
    private val engine: PlayerEngine,
    private val shaderFiles: ShaderFiles,
    private val persist: (Boolean) -> Unit,
    private val scope: CoroutineScope,
) {
    /** The stored setting (`ambient_lighting`), as the store last heard it. */
    var saved: Boolean = false

    /** It is on in this player. */
    var enabled: Boolean = false
        private set

    private var restoreArmed = true
    private var beforePictureInPicture = false
    private var job: Job? = null

    /** Turns it off, or on; stores the choice. True when it turned on: the shader goes off and the fit back to Fit. */
    fun toggle(): Boolean {
        set(!enabled)
        persist(enabled)
        return enabled
    }

    /** The first frame of a file: the stored setting at the first one. True when it turned on, as [toggle]. */
    fun onFirstFrame(): Boolean {
        if (!restoreArmed) return false
        restoreArmed = false
        if (!saved || enabled) return false
        set(true)
        return true
    }

    /** The fit or the zoom changed: off for this player, the stored setting kept. */
    fun suspend() = set(false)

    /** A shader preset other than Off started: off, and stored off. */
    fun offForShader() {
        if (!enabled) return
        set(false)
        persist(false)
    }

    fun enterPictureInPicture() {
        beforePictureInPicture = enabled
        set(false)
    }

    /** Back from picture in picture: on again if it was on before. True when it turned on, as [toggle]. */
    fun exitPictureInPicture(): Boolean {
        if (!beforePictureInPicture) return false
        beforePictureInPicture = false
        set(true)
        return true
    }

    private fun set(on: Boolean) {
        if (on == enabled) return
        enabled = on
        job?.cancel()
        if (!on) {
            engine.setAmbientLighting(null)
            return
        }
        job = scope.launch {
            val shader = try {
                shaderFiles.ambientLighting()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Couldn't write the ambient lighting shader" }
                enabled = false
                return@launch
            }
            engine.setAmbientLighting(shader)
        }
    }

    private companion object {
        const val TAG = "AmbientLighting"
    }
}

/**
 * Ambient lighting's mpv user shader, all passes on MAIN: keep the picture (ORIGINAL); shrink its centre 60% to an
 * eighth; blur it three times (Kawase, offsets 2, 6 and 12 texels); shrink that to an eighth again; blur twice more (3
 * and 6); then draw the picture at its own aspect inside the output (mpv's `input_size` and `target_size`, so a resize
 * or another file needs no new shader) and the glow at half brightness around it.
 */
object AmbientLightingShader {
    /** How bright the glow is against the picture. */
    private const val BRIGHTNESS = "0.50"

    val source: String = buildString {
        pass("ORIGINAL", "Save", bind = "HOOKED", body = "    return HOOKED_tex(HOOKED_pos);")
        pass(
            "SMALL", "Downscale", bind = "ORIGINAL", size = "ORIGINAL" to "8 /",
            body = "    vec2 uv = ORIGINAL_pos * 0.6 + 0.2;\n    return ORIGINAL_tex(uv);",
        )
        kawase("SMALL", "BLUR8A", "2.0", "Blur1")
        kawase("BLUR8A", "BLUR8B", "6.0", "Blur2")
        kawase("BLUR8B", "BLUR8C", "12.0", "Blur3")
        pass("TINY", "Downscale2", bind = "BLUR8C", size = "BLUR8C" to "8 /", body = "    return BLUR8C_tex(BLUR8C_pos);")
        kawase("TINY", "GLOW1", "3.0", "Blur4")
        kawase("GLOW1", "GLOW", "6.0", "Blur5")
        append(
            """
            //!HOOK MAIN
            //!BIND ORIGINAL
            //!BIND GLOW
            //!DESC Ambient Lighting Composite
            vec4 hook() {
                float vid_aspect = input_size.x / input_size.y;
                float out_aspect = target_size.x / target_size.y;

                vec2 scale, off;
                if (vid_aspect > out_aspect) {
                    float s = out_aspect / vid_aspect;
                    scale = vec2(1.0, s);
                    off = vec2(0.0, (1.0 - s) * 0.5);
                } else {
                    float s = vid_aspect / out_aspect;
                    scale = vec2(s, 1.0);
                    off = vec2((1.0 - s) * 0.5, 0.0);
                }

                vec2 vid_pos = (ORIGINAL_pos - off) / scale;

                if (all(greaterThanEqual(vid_pos, vec2(0.0))) &&
                    all(lessThanEqual(vid_pos, vec2(1.0)))) {
                    return ORIGINAL_tex(vid_pos);
                }

                return GLOW_tex(ORIGINAL_pos) * $BRIGHTNESS;
            }

            """.trimIndent(),
        )
    }

    /** One pass saving [save] from [bind], at [size]'s texture divided as given (its own size without). */
    private fun StringBuilder.pass(save: String, desc: String, bind: String, size: Pair<String, String>? = null, body: String) {
        appendLine("//!HOOK MAIN")
        appendLine("//!BIND $bind")
        appendLine("//!SAVE $save")
        size?.let { (texture, divide) ->
            appendLine("//!WIDTH $texture.w $divide")
            appendLine("//!HEIGHT $texture.h $divide")
        }
        appendLine("//!DESC Ambient Lighting $desc")
        appendLine("vec4 hook() {")
        appendLine(body)
        appendLine("}")
        appendLine()
    }

    /** A Kawase blur pass: four samples [offset] texels away on the diagonals, averaged. */
    private fun StringBuilder.kawase(input: String, output: String, offset: String, desc: String) {
        appendLine("//!HOOK MAIN")
        appendLine("//!BIND $input")
        appendLine("//!SAVE $output")
        appendLine("//!WIDTH $input.w")
        appendLine("//!HEIGHT $input.h")
        appendLine("//!DESC Ambient Lighting $desc")
        appendLine("vec4 hook() {")
        appendLine("    vec2 ps = ${input}_pt;")
        appendLine("    vec4 s = ${input}_tex(${input}_pos + vec2( $offset,  $offset) * ps)")
        appendLine("           + ${input}_tex(${input}_pos + vec2( $offset, -$offset) * ps)")
        appendLine("           + ${input}_tex(${input}_pos + vec2(-$offset,  $offset) * ps)")
        appendLine("           + ${input}_tex(${input}_pos + vec2(-$offset, -$offset) * ps);")
        appendLine("    return s * 0.25;")
        appendLine("}")
        appendLine()
    }
}
