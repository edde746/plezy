package com.edde746.plezy.model

import com.edde746.plezy.backend.AudioTrackPreference
import com.edde746.plezy.backend.SubtitlePreference
import com.edde746.plezy.lang.LanguageTags

/**
 * Forced-ness as the servers treat it: the flag, or a title that says "forced". Every forced comparison uses this on
 * both sides; the raw [MediaSubtitleTrack.forced] keeps the server's truth for parsing and file info.
 */
val MediaSubtitleTrack.effectiveForced: Boolean
    get() = forced || titleSaysForced(title) || titleSaysForced(displayTitle)

/**
 * The row of [sourceTracks] that serves a subtitle [intent] carried from another item, or null when none does or the
 * catalog cannot tell which one the viewer meant.
 *
 * Forced-ness is a hard gate, and so is language when both sides declare one. Without language on either side, only a
 * real title match may vouch for a row; codec or external parity alone never does. Ties are broken by the title, then
 * the codec, then external parity; a tie still standing declines, so two indistinguishable rows never latch by order.
 *
 * [SubtitlePreference.Track.sourceStreamId], the row picked in this same item, wins outright when the intent declares
 * no language. Otherwise the semantic match decides, and when it declines on a tie the picked row settles it if it
 * passes the gates itself and no other row serves the intent better.
 */
fun findSourceTrackForIntent(intent: SubtitlePreference.Track, sourceTracks: List<MediaSubtitleTrack>): MediaSubtitleTrack? {
    val picked = intent.sourceStreamId?.let { id -> sourceTracks.firstOrNull { it.id == id } }
    if (picked != null && intent.language.isNullOrEmpty()) return picked
    matchSubtitleIntent(intent, sourceTracks)?.let { return it }
    if (picked == null || matchSubtitleIntent(intent, listOf(picked)) == null) return null
    val outranked = sourceTracks.any { other ->
        other.id != picked.id && matchSubtitleIntent(intent, listOf(picked, other))?.id == other.id
    }
    return if (outranked) null else picked
}

/**
 * The row of [rows] that serves an audio track [carried] from another item: [findSourceTrackForIntent] without the
 * forced gate, with channel-count parity in place of external parity.
 */
fun findSourceAudioTrackForIntent(carried: AudioTrackPreference, rows: List<MediaAudioTrack>): MediaAudioTrack? =
    findByEvidence(
        rows,
        intentLanguage = carried.language,
        classMatches = { true },
        language = { it.languageCode ?: it.language },
        titleScore = { titleScore(carried.title, it.title, it.displayTitle) },
        codecMatches = { codecsMatch(carried.codec, it.codec, AUDIO_CODEC_ALIASES) },
        extraScore = { if (carried.channels != null && carried.channels == it.channels) 1 else 0 },
    )

private fun matchSubtitleIntent(intent: SubtitlePreference.Track, rows: List<MediaSubtitleTrack>): MediaSubtitleTrack? =
    findByEvidence(
        rows,
        intentLanguage = intent.language,
        classMatches = { it.effectiveForced == intent.forced },
        language = { it.languageCode ?: it.language },
        titleScore = { titleScore(intent.title, it.title, it.displayTitle) },
        codecMatches = { codecsMatch(intent.codec, it.codec, SUBTITLE_CODEC_ALIASES) },
        extraScore = { if (intent.isExternal == it.isExternal) 1 else 0 },
    )

/**
 * The candidate with the strongest evidence, compared strongest first: declared-language parity, the title match,
 * codec parity, then [extraScore]. Each tier only breaks ties the tiers above left; a tie at the top declines.
 */
internal fun <T> findByEvidence(
    candidates: List<T>,
    intentLanguage: String?,
    classMatches: (T) -> Boolean,
    language: (T) -> String?,
    titleScore: (T) -> Int,
    codecMatches: (T) -> Boolean,
    extraScore: (T) -> Int,
): T? {
    var best: T? = null
    var bestKey: IntArray? = null
    var ambiguous = false
    for (candidate in candidates) {
        if (!classMatches(candidate)) continue
        val candidateLanguage = language(candidate)
        val candidateTitleScore = titleScore(candidate)
        val hasLanguageParity = intentLanguage != null && candidateLanguage != null
        if (hasLanguageParity) {
            // A language declared on both sides stays authoritative: a contradiction declines whatever the title says.
            if (!languagesMatch(intentLanguage, candidateLanguage)) continue
        } else if (candidateTitleScore < TITLE_MATCH) {
            continue
        }
        val key = intArrayOf(
            if (hasLanguageParity) 1 else 0,
            candidateTitleScore,
            if (codecMatches(candidate)) 1 else 0,
            extraScore(candidate),
        )
        val comparison = bestKey?.let { compareKeys(key, it) } ?: 1
        if (comparison > 0) {
            best = candidate
            bestKey = key
            ambiguous = false
        } else if (comparison == 0) {
            ambiguous = true
        }
    }
    return if (ambiguous) null else best
}

private fun compareKeys(a: IntArray, b: IntArray): Int {
    for (i in a.indices) if (a[i] != b[i]) return a[i].compareTo(b[i])
    return 0
}

/** Whether two language codes name the same language, across ISO 639-1, 639-2/T and 639-2/B, ignoring regions. */
internal fun languagesMatch(a: String, b: String): Boolean {
    val left = a.lowercase().substringBefore('-')
    val right = b.lowercase().substringBefore('-')
    if (left == right) return true
    val canonical = LanguageTags.canonical(left) ?: return false
    return canonical == LanguageTags.canonical(right)
}

internal const val TITLE_MATCH = 3

/** [TITLE_MATCH] when [title] equals or is contained in either row title, 1 when there is no title to contradict, else 0. */
internal fun titleScore(title: String?, rowTitle: String?, rowDisplayTitle: String?): Int {
    if (title.isNullOrEmpty()) return 1
    val wanted = title.lowercase().trim()
    val matches = listOfNotNull(rowTitle, rowDisplayTitle).any { it.lowercase().contains(wanted) }
    return if (matches) TITLE_MATCH else 0
}

/** Whether two subtitle codec names are the same codec (`srt` and `subrip`…). */
internal fun subtitleCodecsMatch(wanted: String?, row: String?): Boolean = codecsMatch(wanted, row, SUBTITLE_CODEC_ALIASES)

/** Whether two audio codec names are the same codec (`dts` and `dca`…), as far as a wanted [wanted] accepts [row]. */
internal fun audioCodecsMatch(wanted: String?, row: String?): Boolean = codecsMatch(wanted, row, AUDIO_CODEC_ALIASES)

private fun codecsMatch(wanted: String?, row: String?, aliases: Map<String, List<String>>): Boolean {
    if (wanted == null || row == null) return false
    val left = wanted.lowercase()
    val right = row.lowercase()
    return left == right || aliases[left]?.contains(right) == true
}

private val SUBTITLE_CODEC_ALIASES = mapOf(
    "subrip" to listOf("srt", "subrip"),
    "srt" to listOf("srt", "subrip"),
    "ass" to listOf("ass", "ssa"),
    "ssa" to listOf("ass", "ssa"),
    "pgs" to listOf("pgs", "hdmv_pgs_subtitle"),
    "hdmv_pgs_subtitle" to listOf("pgs", "hdmv_pgs_subtitle"),
    "vobsub" to listOf("vobsub", "dvd_subtitle"),
    "dvd_subtitle" to listOf("vobsub", "dvd_subtitle"),
    "webvtt" to listOf("webvtt", "vtt"),
    "vtt" to listOf("webvtt", "vtt"),
)

private val AUDIO_CODEC_ALIASES = mapOf(
    "ac3" to listOf("ac3", "a52", "eac3", "dolby digital"),
    "a52" to listOf("ac3", "a52"),
    "eac3" to listOf("eac3", "e-ac-3", "dolby digital plus", "ac3"),
    "dts" to listOf("dts", "dca"),
    "dca" to listOf("dts", "dca"),
    "aac" to listOf("aac", "mp4a"),
    "mp4a" to listOf("aac", "mp4a"),
    "truehd" to listOf("truehd", "mlp"),
    "mlp" to listOf("truehd", "mlp"),
    "flac" to listOf("flac"),
    "opus" to listOf("opus"),
    "vorbis" to listOf("vorbis", "ogg"),
    "mp3" to listOf("mp3", "mp3float"),
)
