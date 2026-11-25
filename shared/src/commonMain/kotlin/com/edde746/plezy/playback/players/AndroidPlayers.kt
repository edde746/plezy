package com.edde746.plezy.playback.players

/**
 * One extra of a player app's `ACTION_VIEW` intent, typed as the apps read it: `Bundle.getInt` finds nothing where a
 * Long was put, and a `String[]` where a `Parcelable[]` of `Uri`s is read. The values carry the stream's URL: never log
 * them.
 */
sealed interface AndroidExtra {
    val key: String

    data class Text(override val key: String, val value: String) : AndroidExtra

    /** A `String[]`. */
    data class Texts(override val key: String, val values: List<String>) : AndroidExtra

    data class IntValue(override val key: String, val value: Int) : AndroidExtra

    data class Flag(override val key: String, val value: Boolean) : AndroidExtra

    /** A `Parcelable[]` of `Uri`s, from their strings. */
    data class Uris(override val key: String, val uris: List<String>) : AndroidExtra
}

/**
 * A file handed with the intent: its [uri] (an http(s) URL, or the `content://` URI a local file is shared under) and
 * its [fileName] (the URI's last path segment, a local file's name).
 */
data class AndroidSource(val uri: String, val fileName: String?) {
    override fun toString(): String = "AndroidSource(uri=<redacted>, fileName=$fileName)"
}

/** A subtitle handed with the video: [name] its title, [enabled] the one to show. */
data class AndroidSubtitle(val source: AndroidSource, val name: String?, val enabled: Boolean)

/**
 * The intent hand-off to Android player apps: one `ACTION_VIEW` of any video type with the extras the common players read
 * ([extras]), started for a result, and that result read back ([result]):
 *
 * - **MX Player** (`com.mxtech.videoplayer.ad`, `.pro`) and **Just Player** read `position` (int, ms), `title`,
 *   `filename`, `secure_uri`, `return_result`, and the subtitles `subs` (`Uri[]`), `subs.name`, `subs.filename`,
 *   `subs.enable`; they answer `com.mxtech.intent.result.VIEW` with `position`, `duration` and `end_by`.
 * - **mpv-android** reads `position`, `title`, `subs` and `subs.enable`, and answers `position`/`duration`.
 * - **VLC** and the native Zidoo player read `from_start`: without it, a launch with no resume point lets the player
 *   consult its own bookmarks, which collide across Plex items because every part URL ends in `file.<ext>`. VLC answers
 *   `extra_position`/`extra_duration`. Its subtitle extra takes only a local path, so subtitles don't reach it.
 * - **Vimu** reads `forcename`, `startfrom` and `forceresume`, and answers `net.gtvbox.videoplayer.result` with result
 *   code 1 (played to the end) or 4 (failed).
 */
object AndroidPlayers {
    /** The extras of the intent for [source], starting at [startPositionMs] (0: from the beginning). */
    fun extras(source: AndroidSource, startPositionMs: Long, title: String?, subtitles: List<AndroidSubtitle>): List<AndroidExtra> = buildList {
        val start = startPositionMs.coerceIn(0, Int.MAX_VALUE.toLong()).toInt()
        if (start > 0) {
            add(AndroidExtra.IntValue(POSITION, start))
            add(AndroidExtra.IntValue(VIMU_START, start))
            add(AndroidExtra.Flag(FROM_START, false))
        } else {
            add(AndroidExtra.Flag(FROM_START, true))
        }
        add(AndroidExtra.Flag(RETURN_RESULT, true))
        add(AndroidExtra.Flag(SECURE_URI, true))
        add(AndroidExtra.Flag(VIMU_RESUME, false))
        title?.let {
            add(AndroidExtra.Text(TITLE, it))
            add(AndroidExtra.Text(VIMU_TITLE, it))
        }
        source.fileName?.let { add(AndroidExtra.Text(FILENAME, it)) }
        if (subtitles.isNotEmpty()) {
            add(AndroidExtra.Uris(SUBS, subtitles.map { it.source.uri }))
            add(AndroidExtra.Texts(SUBS_NAME, subtitles.map { it.name ?: it.source.fileName.orEmpty() }))
            add(AndroidExtra.Texts(SUBS_FILENAME, subtitles.map { it.source.fileName.orEmpty() }))
            add(AndroidExtra.Uris(SUBS_ENABLE, subtitles.filter { it.enabled }.map { it.source.uri }))
        }
    }

    /**
     * What a player's activity result says: the first number among its position extras and its duration extras (an Int,
     * a Long or text), completed when MX Player's result says it ended by playback completion, Vimu's code says it
     * played to the end, or mpv's is a success without a position (mpv leaves the position out when the file finished),
     * an error only on Vimu's failure code.
     */
    fun result(action: String?, resultCode: Int, extras: Map<String, Any?>): ExternalPlaybackResult {
        fun firstNumber(keys: List<String>): Long? {
            for (key in keys) {
                when (val value = extras[key]) {
                    is Number -> return value.toLong()
                    is String -> value.toLongOrNull()?.let { return it }
                }
            }
            return null
        }
        val positionMs = firstNumber(listOf(POSITION, VLC_POSITION))
        val completed = when (action) {
            MX_RESULT -> extras[END_BY] == END_BY_COMPLETION
            VIMU_RESULT -> resultCode == VIMU_COMPLETED
            MPV_RESULT -> resultCode == RESULT_OK && positionMs == null
            else -> false
        }
        return ExternalPlaybackResult(
            positionMs = positionMs,
            durationMs = firstNumber(listOf(DURATION, VLC_DURATION)),
            completed = completed,
            error = action == VIMU_RESULT && resultCode == VIMU_FAILED,
        )
    }

    private const val POSITION = "position"
    private const val DURATION = "duration"
    private const val TITLE = "title"
    private const val FILENAME = "filename"
    private const val RETURN_RESULT = "return_result"
    private const val SECURE_URI = "secure_uri"
    private const val SUBS = "subs"
    private const val SUBS_NAME = "subs.name"
    private const val SUBS_FILENAME = "subs.filename"
    private const val SUBS_ENABLE = "subs.enable"
    private const val END_BY = "end_by"
    private const val END_BY_COMPLETION = "playback_completion"
    private const val MX_RESULT = "com.mxtech.intent.result.VIEW"
    private const val VLC_POSITION = "extra_position"
    private const val VLC_DURATION = "extra_duration"
    private const val MPV_RESULT = "is.xyz.mpv.MPVActivity.result"
    private const val RESULT_OK = -1
    private const val FROM_START = "from_start"
    private const val VIMU_TITLE = "forcename"
    private const val VIMU_START = "startfrom"
    private const val VIMU_RESUME = "forceresume"
    private const val VIMU_RESULT = "net.gtvbox.videoplayer.result"
    private const val VIMU_COMPLETED = 1
    private const val VIMU_FAILED = 4
}
