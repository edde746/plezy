package com.edde746.plezy.players

import android.annotation.SuppressLint
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Parcelable
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResult
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.FileProvider
import com.edde746.plezy.log.Log
import com.edde746.plezy.playback.players.AndroidExtra
import com.edde746.plezy.playback.players.AndroidPlayers
import com.edde746.plezy.playback.players.AndroidSource
import com.edde746.plezy.playback.players.AndroidSubtitle
import com.edde746.plezy.playback.players.ExternalLaunchStatus
import com.edde746.plezy.playback.players.ExternalPlaybackResult
import com.edde746.plezy.playback.players.ExternalPlayerLaunch
import com.edde746.plezy.playback.players.ExternalPlayerLauncher
import com.edde746.plezy.playback.players.ExternalPlayerPlatform
import com.edde746.plezy.playback.players.ExternalPlayerSubtitle
import com.edde746.plezy.playback.players.PlayerInstallProbe
import java.io.File

/**
 * External players on Android phones, tablets and TVs (`AppPlatform.externalPlayers`), one per process: an
 * `ACTION_VIEW` of any video type with [AndroidPlayers]' extras, started for a result through the activity's launcher
 * ([attach]) for each of the launch's packages in turn (none: Android resolves it), and the result read back.
 *
 * An http(s) URL goes as it is; a `content://` URI with a read grant; a download's file (a path or a `file://` URL) as
 * a [PlayerFiles] `content://` URI with a read grant. The grant reaches the data URI and the ClipData, never extras, so
 * a shared subtitle rides in the ClipData too. One launch at a time: another while a player hasn't answered fails.
 * Nothing here logs a URL or an extra.
 */
internal class AndroidPlayerApps(context: Context) : ExternalPlayerLauncher {
    private val context: Context = context.applicationContext

    /** The activity showing the app and its result launcher, while one does. Main thread. */
    private var activity: ComponentActivity? = null
    private var results: ActivityResultLauncher<Intent>? = null

    /** Where the awaited launch's result goes. Main thread. */
    private var pending: ((ExternalPlaybackResult) -> Unit)? = null

    override val platform: ExternalPlayerPlatform = ExternalPlayerPlatform.ANDROID

    /** Android lists every known player: no app is probed for. */
    override val probe: PlayerInstallProbe = object : PlayerInstallProbe {
        override val environment: Map<String, String> = emptyMap()
        override suspend fun commandExists(command: String) = true
        override suspend fun fileExists(path: String) = true
        override suspend fun applicationInstalled(bundleId: String) = true
        override suspend fun schemeHasHandler(scheme: String) = true
    }

    /**
     * Registers [activity]'s result launcher, in its `onCreate` (before it starts): results come back to it, also those
     * of a launch an earlier activity made.
     *
     * Lint's fragment check fires on libraries that ask for androidx.fragment before 1.3.0 (1.5.7 resolves), and is
     * about a FragmentActivity's request codes: the activity is a plain ComponentActivity.
     */
    @SuppressLint("InvalidFragmentVersionForActivityResult")
    fun attach(activity: ComponentActivity) {
        this.activity = activity
        results = activity.registerForActivityResult(ActivityResultContracts.StartActivityForResult(), ::onResult)
    }

    /**
     * [activity] is destroyed. Recreated, the next activity's launcher gets the result; finishing, no result comes and
     * the launch is forgotten.
     */
    fun detach(activity: ComponentActivity) {
        if (this.activity !== activity) return
        this.activity = null
        results = null
        if (activity.isFinishing && pending != null) {
            Log.w(TAG) { "The activity finished while an external player was active" }
            pending = null
        }
    }

    override suspend fun launch(launch: ExternalPlayerLaunch, ended: (ExternalPlaybackResult) -> Unit): ExternalLaunchStatus {
        val results = results ?: return ExternalLaunchStatus.FAILED
        if (pending != null) {
            Log.w(TAG) { "An external player is already active" }
            return ExternalLaunchStatus.FAILED
        }
        val intent = try {
            val subtitles = launch.subtitles.mapNotNull(::subtitle)
            buildIntent(source(launch.url), launch.startPositionMs, launch.title, subtitles)
        } catch (e: IllegalArgumentException) {
            Log.w(TAG) { "The download's file can't be shared: ${e.javaClass.simpleName}" }
            return ExternalLaunchStatus.FAILED
        }
        val packages: List<String?> = launch.packages.ifEmpty { listOf(null) }
        for (packageName in packages) {
            try {
                results.launch(Intent(intent).setPackage(packageName))
            } catch (_: ActivityNotFoundException) {
                continue
            } catch (e: RuntimeException) {
                // By its class only: a refusal's message names the intent, the stream's link with it.
                Log.w(TAG) { "${packageName ?: "The system"} refused the launch: ${e.javaClass.simpleName}" }
                return ExternalLaunchStatus.FAILED
            }
            pending = ended
            Log.i(TAG) { "Started ${packageName ?: "the system's video player"} at ${launch.startPositionMs} ms" }
            return ExternalLaunchStatus.LAUNCHED
        }
        Log.w(TAG) { "No app found for ${launch.packages.ifEmpty { listOf("video") }.joinToString()}" }
        return ExternalLaunchStatus.NOT_INSTALLED
    }

    private fun onResult(result: ActivityResult) {
        val ended = pending
        pending = null
        if (ended == null) {
            Log.w(TAG) { "Result received without a pending launch" }
            return
        }
        val data = result.data
        val read = readResult(result.resultCode, data)
        Log.i(TAG) { "Player returned ${result.resultCode} (${data?.action}): $read" }
        ended(read)
    }

    /** [url] as the intent hands it: an http(s) URL as it is, a `content://` URI or a local file shared with a grant. */
    private fun source(url: String): Source {
        if (url.startsWith("http://") || url.startsWith("https://")) {
            val uri = Uri.parse(url)
            return Source(uri, grantRead = false, fileName = uri.lastPathSegment)
        }
        if (url.startsWith("content://")) {
            val uri = Uri.parse(url)
            return Source(uri, grantRead = true, fileName = uri.lastPathSegment)
        }
        val file = File(if (url.startsWith("file://")) Uri.parse(url).path.orEmpty() else url)
        val uri = FileProvider.getUriForFile(context, "${context.packageName}$AUTHORITY_SUFFIX", file)
        return Source(uri, grantRead = true, fileName = file.name)
    }

    /** One subtitle, or null when [PlayerFiles] refuses its path: losing one subtitle must not cost the launch. */
    private fun subtitle(subtitle: ExternalPlayerSubtitle): Subtitle? = try {
        Subtitle(source(subtitle.uri), subtitle.name, subtitle.enabled)
    } catch (e: IllegalArgumentException) {
        Log.w(TAG) { "Skipping a subtitle that can't be shared: ${e.javaClass.simpleName}" }
        null
    }

    /** A file the intent hands over: [grantRead] when the player needs this app's read grant for it. */
    internal data class Source(val uri: Uri, val grantRead: Boolean, val fileName: String?)

    internal data class Subtitle(val source: Source, val name: String?, val enabled: Boolean)

    internal companion object {
        const val TAG = "ExternalPlayers"

        /**
         * [PlayerFiles]' authority after the application id (the manifest's `${applicationId}.fileprovider`):
         * `com.edde746.plezy.fileprovider` in the release build.
         */
        const val AUTHORITY_SUFFIX = ".fileprovider"

        /** The intent for [source]: [AndroidPlayers.extras] as the players read them, the shared files granted. */
        fun buildIntent(source: Source, startPositionMs: Long, title: String?, subtitles: List<Subtitle> = emptyList()): Intent =
            Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(source.uri, "video/*")
                if (source.grantRead) addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                val extras = AndroidPlayers.extras(
                    AndroidSource(source.uri.toString(), source.fileName),
                    startPositionMs,
                    title,
                    subtitles.map { AndroidSubtitle(AndroidSource(it.source.uri.toString(), it.source.fileName), it.name, it.enabled) },
                )
                for (extra in extras) put(extra)
                val shared = subtitles.filter { it.source.grantRead }.map { it.source.uri }
                if (shared.isNotEmpty()) {
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    clipData = ClipData.newRawUri(null, shared.first()).apply { shared.drop(1).forEach { addItem(ClipData.Item(it)) } }
                }
            }

        /** What the player's result intent [data] says ([AndroidPlayers.result]). */
        fun readResult(resultCode: Int, data: Intent?): ExternalPlaybackResult {
            val extras = try {
                data?.extras?.let(::values).orEmpty()
            } catch (e: RuntimeException) {
                // A value of a class only the player has.
                Log.w(TAG) { "The player's result can't be read: ${e.javaClass.simpleName}" }
                emptyMap()
            }
            return AndroidPlayers.result(data?.action, resultCode, extras)
        }

        @Suppress("DEPRECATION")
        private fun values(bundle: Bundle): Map<String, Any?> = bundle.keySet().associateWith { bundle.get(it) }

        private fun Intent.put(extra: AndroidExtra) {
            when (extra) {
                is AndroidExtra.Text -> putExtra(extra.key, extra.value)
                is AndroidExtra.Texts -> putExtra(extra.key, extra.values.toTypedArray())
                is AndroidExtra.IntValue -> putExtra(extra.key, extra.value)
                is AndroidExtra.Flag -> putExtra(extra.key, extra.value)
                is AndroidExtra.Uris -> putExtra(extra.key, Array<Parcelable>(extra.uris.size) { Uri.parse(extra.uris[it]) })
            }
        }
    }
}

/**
 * Shares a download's file and its saved subtitles with the player app it is handed to: only those, each to that app
 * alone, read-only (`res/xml/file_provider_paths.xml` names the roots: the app's files, caches and external
 * directories, shared storage, and the file system's root for any other path). Its own class, so no library's
 * FileProvider entry in the merged manifest collides with it.
 */
class PlayerFiles : FileProvider()
