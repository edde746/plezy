package com.edde746.plezy.app

import com.edde746.plezy.downloads.BackgroundWorkProbe
import com.edde746.plezy.downloads.DownloadPlatform
import com.edde746.plezy.downloads.DownloadStoragePlatform
import com.edde746.plezy.downloads.SafStorageOperations
import com.edde746.plezy.downloads.TaskDownloader
import com.edde746.plezy.presentation.downloads.FolderPicker
import io.ktor.client.HttpClient

/**
 * The OS side of downloads ([AppPlatform.downloads]), one per process: the downloader's platform, where downloads are
 * stored, Android's storage-access-framework trees, the folder picker of Settings →
 * Downloads location and the background-work signals. Apple TV has none.
 */
interface PlatformDownloads {
    /** The base directory downloads are stored relative to, and how the platform marks their folder. */
    val storage: DownloadStoragePlatform

    /** Android's storage-access-framework trees; [com.edde746.plezy.downloads.UnsupportedSafStorage] elsewhere. */
    val safStorage: SafStorageOperations

    /** Settings → Downloads location's picker; unavailable where the platform has none (iPhone, iPad, Android TV without one). */
    val folderPicker: FolderPicker

    /**
     * The OS's reasons background downloads won't run (Android phones and tablets); null where it tells none, and the
     * background-download warnings stay silent.
     */
    val backgroundWork: BackgroundWorkProbe?

    /**
     * Builds the app's downloader: [create] runs on this device's [DownloadPlatform], whose transfers go over [http]
     * where they run in the app's process. The platform keeps the downloader (Android's worker runs its transfers)
     * until [uninstall]. Main thread.
     */
    fun install(http: HttpClient, create: (DownloadPlatform) -> TaskDownloader): TaskDownloader

    /** The [downloader] goes with its app session: the platform stops running its transfers. Main thread. */
    fun uninstall(downloader: TaskDownloader)
}
