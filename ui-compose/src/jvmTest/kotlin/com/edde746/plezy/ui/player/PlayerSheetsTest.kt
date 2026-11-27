package com.edde746.plezy.ui.player

import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.assertIsSelected
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.performImeAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextReplacement
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaFileInfo
import com.edde746.plezy.model.MediaFilePart
import com.edde746.plezy.model.MediaFileVersion
import com.edde746.plezy.model.MediaStreamDetails
import com.edde746.plezy.model.MediaStreamKind
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.presentation.player.ChapterItem
import com.edde746.plezy.presentation.player.FileInfoState
import com.edde746.plezy.presentation.player.OptionChoice
import com.edde746.plezy.presentation.player.PlayerOption
import com.edde746.plezy.presentation.player.PlayerOptionId
import com.edde746.plezy.presentation.player.QueueItem
import com.edde746.plezy.presentation.player.SleepTimerBanner
import com.edde746.plezy.presentation.player.SubtitleResult
import com.edde746.plezy.presentation.player.SubtitleSearchState
import com.edde746.plezy.presentation.player.TrackItem
import com.edde746.plezy.presentation.player.VersionsMenu
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.probe.LayoutProbe
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** Plezy's player sheets: settings rows and pages, tracks, versions, chapters, queue, subtitle search, sleep timer. */
@OptIn(ExperimentalTestApi::class)
class PlayerSheetsTest {
    private val commands = mutableListOf<PlayerCommand>()
    private val vc = T.videoControls

    private fun row(label: String) = hasText(label) and hasClickAction()

    // Settings sheet

    /** The zoom page lists its presets and Reset; Reset sends the reset. */
    @Test
    fun theZoomPageOffersItsPresetsAndReset() = runComposeUiTest {
        player(FormFactor.HANDHELD, onCommand = { commands += it }) { testPlayerState(menu = PlayerMenu.ZOOM) }
        onNode(row("150%")).assertExists()
        onNode(row(T.player.options.resetZoom)).performClick()
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.ResetZoom), commands) }
    }

    /**
     * The settings' values show as the store words them (Off, Normal, Active); the performance overlay, ambient lighting
     * and HDR switches flip in place; the file info row opens its page.
     */
    @Test
    fun theSettingsShowTheirValuesAndSwitchesFlip() = runComposeUiTest {
        fun switch(id: PlayerOptionId, label: String, on: Boolean, toggle: PlayerCommand) =
            PlayerOption(id, label, if (on) "On" else T.common.off, adjusted = false, page = null, choices = emptyList(), on = on, toggle = toggle)
        val overlay = PlayerCommand.ShowControls
        val ambient = PlayerCommand.HideControls
        val hdr = PlayerCommand.ToggleControls
        val options = listOf(
            PlayerOption(PlayerOptionId.SPEED, T.videoSettings.playbackSpeed, T.player.speed.normal, false, PlayerMenu.SPEED, emptyList(), null, null),
            PlayerOption(PlayerOptionId.SLEEP_TIMER, T.videoSettings.sleepTimer, "Active", true, PlayerMenu.SLEEP_TIMER, emptyList(), null, null),
            switch(PlayerOptionId.HDR, T.videoSettings.hdr, on = true, hdr),
            switch(PlayerOptionId.PLAYBACK_INFO, T.player.info.show, on = false, overlay),
            switch(PlayerOptionId.AMBIENT_LIGHTING, vc.ambientLighting, on = false, ambient),
            PlayerOption(PlayerOptionId.FILE_INFO, T.fileInfo.title, "", false, PlayerMenu.FILE_INFO, emptyList(), null, null),
        )
        player(FormFactor.DESKTOP, onCommand = { commands += it }) { testPlayerState(menu = PlayerMenu.OPTIONS).copy(options = options) }
        onNodeWithText(T.player.speed.normal).assertExists()
        onNodeWithText("Active").assertExists()
        onNodeWithText(T.player.info.show).performClick()
        onNodeWithText(vc.ambientLighting).performClick()
        onNodeWithText(T.videoSettings.hdr).performClick()
        onNodeWithText(T.fileInfo.title).performClick()
        runOnIdle { assertEquals(listOf(overlay, ambient, hdr, PlayerCommand.OpenMenu(PlayerMenu.FILE_INFO)), commands) }
    }

    /**
     * The file info opens as a page whose back button returns to the settings; it loads, then shows its rows, or says
     * the server has none.
     */
    @Test
    fun theFileInfoPageLoadsShowsItsRowsOrItsFailureAndGoesBack() = runComposeUiTest {
        val loading = FileInfoState(loading = true, info = null, title = "Movie", error = null)
        val video = MediaStreamDetails(MediaStreamKind.VIDEO, 1, codec = "hevc")
        val rows = FileInfoState(false, MediaFileInfo(listOf(MediaFileVersion(parts = listOf(MediaFilePart(streams = listOf(video)))))), "", null)
        val failed = FileInfoState(false, null, "Movie", T.messages.fileInfoNotAvailable)
        val state = mutableStateOf(loading)
        player(FormFactor.HANDHELD, onCommand = { commands += it }) { testPlayerState(menu = PlayerMenu.FILE_INFO).copy(fileInfo = state.value) }
        onNodeWithText(T.fileInfo.title).assertExists()
        onNodeWithText("HEVC").assertDoesNotExist()
        state.value = rows
        onNodeWithText(T.fileInfo.codec).assertExists()
        onNodeWithText("HEVC").assertExists()
        state.value = failed
        onNodeWithText(T.messages.fileInfoNotAvailable).assertExists()
        onNodeWithContentDescription(T.nav.back).performClick()
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.Back), commands) }
    }

    /** Without an output to pick, the audio output page says so. */
    @Test
    fun anAudioOutputPageWithoutDevicesSaysSo() = runComposeUiTest {
        val output = PlayerOption(PlayerOptionId.AUDIO_OUTPUT, T.videoSettings.audioOutput, "", false, PlayerMenu.AUDIO_OUTPUT, emptyList(), null, null)
        player(FormFactor.DESKTOP) { testPlayerState(menu = PlayerMenu.AUDIO_OUTPUT).copy(audioOptions = testAudioOptions + output) }
        onNodeWithText(vc.noAudioDevicesAvailable).assertExists()
    }

    // Version and quality

    /** Versions above qualities in one list, under their headings; one the server can't play is disabled. */
    @Test
    fun theVersionPageListsVersionsThenQualitiesAndDisablesTheUnreachable() = runComposeUiTest {
        val menu = VersionsMenu(
            versions = listOf(
                OptionChoice("4K HDR", null, selected = true, PlayerCommand.SelectVersion(0)),
                OptionChoice("1080p", null, selected = false, PlayerCommand.SelectVersion(1)),
            ),
            qualities = listOf(
                OptionChoice(vc.qualityOriginal, "38 Mbps", selected = true, PlayerCommand.SelectQuality(TranscodeQualityPreset.entries.first())),
                OptionChoice("720p 4 Mbps", null, selected = false, PlayerCommand.SelectQuality(TranscodeQualityPreset.entries.last()), enabled = false),
            ),
        )
        player(FormFactor.TV, onCommand = { commands += it }) { testPlayerState(menu = PlayerMenu.VERSIONS).copy(versions = menu) }
        onNodeWithText(vc.versionColumnHeader).assertExists()
        onNodeWithText(vc.qualityColumnHeader).assertExists()
        onNode(row(vc.qualityOriginal)).assertIsFocused()
        onNode(row("720p 4 Mbps")).assertIsNotEnabled()
        onNode(row("1080p")).performClick()
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.SelectVersion(1)), commands) }
    }

    // Audio and subtitles

    private val tracks = testPlayerState().copy(
        audioTracks = listOf(
            TrackItem(1, "English", "AC3 5.1", selected = true),
            TrackItem(2, "Japanese", "AAC", selected = false),
        ),
        subtitleTracks = listOf(
            TrackItem(null, "Off", null, selected = false),
            TrackItem(3, "English", null, selected = true, forced = true),
        ),
    )

    /** The audio page lists the audio, the selected track focused on TV; a pick sends it. */
    @Test
    fun theAudioPageListsTheAudioWithTheSelectedFocused() = runComposeUiTest {
        player(FormFactor.TV, onCommand = { commands += it }) { tracks.copy(menu = PlayerMenu.AUDIO) }
        onNode(row("AC3 5.1")).assertIsFocused()
        onNode(row("Japanese")).performClick()
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.SelectTrack(TrackKind.AUDIO, 2)), commands) }
    }

    /**
     * After the audio and its delay the audio menu holds the audio settings, each with its value: a switch flips in
     * place, a setting with a page opens it.
     */
    @Test
    fun theAudioMenuHoldsTheAudioSettingsAfterTheTracks() = runComposeUiTest {
        val bounds = HashMap<String, Rect>()
        player(FormFactor.DESKTOP, probe = LayoutProbe { name, rect -> if (rect != null) bounds[name] = rect else bounds.remove(name) }, onCommand = { commands += it }) {
            tracks.copy(menu = PlayerMenu.AUDIO)
        }
        onNode(row("Japanese")).assertExists()
        onNodeWithText(T.player.menu.audioDelay).assertExists()
        onNodeWithText(T.settings.audioChannelLimitStereo).assertExists()
        runOnIdle {
            val delay = bounds.getValue("player.menu.delay")
            val normalization = bounds.getValue("player.option.audioNormalization")
            val channels = bounds.getValue("player.option.audioChannels")
            assertTrue(bounds.getValue("player.menu.item.1").bottom <= delay.top, "the delay after the tracks")
            assertTrue(delay.bottom <= normalization.top && normalization.bottom <= channels.top, "the settings after the delay, in order")
            assertTrue("player.option.audioChannels.adjusted" in bounds, "the stereo mix marked")
        }
        onNodeWithText(T.player.options.audioNormalization).performClick()
        onNodeWithText(T.player.options.audioChannels).performClick()
        runOnIdle {
            assertEquals(listOf(PlayerCommand.SetAudioNormalization(true), PlayerCommand.OpenMenu(PlayerMenu.AUDIO_CHANNELS)), commands)
        }
    }

    /** The subtitles page lists the subtitles from Off, a forced track badged; Off sends no track. */
    @Test
    fun theSubtitlePageStartsWithOffAndBadgesAForcedTrack() = runComposeUiTest {
        player(FormFactor.TV, onCommand = { commands += it }) { tracks.copy(menu = PlayerMenu.SUBTITLES) }
        onNodeWithText(T.player.track.forced, useUnmergedTree = true).assertExists()
        onNode(row("Off")).performClick()
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.SelectTrack(TrackKind.SUBTITLE, null)), commands) }
    }

    /** While the server transcodes the audio page picks the server's track; on Plex Search subtitles opens the search. */
    @Test
    fun theAudioPagePicksTheServersAudioAndTheSubtitlesOpenTheSearch() = runComposeUiTest {
        val state = mutableStateOf(
            tracks.copy(
                menu = PlayerMenu.AUDIO,
                sourceAudioTracks = listOf(TrackItem(10, "German", null, selected = true), TrackItem(11, "French", null, selected = false)),
                subtitleSearch = search(),
            ),
        )
        player(FormFactor.HANDHELD, onCommand = { commands += it }) { state.value }
        onNode(row("Japanese")).assertDoesNotExist()
        onNode(row("French")).performClick()
        state.value = state.value.copy(menu = PlayerMenu.SUBTITLES)
        onNodeWithText(vc.searchSubtitles).performClick()
        runOnIdle {
            assertEquals(listOf<PlayerCommand>(PlayerCommand.SelectSourceTrack(TrackKind.AUDIO, 11), PlayerCommand.OpenMenu(PlayerMenu.SUBTITLE_SEARCH)), commands)
        }
    }

    // Subtitle search

    private fun search(
        results: List<SubtitleResult> = emptyList(),
        searching: Boolean = false,
        downloading: String? = null,
        message: String? = null,
    ) = SubtitleSearchState(
        language = "English",
        languageCode = "en",
        languages = listOf(
            OptionChoice("English", null, selected = true, PlayerCommand.SearchSubtitles("en", null)),
            OptionChoice("Swedish", null, selected = false, PlayerCommand.SearchSubtitles("sv", null)),
        ),
        title = "Dune",
        searching = searching,
        results = results,
        downloading = downloading,
        message = message,
    )

    /** Each title edit goes to the store, which waits for typing to pause; the keyboard's Search asks for it at once. */
    @Test
    fun theTitleGoesToTheStoreAsTypedAndSearchSubmitsIt() = runComposeUiTest {
        player(FormFactor.HANDHELD, onCommand = { commands += it }) { testPlayerState(menu = PlayerMenu.SUBTITLE_SEARCH).copy(subtitleSearch = search()) }
        onNode(hasSetTextAction()).performTextReplacement("Dune Part")
        onNode(hasSetTextAction()).performTextReplacement("Dune Part Two")
        onNode(hasSetTextAction()).performImeAction()
        runOnIdle {
            assertEquals(
                listOf<PlayerCommand>(
                    PlayerCommand.SearchSubtitles("en", "Dune Part"),
                    PlayerCommand.SearchSubtitles("en", "Dune Part Two"),
                    PlayerCommand.SearchSubtitles("en", "Dune Part Two", now = true),
                ),
                commands,
            )
        }
    }

    /** The language row opens the languages; a pick searches in it. */
    @Test
    fun theLanguageRowPicksTheSearchLanguage() = runComposeUiTest {
        player(FormFactor.HANDHELD, onCommand = { commands += it }) { testPlayerState(menu = PlayerMenu.SUBTITLE_SEARCH).copy(subtitleSearch = search()) }
        onNodeWithText(vc.language).performClick()
        onNode(row("Swedish")).performClick()
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.SearchSubtitles("sv", null)), commands) }
    }

    /**
     * On an Android TV a remote passing down from the language over the title raises no keyboard (the field isn't
     * editable) and goes on to the results; Select on the title lets it be typed.
     */
    @Test
    fun theTvRemotePassesOverTheTitleWithoutItsKeyboard() = runComposeUiTest {
        val results = listOf(SubtitleResult("a", "Dune.2021.srt", "OpenSubtitles", PlayerCommand.DownloadSubtitle("a")))
        player(FormFactor.TV, onCommand = { commands += it }, keyboardWaitsForSelect = true) {
            testPlayerState(menu = PlayerMenu.SUBTITLE_SEARCH).copy(subtitleSearch = search(results))
        }
        val title = onNode(SemanticsMatcher.keyIsDefined(SemanticsProperties.EditableText))
        onNode(row(vc.language)).assertIsFocused()
        press(Key.DirectionDown)
        title.assertIsFocused().assert(SemanticsMatcher.expectValue(SemanticsProperties.IsEditable, false))
        press(Key.DirectionDown)
        onNode(row("Dune.2021.srt")).assertIsFocused()
        press(Key.DirectionUp)
        press(Key.DirectionCenter)
        title.assertIsFocused().assert(SemanticsMatcher.expectValue(SemanticsProperties.IsEditable, true))
        runOnIdle { assertEquals(emptyList(), commands) }
    }

    /** A result downloads on a pick; while one downloads the others wait; the outcome shows. */
    @Test
    fun aResultDownloadsOneAtATimeAndTheOutcomeShows() = runComposeUiTest {
        val results = listOf(
            SubtitleResult("a", "Dune.2021.srt", "OpenSubtitles", PlayerCommand.DownloadSubtitle("a")),
            SubtitleResult("b", "Dune.2021.SDH.srt", "OpenSubtitles", PlayerCommand.DownloadSubtitle("b")),
        )
        val state = mutableStateOf(search(results))
        player(FormFactor.HANDHELD, onCommand = { commands += it }) { testPlayerState(menu = PlayerMenu.SUBTITLE_SEARCH).copy(subtitleSearch = state.value) }
        onNode(row("Dune.2021.srt")).performClick()
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.DownloadSubtitle("a")), commands) }
        state.value = search(results, downloading = "a")
        onNode(row("Dune.2021.SDH.srt")).assertIsNotEnabled()
        state.value = search(results, message = vc.subtitleDownloaded)
        onNodeWithText(vc.subtitleDownloaded).assertExists()
        state.value = search(searching = true)
        onNode(row("Dune.2021.srt")).assertDoesNotExist()
    }

    // Chapters and queue

    private val nowPlaying = hasContentDescription(T.player.nowPlaying)

    /** The current chapter carries the now-playing mark and focus; a pick seeks there; without chapters the sheet says so. */
    @Test
    fun theChapterSheetMarksTheCurrentChapterAndSeeks() = runComposeUiTest {
        val chapters = listOf(
            ChapterItem("Opening", "0:00", null, current = false, PlayerCommand.SeekToChapter(0)),
            ChapterItem("The Spice", "12:30", null, current = true, PlayerCommand.SeekToChapter(1)),
        )
        val state = mutableStateOf(chapters)
        player(FormFactor.TV, onCommand = { commands += it }) { testPlayerState(menu = PlayerMenu.CHAPTERS).copy(chapters = state.value) }
        onNode(row("The Spice")).assertIsFocused().assertIsSelected().assert(nowPlaying)
        onNode(row("Opening")).assert(!nowPlaying)
        onNode(row("Opening")).performClick()
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.SeekToChapter(0)), commands) }
        state.value = emptyList()
        onNodeWithText(vc.noChaptersAvailable).assertExists()
    }

    /** The entry playing carries the now-playing mark, as the chapter does, and focus; a pick plays it; an empty queue says so. */
    @Test
    fun theQueueSheetMarksWhatPlaysAndPlaysAPick() = runComposeUiTest {
        val queue = listOf(
            QueueItem("1", "Pilot", "S1E1", null, current = true),
            QueueItem("2", "Second", "S1E2", null, current = false, spoiler = true),
        )
        val state = mutableStateOf(queue)
        player(FormFactor.TV, onCommand = { commands += it }) { testPlayerState(menu = PlayerMenu.QUEUE).copy(queue = state.value) }
        onNode(row("Pilot")).assertIsFocused().assertIsSelected().assert(nowPlaying)
        onNode(row("Second")).assert(!nowPlaying)
        onNode(row("Second")).performClick()
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.PlayQueueItem("2")), commands) }
        state.value = emptyList()
        onNodeWithText(vc.noQueueItems).assertExists()
    }

    /**
     * On a phone on its side the forced track the player picked shows checked and opens in the middle of the list,
     * though seven tracks come before it: brought there by the list itself, not by focus, which a touch screen gives no
     * row (a focused row would only be scrolled to the list's edge). The sync entry after the tracks scrolls with them,
     * not pinned over them.
     */
    @Test
    fun theForcedTrackPlayingIsCheckedAndInTheMiddleOfTheList() = runComposeUiTest {
        val probe = PlayerProbe()
        fun language(id: Long) = TrackItem(id, "Language $id", "SRT", selected = false)
        val subtitles = listOf(TrackItem(null, "Off", null, selected = false)) + (1L..6L).map(::language) +
            TrackItem(9, "English", "Forced · SRT", selected = true, forced = true) + (10L..15L).map(::language)
        player(FormFactor.HANDHELD, probe = probe, size = DpSize(915.dp, 412.dp)) {
            testPlayerState(menu = PlayerMenu.SUBTITLES).copy(subtitleTracks = subtitles)
        }
        mainClock.advanceTimeBy(1_000)
        waitForIdle()
        onNode(row("Forced · SRT")).assertIsSelected()
        val sheet = probe.bounds.getValue("player.menu")
        val forced = probe.bounds.getValue("player.menu.item.7")
        assertTrue(forced.center.y in sheet.top + sheet.height * 0.3f..sheet.top + sheet.height * 0.7f, "the forced track $forced in the middle of $sheet")
        onNode(row(testDelay(subtitles = true).title)).performScrollTo()
        val delay = probe.bounds.getValue("player.menu.delay")
        assertTrue(delay.top >= probe.bounds.getValue("player.menu.item.13").bottom, "the sync entry $delay after the tracks, not over them")
    }

    // Sleep timer

    private val sleepOption = PlayerOption(
        PlayerOptionId.SLEEP_TIMER, T.videoSettings.sleepTimer, T.common.off, adjusted = false, PlayerMenu.SLEEP_TIMER,
        listOf(
            OptionChoice(T.common.off, null, selected = true, PlayerCommand.CancelSleepTimer),
            OptionChoice(T.player.options.sleepEndOfVideo, null, selected = false, PlayerCommand.SleepAtEndOfVideo),
            OptionChoice("15 minutes", null, selected = false, PlayerCommand.SetSleepTimer(15)),
            OptionChoice("30 minutes", null, selected = false, PlayerCommand.SetSleepTimer(30)),
        ),
        on = null, toggle = null,
    )

    /** The end of the video and the durations in one list; a duration starts the timer. */
    @Test
    fun theSleepTimerListsTheEndOfTheVideoAndTheDurations() = runComposeUiTest {
        player(FormFactor.HANDHELD, onCommand = { commands += it }) {
            testPlayerState(menu = PlayerMenu.SLEEP_TIMER).copy(options = listOf(sleepOption))
        }
        onNodeWithText(vc.timerActive).assertDoesNotExist()
        onNode(row("30 minutes")).performClick()
        onNode(row(T.player.options.sleepEndOfVideo)).performClick()
        runOnIdle { assertEquals(listOf(PlayerCommand.SetSleepTimer(30), PlayerCommand.SleepAtEndOfVideo), commands) }
    }

    /** A running timer's banner says when it pauses, adds 15 minutes and cancels; at the end of the video no +15 min. */
    @Test
    fun theActiveSleepTimerExtendsAndCancels() = runComposeUiTest {
        val state = mutableStateOf(SleepTimerBanner("Playback will pause in 12:30", "+15 min"))
        player(FormFactor.HANDHELD, onCommand = { commands += it }) {
            testPlayerState(menu = PlayerMenu.SLEEP_TIMER).copy(options = listOf(sleepOption), sleepTimer = state.value)
        }
        onNodeWithText(vc.timerActive).assertExists()
        onNodeWithText("Playback will pause in 12:30").assertExists()
        onNodeWithText("+15 min").performClick()
        onNodeWithText(T.common.cancel).performClick()
        runOnIdle { assertEquals(listOf(PlayerCommand.ExtendSleepTimer, PlayerCommand.CancelSleepTimer), commands) }
        state.value = SleepTimerBanner(vc.playbackWillPauseAtEnd, extend = null)
        onNodeWithText("+15 min").assertDoesNotExist()
    }
}
