package com.edde746.plezy.ui.player

import androidx.compose.material3.Typography
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.click
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performMouseInput
import androidx.compose.ui.test.runSkikoComposeUiTest
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.createFontFamilyResolver
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.player.ChapterItem
import com.edde746.plezy.presentation.player.InfoRow
import com.edde746.plezy.presentation.player.InfoSection
import com.edde746.plezy.presentation.player.InfoSectionId
import com.edde746.plezy.presentation.player.PlaybackInfoLayout
import com.edde746.plezy.presentation.player.PlaybackInfoState
import com.edde746.plezy.presentation.probeName
import com.edde746.plezy.strings.T
import kotlinx.coroutines.flow.MutableStateFlow
import kotlin.math.roundToInt
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The playback info's card: on and visible (auto-hide takes it with the controls) it covers none of the controls (the
 * top bar, a phone's transport, the timeline, an open desktop menu) and at most a third of the picture, its text keeps
 * its size, no data value in it is cut (only free text, a file's name or a track's title, may end in "…"), and what
 * doesn't fit is left out by whole sections, least useful first; it takes no touch and screen readers pass it by; the
 * frames drawn while it shows reach the store. The card's frame counter asks for every frame, so the clock moves by
 * hand.
 */
@OptIn(ExperimentalTestApi::class)
class PlaybackInfoCardTest {
    private fun test(width: Int = 960, height: Int = 540, block: ComposeUiTest.() -> Unit) =
        runSkikoComposeUiTest(size = Size(width.toFloat(), height.toFloat()), density = Density(1f)) {
            mainClock.autoAdvance = false
            block()
        }

    private fun ComposeUiTest.settle() = mainClock.advanceTimeBy(1_000)

    private val on = PlaybackInfoState(visible = true)

    /** With the controls up, the card covers none of them, on every form factor, and Stream comes first. */
    @Test
    fun theCardCoversNoControl() {
        for (formFactor in listOf(FormFactor.DESKTOP, FormFactor.TV, FormFactor.HANDHELD)) test {
            val probe = PlayerProbe()
            player(formFactor, probe = probe, playbackInfo = MutableStateFlow(remux)) { testPlayerState().copy(playbackInfo = on) }
            settle()
            assertTheRules("$formFactor", probe, 960f, 540f, controlsUp = true, floor = if (formFactor == FormFactor.HANDHELD) 11f else 12f, tv = formFactor == FormFactor.TV)
        }
    }

    /** Without its setting, or faded out with the controls (auto-hide), there is no card and no frames are counted. */
    @Test
    fun hiddenOrOffThereIsNoCardAndNoFramesCounted() = test {
        val probe = PlayerProbe()
        var frames = 0
        var info by mutableStateOf<PlaybackInfoState?>(on)
        player(FormFactor.DESKTOP, probe = probe, playbackInfo = MutableStateFlow(remux), onPlaybackInfoFrame = { frames++ }) {
            testPlayerState().copy(playbackInfo = info)
        }
        mainClock.advanceTimeBy(500)
        assertTrue("player.playbackInfo" in probe.bounds, "the card while shown")
        assertTrue(frames > 0, "no frames heard while shown")

        info = PlaybackInfoState(visible = false)
        settle()
        val counted = frames
        assertTrue("player.playbackInfo" !in probe.bounds, "the card auto-hidden")
        mainClock.advanceTimeBy(500)
        assertEquals(counted, frames, "frames heard while hidden")

        info = null
        mainClock.advanceTimeBy(100)
        assertTrue("player.playbackInfo" !in probe.bounds, "the card without its setting")
    }

    /** A click on the card is a click on the video under it, and no screen reader meets its text. */
    @Test
    fun theCardTakesNoTouchAndScreenReadersPassItBy() = test {
        val probe = PlayerProbe()
        val clicks = mutableListOf<InputEvent.Click>()
        player(FormFactor.DESKTOP, probe = probe, playbackInfo = MutableStateFlow(remux), onInput = { if (it is InputEvent.Click) clicks += it; false }) {
            testPlayerState(episodes = null).copy(controlsVisible = false, playbackInfo = on)
        }
        settle()
        onRoot().performMouseInput { click(probe.bounds.getValue("player.info.video").center) }
        settle()
        assertEquals(1, clicks.size, "the click on the card reached the video")
        // What a screen reader walks: the semantics as merged, where a cleared node's descendants are gone.
        for (text in listOf(T.player.info.title, "Video", "HEVC Main 10")) {
            assertEquals(0, onAllNodesWithText(text).fetchSemanticsNodes().size, "\"$text\" reaches a screen reader")
        }
    }

    /**
     * On a 1920 × 1080 TV (960 × 540 dp), for each of the test matrix's streams, with the controls up or down: the card
     * stays within the safe area and a third of the screen, its text at TV's floor, the sections it leaves out the
     * least useful ones. Before, three columns across the safe area covered three quarters of the picture.
     */
    @Test
    fun onTvTheCardKeepsToAThirdOfTheScreenAtItsFloorSize() = test {
        val probe = PlayerProbe()
        val flow = MutableStateFlow(remux)
        var controls by mutableStateOf(false)
        player(FormFactor.TV, probe = probe, playbackInfo = flow) {
            testPlayerState(episodes = null).copy(controlsVisible = controls, playbackInfo = on)
        }
        for (up in listOf(false, true)) {
            controls = up
            for ((name, shown) in matrix + ("hdr10-atmos" to remux)) {
                flow.value = shown
                settle()
                val case = "$name, controls ${if (up) "up" else "down"}"
                assertTheRules(case, probe, 960f, 540f, controlsUp = up, floor = 11f, sections = shown, tv = true)
                val card = probe.bounds.getValue("player.playbackInfo")
                assertTrue(card.left >= 48f - 0.5f && card.right <= 960f - 48f + 0.5f, "$case: the card $card within the safe area")
            }
        }
    }

    /** Live values change in place: a bitrate, a dropped-frame count and the download speed growing a digit move nothing. */
    @Test
    fun liveValuesMoveNothingElse() = test(1266, 743) {
        val probe = PlayerProbe()
        val flow = MutableStateFlow(remux)
        player(FormFactor.DESKTOP, probe = probe, size = DpSize(1266.dp, 743.dp), playbackInfo = flow) {
            testPlayerState(episodes = null).copy(controlsVisible = false, playbackInfo = on)
        }
        settle()
        val names = (listOf("player.playbackInfo") + remux.map { "player.info.${it.id.probeName}" }).filter { it in probe.bounds }
        assertTrue("player.info.buffer" in names, "the buffer shows on the desktop: $names")
        val before = names.associateWith { probe.bounds.getValue(it) }
        flow.value = remuxSections(videoBitrate = "102.4 Mb/s", dropped = "12 (decoder 3)", speed = "112.5 MB/s")
        settle()
        for (name in names) assertEquals(before.getValue(name), probe.bounds.getValue(name), "$name moved")
    }

    /**
     * On a phone playing an episode with chapters (the bottom bar's hint to the chapters and queue page over the
     * timeline, in the middle): upright (411 × 915), above the transport, under the top bar, Stream and Video at the
     * phone's floor. On its side (915 × 411, and a short one, 731 × 411, where the room beside the transport is under
     * 200 dp and the card had none) and on the Fold's cover screen (872 × 320, where the top bar's margin under its
     * buttons and the hint's height across the whole width left too little beside the transport): beside the transport,
     * Stream alone with the controls up, its file's name cut short but none of its figures. With them down, more on a
     * phone; on the cover, where a third of the screen holds Stream and Video only in a column narrower than Video's 4K
     * output line needs, Stream still.
     */
    @Test
    fun onAPhoneTheCardKeepsClearOfTheTransportAtItsFloorSize() {
        test(411, 915) {
            val probe = PlayerProbe()
            player(FormFactor.HANDHELD, probe = probe, size = DpSize(411.dp, 915.dp), playbackInfo = MutableStateFlow(remux)) {
                testPlayerState().copy(playbackInfo = on, chapters = chapters)
            }
            settle()
            val shown = assertTheRules("upright", probe, 411f, 915f, controlsUp = true, floor = 11f)
            assertEquals(listOf(InfoSectionId.STREAM, InfoSectionId.VIDEO), shown)
        }
        for ((width, height, more) in listOf(Triple(915, 411, true), Triple(731, 411, true), Triple(872, 320, false))) test(width, height) {
            val probe = PlayerProbe()
            var controls by mutableStateOf(true)
            player(FormFactor.HANDHELD, probe = probe, size = DpSize(width.dp, height.dp), playbackInfo = MutableStateFlow(remux)) {
                testPlayerState().copy(controlsVisible = controls, playbackInfo = on, chapters = chapters)
            }
            settle()
            val case = "$width × $height on its side"
            assertTrue("player.strip" in probe.bounds, "$case: the chapters hint shows")
            val up = assertTheRules("$case, controls up", probe, width.toFloat(), height.toFloat(), controlsUp = true, floor = 11f)
            assertEquals(listOf(InfoSectionId.STREAM), up, case)
            val stream = probe.bounds.getValue("player.info.stream")
            assertTrue(probe.bounds.getValue("player.back").bottom <= stream.top, "$case: Stream $stream under Back")
            assertTrue(textWidth(remux.first().rows.first().value) > stream.width, "$case: the file's name is longer than its column, and cut")
            controls = false
            settle()
            val down = assertTheRules("$case, controls down", probe, width.toFloat(), height.toFloat(), controlsUp = false, floor = 11f)
            if (more) assertTrue(down.size > up.size, "$case: more with the controls down: $down") else assertEquals(up, down, case)
        }
    }

    private val chapters = listOf(
        ChapterItem("Opening", "0:00", null, current = true, command = PlayerCommand.SeekToChapter(0)),
        ChapterItem("The Reactor", "12:30", null, current = false, command = PlayerCommand.SeekToChapter(1)),
    )

    /**
     * On the desktop an open menu moves the card clear of it (the options menu covered part of it), in a wide window and
     * in a narrow one, where beside the menu the column narrows only as far as its figures read whole: fewer sections
     * there rather than every figure cut short ("213 kb…").
     */
    @Test
    fun onTheDesktopTheCardMovesClearOfAnOpenMenu() {
        for ((width, height) in listOf(1266 to 743, 640 to 720)) test(width, height) {
            val probe = PlayerProbe()
            var menu by mutableStateOf<PlayerMenu?>(null)
            player(FormFactor.DESKTOP, probe = probe, size = DpSize(width.dp, height.dp), playbackInfo = MutableStateFlow(remux)) {
                testPlayerState(menu = menu).copy(playbackInfo = on)
            }
            settle()
            val alone = probe.bounds.getValue("player.playbackInfo")
            val all = assertTheRules("$width × $height", probe, width.toFloat(), height.toFloat(), controlsUp = true, floor = 12f)
            menu = PlayerMenu.OPTIONS
            settle()
            val case = "$width × $height, menu open"
            val card = probe.bounds.getValue("player.playbackInfo")
            val rows = probe.bounds.filterKeys { it.startsWith("player.option.") }
            assertTrue(rows.isNotEmpty(), "$case: the options menu is open")
            for ((name, row) in rows) assertTrue(!card.overlaps(row), "$case: the card $card over the menu's $name $row")
            assertTrue(card != alone, "$case: the card moved: $alone")
            val beside = assertTheRules(case, probe, width.toFloat(), height.toFloat(), controlsUp = true, floor = 12f)
            if (width < 1000) assertTrue(beside.size < all.size, "$case: fewer sections beside the menu than $all: $beside")
        }
    }

    /**
     * Where no room clear of an open menu holds even Stream (a window 420 × 400, the options menu up to its top and all
     * but 20 dp of its width), there is no card rather than one over the menu; it comes back as the menu closes.
     */
    @Test
    fun withNoRoomBesideAnOpenMenuThereIsNoCard() = test(420, 400) {
        val probe = PlayerProbe()
        var menu by mutableStateOf<PlayerMenu?>(null)
        player(FormFactor.DESKTOP, probe = probe, size = DpSize(420.dp, 400.dp), playbackInfo = MutableStateFlow(remux)) {
            testPlayerState(menu = menu).copy(playbackInfo = on)
        }
        settle()
        assertTheRules("420 × 400", probe, 420f, 400f, controlsUp = true, floor = 12f)
        menu = PlayerMenu.OPTIONS
        settle()
        assertTrue(probe.bounds.keys.any { it.startsWith("player.option.") }, "the options menu is open")
        assertTrue("player.playbackInfo" !in probe.bounds, "a card with the menu open: ${probe.bounds["player.playbackInfo"]}")
        menu = null
        settle()
        assertTheRules("420 × 400, menu closed", probe, 420f, 400f, controlsUp = true, floor = 12f)
    }

    /**
     * The rules every card keeps, from its probes: within the player and a third of it, clear of the top bar, the
     * transport and the timeline (with the controls up), its sections whole inside it and their rows at least [floor]
     * sp tall in text (the card is never scaled), no data value cut (beside its column's labels, as wide as the longest
     * to 140 dp, and the gap between, 10 dp on [tv] and 12 elsewhere, each figure reads whole), and the sections shown
     * the first ones of [PlaybackInfoLayout.PRIORITY] among [sections]. Returns the sections shown, in order.
     */
    private fun assertTheRules(
        case: String,
        probe: PlayerProbe,
        width: Float,
        height: Float,
        controlsUp: Boolean,
        floor: Float,
        sections: List<InfoSection> = remux,
        tv: Boolean = false,
    ): List<InfoSectionId> {
        val card = probe.bounds.getValue("player.playbackInfo")
        assertTrue(card.left >= 0f && card.top >= 0f && card.right <= width && card.bottom <= height, "$case: the card $card within the player")
        assertTrue(card.width * card.height <= width * height / 3 + 1f, "$case: the card $card covers over a third of $width × $height")
        if (controlsUp) {
            val controls = listOf(
                "player.back", "player.title", "player.scrub", "player.position", "player.previous", "player.playPause", "player.next", "player.strip",
            )
            for (name in controls) {
                val control = probe.bounds[name] ?: continue
                assertTrue(!card.overlaps(control), "$case: the card $card over $name $control")
            }
        }
        val shown = sections.filter { "player.info.${it.id.probeName}" in probe.bounds }
        for (section in shown) {
            val bounds = probe.bounds.getValue("player.info.${section.id.probeName}")
            assertTrue(
                bounds.left >= card.left - 0.5f && bounds.top >= card.top - 0.5f && bounds.right <= card.right + 0.5f && bounds.bottom <= card.bottom + 0.5f,
                "$case: ${section.id} at $bounds whole inside the card $card",
            )
            // A line of text is about 1.2 times its size: each row and the heading a line at least.
            assertTrue(bounds.height >= (section.rows.size + 1) * floor * 1.2f, "$case: ${section.id} at $bounds, its text under $floor sp")
        }
        val columns = shown.groupBy { probe.bounds.getValue("player.info.${it.id.probeName}").left.roundToInt() }.values
        for (column in columns) {
            val labels = minOf(column.flatMap { it.rows }.maxOf { textWidth(it.label) }, 140f)
            for (section in column) {
                val room = probe.bounds.getValue("player.info.${section.id.probeName}").width - labels - (if (tv) 10f else 12f)
                for (row in section.rows.filterNot { it.freeText }) {
                    assertTrue(textWidth(row.value) <= room + 0.5f, "$case: ${section.id}'s ${row.label} \"${row.value}\" cut to $room dp")
                }
            }
        }
        val ranked = sections.sortedBy { PlaybackInfoLayout.PRIORITY.indexOf(it.id) }.map { it.id }
        assertEquals(ranked.take(shown.size).toSet(), shown.map { it.id }.toSet(), "$case: the sections kept are the most useful")
        assertTrue(shown.first().id == InfoSectionId.STREAM, "$case: Stream first")
        return shown.map { it.id }
    }

    private val measurer = TextMeasurer(createFontFamilyResolver(), Density(1f), LayoutDirection.Ltr)

    /** [text]'s width in the card's rows' style (the body's small size, digits of one width), in dp at density 1. */
    private fun textWidth(text: String): Float =
        measurer.measure(text, Typography().bodySmall.merge(TextStyle(fontFeatureSettings = "tnum")), softWrap = false, maxLines = 1).size.width.toFloat()

    private val remux = remuxSections("48.5 Mb/s", "0 (decoder 0)", "12.3 MB/s")

    /** The info of an HEVC HDR10 remux with TrueHD Atmos playing on an Android TV, as the store lays it out. */
    private fun remuxSections(videoBitrate: String, dropped: String, speed: String) = listOf(
        section(
            InfoSectionId.STREAM, "Stream",
            "File" to "Movie.2160p.UHD.BluRay.REMUX.HDR.HEVC.TrueHD.7.1.Atmos.mkv", "Container" to "MKV", "Size" to "58.3 GB",
            "Bitrate" to "62.6 Mb/s",
        ),
        section(
            InfoSectionId.VIDEO, "Video",
            "Codec" to "HEVC Main 10", "Resolution" to "3840×2160 · 23.976 fps", "Dynamic range" to "HDR10", "Bitrate" to videoBitrate,
            "Decoder" to "Hardware (MediaCodec)", "Aspect" to "16:9", "Output" to "3840×2160 · 23.976 Hz · HDR10",
        ),
        section(InfoSectionId.COLOR, "Color", "Pixel format" to "10-bit", "Primaries" to "BT.2020", "Transfer" to "PQ", "Matrix" to "BT.2020 NCL"),
        section(InfoSectionId.HDR, "HDR", "Mastering display" to "0.005–1,000 nits", "MaxCLL / MaxFALL" to "1,000 / 400 nits"),
        section(
            InfoSectionId.AUDIO, "Audio",
            "Codec" to "TrueHD Atmos", "Channels" to "7.1", "Sample rate" to "48 kHz", "Bitrate" to "4.2 Mb/s",
            "Track" to "English · TrueHD Atmos 7.1", "Output" to "AudioTrack · Passthrough (TrueHD)",
        ),
        section(InfoSectionId.SUBTITLES, "Subtitles", "Track" to "English", "Format" to "PGS · Embedded"),
        section(
            InfoSectionId.PERFORMANCE, "Performance",
            "Render FPS" to "23.98", "A/V sync" to "−12 ms", "Dropped frames" to dropped, "Delayed frames" to "0", "UI FPS" to "60.0",
        ),
        section(InfoSectionId.APP, "App", "Play method" to "Direct Play", "Memory" to "412 MB"),
        section(InfoSectionId.BUFFER, "Buffer", "Cache" to "42 s · 240 MB", "Cache limit" to "96 MB", "Download speed" to speed),
    )

    /**
     * The test matrix's streams (tools/media: the HDR10 remux with TrueHD, Dolby Vision 8.1, DTS-HD MA 7.1) as the
     * Android TV emulator shows their info: the longest values the card meets there ("English · English - TrueHD 5.1",
     * the Dolby Vision stream's 45-character audio track title).
     */
    private val matrix = mapOf(
        "dv8" to listOf(
            section(InfoSectionId.STREAM, "Stream", "File" to "dv-p81.mkv", "Container" to "MKV", "Size" to "1.8 MB", "Bitrate" to "753 kb/s"),
            section(
                InfoSectionId.VIDEO, "Video",
                "Codec" to "HEVC Main 10", "Resolution" to "3840×2160 · 23.976 fps", "Dynamic range" to "Dolby Vision profile 8",
                "Bitrate" to "559 kb/s", "Decoder" to "Software", "Dolby Vision path" to "HDR10 base layer", "Output" to "1920×1080 · 60 Hz · SDR",
            ),
            section(InfoSectionId.COLOR, "Color", "Pixel format" to "10-bit · 4:2:0", "Primaries" to "BT.2020", "Transfer" to "PQ", "Matrix" to "Dolby Vision"),
            section(InfoSectionId.HDR, "HDR", "Mastering display" to "0.0001–1,001 nits", "MaxCLL / MaxFALL" to "1,000 / 41 nits"),
            section(
                InfoSectionId.AUDIO, "Audio",
                "Codec" to "AAC LC", "Channels" to "Stereo", "Sample rate" to "48 kHz", "Bitrate" to "192 kb/s",
                "Track" to "English · AAC 2.0 - tones L 440 Hz, R 660 Hz", "Output" to "AudioTrack",
            ),
            section(
                InfoSectionId.PERFORMANCE, "Performance",
                "Render FPS" to "23.98", "A/V sync" to "0 ms", "Dropped frames" to "220 (decoder 0)", "Delayed frames" to "0", "UI FPS" to "59.9",
            ),
            section(InfoSectionId.APP, "App", "Play method" to "Direct Play", "Memory" to "388 MB"),
            section(InfoSectionId.BUFFER, "Buffer", "Cache" to "5 s · 773 KB", "Cache limit" to "150 MB", "Download speed" to "0 B/s"),
        ),
        "dts" to listOf(
            section(InfoSectionId.STREAM, "Stream", "File" to "dts-hdma.mkv", "Container" to "MKV", "Size" to "5.1 MB", "Bitrate" to "4.3 Mb/s"),
            section(
                InfoSectionId.VIDEO, "Video",
                "Codec" to "H.264 High", "Resolution" to "1920×1080 · 23.976 fps", "Dynamic range" to "SDR", "Bitrate" to "271 kb/s",
                "Decoder" to "Hardware (MediaCodec)", "Output" to "1920×1080 · 60 Hz · SDR",
            ),
            section(InfoSectionId.COLOR, "Color", "Pixel format" to "8-bit · 4:2:0", "Primaries" to "BT.709", "Transfer" to "BT.1886", "Matrix" to "BT.709"),
            section(
                InfoSectionId.AUDIO, "Audio",
                "Codec" to "DTS-HD MA", "Channels" to "7.1", "Sample rate" to "48 kHz", "Bitrate" to "5.0 Mb/s",
                "Track" to "English · English - TrueHD 5.1", "Output" to "AudioTrack",
            ),
            section(
                InfoSectionId.PERFORMANCE, "Performance",
                "Render FPS" to "23.98", "A/V sync" to "+3 ms", "Dropped frames" to "17 (decoder 0)", "Delayed frames" to "0", "UI FPS" to "60.0",
            ),
            section(InfoSectionId.APP, "App", "Play method" to "Transcoding", "Memory" to "301 MB"),
            section(InfoSectionId.BUFFER, "Buffer", "Cache" to "6 s · 3.7 MB", "Cache limit" to "150 MB", "Download speed" to "0 B/s"),
        ),
    )

    /** A section of [rows]; a file's name, a track's title and the audio output are free text, as the store marks them. */
    private fun section(id: InfoSectionId, title: String, vararg rows: Pair<String, String>) = InfoSection(
        id,
        title,
        rows.map { (label, value) -> InfoRow(label, value, freeText = label == "File" || label == "Track" || (id == InfoSectionId.AUDIO && label == "Output")) },
    )
}
