package com.edde746.plezy.desktop.updates

import com.edde746.plezy.log.Log
import com.edde746.plezy.ui.updates.InstallerUpdate
import com.edde746.plezy.ui.updates.InstallerUpdater
import io.ktor.client.HttpClient
import io.ktor.client.plugins.HttpTimeoutConfig
import io.ktor.client.plugins.timeout
import io.ktor.client.request.prepareGet
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsChannel
import io.ktor.http.HttpStatusCode
import io.ktor.utils.io.cancel
import io.ktor.utils.io.readAvailable
import io.ktor.utils.io.readBuffer
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.io.readString
import java.io.IOException
import java.lang.ProcessBuilder.Redirect
import java.nio.file.Files
import java.nio.file.Path
import kotlin.time.Duration.Companion.seconds

/** A downloaded installer that isn't the one the feed signed: its size or its signature doesn't match. */
internal class UpdateRejectedException(message: String) : Exception(message)

/**
 * The updater of a Windows copy installed by Plezy's installer, as WinSparkle was: reads the update feed ([feedUrl], an
 * [Appcast]), offers its newest Windows build when it is newer than [currentBuild], and installs it: downloads the
 * installer into [directory], checks its size and its Ed25519 signature against [publicKey] (a mismatch is refused and
 * the file deleted), starts it with [INSTALLER_ARGUMENTS] ([start]: a silent install that starts the new
 * version when it is done) and ends the app ([exit]), so the installer can replace its files.
 */
internal class WindowsUpdater(
    private val http: HttpClient,
    private val currentBuild: Long,
    private val feedUrl: String,
    private val publicKey: String,
    private val directory: Path,
    private val start: (installer: Path, arguments: List<String>) -> Unit,
    private val exit: () -> Unit,
) : InstallerUpdater {
    override suspend fun check(): AppcastItem? {
        val xml = http.prepareGet(feedUrl) { timeout { requestTimeoutMillis = FEED_TIMEOUT.inWholeMilliseconds } }.execute { response ->
            response.requireOk("the update feed")
            val body = response.bodyAsChannel()
            try {
                val text = body.readBuffer(MAX_FEED_BYTES + 1)
                if (text.size > MAX_FEED_BYTES) throw IOException("the update feed is over $MAX_FEED_BYTES bytes")
                text.readString()
            } finally {
                body.cancel()
            }
        }
        return Appcast.parse(xml, OS).firstOrNull()?.takeIf { it.build > currentBuild }
    }

    override suspend fun install(update: InstallerUpdate, progress: (Float) -> Unit) {
        val installer = (update as AppcastItem).installer
        val file = download(installer, progress)
        val verified = withContext(Dispatchers.IO) { UpdateSignature.verify(file, installer.signature, publicKey) }
        if (!verified) {
            Files.delete(file)
            Log.e(TAG) { "the installer of ${update.version} from ${installer.url} doesn't carry the update key's signature: refused" }
            throw UpdateRejectedException("the installer's signature doesn't match the update key")
        }
        Log.i(TAG) { "starting the installer of ${update.version} (build ${update.build}) and leaving" }
        start(file, INSTALLER_ARGUMENTS)
        exit()
    }

    /** [installer] into [directory], its size checked as it streams; progress whenever another percent is done. */
    private suspend fun download(installer: AppcastEnclosure, progress: (Float) -> Unit): Path {
        val file = directory.resolve(INSTALLER_NAME)
        http.prepareGet(installer.url) { timeout { requestTimeoutMillis = HttpTimeoutConfig.INFINITE_TIMEOUT_MS } }.execute { response ->
            response.requireOk("the installer's download")
            val body = response.bodyAsChannel()
            try {
                withContext(Dispatchers.IO) {
                    Files.createDirectories(directory)
                    var written = 0L
                    var percent = -1
                    Files.newOutputStream(file).use { output ->
                        val buffer = ByteArray(1 shl 16)
                        while (true) {
                            val read = body.readAvailable(buffer, 0, buffer.size)
                            if (read == -1) break
                            written += read
                            if (written > installer.length) break
                            output.write(buffer, 0, read)
                            val done = (written * 100 / installer.length).toInt()
                            if (done != percent) {
                                percent = done
                                progress(done / 100f)
                            }
                        }
                    }
                    if (written != installer.length) {
                        Files.delete(file)
                        Log.e(TAG) { "the installer from ${installer.url} isn't the feed's ${installer.length} bytes: refused" }
                        throw UpdateRejectedException("the installer's size doesn't match the feed's")
                    }
                }
            } finally {
                body.cancel()
            }
        }
        return file
    }

    private fun HttpResponse.requireOk(what: String) {
        if (status != HttpStatusCode.OK) throw IOException("$what answered HTTP ${status.value}")
    }

    companion object {
        private const val TAG = "updates"
        private const val OS = "windows"
        private const val INSTALLER_NAME = "plezy-windows-installer.exe"
        private val FEED_TIMEOUT = 30.seconds
        private const val MAX_FEED_BYTES = 1L shl 20

        /** Inno Setup's silent install without its first prompt. A constant: the feed isn't signed. */
        private val INSTALLER_ARGUMENTS = listOf("/SILENT", "/SP-")

        /** The feed the release workflow publishes. */
        const val FEED_URL = "https://cdn.jsdelivr.net/gh/edde746/plezy@appcast/appcast.xml"

        /** Starts [installer] with [arguments] as a process of its own, which outlives the app. */
        fun startDetached(installer: Path, arguments: List<String>) {
            ProcessBuilder(listOf(installer.toString()) + arguments)
                .redirectInput(Redirect.from(Path.of("NUL").toFile()))
                .redirectOutput(Redirect.DISCARD)
                .redirectError(Redirect.DISCARD)
                .start()
        }
    }
}
