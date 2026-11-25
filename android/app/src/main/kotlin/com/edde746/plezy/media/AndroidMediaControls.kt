package com.edde746.plezy.media

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.media.AudioAttributes
import android.media.MediaMetadata
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import coil3.SingletonImageLoader
import coil3.request.Disposable
import coil3.request.ImageRequest
import coil3.request.allowHardware
import coil3.toBitmap
import com.edde746.plezy.PlezyActivity
import com.edde746.plezy.presentation.player.MediaCommand
import com.edde746.plezy.presentation.player.MediaCommandHandler
import com.edde746.plezy.presentation.player.MediaControlsHost
import com.edde746.plezy.presentation.player.NowPlaying
import com.edde746.plezy.presentation.player.NowPlayingKind
import com.edde746.plezy.presentation.player.NowPlayingStatus
import kotlin.math.roundToLong

/**
 * The OS media controls on Android: the platform's [MediaSession] with the shared [NowPlaying] and its
 * media notification ([PlaybackNotification], shown by [PlaybackService]) while a playback runs: the shade, the lock
 * screen, Android TV's now-playing card, and media buttons from headsets, Bluetooth and remotes when the app's window
 * doesn't take them itself. The session's commands (its callback, the notification's actions) become [MediaCommand]s
 * for the playback. The playback's audio focus and noisy handling ([PlaybackAudioFocus]) follow the same state. While
 * the display switches mode for the playback ([displaySwitching]) HDMI renegotiates, and a pause the session gets (Fire
 * TV sends one) and the audio becoming noisy as its audio route drops are the switch's, not the viewer's: neither
 * pauses, so the playback plays on once the display has settled. Every other pause (a loss of audio focus) pauses as
 * usual.
 *
 * A video's service is in the foreground while it plays and for [LINGER_MS] after it stops playing, so that it can
 * play again from the background (Android 12+ lets an app in the background into the foreground only on a user's
 * action); after that the notification stays, dismissable, and Android may stop the idle service: the next play
 * starts it again. Android 8+ refuses to start a service while the app is in the background (a watch-together room
 * opens its new media while the app is away): the session then goes on without the notification until the app is in
 * front again ([onForeground]) or a play comes from the session's controls (media buttons and the notification's
 * actions come with Android's leave to start one).
 *
 * The session offers what [NowPlaying] allows: play and pause ([NowPlaying.canPlayPause]), stop always, seeking, next
 * and previous, fast forward and rewind ([NowPlaying.canSkip]), and the speed ([NowPlaying.canSetSpeed]; Android 10+).
 *
 * A music session ([NowPlayingKind.MUSIC]) is music to the system (its volume keys and audio focus), with the album
 * and square artwork, previous and next while the queue has an entry that way, and fast forward and rewind as 15 s
 * skips. While the music may play on in the background ([NowPlaying.backgroundPlayback]) its service is started and in
 * the foreground while it plays, out of the foreground with its notification kept while paused (dismissing it then
 * stops only the service; a paused session never starts it), and stopped when the music stops. Playing music takes
 * audio focus only once its service is in the foreground: Android 15+ refuses focus to an app in the background that
 * runs none, and a refusal pauses. The task's removal turns background playback off until the app is in front again,
 * so updates racing the music's teardown can't start the service again. Music never drives picture-in-picture
 * ([listener], [nowPlaying]).
 *
 * One per process ([com.edde746.plezy.AndroidPlatform]); a session exists from a playback's first [show] to its
 * [hide]. Main thread.
 */
internal class AndroidMediaControls(context: Context, television: Boolean) : MediaControlsHost {
    private val context = context.applicationContext
    private val handler = Handler(Looper.getMainLooper())
    private var session: MediaSession? = null
    private var commands: MediaCommandHandler? = null
    private val focus = PlaybackAudioFocus(this.context, television, { displaySwitching }, ::perform)
    private val notification = PlaybackNotification(this.context)
    private var service: PlaybackService? = null

    /** A start of [PlaybackService] went out and it hasn't come up ([attach]) yet. */
    private var serviceStarting = false
    private var lingering = false
    private val lingered = Runnable {
        lingering = false
        showNotification()
    }

    /** The task was removed: no music service until the app is in front again ([onForeground]). */
    private var taskRemoved = false
    private var current: NowPlaying? = null
    private var artworkUrl: String? = null
    private var artwork: Bitmap? = null
    private var artworkRequest: Disposable? = null
    private var metadata: Metadata? = null

    /**
     * What the service shows now ([post]); null while it shows nothing of ours. Each post costs the system a
     * notification update and, in the foreground, a foreground-service update: a paused seek, which changes nothing in
     * the notification, posted it again while the video decoder restarted, and on a Fire TV that system work
     * held the seek's frame back.
     */
    private var posted: Posted? = null
    private val open = PendingIntent.getActivity(
        this.context,
        0,
        Intent(this.context, PlezyActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    private val callback = object : MediaSession.Callback() {
        override fun onPlay() = perform(MediaCommand.Play)
        override fun onPause() {
            if (displaySwitching) {
                Log.i(TAG, "Media session pause during a display switch: the switch's, not the viewer's; ignored")
                return
            }
            perform(MediaCommand.Pause)
        }
        override fun onStop() = perform(MediaCommand.Stop)
        override fun onSeekTo(pos: Long) = perform(MediaCommand.SeekTo(pos.coerceAtLeast(0) / 1000.0))
        override fun onFastForward() = skip(1.0)
        override fun onRewind() = skip(-1.0)
        override fun onSkipToNext() = perform(MediaCommand.Next)
        override fun onSkipToPrevious() = perform(MediaCommand.Previous)
        override fun onSetPlaybackSpeed(speed: Float) = perform(MediaCommand.SetSpeed(speed.toDouble()))
    }

    /** What the controls show now for a video; null between videos and while music plays. */
    val nowPlaying: NowPlaying? get() = current?.takeIf { it.kind == NowPlayingKind.VIDEO }

    /** Hears each [NowPlaying] of a video and, with null, its end. */
    var listener: ((NowPlaying?) -> Unit)? = null

    override fun show(nowPlaying: NowPlaying, commands: MediaCommandHandler) {
        val wasPlaying = current?.playing == true
        current = nowPlaying
        this.commands = commands
        val started = session == null
        val session = session ?: start(nowPlaying.kind)
        val music = nowPlaying.kind == NowPlayingKind.MUSIC
        if (!music) {
            if (nowPlaying.playing) {
                handler.removeCallbacks(lingered)
                lingering = false
            } else if (wasPlaying) {
                lingering = true
                handler.postDelayed(lingered, LINGER_MS)
            }
            if (started || (nowPlaying.playing && !wasPlaying)) startService()
        }
        session.setPlaybackState(state(nowPlaying))
        loadArtwork(nowPlaying.artworkUrl, nowPlaying.kind)
        publish()
        session.isActive = true
        // Music's audio focus follows its service ([showNotification]).
        if (!music) {
            focus.update(nowPlaying.playing)
            listener?.invoke(nowPlaying)
        }
    }

    override fun hide() {
        val session = session ?: return
        val video = current?.kind != NowPlayingKind.MUSIC
        this.session = null
        service = null
        posted = null
        serviceStarting = false
        current = null
        commands = null
        handler.removeCallbacks(lingered)
        lingering = false
        artworkRequest?.dispose()
        artworkRequest = null
        artworkUrl = null
        artwork = null
        metadata = null
        focus.release()
        context.stopService(Intent(context, PlaybackService::class.java))
        notification.cancel()
        session.release()
        if (video) listener?.invoke(null)
        Log.i(TAG, "Media session released")
    }

    /** A command from outside the session (picture-in-picture and the notification's actions): the same way in. */
    fun perform(command: MediaCommand) {
        Log.i(TAG, "Media command: $command")
        commands?.perform(command)
    }

    /**
     * Fast forward ([direction] 1) or rewind (-1), while the playback offers skips: music by 15 s, a video by the
     * player's own step ([NowPlaying.skipSeconds]).
     */
    private fun skip(direction: Double) {
        val now = current?.takeIf { it.canSkip } ?: return
        perform(MediaCommand.SeekBy(direction * if (now.kind == NowPlayingKind.MUSIC) MUSIC_SKIP_SECONDS else now.skipSeconds))
    }

    /** The viewer's pause cancels the resume a transient loss of audio focus waits for ([PlaybackAudioFocus.userPaused]). */
    override fun userPaused() = focus.userPaused()

    /** The display is switching mode for the playback, until it has settled (the playback's output says so). */
    var displaySwitching = false

    /**
     * The app's task was removed (swiped away from Recents) while the service ran: nothing is left to show the
     * playback, so it stops, with background playback off first so that no late update starts the service again. If
     * the player can't close (a dev session's direct play has no screen to return to), it pauses, the system's pause
     * rather than the viewer's, and the controls go.
     */
    fun onTaskRemoved() {
        taskRemoved = true
        val commands = commands ?: return
        commands.perform(MediaCommand.Stop)
        if (session != null) {
            commands.perform(MediaCommand.SystemPause)
            hide()
        }
    }

    /**
     * The app is in front ([com.edde746.plezy.PlezyActivity.onStart]): background playback may run again, and a
     * playback without its service gets it now (music only while it plays).
     */
    fun onForeground() {
        taskRemoved = false
        val now = current ?: return
        if (now.kind == NowPlayingKind.MUSIC) showNotification() else startService()
    }

    /**
     * The notification was dismissed (possible only out of the foreground): a video stops; music stays paused and
     * only its service stops, to start again at the next play.
     */
    fun onNotificationDismissed() {
        if (current?.kind == NowPlayingKind.MUSIC) stopService() else perform(MediaCommand.Stop)
    }

    /** [PlaybackService] came up: it shows the notification from now on, or stops if the playback has already ended. */
    fun attach(service: PlaybackService) {
        serviceStarting = false
        if (session == null) {
            service.stopSelf()
            return
        }
        this.service = service
        posted = null
        showNotification()
    }

    fun detach(service: PlaybackService) {
        if (this.service === service) {
            this.service = null
            posted = null
        }
    }

    private fun start(kind: NowPlayingKind): MediaSession {
        notification.ensureChannel(kind)
        val session = MediaSession(context, TAG)
        session.setSessionActivity(open)
        // A film's soundtrack or music: the volume keys change the media stream.
        val content = if (kind == NowPlayingKind.MUSIC) AudioAttributes.CONTENT_TYPE_MUSIC else AudioAttributes.CONTENT_TYPE_MOVIE
        session.setPlaybackToLocal(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).setContentType(content).build())
        session.setCallback(callback, handler)
        focus.music = kind == NowPlayingKind.MUSIC
        this.session = session
        Log.i(TAG, "Media session started ($kind)")
        return session
    }

    /**
     * Starts [PlaybackService], which shows the notification once up, unless it runs or is on its way. Android 8+
     * refuses the start while the app is in the background (an [IllegalStateException]; from Android 12
     * `BackgroundServiceStartNotAllowedException`): the session goes on without it until the next try.
     */
    private fun startService() {
        if (service != null || serviceStarting) return
        try {
            context.startService(Intent(context, PlaybackService::class.java))
            serviceStarting = true
        } catch (e: IllegalStateException) {
            Log.w(TAG, "Android refused the playback service while the app is in the background; the session goes on without it", e)
        }
    }

    /** Stops [PlaybackService] and takes its notification away; the session goes on. */
    private fun stopService() {
        service = null
        posted = null
        serviceStarting = false
        context.stopService(Intent(context, PlaybackService::class.java))
        notification.cancel()
    }

    /** The metadata and the notification as [current] and the artwork are now. */
    private fun publish() {
        val session = session ?: return
        val now = current ?: return
        val durationMs = if (now.durationSeconds > 0) (now.durationSeconds * 1000).roundToLong() else -1
        val next = Metadata(now.title, now.subtitle, now.album, durationMs, artwork)
        if (next != metadata) {
            metadata = next
            val builder = MediaMetadata.Builder()
                .putText(MediaMetadata.METADATA_KEY_TITLE, now.title)
                .putText(MediaMetadata.METADATA_KEY_DISPLAY_TITLE, now.title)
                .putText(MediaMetadata.METADATA_KEY_ARTIST, now.subtitle)
                .putText(MediaMetadata.METADATA_KEY_DISPLAY_SUBTITLE, now.subtitle)
                .putLong(MediaMetadata.METADATA_KEY_DURATION, durationMs)
            now.album?.let {
                builder.putText(MediaMetadata.METADATA_KEY_ALBUM, it)
                builder.putText(MediaMetadata.METADATA_KEY_DISPLAY_DESCRIPTION, it)
            }
            // The artwork as the loaded bitmap only: its URL carries the server's token, and every controller of the
            // session (notification listeners, companion apps) reads the metadata.
            artwork?.let { bitmap -> ARTWORK_BITMAPS.forEach { builder.putBitmap(it, bitmap) } }
            session.setMetadata(builder.build())
        }
        showNotification()
    }

    /**
     * The notification as things are now: a video's in the foreground while it plays or lingers; music's as the class
     * says, with the audio focus once its service is in the foreground (or Android refused the service).
     */
    private fun showNotification() {
        val session = session ?: return
        val now = current ?: return
        if (now.kind != NowPlayingKind.MUSIC) {
            post(session, PlaybackNotification.ID, now, now.playing || lingering)
            return
        }
        val started = service != null || serviceStarting
        when {
            !now.backgroundPlayback || taskRemoved || now.status == NowPlayingStatus.STOPPED -> if (started) stopService()
            now.playing -> if (started) post(session, PlaybackNotification.MUSIC_ID, now, foreground = true) else startService()
            else -> if (started) post(session, PlaybackNotification.MUSIC_ID, now, foreground = false)
        }
        if (!now.playing || !serviceStarting) focus.update(now.playing)
    }

    /**
     * Has the service show [now]'s notification as [id], in the foreground when [foreground], unless it shows that
     * already. A foreground Android refused isn't recorded, so the next post (the app in front again) tries again.
     */
    private fun post(session: MediaSession, id: Int, now: NowPlaying, foreground: Boolean) {
        val service = service ?: return
        val content = PlaybackNotification.content(now)
        if (posted == Posted(id, content, artwork, foreground)) return
        val inForeground = service.show(id, notification.build(now, artwork, session.sessionToken, open), foreground)
        posted = Posted(id, content, artwork, inForeground)
    }

    /**
     * Loads [url] (the UI's image loader: its cache, the app's HTTP client) for the metadata and the notification: a
     * video's at the size the system keeps, music's square at most [MUSIC_ARTWORK_PX].
     */
    private fun loadArtwork(url: String?, kind: NowPlayingKind) {
        if (url == artworkUrl) return
        artworkRequest?.dispose()
        artworkUrl = url
        artwork = null
        artworkRequest = url?.let {
            val size = if (kind == NowPlayingKind.MUSIC) MUSIC_ARTWORK_PX else (ARTWORK_DP * context.resources.displayMetrics.density).toInt()
            val request = ImageRequest.Builder(context)
                .data(it)
                .size(size)
                // Parcelled into the session's metadata and the notification.
                .allowHardware(false)
                .listener(onError = { _, result -> Log.w(TAG, "The artwork didn't load: ${result.throwable::class.simpleName}") })
                .target(onSuccess = { image ->
                    artwork = image.toBitmap()
                    publish()
                })
                .build()
            SingletonImageLoader.get(context).enqueue(request)
        }
    }

    /** What the session's metadata was last built from. */
    private data class Metadata(
        val title: String,
        val subtitle: String?,
        val album: String?,
        val durationMs: Long,
        val artwork: Bitmap?,
    )

    /**
     * What the service's notification was last built from: its id, what it shows ([PlaybackNotification.content]), the
     * artwork, and whether it is in the foreground.
     */
    private data class Posted(val id: Int, val content: NowPlaying, val artwork: Bitmap?, val foreground: Boolean)

    private companion object {
        const val TAG = "MediaControls"

        /** How long a video's service stays in the foreground once it stops playing: a pause, not for good. */
        const val LINGER_MS = 10 * 60 * 1000L

        /** The largest artwork the system keeps in a session's metadata (`config_mediaMetadataBitmapMaxSize`). */
        const val ARTWORK_DP = 320

        /** Music's artwork, downsampled: an album cover in the shade and on the lock screen. */
        const val MUSIC_ARTWORK_PX = 512

        /** Music's fast forward and rewind (Bluetooth and steering-wheel buttons): an in-track skip. */
        const val MUSIC_SKIP_SECONDS = 15.0

        val ARTWORK_BITMAPS = listOf(MediaMetadata.METADATA_KEY_DISPLAY_ICON, MediaMetadata.METADATA_KEY_ALBUM_ART)

        fun state(now: NowPlaying): PlaybackState {
            var actions = PlaybackState.ACTION_STOP
            if (now.canPlayPause) actions = actions or PlaybackState.ACTION_PLAY or PlaybackState.ACTION_PAUSE or PlaybackState.ACTION_PLAY_PAUSE
            if (now.canSeek) actions = actions or PlaybackState.ACTION_SEEK_TO
            if (now.canSkip) actions = actions or PlaybackState.ACTION_FAST_FORWARD or PlaybackState.ACTION_REWIND
            // Previous and next only with an entry that way in the queue.
            if (now.canSkipPrevious) actions = actions or PlaybackState.ACTION_SKIP_TO_PREVIOUS
            if (now.canSkipNext) actions = actions or PlaybackState.ACTION_SKIP_TO_NEXT
            // A video's speed (Android 10+), while it may change: not live, nor a guest's.
            if (now.canSetSpeed && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) actions = actions or PlaybackState.ACTION_SET_PLAYBACK_SPEED
            val state = when (now.status) {
                NowPlayingStatus.BUFFERING -> PlaybackState.STATE_BUFFERING
                NowPlayingStatus.PLAYING -> PlaybackState.STATE_PLAYING
                NowPlayingStatus.PAUSED -> PlaybackState.STATE_PAUSED
                NowPlayingStatus.STOPPED -> PlaybackState.STATE_STOPPED
            }
            // While it plays, the system carries the position on at this speed from now.
            val speed = if (now.status == NowPlayingStatus.PLAYING) now.rate.toFloat() else 0f
            return PlaybackState.Builder()
                .setActions(actions)
                .setState(state, (now.positionSeconds * 1000).roundToLong(), speed, SystemClock.elapsedRealtime())
                .build()
        }
    }
}
