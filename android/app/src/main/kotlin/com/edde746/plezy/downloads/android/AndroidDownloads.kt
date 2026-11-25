package com.edde746.plezy.downloads.android

import android.content.Context
import android.os.StatFs
import com.edde746.plezy.app.PlatformDownloads
import com.edde746.plezy.downloads.AndroidSafStorage
import com.edde746.plezy.downloads.BackgroundWorkProbe
import com.edde746.plezy.downloads.BaseDirectory
import com.edde746.plezy.downloads.DocumentStore
import com.edde746.plezy.downloads.DownloadPlatform
import com.edde746.plezy.downloads.DownloadStoragePlatform
import com.edde746.plezy.downloads.KtorTransport
import com.edde746.plezy.downloads.SafDocumentStore
import com.edde746.plezy.downloads.SafStorageOperations
import com.edde746.plezy.downloads.TaskDownloader
import com.edde746.plezy.downloads.TaskNotification
import com.edde746.plezy.downloads.VolumeCapacity
import com.edde746.plezy.downloads.android
import com.edde746.plezy.importer.EarlierReleaseLocations
import com.edde746.plezy.importer.android
import com.edde746.plezy.log.Log
import com.edde746.plezy.presentation.downloads.FolderPicker
import io.ktor.client.HttpClient
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.io.File

/**
 * Downloads on Android, one per process (`PlezyApplication.downloads`): the app's [PlatformDownloads], the
 * [DownloadPlatform] of its [TaskDownloader] ([install]) and the WorkManager worker its bytes move in.
 *
 * - **Directories:** the earlier releases' (`app_flutter` for the documents base, `files` for support), so the paths
 *   they stored keep resolving; a task's bytes arrive in `download_tasks` in `noBackupFilesDir`. Document tasks write
 *   into storage-access-framework documents ([SafDocumentStore]).
 * - **Transfers:** [KtorTransport]'s, run by [DownloadWorker] in its own coroutine while it runs in the foreground
 *   ([TransferHost]), so bytes never move without its `dataSync` service and notification. The downloader's
 *   [DownloadPlatform.onActive] enqueues the worker ([DownloadScheduler]); it ends once no task is under way.
 * - **Wi-Fi only:** the worker's network constraint is an unmetered Wi-Fi or Ethernet network, a VPN over it included,
 *   while every task under way needs Wi-Fi.
 * - `POST_NOTIFICATIONS` (Android 13+) is asked before a download is queued (the platform's notification permission).
 *
 * @param television a TV: no background-work warnings, and the folder picker only where a documents UI exists.
 * @param buildProduct builds what [install]s the app's downloader: the worker's way to it when WorkManager started the
 *   process without an activity. Main thread.
 */
internal class AndroidDownloads(
    context: Context,
    television: Boolean,
    private val buildProduct: () -> Unit,
) : PlatformDownloads {
    private val context: Context = context.applicationContext

    /** Where transfers run: the worker's coroutine while it runs. */
    val host = TransferHost()

    val notifications = DownloadNotifications(this.context)

    private val scheduler = DownloadScheduler(this.context)
    private val scope = MainScope()

    /** The app's downloader, once installed. Main thread. */
    var downloader: TaskDownloader? = null
        private set

    private val mutableActive = MutableStateFlow(false)

    /** Some task is under way (enqueued, running, waiting to retry): the worker runs while true. */
    val active: StateFlow<Boolean> = mutableActive.asStateFlow()

    /** The download folder picker; its answer comes back to the activity on screen. */
    val permissions = DownloadPermissions(this.context, television)

    override val storage: DownloadStoragePlatform = DownloadStoragePlatform.android(this.context)

    override val safStorage: SafStorageOperations = AndroidSafStorage(this.context)

    override val folderPicker: FolderPicker get() = permissions

    /** Phones and tablets: TV boxes run on mains power, and battery and data restrictions there are noise. */
    override val backgroundWork: BackgroundWorkProbe? = if (television) null else BackgroundWorkDiagnostics(this.context)

    /** The storage-access-framework documents of document tasks. */
    val documents: DocumentStore = SafDocumentStore(this.context)

    /**
     * Sets up the platform of the app's downloader, its transfers over [http], and the downloader [create]d on it.
     * Main thread.
     */
    override fun install(http: HttpClient, create: (DownloadPlatform) -> TaskDownloader): TaskDownloader {
        val transport = WorkerTransport(KtorTransport(http, ::capacity, documents), host)
        return create(Platform(transport)).also { downloader = it }
    }

    /** [downloader] is closing (its database with it): it no longer runs in the worker. */
    override fun uninstall(downloader: TaskDownloader) {
        if (this.downloader !== downloader) return
        this.downloader = null
        onActive(active = false, wifiOnly = false)
    }

    /**
     * The worker's way to the downloader: when none is installed yet (WorkManager started the process for the worker),
     * [buildProduct] installs the app's, which reschedules the tasks the last process left. Main thread.
     */
    fun ensureInstalled() {
        if (downloader == null) buildProduct()
    }

    /** The notification's Pause: the task it showed, which the downloader reports paused (its download pauses). Main thread. */
    fun pause(taskId: String) {
        val downloader = downloader ?: return
        scope.launch { downloader.taskForId(taskId)?.let { downloader.pause(it) } }
    }

    /** The notification's Cancel: the task it showed, which the downloader reports cancelled. Main thread. */
    fun cancel(taskId: String) {
        val downloader = downloader ?: return
        scope.launch { downloader.cancelTasksWithIds(listOf(taskId)) }
    }

    private val mutableForegrounds = MutableStateFlow(0)

    /**
     * Counts the app coming to the foreground: a worker that couldn't start its foreground service in the background
     * (Android 12+) tries again at the next one.
     */
    val foregrounds: StateFlow<Int> = mutableForegrounds.asStateFlow()

    /** The app came to the foreground (the activity started). Main thread. */
    fun onForeground() {
        mutableForegrounds.value++
    }

    /**
     * Tasks under way wait for the network ([TaskDownloader.waitingForNetwork]). The worker ending then asks WorkManager
     * to run it again once its network constraint holds, so they go on even when the process is gone by then.
     */
    fun waitingForNetwork(): Boolean = downloader?.waitingForNetwork() == true

    /**
     * Tasks are under way or none ([DownloadPlatform.onActive]): the worker runs while some are, on an unmetered
     * network only while every one needs it.
     */
    private fun onActive(active: Boolean, wifiOnly: Boolean) {
        mutableActive.value = active
        if (!active) {
            scheduler.idle() // The running worker ends on its own once no task is under way.
            return
        }
        scheduler.schedule(wifiOnly)
    }

    /** The free bytes for the app's data, and the size, of the volume holding [path] (its nearest existing directory). */
    private fun capacity(path: String): VolumeCapacity? {
        val existing = generateSequence(File(path)) { it.parentFile }.firstOrNull { it.exists() } ?: return null
        return try {
            val stat = StatFs(existing.path)
            VolumeCapacity(available = stat.availableBytes, total = stat.totalBytes)
        } catch (e: IllegalArgumentException) {
            Log.w(TAG) { "the volume of a download can't be measured: ${e::class.simpleName}" }
            null
        }
    }

    /** The downloader's [DownloadPlatform]: the earlier releases' directories, its bytes through [transport]. */
    private inner class Platform(override val transport: WorkerTransport) : DownloadPlatform {
        private val earlier = EarlierReleaseLocations.android(context)

        override fun baseDirectoryPath(base: BaseDirectory): String = when (base) {
            BaseDirectory.APPLICATION_DOCUMENTS -> earlier.baseDirectory
            BaseDirectory.APPLICATION_SUPPORT -> earlier.supportDirectory
            BaseDirectory.ROOT -> "/"
        }

        override val tempDirectory: String = AndroidDownloads.tempDirectory(context)

        override fun capacity(path: String): VolumeCapacity? = this@AndroidDownloads.capacity(path)

        override val documents: DocumentStore get() = this@AndroidDownloads.documents

        override fun onActive(active: Boolean, wifiOnly: Boolean) = this@AndroidDownloads.onActive(active, wifiOnly)

        override fun notify(notification: TaskNotification) = notifications.show(notification)
    }

    companion object {
        private const val TAG = "Downloads"
        private const val TEMP_DIRECTORY = "download_tasks"

        /** Where the downloader's transfers write their bytes until they complete. */
        fun tempDirectory(context: Context): String = File(context.noBackupFilesDir, TEMP_DIRECTORY).path
    }
}
