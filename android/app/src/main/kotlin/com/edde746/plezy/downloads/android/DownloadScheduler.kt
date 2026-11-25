package com.edde746.plezy.downloads.android

import android.content.Context
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkInfo
import androidx.work.WorkManager
import com.edde746.plezy.log.Log
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import java.util.concurrent.TimeUnit

/**
 * Keeps one [DownloadWorker] enqueued (unique work) while a queue is active, with the network constraint Wi-Fi only
 * asks for: Wi-Fi or Ethernet (a VPN over them included), else any connected network. It enqueues the worker again
 * (replacing what's there) when there is none, when the constraint changed (the running worker stops; its transfers
 * queue again and continue in the new one), or when it waits out a retry's backoff although the network is back. The
 * worker ends on its own once no queue is active ([DownloadWorker]). Main thread.
 */
internal class DownloadScheduler(context: Context) {
    private val workManager: WorkManager by lazy { WorkManager.getInstance(context) }
    private val scope = MainScope()

    /** Wi-Fi only while a queue is active; null while none is. */
    private val wanted = MutableStateFlow<Boolean?>(null)
    private var started = false

    /** [schedule] was called since the worker was last enqueued. */
    private var asked = false

    /** A queue has work: the worker runs, on an unmetered network when [wifiOnly]. */
    fun schedule(wifiOnly: Boolean) {
        wanted.value = wifiOnly
        asked = true
        if (started) return
        started = true
        scope.launch {
            combine(wanted, workManager.getWorkInfosForUniqueWorkFlow(WORK)) { wifiOnly, infos -> wifiOnly to infos }
                .collect { (wifiOnly, infos) -> if (wifiOnly != null) reconcile(wifiOnly, infos) }
        }
    }

    /** No queue has work: the running worker ends by itself; one waiting for its network stays for when it's back. */
    fun idle() {
        wanted.value = null
    }

    private fun reconcile(wifiOnly: Boolean, infos: List<WorkInfo>) {
        val work = infos.firstOrNull { !it.state.isFinished }
        val replace = when {
            // A worker that failed (it threw) isn't started over and over: only when the queue asks again.
            work == null -> asked || infos.none { it.state == WorkInfo.State.FAILED }
            tag(wifiOnly) !in work.tags -> true
            // A retry waiting for its backoff (DownloadWorker ended while the network was away), and the network is back.
            work.state == WorkInfo.State.ENQUEUED && work.runAttemptCount > 0 -> true
            else -> false
        }
        if (!replace) return
        Log.i(TAG) { "Scheduling the download worker (wifiOnly=$wifiOnly, was ${work?.state})" }
        asked = false
        workManager.enqueueUniqueWork(WORK, ExistingWorkPolicy.REPLACE, request(wifiOnly))
    }

    private fun request(wifiOnly: Boolean) = OneTimeWorkRequestBuilder<DownloadWorker>()
        .setConstraints(constraints(wifiOnly))
        .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, RETRY_SECONDS, TimeUnit.SECONDS)
        .addTag(tag(wifiOnly))
        .build()

    // Wi-Fi only's: an unmetered Wi-Fi or Ethernet network, whether or not a VPN runs over it. The system counts a VPN
    // metered unless its app declares it unmetered, so the unmetered network type alone, which JobScheduler judges on
    // the app's default network (the VPN), would hold the worker back behind most VPNs; this request is met by the
    // network under the VPN. JobScheduler keeps NOT_METERED in it, so a metered Wi-Fi (a hotspot) stops the worker and
    // keeps it waiting without waking it, and it starts again as soon as the Wi-Fi is unmetered.
    private fun constraints(wifiOnly: Boolean): Constraints = Constraints.Builder().apply {
        when {
            !wifiOnly -> setRequiredNetworkType(NetworkType.CONNECTED)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.P -> setRequiredNetworkRequest(
                NetworkRequest.Builder()
                    .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                    .removeCapability(NetworkCapabilities.NET_CAPABILITY_NOT_VPN)
                    .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
                    .addTransportType(NetworkCapabilities.TRANSPORT_ETHERNET)
                    .build(),
                NetworkType.UNMETERED,
            )
            else -> setRequiredNetworkType(NetworkType.UNMETERED)
        }
    }.build()

    private fun tag(wifiOnly: Boolean): String = if (wifiOnly) TAG_WIFI else TAG_CONNECTED

    private companion object {
        const val TAG = "Downloads"
        const val WORK = "downloads"
        // A worker enqueued with an earlier constraint for Wi-Fi only (unmetered, which held it back behind a VPN) has
        // another tag, so the next schedule replaces it.
        const val TAG_WIFI = "downloads:wifi"
        const val TAG_CONNECTED = "downloads:connected"
        const val RETRY_SECONDS = 30L
    }
}
