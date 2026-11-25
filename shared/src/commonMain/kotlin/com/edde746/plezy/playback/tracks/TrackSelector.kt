package com.edde746.plezy.playback.tracks

import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaServerUserProfile
import com.edde746.plezy.model.MediaSourceInfo
import com.edde746.plezy.model.MediaSubtitleTrack
import com.edde746.plezy.model.SubtitlePlaybackMode
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.Duration.Companion.seconds

/** Which rung of the selection ladder picked a track, strongest first. */
enum class TrackSelectionPriority {
    /** The viewer's own pick, carried from the previous item or reload. */
    NAVIGATION,

    /** The server's selected (or MediaBrowser default) stream. */
    SERVER_SELECTED,

    /** The account's language and subtitle-mode preferences. */
    PROFILE,

    /** The track the file flags default, else the first. */
    DEFAULT_TRACK,

    /** Subtitles off, nothing else applying. */
    OFF,
}

data class TrackSelectionResult<T>(val track: T, val priority: TrackSelectionPriority)

/**
 * Picks the audio and subtitle tracks for one open of [backend]'s item from the player's tracks, by priority: the
 * viewer's carried pick, the server's selection for the item ([sourceInfo]), the account's preferences ([profile]),
 * then the file's default. Per-item language overrides are not a rung: every backend folds them into the source's
 * selected stream already.
 */
class TrackSelector(
    private val backend: BackendKind,
    private val sourceInfo: MediaSourceInfo?,
    private val profile: MediaServerUserProfile? = null,
) {
    /**
     * The best of [tracks] for subtitle [preferred]: one with the same id, title and language (a reload passing back its
     * own track) ranks above one with the same title and language, then the same language. The first track of the
     * strongest rung wins; sentinels never do.
     */
    fun findBestSubtitleTrackMatch(tracks: List<NativeSubtitleTrack>, preferred: NativeSubtitleTrack): NativeSubtitleTrack? {
        var best: NativeSubtitleTrack? = null
        var bestTier = 0
        for (track in tracks) {
            if (!track.isReal || track.language != preferred.language) continue
            var tier = 1
            if (track.title == preferred.title) tier = if (track.id == preferred.id) 3 else 2
            if (tier == 3) return track
            if (tier > bestTier) {
                bestTier = tier
                best = track
            }
        }
        return best
    }

    /** The first of [tracks] in the profile's audio language, when the profile auto-selects audio. */
    fun findAudioTrackByProfile(tracks: List<NativeAudioTrack>, profile: MediaServerUserProfile): NativeAudioTrack? {
        if (tracks.isEmpty() || !profile.autoSelectAudio) return null
        val preferred = profile.defaultAudioLanguage?.takeIf { it.isNotEmpty() } ?: return null
        return tracks.firstOrNull { languageMatches(it.language, preferred) }
    }

    private fun findSubtitleTrackByProfile(
        tracks: List<NativeSubtitleTrack>,
        profile: MediaServerUserProfile,
        forcedOnly: Boolean = false,
    ): NativeSubtitleTrack? {
        val candidates = if (forcedOnly) tracks.filter { it.effectiveForced } else tracks
        val preferred = profile.defaultSubtitleLanguage?.takeIf { it.isNotEmpty() } ?: return null
        return candidates.firstOrNull { languageMatches(it.language, preferred) }
    }

    private fun audioMatchesProfile(audio: NativeAudioTrack?, profile: MediaServerUserProfile): Boolean {
        val preferred = profile.defaultAudioLanguage?.takeIf { it.isNotEmpty() } ?: return false
        return audio != null && languageMatches(audio.language, preferred)
    }

    /**
     * The account's subtitle mode, where the server leaves auto-selection to the client (MediaBrowser). Plex already
     * folded the account's mode into the stream it marks selected, and its 0 means "manually selected", not off.
     */
    private fun selectSubtitleTrackByProfile(
        tracks: List<NativeSubtitleTrack>,
        audio: NativeAudioTrack?,
    ): TrackSelectionResult<NativeSubtitleTrack>? {
        if (backend == BackendKind.PLEX) return null
        val profile = profile ?: return null
        fun forced() = findSubtitleTrackByProfile(tracks, profile, forcedOnly = true)
            ?: tracks.firstOrNull { it.effectiveForced }
            ?: NativeSubtitleTrack.OFF
        fun full() = findSubtitleTrackByProfile(tracks, profile)
            ?: tracks.firstOrNull { it.isDefault }
            ?: tracks.firstOrNull()
            ?: NativeSubtitleTrack.OFF
        val selected = when (profile.subtitleMode) {
            null, SubtitlePlaybackMode.DEFAULT_MODE -> return null
            SubtitlePlaybackMode.NONE -> NativeSubtitleTrack.OFF
            SubtitlePlaybackMode.ONLY_FORCED -> forced()
            SubtitlePlaybackMode.ALWAYS -> full()
            SubtitlePlaybackMode.SMART -> if (audioMatchesProfile(audio, profile)) forced() else full()
        }
        return TrackSelectionResult(selected, TrackSelectionPriority.PROFILE)
    }

    private fun sourceSubtitleTrack(nativeId: String): MediaSubtitleTrack? {
        val id = sourceStreamIdOf(nativeId) ?: return null
        return sourceInfo?.subtitleTracks?.firstOrNull { it.id == id }
    }

    /**
     * Whether the source proves every ordinary embedded row already arrived as a player track, so an unmatched
     * [sourceTrack] is a real mismatch rather than a track still on its way. Sidecar rows never can.
     */
    private fun completeDirectCatalogFor(sourceTrack: MediaSubtitleTrack?, tracks: List<NativeSubtitleTrack>): Boolean {
        val info = sourceInfo ?: return false
        return sourceTrack != null && !sourceTrack.isExternal && directEmbeddedCatalogComplete(info.subtitleTracks, tracks)
    }

    /**
     * The player track for subtitle reference [preferred]. A `source:` reference tries its file's URI first (a unique
     * non-container hit is the same file), then the row's own match; any other reference its URI, then
     * [findBestSubtitleTrackMatch].
     */
    fun findBestSubtitleMatch(tracks: List<NativeSubtitleTrack>, preferred: NativeSubtitleTrack): NativeSubtitleTrack? {
        if (preferred.id == NativeSubtitleTrack.OFF.id) return NativeSubtitleTrack.OFF
        if (preferred.id.startsWith("source:")) {
            val uri = preferred.uri
            if (!uri.isNullOrEmpty()) {
                tracks.filter { it.uri == uri && !it.isContainer }.singleOrNull()?.let { return it }
            }
            val sourceTrack = sourceSubtitleTrack(preferred.id) ?: return null
            return findNativeTrackForSourceSubtitle(sourceTrack, tracks, sourceInfo?.subtitleTracks)
        }
        val uri = preferred.uri
        if (uri != null) tracks.filter { it.uri == uri }.singleOrNull()?.let { return it }
        return findBestSubtitleTrackMatch(tracks, preferred)
    }

    /**
     * Audio by priority: the carried track (same id, title and language, else its best semantic match), the server's
     * selected row (MediaBrowser: its default index), the profile's language, the default-flagged or first track.
     */
    fun selectAudioTrack(tracks: List<NativeAudioTrack>, preferred: NativeAudioTrack?): TrackSelectionResult<NativeAudioTrack>? {
        if (tracks.isEmpty()) return null
        if (preferred != null) {
            val carried = tracks.firstOrNull {
                it.isReal && it.id == preferred.id && it.title == preferred.title && it.language == preferred.language
            } ?: findNativeAudioTrackForIntent(preferred, tracks)
            if (carried != null) return TrackSelectionResult(carried, TrackSelectionPriority.NAVIGATION)
            Log.d(TAG) { "Audio carry declined: ${preferred.language}/${preferred.title}" }
        }

        val info = sourceInfo
        if (info != null) {
            val serverSelected = info.audioTracks.firstOrNull { it.selected }
            val serverRow = serverSelected ?: if (backend.usesMediaBrowserApi) {
                info.defaultAudioStreamIndex?.let { index -> info.audioTracks.firstOrNull { (it.index ?: it.id) == index } }
            } else {
                null
            }
            if (serverRow != null) {
                findNativeTrackForSourceAudio(serverRow, tracks, info.audioTracks)?.let {
                    return TrackSelectionResult(it, TrackSelectionPriority.SERVER_SELECTED)
                }
            }
        }

        profile?.let { findAudioTrackByProfile(tracks, it) }?.let {
            return TrackSelectionResult(it, TrackSelectionPriority.PROFILE)
        }
        return TrackSelectionResult(tracks.firstOrNull { it.isDefault } ?: tracks.first(), TrackSelectionPriority.DEFAULT_TRACK)
    }

    /**
     * Subtitles by priority: the caller's [preference], the server's selected row (MediaBrowser: its default index, -1
     * being off; Plex with rows but none selected: off), the account's subtitle mode, the default-flagged track, off.
     *
     * Null only while the source can still deliver the wanted subtitle as a player track. With [waitForPendingSource]
     * false every pending branch falls through instead, so a deadline pass gets a real decision.
     */
    fun selectSubtitleTrack(
        tracks: List<NativeSubtitleTrack>,
        preference: PreferredSubtitle?,
        audio: NativeAudioTrack?,
        waitForPendingSource: Boolean = true,
    ): TrackSelectionResult<NativeSubtitleTrack>? {
        when (preference) {
            null -> Unit
            PreferredSubtitle.Off -> return TrackSelectionResult(NativeSubtitleTrack.OFF, TrackSelectionPriority.NAVIGATION)
            is PreferredSubtitle.Native -> {
                val track = preference.track
                if (track.id == NativeSubtitleTrack.OFF.id) {
                    return TrackSelectionResult(NativeSubtitleTrack.OFF, TrackSelectionPriority.NAVIGATION)
                }
                if (tracks.isNotEmpty()) {
                    findBestSubtitleMatch(tracks, track)?.let { return TrackSelectionResult(it, TrackSelectionPriority.NAVIGATION) }
                }
                // Only a row this catalog advertises can still arrive; a stale id resolves the same on every retry.
                if (waitForPendingSource && track.id.startsWith("source:")) {
                    val sourceTrack = sourceSubtitleTrack(track.id)
                    if (sourceTrack != null && !completeDirectCatalogFor(sourceTrack, tracks)) return null
                }
            }
            is PreferredSubtitle.Intent -> {
                if (tracks.isNotEmpty()) {
                    findNativeTrackForIntent(preference.intent, tracks)?.let {
                        return TrackSelectionResult(it, TrackSelectionPriority.NAVIGATION)
                    }
                }
                if (waitForPendingSource) {
                    val servable = findSourceTrackForIntent(preference.intent, sourceInfo?.subtitleTracks.orEmpty())
                    if (servable != null && !completeDirectCatalogFor(servable, tracks)) return null
                }
                Log.d(TAG) { "Subtitle intent declined: ${preference.intent}" }
            }
        }

        val info = sourceInfo
        if (info != null) {
            val serverSelected = info.subtitleTracks.firstOrNull { it.selected }
            if (serverSelected != null) {
                findNativeTrackForSourceSubtitle(serverSelected, tracks, info.subtitleTracks)?.let {
                    return TrackSelectionResult(it, TrackSelectionPriority.SERVER_SELECTED)
                }
                // A selected row the player has not produced yet keeps the pass pending on every backend.
                if (waitForPendingSource && !completeDirectCatalogFor(serverSelected, tracks)) return null
            } else if (backend.usesMediaBrowserApi) {
                val defaultIndex = info.defaultSubtitleStreamIndex
                if (defaultIndex == -1) return TrackSelectionResult(NativeSubtitleTrack.OFF, TrackSelectionPriority.SERVER_SELECTED)
                val defaultRow = if (defaultIndex != null && tracks.isNotEmpty()) {
                    info.subtitleTracks.firstOrNull { (it.index ?: it.id) == defaultIndex }
                } else {
                    null
                }
                if (defaultRow != null) {
                    findNativeTrackForSourceSubtitle(defaultRow, tracks, info.subtitleTracks)?.let {
                        return TrackSelectionResult(it, TrackSelectionPriority.SERVER_SELECTED)
                    }
                }
            } else if (backend == BackendKind.PLEX && info.subtitleTracks.isNotEmpty()) {
                if (tracks.isEmpty() && waitForPendingSource) return null
                return TrackSelectionResult(NativeSubtitleTrack.OFF, TrackSelectionPriority.SERVER_SELECTED)
            }
            if (waitForPendingSource && tracks.isEmpty() && info.subtitleTracks.isNotEmpty()) return null
        }

        selectSubtitleTrackByProfile(tracks, audio)?.let { return it }
        tracks.firstOrNull { it.isDefault }?.let { return TrackSelectionResult(it, TrackSelectionPriority.DEFAULT_TRACK) }
        return TrackSelectionResult(NativeSubtitleTrack.OFF, TrackSelectionPriority.OFF)
    }

    /** The player track a second-subtitle [preference] lands on, or null when none (or off). */
    fun secondarySubtitleMatch(tracks: List<NativeSubtitleTrack>, preference: PreferredSubtitle?): NativeSubtitleTrack? {
        val match = when (preference) {
            null, PreferredSubtitle.Off -> null
            is PreferredSubtitle.Native ->
                if (preference.track.id == NativeSubtitleTrack.OFF.id) null else findBestSubtitleMatch(tracks, preference.track)
            is PreferredSubtitle.Intent -> findNativeTrackForIntent(preference.intent, tracks)
        }
        return match?.takeIf { it.id != NativeSubtitleTrack.OFF.id }
    }

    /**
     * Waits for [player]'s tracks (up to 10 s, unless nothing can arrive: a burned-in primary with no second subtitle
     * wanted), then applies audio, subtitle, second subtitle and [defaultPlaybackSpeed] in that order, reporting each
     * player command to [onMutationDispatched] as it starts (completed once it ended). A pick of the
     * viewer's carried choice ([TrackSelectionPriority.NAVIGATION]) is reported to
     * [onAudioTrackChanged]/[onSubtitleTrackChanged]. Returns whether every step ran while [isActive] and the player
     * lived.
     */
    suspend fun selectAndApplyTracks(
        player: TrackPlayer,
        preferredAudioTrack: NativeAudioTrack? = null,
        preferredSubtitle: PreferredSubtitle? = null,
        preferredSecondarySubtitle: PreferredSubtitle? = null,
        defaultPlaybackSpeed: Double? = null,
        onAudioTrackChanged: (suspend (NativeAudioTrack) -> Unit)? = null,
        onSubtitleTrackChanged: (suspend (NativeSubtitleTrack) -> Unit)? = null,
        isActive: () -> Boolean = { true },
        onMutationDispatched: ((Deferred<Unit>) -> Unit)? = null,
        waitForPendingSource: Boolean = true,
        primarySubtitleIsServerRendered: Boolean = false,
    ): Boolean {
        fun canMutate() = !player.disposed && isActive()
        if (!canMutate()) return false

        val nothingToWaitFor = primarySubtitleIsServerRendered &&
            (preferredSecondarySubtitle == null || preferredSecondarySubtitle == PreferredSubtitle.Off)
        val current = player.tracks.value
        if (!nothingToWaitFor && current.audio.isEmpty() && current.subtitle.isEmpty()) {
            withTimeoutOrNull(TRACK_LOAD_TIMEOUT) { player.tracks.first { it.audio.isNotEmpty() || it.subtitle.isNotEmpty() } }
        }
        if (!canMutate()) return false

        val tracks = player.tracks.value
        val realAudio = tracks.realAudio
        val realSubtitles = tracks.realSubtitle

        val audioResult = selectAudioTrack(realAudio, preferredAudioTrack)
        val audio = audioResult?.track
        if (audioResult != null) {
            Log.d(TAG) { "Audio: ${audioResult.track.title ?: audioResult.track.language ?: "Track ${audioResult.track.id}"} [${audioResult.priority}]" }
            if (!canMutate()) return false
            dispatch(onMutationDispatched) { player.selectAudioTrack(audioResult.track) }
            if (!canMutate()) return false
            if (audioResult.priority == TrackSelectionPriority.NAVIGATION) onAudioTrackChanged?.invoke(audioResult.track)
        }

        val subtitleResult = selectSubtitleTrack(realSubtitles, preferredSubtitle, audio, waitForPendingSource)
        if (subtitleResult != null) {
            val subtitle = subtitleResult.track
            Log.d(TAG) {
                val name = if (subtitle.id == NativeSubtitleTrack.OFF.id) "OFF" else subtitle.title ?: subtitle.language ?: "Track ${subtitle.id}"
                "Subtitle: $name [${subtitleResult.priority}]"
            }
            if (!canMutate()) return false
            dispatch(onMutationDispatched) { player.selectSubtitleTrack(subtitle) }
            if (!canMutate()) return false
            if (subtitleResult.priority == TrackSelectionPriority.NAVIGATION) onSubtitleTrackChanged?.invoke(subtitle)
        } else {
            Log.d(TAG) { "Subtitle selection pending: player tracks have not arrived" }
        }

        if (preferredSecondarySubtitle != null &&
            preferredSecondarySubtitle != PreferredSubtitle.Off &&
            player.supportsSecondarySubtitles &&
            realSubtitles.isNotEmpty()
        ) {
            val secondary = secondarySubtitleMatch(realSubtitles, preferredSecondarySubtitle)
            if (secondary != null) {
                if (!canMutate()) return false
                dispatch(onMutationDispatched) { player.selectSecondarySubtitleTrack(secondary) }
                if (!canMutate()) return false
            }
        }

        // Compared with the live rate, not 1.0: an in-place reload keeps the previous item's rate.
        if (defaultPlaybackSpeed != null && defaultPlaybackSpeed != player.rate) {
            if (!canMutate()) return false
            dispatch(onMutationDispatched) { player.setRate(defaultPlaybackSpeed) }
            if (!canMutate()) return false
        }
        return true
    }

    private suspend fun dispatch(onDispatched: ((Deferred<Unit>) -> Unit)?, command: suspend () -> Unit) {
        val done = CompletableDeferred<Unit>()
        onDispatched?.invoke(done)
        try {
            command()
        } finally {
            done.complete(Unit)
        }
    }

    companion object {
        private const val TAG = "TrackSelector"
        private val TRACK_LOAD_TIMEOUT = 10.seconds

        /**
         * Whether [trackLanguage] is in [preferredLanguage]: case-insensitive, regions ignored (`en-US` is `en`), across
         * ISO 639-1 and 639-2 codes; never by prefix (`est` is not `es`). Null never matches.
         */
        fun languageMatches(trackLanguage: String?, preferredLanguage: String?): Boolean =
            languagesMatch(trackLanguage, preferredLanguage)
    }
}
