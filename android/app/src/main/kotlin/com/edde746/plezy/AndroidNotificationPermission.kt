package com.edde746.plezy

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import com.edde746.plezy.app.NotificationPermission
import com.edde746.plezy.log.Log
import kotlinx.coroutines.CompletableDeferred

/**
 * Android 13+'s notification permission, asked for downloads (before a download is queued: the transfer's notification
 * anchors its foreground service, without which the system stops it once the screen goes off). Media-session
 * notifications are exempt from it, so playback never asks.
 *
 * The activity on screen registers its launcher before it starts ([attach]). The request is asked once per process run
 * (the system remembers a real denial); concurrent callers await the same answer, and with no activity on screen the
 * request is skipped (it is best-effort).
 */
internal class AndroidNotificationPermission(context: Context) : NotificationPermission {
    private val context: Context = context.applicationContext

    private var activity: ComponentActivity? = null
    private var launcher: ActivityResultLauncher<String>? = null
    private var request: CompletableDeferred<Unit>? = null

    /** Registers [activity]'s launcher, in its `onCreate`. Lint's fragment check concerns FragmentActivity only. */
    @SuppressLint("InvalidFragmentVersionForActivityResult")
    fun attach(activity: ComponentActivity) {
        this.activity = activity
        launcher = activity.registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
            Log.d(TAG) { "Notification permission granted: $granted" }
            request?.complete(Unit)
        }
    }

    /** [activity] is destroyed; finishing, a pending request ends as answered. */
    fun detach(activity: ComponentActivity) {
        if (this.activity !== activity) return
        this.activity = null
        launcher = null
        if (activity.isFinishing) request?.complete(Unit)
    }

    override suspend fun ensure() {
        request?.let { return it.await() }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) return
        val launcher = launcher ?: return
        val asked = CompletableDeferred<Unit>()
        request = asked
        try {
            launcher.launch(Manifest.permission.POST_NOTIFICATIONS)
        } catch (e: IllegalStateException) {
            Log.w(TAG, e) { "Notification permission request failed" }
            asked.complete(Unit)
        }
        asked.await()
    }

    private companion object {
        const val TAG = "NotificationPermission"
    }
}
