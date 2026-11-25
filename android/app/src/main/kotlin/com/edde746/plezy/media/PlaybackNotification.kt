package com.edde746.plezy.media

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.drawable.Icon
import android.media.session.MediaSession
import android.os.Build
import com.edde746.plezy.R
import com.edde746.plezy.PlezyApplication
import com.edde746.plezy.presentation.player.MediaCommand
import com.edde746.plezy.presentation.player.NowPlaying
import com.edde746.plezy.presentation.player.NowPlayingKind
import com.edde746.plezy.presentation.player.NowPlayingStatus
import com.edde746.plezy.strings.T
import kotlin.math.roundToLong

/**
 * The playback's media notification, which [PlaybackService] shows: a [Notification.MediaStyle] over the session's
 * token (Android 13+ draws its controls from the session itself), with the title, the secondary line, the artwork, and
 * previous, play or pause, and next. A tap opens the app. Its actions and its dismissal arrive at [MediaActionReceiver].
 *
 * - A video's is on the "Now playing" channel ([ID]), previous and next when there is such an episode; dismissing it
 *   (possible once the service has left the foreground) stops the playback.
 * - Music's is on the "Media playback" channel ([MUSIC_ID]), with the album under the artist, previous and next while
 *   the queue has an entry that way, ongoing only while it plays or buffers; dismissing it stops only the service.
 */
internal class PlaybackNotification(private val context: Context) {
    private val notifications = context.getSystemService(NotificationManager::class.java)

    /** Creates [kind]'s channel, or renames it in the interface language now. Android 7 has no channels. */
    fun ensureChannel(kind: NowPlayingKind) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = when (kind) {
            NowPlayingKind.VIDEO -> NotificationChannel(CHANNEL, T.player.nowPlaying, NotificationManager.IMPORTANCE_LOW)
            NowPlayingKind.MUSIC -> NotificationChannel(MUSIC_CHANNEL, T.music.notificationChannel, NotificationManager.IMPORTANCE_LOW).apply {
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
        }
        channel.setShowBadge(false)
        notifications.createNotificationChannel(channel)
    }

    fun build(now: NowPlaying, artwork: Bitmap?, session: MediaSession.Token, open: PendingIntent): Notification {
        val music = now.kind == NowPlayingKind.MUSIC
        val actions = buildList {
            if (now.canSkipPrevious) add(action(PREVIOUS, R.drawable.ic_media_previous, if (music) T.music.previousTrack else T.player.previousEpisode))
            add(if (now.playing) action(PAUSE, R.drawable.ic_media_pause, T.player.pause) else action(PLAY, R.drawable.ic_media_play, T.player.play))
            if (now.canSkipNext) add(action(NEXT, R.drawable.ic_media_next, if (music) T.music.nextTrack else T.player.nextEpisode))
        }
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, if (music) MUSIC_CHANNEL else CHANNEL)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        builder
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(now.title)
            .setContentText(now.subtitle)
            .setLargeIcon(artwork)
            .setContentIntent(open)
            .setDeleteIntent(broadcast(DISMISS))
            .setOnlyAlertOnce(true)
            .setCategory(Notification.CATEGORY_TRANSPORT)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            // A group of its own: never bundled with the download notifications.
            .setGroup(if (music) MUSIC_CHANNEL else CHANNEL)
            .setActions(*actions.toTypedArray())
            .setStyle(Notification.MediaStyle().setMediaSession(session).setShowActionsInCompactView(*actions.indices.toList().toIntArray()))
        if (music) {
            builder.setSubText(now.album).setOngoing(now.playing).setShowWhen(false)
        } else if (showsTimePlayed(now)) {
            // The time played in the header while it plays at normal speed (releases before Android 13 show it).
            builder.setWhen(System.currentTimeMillis() - (now.positionSeconds * 1000).roundToLong()).setShowWhen(true).setUsesChronometer(true)
        } else {
            builder.setShowWhen(false)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
        return builder.build()
    }

    /** Takes the notification away: one left in the shade outlives the service that showed it. */
    fun cancel() {
        notifications.cancel(ID)
        notifications.cancel(MUSIC_ID)
    }

    private fun action(command: Int, icon: Int, label: String): Notification.Action =
        Notification.Action.Builder(Icon.createWithResource(context, icon), label, broadcast(command)).build()

    private fun broadcast(command: Int): PendingIntent = PendingIntent.getBroadcast(
        context,
        command,
        Intent(context, MediaActionReceiver::class.java).putExtra(EXTRA_COMMAND, command),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    companion object {
        const val ID = 0x7D02
        const val MUSIC_ID = 0x6D6470
        private const val CHANNEL = "playback"
        private const val MUSIC_CHANNEL = "media_playback"
        const val EXTRA_COMMAND = "command"
        const val PLAY = 1
        const val PAUSE = 2
        const val PREVIOUS = 3
        const val NEXT = 4
        const val DISMISS = 5

        /**
         * What of [now] the notification shows: the position only as a playing video's time played. Two values with
         * the same content build the same notification (a paused seek changes nothing in it).
         */
        fun content(now: NowPlaying): NowPlaying = if (showsTimePlayed(now)) now else now.copy(positionSeconds = 0.0)

        /** A video playing at normal speed: its header counts the time played. */
        private fun showsTimePlayed(now: NowPlaying) =
            now.kind == NowPlayingKind.VIDEO && now.status == NowPlayingStatus.PLAYING && now.rate == 1.0
    }
}

/** The media notification's actions and its dismissal, in this process (not exported): the playback's commands. */
internal class MediaActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val controls = (context.applicationContext as PlezyApplication).platform.mediaControls
        val command = when (intent.getIntExtra(PlaybackNotification.EXTRA_COMMAND, 0)) {
            PlaybackNotification.PLAY -> MediaCommand.Play
            PlaybackNotification.PAUSE -> MediaCommand.Pause
            PlaybackNotification.PREVIOUS -> MediaCommand.Previous
            PlaybackNotification.NEXT -> MediaCommand.Next
            PlaybackNotification.DISMISS -> return controls.onNotificationDismissed()
            else -> return
        }
        controls.perform(command)
    }
}
