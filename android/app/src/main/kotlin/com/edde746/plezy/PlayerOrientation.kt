package com.edde746.plezy

import android.app.Activity
import android.content.pm.ActivityInfo
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Build
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.edde746.plezy.presentation.player.ImmersiveModeGuard
import com.edde746.plezy.presentation.player.OrientationRequest
import com.edde746.plezy.presentation.player.PlayerOrientationRules

/**
 * The player's window on a phone or tablet, one per activity: its orientation and its immersive system bars.
 *
 * While the player shows, the activity asks for landscape either way round (`SCREEN_ORIENTATION_USER_LANDSCAPE`)
 * while the rotation lock (`rotation_locked`, [rotationLockChanged]) is on, and for every orientation
 * (`SCREEN_ORIENTATION_FULL_USER`) while it is off; leaving the player asks for every orientation again
 * ([PlayerOrientationRules]). A TV or a car is never asked for an orientation. Nothing is asked for in picture in
 * picture, whose window has none; what the player wants is asked for once the activity fills the screen again.
 *
 * The system bars hide while the player shows (back for a moment by a swipe); a fold, an unfold or a display switch
 * that shows them again while the activity stays resumed hides them again ([ImmersiveModeGuard]). Leaving the player
 * releases the guard before it shows the bars, then asks for the orientation: each independently of the other.
 *
 * The player's video surfaces report in ([playerShown], [playerHidden]); leaving waits for the frame after the last
 * one left, since the next playback's player takes the last one's place in the same frame and keeps the window
 * without a turn between them. Main thread.
 */
internal class PlayerOrientation(private val activity: Activity, television: Boolean) {
    private val platformOwnsOrientation = television ||
        activity.packageManager.hasSystemFeature(PackageManager.FEATURE_AUTOMOTIVE)
    private var players = 0
    private var shown = false
    private var rotationLocked = true
    private var inPictureInPicture = false
    private val bars = WindowCompat.getInsetsController(activity.window, activity.window.decorView)
    private val guard = ImmersiveModeGuard { hideBars() }
    private val leaveLater = Runnable { if (players == 0) leave() }
    private var configuration = Configuration(activity.resources.configuration)
    private val reassert = Runnable { if (shown && !inPictureInPicture) hideBars() }

    init {
        // Bars shown again while the activity stays resumed: the guard hides them while a player owns the window.
        ViewCompat.setOnApplyWindowInsetsListener(activity.window.decorView) { view, insets ->
            guard.onSystemBarsChanged(insets.isVisible(WindowInsetsCompat.Type.systemBars()))
            ViewCompat.onApplyWindowInsets(view, insets)
        }
    }

    fun playerShown() {
        players++
        activity.window.decorView.removeCallbacks(leaveLater)
        if (shown) return
        shown = true
        hideBars()
        guard.acquire(this)
        request(PlayerOrientationRules.whilePlaying(rotationLocked, platformOwnsOrientation))
    }

    fun playerHidden() {
        players--
        activity.window.decorView.post(leaveLater)
    }

    /** The rotation lock setting, now and as it changes (the player's button, the settings). */
    fun rotationLockChanged(locked: Boolean) {
        if (locked == rotationLocked) return
        rotationLocked = locked
        if (shown) request(PlayerOrientationRules.whilePlaying(locked, platformOwnsOrientation))
    }

    fun onPictureInPictureChanged(inPictureInPicture: Boolean) {
        this.inPictureInPicture = inPictureInPicture
        if (!inPictureInPicture && shown) request(PlayerOrientationRules.whilePlaying(rotationLocked, platformOwnsOrientation))
    }

    /**
     * The activity's configuration changed. A fold, an unfold or a display switch ([isDisplaySwitch]) can leave the
     * bars shown on the new display while the window still counts them hidden, so no re-show reaches the guard: while
     * the player shows (Android 11+), the navigation bar is shown and, once the change has settled ([REASSERT_DELAY_MS]),
     * the bars are hidden again.
     */
    fun onConfigurationChanged(newConfig: Configuration) {
        val diff = newConfig.diff(configuration)
        configuration = Configuration(newConfig)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R || !shown || inPictureInPicture || !isDisplaySwitch(diff)) return
        val decor = activity.window.decorView
        decor.removeCallbacks(reassert)
        bars.show(WindowInsetsCompat.Type.navigationBars())
        decor.postDelayed(reassert, REASSERT_DELAY_MS)
    }

    private fun leave() {
        if (!shown) return
        shown = false
        // Before the bars show: the re-show that follows must find no owner, or it would hide them again.
        guard.release(this)
        bars.show(WindowInsetsCompat.Type.systemBars())
        request(PlayerOrientationRules.onExit(platformOwnsOrientation))
    }

    private fun hideBars() {
        bars.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        bars.hide(WindowInsetsCompat.Type.systemBars())
    }

    private fun request(request: OrientationRequest?) {
        if (request == null || inPictureInPicture) return
        val wanted = when (request) {
            OrientationRequest.LANDSCAPE -> ActivityInfo.SCREEN_ORIENTATION_USER_LANDSCAPE
            OrientationRequest.ALL -> ActivityInfo.SCREEN_ORIENTATION_FULL_USER
        }
        if (activity.requestedOrientation != wanted) activity.requestedOrientation = wanted
    }

    companion object {
        const val REASSERT_DELAY_MS = 400L

        /**
         * Whether a configuration change ([Configuration.diff]) moved the window to another display or display shape:
         * the smallest width or the screen layout changed, or the size changed without a rotation.
         */
        fun isDisplaySwitch(diff: Int): Boolean =
            diff and (ActivityInfo.CONFIG_SMALLEST_SCREEN_SIZE or ActivityInfo.CONFIG_SCREEN_LAYOUT) != 0 ||
                (diff and ActivityInfo.CONFIG_SCREEN_SIZE != 0 && diff and ActivityInfo.CONFIG_ORIENTATION == 0)
    }
}
