package com.edde746.plezy.desktop

import com.edde746.plezy.desktop.windows.WindowsKnownFolders
import com.edde746.plezy.downloads.BaseDirectory
import com.edde746.plezy.downloads.DownloadPlatform
import com.edde746.plezy.downloads.DownloadTransport
import com.edde746.plezy.downloads.KtorTransport
import com.edde746.plezy.downloads.VolumeCapacity
import com.edde746.plezy.importer.EARLIER_RELEASE_APP_ID
import com.edde746.plezy.importer.EarlierReleaseLocations
import com.edde746.plezy.importer.desktop
import com.edde746.plezy.log.Log
import io.ktor.client.HttpClient
import java.io.File
import java.io.IOException
import java.util.concurrent.TimeUnit

/**
 * Downloads on Windows and Linux: [KtorTransport] in this process, while the app runs (queued and interrupted tasks go
 * on at the next launch). The base directories are the earlier releases' ([supportDirectory] the app's data folder,
 * [documentsDirectory] the user's Documents), so the relative paths they stored keep resolving; a task's bytes arrive
 * in `download_tasks` in the data folder. The desktop can't tell a metered network: its network state is unmetered.
 */
internal class DesktopDownloads(
    http: HttpClient,
    private val supportDirectory: String = appSupport(),
    private val documentsDirectory: () -> String = ::userDocuments,
) : DownloadPlatform {
    override fun baseDirectoryPath(base: BaseDirectory): String = when (base) {
        BaseDirectory.APPLICATION_SUPPORT -> supportDirectory
        BaseDirectory.APPLICATION_DOCUMENTS -> documentsDirectory()
        BaseDirectory.ROOT -> if (isWindows) "" else "/"
    }

    override val tempDirectory: String = tempDirectory(supportDirectory)

    /** The volume holding [path] (its nearest directory that exists yet), as this user may fill it. */
    override fun capacity(path: String): VolumeCapacity? {
        val existing = generateSequence(File(path).absoluteFile) { it.parentFile }.firstOrNull { it.exists() } ?: return null
        return VolumeCapacity(available = existing.usableSpace, total = existing.totalSpace)
    }

    override val transport: DownloadTransport = KtorTransport(http, ::capacity)

    companion object {
        private const val TAG = "DesktopDownloads"
        private const val TEMP_DIRECTORY = "download_tasks"
        private val isWindows = System.getProperty("os.name").startsWith("Windows")

        /** Where the downloader's transfers write their bytes until they complete, in the app's data folder [supportDirectory]. */
        fun tempDirectory(supportDirectory: String = appSupport()): String = File(supportDirectory, TEMP_DIRECTORY).path

        /** The app's data folder: the earlier releases' support directory (a development run on a Mac: the Mac app's). */
        fun appSupport(): String =
            if (System.getProperty("os.name").lowercase().startsWith("mac")) {
                File(System.getProperty("user.home"), "Library/Application Support/$EARLIER_RELEASE_APP_ID").path
            } else {
                EarlierReleaseLocations.desktop(::windowsDocuments).supportDirectory
            }

        /**
         * The user's Documents folder, as the earlier releases asked for it: Windows' Known Folder (wherever the user or
         * OneDrive moved it), else `%USERPROFILE%\Documents`; on Linux `xdg-user-dir DOCUMENTS`, else `~/Documents` when
         * no XDG Documents directory is set (a minimal or headless system).
         */
        fun userDocuments(): String {
            val home = System.getProperty("user.home")
            if (isWindows) {
                return windowsDocuments() ?: File(System.getenv("USERPROFILE")?.takeIf { it.isNotBlank() } ?: home, "Documents").path
            }
            return xdgDocuments(home) ?: File(home, "Documents").path
        }

        /** Windows' Documents Known Folder; null when Windows can't tell. */
        fun windowsDocuments(): String? = try {
            WindowsKnownFolders.documents()?.toString()
        } catch (e: Exception) {
            Log.w(TAG) { "No Known Folder for Documents: ${e::class.simpleName}" }
            null
        }

        /** The XDG Documents directory; null without `xdg-user-dir` or without one set (it answers the home directory). */
        private fun xdgDocuments(home: String): String? = try {
            val process = ProcessBuilder("xdg-user-dir", "DOCUMENTS").redirectError(ProcessBuilder.Redirect.DISCARD).start()
            if (!process.waitFor(2, TimeUnit.SECONDS)) {
                process.destroy()
                null
            } else {
                val answer = process.inputStream.bufferedReader().readText().trim()
                answer.takeIf { process.exitValue() == 0 && it.isNotEmpty() && it != home }
            }
        } catch (_: IOException) {
            null
        }
    }
}
