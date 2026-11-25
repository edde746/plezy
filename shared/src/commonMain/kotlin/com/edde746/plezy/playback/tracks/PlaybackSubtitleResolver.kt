package com.edde746.plezy.playback.tracks

import com.edde746.plezy.backend.PlaybackSubtitleSidecar
import com.edde746.plezy.backend.SubtitleSidecar
import com.edde746.plezy.model.MediaAudioTrack
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaServerUserProfile
import com.edde746.plezy.model.MediaSourceInfo
import com.edde746.plezy.model.MediaSubtitleTrack
import com.edde746.plezy.model.effectiveForced

/** A subtitle choice among the source's rows: off, or the server stream [Source.id] (0 is a real id on Jellyfin). */
sealed interface SourceSubtitleChoice {
    data object Off : SourceSubtitleChoice

    data class Source(val id: Int) : SourceSubtitleChoice
}

/**
 * The subtitles one player open starts with. The source ids stay stable across reloads; [primaryTrack] and
 * [secondaryTrack] carry the metadata that selects the player's tracks once it listed them.
 *
 * @param declinedPreference the primary preference the resolver could not serve when this selection is off: the open
 *   hands it to the track manager so tracks arriving late may still serve it, and progress reports must not persist
 *   the fallout as an explicit off. Null for a deliberate off.
 * @param primaryHonorsPreference [primaryTrack] is the caller's own choice rather than the source's selected row: only
 *   the caller's choice may be written back to the server.
 */
data class PlaybackSubtitleSelection(
    val primaryTrack: NativeSubtitleTrack,
    val primarySourceStreamId: Int? = null,
    val primarySidecar: PlaybackSubtitleSidecar? = null,
    val secondaryTrack: NativeSubtitleTrack? = null,
    val secondarySourceStreamId: Int? = null,
    val secondarySidecar: PlaybackSubtitleSidecar? = null,
    val preloadedSidecars: List<PlaybackSubtitleSidecar> = emptyList(),
    val declinedPreference: PreferredSubtitle? = null,
    val primaryHonorsPreference: Boolean = false,
) {
    val isOff: Boolean get() = primaryTrack.id == NativeSubtitleTrack.OFF.id

    /** The files the player attaches at open, selected or not: the preloaded ones, the primary's, the second's; once each. */
    val sidecarsAtOpen: List<SubtitleSidecar>
        get() = (preloadedSidecars.map { it.track } + listOfNotNull(primarySidecar?.track, secondarySidecar?.track)).distinct()

    companion object {
        fun off(
            preloadedSidecars: List<PlaybackSubtitleSidecar> = emptyList(),
            declinedPreference: PreferredSubtitle? = null,
            primaryHonorsPreference: Boolean = false,
        ) = PlaybackSubtitleSelection(
            primaryTrack = NativeSubtitleTrack.OFF,
            preloadedSidecars = preloadedSidecars,
            declinedPreference = declinedPreference,
            primaryHonorsPreference = primaryHonorsPreference,
        )
    }
}

/** Resolves the server's subtitle catalog before the player opens, with the sidecars marked for preloading. */
object PlaybackSubtitleResolver {
    private data class Candidate(val track: NativeSubtitleTrack, val sourceStreamId: Int?, val sidecar: PlaybackSubtitleSidecar?)

    /** [preferred] as a reference into [candidates] where one serves it; a declined intent stays as it is. */
    private fun sourceBackedPreference(
        preferred: PreferredSubtitle?,
        mediaInfo: MediaSourceInfo?,
        candidates: List<Candidate>,
        preserveSourceIdentity: Boolean,
    ): PreferredSubtitle? {
        val rows = mediaInfo?.subtitleTracks.orEmpty()
        fun resolveIntent(preference: PreferredSubtitle.Intent): PreferredSubtitle {
            val row = findSourceTrackForIntent(preference.intent, rows) ?: return preference
            return candidates.firstOrNull { it.sourceStreamId == row.id }?.let { PreferredSubtitle.Native(it.track) } ?: preference
        }

        // Crossing an item or source boundary strips identity from every reference.
        val pref = if (preserveSourceIdentity) preferred else PreferredSubtitle.demoteToIntent(preferred)
        return when (pref) {
            null, PreferredSubtitle.Off -> pref
            is PreferredSubtitle.Intent -> resolveIntent(pref)
            is PreferredSubtitle.Native -> {
                val track = pref.track
                if (track.id.startsWith("source:")) {
                    val id = sourceStreamIdOf(track.id)
                    candidates.firstOrNull { it.sourceStreamId == id }?.let { return PreferredSubtitle.Native(it.track) }
                    // The row left this source: only its semantics carry forward, hard-gated.
                    val demoted = PreferredSubtitle.demoteToIntent(pref)
                    return if (demoted is PreferredSubtitle.Intent) resolveIntent(demoted) else demoted
                }
                // A raw player or URI reference of this item: back it by this item's own row where one is it.
                val row = findSourceTrackForNativeSubtitle(track, rows)
                row?.let { r -> candidates.firstOrNull { it.sourceStreamId == r.id } }?.let { PreferredSubtitle.Native(it.track) } ?: pref
            }
        }
    }

    /**
     * The subtitles to open [metadata] with. Candidates are every source row as a `source:<id>` track (with its sidecar
     * when one serves it), then the sidecars no row claims (offline copies without cached rows). The ladder runs
     * against the source's own audio rows. [preserveSourceIdentity] false (another item) demotes every reference to its
     * intent. While [isTranscoding], a second subtitle without a sidecar file has no route and is dropped.
     */
    fun resolve(
        metadata: MediaItem,
        mediaInfo: MediaSourceInfo?,
        sidecars: List<PlaybackSubtitleSidecar>,
        profile: MediaServerUserProfile? = null,
        preferredAudioTrack: NativeAudioTrack? = null,
        preferredSubtitle: PreferredSubtitle? = null,
        preferredSecondarySubtitle: PreferredSubtitle? = null,
        preserveSourceIdentity: Boolean = true,
        isTranscoding: Boolean = false,
    ): PlaybackSubtitleSelection {
        val candidates = mutableListOf<Candidate>()
        val matched = mutableSetOf<PlaybackSubtitleSidecar>()
        for (row in mediaInfo?.subtitleTracks.orEmpty()) {
            val sidecar = sidecars.firstOrNull { it.sourceStreamId == row.id }
            if (sidecar != null) matched += sidecar
            candidates += Candidate(subtitleTrackForSource(row, sidecar), row.id, sidecar)
        }
        for (sidecar in sidecars) {
            if (sidecar !in matched) candidates += Candidate(sidecar.track.toNativeTrack(), sidecar.sourceStreamId, sidecar)
        }

        val preloaded = sidecars.filter { it.preload }
        val available = candidates.map { it.track }
        val selector = TrackSelector(metadata.backend, mediaInfo, profile)
        val audio = selector.selectAudioTrack(audioTracksForSource(mediaInfo), preferredAudioTrack)?.track
        val primaryPreference = sourceBackedPreference(preferredSubtitle, mediaInfo, candidates, preserveSourceIdentity)
        val primaryResult = selector.selectSubtitleTrack(available, primaryPreference, audio)
        val primary = primaryResult?.track
        val honors = primaryResult?.priority == TrackSelectionPriority.NAVIGATION
        val declined = primaryPreference?.takeIf { it != PreferredSubtitle.Off }
        if (primary == null || primary.id == NativeSubtitleTrack.OFF.id) {
            return PlaybackSubtitleSelection.off(preloaded, declined, honors)
        }
        val primaryCandidate = candidates.firstOrNull { it.track.id == primary.id }
            ?: return PlaybackSubtitleSelection.off(preloaded, declined, honors)

        var secondaryCandidate: Candidate? = null
        val secondaryPreference = sourceBackedPreference(preferredSecondarySubtitle, mediaInfo, candidates, preserveSourceIdentity)
        if (secondaryPreference != null && secondaryPreference != PreferredSubtitle.Off) {
            val secondary = when (secondaryPreference) {
                PreferredSubtitle.Off -> null
                is PreferredSubtitle.Native -> selector.findBestSubtitleMatch(available, secondaryPreference.track)
                is PreferredSubtitle.Intent -> findNativeTrackForIntent(secondaryPreference.intent, available)
            }
            secondaryCandidate = candidates.firstOrNull { it.track.id == secondary?.id && it.track.id != primary.id }
            // A transcode carries only the burned primary: an embedded second subtitle could never arrive.
            if (isTranscoding && secondaryCandidate?.sidecar == null) secondaryCandidate = null
        }

        return PlaybackSubtitleSelection(
            primaryTrack = primaryCandidate.track,
            primarySourceStreamId = primaryCandidate.sourceStreamId,
            primarySidecar = primaryCandidate.sidecar,
            secondaryTrack = secondaryCandidate?.track,
            secondarySourceStreamId = secondaryCandidate?.sourceStreamId,
            secondarySidecar = secondaryCandidate?.sidecar,
            preloadedSidecars = preloaded,
            primaryHonorsPreference = honors,
        )
    }

    /**
     * Whether a subtitle change must go back to the server instead of to the running player; only ever on a transcode.
     * Something burned in now (a source row without a sidecar) needs a new negotiation whatever the target, since
     * burned pixels are no track to hide; and a target that is neither off nor an external file can only be burned in.
     */
    fun burnRequiresRenegotiation(
        isTranscoding: Boolean,
        currentSourceStreamId: Int?,
        currentSelectionHasSidecar: Boolean,
        targetIsOff: Boolean,
        targetIsExternalFile: Boolean,
    ): Boolean {
        if (!isTranscoding) return false
        if (currentSourceStreamId != null && !currentSelectionHasSidecar) return true
        return !targetIsOff && !targetIsExternalFile
    }

    /** The stable reference of the viewer's pick of row [sourceStreamId], without a sidecar URL that may go stale. */
    fun preferredTrackForSource(mediaInfo: MediaSourceInfo?, sourceStreamId: Int): NativeSubtitleTrack? =
        mediaInfo?.subtitleTracks?.firstOrNull { it.id == sourceStreamId }?.let { subtitleTrackForSource(it) }

    /**
     * Row [source] as a `source:<id>` track, with [sidecar]'s file when one serves it. The row's own title comes
     * first: display titles collapse to the bare language and can't tell a Signs track from the full one.
     */
    fun subtitleTrackForSource(source: MediaSubtitleTrack, sidecar: PlaybackSubtitleSidecar? = null): NativeSubtitleTrack {
        val playable = sidecar?.track
        return NativeSubtitleTrack(
            id = sourceTrackId(source.id),
            title = source.title ?: playable?.title ?: source.displayTitle ?: source.language,
            language = playable?.language ?: source.languageCode ?: source.language,
            codec = playable?.codec ?: source.codec,
            isDefault = source.selected,
            isForced = source.effectiveForced,
            isExternal = playable != null,
            uri = playable?.url,
        )
    }

    /**
     * The player track for row [source]. A resolved sidecar matches a container track by container position, else the
     * external track whose URI holds the row's key, else the selected external track when the row is the current
     * choice. Rows without a sidecar match by metadata.
     */
    fun nativeTrackForSource(
        source: MediaSubtitleTrack,
        nativeTracks: List<NativeSubtitleTrack>,
        allSourceTracks: List<MediaSubtitleTrack>,
        isResolvedSidecar: Boolean,
        isContainerSidecar: Boolean,
        currentSourceStreamId: Int? = null,
        selectedNativeTrack: NativeSubtitleTrack? = null,
    ): NativeSubtitleTrack? {
        if (!isResolvedSidecar) return findNativeTrackForSourceSubtitle(source, nativeTracks, allSourceTracks)
        if (isContainerSidecar) {
            return findNativeTrackForSourceSubtitle(source, nativeTracks.filter { it.isContainer }, allSourceTracks)
        }
        val key = source.key
        if (!key.isNullOrEmpty()) {
            nativeTracks.firstOrNull { it.isExternal && it.uri?.contains(key) == true }?.let { return it }
        }
        if (currentSourceStreamId == source.id &&
            selectedNativeTrack != null &&
            selectedNativeTrack.id != NativeSubtitleTrack.OFF.id &&
            selectedNativeTrack.isExternal
        ) {
            return selectedNativeTrack
        }
        return null
    }

    /** The choice [advances] steps after [current] in [off, each of the streams [ids]], wrapping; an unknown current is off. */
    fun advanceSourceChoice(ids: List<Int>, current: SourceSubtitleChoice, advances: Int): SourceSubtitleChoice {
        val choices = listOf(SourceSubtitleChoice.Off) + ids.map { SourceSubtitleChoice.Source(it) }
        val index = choices.indexOf(current).coerceAtLeast(0)
        return choices[(index + advances).mod(choices.size)]
    }

    /** Audio row [track] as a `source:<id>` track; its own title first, as [subtitleTrackForSource]. */
    fun audioTrackForSource(track: MediaAudioTrack): NativeAudioTrack = NativeAudioTrack(
        id = sourceTrackId(track.id),
        title = track.title ?: track.displayTitle ?: track.language,
        language = track.languageCode ?: track.language,
        codec = track.codec,
        channels = track.channels,
        isDefault = track.isDefault,
    )

    /** Every audio row of [mediaInfo] as [audioTrackForSource] makes it: what the ladder ranks before the player opens. */
    fun audioTracksForSource(mediaInfo: MediaSourceInfo?): List<NativeAudioTrack> = mediaInfo?.audioTracks.orEmpty().map(::audioTrackForSource)
}
