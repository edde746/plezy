package com.edde746.plezy.desktop.windows

import com.edde746.plezy.desktop.DesktopMediaControls
import com.edde746.plezy.log.Log
import com.edde746.plezy.presentation.player.MediaCommand
import com.edde746.plezy.presentation.player.MediaCommandHandler
import com.edde746.plezy.presentation.player.MediaControlsHost
import com.edde746.plezy.presentation.player.NowPlaying
import com.edde746.plezy.presentation.player.NowPlayingKind
import com.edde746.plezy.presentation.player.NowPlayingStatus
import java.lang.foreign.MemorySegment
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import javax.swing.SwingUtilities

/**
 * The System Media Transport Controls of the app's window ([MediaControlsHost] on Windows): the media overlay (volume
 * and media keys), the lock screen and other apps' media sessions (`GlobalSystemMediaTransportControlsSessionManager`)
 * show what plays, and the media keys control it while the app is in the background.
 *
 * Through FFM into the Windows Runtime ([WinRt]): `ISystemMediaTransportControlsInterop::GetForWindow` on the window's
 * HWND, the display updater (a video with title and subtitle, or a music track with title, artist and album, and a
 * thumbnail the system loads from the artwork URL), the playback status, the play and pause buttons (on while this
 * device may control playback), the previous and next buttons (on as [NowPlaying] offers them; music's previous
 * always), the timeline and rate, and
 * the ButtonPressed (play, pause, stop, previous, next) and PlaybackPositionChangeRequested (seek) events. Every call
 * runs on one thread of the multithreaded apartment; the events arrive on the runtime's threads and reach the
 * playback's [MediaCommandHandler] on the AWT event thread (the main thread). [onCommand] sees each command as it
 * arrives (the test report). [close] releases everything.
 */
internal class WindowsMediaControls(
    private val window: () -> Long,
    private val onCommand: (MediaCommand) -> Unit = {},
) : DesktopMediaControls {
    private val thread: ExecutorService = Executors.newSingleThreadExecutor { Thread(it, "smtc").apply { isDaemon = true } }

    // The smtc thread's state.
    private var controls: MemorySegment? = null
    private var controls2: MemorySegment? = null
    private var updater: MemorySegment? = null
    private var buttonPressed: WinRt.Delegate? = null
    private var positionRequested: WinRt.Delegate? = null
    private var buttonToken = 0L
    private var positionToken = 0L
    private var shown: NowPlaying? = null

    /** The playback's handler while the controls are up; read on the event thread. */
    @Volatile private var commands: MediaCommandHandler? = null
    private var initialized = false
    private var failed = false

    /**
     * The controls attach to the window on the first [show] once it has its HWND ([window] returns 0 until then), so
     * a playback that starts before the window is up (a dev session's direct play) gets them from its next update.
     */
    override fun show(nowPlaying: NowPlaying, commands: MediaCommandHandler) {
        this.commands = commands
        val hwnd = window()
        post {
            if (controls == null && hwnd != 0L) attach(hwnd)
            apply(nowPlaying)
        }
    }

    override fun hide() {
        commands = null
        post { controls?.let { if (shown != null) hide(it) } }
    }

    /**
     * Runs [block] on the smtc thread (joining the multithreaded apartment first) unless the controls turned out to be
     * unavailable; a failure is logged, not thrown, and a failure to attach disables the controls for the app's run.
     */
    private fun post(block: () -> Unit) {
        if (thread.isShutdown) return
        thread.execute {
            if (failed) return@execute
            try {
                if (!initialized) {
                    check(WinRt.initializeThread()) { "RoInitialize failed" }
                    initialized = true
                }
                block()
            } catch (e: Exception) {
                if (controls == null) failed = true
                Log.w(TAG, e) { if (failed) "media controls unavailable" else "media controls update failed" }
            }
        }
    }

    /** Hands an OS command to the playback on the event thread (the handler is the one current then). */
    private fun deliver(command: MediaCommand) {
        onCommand(command)
        SwingUtilities.invokeLater { commands?.perform(command) }
    }

    override fun close() {
        if (thread.isShutdown) return
        thread.execute {
            try {
                if (!failed) detach()
            } catch (e: Exception) {
                Log.w(TAG, e) { "media controls release failed" }
            } finally {
                if (initialized) WinRt.uninitializeThread()
            }
        }
        thread.shutdown()
        thread.awaitTermination(3, TimeUnit.SECONDS)
    }

    private fun attach(hwnd: Long) {
        val interop = WinRt.activationFactory(SMTC_CLASS, IID_INTEROP)
        val smtc = try {
            WinRt.invokeForObject("GetForWindow", interop, 6, MemorySegment.ofAddress(hwnd), IID_SMTC)
        } finally {
            WinRt.release(interop)
        }
        controls = smtc
        controls2 = WinRt.queryInterface(smtc, IID_SMTC2)
        updater = WinRt.invokeForObject("get_DisplayUpdater", smtc, 8)
        WinRt.invoke("put_IsStopEnabled", smtc, 15, true)
        val button = WinRt.Delegate(IID_BUTTON_HANDLER) { _, args ->
            when (WinRt.invokeForInt("get_Button", args, 6)) {
                BUTTON_PLAY -> deliver(MediaCommand.Play)
                BUTTON_PAUSE -> deliver(MediaCommand.Pause)
                BUTTON_STOP -> deliver(MediaCommand.Stop)
                BUTTON_NEXT -> deliver(MediaCommand.Next)
                BUTTON_PREVIOUS -> deliver(MediaCommand.Previous)
            }
        }
        buttonPressed = button
        buttonToken = WinRt.invokeForLong("add_ButtonPressed", smtc, 32, button.pointer)
        val position = WinRt.Delegate(IID_POSITION_HANDLER) { _, args ->
            val ticks = WinRt.invokeForLong("get_RequestedPlaybackPosition", args, 6)
            deliver(MediaCommand.SeekTo(ticks / TICKS_PER_SECOND))
        }
        positionRequested = position
        positionToken = WinRt.invokeForLong("add_PlaybackPositionChangeRequested", checkNotNull(controls2), 13, position.pointer)
    }

    private fun apply(next: NowPlaying) {
        val smtc = controls ?: return
        val updater = checkNotNull(updater)
        val controls2 = checkNotNull(controls2)
        val before = shown
        val music = next.kind == NowPlayingKind.MUSIC
        if (before == null) WinRt.invoke("put_IsEnabled", smtc, 11, true)
        if (before == null || before.kind != next.kind || before.title != next.title || before.subtitle != next.subtitle ||
            before.album != next.album || before.artworkUrl != next.artworkUrl
        ) {
            if (music) showTrack(updater, next) else showVideo(updater, next)
            setThumbnail(updater, next.artworkUrl)
            WinRt.invoke("Update", updater, 17)
        }
        if (before == null || before.status != next.status) WinRt.invoke("put_PlaybackStatus", smtc, 7, statusCode(next.status))
        if (before == null || before.canPlayPause != next.canPlayPause) {
            WinRt.invoke("put_IsPlayEnabled", smtc, 13, next.canPlayPause)
            WinRt.invoke("put_IsPauseEnabled", smtc, 17, next.canPlayPause)
        }
        if (before == null || before.canSkipNext != next.canSkipNext) WinRt.invoke("put_IsNextEnabled", smtc, 27, next.canSkipNext)
        if (before == null || before.canSkipPrevious != next.canSkipPrevious) WinRt.invoke("put_IsPreviousEnabled", smtc, 25, next.canSkipPrevious)
        if (before == null || before.rate != next.rate) WinRt.invoke("put_PlaybackRate", controls2, 11, next.rate)
        if (before == null || before.durationSeconds != next.durationSeconds || before.positionSeconds != next.positionSeconds || before.canSeek != next.canSeek) {
            updateTimeline(controls2, next.durationSeconds, next.positionSeconds, next.canSeek)
        }
        shown = next
    }

    /** A video: the title and the episode line. */
    private fun showVideo(updater: MemorySegment, next: NowPlaying) {
        WinRt.invoke("put_Type", updater, 7, MEDIA_TYPE_VIDEO)
        val video = WinRt.invokeForObject("get_VideoProperties", updater, 13)
        try {
            WinRt.withHString(next.title) { WinRt.invoke("put_Title", video, 7, it) }
            WinRt.withHString(next.subtitle.orEmpty()) { WinRt.invoke("put_Subtitle", video, 9, it) }
        } finally {
            WinRt.release(video)
        }
    }

    /** A music track: the title, the artist and the album. */
    private fun showTrack(updater: MemorySegment, next: NowPlaying) {
        WinRt.invoke("put_Type", updater, 7, MEDIA_TYPE_MUSIC)
        val track = WinRt.invokeForObject("get_MusicProperties", updater, 12)
        try {
            WinRt.withHString(next.title) { WinRt.invoke("put_Title", track, 7, it) }
            WinRt.withHString(next.subtitle.orEmpty()) { WinRt.invoke("put_Artist", track, 11, it) }
            val album = WinRt.queryInterface(track, IID_MUSIC_PROPERTIES2)
            try {
                WinRt.withHString(next.album.orEmpty()) { WinRt.invoke("put_AlbumTitle", album, 7, it) }
            } finally {
                WinRt.release(album)
            }
        } finally {
            WinRt.release(track)
        }
    }

    private fun hide(smtc: MemorySegment) {
        WinRt.invoke("put_PlaybackStatus", smtc, 7, STATUS_CLOSED)
        updater?.let {
            WinRt.invoke("ClearAll", it, 16)
            WinRt.invoke("Update", it, 17)
        }
        WinRt.invoke("put_IsEnabled", smtc, 11, false)
        shown = null
    }

    /** The system loads the image from [url] itself (`RandomAccessStreamReference.CreateFromUri`); null clears it. */
    private fun setThumbnail(updater: MemorySegment, url: String?) {
        if (url == null) {
            WinRt.invoke("put_Thumbnail", updater, 11, MemorySegment.NULL)
            return
        }
        val uriFactory = WinRt.activationFactory(URI_CLASS, IID_URI_FACTORY)
        val streams = WinRt.activationFactory(STREAM_REFERENCE_CLASS, IID_STREAM_REFERENCE_STATICS)
        var uri: MemorySegment? = null
        var reference: MemorySegment? = null
        try {
            uri = WinRt.withHString(url) { WinRt.invokeForObject("Uri.CreateUri", uriFactory, 6, it) }
            reference = WinRt.invokeForObject("RandomAccessStreamReference.CreateFromUri", streams, 7, uri)
            WinRt.invoke("put_Thumbnail", updater, 11, reference)
        } finally {
            WinRt.release(reference)
            WinRt.release(uri)
            WinRt.release(streams)
            WinRt.release(uriFactory)
        }
    }

    /** The seek range is the whole file where [canSeek], else empty (no seek bar). */
    private fun updateTimeline(controls2: MemorySegment, durationSeconds: Double, positionSeconds: Double, canSeek: Boolean) {
        val instance = WinRt.activateInstance(TIMELINE_CLASS)
        val timeline = try {
            WinRt.queryInterface(instance, IID_TIMELINE)
        } finally {
            WinRt.release(instance)
        }
        try {
            val end = ticks(durationSeconds)
            WinRt.invoke("put_StartTime", timeline, 7, 0L)
            WinRt.invoke("put_EndTime", timeline, 9, end)
            WinRt.invoke("put_MinSeekTime", timeline, 11, 0L)
            WinRt.invoke("put_MaxSeekTime", timeline, 13, if (canSeek) end else 0L)
            WinRt.invoke("put_Position", timeline, 15, ticks(positionSeconds.coerceIn(0.0, durationSeconds.coerceAtLeast(0.0))))
            WinRt.invoke("UpdateTimelineProperties", controls2, 12, timeline)
        } finally {
            WinRt.release(timeline)
        }
    }

    private fun detach() {
        val smtc = controls ?: return
        if (shown != null) hide(smtc)
        controls2?.let { if (positionRequested != null) WinRt.call(it, 14, positionToken) }
        if (buttonPressed != null) WinRt.call(smtc, 33, buttonToken)
        positionRequested?.release()
        buttonPressed?.release()
        WinRt.release(updater)
        WinRt.release(controls2)
        WinRt.release(smtc)
        positionRequested = null
        buttonPressed = null
        updater = null
        controls2 = null
        controls = null
    }

    companion object {
        private const val TAG = "smtc"

        private const val SMTC_CLASS = "Windows.Media.SystemMediaTransportControls"
        private const val TIMELINE_CLASS = "Windows.Media.SystemMediaTransportControlsTimelineProperties"
        private const val URI_CLASS = "Windows.Foundation.Uri"
        private const val STREAM_REFERENCE_CLASS = "Windows.Storage.Streams.RandomAccessStreamReference"

        private val IID_INTEROP = WinRt.guid("ddb0472d-c911-4a1f-86d9-dc3d71a95f5a")
        private val IID_SMTC = WinRt.guid("99fa3ff4-1742-42a6-902e-087d41f965ec")
        private val IID_SMTC2 = WinRt.guid("ea98d2f6-7f3c-4af2-a586-72889808efb1")
        private val IID_TIMELINE = WinRt.guid("5125316a-c3a2-475b-8507-93534dc88f15")
        private val IID_URI_FACTORY = WinRt.guid("44a9796f-723e-4fdf-a218-033e75b0c084")
        private val IID_STREAM_REFERENCE_STATICS = WinRt.guid("857309dc-3fbf-4e7d-986f-ef3b1a07a964")
        private val IID_MUSIC_PROPERTIES2 = WinRt.guid("00368462-97d3-44b9-b00f-008afcefaf18")

        /** TypedEventHandler<SystemMediaTransportControls, …>'s instances for the two events. */
        private const val TYPED_EVENT_HANDLER = "{9de1c534-6ae1-11e0-84e1-18a905bcc53f}"
        private const val SMTC_SIGNATURE = "rc($SMTC_CLASS;{99fa3ff4-1742-42a6-902e-087d41f965ec})"
        private val IID_BUTTON_HANDLER = WinRt.guid(
            WinRt.parameterizedIid(
                "pinterface($TYPED_EVENT_HANDLER;$SMTC_SIGNATURE;" +
                    "rc(Windows.Media.SystemMediaTransportControlsButtonPressedEventArgs;{b7f47116-a56f-4dc8-9e11-92031f4a87c2}))",
            ),
        )
        private val IID_POSITION_HANDLER = WinRt.guid(
            WinRt.parameterizedIid(
                "pinterface($TYPED_EVENT_HANDLER;$SMTC_SIGNATURE;" +
                    "rc(Windows.Media.PlaybackPositionChangeRequestedEventArgs;{b4493f88-eb28-4961-9c14-335e44f3e125}))",
            ),
        )

        // SystemMediaTransportControlsButton, MediaPlaybackStatus, MediaPlaybackType.
        private const val BUTTON_PLAY = 0
        private const val BUTTON_PAUSE = 1
        private const val BUTTON_STOP = 2
        private const val BUTTON_NEXT = 6
        private const val BUTTON_PREVIOUS = 7
        private const val STATUS_CLOSED = 0
        private const val MEDIA_TYPE_MUSIC = 1
        private const val MEDIA_TYPE_VIDEO = 2

        /** TimeSpan units (100 ns). */
        private const val TICKS_PER_SECOND = 10_000_000.0

        private fun ticks(seconds: Double): Long = (seconds * TICKS_PER_SECOND).toLong()

        /** Buffering shows as playing: it plays once it has the data, and the play/pause key then pauses (NowPlaying.playing). */
        private fun statusCode(status: NowPlayingStatus): Int = when (status) {
            NowPlayingStatus.STOPPED -> 2
            NowPlayingStatus.PLAYING, NowPlayingStatus.BUFFERING -> 3
            NowPlayingStatus.PAUSED -> 4
        }
    }
}
