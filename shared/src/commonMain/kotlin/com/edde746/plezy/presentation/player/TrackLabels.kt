package com.edde746.plezy.presentation.player

import com.edde746.plezy.lang.LanguageNames
import com.edde746.plezy.playback.Track
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.playback.session.TrackChooser
import com.edde746.plezy.strings.T
import com.edde746.plezy.strings.isolate

/**
 * Track menu rows. The first line is the language, else the track's title, else "Track 2". The second line collects the
 * rest: the title (when the language took the first line and the title says more than the language), Forced, SDH,
 * Audio description, the codec, the channel layout, Default, External. The title is the file's own words: isolated
 * wherever it shares a line with the app's.
 */
internal object TrackLabels {
    private const val SEPARATOR = " · "

    /**
     * The menu rows for [kind]'s tracks among [tracks]. [selectedId] and [secondId] (the second subtitle's) override the
     * engine's selection while a change is on its way (null: none). Subtitles start with "Off".
     */
    fun items(tracks: List<Track>, kind: TrackKind, selectedId: Long?, secondId: Long?, locale: String): List<TrackItem> {
        val ofKind = tracks.filter { it.kind == kind }
        val rows = ofKind.mapIndexed { index, track ->
            val (label, detail) = describe(track, index, locale)
            TrackItem(id = track.id, label = label, detail = detail, selected = track.id == selectedId, second = track.id == secondId)
        }
        if (kind != TrackKind.SUBTITLE) return rows
        return listOf(TrackItem(id = null, label = T.player.track.off, detail = null, selected = selectedId == null)) + rows
    }

    /** The first line alone, for messages ("Subtitles: English"). */
    fun label(track: Track, tracks: List<Track>, locale: String): String {
        val (label, own) = naming(track, index(track, tracks), locale)
        return if (own) isolate(label) else label
    }

    /**
     * The first line with what names the track further (its title when it says more than the language, Forced, SDH,
     * Audio description), without the format: the playback info's track ("English · Commentary", "English · SDH").
     */
    fun name(track: Track, tracks: List<Track>, locale: String): String {
        val (label, own, title) = naming(track, index(track, tracks), locale)
        return line(label, own, listOfNotNull(title?.let(::isolate)) + flags(track))
    }

    private fun index(track: Track, tracks: List<Track>): Int =
        tracks.filter { it.kind == track.kind }.indexOfFirst { it.id == track.id }.coerceAtLeast(0)

    private fun describe(track: Track, index: Int, locale: String): Pair<String, String?> {
        val (label, _, title) = naming(track, index, locale)
        val details = buildList {
            addAll(flags(track))
            track.codec?.takeIf { it.isNotBlank() }?.let { add(codecName(track.kind, it, track.codecProfile)) }
            track.channels?.takeIf { it > 0 && track.kind == TrackKind.AUDIO }?.let { add(CodecNames.channels(it)) }
            if (track.isDefault) add(T.player.track.defaultTrack)
            if (track.external) add(T.player.track.external)
        }
        return label to (title?.let { line(it, own = true, details) } ?: details.takeIf { it.isNotEmpty() }?.joinToString(SEPARATOR))
    }

    /** [first] and [rest] on one line; [first] isolated when it is the track's [own] words and doesn't stand alone. */
    private fun line(first: String, own: Boolean, rest: List<String>): String =
        if (rest.isEmpty()) first else (listOf(if (own) isolate(first) else first) + rest).joinToString(SEPARATOR)

    /**
     * The first line, whether it is the track's own title rather than the language or "Track 2", and the title when
     * the language took that line and the title says more than it.
     */
    private fun naming(track: Track, index: Int, locale: String): Triple<String, Boolean, String?> {
        val language = LanguageNames.displayName(track.language, locale)
        val title = track.title?.trim()?.takeIf { it.isNotEmpty() }
        val label = language ?: title ?: T.player.track.numbered((index + 1).toString())
        return Triple(label, language == null && title != null, title?.takeIf { language != null && !restates(it, language, track) })
    }

    /** Forced, SDH and Audio description, unless the track's title already says so. */
    private fun flags(track: Track): List<String> = buildList {
        if (track.forced && !track.title.mentions("forced")) add(T.player.track.forced)
        if (track.hearingImpaired && !track.title.mentions("sdh")) add(T.player.track.sdh)
        if (track.visualImpaired && TrackChooser.audioDescriptionWords.none { track.title.mentions(it) }) {
            add(T.player.track.audioDescription)
        }
    }

    /**
     * An audio codec by its profile, so a DTS-HD MA track and its DTS core don't both read "DTS" and Atmos shows. AAC's
     * profile ("LC") stays in the playback info: in the menu it would only lengthen nearly every row.
     */
    private fun codecName(kind: TrackKind, codec: String, profile: String?): String = when (kind) {
        TrackKind.VIDEO -> CodecNames.video(codec)
        TrackKind.AUDIO -> CodecNames.audio(codec, profile.takeUnless { codec.startsWith("aac", ignoreCase = true) })
        TrackKind.SUBTITLE -> CodecNames.subtitle(codec)
    }

    /** A title that is only the language, by name or by code ("English", "eng"), adds nothing. */
    private fun restates(title: String, language: String, track: Track): Boolean =
        title.equals(language, ignoreCase = true) || title.equals(track.language?.trim(), ignoreCase = true)

    /** Whether the title already carries [word] as a word of its own ("English (Forced)", "English SDH"). */
    private fun String?.mentions(word: String): Boolean {
        if (this == null) return false
        var start = 0
        while (start < length) {
            if (!this[start].isLetterOrDigit()) {
                start++
                continue
            }
            var end = start
            while (end < length && this[end].isLetterOrDigit()) end++
            if (end - start == word.length && regionMatches(start, word, 0, word.length, ignoreCase = true)) return true
            start = end
        }
        return false
    }
}
