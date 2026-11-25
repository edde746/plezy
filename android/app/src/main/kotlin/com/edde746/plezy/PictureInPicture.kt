package com.edde746.plezy

import android.app.AppOpsManager
import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.graphics.Rect
import android.graphics.drawable.Icon
import android.os.Build
import android.util.Log
import android.util.Rational
import androidx.activity.ComponentActivity
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import com.edde746.plezy.media.AndroidMediaControls
import com.edde746.plezy.presentation.player.MediaCommand
import com.edde746.plezy.presentation.player.NowPlaying
import com.edde746.plezy.presentation.player.PictureInPictureError
import com.edde746.plezy.presentation.player.PictureInPictureHost
import com.edde746.plezy.presentation.player.PictureInPictureResult
import com.edde746.plezy.presentation.player.PictureInPictureRules
import com.edde746.plezy.strings.T

/**
 * Picture-in-picture for the playback on phones and tablets, one per activity ([PictureInPictureHost]):
 * - The player's button starts it ([enter]): with the window shaped like the video, or reports why it can't (Android
 *   before 8.0, no picture-in-picture on the device, the user's app-ops switch off, the system refusing).
 * - It enters on Home by itself where auto picture-in-picture is on ([autoPipOn], the `auto_pip` setting) and the
 *   playback plays: on API 31+ through `setAutoEnterEnabled`, on API 26–30 from [onUserLeaveHint], which marks the
 *   transition ([autoEntering]) until the mode changes.
 * - The window takes the picture's aspect ratio (within the system's 2.39:1 limits, [PictureInPictureRules.aspectRatio])
 *   and grows out of the picture's bounds (`sourceRectHint`).
 * - Its actions rewind, play or pause, and fast-forward, as the player's own buttons do ([AndroidMediaControls.perform]).
 * - The player shows only the video while it is in picture-in-picture ([AndroidPlatform.inPictureInPicture]).
 * - Closing the window (not expanding it) stops the playback; the playback ending in it closes the window.
 *
 * Main thread.
 */
internal class PictureInPicture(
    private val activity: ComponentActivity,
    private val platform: AndroidPlatform,
    private val controls: AndroidMediaControls,
) : PictureInPictureHost {
    /** API 26+, no TV, and the system feature. */
    override val supported: Boolean = PictureInPictureRules.androidSupported(
        Build.VERSION.SDK_INT,
        platform.isTelevision,
        activity.packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE),
    )

    override val active: Boolean get() = supported && activity.isInPictureInPictureMode

    /** The `auto_pip` setting as it applies here (`AppSettings.autoPipOn`). */
    var autoPipOn: Boolean = false
        set(value) {
            field = value
            update()
        }

    /** API 26–30: Home started the window by itself and the mode hasn't changed yet. */
    var autoEntering: Boolean = false
        private set

    private var nowPlaying: NowPlaying? = null
    private var aspectRatio: Rational? = null
    private var pictureBounds: Rect? = null
    private var shown: Shown? = null
    private val listener: (NowPlaying?) -> Unit = ::onNowPlaying

    private val autoReady: Boolean get() = PictureInPictureRules.autoEnterReady(autoPipOn, nowPlaying?.playing == true)

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val step = nowPlaying?.skipSeconds ?: return
            val command = when (intent.getIntExtra(EXTRA_ACTION, -1)) {
                ACTION_PLAY -> MediaCommand.Play
                ACTION_PAUSE -> MediaCommand.Pause
                ACTION_REWIND -> MediaCommand.SeekBy(-step)
                ACTION_FORWARD -> MediaCommand.SeekBy(step)
                else -> return
            }
            Log.i(TAG, "Picture-in-picture action: $command")
            controls.perform(command)
        }
    }

    /** From the activity's `onCreate`. */
    fun attach() {
        if (!supported) return
        ContextCompat.registerReceiver(activity, receiver, IntentFilter(BROADCAST), ContextCompat.RECEIVER_NOT_EXPORTED)
        controls.listener = listener
        onNowPlaying(controls.nowPlaying)
    }

    /** From the activity's `onDestroy`. */
    fun detach() {
        if (!supported) return
        activity.unregisterReceiver(receiver)
        if (controls.listener === listener) controls.listener = null
    }

    /**
     * The player's picture changed size or moved (`MpvVideoView.onPictureChanged`):
     * [width]×[height] its display size, [bounds] where the whole picture is in the window (`pictureBoundsInWindow`).
     */
    fun onPicture(width: Int, height: Int, bounds: () -> Rect?) {
        if (!supported || width <= 0 || height <= 0) return
        aspectRatio = rational(width, height)
        // In picture-in-picture the view fills the small window; the hint is for entering from full screen.
        if (!activity.isInPictureInPictureMode) pictureBounds = bounds()
        update()
    }

    override suspend fun enter(width: Int?, height: Int?): PictureInPictureResult {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return PictureInPictureError.ANDROID_VERSION.failed()
        if (!supported) return PictureInPictureError.NOT_SUPPORTED.failed()
        if (!permitted()) return PictureInPictureError.PERMISSION_DISABLED.failed()
        if (width != null && height != null) aspectRatio = rational(width, height)
        return try {
            if (activity.enterPictureInPictureMode(params())) PictureInPictureResult.Entered else PictureInPictureError.FAILED.failed()
        } catch (e: IllegalStateException) {
            Log.w(TAG, "Picture-in-picture refused", e)
            PictureInPictureError.NOT_SUPPORTED.failed()
        } catch (e: Exception) {
            Log.w(TAG, "Picture-in-picture failed", e)
            PictureInPictureResult.Failed("unknown", e.message)
        }
    }

    /** Expands the window back into the app. */
    override fun exit() {
        if (!active) return
        activity.startActivity(Intent(activity, activity.javaClass).addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT))
    }

    /** The activity's `onUserLeaveHint`: on API 26–30, Home while auto picture-in-picture is ready enters it. */
    fun onUserLeaveHint() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) return
        if (!supported || !autoReady || !permitted()) return
        autoEntering = true
        try {
            activity.enterPictureInPictureMode(params())
        } catch (e: Exception) {
            autoEntering = false
            Log.w(TAG, "Automatic picture-in-picture failed", e)
        }
    }

    /**
     * The activity entered or left picture-in-picture. Leaving while [stopped] means the window was closed, not
     * expanded: the playback stops.
     */
    fun onModeChanged(inPictureInPicture: Boolean, stopped: Boolean) {
        autoEntering = false
        platform.inPictureInPicture = inPictureInPicture
        if (!inPictureInPicture && stopped && nowPlaying != null) {
            Log.i(TAG, "Picture-in-picture closed: stopping the playback")
            controls.perform(MediaCommand.Stop)
        }
    }

    /** The user's app-ops switch for picture-in-picture is on. */
    private fun permitted(): Boolean {
        val ops = activity.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        @Suppress("DEPRECATION")
        return ops.checkOpNoThrow(AppOpsManager.OPSTR_PICTURE_IN_PICTURE, activity.applicationInfo.uid, activity.packageName) ==
            AppOpsManager.MODE_ALLOWED
    }

    /**
     * The playback's controls changed; none means it ended. Ended in the window (the film played out), the window goes
     * with the task to the back rather than showing the page the player leaves to.
     */
    private fun onNowPlaying(nowPlaying: NowPlaying?) {
        this.nowPlaying = nowPlaying
        if (nowPlaying == null) {
            aspectRatio = null
            pictureBounds = null
            if (active) activity.moveTaskToBack(false)
        }
        update()
    }

    private fun update() {
        if (!supported || Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val next = Shown(nowPlaying?.playing, nowPlaying?.canSkip, aspectRatio, pictureBounds, autoReady)
        if (next == shown) return
        shown = next
        activity.setPictureInPictureParams(params())
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun params(): PictureInPictureParams {
        val now = nowPlaying
        val builder = PictureInPictureParams.Builder()
            .setAspectRatio(aspectRatio ?: DEFAULT_ASPECT)
            .setSourceRectHint(pictureBounds)
            .setActions(if (now == null) emptyList() else actions(now))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setAutoEnterEnabled(autoReady)
            // A video cross-fades into the window; resizing it seamlessly would show a stretched frame.
            builder.setSeamlessResizeEnabled(false)
        }
        return builder.build()
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun actions(now: NowPlaying): List<RemoteAction> {
        val playPause = if (now.playing) {
            action(ACTION_PAUSE, R.drawable.ic_media_pause, T.player.pause)
        } else {
            action(ACTION_PLAY, R.drawable.ic_media_play, T.player.play)
        }
        if (!now.canSkip || activity.maxNumPictureInPictureActions < 3) return listOf(playPause)
        return listOf(
            action(ACTION_REWIND, R.drawable.ic_media_rewind, T.nav.player.rewind),
            playPause,
            action(ACTION_FORWARD, R.drawable.ic_media_forward, T.nav.player.fastForward),
        )
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun action(code: Int, icon: Int, label: String): RemoteAction {
        val intent = Intent(BROADCAST).setPackage(activity.packageName).putExtra(EXTRA_ACTION, code)
        val pending = PendingIntent.getBroadcast(activity, code, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        return RemoteAction(Icon.createWithResource(activity, icon), label, label, pending)
    }

    /** What the window's parameters were last built from. */
    private data class Shown(val playing: Boolean?, val canSkip: Boolean?, val aspectRatio: Rational?, val bounds: Rect?, val autoReady: Boolean)

    private companion object {
        const val TAG = "PictureInPicture"
        const val BROADCAST = "com.edde746.plezy.PICTURE_IN_PICTURE"
        const val EXTRA_ACTION = "action"
        const val ACTION_PLAY = 1
        const val ACTION_PAUSE = 2
        const val ACTION_REWIND = 3
        const val ACTION_FORWARD = 4
        val DEFAULT_ASPECT = Rational(16, 9)

        fun rational(width: Int, height: Int): Rational = PictureInPictureRules.aspectRatio(width, height).let { (w, h) -> Rational(w, h) }
    }
}
