package com.bbflight.background_downloader

import android.annotation.SuppressLint
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.system.Os
import android.system.OsConstants
import android.util.Log
import androidx.core.content.FileProvider.getUriForFile
import androidx.preference.PreferenceManager
import com.bbflight.background_downloader.TaskRunner.Companion.TAG
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CompletableDeferred
import java.io.File
import java.io.FileOutputStream
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager
import kotlin.io.path.Path
import kotlin.io.path.pathString


/**
 * Installs a custom X509 TrustManager that accepts all certificates. Future
 * HTTPS calls will therefore not check the validity of the TLS certificate.
 *
 * DO NOT CONFIGURE THE DOWNLOADER TO BYPASS CERTIFICATE VALIDATION IN RELEASE
 */
fun acceptUntrustedCertificates() {
    try {
        // Create a trust manager that does not validate certificate chains
        val trustAllCerts = arrayOf<TrustManager>(
            @SuppressLint("CustomX509TrustManager")
            object : X509TrustManager {
                @SuppressLint("TrustAllX509TrustManager")
                override fun checkClientTrusted(
                    chain: Array<java.security.cert.X509Certificate>,
                    authType: String
                ) {
                }

                @SuppressLint("TrustAllX509TrustManager")
                override fun checkServerTrusted(
                    chain: Array<java.security.cert.X509Certificate>,
                    authType: String
                ) {
                }

                override fun getAcceptedIssuers(): Array<java.security.cert.X509Certificate> {
                    return arrayOf()
                }
            })

        // Install the all-trusting trust manager
        val sslContext = SSLContext.getInstance("TLS")
        sslContext.init(null, trustAllCerts, java.security.SecureRandom())
        // Create an ssl socket factory with our all-trusting manager
        HttpsURLConnection.setDefaultSSLSocketFactory(sslContext.socketFactory)
        Log.w(
            BDPlugin.TAG, "Bypassing TLS certificate validation\n" +
                    "HTTPS calls will NOT check the validity of the TLS certificate."
        )
    } catch (e: Exception) {
        throw RuntimeException(e)
    }
}

/** Query the filesystem actually backing this descriptor, never the app data volume. */
internal fun guardedDownloadOutput(
    applicationContext: Context,
    output: FileOutputStream,
    contentLength: Long,
    removeIncomplete: () -> Unit
): DownloadStorageGuard = DownloadStorageGuard(
    output,
    PreferenceManager.getDefaultSharedPreferences(applicationContext)
        .getInt(BDPlugin.keyConfigCheckAvailableSpace, 0),
    contentLength,
    {
        // SAF providers may return pipes or proxies, which do not identify storage.
        require(OsConstants.S_ISREG(Os.fstat(output.fd).st_mode))
        val stat = Os.fstatvfs(output.fd)
        DownloadVolumeCapacity(
            Math.multiplyExact(stat.f_bavail, stat.f_frsize),
            Math.multiplyExact(stat.f_blocks, stat.f_frsize)
        )
    },
    removeIncomplete,
    { error ->
        generateSequence<Throwable>(error) { it.cause }.any {
            it is android.system.ErrnoException &&
                (it.errno == OsConstants.ENOSPC || it.errno == OsConstants.EDQUOT)
        }
    }
)

/**
 * 8-char lowercase hex FNV-1a 32-bit hash of [taskId]
 *
 * MUST stay identical to partFileSuffix in lib/src/resume_data_cleanup.dart:
 * the Dart orphan scan reconstructs Android-created part file paths from the
 * destination path and taskId alone
 */
fun partFileSuffix(taskId: String): String {
    var hash = 0x811c9dc5L
    for (b in taskId.toByteArray(Charsets.UTF_8)) {
        hash = ((hash xor (b.toLong() and 0xffL)) * 0x01000193L) and 0xffffffffL
    }
    return hash.toString(16).padStart(8, '0')
}

/**
 * Returns the destination-local temporary file path for a download
 *
 * The taskId-derived suffix keeps temp files of different tasks targeting
 * the same destination from colliding
 */
fun partialDownloadFilePath(destFilePath: String, taskId: String): String =
    "$destFilePath.${partFileSuffix(taskId)}.part"

/**
 * Parses the range in a Range header, and returns a Pair representing
 * the range. The format needs to be "bytes=10-20"
 *
 * A missing lower range is substituted with 0L, and a missing upper
 * range with null.  If the string cannot be parsed, returns (0L, null)
 */
fun parseRange(rangeStr: String): Pair<Long, Long?> {
    val regex = Regex("""bytes=(\d*)-(\d*)""")
    val match = regex.find(rangeStr) ?: return Pair(0, null)
    val start = match.groupValues[1].toLongOrNull() ?: 0L
    val end = match.groupValues[2].toLongOrNull()
    return Pair(start, end)
}

fun headerValue(responseHeaders: Map<String, List<String>>, name: String): String? =
    responseHeaders.entries.firstOrNull { it.key.equals(name, ignoreCase = true) }
        ?.value
        ?.firstOrNull { it.isNotEmpty() }

fun taskHeaderValue(headers: Map<String, String>, name: String): String? =
    headers.entries.firstOrNull { it.key.equals(name, ignoreCase = true) }
        ?.value
        ?.takeIf { it.isNotEmpty() }

/**
 * Returns the content length extracted from the [responseHeaders], or from
 * the [task] headers
 */
fun getContentLength(responseHeaders: Map<String, List<String>>, task: Task): Long {
    // if response provides contentLength, return it
    val contentLength = headerValue(responseHeaders, "Content-Length")?.toLongOrNull()
        ?: -1L
    if (contentLength != -1L) {
        return contentLength
    }
    // try extracting it from Range header
    val taskRangeHeader = taskHeaderValue(task.headers, "Range") ?: ""
    val taskRange = parseRange(taskRangeHeader)
    if (taskRange.second != null) {
        val rangeLength = taskRange.second!! - taskRange.first + 1L
        Log.d(TAG, "TaskId ${task.taskId} contentLength set to $rangeLength based on Range header")
        return rangeLength
    }
    // try extracting it from a special "Known-Content-Length" header
    val knownLength = (taskHeaderValue(task.headers, "Known-Content-Length")?.toLongOrNull()
        ?: -1)
    if (knownLength != -1L) {
        Log.d(
            TAG,
            "TaskId ${task.taskId} contentLength set to $knownLength based on Known-Content-Length header"
        )
    } else {
        Log.d(TAG, "TaskId ${task.taskId} contentLength undetermined")
    }
    return knownLength
}


/**
 * Return the path to the baseDir for this [baseDirectory], or null if path could not be reached
 *
 * Null only happens if external storage is requested but not available
 */
fun baseDirPath(context: Context, baseDirectory: BaseDirectory): String? {
    val useExternalStorage = PreferenceManager.getDefaultSharedPreferences(context)
        .getInt(BDPlugin.keyConfigUseExternalStorage, -1) == 0
    val baseDirPath: String
    if (!useExternalStorage) {
        if (Build.VERSION.SDK_INT >= 26) {
            baseDirPath = when (baseDirectory) {
                BaseDirectory.applicationDocuments -> Path(
                    context.dataDir.path, "app_flutter"
                ).pathString

                BaseDirectory.temporary -> context.cacheDir.path
                BaseDirectory.applicationSupport -> context.filesDir.path
                BaseDirectory.applicationLibrary -> Path(
                    context.filesDir.path, "Library"
                ).pathString

                BaseDirectory.root -> ""
            }
        } else {
            baseDirPath = when (baseDirectory) {
                BaseDirectory.applicationDocuments -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    "${context.dataDir.path}/app_flutter"
                } else {
                    "${context.applicationInfo.dataDir}/app_flutter"
                }

                BaseDirectory.temporary -> context.cacheDir.path
                BaseDirectory.applicationSupport -> context.filesDir.path
                BaseDirectory.applicationLibrary -> "${context.filesDir.path}/Library"
                BaseDirectory.root -> ""
            }
        }
    } else {
        // external storage variant
        val externalStorageDirectory = context.getExternalFilesDir(null)
        val externalCacheDirectory = context.externalCacheDir
        if (externalStorageDirectory == null || externalCacheDirectory == null) {
            Log.e(TAG, "Could not access external storage")
            return null
        }
        baseDirPath = when (baseDirectory) {
            BaseDirectory.applicationDocuments -> externalStorageDirectory.path
            BaseDirectory.temporary -> externalCacheDirectory.path
            BaseDirectory.applicationSupport -> "${externalStorageDirectory.path}/Support"
            BaseDirectory.applicationLibrary -> "${externalStorageDirectory.path}/Library"
            BaseDirectory.root -> ""
        }
    }
    return baseDirPath
}

fun getBasenameWithoutExtension(file: File): String {
    val fileName = file.name
    val extension = file.extension
    return fileName.substringBeforeLast(".$extension")
}

/**
 * Returns the Uri for the given [filePath], or null if not allowed/possible
 */
fun getUriFromFilePath(context: Context, filePath: String): String? {
    try {
        val contentUri = getUriForFile(
            context,
            context.packageName + ".com.bbflight.background_downloader.fileprovider",
            File(filePath)
        )
        return contentUri.toString()
    } catch (e: Exception) {
        Log.i(BDPlugin.TAG, "Failed to get Uri for file $filePath: $e")
        return null
    }
}

/**
 * Suggests a filename based on response headers and a URL. If none can be derived, returns ""
 *
 * @param responseHeaders The response headers map.
 * @param url             The URL the file would be downloaded from.
 * @return A suggested filename, derived from the headers or the URL.
 */
fun suggestFilename(responseHeaders: Map<String, List<String>>, url: String): String {
    val disposition = headerValue(responseHeaders, "Content-Disposition")
    val filename = disposition?.let { filenameFromContentDisposition(it) }
    if (!filename.isNullOrEmpty()) {
        return filename
    }
    // Try filename derived from last path segment of the url
    try {
        val uri = Uri.parse(url)
        return getFilenameFromUri(uri)
    } catch (_: Throwable) {
    }
    return "" // Default fallback
}

fun filenameFromContentDisposition(disposition: String): String? {
    val parameters = contentDispositionParameters(disposition)
    val encodedFilename = parameters["filename*"]
    if (encodedFilename != null) {
        val decoded = decodeExtendedFilename(encodedFilename)
        if (!decoded.isNullOrEmpty()) return decoded
    }
    return parameters["filename"]
}

private fun decodeExtendedFilename(value: String): String? {
    val firstQuote = value.indexOf('\'')
    if (firstQuote < 0) return value
    val secondQuote = value.indexOf('\'', firstQuote + 1)
    if (secondQuote < 0) return value
    val charset = value.substring(0, firstQuote).uppercase()
    val encoded = value.substring(secondQuote + 1)
    if (charset != "UTF-8") return encoded
    return Uri.decode(encoded)
}

private fun contentDispositionParameters(disposition: String): Map<String, String> {
    val parameters = mutableMapOf<String, String>()
    for (segment in splitContentDisposition(disposition).drop(1)) {
        val equalsIndex = segment.indexOf('=')
        if (equalsIndex <= 0) continue
        val key = segment.substring(0, equalsIndex).trim().lowercase()
        val value = unquoteHeaderValue(segment.substring(equalsIndex + 1).trim())
        if (key.isNotEmpty() && value.isNotEmpty()) parameters[key] = value
    }
    return parameters
}

private fun splitContentDisposition(value: String): List<String> {
    val segments = mutableListOf<String>()
    val current = StringBuilder()
    var inQuotes = false
    var escaped = false
    for (char in value) {
        if (escaped) {
            current.append(char)
            escaped = false
            continue
        }
        if (char == '\\' && inQuotes) {
            escaped = true
            current.append(char)
            continue
        }
        if (char == '"') {
            inQuotes = !inQuotes
            current.append(char)
            continue
        }
        if (char == ';' && !inQuotes) {
            segments.add(current.toString().trim())
            current.clear()
            continue
        }
        current.append(char)
    }
    segments.add(current.toString().trim())
    return segments
}

private fun unquoteHeaderValue(value: String): String =
    if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
        value.substring(1, value.length - 1)
            .replace("\\\"", "\"")
            .replace("\\\\", "\\")
    } else value

/**
 * Returns the filename from the given [uri]
 *
 * Returns "" if not possible
 *
 * Slightly modified from lastPathSegment to account for possible subdirs in that last segment
 * (e.g. '/primary:Documents/dog-drawing.jpg' will have 'Documents/dog-drawing.jpg' as last path
 * segment, not 'dog-drawing.jpg')
 */
fun getFilenameFromUri(uri: Uri): String {
    val lastPathSegment = uri.lastPathSegment
    if (lastPathSegment != null) {
        val lastSlashIndex = lastPathSegment.lastIndexOf("/")
        val filename =
            if (lastSlashIndex != -1) lastPathSegment.substring(lastSlashIndex + 1) else lastPathSegment
        return filename
    }
    return ""
}

// Helper extension to filter out null values from Maps
fun <K, V> Map<K, V>?.filterNotNull(): Map<K, V> {
    return this?.filter { (key, value) -> key != null && value != null } ?: emptyMap()
}

/**
 * Simple Flutter result handler, completes the [completer] with true if the result of the
 * method call is true, and false otherwise
 */
class FlutterBooleanResultHandler(private val completer: CompletableDeferred<Boolean>) :
    MethodChannel.Result {

    override fun success(result: Any?) {
        completer.complete(result == true)
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
        Log.i(BDPlugin.TAG, "Flutter result error $errorCode: $errorMessage")
        completer.complete(false)
    }

    override fun notImplemented() {
        Log.i(BDPlugin.TAG, "Flutter method not implemented")
        completer.complete(false)
    }
}

/**
 * Flutter result handler, completes the [completer] with the result of the method call
 */
class FlutterResultHandler<T>(private val completer: CompletableDeferred<T?>) :
    MethodChannel.Result {

    override fun success(result: Any?) {
        @Suppress("UNCHECKED_CAST")
        val castedResult = result as? T?
        completer.complete(castedResult)
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
        Log.i(BDPlugin.TAG, "Flutter result error $errorCode: $errorMessage")
        completer.complete(null)
    }

    override fun notImplemented() {
        Log.i(BDPlugin.TAG, "Flutter method not implemented")
        completer.complete(null)
    }
}
