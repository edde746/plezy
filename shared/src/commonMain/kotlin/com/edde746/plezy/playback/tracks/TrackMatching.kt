package com.edde746.plezy.playback.tracks

import com.edde746.plezy.backend.SubtitlePreference
import com.edde746.plezy.model.MediaAudioTrack
import com.edde746.plezy.model.MediaSubtitleTrack
import com.edde746.plezy.model.audioCodecsMatch
import com.edde746.plezy.model.effectiveForced
import com.edde746.plezy.model.findByEvidence
import com.edde746.plezy.model.subtitleCodecsMatch
import com.edde746.plezy.model.titleScore

// The player and the server may list the same tracks in different orders, so tracks are paired by their properties
// (language, codec, title…), never by list position alone.

/**
 * How well player subtitle [native] matches server row [source]: language +10 (+1 for the exact code), codec +5,
 * title 0–3 (1 when the player has none), the same forced class +2, the same container position +1.
 */
private fun scoreSubtitleMatch(native: NativeSubtitleTrack, source: MediaSubtitleTrack, ordinalMatches: Boolean): Int {
    var score = 0
    if (languagesMatch(native.language, source.languageCode)) {
        score += 10
        if (languageCodesExactMatch(native.language, source.languageCode)) score += 1
    }
    if (subtitleCodecsMatch(native.codec, source.codec)) score += 5
    score += titleScore(native.title, source.title, source.displayTitle)
    if (native.effectiveForced == source.effectiveForced) score += 2
    if (ordinalMatches) score += 1
    return score
}

/**
 * How well player audio [native] matches server row [source]: language +10 (+1 exact), codec +5, channel count +3,
 * title +2, the same position +1.
 */
private fun scoreAudioMatch(native: NativeAudioTrack, source: MediaAudioTrack, ordinalMatches: Boolean): Int {
    var score = 0
    if (languagesMatch(native.language, source.languageCode)) {
        score += 10
        if (languageCodesExactMatch(native.language, source.languageCode)) score += 1
    }
    if (audioCodecsMatch(native.codec, source.codec)) score += 5
    if (native.channels != null && native.channels == source.channels) score += 3
    if (titleScore(native.title, source.title, source.displayTitle) > 0) score += 2
    if (ordinalMatches) score += 1
    return score
}

private fun isDirectEmbeddedSource(track: MediaSubtitleTrack): Boolean = !track.isExternal

private fun isDirectEmbeddedNative(track: NativeSubtitleTrack): Boolean = track.isReal && !track.isExternal && !track.isContainer

/**
 * Whether the server's ordinary embedded rows have all arrived as player tracks: the same count, at least one. Sidecar
 * rows and container tracks arrive on their own schedule and never prove the catalog complete.
 */
internal fun directEmbeddedCatalogComplete(sourceTracks: List<MediaSubtitleTrack>, nativeTracks: List<NativeSubtitleTrack>): Boolean {
    val sourceCount = sourceTracks.count(::isDirectEmbeddedSource)
    return sourceCount > 0 && sourceCount == nativeTracks.count(::isDirectEmbeddedNative)
}

private fun hasFact(value: String?): Boolean = value != null && value.isNotBlank()

/** No fact on one side contradicts the other: language, codec, title, and the same forced class. */
private fun lowMetadataCompatible(native: NativeSubtitleTrack, source: MediaSubtitleTrack): Boolean {
    if (hasFact(native.language) && hasFact(source.languageCode) && !languagesMatch(native.language, source.languageCode)) return false
    if (hasFact(native.codec) && hasFact(source.codec) && !subtitleCodecsMatch(native.codec, source.codec)) return false
    val sourceHasTitle = hasFact(source.title) || hasFact(source.displayTitle)
    if (hasFact(native.title) && sourceHasTitle && titleScore(native.title, source.title, source.displayTitle) == 0) return false
    return native.effectiveForced == source.effectiveForced
}

private fun lowMetadataScore(native: NativeSubtitleTrack, source: MediaSubtitleTrack): Int {
    var score = 0
    if (hasFact(native.language) && hasFact(source.languageCode) && languagesMatch(native.language, source.languageCode)) {
        score += 10
        if (languageCodesExactMatch(native.language, source.languageCode)) score++
    }
    if (hasFact(native.codec) && hasFact(source.codec) && subtitleCodecsMatch(native.codec, source.codec)) score += 5
    if (hasFact(native.title) &&
        (hasFact(source.title) || hasFact(source.displayTitle)) &&
        titleScore(native.title, source.title, source.displayTitle) > 0
    ) {
        score += 3
    }
    if (native.effectiveForced == source.effectiveForced) score += 2
    return score
}

/** The compatible candidate with the strictly best score, or null when none is compatible or the best ties. */
private fun <T> uniqueBestLowMetadataMatch(candidates: List<T>, isCompatible: (T) -> Boolean, score: (T) -> Int): T? {
    var best: T? = null
    var bestScore = -1
    var unique = false
    for (candidate in candidates) {
        if (!isCompatible(candidate)) continue
        val candidateScore = score(candidate)
        if (candidateScore > bestScore) {
            best = candidate
            bestScore = candidateScore
            unique = true
        } else if (candidateScore == bestScore) {
            unique = false
        }
    }
    return if (unique) best else null
}

private fun MediaSubtitleTrack.isKeyless(): Boolean = key.isNullOrEmpty()

/**
 * The player track that is server row [source], or null while none can be told apart.
 *
 * A `source:<id>` track is the row by id. A row with a key (a sidecar) is only ever the external track whose URI
 * contains that key, never a lookalike. Otherwise the best scoring track of at least 10 wins (an embedded row never
 * pairs with a standalone external track), and so does a container track at the row's container position, its only
 * stable identity. When [allSourceTracks] shows the embedded catalog complete, a track with too little metadata to
 * score may still pair with the row on the strength of its facts alone, if exactly one fits best.
 */
fun findNativeTrackForSourceSubtitle(
    source: MediaSubtitleTrack,
    nativeTracks: List<NativeSubtitleTrack>,
    allSourceTracks: List<MediaSubtitleTrack>? = null,
): NativeSubtitleTrack? {
    if (nativeTracks.isEmpty()) return null
    nativeTracks.firstOrNull { it.id == sourceTrackId(source.id) }?.let { return it }

    val key = source.key
    if (!key.isNullOrEmpty()) return nativeTracks.firstOrNull { it.isExternal && it.uri?.contains(key) == true }

    val containerSources = allSourceTracks?.filter { it.isKeyless() }
    val internalNatives = if (allSourceTracks == null) null else nativeTracks.filter { !it.isExternal || it.isContainer }
    val sourceOrdinal = containerSources?.indexOf(source) ?: -1

    var best: NativeSubtitleTrack? = null
    var bestScore = 0
    var bestByContainerOrdinal = false
    for (native in nativeTracks) {
        if (!source.isExternal && native.isExternal && !native.isContainer) continue
        val ordinalMatches = internalNatives != null && sourceOrdinal >= 0 && internalNatives.indexOf(native) == sourceOrdinal
        // A container track has no stable id: its container position is authoritative.
        if (native.isContainer && sourceOrdinal >= 0 && !ordinalMatches) continue
        val score = scoreSubtitleMatch(native, source, ordinalMatches)
        if (score > bestScore) {
            bestScore = score
            best = native
            bestByContainerOrdinal = native.isContainer && ordinalMatches
        }
    }
    if (bestScore >= 10 || bestByContainerOrdinal) return best

    if (allSourceTracks == null || !isDirectEmbeddedSource(source) || !directEmbeddedCatalogComplete(allSourceTracks, nativeTracks)) {
        return null
    }
    return uniqueBestLowMetadataMatch(
        nativeTracks.filter(::isDirectEmbeddedNative),
        isCompatible = { lowMetadataCompatible(it, source) },
        score = { lowMetadataScore(it, source) },
    )
}

/**
 * The server row that player track [native] is: [findNativeTrackForSourceSubtitle] the other way round. A standalone
 * external track maps back only by a row's key in its URI; a container track only at its own container position once
 * [allNativeTracks] gives one.
 */
fun findSourceTrackForNativeSubtitle(
    native: NativeSubtitleTrack,
    sourceTracks: List<MediaSubtitleTrack>,
    allNativeTracks: List<NativeSubtitleTrack>? = null,
): MediaSubtitleTrack? {
    if (sourceTracks.isEmpty()) return null
    sourceStreamIdOf(native.id)?.let { id -> sourceTracks.firstOrNull { it.id == id }?.let { return it } }

    val uri = native.uri
    if (native.isExternal && uri != null) {
        sourceTracks.firstOrNull { row -> !row.key.isNullOrEmpty() && uri.contains(row.key) }?.let { return it }
        if (!native.isContainer) return null
    }

    val nativeIsInternal = !native.isExternal || native.isContainer
    val containerSources = if (allNativeTracks == null) null else sourceTracks.filter { it.isKeyless() }
    val nativeOrdinal = allNativeTracks?.filter { !it.isExternal || it.isContainer }?.indexOf(native) ?: -1

    var best: MediaSubtitleTrack? = null
    var bestScore = 0
    var bestByContainerOrdinal = false
    for (source in sourceTracks) {
        if (nativeIsInternal && source.isExternal) continue
        val ordinalMatches = containerSources != null && nativeOrdinal >= 0 && containerSources.indexOf(source) == nativeOrdinal
        if (native.isContainer && containerSources != null && !ordinalMatches) continue
        val score = scoreSubtitleMatch(native, source, ordinalMatches)
        if (score > bestScore) {
            bestScore = score
            best = source
            bestByContainerOrdinal = native.isContainer && ordinalMatches
        }
    }
    if (bestScore >= 10 || bestByContainerOrdinal) return best

    if (allNativeTracks == null || !isDirectEmbeddedNative(native) || !directEmbeddedCatalogComplete(sourceTracks, allNativeTracks)) {
        return null
    }
    return uniqueBestLowMetadataMatch(
        sourceTracks.filter(::isDirectEmbeddedSource),
        isCompatible = { lowMetadataCompatible(native, it) },
        score = { lowMetadataScore(native, it) },
    )
}

/**
 * The server row that serves a subtitle [intent] carried from another item: language and forced class are hard gates,
 * a title vouches only without language parity, and a tie declines. The intent names no row of its own.
 */
fun findSourceTrackForIntent(intent: SubtitlePreference.Track, sourceTracks: List<MediaSubtitleTrack>): MediaSubtitleTrack? =
    com.edde746.plezy.model.findSourceTrackForIntent(intent.copy(sourceStreamId = null), sourceTracks)

/** The player track that serves a subtitle [intent] carried from another item, by the rules of [findSourceTrackForIntent]. */
fun findNativeTrackForIntent(intent: SubtitlePreference.Track, tracks: List<NativeSubtitleTrack>): NativeSubtitleTrack? =
    findByEvidence(
        tracks.filter { it.isReal },
        intentLanguage = intent.language,
        classMatches = { it.effectiveForced == intent.forced },
        language = { it.language },
        titleScore = { titleScore(intent.title, it.title, null) },
        codecMatches = { subtitleCodecsMatch(intent.codec, it.codec) },
        extraScore = { if (intent.isExternal == it.isExternal) 1 else 0 },
    )

/**
 * The player audio track that serves audio [carried] from another item: no forced gate, channel-count parity breaks
 * the last ties.
 */
fun findNativeAudioTrackForIntent(carried: NativeAudioTrack, tracks: List<NativeAudioTrack>): NativeAudioTrack? =
    findByEvidence(
        tracks.filter { it.isReal },
        intentLanguage = carried.language,
        classMatches = { true },
        language = { it.language },
        titleScore = { titleScore(carried.title, it.title, null) },
        codecMatches = { audioCodecsMatch(carried.codec, it.codec) },
        extraScore = { if (carried.channels != null && carried.channels == it.channels) 1 else 0 },
    )

/**
 * The id of a carried audio track (the request's, from another item): it matches by its language, title, codec and
 * channels alone. Player ids ("1", "2"…) and `source:<index>` ids repeat across items, so a carry keeping its id would
 * match whatever track sits at the same place in the next item.
 */
const val CARRIED_AUDIO_TRACK_ID = "carried"

/** The best scoring of [candidates] at 10 or more (a language match at least); the position bonus is cross-side. */
private fun <T> bestScoredAudioMatch(candidates: List<T>, probeOrdinal: Int, score: (T, Boolean) -> Int): T? {
    var best: T? = null
    var bestScore = 0
    candidates.forEachIndexed { index, candidate ->
        val candidateScore = score(candidate, index == probeOrdinal)
        if (candidateScore > bestScore) {
            bestScore = candidateScore
            best = candidate
        }
    }
    return if (bestScore >= 10) best else null
}

/** The player audio track that is server row [source]; [allSourceTracks] gives the row's position. */
fun findNativeTrackForSourceAudio(
    source: MediaAudioTrack,
    nativeTracks: List<NativeAudioTrack>,
    allSourceTracks: List<MediaAudioTrack>? = null,
): NativeAudioTrack? = bestScoredAudioMatch(nativeTracks, allSourceTracks?.indexOf(source) ?: -1) { native, ordinal ->
    scoreAudioMatch(native, source, ordinal)
}

/** The server audio row that player track [native] is; [allNativeTracks] gives the track's position. */
fun findSourceTrackForNativeAudio(
    native: NativeAudioTrack,
    sourceTracks: List<MediaAudioTrack>,
    allNativeTracks: List<NativeAudioTrack>? = null,
): MediaAudioTrack? = bestScoredAudioMatch(sourceTracks, allNativeTracks?.indexOf(native) ?: -1) { source, ordinal ->
    scoreAudioMatch(native, source, ordinal)
}

/**
 * The server audio row the player plays, or null when its selection maps to none. Weakest evidence last: the
 * selected track's position among the real player tracks, then [findSourceTrackForNativeAudio], then a player id that
 * is a row's stream id. [nativeTracks] is the player's whole list.
 */
fun playingSourceAudioTrack(
    selected: NativeAudioTrack?,
    nativeTracks: List<NativeAudioTrack>,
    sourceTracks: List<MediaAudioTrack>,
): MediaAudioTrack? {
    if (selected == null || sourceTracks.isEmpty()) return null
    val ordinal = nativeTracks.filter { it.isReal }.indexOf(selected)
    if (ordinal >= 0 && ordinal < sourceTracks.size) return sourceTracks[ordinal]
    findSourceTrackForNativeAudio(selected, sourceTracks, nativeTracks)?.let { return it }
    val parsedId = selected.id.toIntOrNull() ?: return null
    return sourceTracks.firstOrNull { it.id == parsedId }
}

/** Whether two language codes name the same language, ignoring case and regions; null never matches. */
internal fun languagesMatch(a: String?, b: String?): Boolean =
    a != null && b != null && com.edde746.plezy.model.languagesMatch(a, b)

/** Whether two codes are the same code once case and regions are stripped. */
private fun languageCodesExactMatch(a: String?, b: String?): Boolean =
    a != null && b != null && a.lowercase().substringBefore('-') == b.lowercase().substringBefore('-')
