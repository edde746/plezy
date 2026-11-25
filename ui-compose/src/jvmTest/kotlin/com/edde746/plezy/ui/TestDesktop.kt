package com.edde746.plezy.ui

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.edde746.plezy.app.BundledText
import com.edde746.plezy.app.DeviceIdentity
import com.edde746.plezy.app.PlatformDownloads
import com.edde746.plezy.app.PlatformPlayback
import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.downloads.BackgroundWorkProbe
import com.edde746.plezy.downloads.BaseDirectory
import com.edde746.plezy.downloads.DownloadPlatform
import com.edde746.plezy.downloads.DownloadStoragePlatform
import com.edde746.plezy.downloads.DownloadTransport
import com.edde746.plezy.downloads.SafStorageOperations
import com.edde746.plezy.downloads.TaskDownloader
import com.edde746.plezy.downloads.TransferListener
import com.edde746.plezy.downloads.TransferRequest
import com.edde746.plezy.downloads.UnsupportedSafStorage
import com.edde746.plezy.downloads.VolumeCapacity
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.music.engine.AudioPlayer
import com.edde746.plezy.playback.PlayerEngine
import com.edde746.plezy.presentation.downloads.FolderPicker
import com.edde746.plezy.presentation.downloads.PickedFolder
import com.edde746.plezy.presentation.player.PlayerConfig
import com.edde746.plezy.presentation.settings.DeviceFeatures
import com.edde746.plezy.ui.app.PlezyPlatform
import com.edde746.plezy.ui.app.SaveResult
import io.ktor.client.HttpClient
import java.io.File

/** A desktop for an app session in a test: its downloads live in [directory] and download nothing; it plays nothing. */
internal class TestDesktop(directory: String) : PlezyPlatform {
    override val formFactor = FormFactor.DESKTOP
    override val device = DeviceIdentity(platform = "Linux", platformVersion = "6.1", deviceModel = "Linux", deviceName = "test-box", isTv = false)
    override val artworkCacheDirectory = File(directory, "artwork")
    override val appleTv = false
    override val playerConfig = PlayerConfig.defaults(InputProfile.DESKTOP, doubleClickIntervalMillis = 500)
    override val downloads: PlatformDownloads = Downloads(directory)

    override fun createPlayback(settings: DeviceSettings): PlatformPlayback = error("the test plays nothing")

    override fun createMusicAudioPlayer(): AudioPlayer = error("the test plays nothing")

    override fun setFullscreen(fullscreen: Boolean) = Unit

    override fun openUrl(url: String) = false

    override fun setClipboardText(text: String, sensitive: Boolean) = Unit

    override fun deviceFeatures() = DeviceFeatures(hardwareDecoding = false, hdr = false, matchFrameRate = false, audioPassthrough = false)

    override fun bundledTexts(folder: String): List<BundledText> = emptyList()

    override fun exit() = Unit

    @Composable
    override fun VideoSurface(engine: PlayerEngine, modifier: Modifier) = Unit

    override fun saveFile(fileName: String, text: String, done: (SaveResult) -> Unit) = Unit

    override fun openFile(opened: (name: String, text: String) -> Unit, failed: () -> Unit) = Unit

    private class Downloads(private val directory: String) : PlatformDownloads {
        override val storage = DownloadStoragePlatform(BaseDirectory.APPLICATION_SUPPORT, { directory }, supportsSaf = false)
        override val safStorage: SafStorageOperations = UnsupportedSafStorage
        override val backgroundWork: BackgroundWorkProbe? = null
        override val folderPicker = object : FolderPicker {
            override val available = false

            override suspend fun pick(title: String): PickedFolder? = null
        }

        override fun install(http: HttpClient, create: (DownloadPlatform) -> TaskDownloader): TaskDownloader = create(
            object : DownloadPlatform {
                override fun baseDirectoryPath(base: BaseDirectory) = directory

                override val tempDirectory = "$directory/partial"

                override fun capacity(path: String): VolumeCapacity? = null

                override val transport = object : DownloadTransport {
                    override fun start(request: TransferRequest, listener: TransferListener) = error("the test downloads nothing")

                    override fun stop(id: String) = Unit
                }
            },
        )

        override fun uninstall(downloader: TaskDownloader) = Unit
    }
}
