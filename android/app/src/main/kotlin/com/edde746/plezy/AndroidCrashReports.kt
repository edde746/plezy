package com.edde746.plezy

import android.content.Context
import com.edde746.plezy.app.AppGraph
import com.edde746.plezy.crash.CrashReports
import com.edde746.plezy.ui.crash.SentryReports
import io.sentry.android.core.SentryAndroid
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

/**
 * Sends [reports] through Sentry's Android SDK while they are on ([SentryReports.follow]): uncaught exceptions as they
 * happen, native crashes (libmpv's, through the SDK's NDK part) and ANRs at the next launch. No screenshots or view
 * hierarchies. With reports on, how the previous process ended is logged and, when it matters, reported too
 * ([PreviousExit]).
 */
internal fun AppGraph.followCrashReports(context: Context, reports: CrashReports): Job {
    scope.launch(Dispatchers.Default) {
        if (data.deviceSettings.settings().crashReports) PreviousExit.report(context.applicationContext)
    }
    return SentryReports.follow(reports, scope) { configure ->
        SentryAndroid.init(context.applicationContext) { options ->
            configure(options)
            options.isAttachScreenshot = false
            options.isAttachViewHierarchy = false
        }
    }
}
