package com.edde746.plezy.playback.session

import com.edde746.plezy.lang.LanguageTags
import com.edde746.plezy.lang.localizedLanguageName
import com.edde746.plezy.playback.Track
import com.edde746.plezy.playback.TrackKind

/**
 * Picks audio and subtitle tracks by the profile's language preferences and the system's caption and
 * audio-description settings ([com.edde746.plezy.playback.MediaAccessibilityPreferences]). Preferences are canonical
 * BCP 47 tags ([LanguageTags]), most preferred first; a track matches a preference by language, and one with the
 * preferred region or script too wins over one without.
 *
 * Audio: the best track in the most preferred language the file has. Among equal matches: an audio description first
 * when the system asks for them and last otherwise, then not a commentary, then the default track, then file order.
 * None preferred or none present keeps the file's own choice, put right for audio descriptions: the audio description
 * in its language when the system asks for them, the plain track in its language when it plays one nobody asked for.
 *
 * Subtitles follow the audio, the way Plex's "shown with foreign audio" and Jellyfin's "smart" modes do:
 * - audio in a language the user doesn't read subtitles in (no preferred subtitle language matches it), or of
 *   unknown language, gets full subtitles in the most preferred language available (not forced, embedded before
 *   external, default first), else forced ones in a preferred language;
 * - audio in a preferred subtitle language, or no subtitle preference at all, gets only forced subtitles in the
 *   audio's language (they translate the parts in yet another language), else subtitles off.
 *
 * SDH ranks after plain subtitles, unless captions are on (the profile's Show subtitles is Always, or the system's
 * captions are: Closed Captions + SDH, Android's captions): then SDH ranks first, and the second case gets full
 * subtitles in the audio's language, else in the most preferred language available, and its forced ones only when
 * there are none.
 *
 * A track the user picked in another file of the show is matched first ([carried]). The second subtitle, shown at the
 * top of the picture, is the best full subtitle in its one language ([second]).
 */
internal object TrackChooser {
    /**
     * The audio track to select, or null to keep the engine's. [descriptions]: the system asks for audio descriptions.
     */
    fun audio(tracks: List<Track>, preferred: List<String>, descriptions: Boolean): Track? {
        val audio = tracks.filter { it.kind == TrackKind.AUDIO }
        best(audio, preferred, if (descriptions) describedFirst else describedLast)?.let { return it }
        val own = audio.firstOrNull { it.selected } ?: return null
        if (own.isDescriptive() == descriptions) return null
        val language = LanguageTags.canonical(own.language) ?: return null
        return best(audio.filter { it.isDescriptive() == descriptions }, listOf(language), audioOrder)
    }

    /**
     * The subtitle track to select, or null for subtitles off. [audioLanguage] is the selected audio track's;
     * [captions]: the profile shows subtitles always or the system's captions are on.
     */
    fun subtitle(tracks: List<Track>, audioLanguage: String?, preferred: List<String>, captions: Boolean): Track? {
        val subtitles = tracks.filter { it.kind == TrackKind.SUBTITLE }
        val (forced, full) = subtitles.partition { it.isForced() }
        val audio = LanguageTags.canonical(audioLanguage)
        val understood = audio != null && preferred.any { LanguageTags.match(it, audio) > 0 }
        val order = if (captions) captionOrder else subtitleOrder
        if (preferred.isNotEmpty() && !understood) {
            return best(full, preferred, order) ?: best(forced, preferred, order)
        }
        if (audio == null) return null
        if (captions) {
            // The audio's language as a preference names it (with its region or script) first, then the others.
            val languages = preferred.filter { LanguageTags.match(it, audio) > 0 } + audio + preferred
            best(full, languages.distinct(), order)?.let { return it }
        }
        return best(forced, listOf(audio), order)
    }

    /**
     * The second subtitle: the best full (not forced) subtitle track of [tracks] in [language], as the first is ranked
     * ([captions]: SDH first); null with no language, or none in it. [tracks] leaves out the first subtitle's track.
     */
    fun second(tracks: List<Track>, language: String?, captions: Boolean): Track? {
        language ?: return null
        val full = tracks.filter { it.kind == TrackKind.SUBTITLE && !it.isForced() }
        return best(full, listOf(language), if (captions) captionOrder else subtitleOrder)
    }

    /**
     * Which of the external subtitles in [languages] (a player app's, in the order they're handed over) shows at
     * start, as an index: the first in the most preferred language any of them has, one with the preferred region or
     * script winning over one without; null with no preferred language or none matching (subtitles off).
     */
    fun external(languages: List<String?>, preferred: List<String>): Int? {
        val tagged = languages.mapIndexedNotNull { index, language -> LanguageTags.canonical(language)?.let { index to it } }
        for (wanted in preferred) {
            val best = tagged.map { (index, tag) -> index to LanguageTags.match(wanted, tag) }.filter { it.second > 0 }
                .maxWithOrNull(compareBy<Pair<Int, Int>> { it.second }.thenByDescending { it.first }) ?: continue
            return best.first
        }
        return null
    }

    /**
     * The track of [tracks] that stands for [picked], the user's pick in another file of the title or in this one before
     * it loaded again ([TrackCarry]): the best match, never refused for one attribute
     * that differs; null only when no track is in the picked one's language.
     * - The very track first: one with the picked one's id and everything else alike.
     * - Only tracks in the picked one's language stand for it. A track's language is its tag in any form (`eng`, `en`,
     *   `en-US` alike: [LanguageTags]), else the one its title names ("English [SDH]", "Français"). A track of no known
     *   language stands for a pick of none, and either way for one whose title its own names.
     * - The best of those by, in order: the same kind for subtitles (forced or full: the flag, or "forced" in the
     *   title), the closer language (the same region or script first), the same SDH standing for subtitles or the same
     *   commentary and audio-description standing for audio, the title (one naming the picked one's; none to name counts
     *   a little), the same codec, and the same source for subtitles (embedded or added) or the same channel count for
     *   audio.
     * - Among tracks equal on all of that: the default one, then the first. A tie isn't declined: the fallback would be
     *   the language preferences, which turn subtitles off under audio the user understands, so a tie keeps the picked
     *   language instead.
     */
    fun carried(tracks: List<Track>, picked: Track): Track? {
        val candidates = tracks.filter { it.kind == picked.kind }
        val same = picked.copy(selected = false, secondary = false)
        candidates.firstOrNull { it.copy(selected = false, secondary = false) == same }?.let { return it }
        val subtitle = picked.kind == TrackKind.SUBTITLE
        val language = picked.languageTag()
        return candidates.mapNotNull { candidate ->
            val title = titleScore(picked.title, candidate.title)
            val tag = candidate.languageTag()
            val closeness = when {
                language != null && tag != null -> LanguageTags.match(language, tag).takeIf { it > 0 } ?: return@mapNotNull null
                title == TITLE_NAMED || (language == null && tag == null) -> 0
                else -> return@mapNotNull null
            }
            Evidence(
                track = candidate,
                kind = !subtitle || candidate.isForced() == picked.isForced(),
                closeness = closeness,
                standing = if (subtitle) {
                    candidate.isSdh() == picked.isSdh()
                } else {
                    candidate.isCommentary() == picked.isCommentary() && candidate.isDescriptive() == picked.isDescriptive()
                },
                title = title,
                codec = picked.codec != null && picked.codec.equals(candidate.codec, ignoreCase = true),
                source = if (subtitle) candidate.external == picked.external else picked.channels != null && candidate.channels == picked.channels,
            )
        }.sortedWith(evidenceOrder).firstOrNull()?.track
    }

    private class Evidence(
        val track: Track,
        val kind: Boolean,
        val closeness: Int,
        val standing: Boolean,
        val title: Int,
        val codec: Boolean,
        val source: Boolean,
    )

    private val evidenceOrder: Comparator<Evidence> = compareByDescending<Evidence> { it.kind }
        .thenByDescending { it.closeness }
        .thenByDescending { it.standing }
        .thenByDescending { it.title }
        .thenByDescending { it.codec }
        .thenByDescending { it.source }
        .thenBy { !it.track.isDefault }

    private const val TITLE_NAMED = 2

    /** [TITLE_NAMED] when [candidate] is or contains the picked track's [title], 1 when that has none, else 0. */
    private fun titleScore(title: String?, candidate: String?): Int {
        val wanted = title?.trim()?.lowercase()?.takeIf { it.isNotEmpty() } ?: return 1
        return if (candidate != null && candidate.lowercase().contains(wanted)) TITLE_NAMED else 0
    }

    /** The track's language as a canonical tag: its own, else the one its title names; null when neither says. */
    private fun Track.languageTag(): String? = LanguageTags.canonical(language) ?: title?.let(::namedLanguage)

    /** The language [title] names in English or in that language ("English [SDH]", "Français"), the longest name first. */
    private fun namedLanguage(title: String): String? {
        val words = title.lowercase().words()
        return languageNames.filter { (name, _) -> words.containsRun(name) }.maxByOrNull { it.first.size }?.second
    }

    /** Every language a preference can name ([LanguageTags.preferenceCodes]), by the words of its names. */
    private val languageNames: List<Pair<List<String>, String>> by lazy {
        LanguageTags.preferenceCodes.mapNotNull(LanguageTags::canonical).distinct().flatMap { tag ->
            listOf("en", tag).mapNotNull { locale -> localizedLanguageName(tag, locale)?.lowercase()?.words()?.takeIf { it.isNotEmpty() } }
                .distinct()
                .map { it to tag }
        }
    }

    /** Whether [run] appears in this list as consecutive elements. */
    private fun List<String>.containsRun(run: List<String>): Boolean =
        (0..size - run.size).any { start -> run.indices.all { this[start + it] == run[it] } }

    /** The best of [tracks] for the first of [preferred] that any of them matches. */
    private fun best(tracks: List<Track>, preferred: List<String>, order: Comparator<Track>): Track? {
        val tagged = tracks.mapNotNull { track -> LanguageTags.canonical(track.language)?.let { track to it } }
        for (wanted in preferred) {
            val matches = tagged.mapNotNull { (track, tag) -> LanguageTags.match(wanted, tag).takeIf { it > 0 }?.let { track to it } }
            if (matches.isEmpty()) continue
            return matches.sortedWith(compareByDescending<Pair<Track, Int>> { it.second }.thenBy(order) { it.first }).first().first
        }
        return null
    }

    private val audioOrder: Comparator<Track> = compareBy<Track> { it.isCommentary() }.thenBy { !it.isDefault }

    private val describedFirst: Comparator<Track> = compareBy<Track> { !it.isDescriptive() }.then(audioOrder)

    private val describedLast: Comparator<Track> = compareBy<Track> { it.isDescriptive() }.then(audioOrder)

    private val subtitleOrder: Comparator<Track> = compareBy<Track> { it.isSdh() }.thenBy { it.external }.thenBy { !it.isDefault }

    private val captionOrder: Comparator<Track> = compareBy<Track> { !it.isSdh() }.thenBy { it.external }.thenBy { !it.isDefault }

    /** Containers often leave the flag unset and say it in the title ("English (Forced)"). */
    private fun Track.isForced() = forced || title.mentions("forced")

    private fun Track.isSdh() = hearingImpaired || title.mentions("sdh")

    private fun Track.isCommentary() = title.mentions("commentary")

    /** An audio description of the picture: the flag, or a title that says so ("English (Audio Description)", "AD"). */
    private fun Track.isDescriptive() = visualImpaired || audioDescriptionWords.any { title.mentions(it) }

    /** The words a track's title says it is an audio description with. */
    internal val audioDescriptionWords = listOf("description", "descriptive", "described", "ad")

    /** Whether [word] appears as a word of its own, ignoring case. */
    private fun String?.mentions(word: String): Boolean = this != null && words().any { it.equals(word, ignoreCase = true) }

    /** The runs of letters and digits. */
    private fun String.words(): List<String> {
        val words = mutableListOf<String>()
        var start = -1
        for (i in indices) {
            if (!this[i].isLetterOrDigit()) {
                if (start >= 0) words += substring(start, i)
                start = -1
            } else if (start < 0) {
                start = i
            }
        }
        if (start >= 0) words += substring(start)
        return words
    }
}
