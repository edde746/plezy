package com.edde746.plezy.media

import com.edde746.plezy.presentation.player.NowPlaying
import com.edde746.plezy.presentation.player.NowPlayingKind
import com.edde746.plezy.presentation.player.NowPlayingStatus
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals

/** What the media notification shows of the playback: a seek posts it again only where it shows the position. */
class PlaybackNotificationTest {
    private fun now(status: NowPlayingStatus, position: Double, rate: Double = 1.0, kind: NowPlayingKind = NowPlayingKind.VIDEO) = NowPlaying(
        title = "Codec Numbered Chapters",
        subtitle = null,
        artworkUrl = "http://server/art.jpg",
        durationSeconds = 420.0,
        positionSeconds = position,
        rate = rate,
        status = status,
        canSeek = true,
        canSkipNext = false,
        canSkipPrevious = false,
        live = false,
        kind = kind,
    )

    private fun content(now: NowPlaying) = PlaybackNotification.content(now)

    @Test
    fun aPausedVideoShowsTheSameWhereverItIsPaused() {
        assertEquals(content(now(NowPlayingStatus.PAUSED, 11.4)), content(now(NowPlayingStatus.PAUSED, 21.4)))
    }

    @Test
    fun aBufferingVideoShowsTheSameWhereverItWaits() {
        assertEquals(content(now(NowPlayingStatus.BUFFERING, 11.4)), content(now(NowPlayingStatus.BUFFERING, 21.4)))
    }

    @Test
    fun aVideoPlayingAtNormalSpeedShowsItsTimePlayed() {
        assertNotEquals(content(now(NowPlayingStatus.PLAYING, 11.4)), content(now(NowPlayingStatus.PLAYING, 21.4)))
    }

    @Test
    fun aVideoPlayingAtAnotherSpeedShowsNoTimePlayed() {
        assertEquals(content(now(NowPlayingStatus.PLAYING, 11.4, rate = 1.5)), content(now(NowPlayingStatus.PLAYING, 21.4, rate = 1.5)))
    }

    @Test
    fun musicShowsNoPosition() {
        val kind = NowPlayingKind.MUSIC
        assertEquals(content(now(NowPlayingStatus.PLAYING, 11.4, kind = kind)), content(now(NowPlayingStatus.PLAYING, 21.4, kind = kind)))
    }

    @Test
    fun pausingChangesWhatItShows() {
        assertNotEquals(content(now(NowPlayingStatus.PLAYING, 11.4)), content(now(NowPlayingStatus.PAUSED, 11.4)))
    }
}
