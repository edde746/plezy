package com.edde746.plezy.playback.session

import com.edde746.plezy.playback.TrackKind.AUDIO
import com.edde746.plezy.playback.TrackKind.SUBTITLE
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class TrackChooserTest {
    private val englishAudio = track(1, AUDIO, "eng", default = true, selected = true)
    private val commentary = track(2, AUDIO, "jpn", title = "Director's Commentary")
    private val japaneseAudio = track(3, AUDIO, "jpn")
    private val audio = listOf(englishAudio, commentary, japaneseAudio)

    @Test
    fun audioTakesTheMostPreferredLanguageTheFileHas() {
        assertEquals(japaneseAudio, TrackChooser.audio(audio, listOf("de", "ja"), descriptions = false), "no German: Japanese, not its commentary")
        assertEquals(englishAudio, TrackChooser.audio(audio, listOf("en", "ja"), descriptions = false))
        assertNull(TrackChooser.audio(audio, emptyList(), descriptions = false), "no preference keeps the file's default")
        assertNull(TrackChooser.audio(audio, listOf("fr"), descriptions = false))
    }

    @Test
    fun aRegionalPreferencePrefersItsRegion() {
        val portuguese = track(1, AUDIO, "por")
        val brazilian = track(2, AUDIO, "pt-BR")
        assertEquals(brazilian, TrackChooser.audio(listOf(portuguese, brazilian), listOf("pt-BR"), descriptions = false))
        assertEquals(portuguese, TrackChooser.audio(listOf(portuguese), listOf("pt-BR"), descriptions = false))
    }

    private val englishDescription = track(4, AUDIO, "eng", visualImpaired = true)

    @Test
    fun anAudioDescriptionComesFirstWhenTheSystemAsksForThemAndLastOtherwise() {
        val described = listOf(englishDescription) + audio
        assertEquals(englishDescription, TrackChooser.audio(described, listOf("en"), descriptions = true))
        assertEquals(englishAudio, TrackChooser.audio(described, listOf("en"), descriptions = false))
        // One its title names, flagged default: the flag doesn't make it the choice of someone who didn't ask.
        val titled = track(5, AUDIO, "eng", title = "English - Audio Description", default = true)
        assertEquals(titled, TrackChooser.audio(audio + titled, listOf("en"), descriptions = true))
        assertEquals(englishAudio, TrackChooser.audio(listOf(titled) + audio, listOf("en"), descriptions = false))
        // The language comes first: no Japanese description, the Japanese audio.
        assertEquals(japaneseAudio, TrackChooser.audio(described, listOf("ja"), descriptions = true))
    }

    @Test
    fun withoutAPreferenceTheFilesOwnChoiceIsPutRightForAudioDescriptions() {
        val described = audio + englishDescription
        assertEquals(englishDescription, TrackChooser.audio(described, emptyList(), descriptions = true), "English playing: its description")
        assertNull(TrackChooser.audio(described, emptyList(), descriptions = false))
        val plain = englishAudio.copy(selected = false)
        val describedPlaying = listOf(plain, commentary, japaneseAudio, englishDescription.copy(selected = true))
        assertEquals(plain, TrackChooser.audio(describedPlaying, emptyList(), descriptions = false), "a description nobody asked for: the plain track")
        assertNull(TrackChooser.audio(describedPlaying, emptyList(), descriptions = true))
    }

    private val englishFull = track(1, SUBTITLE, "eng")
    private val englishSdh = track(2, SUBTITLE, "eng", title = "English SDH")
    private val englishForced = track(3, SUBTITLE, "eng", title = "English (Forced)")
    private val japaneseForced = track(4, SUBTITLE, "jpn", forced = true)
    private val englishExternal = track(5, SUBTITLE, "en", external = true)
    private val subtitles = listOf(englishSdh, englishExternal, englishForced, japaneseForced, englishFull)

    @Test
    fun foreignAudioGetsFullSubtitlesInThePreferredLanguage() {
        // Embedded before external, plain before SDH, never the forced track.
        assertEquals(englishFull, TrackChooser.subtitle(subtitles, audioLanguage = "jpn", preferred = listOf("en"), captions = false))
        assertEquals(englishExternal, TrackChooser.subtitle(subtitles - englishFull, "jpn", listOf("en"), captions = false))
        assertEquals(englishForced, TrackChooser.subtitle(listOf(englishForced), "jpn", listOf("en"), captions = false), "forced ones only as a last resort")
        // Audio of unknown language may be foreign: the preferred subtitles show.
        assertEquals(englishFull, TrackChooser.subtitle(subtitles, audioLanguage = null, preferred = listOf("en"), captions = false))
    }

    @Test
    fun audioInAPreferredLanguageOnlyGetsItsForcedSubtitles() {
        assertEquals(englishForced, TrackChooser.subtitle(subtitles, audioLanguage = "eng", preferred = listOf("en"), captions = false))
        assertEquals(japaneseForced, TrackChooser.subtitle(subtitles, audioLanguage = "jpn", preferred = listOf("ja", "en"), captions = false))
        assertNull(TrackChooser.subtitle(subtitles - englishForced, audioLanguage = "en", preferred = listOf("en"), captions = false))
    }

    @Test
    fun withoutASubtitleLanguageOnlyForcedSubtitlesShow() {
        assertEquals(englishForced, TrackChooser.subtitle(subtitles, audioLanguage = "eng", preferred = emptyList(), captions = false))
        assertNull(TrackChooser.subtitle(subtitles, audioLanguage = "fre", preferred = emptyList(), captions = false))
        assertNull(TrackChooser.subtitle(subtitles, audioLanguage = null, preferred = emptyList(), captions = false))
    }

    @Test
    fun withCaptionsOnAudioTheUserUnderstandsGetsFullSubtitlesInItsLanguageSdhFirst() {
        // remux.mkv: English audio, its forced subtitles flagged default, then English and English (SDH).
        val remux = EPISODE_1_TRACKS
        assertEquals(remux.withId(SUBTITLE, 3), TrackChooser.subtitle(remux, "en", listOf("en"), captions = true), "English (SDH), not the forced")
        assertEquals(remux.withId(SUBTITLE, 3), TrackChooser.subtitle(remux, "en", emptyList(), captions = true), "no subtitle language: the audio's")
        assertEquals(englishSdh, TrackChooser.subtitle(subtitles, "eng", listOf("fr", "en"), captions = true), "the audio's language first")
        assertEquals(englishFull, TrackChooser.subtitle(subtitles - englishSdh, "eng", listOf("en"), captions = true), "no SDH: the full ones")
        // None in the audio's language: the most preferred language that has some, forced ones only without any.
        val french = track(6, SUBTITLE, "fre")
        assertEquals(french, TrackChooser.subtitle(listOf(englishForced, french), "eng", listOf("en", "fr"), captions = true))
        assertEquals(englishForced, TrackChooser.subtitle(listOf(englishForced, japaneseForced), "eng", listOf("en"), captions = true))
        assertNull(TrackChooser.subtitle(subtitles, audioLanguage = null, preferred = emptyList(), captions = true), "no language known")
    }

    @Test
    fun withCaptionsOnForeignAudioGetsSdhFirst() {
        assertEquals(englishSdh, TrackChooser.subtitle(subtitles, audioLanguage = "jpn", preferred = listOf("en"), captions = true))
        assertEquals(englishFull, TrackChooser.subtitle(subtitles - englishSdh, "jpn", listOf("en"), captions = true))
    }

    @Test
    fun aCarriedPickTakesTheSameTrackWhereverTheNextFileHasIt() {
        val next = EPISODE_2_TRACKS
        assertEquals(next.withId(SUBTITLE, 2), TrackChooser.carried(next, EPISODE_1_TRACKS.withId(SUBTITLE, 5)), "Français, 5th then 2nd")
        assertEquals(next.withId(SUBTITLE, 5), TrackChooser.carried(next, EPISODE_1_TRACKS.withId(SUBTITLE, 4)), "Español")
        // German is the 2nd audio track in episode 1, where episode 2 has the commentary.
        assertEquals(next.withId(AUDIO, 3), TrackChooser.carried(next, EPISODE_1_TRACKS.withId(AUDIO, 2)))
        assertEquals(next.withId(AUDIO, 2), TrackChooser.carried(next, EPISODE_1_TRACKS.withId(AUDIO, 3)), "the commentary, not the English audio")
        assertEquals(next.withId(AUDIO, 1), TrackChooser.carried(next, EPISODE_1_TRACKS.withId(AUDIO, 1)), "the English audio, not its commentary")
    }

    @Test
    fun forcedStandsForForcedAndFullForFullBeforeTheOther() {
        val next = EPISODE_2_TRACKS
        assertEquals(next.withId(SUBTITLE, 3), TrackChooser.carried(next, EPISODE_1_TRACKS.withId(SUBTITLE, 2)))
        assertEquals(next.withId(SUBTITLE, 4), TrackChooser.carried(next, EPISODE_1_TRACKS.withId(SUBTITLE, 1)))
        // The next file's only English flagged forced, or its forced one without the flag: the language still decides.
        val flagged = listOf(track(1, SUBTITLE, "fr"), track(2, SUBTITLE, "en", "English", forced = true))
        assertEquals(flagged[1], TrackChooser.carried(flagged, EPISODE_1_TRACKS.withId(SUBTITLE, 2)))
        val unflagged = listOf(track(1, SUBTITLE, "fr"), track(2, SUBTITLE, "en"))
        assertEquals(unflagged[1], TrackChooser.carried(unflagged, EPISODE_1_TRACKS.withId(SUBTITLE, 1)))
    }

    @Test
    fun sdhStandsForSdhAndFullForFullBeforeTheOther() {
        val next = EPISODE_2_TRACKS
        assertEquals(next.withId(SUBTITLE, 1), TrackChooser.carried(next, EPISODE_1_TRACKS.withId(SUBTITLE, 3)))
        // "English (SDH)" names "English" too: the standing comes first.
        assertEquals(next.withId(SUBTITLE, 3), TrackChooser.carried(next, EPISODE_1_TRACKS.withId(SUBTITLE, 2)))
        val onlyFull = listOf(track(7, SUBTITLE, "en", "English"))
        assertEquals(onlyFull.single(), TrackChooser.carried(onlyFull, EPISODE_1_TRACKS.withId(SUBTITLE, 3)), "SDH English, else English")
    }

    @Test
    fun anAudioDescriptionStandsForAnAudioDescriptionAndPlainForPlain() {
        val next = listOf(track(1, AUDIO, "en", "English", default = true), track(2, AUDIO, "en", "English", visualImpaired = true))
        assertEquals(next[1], TrackChooser.carried(next, track(4, AUDIO, "en", "English AD", visualImpaired = true)), "not the default plain one")
        assertEquals(next[0], TrackChooser.carried(next.reversed(), track(3, AUDIO, "en", "English")))
    }

    @Test
    fun anAddedSubtitleIsStoodForByAnEmbeddedOneInItsLanguageUntilItsOwnArrives() {
        val added = track(6, SUBTITLE, "en", "OpenSubtitles", external = true, codec = "subrip")
        val embedded = listOf(track(1, SUBTITLE, "en", "English (forced)", forced = true), track(2, SUBTITLE, "es"), track(3, SUBTITLE, "en", codec = "ass"))
        assertEquals(embedded[2], TrackChooser.carried(embedded, added))
        val withAdded = embedded + track(4, SUBTITLE, "en", "Subs", external = true, codec = "subrip") +
            track(5, SUBTITLE, "en", "OpenSubtitles", external = true, codec = "subrip")
        assertEquals(withAdded[4], TrackChooser.carried(withAdded, added))
    }

    @Test
    fun withoutTheLanguageThereIsNoMatchUnlessATitleVouches() {
        assertNull(TrackChooser.carried(EPISODE_2_TRACKS - EPISODE_2_TRACKS.withId(SUBTITLE, 5), EPISODE_1_TRACKS.withId(SUBTITLE, 4)), "no Spanish")
        val swedish = track(3, SUBTITLE, null, "Swedish")
        val untagged = listOf(track(1, SUBTITLE, null, "Finnish"), track(2, SUBTITLE, null, "Swedish"))
        assertEquals(untagged[1], TrackChooser.carried(untagged, swedish))
        assertEquals(untagged[1], TrackChooser.carried(untagged, swedish.copy(language = "sv")))
        assertNull(TrackChooser.carried(listOf(track(1, SUBTITLE, null)), swedish), "nothing names it")
        assertNull(TrackChooser.carried(listOf(track(1, SUBTITLE, "fi", "Swedish")), swedish.copy(language = "sv")), "a language on both sides decides")
    }

    @Test
    fun theCloserLanguageWins() {
        val portuguese = track(1, SUBTITLE, "pt")
        val brazilian = track(2, SUBTITLE, "pt-BR")
        assertEquals(brazilian, TrackChooser.carried(listOf(portuguese, brazilian), track(9, SUBTITLE, "pt-BR")))
        assertEquals(portuguese, TrackChooser.carried(listOf(portuguese), track(9, SUBTITLE, "pt-BR")))
    }

    @Test
    fun theVeryTrackComesBackElseTheDefaultThenTheFirstOfEqualOnes() {
        val twins = listOf(track(1, SUBTITLE, "en", selected = true), track(2, SUBTITLE, "en"), track(3, SUBTITLE, "en", default = true))
        assertEquals(twins[1], TrackChooser.carried(twins, twins[1].copy(selected = true)), "the same file loaded again")
        assertEquals(twins[2], TrackChooser.carried(twins, track(9, SUBTITLE, "en")))
        assertEquals(twins[0], TrackChooser.carried(twins.take(2), track(9, SUBTITLE, "en")))
    }

    @Test
    fun aTrackWithoutALanguageTagIsInTheLanguageItsTitleNames() {
        val next = listOf(track(1, SUBTITLE, null, "Français"), track(2, SUBTITLE, "und", "English [SDH]"), track(3, SUBTITLE, null, "Signs"))
        assertEquals(next[1], TrackChooser.carried(next, track(9, SUBTITLE, "eng")), "an English track without a title")
        assertEquals(next[1], TrackChooser.carried(next, track(9, SUBTITLE, "en", "OpenSubtitles v3 2", external = true, codec = "subrip")))
        assertEquals(next[0], TrackChooser.carried(next, track(9, SUBTITLE, "fre", "French")))
        // The language's code in any form: ISO 639-2/B or /T, ISO 639-1, BCP 47 with a region.
        val forms = listOf(track(1, SUBTITLE, "en-US"), track(2, SUBTITLE, "ger"))
        assertEquals(forms[0], TrackChooser.carried(forms, track(9, SUBTITLE, "eng")))
        assertEquals(forms[1], TrackChooser.carried(forms, track(9, SUBTITLE, "deu")))
    }

    @Test
    fun aPickOfNoKnownLanguageStandsForATrackOfNoneElseNothing() {
        val untagged = track(9, SUBTITLE, "und")
        val next = listOf(track(1, SUBTITLE, "fr"), track(2, SUBTITLE, null))
        assertEquals(next[1], TrackChooser.carried(next, untagged))
        assertNull(TrackChooser.carried(next.take(1), untagged))
    }
}
