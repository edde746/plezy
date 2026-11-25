package com.edde746.plezy.watchnext

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import com.edde746.plezy.PlezyApplication

/**
 * The device started, or this app was updated: the launchers' read grants to the Watch Next posters are gone (grants
 * live only as long as the system's run and the app's install), so the rows' posters are granted again
 * ([WatchNext.grantAgain]). Before Android 8 there are no rows.
 */
class WatchNextGrantReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED && intent.action != Intent.ACTION_MY_PACKAGE_REPLACED) return
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val watchNext = (context.applicationContext as PlezyApplication).platform.homeScreen ?: return
        val pending = goAsync()
        watchNext.grantAgain(pending::finish)
    }
}
