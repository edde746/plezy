package com.edde746.plezy.model

import com.edde746.plezy.playback.ChapterMarkerClassifier
import com.edde746.plezy.playback.SkipKind
import com.edde746.plezy.playback.SkipSegments
import com.edde746.plezy.strings.T
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/**
 * What playback of one item opens: the stream URL, its tracks and chapters, and the selected version's identity.
 * The playback pipeline rewrites only the track lists after construction (`copy(audioTracks = …)`); every other field
 * survives those rewrites.
 */
data class MediaSourceInfo(
    val videoUrl: String,
    val audioTracks: List<MediaAudioTrack>,
    val subtitleTracks: List<MediaSubtitleTrack>,
    val chapters: List<MediaChapter>,
    val partId: Int? = null,
    val displayCriteria: MediaDisplayCriteria? = null,
    /**
     * Backend-opaque source id for the selected version. Plex uses the authoritative [MediaVersion.id]; Jellyfin uses
     * the selected `MediaSources` id.
     */
    val mediaSourceId: String? = null,
    /** Effective version position after backend selection and fallback. */
    val mediaIndex: Int? = null,
    /** Effective part position after backend selection and fallback. */
    val partIndex: Int? = null,
    /** Non-null when the selected version is stacked across several files: where the open file ([partIndex]) sits. */
    val partTimeline: MediaPartTimeline? = null,
    /** Jellyfin's default audio stream index for this source. */
    val defaultAudioStreamIndex: Int? = null,
    /** Jellyfin's default subtitle stream index; -1 is an explicit server/user decision to start with subtitles off. */
    val defaultSubtitleStreamIndex: Int? = null,
    /**
     * Jellyfin trickplay manifest for the selected source, keyed by tile width. Null when the server didn't run
     * trickplay extraction. Plex leaves it null and uses [partId] with the BIF service instead.
     */
    val trickplayByWidth: Map<Int, TrickplayInfo>? = null,
    /** Display aspect ratio of the video stream (width / height). */
    val videoAspectRatio: Double? = null,
)

/** Per-resolution Jellyfin trickplay manifest, as Jellyfin's `TrickplayInfoDto`. */
data class TrickplayInfo(
    val width: Int,
    val height: Int,
    val tileWidth: Int,
    val tileHeight: Int,
    val thumbnailCount: Int,
    val interval: Int,
    val bandwidth: Int,
)

/** The zero-based position a track's fallback label numbers: its stream index (else id) minus one, floored at 0. */
private fun fallbackLabelIndex(index: Int?, id: Int): Int {
    val streamIndex = index ?: id
    return if (streamIndex > 0) streamIndex - 1 else 0
}

data class MediaAudioTrack(
    val id: Int,
    val index: Int? = null,
    val codec: String? = null,
    val language: String? = null,
    val languageCode: String? = null,
    val title: String? = null,
    val displayTitle: String? = null,
    val channels: Int? = null,
    val selected: Boolean,
    /** Container fallback, independent of the server/user-selected row. */
    val isDefault: Boolean = false,
    val external: Boolean = false,
) {
    val isExternal: Boolean get() = external

    fun withSelected(selected: Boolean): MediaAudioTrack = copy(selected = selected)

    val label: TrackLabel
        get() = TrackLabelBuilder.audioLabel(
            title = title,
            language = language,
            languageCode = languageCode,
            codec = codec,
            channels = channels,
            displayTitle = displayTitle,
            index = fallbackLabelIndex(index, id),
        )
}

data class MediaSubtitleTrack(
    val id: Int,
    val index: Int? = null,
    val codec: String? = null,
    val language: String? = null,
    val languageCode: String? = null,
    val title: String? = null,
    val displayTitle: String? = null,
    val selected: Boolean,
    val forced: Boolean,
    val key: String? = null,
    val external: Boolean = false,
    val usesExternalDelivery: Boolean = false,
) {
    val label: TrackLabel get() = labelForIndex(fallbackLabelIndex(index, id))

    fun labelForIndex(visibleIndex: Int): TrackLabel = TrackLabelBuilder.subtitleLabel(
        title = title,
        language = language,
        languageCode = languageCode,
        codec = codec,
        forced = forced,
        displayTitle = displayTitle,
        index = visibleIndex,
    )

    /** Whether this track is an external file (sidecar subtitle). */
    val isExternalFile: Boolean get() = external

    val isExternal: Boolean get() = external || usesExternalDelivery || !key.isNullOrEmpty()

    fun withSelected(selected: Boolean): MediaSubtitleTrack = copy(selected = selected)

    /**
     * Without the sidecar identity fields ([key] and [usesExternalDelivery]). Whether a row has sidecar identity is a
     * per-playback fact only the backend layer can establish; this applies that decision. [external] is left for the
     * caller to interpret.
     */
    fun withoutSidecarIdentity(): MediaSubtitleTrack =
        if (key == null && !usesExternalDelivery) this else copy(key = null, usesExternalDelivery = false)
}

data class MediaChapter(
    val id: Int,
    val index: Int? = null,
    val startTimeOffset: Long? = null,
    val endTimeOffset: Long? = null,
    val title: String? = null,
    val thumb: String? = null,
) {
    /** The title, else "Chapter N" from the zero-based [index]. */
    val label: String get() = title ?: T.common.chapterNumber(((index ?: 0) + 1).toString())

    val startTime: Duration get() = (startTimeOffset ?: 0L).milliseconds
    val endTime: Duration? get() = endTimeOffset?.milliseconds

    companion object {
        /**
         * Fills each missing [endTimeOffset] from the next chapter's start, and the last one's from [runtimeMs] when
         * that is past its start (Jellyfin sends only starts; seek-bar ticks need ranges). Rewrites [chapters] in place
         * and returns it.
         */
        fun backfillEndOffsets(chapters: MutableList<MediaChapter>, runtimeMs: Long? = null): MutableList<MediaChapter> {
            for (i in 0 until chapters.size - 1) {
                val c = chapters[i]
                if (c.endTimeOffset != null) continue
                chapters[i] = c.copy(endTimeOffset = chapters[i + 1].startTimeOffset)
            }
            if (runtimeMs != null && chapters.isNotEmpty()) {
                val last = chapters.last()
                val start = last.startTimeOffset
                if (last.endTimeOffset == null && start != null && runtimeMs > start) {
                    chapters[chapters.lastIndex] = last.copy(endTimeOffset = runtimeMs)
                }
            }
            return chapters
        }

        /**
         * The index of the chapter containing [position] (start-inclusive, end-exclusive), or null. A missing end is
         * the next chapter's start; the final chapter without an end runs on forever.
         */
        fun indexAtPosition(position: Duration, chapters: List<MediaChapter>): Int? {
            val positionMs = position.inWholeMilliseconds
            for (i in chapters.indices) {
                val chapter = chapters[i]
                val startMs = chapter.startTimeOffset ?: 0L
                val endMs = chapter.endTimeOffset
                    ?: if (i < chapters.size - 1) chapters[i + 1].startTimeOffset ?: 0L else Long.MAX_VALUE
                if (positionMs in startMs until endMs) return i
            }
            return null
        }

        /**
         * The chapter next/previous traversal lands on. Forward: the first chapter starting strictly after [position].
         * Backward: the last chapter [position] is more than [previousRestartThreshold] into, so a press early in a
         * chapter goes to the one before it.
         */
        fun seekTargetIndex(
            position: Duration,
            chapters: List<MediaChapter>,
            forward: Boolean,
            previousRestartThreshold: Duration = 3.seconds,
        ): Int? {
            val positionMs = position.inWholeMilliseconds
            if (forward) return chapters.indexOfFirst { (it.startTimeOffset ?: 0L) > positionMs }.takeIf { it >= 0 }
            val thresholdMs = previousRestartThreshold.inWholeMilliseconds
            return chapters.indexOfLast { positionMs > (it.startTimeOffset ?: 0L) + thresholdMs }.takeIf { it >= 0 }
        }
    }
}

data class MediaMarker(val id: Int, val type: String, val startTimeOffset: Long, val endTimeOffset: Long) {
    val startTime: Duration get() = startTimeOffset.milliseconds
    val endTime: Duration get() = endTimeOffset.milliseconds

    val isCredits: Boolean get() = type == CREDITS

    /** Start-inclusive, end-exclusive. */
    fun containsPosition(position: Duration): Boolean = position.inWholeMilliseconds.let { it >= startTimeOffset && it < endTimeOffset }

    companion object {
        const val INTRO = "intro"
        const val CREDITS = "credits"
    }
}

/** An item's chapters and skip markers, fetched together. */
data class PlaybackExtras(val chapters: List<MediaChapter>, val markers: List<MediaMarker>) {
    /** Whether any marker is a credits marker (detected or chapter-derived). */
    val hasCreditsMarkers: Boolean get() = markers.any { it.isCredits }

    /** Without its credits markers: the server admin disabled credits detection for the item's show or movie. */
    fun withoutCreditsMarkers(): PlaybackExtras = copy(markers = markers.filterNot { it.isCredits })

    companion object {
        /**
         * Built-in chapter-title patterns. They classify server markers with non-standard type strings; chapter titles
         * are classified by [ChapterMarkerClassifier] unless the user replaced a pattern.
         */
        const val DEFAULT_INTRO_PATTERN = """(?:^|\b)(?:intro(?:duction)?|opening)(?:\b|$)|^op(?:\s?\d+)?$"""
        const val DEFAULT_CREDITS_PATTERN = """(?:^|\b)(?:outro|credits?|ending)(?:\b|$)|^ed(?:\s?\d+)?$"""

        /**
         * Longest chapter that may become a chapter-derived intro marker; a movie's "Opening Credits" can run 5–10
         * minutes of picture. Applies to chapters matched by a custom pattern too, never to server-supplied markers,
         * and never to credits, which are legitimately long on movies.
         */
        val maxChapterIntroDuration: Duration = ChapterMarkerClassifier.MAX_INTRO_MS.milliseconds

        /**
         * Earliest start, as a fraction of the runtime, for a chapter-derived credits marker. Credits words also title
         * chapters inside the film (The Shining's "Closing Day" starts 12% in); end credits, an anime ED, and credits
         * split by a post-credits scene all start in the final quarter. Applies only to markers minted from chapters.
         * The furthest chapter offset stands in for the runtime.
         */
        const val MIN_CHAPTER_CREDITS_START_FRACTION = 0.75

        /**
         * Real markers, with missing types filled from the chapters: [classifier]'s intro and credits picks or, for a
         * type whose pattern the user replaced ([introPattern], [creditsPattern]), the chapters whose titles match it.
         * Where the classifier picks no chapter of a type, the chapters whose whole title names it ([SkipSegments.kindOf]:
         * "Intro", "Opening", "Credits") are that type, as the player's own chapter segments are, so a short episode's
         * "Intro" the model takes for content still offers its skip. [forceChapterFallback] prefers chapter-derived
         * markers for any type they provide. Server markers with unknown types are reclassified against the patterns.
         * Chapter-derived intros longer than [maxChapterIntroDuration] and chapter-derived credits starting before
         * [MIN_CHAPTER_CREDITS_START_FRACTION] of the runtime are dropped; a chapter claimed as the intro is never
         * credits, even when dropped for its length.
         */
        internal fun withChapterFallback(
            chapters: List<MediaChapter>,
            markers: List<MediaMarker>,
            classifier: ChapterMarkerClassifier,
            introPattern: String? = null,
            creditsPattern: String? = null,
            forceChapterFallback: Boolean = false,
        ): PlaybackExtras {
            val customIntro = customPattern(introPattern, DEFAULT_INTRO_PATTERN)
            val customCredits = customPattern(creditsPattern, DEFAULT_CREDITS_PATTERN)
            val intro = customIntro ?: Regex(DEFAULT_INTRO_PATTERN, RegexOption.IGNORE_CASE)
            val credits = customCredits ?: Regex(DEFAULT_CREDITS_PATTERN, RegexOption.IGNORE_CASE)

            val runtimeMs = chapters.fold(0L) { furthest, ch -> maxOf(furthest, ch.endTimeOffset ?: ch.startTimeOffset ?: 0L) }
            val minCreditsStartMs = runtimeMs * MIN_CHAPTER_CREDITS_START_FRACTION

            // Chapters with a usable span; a missing end is the next chapter's start.
            val spanned = ArrayList<Pair<MediaChapter, ChapterMarkerClassifier.Span>>()
            chapters.forEachIndexed { i, ch ->
                val start = ch.startTimeOffset ?: return@forEachIndexed
                val end = ch.endTimeOffset ?: chapters.getOrNull(i + 1)?.startTimeOffset ?: return@forEachIndexed
                if (end < start) return@forEachIndexed
                spanned += ch to ChapterMarkerClassifier.Span(ch.title, start, end)
            }
            val picks = if (customIntro != null && customCredits != null) null else classifier.pick(spanned.map { it.second })

            val synthetic = ArrayList<MediaMarker>()
            spanned.forEachIndexed { i, (ch, span) ->
                val title = ch.title
                fun matches(pattern: Regex) = !title.isNullOrEmpty() && pattern.containsMatchIn(title)
                val isIntro = if (customIntro != null) matches(customIntro) else picks!!.intro?.let { it == i } ?: (SkipSegments.kindOf(title) == SkipKind.INTRO)
                val isCredits = if (customCredits != null) matches(customCredits) else picks!!.credits?.let { it == i } ?: (SkipSegments.kindOf(title) == SkipKind.CREDITS)
                val type = when {
                    isIntro -> {
                        if (span.endMs - span.startMs > maxChapterIntroDuration.inWholeMilliseconds) return@forEachIndexed
                        MediaMarker.INTRO
                    }
                    isCredits -> {
                        if (span.startMs < minCreditsStartMs) return@forEachIndexed
                        MediaMarker.CREDITS
                    }
                    else -> return@forEachIndexed
                }
                synthetic += MediaMarker(id = ch.id, type = type, startTimeOffset = span.startMs, endTimeOffset = span.endMs)
            }

            if (markers.isEmpty()) return PlaybackExtras(chapters, synthetic)

            val reclassified = markers.map { m ->
                if (m.type == MediaMarker.INTRO || m.type == MediaMarker.CREDITS) return@map m
                when {
                    intro.containsMatchIn(m.type) -> m.copy(type = MediaMarker.INTRO)
                    credits.containsMatchIn(m.type) -> m.copy(type = MediaMarker.CREDITS)
                    else -> m
                }
            }
            if (synthetic.isEmpty()) return PlaybackExtras(chapters, reclassified)

            val syntheticTypes = synthetic.mapTo(HashSet()) { it.type }
            val nativeTypes = reclassified.mapTo(HashSet()) { it.type }
            val merged = if (forceChapterFallback) {
                reclassified.filter { it.type !in syntheticTypes } + synthetic
            } else {
                reclassified + synthetic.filter { it.type !in nativeTypes }
            }
            return PlaybackExtras(chapters, merged.sortedBy { it.startTimeOffset })
        }

        /**
         * The user's own [pattern], or null when it is unset, blank, or [defaultPattern]: a blank stored pattern would
         * match every chapter title.
         */
        private fun customPattern(pattern: String?, defaultPattern: String): Regex? =
            if (pattern.isNullOrBlank() || pattern == defaultPattern) null else Regex(pattern, RegexOption.IGNORE_CASE)
    }
}
