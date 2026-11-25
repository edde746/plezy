package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.playback.session.SubtitleDownloadOutcome
import com.edde746.plezy.playback.session.SubtitleSearchHit
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

class SubtitleSearchTest {
    @Test
    fun theLanguageIsTheOneKeptElseTheViewersElseEnglish() {
        assertEquals("fr", SubtitleSearch.language("fr", "nl"), "prefers the saved language")
        assertEquals("pt", SubtitleSearch.language("pt_BR", "nl"), "normalizes a saved locale")
        assertEquals("en", SubtitleSearch.language("eng", "nl"), "and a three-letter language")
        assertEquals("nl", SubtitleSearch.language("zz", "nl"), "an invalid saved language falls back to the system's")
        assertEquals("en", SubtitleSearch.language("zz", "xx"), "then to English")
        assertEquals("nl", SubtitleSearch.language(null, "nl"))
    }

    private fun PlayerHarness.searchable() {
        playing()
        sessionInfo { it.copy(subtitleSearch = true) }
    }

    @Test
    fun onlyAServerWithSearchHasTheSheet() = playerTest {
        playing()
        assertNull(state.subtitleSearch)
        sessionInfo { it.copy(subtitleSearch = true) }
        assertEquals("Big Buck Bunny", state.subtitleSearch?.title)
    }

    @Test
    fun openingTheSheetSearchesAtOnceInTheKeptLanguage() = playerTest(preferences = PlayerChoices(subtitleSearchLanguage = "de")) {
        searchable()
        session.searchHits = listOf(SubtitleSearchHit("k1", "Movie.de.srt", "OpenSubtitles"))
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.SUBTITLE_SEARCH))
        assertEquals(listOf("search de null"), session.actions)
        val search = assertNotNull(state.subtitleSearch)
        assertEquals("de", search.languageCode)
        assertEquals(listOf(SubtitleResult("k1", "Movie.de.srt", "OpenSubtitles", PlayerCommand.DownloadSubtitle("k1"))), search.results)
        assertNull(search.message)
        assertEquals(listOf("de"), search.languages.filter { it.selected }.map { (it.command as PlayerCommand.SearchSubtitles).language })
    }

    @Test
    fun titleEditsSearchOnceTheyRestHalfASecondAndANewLanguageAtOnce() = playerTest {
        searchable()
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.SUBTITLE_SEARCH))
        assertEquals("No subtitles found", state.subtitleSearch?.message)
        session.actions.clear()
        dispatch(PlayerCommand.SearchSubtitles("en", "Big"))
        advance(300.milliseconds)
        dispatch(PlayerCommand.SearchSubtitles("en", "Big Buck"))
        advance(499.milliseconds)
        assertEquals(emptyList(), session.actions)
        advance(1.milliseconds)
        assertEquals(listOf("search en Big Buck"), session.actions)
        assertEquals("Big Buck", state.subtitleSearch?.title)

        dispatch(PlayerCommand.SearchSubtitles("en", "Big Buck Bunny", now = true))
        assertEquals("search en Big Buck Bunny", session.actions.last(), "a submit searches now")
        dispatch(PlayerCommand.SearchSubtitles("fr", "Big Buck Bunny"))
        assertEquals("search fr Big Buck Bunny", session.actions.last(), "a new language searches now")
        assertEquals("fr", preferences.choices.value.subtitleSearchLanguage, "and is kept")
    }

    @Test
    fun aFailedSearchSaysWhy() = playerTest {
        searchable()
        session.searchFailure = IllegalStateException("HTTP 500")
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.SUBTITLE_SEARCH))
        assertEquals(T.errors.searchFailed(T.errors.reasonUnexpected), state.subtitleSearch?.message)
        assertEquals(emptyList(), state.subtitleSearch?.results)
    }

    @Test
    fun eachDownloadOutcomeHasItsTextAndAShownSubtitleClosesTheSheet() = playerTest {
        searchable()
        session.searchHits = listOf(SubtitleSearchHit("k1", "a.srt", null))
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.SUBTITLE_SEARCH))
        for ((outcome, text) in listOf(
            SubtitleDownloadOutcome.NOT_APPLIED to T.videoControls.subtitleDownloadedNotApplied,
            SubtitleDownloadOutcome.TIMED_OUT to T.videoControls.subtitleDownloadTimedOut,
        )) {
            session.downloadOutcome = outcome
            dispatch(PlayerCommand.DownloadSubtitle("k1"))
            assertEquals(text, state.subtitleSearch?.message)
            assertEquals(PlayerMenu.SUBTITLE_SEARCH, state.menu)
            assertNull(state.subtitleSearch?.downloading)
        }
        session.downloadFailure = IllegalStateException()
        dispatch(PlayerCommand.DownloadSubtitle("k1"))
        assertEquals(T.videoControls.subtitleDownloadFailed, state.subtitleSearch?.message)

        session.downloadFailure = null
        session.downloadOutcome = SubtitleDownloadOutcome.APPLIED
        dispatch(PlayerCommand.DownloadSubtitle("k1"))
        assertNull(state.menu)
        assertEquals(T.videoControls.subtitleDownloaded, state.osd)
    }

    @Test
    fun `a slow earlier search cannot break downloading a result of the later one`() = playerTest {
        searchable()
        session.hold = true
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.SUBTITLE_SEARCH))
        dispatch(PlayerCommand.SearchSubtitles("fr", null))
        assertEquals(2, session.heldSearches.size)
        session.heldSearches[1].complete(listOf(SubtitleSearchHit("b", "Movie.fr.srt", null)))
        advance(Duration.ZERO)
        session.heldSearches[0].complete(listOf(SubtitleSearchHit("a", "Movie.en.srt", null)))
        advance(Duration.ZERO)
        assertEquals(listOf("b"), state.subtitleSearch?.results?.map { it.key })

        dispatch(PlayerCommand.DownloadSubtitle("b"))
        assertNull(state.menu, "the later search's subtitle downloads and shows")
        assertEquals(T.videoControls.subtitleDownloaded, state.osd)
    }
}
