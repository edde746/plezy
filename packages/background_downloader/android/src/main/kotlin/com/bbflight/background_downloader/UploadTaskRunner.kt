package com.bbflight.background_downloader

import android.content.ContentResolver
import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Log
import androidx.core.net.toFile
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.DataOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.InputStream
import java.net.HttpURLConnection
import android.database.Cursor

class UploadTaskRunner(context: TaskJobContext) : TaskRunner(context) {

    companion object {
        private val asciiOnlyRegEx = Regex("^[\\x00-\\x7F]+$")
        private val jsonStringRegEx = Regex("^\\s*(\\{.*\\}|\\[.*\\])\\s*$")
        private val newlineRegEx = Regex("\r\n|\r|\n")
        const val boundary = "-----background_downloader-akjhfw281onqciyhnIk"
        const val lineFeed = "\r\n"
    }

    /**
     * Process the upload of the file
     *
     * If the [Task.post] field is set to "binary" then the file will be uploaded as a byte stream POST
     *
     * If the [Task.post] field is not "binary" then the file(s) will be uploaded as a multipart POST
     *
     * Note that the [Task.post] field is just used to set whether this is a binary or multipart
     * upload. The bytes that will be posted are derived from the file to be uploaded.
     *
     * Returns the [TaskStatus]
     */
    override suspend fun process(
        connection: HttpURLConnection
    ): TaskStatus {
        connection.doOutput = true
        val transferBytesResult =
            if (task.post?.lowercase() == "binary") {
                processBinaryUpload(connection)
            } else {
                processMultipartUpload(connection)
            }
        when (transferBytesResult) {
            TaskStatus.canceled -> {
                Log.i(TAG, "Canceled taskId ${task.taskId}")
                return TaskStatus.canceled
            }

            TaskStatus.failed -> {
                return TaskStatus.failed
            }

            TaskStatus.complete -> {
                extractResponseBody(connection)
                extractResponseHeaders(connection.headerFields)
                responseStatusCode = connection.responseCode
                if (connection.responseCode in 200..206) {
                    Log.i(
                        TAG, "Successfully uploaded taskId ${task.taskId}"
                    )
                    return TaskStatus.complete
                }
                Log.i(
                    TAG,
                    "Response code ${connection.responseCode} for taskId ${task.taskId}"
                )
                val errorContent = responseErrorContent(connection)
                taskException = TaskException(
                    ExceptionType.httpResponse, httpResponseCode = connection.responseCode,
                    description = if (errorContent?.isNotEmpty() == true) errorContent else connection.responseMessage
                )
                return if (connection.responseCode == 404) {
                    TaskStatus.notFound
                } else {
                    TaskStatus.failed
                }
            }

            else -> {
                return TaskStatus.failed
            }
        }
    }

    /**
     * Process the binary upload of the file
     *
     * Content-Disposition header will be:
     *   - set to 'attachment = "filename"' if the task.headers field does not contain an entry for
     *     'Content-Disposition'
     *   - not set at all (i.e. omitted) if the task.headers field contains an entry for
     *     'Content-Disposition' with the value "" (an empty string)
     *   - set to the value of task.headers['Content-Disposition'] in all other cases
     *
     * The mime-type will be set to [Task.mimeType]
     *
     * Returns the [TaskStatus]
     */
    private suspend fun processBinaryUpload(
        connection: HttpURLConnection
    ): TaskStatus {
        val (filename, fileUri) = UriUtils.unpack(task.filename)
        var resolvedMimeType = task.mimeType
        val (fileSize, inputStream) = withContext(Dispatchers.IO) { // Use Dispatchers.IO for file operations
            if (fileUri != null) {
                try {
                    if (filename == null) {
                        // attempt to set a filename for the uploaded file in the task object
                        val derivedFilename = getFileNameFromUri(fileUri)
                        if (derivedFilename != null) {
                            task = task.copyWith(filename = UriUtils.pack(derivedFilename, fileUri))
                        }
                        if (resolvedMimeType.isEmpty()) resolvedMimeType =
                            getMimeType(derivedFilename ?: "")
                    }
                    if (fileUri.scheme != "file") {
                        // a content:// URI scheme is resolved via the contentResolver
                        val contentResolver = context.appContext.contentResolver
                        // Get file size from URI
                        val fileSize =
                            contentResolver.query(fileUri, null, null, null, null)?.use { cursor ->
                                val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                                cursor.moveToFirst()
                                if (sizeIndex != -1) cursor.getLong(sizeIndex) else null
                            } ?: run {
                                val message =
                                    "Could not open file or determine file size for URI: $fileUri"
                                Log.w(TAG, message)
                                taskException = TaskException(
                                    ExceptionType.fileSystem,
                                    description = message
                                )
                                return@withContext Pair(
                                    null,
                                    null
                                ) // Return nulls to indicate failure
                            }
                        if (resolvedMimeType.isEmpty()) resolvedMimeType =
                            getMimeType(contentResolver, fileUri)
                        // Get InputStream from URI
                        val inputStream = contentResolver.openInputStream(fileUri) ?: run {
                            val message = "Could not open input stream for URI: $fileUri"
                            Log.w(TAG, message)
                            taskException = TaskException(
                                ExceptionType.fileSystem,
                                description = message
                            )
                            return@withContext Pair(null, null) // Return nulls to indicate failure
                        }
                        Pair(fileSize, inputStream)
                    } else {
                        // a file:// Uri scheme is interpreted as a regular file path
                        val file = fileUri.toFile()
                        val fileSize = file.length()
                        if (resolvedMimeType.isEmpty()) resolvedMimeType =
                            getMimeType(file.name)
                        Pair(fileSize, FileInputStream(file))
                    }
                } catch (e: Exception) {
                    val message = "Error processing URI: ${task.directory}"
                    Log.w(TAG, message, e)
                    taskException = TaskException(
                        ExceptionType.fileSystem,
                        description = message
                    )
                    return@withContext Pair(null, null) // Return nulls to indicate failure
                }
            } else {
                val filePath = task.filePath(context.appContext)
                val file = File(filePath)
                if (!file.exists() || !file.isFile) {
                    val message = "File to upload does not exist: $filePath"
                    Log.w(TAG, message)
                    taskException = TaskException(
                        ExceptionType.fileSystem,
                        description = message
                    )
                    return@withContext Pair(null, null) // Return nulls to indicate failure
                }
                val fileSize = file.length()
                if (fileSize <= 0) {
                    val message = "File $filePath has 0 length"
                    Log.w(TAG, message)
                    taskException = TaskException(
                        ExceptionType.fileSystem,
                        description = message
                    )
                    return@withContext Pair(null, null)
                }
                if (resolvedMimeType.isEmpty()) resolvedMimeType =
                    getMimeType(file.name)
                Pair(fileSize, FileInputStream(file))
            }
        }
        // Check for failures in getting fileSize and inputStream
        if (fileSize == null || inputStream == null) {
            try { inputStream?.close() } catch (_: Exception) {}
            return TaskStatus.failed
        }
        return inputStream.use { fis ->
            // Extract Range header information
            var start = 0L
            var end = fileSize - 1 // Default to the whole file
            val rangeHeader = task.headers["Range"]
            if (rangeHeader != null) {
                val match = Regex("""bytes=(\d+)-(\d*)""").find(rangeHeader)
                if (match != null) {
                    start = match.groupValues[1].toLong()
                    if (match.groupValues.size > 2 && match.groupValues[2].isNotEmpty()) {
                        end = match.groupValues[2].toLong()
                    }
                } else {
                    val message = "Invalid Range header $rangeHeader"
                    Log.w(TAG, message)
                    taskException = TaskException(
                        ExceptionType.general,
                        description = message
                    )
                    return TaskStatus.failed
                }
            }
            val contentLength = end - start + 1
            determineRunInForeground(task, contentLength)
            context.updateEstimatedNetworkBytes(0L, contentLength)
            Log.d(TAG, "Binary upload for taskId ${task.taskId}")
            connection.setRequestProperty("Content-Type", resolvedMimeType)
            val taskContentDisposition =
                task.headers["Content-Disposition"] ?: task.headers["content-disposition"]
            if (taskContentDisposition != "") {
                connection.setRequestProperty(
                    "Content-Disposition",
                    taskContentDisposition
                        ?: ("attachment; filename=\"" + Uri.encode(task.filename) + "\"")
                )
            }
            connection.setRequestProperty("Content-Length", contentLength.toString())
            connection.setFixedLengthStreamingMode(contentLength)
            withContext(Dispatchers.IO) {
                if (rangeHeader != null) {
                    // Special treatment for partial uploads
                    fis.skip(start)
                }
                LimitedInputStream(fis, contentLength).use { limitedInputStream ->
                    DataOutputStream(connection.outputStream.buffered()).use { outputStream ->
                        return@withContext transferBytes(
                            limitedInputStream,
                            outputStream,
                            if (rangeHeader != null) contentLength else fileSize,
                            task
                        )
                    }
                }
            }
        }
    }


    /**
     * Process the multi-part upload of one or more files, and potential form fields
     *
     * Form fields are taken from [Task.fields]. If only one file is to be uploaded,
     * then [Task.filename] determines the file (can be a file path or a Uri string),
     * and [Task.fileField] and [Task.mimeType] are used to set the file field name
     * and mime type respectively.
     * For MultiUploadTasks, the list of fileField, filePath and mimeType are
     * extracted from the [Task.fileField], [Task.filename] and [Task.mimeType] (which
     * for MultiUploadTasks contain a JSON encoded list of strings).
     *
     * The total content length is calculated from the sum of all parts if all files are
     * given as file paths or file:// Uris. If one or more files are given as content:// Uris,
     * then chunked encoding is used.
     *
     * The connection is set up, and the bytes for each part are transferred to the host.
     *
     * Returns the [TaskStatus]
     */
    private suspend fun processMultipartUpload(
        connection: HttpURLConnection,
    ): TaskStatus {
        // field portion of the multipart, all in one string
        // multiple values should be encoded as '"value1", "value2", ...'
        val multiValueRegEx = Regex("""^(?:"[^"]+"\s*,\s*)+"[^"]+"$""")
        var fieldsString = ""
        for (entry in task.fields.entries) {
            // Check if the entry value matches the multiple values format
            if (multiValueRegEx.matches(entry.value)) {
                // Extract multiple values from entry.value
                val valueMatches = Regex(""""([^"]+)"""").findAll(entry.value)
                for (match in valueMatches) {
                    fieldsString += fieldEntry(entry.key, match.groupValues[1])
                }
            } else {
                // Handle single value for key
                fieldsString += fieldEntry(entry.key, entry.value)
            }
        }
        // File portion of the multi-part
        // Assumes list of files. If only one file, that becomes a list of length one.
        // For each file, determine contentDispositionString, contentTypeString
        // and file length or InputStream, so that we can calculate total size of
        // upload or use chunked encoding.
        val separator = "$lineFeed--$boundary$lineFeed" // between files
        val terminator = "$lineFeed--$boundary--$lineFeed" // after last file
        val fileUri = UriUtils.uriFromStringValue(task.filename)
        val filePath = task.filePath(context.appContext)
        // fileData's second field contains either a file path or a Uri string
        val filesData = if (filePath.isNotEmpty()) {
            listOf(
                Triple(task.fileField, fileUri?.toString() ?: filePath, task.mimeType)
            )
        } else {
            task.extractFilesData(context.appContext)
        }
        val contentDispositionStrings = ArrayList<String>()
        val contentTypeStrings = ArrayList<String>()
        val fileLengthsOrStreams = ArrayList<Pair<Long?, InputStream?>>()
        try {
            var useChunkedEncoding = false
            for ((fileField, pathOrUriString, mimeType) in filesData) {
                var resolvedMimeType = mimeType // we need to change it if it is empty
                try {
                    val fileUri = UriUtils.uriFromStringValue(pathOrUriString)
                    val (fileSize, inputStream) = if (fileUri != null) {
                        if (fileUri.scheme != "file") {
                            // a content:// URI scheme is resolved via the contentResolver
                            val contentResolver = context.appContext.contentResolver
                            // Get file size from URI, or set to null
                            val fileSize =
                                contentResolver.query(fileUri, null, null, null, null)?.use { cursor ->
                                    val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                                    if (sizeIndex != -1 && cursor.moveToFirst()) cursor.getLong(
                                        sizeIndex
                                    ) else null
                                }
                            useChunkedEncoding = useChunkedEncoding ||
                                    fileSize == null // Use chunked encoding if file size is unknown
                            if (mimeType.isEmpty()) {
                                resolvedMimeType = getMimeType(contentResolver, fileUri)
                            }
                            // Get InputStream from URI
                            val fileInputStream = contentResolver.openInputStream(fileUri)
                            if (fileInputStream == null) {
                                val message = "Could not open input stream for URI: $fileUri"
                                Log.w(TAG, message)
                                taskException = TaskException(
                                    ExceptionType.fileSystem,
                                    description = message
                                )
                                return TaskStatus.failed
                            }
                            Log.v(TAG, "Using InputStream from URI $fileUri")
                            Pair(fileSize, fileInputStream)
                        } else {
                            // a file:// Uri scheme is interpreted as a regular file path
                            val file = fileUri.toFile()
                            val fileSize = file.length()
                            if (mimeType.isEmpty()) {
                                resolvedMimeType = getMimeType(fileUri.toString())
                            }
                            Log.v(TAG, "Using FileInputStream from URI $fileUri")
                            Pair(fileSize, FileInputStream(file))
                        }
                    } else {
                        val file = File(pathOrUriString)
                        if (!file.exists() || !file.isFile) {
                            Log.w(TAG, "File at $pathOrUriString does not exist")
                            taskException = TaskException(
                                ExceptionType.fileSystem,
                                description = "File to upload does not exist: $pathOrUriString"
                            )
                            return TaskStatus.failed
                        }
                        if (mimeType.isEmpty()) {
                            resolvedMimeType = getMimeType(file.path)
                        }
                        Pair(file.length(), FileInputStream(file))
                    }
                    // we now have a possible content length and InputStream for this file
                    if (!useChunkedEncoding && fileSize == null) {
                        val message = "Could not determine file size for $pathOrUriString"
                        Log.w(TAG, message)
                        taskException = TaskException(
                            ExceptionType.fileSystem,
                            description = message
                        )
                        return TaskStatus.failed
                    }
                    // determine the file name
                    val name = if (fileUri != null) {
                        getFileNameFromUri(fileUri) ?: "unknown"
                    } else {
                        File(pathOrUriString).name
                    }
                    contentDispositionStrings.add(
                        "Content-Disposition: form-data; name=\"${browserEncode(fileField)}\"; " +
                                "filename=\"${browserEncode(name)}\"$lineFeed"
                    )
                    if (filesData.size == 1 && task.taskType != "MultiUploadTask") {
                        // only for single file uploads do we set the task's filename property
                        task = task.copyWith(
                            filename = if (fileUri != null) UriUtils.pack(
                                name,
                                fileUri
                            ) else name
                        )
                    }
                    contentTypeStrings.add("Content-Type: $resolvedMimeType$lineFeed$lineFeed")
                    fileLengthsOrStreams.add(Pair(fileSize, inputStream))
                } catch (_: Exception) {
                    val message =
                        "Could not open file or determine file size for $pathOrUriString"
                    Log.w(TAG, message)
                    taskException = TaskException(
                        ExceptionType.fileSystem,
                        description = message
                    )
                    return TaskStatus.failed
                }
            }

            // setup the connection
            connection.setRequestProperty("Accept-Charset", "UTF-8")
            connection.setRequestProperty("Connection", "Keep-Alive")
            connection.setRequestProperty("Cache-Control", "no-cache")
            connection.setRequestProperty(
                "Content-Type", "multipart/form-data; boundary=$boundary"
            )
            if (!useChunkedEncoding) {
                // Calculate total content length only if not using chunked encoding
                val fileDataLength =
                    contentDispositionStrings.sumOf { string: String -> lengthInBytes(string) } +
                            contentTypeStrings.sumOf { string: String -> string.length } +
                            fileLengthsOrStreams.sumOf { pair ->
                                pair.first ?: 0
                            } + separator.length * contentDispositionStrings.size + 2
                val contentLength =
                    lengthInBytes(fieldsString) + "--$boundary$lineFeed".length + fileDataLength
                determineRunInForeground(task, contentLength)
                context.updateEstimatedNetworkBytes(0L, contentLength)
                connection.setRequestProperty("Content-Length", contentLength.toString())
                connection.setFixedLengthStreamingMode(contentLength)
            } else {
                determineRunInForeground(task, 1024 * 1024 * 20) // assume at least 20MB
                connection.setChunkedStreamingMode(0) // Use default chunk size
            }
            connection.useCaches = false
            // transfer the bytes
            return withContext(Dispatchers.IO) {
                DataOutputStream(connection.outputStream).use { outputStream ->
                    val writer = outputStream.writer()
                    // write form fields
                    writer.append(fieldsString).append("--${boundary}").append(lineFeed)
                    // write each file
                    for (i in filesData.indices) {
                        fileLengthsOrStreams[i].second.use { inputStream ->
                            if (inputStream != null) {
                                writer.append(contentDispositionStrings[i])
                                    .append(contentTypeStrings[i]).flush()
                                val transferBytesResult =
                                    transferBytes(
                                        inputStream,
                                        outputStream,
                                        fileLengthsOrStreams[i].first ?: 0,
                                        task
                                    )
                                if (transferBytesResult == TaskStatus.complete) {
                                    if (i < filesData.size - 1) {
                                        writer.append(separator)
                                    } else
                                        writer.append(terminator)
                                    writer.flush()
                                } else {
                                    return@withContext transferBytesResult
                                }
                            } else {
                                Log.w(TAG, "No input stream for ${filesData[i].first}")
                                taskException = TaskException(
                                    ExceptionType.fileSystem,
                                    description = "No input stream for ${filesData[i].first}"
                                )
                                return@withContext TaskStatus.failed
                            }
                        }
                    }
                    writer.close()
                }
                return@withContext TaskStatus.complete
            }
        } finally {
            for (pair in fileLengthsOrStreams) {
                try {
                    pair.second?.close()
                } catch (_: Exception) {}
            }
        }
    }

    /**
     * Returns the file name for the [uri] using the [ContentResolver], or the last path segment,
     * or null
     */
    private fun getFileNameFromUri(uri: Uri): String? {
        if (uri.scheme == "content") {
            val cursor = context.appContext.contentResolver.query(uri, null, null, null, null)
            cursor?.use {
                if (it.moveToFirst()) {
                    val nameIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (nameIndex != -1) {
                        return it.getString(nameIndex)
                    }
                }
            }
        }
        return uri.lastPathSegment
    }

    /**
     * Returns the mime type for the [uri] using the [ContentResolver] or extension
     */
    fun getMimeType(contentResolver: ContentResolver, uri: Uri): String {
        // Try to get it directly from ContentResolver
        var mimeType = contentResolver.getType(uri)
        if (mimeType != null) return mimeType
        // Try to infer it from the URL file extension if available
        return getMimeType(uri.toString())
    }

    /**
     * Helper to get mimeType from extension
     */
    private fun getMimeType(url: String): String {
        var type: String? = null
        val extension = android.webkit.MimeTypeMap.getFileExtensionFromUrl(url)
        if (extension != null) {
            type = android.webkit.MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
        }
        return type ?: "application/octet-stream"
    }


    /**
     * Extract the response's body content as a String, or null if unable, and store
     * in [responseBody]
     */
    private fun extractResponseBody(connection: HttpURLConnection) {
        try {
            responseBody = connection.inputStream.bufferedReader().readText()
            return
        } catch (e: Exception) {
            Log.i(
                TAG,
                "Could not read response body from httpResponseCode ${connection.responseCode}: $e"
            )
        }
        responseBody = null
    }

    /**
     * Returns the multipart entry for one field name/value pair
     */
    private fun fieldEntry(name: String, value: String): String {
        return "--$boundary$lineFeed${headerForField(name, value)}$value$lineFeed"
    }

    /**
     * Returns the header string for a field
     *
     * The return value is guaranteed to contain only ASCII characters
     */
    private fun headerForField(name: String, value: String): String {
        var header = "Content-Disposition: form-data; name=\"${browserEncode(name)}\""
        if (isJsonString(value)) {
            header = "$header\r\n" +
                    "Content-Type: application/json; charset=utf-8"
        } else if (!isPlainAscii(value)) {
            header = "$header\r\n" +
                    "Content-Type: text/plain; charset=utf-8\r\n" +
                    "Content-Transfer-Encoding: binary"
        }
        return "$header\r\n\r\n"
    }

    /**
     * Returns whether [string] is composed entirely of ASCII-compatible characters
     */
    private fun isPlainAscii(string: String): Boolean {
        return asciiOnlyRegEx.matches(string)
    }

    /**
     * Returns whether [string] is a JSON formatted string
     */
    private fun isJsonString(string: String): Boolean {
        return jsonStringRegEx.matches(string)
    }

    /**
     * Encode [value] in the same way browsers do
     */
    private fun browserEncode(value: String): String {
        // http://tools.ietf.org/html/rfc2388 mandates some complex encodings for
        // field names and file names, but in practice user agents seem not to
        // follow this at all. Instead, they URL-encode `\r`, `\n`, and `\r\n` as
        // `\r\n`; URL-encode `"`; and do nothing else (even for `%` or non-ASCII
        // characters). We follow their behavior.
        return value.replace(newlineRegEx, "%0D%0A").replace("\"", "%22")
    }
}

/**
 * InputStream that limits the number of bytes read
 */
class LimitedInputStream(
    private val inputStream: InputStream,
    private val limit: Long
) : InputStream() {

    private var bytesRead: Long = 0

    override fun read(): Int {
        if (bytesRead >= limit) {
            return -1 // End of stream
        }
        val result = inputStream.read()
        if (result != -1) {
            bytesRead++
        }
        return result
    }

    override fun read(b: ByteArray, off: Int, len: Int): Int {
        if (bytesRead >= limit) {
            return -1
        }
        // Adjust length to not exceed limit
        val remainingBytes: Long = limit - bytesRead
        val maxBytesToRead =
            minOf(len.toLong(), remainingBytes).toInt()
        val result = inputStream.read(b, off, maxBytesToRead)

        if (result != -1) {
            bytesRead += result
        }
        return result
    }
}
