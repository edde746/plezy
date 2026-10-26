package com.bbflight.background_downloader

import android.system.Os
import android.util.Log
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.InternalSerializationApi
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.HttpURLConnection
import kotlin.math.absoluteValue
import kotlin.math.min
import kotlin.random.Random

class ParallelDownloadTaskRunner(context: TaskJobContext) : TaskRunner(context) {

    private var parallelDownloadContentLength = -1L
    private var chunks: List<Chunk> = mutableListOf()
    private var chunksJsonString = ""
    private var parallelTaskStatusUpdateCompleter = CompletableDeferred<TaskStatus>()
    private var lastTaskStatus = TaskStatus.enqueued

    override fun determineIfResume(): Boolean {
        chunksJsonString = context.getInputString(keyResumeDataData) ?: ""
        return chunksJsonString.isNotEmpty()
    }

    override suspend fun connectAndProcess(connection: HttpURLConnection): TaskStatus {
        // Register this runner with BDPlugin so it can receive chunk updates
        BDPlugin.parallelDownloadTaskWorkers[task.taskId] = this 
        
        canRunInForeground = true
        runInForeground = notificationConfig?.running != null
        connection.requestMethod = "HEAD"
        val result = super.connectAndProcess(connection)
        BDPlugin.parallelDownloadTaskWorkers.remove(task.taskId)
        return result
    }

    override suspend fun process(
        connection: HttpURLConnection,
    ): TaskStatus {
        return withContext(Dispatchers.Default) {
            var enqueueJob: Job? = null
            var testerJob: Job? = null
            try {
                enqueueJob = launch {
                    if (!isResume) {
                        // start the download by creating [Chunk]s and enqueuing chunk tasks
                        if (connection.responseCode in listOf(200, 201, 202, 203, 204, 205, 206)) {
                            // if no filename is set, get from headers or url, update task
                            if (!task.hasFilename()) {
                                task = task.withSuggestedFilenameFromResponseHeaders(
                                    context.appContext,
                                    connection.headerFields,
                                    unique = true
                                )
                                Log.d(
                                    TAG,
                                    "Suggested filename for taskId ${task.taskId}: ${task.filename}"
                                )
                            }
                            extractResponseHeaders(connection.headerFields)
                            responseStatusCode = connection.responseCode
                            extractContentType(connection.headerFields)
                            chunks = createChunks(task, connection.headerFields)
                            for (chunk in chunks) {
                                // Ask Dart side to enqueue the child task. Updates related to the child
                                // will be sent to this (parent) task (the child's metaData is the parent taskId).
                                postOnBackgroundChannel(
                                    "enqueueChild",
                                    task,
                                    bdJson.encodeToString<Task>(chunk.task),
                                    onFail =
                                    {
                                        // failed to enqueue child
                                        cancelAllChunkTasks()
                                        Log.i(
                                            TAG,
                                            "Failed to enqueue chunk task with id ${chunk.task.taskId}"
                                        )
                                        taskException = TaskException(
                                            ExceptionType.general,
                                            description = "Failed to enqueue chunk task with id ${chunk.task.taskId}"
                                        )
                                        parallelTaskStatusUpdateCompleter.complete(TaskStatus.failed)
                                    })
                            }
                        } else {
                            // HTTP response code not OK
                            Log.i(
                                TAG,
                                "Response code ${connection.responseCode} for taskId ${task.taskId}"
                            )
                            val errorContent = responseErrorContent(connection)
                            taskException = TaskException(
                                ExceptionType.httpResponse,
                                httpResponseCode = connection.responseCode,
                                description = if (errorContent?.isNotEmpty() == true) errorContent else connection.responseMessage
                            )
                            if (connection.responseCode == 404) {
                                responseBody = errorContent
                                parallelTaskStatusUpdateCompleter.complete(TaskStatus.notFound)
                            } else {
                                parallelTaskStatusUpdateCompleter.complete(TaskStatus.failed)
                            }
                        }
                    } else {
                        // resume: reconstruct [chunks] and wait for all chunk tasks to complete.
                        // The Dart side will resume each chunk task, so we just wait for the
                        // completer to complete
                        chunks = bdJson.decodeFromString(chunksJsonString)
                        parallelDownloadContentLength = chunks.fold(0L) { acc, chunk ->
                            acc + chunk.toByte - chunk.fromByte + 1
                        }
                    }
                }
                testerJob = launch {
                    while (isActive) {
                        // check if task is stopped (canceled), paused or timed out
                        if (context.isTaskStopped) {
                            withContext(NonCancellable) {
                                cancelAllChunkTasks()
                                parallelTaskStatusUpdateCompleter.complete(TaskStatus.failed)
                            }
                            break
                        }
                        // 'pause' is signalled by adding the taskId to a static list
                        if (BDPlugin.pausedTaskIds.remove(task.taskId)) {
                            pauseAllChunkTasks()
                            postOnBackgroundChannel(
                                "resumeData",
                                task,
                                bdJson.encodeToString<List<Chunk>>(chunks)
                            )
                            parallelTaskStatusUpdateCompleter.complete(TaskStatus.paused)
                            break
                        }
                        delay(200)
                    }
                }
                // wait for all chunks to finish
                return@withContext parallelTaskStatusUpdateCompleter.await()
            } catch (e: Exception) {

                Log.i(TAG, "Exception for taskId ${task.taskId}: $e")
                taskException = TaskException(
                    ExceptionType.general,
                    description = "Exception for taskId ${task.taskId}: $e"
                )
                return@withContext TaskStatus.failed
            } finally {
                enqueueJob?.cancelAndJoin()
                testerJob?.cancelAndJoin()
            }
        }
    }

    /**
     * Process incoming [status] update for a chunk with [chunkTaskId]
     *
     * If status is failure, may include [taskException] and [responseBody]
     */
    suspend fun chunkStatusUpdate(
        chunkTaskId: String,
        status: TaskStatus,
        taskException: TaskException?,
        responseBody: String?
    ) {
        val chunk = chunks.firstOrNull { it.task.taskId == chunkTaskId }
            ?: return // chunk is not part of this parent task
        val chunkTask = chunk.task
        // first check for fail -> retry
        if (status == TaskStatus.failed && chunkTask.retriesRemaining > 0) {
            chunkTask.retriesRemaining--
            val waitTimeSeconds = 2 shl (min(chunkTask.retries - chunkTask.retriesRemaining - 1, 8))
            Log.i(
                TAG,
                "Chunk task with taskId ${chunkTask.taskId} failed, waiting $waitTimeSeconds seconds before retrying. ${chunkTask.retriesRemaining} retries remaining"
            )
            delay(waitTimeSeconds * 1000L)
            postOnBackgroundChannel(
                "enqueueChild",
                task,
                bdJson.encodeToString<Task>(chunk.task),
                onFail = {
                    chunkStatusUpdate(chunkTaskId, TaskStatus.failed, taskException, responseBody)
                })
        } else {
            // no retry
            val newStatusUpdate = updateChunkStatus(chunk, status)
            if (newStatusUpdate != null) {
                when (newStatusUpdate) {
                    TaskStatus.complete -> {
                        val stitchResult = stitchChunks()
                        parallelTaskStatusUpdateCompleter.complete(stitchResult)
                    }

                    TaskStatus.failed -> {
                        this.taskException = taskException
                        cancelAllChunkTasks()
                        parallelTaskStatusUpdateCompleter.complete(TaskStatus.failed)
                    }

                    TaskStatus.notFound -> {
                        this.taskException = taskException
                        this.responseBody = responseBody
                        cancelAllChunkTasks()
                        parallelTaskStatusUpdateCompleter.complete(TaskStatus.notFound)
                    }

                    else -> {
                        // ignore all other status updates
                    }
                }
            }
        }
    }


    /**
     * Process incoming [progress] update for a chunk with [chunkTaskId].
     *
     * Recalculates overall task progress (based on the average of the chunk
     * task progress) and sends an update to the Dart side and updates the
     * notification at the appropriate interval
     */
    suspend fun chunkProgressUpdate(chunkTaskId: String, progress: Double) {
        val chunk = chunks.firstOrNull { it.task.taskId == chunkTaskId }
            ?: return // chunk is not part of this parent task
        if (progress > 0 && progress < 1) {
            val parentProgress = updateChunkProgress(chunk, progress)
            if (shouldSendProgressUpdate(parentProgress, System.currentTimeMillis())) {
                updateProgressAndNotify(parentProgress, parallelDownloadContentLength, task)
            }
        }
    }

    /**
     * Update the status for this chunk, and return the status for the parent task
     * as derived from the sum of the child tasks, or null if undefined
     *
     * The updates are received from the NativeDownloader, which intercepts
     * status updates for the chunkGroup
     */
    private fun updateChunkStatus(chunk: Chunk, status: TaskStatus): TaskStatus? {
        chunk.status = status
        val parentStatus = parentTaskStatus()
        if (parentStatus != null && parentStatus != lastTaskStatus) {
            lastTaskStatus = parentStatus
            return parentStatus
        }
        return null
    }

    /**
     * Returns the [TaskStatus] for the parent of this chunk, as derived from
     * the 'sum' of the child tasks, or null if undetermined
     *
     * The updates are received from the NativeDownloader, which intercepts
     * status updates for the chunkGroup
     */
    private fun parentTaskStatus(): TaskStatus? {
        val failed = chunks.firstOrNull { it.status == TaskStatus.failed }
        if (failed != null) {
            return TaskStatus.failed
        }

        val notFound = chunks.firstOrNull { it.status == TaskStatus.notFound }
        if (notFound != null) {
            return TaskStatus.notFound
        }

        val allComplete = chunks.all { it.status == TaskStatus.complete }
        if (allComplete) {
            return TaskStatus.complete
        }
        return null
    }


    /**
     * Updates the chunk's progress and returns the average progress
     *
     * Returns the [progress] for the parent of this chunk, as derived from
     * its children by averaging
     */
    private fun updateChunkProgress(chunk: Chunk, progress: Double): Double {
        chunk.progress = progress
        return chunks.fold(
            0.0
        ) { previousValue, c ->
            previousValue + c.progress
        } / chunks.size
    }

    /**
     * Cancel the tasks associated with each chunk
     *
     * Accomplished by sending list of taskIds to cancel to the NativeDownloader
     */
    suspend fun cancelAllChunkTasks() {
        postOnBackgroundChannel(
            "cancelTasksWithId",
            task,
            bdJson.encodeToString<List<String>>(chunks.map { it.task.taskId })
        )
    }

    /**
     * Pause the tasks associated with each chunk
     *
     * Accomplished by sending a json decoded list of tasks to cancel
     * to the NativeDownloader
     */
    private suspend fun pauseAllChunkTasks() {
        postOnBackgroundChannel("pauseTasks", task, bdJson.encodeToString<List<Task>>(chunks.map { it.task }))
    }

    /**
     * Stitch all chunks together into one file
     */
    private suspend fun stitchChunks(): TaskStatus {
        return withContext(Dispatchers.IO) {
            var outFile: File? = null
            try {
                val dataBuffer = ByteArray(bufferSize)
                var numBytes: Int
                outFile = File(task.filePath(context.appContext))
                // Stitch into a staging file so a failure never touches any completed file,
                // then rename(2) it into place (same volume, atomic).
                val staging = File(outFile.parentFile, ".${outFile.name}.stitch.part")
                try {
                    FileOutputStream(staging).use { rawOutput ->
                        val guardedOutput = guardedDownloadOutput(
                            context.appContext, rawOutput, parallelDownloadContentLength
                        ) { staging.delete() }
                        try {
                            for (chunk in chunks.sortedBy { it.fromByte }) {
                                val inFile = File(chunk.task.filePath(context.appContext))
                                if (!inFile.exists()) {
                                    throw java.io.FileNotFoundException(
                                        "Missing chunk file: ${inFile.path}"
                                    )
                                }
                                FileInputStream(inFile).use { inStream ->
                                    while (inStream.read(
                                            dataBuffer, 0,
                                            bufferSize
                                        )
                                            .also { numBytes = it } != -1
                                    ) {
                                        guardedOutput.write(dataBuffer, 0, numBytes)
                                    }
                                }
                            }
                            guardedOutput.flush()
                        } finally {
                            guardedOutput.close()
                        }
                    }
                    Os.rename(staging.path, outFile.path)
                } finally {
                    staging.delete()
                }
            } catch (e: Exception) {
                Log.i(TAG, "Error stitching chunks: $e\n${e.stackTraceToString()}")
                taskException = if (isDownloadStorageFailure(e.message)) {
                    // Failure to create the output is not resumable; the guard already
                    // removed the staged partial. Chunk files are deleted in the finally below.
                    TaskException(ExceptionType.fileSystem, description = e.message.orEmpty())
                } else {
                    TaskException(
                        ExceptionType.fileSystem,
                        description = "Error stitching chunks: $e"
                    )
                }
                return@withContext TaskStatus.failed
            } finally {
                for (chunk in chunks) {
                    try {
                        val file = File(chunk.task.filePath(context.appContext))
                        file.delete()
                    } catch (_: Exception) {
                        // ignore
                    }
                }
            }
            return@withContext TaskStatus.complete
        }
    }


    /**
     * Returns a list of chunk information for this task, and sets
     * [parallelDownloadContentLength] to the total length of the download
     *
     * Throws a IllegalStateException if any information is missing, which should lead
     * to a failure of the ParallelDownloadTask
     */
    private fun createChunks(
        task: Task,
        headers: MutableMap<String, MutableList<String>>
    ): List<Chunk> {
        val numChunks = task.urls.size * task.chunks
        try {
            val contentLength = getContentLength(headers, task)
            if (contentLength <= 0) {
                throw IllegalStateException("Server does not provide content length - cannot chunk download. If you know the length, set Range or Known-Content-Length header")
            }
            parallelDownloadContentLength = contentLength
            context.updateEstimatedNetworkBytes(contentLength, 0L)
            try {
                headers.entries
                    .first { (it.key == "accept-ranges" || it.key == "Accept-Ranges") && it.value.first() == "bytes" }
            } catch (_: NoSuchElementException) {
                throw IllegalStateException("Server does not accept ranges - cannot chunk download")
            }
            val chunkSize = (contentLength / numChunks) + 1
            return (0 until numChunks).map { i ->
                Chunk(
                    parentTask = task,
                    url = task.urls[i % task.urls.size],
                    filename = "com.bbflight.background_downloader.${Random.nextInt().absoluteValue}",
                    from = i * chunkSize,
                    to = min(i * chunkSize + chunkSize - 1, contentLength - 1)
                )
            }
        } catch (_: NoSuchElementException) {
            throw IllegalStateException("Server does not provide content length - cannot chunk download. If you know the length, set Range or Known-Content-Length header")
        }
    }
}

@Suppress("unused")
@OptIn(InternalSerializationApi::class)
@Serializable
class Chunk private constructor(
    private val parentTaskId: String,
    private val url: String,
    private val filename: String,
    val task: Task,
    val fromByte: Long,
    val toByte: Long,
    var status: TaskStatus = TaskStatus.enqueued,
    var progress: Double = 0.0
) {
    companion object {
        /**
         * Returns [Updates] that is based on the [parentTask]
         */
        fun updatesBasedOnParent(parentTask: Task): Updates {
            return when (parentTask.updates) {
                Updates.none, Updates.status -> Updates.status
                Updates.progress, Updates.statusAndProgress -> Updates.statusAndProgress
            }
        }
    }

    /**
     * Constructor that also creates the [Task] associated with this [Chunk]
     */
    constructor(parentTask: Task, url: String, filename: String, from: Long, to: Long) : this(
        parentTaskId = parentTask.taskId,
        url,
        filename,
        task = Task(
            url = url,
            filename = filename,
            headers = parentTask.headers + mapOf("Range" to "bytes=$from-$to"),
            httpRequestMethod = "GET",
            chunks = 1,
            post = null,
            fileField = "",
            mimeType = "",
            baseDirectory = BaseDirectory.applicationDocuments,
            group = TaskRunner.chunkGroup,
            updates = updatesBasedOnParent(parentTask),
            retries = parentTask.retries,
            retriesRemaining = parentTask.retries,
            requiresWiFi = parentTask.requiresWiFi,
            allowPause = parentTask.allowPause,
            priority = parentTask.priority,
            metaData = bdJson.encodeToString<ChunkTaskMetaData>(ChunkTaskMetaData(parentTask.taskId, from, to)),
            taskType = "DownloadTask"
        ),
        from,
        to
    )
}

@Serializable
@OptIn(InternalSerializationApi::class)
/// Holder for metaData for [Task] related to a [Chunk]
data class ChunkTaskMetaData(val parentTaskId: String, val from: Long, val to: Long)
