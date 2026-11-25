package com.edde746.plezy.playback.mpv

import com.edde746.plezy.log.Log
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.parseMpvConfigText

/**
 * The user's mpv.conf ([AppSettings.mpvConfigText]) for one video engine. The engine sets its own startup options
 * first, then [options], one at a time (a value mpv refuses is logged and the rest still go), before its first
 * loadfile. Every write the engine makes after that (a file's values, decoding, subtitle styling, `volume-max`, the
 * HDR output) goes through one helper per engine that asks [appWrites], so a line keeps its value over the app's.
 *
 * Some names stay with the app, each skipped with a warning naming why:
 * - `hdr-enabled` and `hdr-tone-mapping`, everywhere: the player's HDR settings, not mpv properties.
 * - On the Linux video plane, also `vo`, `gpu-context` and `gpu-api` (embedded video renders through `vo=libmpv`; a
 *   windowed vo would open a window of its own and leave the plane without a picture), and `target-trc`,
 *   `target-prim`, `target-peak` and `tone-mapping`, which the plane sets from the HDR settings and keeps track of.
 */
class MpvUserConfig private constructor(
    /** The lines mpv gets, in the config's order, quotes around a value gone ([parseMpvConfigText]). */
    val options: List<Pair<String, String>>,
) {
    /** The names a line sets. */
    val keys: Set<String> = options.mapTo(LinkedHashSet()) { it.first }

    /** The value a line gives [name]; null when none does. */
    operator fun get(name: String): String? = options.lastOrNull { it.first == name }?.second

    /** Whether the engine's own write of [name] goes: no line sets it, or it is the file's own ([FILE_OWNED]). */
    fun appWrites(name: String): Boolean = name !in keys || name in FILE_OWNED

    /** [writes] without the names a line keeps ([appWrites]). */
    fun yielding(writes: Map<String, String>): Map<String, String> = if (keys.isEmpty()) writes else writes.filterKeys(::appWrites)

    /**
     * mpv's `vd-lavc-o` ([DECODER_OPTIONS]) from the engine's own decoder options [app] and a line's: the line's text
     * after the app's, so FFmpeg, which keeps a key's last value, takes the line's for a key it names and keeps every
     * app key it doesn't. An engine that writes its own decoder options writes this instead, at startup and per file.
     */
    fun decoderOptions(app: String): String =
        listOf(app, this[DECODER_OPTIONS].orEmpty().trim()).filter { it.isNotEmpty() }.joinToString(",")

    companion object {
        /** The decoder's AVOptions, one list an engine's own keys and a line's share ([decoderOptions]). */
        const val DECODER_OPTIONS = "vd-lavc-o"

        /** Not mpv properties: the player's HDR settings. */
        val APP_SETTINGS: Set<String> = setOf("hdr-enabled", "hdr-tone-mapping")

        /** The Linux video plane's video output. */
        val PLANE_OUTPUT: Set<String> = setOf("vo", "gpu-context", "gpu-api")

        /** The Linux video plane's HDR output, set from the HDR settings. */
        val PLANE_HDR: Set<String> = setOf("target-trc", "target-prim", "target-peak", "tone-mapping")

        /** Each file's own values: where it starts, its title, the server's headers; a line doesn't hold them. */
        val FILE_OWNED: Set<String> = setOf("start", "force-media-title", "http-header-fields")

        /** The config [text] for an engine; [linuxPlane]: it shows video on the Linux video plane. */
        fun of(text: String, linuxPlane: Boolean): MpvUserConfig = MpvUserConfig(
            parseMpvConfigText(text).mapNotNull { (name, value) ->
                val reason = when {
                    name in APP_SETTINGS -> "it is the player's HDR setting, not an mpv property: set it in the player's HDR settings"
                    linuxPlane && name in PLANE_OUTPUT ->
                        "the app owns the video output here (embedded video is vo=libmpv); a windowed vo such as gpu-next " +
                            "can't show inside the app, so compute shaders such as ArtCNN can't run embedded either"
                    linuxPlane && name in PLANE_HDR -> "the video plane owns it: set it in the player's HDR settings"
                    else -> null
                }
                if (reason == null) {
                    name to value
                } else {
                    Log.w(TAG) { "mpv.conf line $name=$value skipped: $reason" }
                    null
                }
            },
        )

        private const val TAG = "mpv"
    }
}
