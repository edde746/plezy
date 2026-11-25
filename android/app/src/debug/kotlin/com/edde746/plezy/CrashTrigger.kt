package com.edde746.plezy

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.os.SystemClock
import com.edde746.plezy.app.DevCrashException

/**
 * The test builds' crash, for the crash-report harness: `am broadcast -n
 * com.edde746.plezy.dev/com.edde746.plezy.CrashTrigger` (the shell holds DUMP, which guards it) throws a
 * [DevCrashException] on the main thread; `--es kind native` instead ends the process with SIGSEGV, as a crash in
 * native code (libmpv's) would, which the next launch reports; `--es kind anr` blocks the main thread for
 * [ANR_MILLIS], long enough for the system's and the crash reporter's ANR detection.
 */
class CrashTrigger : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val kind = intent.getStringExtra("kind")
        Handler(Looper.getMainLooper()).post {
            when (kind) {
                "native" -> Process.sendSignal(Process.myPid(), SIGSEGV)
                "anr" -> {
                    SystemClock.sleep(ANR_MILLIS)
                    return@post
                }
            }
            throw DevCrashException()
        }
    }

    private companion object {
        const val SIGSEGV = 11
        const val ANR_MILLIS = 10_000L
    }
}
