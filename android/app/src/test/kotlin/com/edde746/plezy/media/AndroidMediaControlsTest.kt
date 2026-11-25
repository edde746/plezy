package com.edde746.plezy.media

import android.app.Application
import android.media.AudioManager
import android.media.MediaMetadata
import android.media.session.MediaSession
import android.os.Handler
import com.edde746.plezy.presentation.player.MediaCommand
import com.edde746.plezy.presentation.player.MediaCommandHandler
import com.edde746.plezy.presentation.player.NowPlaying
import com.edde746.plezy.presentation.player.NowPlayingKind
import com.edde746.plezy.presentation.player.NowPlayingStatus
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.Implementation
import org.robolectric.annotation.Implements
import org.robolectric.shadows.ShadowMediaSession
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * What the OS media controls hand the system, which every controller of the session (other apps among them) reads, and
 * when the music takes and gives up the audio.
 */
@RunWith(RobolectricTestRunner::class)
@Config(shadows = [AndroidMediaControlsTest.RecordingMediaSession::class])
class AndroidMediaControlsTest {
    /** The session's metadata and callback as they go to the system. */
    @Implements(MediaSession::class)
    class RecordingMediaSession : ShadowMediaSession() {
        @Implementation
        protected fun setMetadata(metadata: MediaMetadata?) {
            published = metadata
        }

        @Implementation
        protected fun setCallback(callback: MediaSession.Callback?, handler: Handler?) {
            Companion.callback = callback
        }

        companion object {
            var published: MediaMetadata? = null
            var callback: MediaSession.Callback? = null
        }
    }

    private val context: Application = RuntimeEnvironment.getApplication()
    private val controls = AndroidMediaControls(context, television = false)
    private val commands = mutableListOf<MediaCommand>()
    private val handler = object : MediaCommandHandler {
        override fun perform(command: MediaCommand) {
            commands += command
        }
    }

    private fun track(status: NowPlayingStatus) = NowPlaying(
        title = "Track",
        subtitle = "Artist",
        artworkUrl = "https://server.example/photo/:/transcode?url=%2Fthumb&X-Plex-Token=secret",
        durationSeconds = 200.0,
        positionSeconds = 12.0,
        rate = 1.0,
        status = status,
        canSeek = true,
        canSkipNext = true,
        canSkipPrevious = false,
        live = false,
        kind = NowPlayingKind.MUSIC,
        album = "Album",
        backgroundPlayback = true,
    )

    private val audio get() = shadowOf(context.getSystemService(AudioManager::class.java))

    /** Background music playing: its service comes up as Android starts it. */
    private fun playInTheBackground(): PlaybackService {
        controls.show(track(NowPlayingStatus.PLAYING), handler)
        val start = assertNotNull(shadowOf(context).nextStartedService)
        assertEquals(PlaybackService::class.java.name, start.component?.className)
        assertNull(audio.lastAudioFocusRequest, "audio focus asked for before the service is in the foreground")
        val service = Robolectric.buildService(PlaybackService::class.java).get()
        controls.attach(service)
        return service
    }

    @Before
    fun forgetMetadata() {
        RecordingMediaSession.published = null
        RecordingMediaSession.callback = null
    }

    @After
    fun hide() = controls.hide()

    @Test
    fun theSessionsMetadataCarriesNoArtworkUrl() {
        controls.show(track(NowPlayingStatus.PLAYING), handler)

        val metadata = assertNotNull(RecordingMediaSession.published)
        val texts = metadata.keySet().mapNotNull { metadata.getText(it)?.toString() }
        assertTrue("Track" in texts, "metadata: $texts")
        assertFalse(texts.any { "secret" in it || "server.example" in it }, "metadata: $texts")
    }

    @Test
    fun aVideosFastForwardAndRewindGoByThePlayersSeekStep() {
        val video = track(NowPlayingStatus.PLAYING).copy(kind = NowPlayingKind.VIDEO, album = null, backgroundPlayback = false, canSkip = true, skipSeconds = 15.0)
        controls.show(video, handler)
        val callback = assertNotNull(RecordingMediaSession.callback)

        callback.onFastForward()
        callback.onRewind()
        assertEquals(listOf<MediaCommand>(MediaCommand.SeekBy(15.0), MediaCommand.SeekBy(-15.0)), commands)
    }

    @Test
    fun backgroundMusicTakesTheAudioFocusOnceItsServiceIsInTheForeground() {
        val service = playInTheBackground()

        assertNotNull(shadowOf(service).lastForegroundNotification)
        assertNotNull(audio.lastAudioFocusRequest)
        assertEquals(emptyList(), commands)
    }

    @Test
    fun musicThatLosesTheAudioForGoodPausesAndStaysPaused() {
        playInTheBackground()
        val focus = assertNotNull(audio.lastAudioFocusRequest).listener

        focus.onAudioFocusChange(AudioManager.AUDIOFOCUS_LOSS)
        assertEquals(listOf<MediaCommand>(MediaCommand.SystemPause), commands)
        assertNotNull(audio.lastAbandonedAudioFocusRequest)

        focus.onAudioFocusChange(AudioManager.AUDIOFOCUS_GAIN)
        assertEquals(listOf<MediaCommand>(MediaCommand.SystemPause), commands)
    }
}
