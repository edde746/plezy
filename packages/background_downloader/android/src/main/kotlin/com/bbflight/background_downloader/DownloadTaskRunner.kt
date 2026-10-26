package com.bbflight.background_downloader

import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.net.toFile
import androidx.documentfile.provider.DocumentFile
import androidx.preference.PreferenceManager
import com.bbflight.background_downloader.UriUtils.unpack
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.withContext
import java.io.BufferedInputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.RandomAccessFile
import java.net.HttpURLConnection
import java.nio.channels.FileChannel
import java.nio.file.StandardOpenOption
import android.system.Os
import android.system.ErrnoException
import kotlin.math.absoluteValue
import kotlin.random.Random

class DownloadTaskRunner(context: TaskJobContext) : TaskRunner(context) {

    companion object {
        private val contentRangeRegex = Regex("(\\d+)-(\\d+)/(\\d+)")

        /**
         * Deletes the destination Uri at [uri]
         *
         * A SAF document is deleted through its provider's deleteDocument, as
         * DocumentsProvider rejects ContentResolver.delete
         */
        fun deleteDestination(context: Context, uri: Uri) {
            try {
                if (uri.scheme == "file") uri.toFile().delete()
                else if (DocumentFile.fromSingleUri(context, uri)?.delete() != true) {
                    Log.i(TAG, "Could not delete SAF document at $uri")
                }
            } catch (_: Exception) {
                Log.i(TAG, "Could not delete file at $uri")
            }
        }
    }

    private var eTagHeader: String? = null
    private var serverAcceptsRanges = false // if true, send resume data on fail
    private var tempFilePath = ""
    private var requiredStartByte = 0L // required start byte within the task range
    private var taskRangeStartByte = 0L // Start of the Task's download range
    private var eTag: String? = null
    private var usesUri = false
    private var safDestUri: Uri? = null // set during process() for use by prepResumeAfterFailure

    /** For SAF downloads, resume data stores the destUri; otherwise the temp file path. */
    private fun resumeDataPath(): String =
        if (usesUri) safDestUri?.toString() ?: tempFilePath else tempFilePath

    /**
     * Make the request to the [connection] and process the [Task]
     *
     * Returns the [TaskStatus]
     * */
    override suspend fun connectAndProcess(connection: HttpURLConnection): TaskStatus {
        if (isResume) {
            val taskRangeHeader = task.headers["Range"] ?: ""
            val taskRange = parseRange(taskRangeHeader)
            taskRangeStartByte = taskRange.first
            val resumeRange = Pair(taskRangeStartByte + requiredStartByte, taskRange.second)
            val newRangeString = "bytes=${resumeRange.first}-${resumeRange.second ?: ""}"
            connection.setRequestProperty("Range", newRangeString)
        }
        val result = super.connectAndProcess(connection)
        when (result) {
            TaskStatus.failed -> when {
                isInterruptedBySystem -> handOffPartialDownload()
                BDPlugin.canceledTaskIds.contains(task.taskId) -> cleanup(usesUri, safDestUri)
                else -> prepResumeAfterFailure()
            }
            // A SAF download writes straight to its destination document, not a temp file
            TaskStatus.canceled -> cleanup(usesUri, safDestUri)
            else -> {}
        }
        return result
    }

    /**
     * Hand this stopped run's partial file to the task's next run: record where the file ends,
     * or delete it if the next run cannot resume from it, so that run starts clean
     */
    private fun handOffPartialDownload() {
        val resumeData = if (responseStatusCode == null) {
            // Stopped before the server answered: the partial file is the one this run resumed
            if (isResume) ResumeData(task, tempFilePath, requiredStartByte, eTag) else null
        } else {
            val partialBytes = bytesTotal + startByte
            if (serverAcceptsRanges && partialBytes > 0) {
                ResumeData(task, resumeDataPath(), partialBytes, eTagHeader)
            } else null
        }
        if (resumeData != null) {
            RunHandoff.store(prefs, resumeData)
            Log.i(
                TAG,
                "Task ${task.taskId} stopped by the system at byte " +
                        "${resumeData.requiredStartByte}; its next run resumes there"
            )
        } else {
            cleanup(usesUri, safDestUri)
            Log.i(TAG, "Task ${task.taskId} stopped by the system; its next run starts over")
        }
    }

    /** Process the response to the GET or POST request on this [connection]
     *
     * Returns the [TaskStatus]
     */
    override suspend fun process(
        connection: HttpURLConnection,
    ): TaskStatus {
        // Check if the file should be skipped
        val skipThreshold = prefs.getInt(BDPlugin.keyConfigSkipExistingFiles, -1)
        if (skipThreshold != -1) {
            val filePath = task.filePath(context.appContext)
            val file = File(filePath)
            if (file.exists()) {
                val fileSize = file.length()
                if (fileSize > skipThreshold * 1024L * 1024L) {
                    responseStatusCode = 304
                    return TaskStatus.complete
                }
            }
        }

        responseStatusCode = connection.responseCode
        if (connection.responseCode in 200..206) {
            val directoryUri = UriUtils.uriFromStringValue(task.directory)
            usesUri = directoryUri != null && directoryUri.scheme != "file"
            eTagHeader = connection.headerFields["ETag"]?.first()
            val acceptRangesHeader = connection.headerFields["Accept-Ranges"]
            serverAcceptsRanges =
                acceptRangesHeader?.first() == "bytes" || connection.responseCode == 206
            if (task.allowPause) {
                taskCanResume = serverAcceptsRanges
                processCanResume(
                    task,
                    taskCanResume
                )
            }
            isResume = isResume && connection.responseCode == 206  // confirm resume response
            if (isResume && !prepareResume(connection)) {
                deleteTempFile()
                return TaskStatus.failed
            }
            if (isResume && (eTagHeader != eTag || eTag?.startsWith("W/") == true)) {
                deleteTempFile()
                Log.i(TAG, "Cannot resume: ETag is not identical, or is weak")
                taskException = TaskException(
                    ExceptionType.resume,
                    description = "Cannot resume: ETag is not identical, or is weak"
                )
                return TaskStatus.failed
            }
            // Determine destination - either [destFilePath] or [destUri]
            // If no filename is set, get from headers or url, and update the task
            var destFilePath = task.filePath(context.appContext)
            var (uriFilename, destUri) = unpack(task.filename)
            if (!task.hasFilename()) {
                // If no filename is set, get from headers or url, and update the task
                if (usesUri) {
                    uriFilename = suggestFilename(connection.headerFields, task.url)
                    if (uriFilename.isEmpty()) {
                        uriFilename = "${Random.nextInt().absoluteValue}"
                    }
                    task = task.copyWith(
                        filename = if (destUri == null) uriFilename else UriUtils.pack(
                            uriFilename,
                            destUri
                        )
                    )
                } else {
                    destFilePath = destFilePath(connection)
                }
            }
            if (directoryUri?.scheme == "file") {
                val fileDestination = destUri?.toFile()
                    ?: File(directoryUri.toFile(), uriFilename ?: task.filename)
                destFilePath = fileDestination.path
                destUri = Uri.fromFile(fileDestination)
                task = task.copyWith(filename = UriUtils.pack(fileDestination.name, destUri))
            }
            extractResponseHeaders(connection.headerFields)
            extractContentType(connection.headerFields)
            val contentLength = getContentLength(connection.headerFields, task)
            // determine tempFile, or set to null if Uri is used
            val tempFile = if (!usesUri) {
                tempFilePath = if (isResume) {
                    tempFilePath.ifEmpty { partialDownloadFilePath(destFilePath, task.taskId) }
                } else {
                    partialDownloadFilePath(destFilePath, task.taskId)
                }
                val sharedPrefs = PreferenceManager.getDefaultSharedPreferences(context.appContext)
                val tempFilePathConfig = sharedPrefs.getString(BDPlugin.keyConfigTempFilePath, null)
                if (!tempFilePathConfig.isNullOrEmpty() && !isResume) {
                    // Config.tempFilePath override: keep the deterministic
                    // .part filename but place it in the configured directory
                    tempFilePath = File(tempFilePathConfig, File(tempFilePath).name).absolutePath
                }
                val tempFile = File(tempFilePath)
                tempFile.parentFile?.mkdirs()

                tempFile
            } else {
                null
            }
            val outputStream: FileOutputStream = if (tempFile != null) {
                FileOutputStream(tempFile, isResume)
            } else {
                // no tempFile, because we have a Uri
                uriFilename = uriFilename ?: "unknown"
                    // other URL scheme will be attempted to resolve using content resolver
                    val resolver = context.appContext.contentResolver
                    val targetFilename = uriFilename ?: "unknown"
                    // create destination Uri if not already exists
                    val documentFile = DocumentFile.fromTreeUri(context.appContext, directoryUri!!)
                    if (destUri != null && !safFileExists(destUri)) {
                        Log.i(TAG, "Ignoring stale SAF destination Uri $destUri")
                        destUri = null
                    }
                    // Only a run of this task packs a content Uri into its filename (the
                    // Dart constructor and copyWith never do), so a recorded destination is
                    // this task's own output: reuse it, truncating unless resuming. A new
                    // document would be numbered "name (1)" by the provider and orphan
                    // the partial one. A run that died with its process packed the Uri only
                    // in memory, so the run replacing it finds the document by task id.
                    if (destUri == null) {
                        destUri = RunHandoff.recordedDestination(prefs, task.taskId)
                            ?.takeIf { safFileExists(it) }
                    }
                    if (destUri == null) {
                        destUri = documentFile?.createFile(task.mimeType, targetFilename)?.uri
                        destUri?.let { RunHandoff.recordDestination(prefs, task.taskId, it) }
                    }
                    if (destUri == null) {
                        val message =
                            "Failed to create document within directory with URI: $directoryUri"
                        Log.e(TAG, message)
                        taskException = TaskException(
                            ExceptionType.fileSystem,
                            description = message
                        )
                        return TaskStatus.failed
                    }
                    // Recorded now, so a stop or cancel before the first write still finds
                    // the document; also used by resumeDataPath() in pause/failure handlers
                    safDestUri = destUri
                    val newFilename = getFilenameFromUri(destUri)
                    if (newFilename.isNotEmpty()) {
                        uriFilename = newFilename
                    }
                    task = task.copyWith(filename = UriUtils.pack(uriFilename, destUri))
                    // "wa" (append) is optional in the SAF contract and some providers
                    // reject it. A provider that silently truncates instead of appending
                    // cannot be detected here.
                    val descriptor = try {
                        resolver.openFileDescriptor(destUri, if (isResume) "wa" else "wt")
                    } catch (e: Exception) {
                        Log.i(
                            TAG,
                            "Failed to open output descriptor for URI $destUri: ${e.message}"
                        )
                        null
                    }
                    if (descriptor == null) {
                        if (isResume) {
                            // The response is already streaming from the resume offset, so
                            // we cannot switch to "w" here. Delete the partial document so
                            // the next attempt restarts from scratch instead of failing on
                            // append forever.
                            deleteDestinationUri(destUri)
                        }
                        val message = "Failed to open output descriptor for URI: $destUri"
                        Log.e(TAG, message)
                        taskException = TaskException(
                            ExceptionType.fileSystem,
                            description = message
                        )
                        return TaskStatus.failed
                    } else ParcelFileDescriptor.AutoCloseOutputStream(descriptor)
            }
            determineRunInForeground(task, contentLength) // sets 'runInForeground'
            context.updateEstimatedNetworkBytes(contentLength, 0L)
            // transfer the bytes from the server to the output stream
            val transferBytesResult = try {
                outputStream.use { rawOutput ->
                    guardedDownloadOutput(context.appContext, rawOutput, contentLength) {
                        cleanup(usesUri, destUri)
                    }.use { guardedOutput ->
                        BufferedInputStream(connection.inputStream).use { inputStream ->
                            transferBytes(inputStream, guardedOutput, contentLength, task)
                        }
                    }
                }
            } catch (e: CancellationException) {
                // Stopped by the system after the last byte arrived: the download is complete
                if (isInterruptedBySystem && contentLength > 0 && bytesTotal == contentLength) {
                    TaskStatus.complete
                } else throw e
            }
            // act on the result of the bytes transfer
            when (transferBytesResult) {
                TaskStatus.complete -> {
                    // Finished even if this run is being stopped: a stop must not cost a
                    // download whose bytes have all arrived
                    withContext(NonCancellable) {
                        if (tempFile == null) {
                            Log.i(
                                TAG, "Successfully downloaded taskId ${task.taskId} to URI $destUri"
                            )
                        } else {
                            // move file from its temp location to the destination
                            val destFile = File(destFilePath)
                            val dir = destFile.parentFile!!
                            if (!dir.exists()) {
                                dir.mkdirs()
                            }
                            moveCompletedDownload(tempFile, destFile)
                            setFileOwnership(destFile)
                            Log.i(
                                TAG, "Successfully downloaded taskId ${task.taskId} to $destFilePath"
                            )
                        }
                    }
                    return TaskStatus.complete
                }

                TaskStatus.canceled -> {
                    cleanup(usesUri, destUri)
                    Log.i(TAG, "Canceled taskId ${task.taskId}")
                    return TaskStatus.canceled
                }

                TaskStatus.paused -> {
                    BDPlugin.pausedTaskIds.remove(task.taskId)
                    if (taskCanResume) {
                        Log.i(TAG, "Task ${task.taskId} paused")
                        processResumeData(
                            ResumeData(
                                task, resumeDataPath(), bytesTotal + startByte, eTagHeader
                            ), prefs
                        )
                        return TaskStatus.paused
                    }
                    if (BDPlugin.tasksToReEnqueue.contains(task) && serverAcceptsRanges) {
                        // pause was triggered by re-enqueue request due to WiFi requirement change
                        // so we only store local resumeData without posting it
                        Log.i(TAG, "Task ${task.taskId} paused in order to re-enqueue")
                        BDPlugin.localResumeData[task.taskId] = ResumeData(
                            task, resumeDataPath(), bytesTotal + startByte, eTagHeader
                        )
                        return TaskStatus.paused
                    }
                    Log.i(TAG, "Task ${task.taskId} cannot resume, therefore pause failed")
                    taskException = TaskException(
                        ExceptionType.resume,
                        description = "Task was paused but cannot resume"
                    )
                    cleanup(usesUri, destUri)
                    return TaskStatus.failed
                }

                TaskStatus.enqueued -> {
                    // Special status, in this context means that the task timed out
                    // so if allowed, pause it and schedule the resume task immediately
                    if (!task.allowPause) {
                        Log.i(TAG, "Task ${task.taskId} timed out")
                        taskException =
                            TaskException(
                                ExceptionType.connection,
                                description = "Task timed out"
                            )
                        return TaskStatus.failed
                    }
                    if (taskCanResume) {
                        Log.i(
                            TAG,
                            "Task ${task.taskId} paused due to timeout, will resume"
                        )
                        val start = bytesTotal + startByte
                        val resumeData = ResumeData(task, resumeDataPath(), start, eTagHeader)
                        val holdingQueue = BDPlugin.holdingQueue
                        val success = if (holdingQueue != null) {
                            // Route the resume through the holding queue: a direct
                            // doEnqueue would run the continuation outside the queue's
                            // accounting, while this run's finish report frees a slot —
                            // every timeout cycle would raise effective concurrency past
                            // maxConcurrent. compareTo orders by the task's original
                            // creation time, so the resume goes to the front, not the back
                            holdingQueue.add(
                                EnqueueItem(
                                    context = context.appContext,
                                    task = task,
                                    notificationConfigJsonString = notificationConfigJsonString,
                                    resumeData = resumeData
                                )
                            )
                        } else {
                            BDPlugin.doEnqueue(
                                context.appContext,
                                task,
                                notificationConfigJsonString,
                                resumeData,
                                1000
                            )
                        }
                        if (!success) {
                            Log.w(TAG, "Task ${task.taskId} timed out and could not re-enqueue to resume")
                            taskException = TaskException(
                                ExceptionType.general,
                                description = "Task timed out and could not re-enqueue to resume"
                            )
                            cleanup(usesUri, destUri)
                            return TaskStatus.failed
                        }
                        return TaskStatus.paused
                    }
                    Log.i(TAG, "Task ${task.taskId} timed out and cannot pause/resume")
                    taskException =
                        TaskException(ExceptionType.connection, description = "Task timed out")
                    cleanup(usesUri, destUri)
                    return TaskStatus.failed
                }

                TaskStatus.failed -> {
                    return TaskStatus.failed
                }

                else -> {
                    Log.e(TAG, "Unknown transferBytesResult $transferBytesResult")
                    cleanup(usesUri, destUri)
                    return TaskStatus.failed
                }
            }
        } else {
            // HTTP response code not OK
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
                responseBody = errorContent
                TaskStatus.notFound
            } else {
                TaskStatus.failed
            }
        }
    }


    private suspend fun moveCompletedDownload(source: File, destination: File) {
        withContext(Dispatchers.IO) {
            try {
                // rename(2) never silently copies across filesystems and atomically replaces.
                Os.rename(source.path, destination.path)
            } catch (renameError: ErrnoException) {
                if (renameError.errno != android.system.OsConstants.EXDEV) throw renameError
                val staging = File.createTempFile(".download-", ".part", destination.parentFile)
                try {
                    FileOutputStream(staging).use { rawOutput ->
                        guardedDownloadOutput(context.appContext, rawOutput, source.length()) {
                            staging.delete()
                        }.use { guardedOutput ->
                            source.inputStream().use { it.copyTo(guardedOutput, 64 * 1024) }
                        }
                    }
                    Os.rename(staging.path, destination.path)
                    source.delete()
                } finally {
                    staging.delete()
                }
            }
        }
    }

    /**
     * Return destination filePath where the filename is set based on response headers, and
     * update the [task] accordingly
     */
    private fun destFilePath(connection: HttpURLConnection): String {
        val destFilePath = task.filePath(context.appContext)
        task = task.withSuggestedFilenameFromResponseHeaders(
            context.appContext,
            connection.headerFields,
            unique = true
        )
        val dirName = File(destFilePath).parent ?: ""
        return if (dirName.isEmpty()) task.filename else "$dirName/${task.filename}"
    }


    /**
     * Return true if this is a resume, and resume is possible,
     * given [tempFilePath] and [requiredStartByte]
     * */
    override fun determineIfResume(): Boolean {
        // A run the platform stopped records where its partial file ends. The platform runs the
        // task again with its original input, so that record is newer than any resume data there
        val handoff = RunHandoff.take(prefs, task.taskId)
        if (handoff != null) {
            // The stopped run may have named the file, and for SAF packed its document Uri
            // into the filename
            task = task.copyWith(filename = handoff.task.filename)
            requiredStartByte = handoff.requiredStartByte
            eTag = handoff.eTag
            tempFilePath = handoff.data
        } else {
            // set tempFilePath from resume data, or "" if a new tempFile is needed
            requiredStartByte = context.getInputLong(keyStartByte, 0)
            if (requiredStartByte == 0L) {
                return false
            }
            eTag = context.getInputString(keyETag)
            tempFilePath = if (requiredStartByte > 0) context.getInputString(keyResumeDataData) ?: ""
            else ""
        }

        val resumeUri = Uri.parse(tempFilePath)
        // file:// destination URI: the partial bytes live in the destination file
        // itself, which supports regular file operations — convert to a plain path
        // so the temp-file logic below (existence, truncation, deletion) applies
        if (resumeUri.scheme == "file") {
            tempFilePath = try {
                resumeUri.toFile().path
            } catch (e: IllegalArgumentException) {
                Log.i(TAG, "Cannot resume from file URI $tempFilePath: ${e.message}")
                return false
            }
        }
        // SAF resume: resume data stores a content:// URI instead of a temp file path
        if (resumeUri.scheme == "content") {
            try {
                val docFile = DocumentFile.fromSingleUri(context.appContext, resumeUri)
                if (docFile?.exists() != true) {
                    Log.i(TAG, "SAF resume file not available, restarting")
                    return false
                }
                val fileSize = docFile.length()
                if (fileSize == requiredStartByte) {
                    Log.i(TAG, "SAF resume: file size matches at $requiredStartByte bytes")
                    return true
                }
                // Can't truncate SAF files — if size mismatches, delete and restart
                Log.i(TAG, "SAF file size $fileSize != required $requiredStartByte, restarting")
                deleteDestinationUri(resumeUri)
            } catch (e: Exception) {
                Log.i(TAG, "Could not inspect SAF resume file at $resumeUri: ${e.message}")
            }
            return false
        }

        val tempFile = File(tempFilePath)
        if (tempFile.exists()) {
            val tempFileLength = tempFile.length()
            if (tempFileLength == requiredStartByte) {
                return true
            } else {
                // attempt to truncate the file to the expected size
                Log.d(
                    TAG,
                    "File length = ${tempFile.length()} vs requiredStartByte = $requiredStartByte"
                )
                if (tempFileLength > requiredStartByte && Build.VERSION.SDK_INT >= 26) {
                    try {
                        val fileChannel =
                            FileChannel.open(tempFile.toPath(), StandardOpenOption.WRITE)
                        fileChannel.truncate(requiredStartByte)
                        fileChannel.close()
                        Log.d(TAG, "Truncated temp file to desired length")
                        return true
                    } catch (e: IOException) {
                        e.printStackTrace()
                    }
                }
                Log.i(TAG, "Partially downloaded file is corrupted, resume not possible")
            }
        } else {
            Log.i(TAG, "Partially downloaded file not available, resume not possible")
        }
        return false
    }

    /** Prepare for resume if possible
     *
     * Returns true if task can continue, false if task failed.
     * Extracts and parses Range headers, and truncates temp file
     */
    private fun prepareResume(connection: HttpURLConnection): Boolean {
        if (tempFilePath.isEmpty()) {
            return false
        }
        // SAF resume: no temp file to prepare — Range header already set in connectAndProcess
        if (Uri.parse(tempFilePath).scheme == "content") {
            val contentRanges = connection.headerFields["Content-Range"]
            if (contentRanges == null || contentRanges.size != 1) {
                Log.i(TAG, "SAF resume: could not process Content-Range")
                return false
            }
            val range = contentRanges.first()
            val matchResult = contentRangeRegex.find(range)
            if (matchResult == null) {
                Log.i(TAG, "SAF resume: could not process Content-Range $range")
                taskException = TaskException(
                    ExceptionType.resume,
                    description = "Could not process partial response Content-Range $range"
                )
                return false
            }
            val serverStart = matchResult.groups[1]?.value?.toLong()!!
            // The document was opened in append mode, which cannot seek or truncate,
            // so the server's range must start exactly where the partial file ends
            if (serverStart != taskRangeStartByte + requiredStartByte) {
                Log.i(
                    TAG,
                    "SAF resume: server range $range does not start at requested byte " +
                            "${taskRangeStartByte + requiredStartByte}"
                )
                taskException = TaskException(
                    ExceptionType.resume,
                    description = "Cannot resume: server offered range $range instead of " +
                            "requested start byte ${taskRangeStartByte + requiredStartByte}"
                )
                return false
            }
            startByte = serverStart - taskRangeStartByte
            return true
        }
        val contentRanges = connection.headerFields["Content-Range"]
        if (contentRanges == null || contentRanges.size > 1) {
            Log.i(
                TAG, "Could not " +
                        "process partial response Content-Range"
            )
            return false
        }
        val range = contentRanges.first()
        val matchResult = contentRangeRegex.find(range)
        if (matchResult == null) {
            Log.i(TAG, "Could not process partial response Content-Range $range")
            taskException = TaskException(
                ExceptionType.resume,
                description = "Could not process partial response Content-Range $range"
            )
            return false
        }
        val start = matchResult.groups[1]?.value?.toLong()!!
        val tempFile = File(tempFilePath)
        val tempFileLength = tempFile.length()
        startByte = start - taskRangeStartByte // relative to start of range
        if (startByte > tempFileLength) {
            Log.i(TAG, "Offered range not feasible: $range with startByte $startByte")
            taskException = TaskException(
                ExceptionType.resume,
                description = "Offered range not feasible: $range with startByte $startByte"
            )
            return false
        }
        // resume possible, set start conditions
        try {
            RandomAccessFile(tempFilePath, "rw").use { it.setLength(startByte) }
        } catch (_: IOException) {
            Log.i(TAG, "Could not truncate temp file")
            taskException =
                TaskException(
                    ExceptionType.resume,
                    description = "Could not truncate temp file"
                )
            return false
        }
        return true
    }

    /**
     * Attempt to allow resume after failure by sending resume data
     * back to Dart
     *
     * If this is not possible, the temp file will be deleted
     */
    private suspend fun prepResumeAfterFailure() {
        if (isDownloadStorageFailure(taskException?.description)) {
            task.retriesRemaining = 0
            taskCanResume = false
            BDPlugin.localResumeData.remove(task.taskId)
            cleanup(usesUri, safDestUri)
            return
        }
        if (serverAcceptsRanges && bytesTotal + startByte > 1 shl 20) {
            // if failure can be resumed, post resume data
            processResumeData(
                ResumeData(
                    task, resumeDataPath(), bytesTotal + startByte, eTagHeader
                ), prefs
            )
        } else {
            // if it cannot be resumed, delete the temp file
            if (!usesUri) deleteTempFile()
        }
    }

    /**
     * Deletes the temp file associated with this download
     *
     * During a SAF resume [tempFilePath] holds the content:// URI of the partial
     * destination document, which a [File] delete cannot touch
     */
    private fun deleteTempFile() {
        if (tempFilePath.isEmpty()) {
            return
        }
        val uri = Uri.parse(tempFilePath)
        if (uri.scheme == "content") {
            deleteDestinationUri(uri)
            return
        }
        try {
            val tempFile = File(tempFilePath)
            tempFile.delete()
        } catch (_: IOException) {
            Log.i(TAG, "Could not delete temp file at $tempFilePath")
        }
    }

    /** Returns true if [uri] points to an existing SAF file. */
    private fun safFileExists(uri: Uri?): Boolean {
        if (uri == null) return false
        return try {
            val file = DocumentFile.fromSingleUri(context.appContext, uri)
            file?.exists() == true && file.isFile
        } catch (e: Exception) {
            Log.i(TAG, "Could not check SAF file at $uri: ${e.message}")
            false
        }
    }


    /** Deletes the destination Uri at [uri] */
    private fun deleteDestinationUri(uri: Uri) = deleteDestination(context.appContext, uri)

    /**
     * Cleanup by deleting the temp file or destination uri
     */
    private fun cleanup(usesUri: Boolean, destUri: Uri?) {
        if (usesUri && destUri != null) {
            deleteDestinationUri(destUri)
        } else {
            deleteTempFile()
        }
    }

    /**
     * Sets the group ownership of the downloaded file to unmark the file as a cache file.
     *
     * Determines the app's GID and then calls Os.chown. Logs success or failure.
     * Likely to fail if the file is in external storage.
     */
    private fun setFileOwnership(destFile: File) {
        try {
            val finalPath = destFile.absolutePath
            val gid = context.appContext.applicationInfo.uid // App's own GID
            Os.chown(finalPath, -1, gid) // -1 for UID means keep current owner
        } catch (e: ErrnoException) {
            // Log the error, common if the filesystem doesn't support chown or due to permissions.
            // Check OsConstants for specific errno values if needed.
            Log.w(
                TAG,
                "Failed to change group ownership for ${destFile.absolutePath}: ${e.message}"
            )
        }
    }

}
