package com.edde746.plezy.downloads.android

import android.content.Context
import android.os.Build
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.edde746.plezy.PlezyApplication
import com.edde746.plezy.log.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.transformLatest
import kotlinx.coroutines.job
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.Duration.Companion.seconds

/**
 * The one worker downloads run in ([DownloadScheduler] enqueues it): a foreground `dataSync` service with the
 * downloads' notification ([DownloadNotifications]) while tasks are under way, the transfers running in its coroutine
 * ([TransferHost.attach]). It ends once none has been under way for a moment; when tasks wait for the network then, it
 * ends as a retry, so WorkManager runs it again once its network constraint holds, starting the process if it has to.
 * The system stopping it (the constraint gone, a time limit) cancels it: the transfers stop keeping their bytes, the
 * downloader queues them again, and they carry on in the next run.
 *
 * Started in a process WorkManager launched for it (the app was killed), it has the app install its downloader
 * ([AndroidDownloads.ensureInstalled]), which reschedules the tasks the last process left. Android 12+ refuses a
 * foreground service started from the background: the worker then runs as plain work (the system's time limit applies)
 * and goes to the foreground when the app next does.
 */
internal class DownloadWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        val downloads = (applicationContext as PlezyApplication).downloads
        withContext(Dispatchers.Main) { downloads.ensureInstalled() }
        // After a process start the downloader reads its tasks first (milliseconds): give it a moment to have work.
        if (withTimeoutOrNull(START_GRACE) { downloads.active.first { it } } == null) return end(downloads)

        downloads.notifications.ensureChannel()
        val inForeground = goForeground(downloads)
        try {
            serve(downloads, inForeground)
        } finally {
            // WorkManager knows the reason from Android 12 on.
            if (isStopped) {
                val reason = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) " (reason $stopReason)" else ""
                Log.i(TAG) { "Download worker stopped$reason" }
            }
        }
        return end(downloads)
    }

    /** Runs the transfers until no task has been under way for [END_GRACE]. */
    @OptIn(ExperimentalCoroutinesApi::class)
    private suspend fun serve(downloads: AndroidDownloads, inForeground: Boolean) = coroutineScope {
        val transfers = CoroutineScope(coroutineContext + SupervisorJob(coroutineContext.job) + Dispatchers.IO)
        downloads.host.attach(transfers)
        val foreground = launch {
            if (inForeground) return@launch
            // Refused in the background: try again each time the app comes to the foreground.
            var seen = downloads.foregrounds.value
            do {
                seen = downloads.foregrounds.first { it > seen }
                delay(FOREGROUND_SETTLE)
            } while (!goForeground(downloads))
        }
        try {
            downloads.active.transformLatest { active ->
                if (!active) {
                    delay(END_GRACE)
                    emit(Unit)
                }
            }.first()
        } finally {
            downloads.host.detach(transfers)
            transfers.cancel()
            foreground.cancel()
        }
    }

    private suspend fun goForeground(downloads: AndroidDownloads): Boolean = try {
        setForeground(withContext(Dispatchers.Main) { downloads.notifications.foregroundInfo(downloads.waitingForNetwork()) })
        true
    } catch (e: IllegalStateException) {
        // ForegroundServiceStartNotAllowedException: the app is in the background (Android 12+).
        Log.w(TAG) { "Downloads can't start their foreground service now: ${e::class.simpleName}" }
        false
    }

    private suspend fun end(downloads: AndroidDownloads): Result =
        if (withContext(Dispatchers.Main) { downloads.waitingForNetwork() }) Result.retry() else Result.success()

    private companion object {
        const val TAG = "Downloads"
        val START_GRACE = 10.seconds
        val END_GRACE = 2.seconds
        val FOREGROUND_SETTLE = 1.seconds
    }
}
