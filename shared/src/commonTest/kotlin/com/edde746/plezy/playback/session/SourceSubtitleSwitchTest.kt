package com.edde746.plezy.playback.session

import com.edde746.plezy.backend.PlaybackSubtitleSidecar
import com.edde746.plezy.backend.SubtitleSidecar
import com.edde746.plezy.model.MediaSubtitleTrack
import com.edde746.plezy.playback.TrackKind
import io.ktor.client.engine.mock.respond
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull

private val english = MediaSubtitleTrack(id = 11, index = 2, codec = "subrip", language = "English", languageCode = "en", title = "English", selected = false, forced = false)
private val french = MediaSubtitleTrack(
    id = 12, codec = "srt", language = "Français", languageCode = "fr", title = "Français", selected = false, forced = false,
    key = "/library/streams/12", external = true,
)
private const val FRENCH_URL = "https://srv/library/streams/12.srt?encoding=utf-8"

/**
 * A Plex movie with an embedded English (stream 11) and an external French (12) subtitle, [burned] the English one
 * selected; the server serves the French file.
 */
internal fun TestScope.subtitleRig(transcoding: Boolean, burned: Boolean = false) = SessionRig(this).apply {
    subtitleServer = { respond("1\n00:00:01,000 --> 00:00:02,000\nBonjour\n") }
    backend.initialize = { options ->
        val stream = SessionBackend.streamOf(options)
        stream.copy(
            isTranscoding = transcoding,
            mediaInfo = stream.mediaInfo?.copy(subtitleTracks = listOf(english.copy(selected = burned), french)),
            subtitleSidecars = listOf(PlaybackSubtitleSidecar(12, SubtitleSidecar(FRENCH_URL, "Français", "fr", "srt"), preload = true)),
        )
    }
    engine.fileTracks = listOf(track(1, TrackKind.AUDIO, "en", "English", selected = true))
}

/** The engine lists the French sidecar the open added (the last file it got), as engine track 2. */
internal fun TestScope.listSidecar(rig: SessionRig) {
    val french = track(2, TrackKind.SUBTITLE, "fr", "Français", external = true, codec = "subrip").copy(externalFilename = rig.engine.addedSubtitles.last().first)
    rig.engine.report { s -> s.copy(tracks = s.tracks + french) }
    runCurrent()
}

/** The server subtitle shown, as [SessionInfo.sourceSubtitles] marks it. */
internal fun SessionRig.shownSourceSubtitle(): Int? = session.info.value.sourceSubtitles.singleOrNull { it.selected }?.id

/** A pick among the server's subtitles: selected in the engine where it can be, else reloaded with it. */
class SourceSubtitleSwitchTest {
    private fun TestScope.rig(transcoding: Boolean, burned: Boolean = false) = subtitleRig(transcoding, burned)

    @Test
    fun aListedSidecarIsSelectedInPlaceAndOffToo() = runTest {
        with(rig(transcoding = true)) {
            play(movie())
            open(600.0)
            listSidecar(this)

            session.selectSourceTrack(TrackKind.SUBTITLE, 12)
            idle()
            assertEquals(TrackKind.SUBTITLE to 2L, engine.selections.last())
            assertEquals(12, shownSourceSubtitle())
            assertEquals(1, backend.initializations.size, "a sidecar the engine has needs no reload")

            session.selectSourceTrack(TrackKind.SUBTITLE, null)
            idle()
            assertEquals(TrackKind.SUBTITLE to null, engine.selections.last())
            assertNull(shownSourceSubtitle())
            assertEquals(1, backend.initializations.size)
        }
    }

    @Test
    fun theTickFollowsTheSessionsPickNotTheServersSelectedFlag() = runTest {
        with(rig(transcoding = true, burned = true)) {
            play(movie())
            open(600.0)
            listSidecar(this)
            session.selectSourceTrack(TrackKind.SUBTITLE, 12)
            idle()
            assertEquals(12, shownSourceSubtitle(), "the server still says English")
            session.selectSourceTrack(TrackKind.SUBTITLE, null)
            idle()
            assertEquals(emptyList(), session.info.value.sourceSubtitles.filter { it.selected })
        }
        with(rig(transcoding = false, burned = true)) {
            play(movie())
            open(600.0)
            assertEquals(emptyList(), session.info.value.sourceSubtitles, "the engine's own tracks are the choice")
        }
    }

    @Test
    fun theSameChoiceAgainReloadsNothing() = runTest {
        with(rig(transcoding = true)) {
            play(movie())
            open(600.0)
            listSidecar(this)
            session.selectSourceTrack(TrackKind.SUBTITLE, 12)
            idle()

            session.selectSourceTrack(TrackKind.SUBTITLE, 12)
            idle()
            assertEquals(1, backend.initializations.size)
            assertEquals(1, engine.loads.size)
            assertEquals(12, shownSourceSubtitle())
            assertEquals(TrackKind.SUBTITLE to 2L, engine.selections.last())
        }
    }

    @Test
    fun anEmbeddedTargetOnATranscodeReloadsToBurnItIn() = runTest {
        with(rig(transcoding = true)) {
            play(movie())
            open(600.0)
            at(42.0)

            session.selectSourceTrack(TrackKind.SUBTITLE, 11)
            idle()
            assertEquals(2, backend.initializations.size)
            assertEquals(2, engine.loads.size)
            assertEquals(42.0, engine.loads.last().startSeconds)
            open(600.0)
            assertEquals(11, shownSourceSubtitle())
        }
    }

    @Test
    fun aBurnedSubtitleReloadsForAnyOtherChoiceButNotForItself() = runTest {
        with(rig(transcoding = true, burned = true)) {
            play(movie())
            open(600.0)
            listSidecar(this)
            assertEquals(11, shownSourceSubtitle())

            session.selectSourceTrack(TrackKind.SUBTITLE, 11)
            idle()
            assertEquals(1, backend.initializations.size, "the burned subtitle again is unchanged")

            session.selectSourceTrack(TrackKind.SUBTITLE, 12)
            idle()
            assertEquals(2, backend.initializations.size, "burned pixels can't be swapped for a sidecar in place")
        }
    }

    @Test
    fun aDirectPlaySelectsTheFilesOwnTrackInPlace() = runTest {
        with(rig(transcoding = false)) {
            engine.fileTracks = engine.fileTracks + track(1, TrackKind.SUBTITLE, "en", "English", codec = "subrip")
            play(movie())
            open(600.0)

            session.selectSourceTrack(TrackKind.SUBTITLE, 11)
            idle()
            assertEquals(TrackKind.SUBTITLE to 1L, engine.selections.last())
            assertEquals(1, backend.initializations.size)
        }
    }

    @Test
    fun aSidecarNotListedYetIsSelectedOnceTheEngineListsIt() = runTest {
        with(rig(transcoding = true)) {
            play(movie())
            open(600.0)

            session.selectSourceTrack(TrackKind.SUBTITLE, 12)
            runCurrent()
            assertEquals(1, backend.initializations.size)
            assertEquals(12, shownSourceSubtitle())
            assertFalse(TrackKind.SUBTITLE to 2L in engine.selections)

            listSidecar(this)
            assertEquals(TrackKind.SUBTITLE to 2L, engine.selections.last())
            assertEquals(1, backend.initializations.size)
        }
    }

    @Test
    fun `a sidecar the engine rejected lends its stream to no later track`() = runTest {
        val german = french.copy(id = 13, language = "Deutsch", languageCode = "de", title = "Deutsch", key = "/library/streams/13")
        with(rig(transcoding = true)) {
            backend.initialize = { options ->
                val stream = SessionBackend.streamOf(options)
                stream.copy(
                    isTranscoding = true,
                    mediaInfo = stream.mediaInfo?.copy(subtitleTracks = listOf(english, french, german)),
                    subtitleSidecars = listOf(
                        PlaybackSubtitleSidecar(12, SubtitleSidecar("/subs/12.srt", "Français", "fr", "srt"), preload = true),
                        PlaybackSubtitleSidecar(13, SubtitleSidecar("/subs/13.srt", "Deutsch", "de", "srt"), preload = true),
                    ),
                )
            }
            engine.deadSubtitles = setOf("/subs/12.srt")
            play(movie())
            open(600.0)
            // The engine lists the German file alone: it couldn't open the French one.
            val listed = track(2, TrackKind.SUBTITLE, "de", "Deutsch", external = true, codec = "subrip").copy(externalFilename = "/subs/13.srt")
            engine.report { s -> s.copy(tracks = s.tracks + listed) }
            runCurrent()

            session.selectSourceTrack(TrackKind.SUBTITLE, 12)
            idle()
            assertFalse(TrackKind.SUBTITLE to 2L in engine.selections, "the German track doesn't show for French")

            session.selectSourceTrack(TrackKind.SUBTITLE, 13)
            idle()
            assertEquals(TrackKind.SUBTITLE to 2L, engine.selections.last())
            assertEquals(13, shownSourceSubtitle())
        }
    }
}
