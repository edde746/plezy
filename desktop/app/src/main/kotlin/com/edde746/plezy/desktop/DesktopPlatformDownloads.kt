package com.edde746.plezy.desktop

import com.edde746.plezy.app.PlatformDownloads
import com.edde746.plezy.downloads.BackgroundWorkProbe
import com.edde746.plezy.downloads.BaseDirectory
import com.edde746.plezy.downloads.DownloadPlatform
import com.edde746.plezy.downloads.DownloadStoragePlatform
import com.edde746.plezy.downloads.SafStorageOperations
import com.edde746.plezy.downloads.TaskDownloader
import com.edde746.plezy.downloads.UnsupportedSafStorage
import com.edde746.plezy.presentation.downloads.FolderPicker
import com.edde746.plezy.presentation.downloads.PickedFolder
import io.ktor.client.HttpClient
import kotlinx.coroutines.suspendCancellableCoroutine
import java.awt.Window
import kotlin.coroutines.resume

/**
 * Downloads on Windows and Linux: [DesktopDownloads] in this process, stored relative to the app's data folder (the
 * earlier releases' support directory), and the folder dialog of Settings → Downloads location over [window]. No
 * notification permission to ask, no background-work signals.
 */
internal class DesktopPlatformDownloads(private val window: Window) : PlatformDownloads {
    private val supportDirectory = DesktopDownloads.appSupport()

    override val storage = DownloadStoragePlatform(BaseDirectory.APPLICATION_SUPPORT, { supportDirectory }, supportsSaf = false)

    override val safStorage: SafStorageOperations = UnsupportedSafStorage

    override val folderPicker = object : FolderPicker {
        override val available = true

        /** The folder dialog ([chooseDirectory]); called on the main thread, the AWT event thread. */
        override suspend fun pick(title: String): PickedFolder? = suspendCancellableCoroutine { picked ->
            chooseDirectory(window, title, initial = null) { path -> picked.resume(path?.let { PickedFolder(it, PickedFolder.FILE) }) }
        }
    }

    override val backgroundWork: BackgroundWorkProbe? = null

    override fun install(http: HttpClient, create: (DownloadPlatform) -> TaskDownloader): TaskDownloader =
        create(DesktopDownloads(http, supportDirectory))

    /** The transfers run in the downloader's own scope, which its session ends. */
    override fun uninstall(downloader: TaskDownloader) {}
}
