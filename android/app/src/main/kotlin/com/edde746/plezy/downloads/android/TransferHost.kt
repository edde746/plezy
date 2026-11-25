package com.edde746.plezy.downloads.android

import com.edde746.plezy.downloads.DownloadTransport
import com.edde746.plezy.downloads.KtorTransport
import com.edde746.plezy.downloads.TransferListener
import com.edde746.plezy.downloads.TransferRequest
import com.edde746.plezy.downloads.TransferResult
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

/** The downloader's [DownloadTransport] on Android: [KtorTransport]'s transfers, run by the [TransferHost] inside the download worker. */
internal class WorkerTransport(private val ktor: KtorTransport, private val host: TransferHost) : DownloadTransport {
    override fun start(request: TransferRequest, listener: TransferListener) = host.start(ktor, request, listener)

    override fun stop(id: String) = host.stop(id)
}

/**
 * Runs transfers in the download worker's coroutine ([attach]) and nowhere else, so bytes only move while its foreground
 * service runs. A transfer started while no worker runs waits for the next one; the worker ending (its run limit, the
 * system stopping it, its network constraint gone) cancels what runs, which reports [TransferResult.Stopped] and keeps
 * its bytes: the downloader queues the task again and it carries on in the next run. Callable from any thread.
 */
internal class TransferHost {
    private class Transfer(val ktor: KtorTransport, val request: TransferRequest, val listener: TransferListener)

    private val lock = Any()
    private var scope: CoroutineScope? = null
    private val waiting = LinkedHashMap<String, Transfer>()
    private val jobs = HashMap<String, Job>()

    fun start(ktor: KtorTransport, request: TransferRequest, listener: TransferListener) {
        val transfer = Transfer(ktor, request, listener)
        synchronized(lock) {
            val scope = scope
            if (scope != null) launch(scope, transfer) else waiting[request.id] = transfer
        }
    }

    fun stop(id: String) {
        val waited: Transfer?
        val job: Job?
        synchronized(lock) {
            waited = waiting.remove(id)
            job = jobs[id]
        }
        waited?.listener?.onResult(id, TransferResult.Stopped)
        job?.cancel()
    }

    /** The worker runs: transfers run in [scope] from now on, the waiting ones first. */
    fun attach(scope: CoroutineScope) {
        synchronized(lock) {
            this.scope = scope
            waiting.values.forEach { launch(scope, it) }
            waiting.clear()
        }
    }

    /** The worker ends: transfers started from now on wait for the next one. */
    fun detach(scope: CoroutineScope) {
        synchronized(lock) {
            if (this.scope === scope) this.scope = null
        }
    }

    /**
     * Under [lock]. Atomic start: a transfer launched into a worker that is just being cancelled still runs up to its
     * first suspension, so it reports [TransferResult.Stopped] rather than nothing.
     */
    @OptIn(DelicateCoroutinesApi::class)
    private fun launch(scope: CoroutineScope, transfer: Transfer) {
        val id = transfer.request.id
        jobs[id] = scope.launch(start = CoroutineStart.ATOMIC) {
            // KtorTransport.transfer turns every failure into a result; cancelling it (a stop, the worker ending) is Stopped.
            val result = try {
                transfer.ktor.transfer(transfer.request, transfer.listener)
            } catch (_: CancellationException) {
                TransferResult.Stopped
            }
            synchronized(lock) { if (jobs[id] === coroutineContext[Job]) jobs.remove(id) }
            transfer.listener.onResult(id, result)
        }
    }
}
