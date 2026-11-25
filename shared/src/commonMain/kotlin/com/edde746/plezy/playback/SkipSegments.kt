package com.edde746.plezy.playback

import kotlin.math.roundToLong

/** What a chapter is, by its title, for skipping ([SkipSegments]). */
enum class SkipKind { INTRO, RECAP, CREDITS, PREVIEW }

/**
 * A part of the video the player offers to skip: from [startSeconds] to [endSeconds].
 * @param toEnd credits that run to the end of the video (only previews follow them): skipping them ends the video,
 *   and with a next episode its prompt starts at [startSeconds].
 */
data class SkipSegment(val kind: SkipKind, val startSeconds: Double, val endSeconds: Double, val toEnd: Boolean = false) {
    val lengthSeconds: Double get() = endSeconds - startSeconds
}

/**
 * Intros, recaps and credits from the video's chapters (mpv's chapter list is the only source: there are no server
 * markers). A chapter ends where the next starts, the last at the duration.
 *
 * - Intros and credits: [ChapterMarkerClassifier] picks at most one chapter of each from the titles and times of the
 *   whole list, so an episode whose chapters are all "Chapter N" or untitled has them too, a cold open titled "Intro"
 *   before "OP" stays content, and names no list has ("Abertura", "Staff Roll") count. The chapters beside a pick that
 *   the model is as sure of, and those right after it whose titles say the same kind, join it. Where the model picks
 *   none of a kind, the titles decide it as they do recaps and previews.
 * - Recaps and previews, and a chapter titled as one whatever the model says: its whole title, normalised
 *   ([normalize]: trimmed, lower case, without a leading "Chapter 3 -" or "03." and a trailing number), matched
 *   against the names in [TITLES] and the prefixes in [PREFIXES]: never a word anywhere in it, so a movie's "The
 *   Ending" stays content.
 * - Adjacent chapters of the same kind make one segment.
 * - Credits followed only by previews run to the end ([SkipSegment.toEnd]), previews included, and so does a preview at
 *   the end without credits before it. Credits followed by more of the video (a post-credits scene) end where that
 *   starts; a preview anywhere else isn't skipped.
 * - Intros and recaps start in the first third of the video and last at most [MAX_OPENING_SECONDS] (a movie's long
 *   "Opening credits" are the film); credits start in its second half. Anything shorter than [MIN_SECONDS] is ignored.
 */
object SkipSegments {
    /** The cap on a chapter intro: 5–10 minute "Opening credits" in movies are content. */
    const val MAX_OPENING_SECONDS = 180.0

    const val MIN_SECONDS = 2.0

    /** The segments of a video with [chapters] and [durationSeconds], by start; none while the duration is unknown. */
    fun of(chapters: List<Chapter>, durationSeconds: Double): List<SkipSegment> {
        if (!(durationSeconds > 0) || chapters.isEmpty()) return emptyList()
        val starts = chapters
            .filter { it.startSeconds.isFinite() && it.startSeconds < durationSeconds }
            .sortedBy { it.startSeconds }
        // One part per chapter (its title and its span, kind by title), then the same kind's neighbours merged.
        val parts = starts.mapIndexedNotNull { index, chapter ->
            val start = chapter.startSeconds.coerceAtLeast(0.0)
            val end = starts.getOrNull(index + 1)?.startSeconds ?: durationSeconds
            if (end <= start) null else chapter.title to Span(kindOf(chapter.title), start, end)
        }
        val kinds = kinds(parts)
        val spans = mutableListOf<Span>()
        parts.forEachIndexed { index, (_, part) ->
            val kind = kinds[index]
            val last = spans.lastOrNull()
            if (last != null && kind != null && last.kind == kind) spans[spans.lastIndex] = last.copy(end = part.end) else spans += part.copy(kind = kind)
        }
        // Credits to the end: the last spans, credits or previews (a sliver too short to count is passed over).
        var first = spans.size
        while (first > 0) {
            val span = spans[first - 1]
            val skippable = span.kind == SkipKind.CREDITS || span.kind == SkipKind.PREVIEW
            if (!skippable && span.length >= MIN_SECONDS) break
            first -= 1
        }
        while (first < spans.size && spans[first].kind != SkipKind.CREDITS && spans[first].kind != SkipKind.PREVIEW) first += 1
        val segments = mutableListOf<SkipSegment>()
        spans.subList(0, first).forEach { span ->
            when (span.kind) {
                SkipKind.INTRO, SkipKind.RECAP ->
                    if (span.start < durationSeconds / 3 && span.length <= MAX_OPENING_SECONDS) segments += SkipSegment(span.kind, span.start, span.end)
                SkipKind.CREDITS -> if (span.start >= durationSeconds / 2) segments += SkipSegment(SkipKind.CREDITS, span.start, span.end)
                // Only skipped as part of the credits to the end.
                SkipKind.PREVIEW, null -> {}
            }
        }
        if (first < spans.size) {
            val start = spans[first].start
            if (start >= durationSeconds / 2) segments += SkipSegment(SkipKind.CREDITS, start, durationSeconds, toEnd = true)
        }
        return segments.filter { it.lengthSeconds >= MIN_SECONDS }
    }

    /**
     * Each part's kind: recaps and previews by its title; intros and credits by the model's picks, joined by the parts
     * beside a pick that it is as sure of and those right after it titled as the same kind, or by the titles where the
     * model picks none of that kind.
     */
    private fun kinds(parts: List<Pair<String?, Span>>): List<SkipKind?> {
        val picks = ChapterMarkerClassifier.bundled.pick(
            parts.map { (title, part) -> ChapterMarkerClassifier.Span(title, (part.start * 1000).roundToLong(), (part.end * 1000).roundToLong()) },
        )
        val titled = parts.map { it.second.kind }
        val kinds = titled.map { it.takeIf { kind -> kind == SkipKind.RECAP || kind == SkipKind.PREVIEW } }.toMutableList()
        fun mark(kind: SkipKind, pick: Int?, sure: (Int) -> Boolean) {
            if (pick == null || kinds[pick] != null) {
                titled.forEachIndexed { i, titledKind -> if (titledKind == kind && kinds[i] == null) kinds[i] = kind }
                return
            }
            kinds[pick] = kind
            var before = pick - 1
            while (before >= 0 && kinds[before] == null && sure(before)) kinds[before--] = kind
            var after = pick + 1
            while (after < parts.size && kinds[after] == null && (sure(after) || titled[after] == kind)) kinds[after++] = kind
        }
        mark(SkipKind.INTRO, picks.intro, picks::isIntro)
        mark(SkipKind.CREDITS, picks.credits, picks::isCredits)
        return kinds
    }

    /** Where the credits to the end start, if [segments] have them: the next episode's prompt starts there. */
    fun creditsStart(segments: List<SkipSegment>): Double? = segments.lastOrNull { it.toEnd }?.startSeconds

    /** The kind a chapter titled [title] is, or null for content (or no title). */
    fun kindOf(title: String?): SkipKind? {
        val name = normalize(title ?: return null)
        if (name.isEmpty()) return null
        TITLES[name]?.let { return it }
        return PREFIXES.firstOrNull { (prefix, _) -> name.startsWith(prefix) }?.second
    }

    /**
     * A title as [kindOf] matches it: trimmed and lower case, without a leading chapter number ("Chapter 3 -", "03.",
     * "2)"), a trailing number ("OP 2", "Opening1") or trailing punctuation ("Previously on…").
     */
    internal fun normalize(title: String): String {
        var name = title.trim().lowercase()
        name = LEADING_NUMBER.replace(name, "")
        name = TRAILING_PUNCTUATION.replace(name, "")
        name = TRAILING_NUMBER.replace(name, "")
        return WHITESPACE.replace(name.trim(), " ")
    }

    /**
     * The whole titles of each kind, normalised, names common on anime and Blu-ray releases among them
     * (BDMV "Main titles"/"End titles", fansub "OP"/"ED"/"Preview", Japanese releases' オープニング/エンディング/予告).
     */
    internal val TITLES: Map<String, SkipKind> = buildMap {
        listOf(
            "intro", "introduction", "opening", "opening credits", "opening titles", "opening title", "opening song",
            "opening theme", "opening sequence", "title sequence", "main titles", "main title", "theme song",
            "intro song", "op", "オープニング",
        ).forEach { put(it, SkipKind.INTRO) }
        listOf(
            "recap", "previously", "previously on", "last time", "last time on", "story so far", "the story so far",
            "前回", "前回のあらすじ", "あらすじ",
        ).forEach { put(it, SkipKind.RECAP) }
        listOf(
            "credits", "credit", "end credits", "end credit", "ending credits", "closing credits", "closing",
            "end titles", "end title", "ending", "ending song", "ending theme", "outro", "ed", "エンディング",
        ).forEach { put(it, SkipKind.CREDITS) }
        listOf(
            "preview", "next episode", "next episode preview", "episode preview", "next time", "next time on",
            "予告", "次回予告",
        ).forEach { put(it, SkipKind.PREVIEW) }
    }

    /** Titles that go on with the show's name: "Previously on Breaking Bad", "Next time on Bleach". */
    internal val PREFIXES: List<Pair<String, SkipKind>> = listOf(
        "previously on " to SkipKind.RECAP,
        "last time on " to SkipKind.RECAP,
        "next time on " to SkipKind.PREVIEW,
    )

    private val LEADING_NUMBER = Regex("""^(?:(?:chapter|chap\.?|ch\.?)\s*)?\d+\s*(?:[-–—.:)]\s*|\s+)""")
    private val TRAILING_NUMBER = Regex("""\s*\d+$""")
    private val TRAILING_PUNCTUATION = Regex("""[\s.…:!\-–—]+$""")
    private val WHITESPACE = Regex("""\s+""")

    private data class Span(val kind: SkipKind?, val start: Double, val end: Double) {
        val length: Double get() = end - start
    }
}
