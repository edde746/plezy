package com.edde746.plezy.watch

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind as ItemKind
import com.edde746.plezy.model.MediaVersion
import party.openwatch.EndReason
import party.openwatch.Media
import party.openwatch.MediaKind
import party.openwatch.Series
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class WatchLabelsTest {
    private fun version(name: String? = null) = MediaVersion(id = "v1", height = 1080, videoCodec = "h264", container = "mkv", name = name)

    private val bigTrouble = MediaItem(
        id = "bt", backend = BackendKind.JELLYFIN, kind = ItemKind.MOVIE, title = "Big Trouble", year = 2002,
        serverId = "jf", serverName = "jf-test", durationMs = 5_106_528,
    )

    @Test
    fun dropsAVersionNameThatOnlyRestatesTheTitleWithOrWithoutItsYear() {
        val technical = version().displayLabel
        for (name in listOf("Big Trouble", "big trouble", "Big Trouble (2002)", "Big.Trouble.2002")) {
            assertEquals(technical, WatchLabels.versionLabel(bigTrouble, version(name)), name)
        }
    }

    @Test
    fun keepsANameThatTellsVersionsApartOrThatIsntQuiteTheTitle() {
        for (name in listOf("Director's Cut", "Big Trouble Extended", "Big Trouble (1986)")) {
            assertEquals(version(name).displayLabel, WatchLabels.versionLabel(bigTrouble, version(name)), name)
        }
    }

    @Test
    fun isNullWithoutAVersionOrWhenTheTitleWasAllTheVersionSaid() {
        assertNull(WatchLabels.versionLabel(bigTrouble, null))
        assertNull(WatchLabels.versionLabel(bigTrouble, MediaVersion(id = "v1", name = "Big Trouble")))
    }

    @Test
    fun aCopysDetailsGiveItsVersionServerAndLengthWithoutTheTitleAgain() {
        val copy = WatchCopy.of(bigTrouble, version("Big Trouble (2002)"))

        val details = WatchLabels.copyDetails(copy)

        assertEquals("${version().displayLabel} · jf-test · 1h 25m", details)
        assertFalse("Big Trouble" in details)
        assertTrue("Big Trouble" in WatchLabels.copyTitle(copy))
    }

    @Test
    fun lengthDifferenceSaysUnknownSameLongerOrShorter() {
        assertEquals("Length unknown", WatchLabels.lengthDifference(null))
        assertEquals("Same length", WatchLabels.lengthDifference(-999))
        assertEquals("2m longer", WatchLabels.lengthDifference(120_000))
        assertEquals("1h 1m shorter", WatchLabels.lengthDifference(-3_660_000))
        assertEquals("5s longer", WatchLabels.lengthDifference(5_400))
    }

    @Test
    fun theRoomsMediaInOneLine() {
        assertEquals("Alien (1979)", WatchLabels.mediaTitle(Media(MediaKind.MOVIE, "Alien", 1, year = 1979)))
        assertEquals("Clip", WatchLabels.mediaTitle(Media(MediaKind.VIDEO, "Clip", 1)))
        val episode = Media(MediaKind.EPISODE, "Half Loop", 1, series = Series("Severance"), season = 1, episode = 2)
        assertEquals("Severance · S1 E2 · Half Loop", WatchLabels.mediaTitle(episode))
        assertEquals("Severance · S1 E2", WatchLabels.mediaTitle(episode.copy(title = "Severance")))
    }

    @Test
    fun errorCodesGetTheirTextUnknownOnesTheGenericText() {
        assertEquals("That room is full.", WatchLabels.errorText("room_full"))
        assertEquals("No room has that code. It may have ended.", WatchLabels.errorText("room_not_found"))
        assertEquals(WatchLabels.errorText("something_new"), WatchLabels.errorText("teapot"))
    }

    @Test
    fun noticesNameWhoActedOrTheRoom() {
        assertEquals("Ann pressed play", WatchLabels.noticeText(WatchNotice.Action("play", "Ann")))
        assertEquals("Playback started", WatchLabels.noticeText(WatchNotice.Action("play")))
        assertEquals("Ann jumped to 1:01:05", WatchLabels.noticeText(WatchNotice.Action("seek", "Ann", positionMs = 3_665_000)))
        assertEquals("Speed set to 1.25x", WatchLabels.noticeText(WatchNotice.Action("rate", rate = 1.25)))
        assertEquals("Ann started Alien (1979)", WatchLabels.noticeText(WatchNotice.Action("media", "Ann"), media = Media(MediaKind.MOVIE, "Alien", 1, year = 1979)))
        assertEquals("The video stopped", WatchLabels.noticeText(WatchNotice.Action("media")))
        assertNull(WatchLabels.noticeText(WatchNotice.Action("host")), "a host change without a host")
        assertNull(WatchLabels.noticeText(WatchNotice.Action("dance", "Ann")))
        assertEquals("That room is full.", WatchLabels.noticeText(WatchNotice.Refused("room_full")))
        assertEquals("You were removed from the room", WatchLabels.noticeText(WatchNotice.Ended(EndReason.KICKED)))
        assertNull(WatchLabels.noticeText(WatchNotice.Ended(EndReason.LEFT)), "the user's own leave says nothing")
    }

    @Test
    fun offsetsAndRatesAsTheControlsShowThem() {
        assertEquals("+200ms", WatchLabels.offsetText(200))
        assertEquals("-1500ms", WatchLabels.offsetText(-1500))
        assertEquals("+15.1s", WatchLabels.offsetText(15_100))
        assertEquals("2x", WatchLabels.rateText(2.0))
        assertEquals("0.5x", WatchLabels.rateText(0.5))
        assertEquals("Plezy", WatchLabels.clientApp("Plezy/2.23.0"))
    }

    @Test
    fun aParticipantsAppIsItsClientUpToTheFirstSlash() {
        assertEquals("Infuse", WatchLabels.clientApp("Infuse/0.9"))
        assertEquals("Plezy", WatchLabels.clientApp("Plezy/1.2.3/beta"))
        assertEquals("Kodi Addon", WatchLabels.clientApp("Kodi Addon"), "a client without a slash shows whole")
    }
}
