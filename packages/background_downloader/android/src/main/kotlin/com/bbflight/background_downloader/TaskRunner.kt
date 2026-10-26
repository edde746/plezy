package com.bbflight.background_downloader

import android.app.job.JobParameters
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.util.Log
import androidx.preference.PreferenceManager
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import java.io.DataOutputStream
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.lang.Double.min as doubleMin
import java.lang.System.currentTimeMillis
import java.net.HttpURLConnection
import java.net.InetSocketAddress
import java.net.Proxy
import java.net.SocketException
import java.net.SocketTimeoutException
import java.net.URL
import java.net.URLDecoder
import java.net.MalformedURLException
import kotlin.concurrent.read
import kotlin.concurrent.write
import androidx.core.content.edit
import androidx.work.WorkManager


/**
 * Interface that abstracts the differences between a WorkManager worker and a JobService job
 */
interface TaskJobContext {
    val appContext: Context
    
    // Mutable properties needed for NotificationService and Task execution
    var task: Task
    var notificationConfig: NotificationConfig?
    var notificationId: Int
    var notificationProgress: Double
    var networkSpeed: Double
    var taskCanResume: Boolean
    var notificationConfigJsonString: String?
    val isTaskStopped: Boolean

    /**
     * True if the system stopped this run without the task being canceled, so the task
     * continues in another run: WorkManager reschedules work it stops for quota, constraints or
     * device state, and a user-initiated job the system stops is enqueued again by [runAgain]
     */
    val willRunAgain: Boolean

    /** The platform's reason for stopping this run, for logging */
    val platformStopReason: Int

    /**
     * Make sure the task runs again after this run was stopped (see [willRunAgain]), returning
     * false if that failed
     */
    suspend fun runAgain(): Boolean

    /** Cancel the run the platform scheduled after stopping this one, if it scheduled one */
    suspend fun cancelRunAgain()

    // Foreground control
    var runInForeground: Boolean
    val isActive: Boolean // maps to !isStopped or Service state

    /**
     * Set the task to run in foreground with the given notification
     */
    suspend fun setForegroundNotification(notificationId: Int, notification: android.app.Notification, notificationType: Int)

    /**
     * Get a Long value from the input data
     */
    fun getInputLong(key: String, defaultValue: Long): Long

    /**
     * Get a String value from the input data
     */
    fun getInputString(key: String): String?

    /**
     * Update the notification for this task. 
     * Implementations should call NotificationService.updateNotification(this, ...).
     */
    suspend fun updateNotification(
        task: Task,
        status: TaskStatus,
        progress: Double = 2.0,
        timeRemaining: Long = -1000
    )

    /**
     * Update the estimated network bytes for this task (Android 14+ UIDT only)
     */
    fun updateEstimatedNetworkBytes(downloadBytes: Long, uploadBytes: Long)
}

/***
 * The runner to execute one task.
 *
 * It is called from [TaskWorker] (WorkManager) or [UIDTJobService] (JobScheduler), which
 * provide the [TaskJobContext]
 */
open class TaskRunner(
    val context: TaskJobContext
) {

    companion object {
        const val TAG = "TaskRunner"
        const val chunkGroup = "chunk"
        const val keyTask = "Task"
        const val keyNotificationConfig = "notificationConfig"
        const val keyResumeDataData = "tempFilename"
        const val keyStartByte = "startByte"
        const val keyETag = "eTag"
        const val bufferSize = 2 shl 12

        const val taskTimeoutMillis = 9 * 60 * 1000L  // 9 minutes
        const val expeditedTaskTimeoutMillis = 2 * 60 * 1000L  // 2 minutes

        /** Converts [Task] to JSON string representation */
        fun taskToJsonString(task: Task): String {
            return bdJson.encodeToString(task)
        }

        /**
         * Post method message on backgroundChannel with arguments
         *
         * If the post is not successful, execute the [onFail] block, if given
         *
         * [arg] can be single variable or a MutableList
         */
        suspend fun postOnBackgroundChannel(
            method: String, task: Task, arg: Any, onFail: (suspend () -> Unit)? = null
        ) {
            val bgPost = BackgroundPost(task, method, arg, onFail)
            QueueService.postOnBackgroundChannel(bgPost)
        }

        /**
         * Processes a change in status for the task
         *
         * Sends status update via the background channel to Flutter. Dart decides
         * which updates are user-visible and synthesizes terminal progress.
         *
         * Optional [taskException] for status .failed
         * */
        suspend fun processStatusUpdate(
            task: Task,
            status: TaskStatus,
            prefs: SharedPreferences,
            taskException: TaskException? = null,
            responseBody: String? = null,
            responseHeaders: Map<String, String>? = null,
            responseStatusCode: Int? = null,
            mimeType: String? = null,
            charSet: String? = null,
            context: Context
        ) {
            val safeTask = AuthTaskRegistry.persistable(task)
            val credentialedTask = AuthTaskRegistry.isProtected(safeTask)
            val safeTaskException =
                if (credentialedTask && taskException != null) TaskException(ExceptionType.general)
                else taskException

            // Intercept status updates resulting from re-enqueue request, which
            // themselves are triggered by a change in WiFi requirement
            if (BDPlugin.tasksToReEnqueue.remove(safeTask)) {
                if (status == TaskStatus.paused || status == TaskStatus.canceled || status == TaskStatus.failed) {
                    WiFi.reEnqueue(
                        EnqueueItem(
                            context,
                            safeTask,
                            BDPlugin.notificationConfigJsonStrings[safeTask.taskId],
                            BDPlugin.localResumeData[safeTask.taskId]
                        )
                    )
                }
                if (BDPlugin.tasksToReEnqueue.isEmpty()) {
                    WiFi.reEnqueue(null) // signal end of batch
                }
                if (status == TaskStatus.paused || status == TaskStatus.canceled || status == TaskStatus.failed) {
                    return
                }
            }

            // Normal status update

            // Check if the task was 'programmatically' canceled, in which case a TaskStatus.failed may be
            // incorrectly generated by the WorkManager, so we change it to 'canceled'
            val modifiedStatus =
                if (BDPlugin.canceledTaskIds.contains(safeTask.taskId)) TaskStatus.canceled else status

            // Retry orchestration and final progress are generated on the Dart side.
            val retryNeeded = modifiedStatus == TaskStatus.failed && safeTask.retriesRemaining > 0
            var canSendStatusUpdate = true  // may become false for cancellations
            when (modifiedStatus) {
                TaskStatus.canceled -> {
                    canSendStatusUpdate = canSendCancellation(safeTask)
                    if (canSendStatusUpdate) {
                        BDPlugin.cancelUpdateSentForTaskId[safeTask.taskId] =
                            currentTimeMillis()
                    }
                }

                else -> {}
            }

            val taskStatusUpdate =
                if (modifiedStatus.isFinalState()) {  // last update gets all data
                    TaskStatusUpdate(
                        task = safeTask,
                        taskStatus = modifiedStatus,
                        exception = if (modifiedStatus == TaskStatus.failed) safeTaskException
                            ?: TaskException(ExceptionType.general) else null,
                        responseBody = if (credentialedTask) null else responseBody,
                        responseStatusCode = if (modifiedStatus == TaskStatus.complete || modifiedStatus == TaskStatus.notFound) responseStatusCode else null,
                        responseHeaders = if (credentialedTask) null else responseHeaders?.filterNotNull()
                            ?.mapKeys { it.key.lowercase() },
                        mimeType = mimeType,
                        charSet = charSet
                    )
                } else TaskStatusUpdate(  // interim updates are limited
                    task = safeTask,
                    taskStatus = modifiedStatus,
                    exception = null,
                    responseBody = null,
                    responseStatusCode = null,
                    responseHeaders = null,
                    mimeType = null,
                    charSet = null
                )

            // Dart decides which updates are user-visible and synthesizes terminal progress.
            if (canSendStatusUpdate) {
                val arg = taskStatusUpdate.argList
                postOnBackgroundChannel("statusUpdate", safeTask, arg, onFail = {
                    // unsuccessful post, so store in local prefs
                    Log.d(TAG, "Could not post status update -> storing locally")
                    storeLocally(
                        BDPlugin.keyStatusUpdateMap,
                        safeTask.taskId,
                        bdJson.encodeToString<TaskStatusUpdate>(taskStatusUpdate),
                        prefs
                    )
                })
            }
            // if the task is in final state, cancel the WorkManager job (if failed),
            // remove the task from persistent storage, clean up references to taskId
            // and invoke the onTaskFinishedCallback if necessary
            if (modifiedStatus.isFinalState()) {
                if (modifiedStatus == TaskStatus.failed) {
                    // Cancel the WorkManager job.
                    // This is to avoid the WorkManager restarting a job that was
                    // canceled because job constraints are violated (e.g. network unavailable)
                    // We want to manage cancellation ourselves, so we cancel the job
                    val workManager = WorkManager.getInstance(context)
                    val operation = workManager.cancelAllWorkByTag("taskId=${safeTask.taskId}")
                    try {
                        withContext(Dispatchers.IO) {
                            operation.result.get()
                        }
                    } catch (_: Throwable) {
                        Log.w(
                            BDPlugin.TAG,
                            "Could not kill task with id ${safeTask.taskId} in operation: $operation"
                        )
                    }
                }
                BDPlugin.prefsLock.write {
                    val tasksMap = getTaskMap(prefs)
                    tasksMap.remove(safeTask.taskId)
                    prefs.edit {
                        putString(
                            BDPlugin.keyTasksMap,
                            bdJson.encodeToString<MutableMap<String, Task>>(tasksMap)
                        )
                    }
                }
                // A stopped run's record is obsolete once the task has ended, and a canceled
                // safeTask also loses the partial file it points to
                RunHandoff.take(prefs, safeTask.taskId)?.let { handoff ->
                    if (modifiedStatus == TaskStatus.canceled) {
                        RunHandoff.deletePartialFile(context, handoff)
                    }
                }
                // Later runs (retry, resume) carry the document in the task's filename
                RunHandoff.forgetDestination(prefs, safeTask.taskId)
                QueueService.cleanupTaskId(safeTask.taskId)
                if (!retryNeeded && safeTask.options?.hasOnFinishCallback() == true) {
                    Callbacks.invokeOnTaskFinishedCallback(context, taskStatusUpdate)
                }
                AuthTaskRegistry.remove(safeTask.taskId)
            }
        }

        /** Return true if we can send a cancellation for this task
         *
         * Cancellation can only be sent if it wasn't already sent by the [BDPlugin]
         *  in the cancelTasksWithId method.  Side effect is to clean out older cancellation entries
         * from the [BDPlugin.cancelUpdateSentForTaskId]
         */
        private fun canSendCancellation(task: Task): Boolean {
            val now = currentTimeMillis()
            // Prune stale cancellation entries older than 3 seconds
            BDPlugin.cancelUpdateSentForTaskId.entries.removeAll { now - it.value >= 3000 }
            return BDPlugin.cancelUpdateSentForTaskId[task.taskId] == null
        }

        /**
         * Processes a progress update for the [task]
         *
         * Sends progress update via the background channel to Flutter, if requested
         */
        suspend fun processProgressUpdate(
            task: Task, progress: Double, prefs: SharedPreferences, expectedFileSize: Long = -1,
            downloadSpeed: Double = -1.0, timeRemaining: Long = -1000
        ) {
            val safeTask = AuthTaskRegistry.persistable(task)

            if (safeTask.providesProgressUpdates()) {
                postOnBackgroundChannel(
                    "progressUpdate", safeTask,
                    mutableListOf(progress, expectedFileSize, downloadSpeed, timeRemaining),
                    onFail =
                        {
                            // unsuccessful post, so store in local prefs
                            Log.d(TAG, "Could not post progress update -> storing locally")
                            storeLocally(
                                BDPlugin.keyProgressUpdateMap,
                                safeTask.taskId,
                                    bdJson.encodeToString<TaskProgressUpdate>(
                                    TaskProgressUpdate(
                                        safeTask,
                                        progress,
                                        expectedFileSize
                                    )
                                ),
                                prefs
                            )
                        })
            }
        }

        /**
         * Send 'canResume' message via the background channel to Flutter
         */
        suspend fun processCanResume(task: Task, canResume: Boolean) {
            val safeTask = AuthTaskRegistry.persistable(task)
            postOnBackgroundChannel("canResume", safeTask, canResume)
        }

        /**
         * Process resume information
         *
         * Attempts to post this to the Dart side via background channel. If that is not
         * successful, stores the resume data in shared preferences, for later retrieval by
         * the Dart side.
         *
         * Also stores a copy in memory locally, to allow notifications to resume a task
         */
        suspend fun processResumeData(resumeData: ResumeData, prefs: SharedPreferences) {
            val safeResumeData = resumeData.copy(
                task = AuthTaskRegistry.persistable(resumeData.task)
            )
            BDPlugin.localResumeData[safeResumeData.task.taskId] = safeResumeData
            postOnBackgroundChannel(
                "resumeData", safeResumeData.task, mutableListOf(
                    safeResumeData.data,
                    safeResumeData.requiredStartByte,
                    safeResumeData.eTag
                ), onFail =
                    {
                        // unsuccessful post, so store the resume data in local prefs
                        Log.d(TAG, "Could not post resume data -> storing locally")
                        storeLocally(
                            BDPlugin.keyResumeDataMap,
                            safeResumeData.task.taskId,
                            bdJson.encodeToString<ResumeData>(safeResumeData),
                            prefs
                        )
                    })
        }

        /**
         * Store the [item] in preferences under [prefsKey], keyed by [taskId]
         */
        private fun storeLocally(
            prefsKey: String,
            taskId: String,
            item: String,
            prefs: SharedPreferences
        ) {
            BDPlugin.prefsLock.write {
                // add the data to a map keyed by taskId
                val jsonString = prefs.getString(prefsKey, "{}") as String
                val mapByTaskId = bdJson.decodeFromString<MutableMap<String, String>>(jsonString)
                mapByTaskId[taskId] = item
                prefs.edit {
                    putString(
                        prefsKey, bdJson.encodeToString<MutableMap<String, String>>(mapByTaskId)
                    )
                }
            }
        }

    }

    var task: Task
        get() = context.task
        set(value) { context.task = value }

    // properties related to pause/resume functionality and progress
    var startByte = 0L // actual starting position within the task range, used for resume
    var bytesTotal = 0L // total bytes read in this download session
    var taskCanResume: Boolean
        get() = context.taskCanResume
        set(value) { context.taskCanResume = value }
    var isResume = false // whether task is a resume
    private var bytesTotalAtLastProgressUpdate = 0L
    private var lastProgressUpdateTime = 0L // in millis
    private var lastProgressUpdate = 0.0
    private var nextProgressUpdateTime = 0L
    var networkSpeed: Double
        get() = context.networkSpeed
        set(value) { context.networkSpeed = value }
    private var isTimedOut = false

    // properties related to notifications
    var notificationConfigJsonString: String?
        get() = context.notificationConfigJsonString
        set(value) { context.notificationConfigJsonString = value }
    var notificationConfig: NotificationConfig?
        get() = context.notificationConfig
        set(value) { context.notificationConfig = value }
    var notificationId: Int
        get() = context.notificationId
        set(value) { context.notificationId = value }
    var notificationProgress: Double
        get() = context.notificationProgress
        set(value) { context.notificationProgress = value }

    @Volatile
    var activeConnection: HttpURLConnection? = null

    // additional parameters for final TaskStatusUpdate
    var taskException: TaskException? = null
    var responseBody: String? = null
    private var responseHeaders: Map<String, String>? = null
    var responseStatusCode: Int? = null
    private var mimeType: String? = null // derived from Content-Type header
    private var charSet: String? = null // derived from Content-Type header

    // related to foreground tasks
    private var runInForegroundFileSize: Int = -1
    var canRunInForeground = false
    var runInForeground: Boolean
        get() = context.runInForeground
        set(value) { context.runInForeground = value }
    private var hasDeliveredResult = false
    val isActive: Boolean
        get() = !hasDeliveredResult && context.isActive

    /**
     * True if the platform stopped this run and will run the task again (see
     * [TaskJobContext.willRunAgain]), and the task was not canceled meanwhile
     */
    val isInterruptedBySystem: Boolean
        get() = context.willRunAgain && !BDPlugin.canceledTaskIds.contains(task.taskId)

    lateinit var prefs: SharedPreferences

    /**
     * Runner execution entrypoint
     */
    open suspend fun run() {
        prefs = PreferenceManager.getDefaultSharedPreferences(context.appContext)
        runInForegroundFileSize =
            prefs.getInt(BDPlugin.keyConfigForegroundFileSize, -1)
        val taskId = context.task.taskId
        // A run the platform stopped may still be unwinding: wait for it, so this run never
        // writes alongside it and sees where it left the partial file
        val turn = RunHandoff.awaitTurn(taskId)
        try {
            runTask()
        } finally {
            RunHandoff.endTurn(taskId, turn)
        }
        hasDeliveredResult = true
    }

    private suspend fun runTask() {
        withContext(Dispatchers.IO) {
            task = context.task
            val isExpedited = task.priority < 5 && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
            val timeout = if (isExpedited) expeditedTaskTimeoutMillis else taskTimeoutMillis
            CoroutineScope(Dispatchers.Default).launch {
                delay(timeout)
                isTimedOut = true
            }
            if (task.options?.hasBeforeStartCallback() == true) {
                val statusUpdate = Callbacks.invokeBeforeTaskStartCallback(context.appContext, task)
                if (statusUpdate != null) {
                    Log.i(
                        TAG,
                        "TaskId ${task.taskId} interrupted by beforeTaskStart callback"
                    )
                    processStatusUpdate(
                        task,
                        statusUpdate.taskStatus,
                        prefs,
                        taskException = statusUpdate.exception,
                        responseBody = statusUpdate.responseBody,
                        responseHeaders = statusUpdate.responseHeaders,
                        responseStatusCode = statusUpdate.responseStatusCode,
                        context = context.appContext
                    )
                    BDPlugin.holdingQueue?.taskFinished(task)
                    return@withContext // task interrupted
                }
            }

            var status = TaskStatus.failed
            try {
                task = getModifiedTask(
                    context = context.appContext,
                    task = task
                )
                notificationConfig = context.notificationConfig
                notificationConfigJsonString = if (notificationConfig != null) bdJson.encodeToString<NotificationConfig>(notificationConfig!!) else null

                canRunInForeground = runInForegroundFileSize >= 0 &&
                        notificationConfig?.running != null // must have notification
                isResume = determineIfResume()
                Log.i(
                    TAG,
                    "${if (isResume) "Resuming" else "Starting"} task with taskId ${task.taskId}"
                )
                processStatusUpdate(task, TaskStatus.running, prefs, context = context.appContext)
                if (!isResume) {
                    processProgressUpdate(task, 0.0, prefs)
                }
                context.updateNotification(AuthTaskRegistry.persistable(task), TaskStatus.running)
                status = doTask()
            } catch (e: Exception) {
                Log.w(TAG, "TaskRunner.run execution failed for taskId ${task.taskId}: $e")
                if (e is CancellationException) {
                    if (BDPlugin.cancelUpdateSentForTaskId.contains(task.taskId)) {
                        status = TaskStatus.canceled
                    }
                    // else status remains .failed (system cancellation)
                }
                setTaskException(e)
            } finally {
                withContext(NonCancellable) {
                    // Restore the encrypted descriptor before a system re-enqueue.
                    task = AuthTaskRegistry.persistable(task)
                    // NonCancellable to make sure we clean up even if job is being cancelled
                    if (status == TaskStatus.failed && isInterruptedBySystem) {
                        // The task continues in its next run, so it is not reported and keeps
                        // its holding queue slot
                        if (context.runAgain()) {
                            Log.i(
                                TAG,
                                "Task ${task.taskId} was stopped by the system (stop reason " +
                                        "${context.platformStopReason}) and will run again"
                            )
                            return@withContext
                        }
                        Log.w(TAG, "Task ${task.taskId} was stopped by the system and could not be enqueued again")
                    }
                    processStatusUpdate(
                        task,
                        status,
                        prefs,
                        taskException,
                        responseBody,
                        responseHeaders,
                        responseStatusCode,
                        mimeType,
                        charSet,
                        context.appContext
                    )
                    if (status != TaskStatus.failed || task.retriesRemaining == 0) {
                        // update only if not failed, or no retries remaining
                        context.updateNotification(AuthTaskRegistry.persistable(task), status)
                    }
                    if (status != TaskStatus.canceled) {
                        // let the holdingQueue know this task is no longer active
                        // except TaskStatus.canceled is handled directly in cancellation and reset methods
                        BDPlugin.holdingQueue?.taskFinished(task)
                    }
                    if (isInterruptedBySystem) {
                        // The run reached an outcome (e.g. completed while being stopped), so
                        // the run the platform scheduled after the stop must not repeat it
                        context.cancelRunAgain()
                    }
                }
            }
        }
    }

    /** Return true if resume is possible - defaults to false */
    open fun determineIfResume(): Boolean {
        return false
    }

    /**
     * Do the task
     *
     * Sets up the HTTP client to use, creates the connection (but does not
     * yet connect) and calls [connectAndProcess]
     *
     * Returns the [TaskStatus]
     */
    private suspend fun doTask(): TaskStatus {
        try {
            var requestUrl = URL(task.url)
            val requestTimeoutSeconds =
                prefs.getInt(BDPlugin.keyConfigRequestTimeout, 60)
            val proxyAddress =
                prefs.getString(BDPlugin.keyConfigProxyAddress, null)
            val proxyPort = prefs.getInt(BDPlugin.keyConfigProxyPort, 0)
            val proxy = if (proxyAddress != null && proxyPort != 0) Proxy(
                Proxy.Type.HTTP,
                InetSocketAddress(proxyAddress, proxyPort)
            ) else null
            if (!BDPlugin.haveLoggedProxyMessage) {
                Log.i(
                    TAG,
                    if (proxy == null) "Not using proxy for any task"
                    else "Using proxy $proxyAddress:$proxyPort for all tasks"
                )
                BDPlugin.haveLoggedProxyMessage = true
            }

            val credentialedTask = AuthTaskRegistry.isProtected(task)
            var redirectsFollowed = 0
            while (true) {
                val connection = withContext(Dispatchers.IO) {
                    requestUrl.openConnection(proxy ?: Proxy.NO_PROXY) as HttpURLConnection
                }
                activeConnection = connection
                connection.requestMethod = task.httpRequestMethod
                connection.connectTimeout = requestTimeoutSeconds * 1000
                connection.readTimeout = requestTimeoutSeconds * 1000
                // Authenticated redirects are followed manually so credentials can only
                // reach the same HTTPS origin. Other tasks keep HttpURLConnection behavior.
                connection.instanceFollowRedirects = !credentialedTask
                for (header in task.headers) {
                    // For UploadTask, copy headers unless it's "Range" or "Content-Disposition".
                    // For other task types, copy all headers.
                    if (!task.isUploadTask() ||
                        (!header.key.equals("Range", ignoreCase = true) &&
                                !header.key.equals("Content-Disposition", ignoreCase = true))
                    ) {
                        connection.setRequestProperty(header.key, header.value)
                    }
                }

                if (!credentialedTask) {
                    return connectAndProcess(connection)
                }

                val responseCode = connection.responseCode
                if (responseCode !in listOf(301, 302, 303, 307, 308)) {
                    return connectAndProcess(connection)
                }
                val location = connection.getHeaderField("Location")
                if (location.isNullOrBlank()) {
                    return connectAndProcess(connection)
                }
                if (!task.httpRequestMethod.equals("GET", ignoreCase = true) ||
                    redirectsFollowed >= 5
                ) {
                    connection.disconnect()
                    activeConnection = null
                    throw IOException("Authenticated request redirect limit or method blocked")
                }
                val nextUrl = URL(requestUrl, location)
                if (!isSameHttpsOrigin(requestUrl, nextUrl)) {
                    connection.disconnect()
                    activeConnection = null
                    throw IOException("Authenticated request cross-origin redirect blocked")
                }
                connection.disconnect()
                activeConnection = null
                requestUrl = nextUrl
                redirectsFollowed += 1
            }
        } catch (e: Exception) {
            Log.w(
                TAG, "Error for taskId ${task.taskId}: $e\n${e.stackTraceToString()}"
            )
            setTaskException(e)
        } finally {
            activeConnection = null
        }
        return TaskStatus.failed
    }

    private fun isSameHttpsOrigin(first: URL, second: URL): Boolean {
        if (!first.protocol.equals("https", ignoreCase = true) ||
            !second.protocol.equals("https", ignoreCase = true) ||
            first.userInfo != null ||
            second.userInfo != null
        ) {
            return false
        }
        val firstPort = if (first.port >= 0) first.port else 443
        val secondPort = if (second.port >= 0) second.port else 443
        return first.host.equals(second.host, ignoreCase = true) && firstPort == secondPort
    }


    /**
     * Further configures the connection and makes the actual request by
     * calling [process], while catching errors
     *
     * Returns the [TaskStatus]
     * */
    open suspend fun connectAndProcess(connection: HttpURLConnection): TaskStatus {
        try {
            if ((task.isDownloadTask() || task.isDataTask()) && task.post != null) {
                val bytes = task.post!!.toByteArray()
                connection.doOutput = true
                connection.setFixedLengthStreamingMode(bytes.size)
                DataOutputStream(connection.outputStream).use {
                    it.write(bytes)
                    it.flush()
                }
            }
            return process(connection)
        } catch (e: Exception) {
            if (isInterruptedBySystem) {
                // Not a cancel: the task continues in its next run, which [run] arranges
                Log.i(TAG, "Task ${task.taskId} was stopped by the system, ignoring exception: ${e.message}")
                return TaskStatus.failed
            }
            if (context.isTaskStopped || BDPlugin.canceledTaskIds.contains(task.taskId)) {
                Log.i(TAG, "Task ${task.taskId} was canceled, ignoring exception: ${e.message}")
                return TaskStatus.canceled
            }
            if (BDPlugin.pausedTaskIds.contains(task.taskId)) {
                Log.i(TAG, "Task ${task.taskId} was paused, ignoring exception: ${e.message}")
                return TaskStatus.paused
            }
            if (isTimedOut && !runInForeground) {
                Log.i(TAG, "Task ${task.taskId} timed out, ignoring exception: ${e.message}")
                return TaskStatus.enqueued
            }

            setTaskException(e)
            when (e) {
                is SocketException, is SocketTimeoutException -> Log.i(
                    TAG,
                    "Socket exception for taskId ${task.taskId}: ${e.message}"
                )

                is IOException -> Log.w(
                    TAG,
                    "FileSystem/IO exception for taskId ${task.taskId}: ${e.message}"
                )

                is CancellationException -> {
                    if (BDPlugin.cancelUpdateSentForTaskId.contains(task.taskId)) {
                        Log.i(
                            TAG,
                            "Canceled task with id ${task.taskId}: ${e.message}"
                        )
                        return TaskStatus.canceled
                    } else {
                        Log.i(
                            TAG,
                            "WorkManager CancellationException for task with id ${task.taskId} without manual cancellation: failing task"
                        )
                        return TaskStatus.failed
                    }
                }

                else -> {
                    Log.w(
                        TAG,
                        "Error for taskId ${task.taskId}: ${e.message}\n${e.stackTraceToString()}"
                    )
                    taskException = TaskException(
                        ExceptionType.general, description =
                            "Error for url ${task.url}: ${e.message}"
                    )
                }
            }
        } finally {
            // clean up remaining bytes tracking
            BDPlugin.remainingBytesToDownload.remove(task.taskId)
        }
        return TaskStatus.failed
    }

    /**
     * Process the [task] using the [connection]
     *
     * Returns the [TaskStatus]
     *
     * Overridden by subclasses
     */
    open suspend fun process(
        connection: HttpURLConnection
    ): TaskStatus {
        throw NotImplementedError()
    }

    /**
     * Transfer all bytes from [inputStream] to [outputStream] and provide
     * progress updates for the [task]
     *
     * Will return [TaskStatus.canceled], [TaskStatus.paused], [TaskStatus.failed],
     * [TaskStatus.complete], or special [TaskStatus.enqueued] which signals the task timed out
     *
     * [contentLength] is used to calculate progress. If [contentLength] is 0, no progress updates
     * will be provided
     */
    suspend fun transferBytes(
        inputStream: InputStream, outputStream: OutputStream, contentLength: Long, task: Task
    ): TaskStatus {
        val dataBuffer = ByteArray(bufferSize)
        var numBytes: Int
        return withContext(Dispatchers.Default) {
            var readerJob: Job? = null
            var testerJob: Job? = null
            val doneCompleter = CompletableDeferred<TaskStatus>()
            try {
                readerJob = launch(Dispatchers.IO) {
                    try {
                        while (inputStream.read(
                                dataBuffer, 0,
                                bufferSize
                            )
                                .also { numBytes = it } != -1
                        ) {
                            if (!isActive) {
                                doneCompleter.complete(TaskStatus.failed)
                                break
                            }
                            if (numBytes > 0) {
                                try {
                                    outputStream.write(dataBuffer, 0, numBytes)
                                } catch (e: DownloadStorageException) {
                                    setTaskException(e)
                                    doneCompleter.complete(TaskStatus.failed)
                                    return@launch
                                }
                                bytesTotal += numBytes
                                val remainingBytes =
                                    BDPlugin.remainingBytesToDownload[task.taskId]
                                if (remainingBytes != null) {
                                    BDPlugin.remainingBytesToDownload[task.taskId] =
                                        remainingBytes - numBytes
                                }
                            }
                            val expectedFileSize = contentLength + startByte
                            val progress = doubleMin(
                                (bytesTotal + startByte).toDouble() / expectedFileSize,
                                0.999
                            )
                            if (contentLength > 0 && shouldSendProgressUpdate(
                                    progress,
                                    currentTimeMillis()
                                )
                            ) {
                                updateProgressAndNotify(progress, expectedFileSize, task)
                            }
                        }
                        doneCompleter.complete(TaskStatus.complete)
                    } catch (e: Exception) {
                        if (!doneCompleter.isCompleted) {
                            doneCompleter.completeExceptionally(e)
                        }
                    }
                }
                testerJob = launch {
                    while (isActive) {
                        // check if task is stopped (canceled), paused or timed out
                        if (context.isTaskStopped) {
                            activeConnection?.disconnect()
                            Log.w(TAG, "Task ${task.taskId} stopped")
                            doneCompleter.complete(TaskStatus.failed)
                            break
                        }
                        // 'pause' is signalled by adding the taskId to a static list
                        if (BDPlugin.pausedTaskIds.contains(task.taskId)) {
                            activeConnection?.disconnect()
                            doneCompleter.complete(TaskStatus.paused)
                            break
                        }
                        if (isTimedOut && !runInForeground) {
                            activeConnection?.disconnect()
                            // special use of .enqueued status, see [processDownload]
                            doneCompleter.complete(TaskStatus.enqueued)
                            break
                        }
                        delay(100)
                    }
                }
                return@withContext doneCompleter.await()
            } catch (e: Exception) {
                Log.i(TAG, "Exception for taskId ${task.taskId}: $e")
                setTaskException(e)
                return@withContext TaskStatus.failed
            } finally {
                readerJob?.cancelAndJoin()
                testerJob?.cancelAndJoin()
            }
        }
    }

    /**
     * Returns true if [currentProgress] > [lastProgressUpdate] + 2% and
     * [now] > [nextProgressUpdateTime], or if there was progress and
     * [now] > [nextProgressUpdateTime] + 2 seconds
     */
    open fun shouldSendProgressUpdate(currentProgress: Double, now: Long): Boolean {
        return (currentProgress - lastProgressUpdate > 0.02 &&
                now > nextProgressUpdateTime) || (currentProgress > lastProgressUpdate &&
                now > nextProgressUpdateTime + 2000)
    }

    /**
     * Calculate network speed and time remaining, then post an update
     * to the Dart side and update the 'running' notification
     *
     * Mst be called at the appropriate frequency, and will update
     * [lastProgressUpdate] and [nextProgressUpdateTime]
     */
    suspend fun updateProgressAndNotify(
        progress: Double,
        expectedFileSize: Long,
        task: Task
    ) {
        val now = currentTimeMillis()
        if (task.isParallelDownloadTask()) {
            // approximate based on aggregate progress
            bytesTotal = (progress * expectedFileSize).toLong()
        }
        val timeSinceLastUpdate = now - lastProgressUpdateTime
        lastProgressUpdateTime = now
        val bytesSinceLastUpdate = bytesTotal - bytesTotalAtLastProgressUpdate
        bytesTotalAtLastProgressUpdate = bytesTotal
        val currentNetworkSpeed: Double = if (timeSinceLastUpdate > 3600000)
            -1.0 else bytesSinceLastUpdate / (timeSinceLastUpdate * 1000.0)
        networkSpeed =
            if (networkSpeed == -1.0) currentNetworkSpeed else (networkSpeed * 3.0 + currentNetworkSpeed) / 4.0
        val remainingBytes = (1 - progress) * expectedFileSize
        val timeRemaining: Long =
            if (networkSpeed == -1.0) -1000 else (remainingBytes / networkSpeed / 1000).toLong()
        // update progress and notification
        processProgressUpdate(
            task,
            progress,
            prefs,
            expectedFileSize,
            networkSpeed,
            timeRemaining
        )
        context.updateNotification(
            AuthTaskRegistry.persistable(task),
            TaskStatus.running,
            progress, timeRemaining
        )
        lastProgressUpdate = progress
        nextProgressUpdateTime = currentTimeMillis() + 500
    }


    /**
     * Determine if this task should run in the foreground
     *
     * Based on [canRunInForeground] and [contentLength] > [runInForegroundFileSize]
     */
    fun determineRunInForeground(task: Task, contentLength: Long) {
        val wasRunInForeground = runInForeground
        runInForeground =
            canRunInForeground && contentLength > (runInForegroundFileSize.toLong() shl 20)
        if (runInForeground) {
            Log.i(TAG, "TaskId ${task.taskId} will run in foreground")
            if (!wasRunInForeground) {
                CoroutineScope(Dispatchers.Default).launch {
                    context.updateNotification(AuthTaskRegistry.persistable(task), TaskStatus.running)
                }
            }
        }
    }


    /**
     * Return the response's error content as a String, or null if unable
     */
    fun responseErrorContent(connection: HttpURLConnection): String? {
        try {
            return connection.errorStream.bufferedReader().readText()
        } catch (e: Exception) {
            Log.i(
                TAG,
                "Could not read response error content from httpResponseCode ${connection.responseCode}: $e"
            )
        }
        return null
    }

    /**
     * Set the [taskException] variable based on Exception [e]
     */
    private fun setTaskException(e: Any) {
        var exceptionType = ExceptionType.general
        if (e is IOException) {
            exceptionType = ExceptionType.fileSystem
        }
        if (e is SocketException || e is SocketTimeoutException) {
            exceptionType = ExceptionType.connection
        }
        val description = if (e is DownloadStorageException) e.message.orEmpty() else e.toString()
        if (isDownloadStorageFailure(description)) {
            task.retriesRemaining = 0
            taskCanResume = false
            BDPlugin.localResumeData.remove(task.taskId)
        }
        taskException = TaskException(exceptionType, description = description)
    }

    /**
     * Extract content type from [headers] and set [mimeType] and [charSet]
     */
    fun extractContentType(headers: MutableMap<String, MutableList<String>>) {
        val contentType = headerValue(headers, "Content-Type")
        if (contentType != null) {
            val regEx = Regex("""(.*);\s*charset\s*=(.*)""")
            val match = regEx.find(contentType)
            if (match != null) {
                mimeType = match.groups[1]?.value
                charSet = match.groups[2]?.value
            } else {
                mimeType = contentType
            }
        }
    }

    /**
     * Extract headers from response [headers] and store in [responseHeaders]
     *
     * Required because the headers object has a List<String> for each key,
     * whereas the Dart convention separates values under the same key by
     * concatenating them, separated by a comma and a space.
     *
     * This method sets the global responseHeaders field based on the Dart
     * convention.
     */
    fun extractResponseHeaders(headers: MutableMap<String, MutableList<String>>) {
        responseHeaders = headers.mapValues { it.value.joinToString() }
    }
}

/** Return the map of tasks stored in preferences */
fun getTaskMap(prefs: SharedPreferences): MutableMap<String, Task> {
    BDPlugin.prefsLock.read {
        val tasksMapJson = prefs.getString(BDPlugin.keyTasksMap, "{}") ?: "{}"
        return bdJson.decodeFromString(tasksMapJson)
    }
}

/**
 * Persist only an updated encrypted descriptor. The actual request URL and
 * headers returned by an auth callback are intentionally never written here.
 */
private fun persistProtectedTaskMetadata(task: Task, prefs: SharedPreferences) {
    if (!AuthTaskRegistry.isProtected(task) ||
        !task.metaData.startsWith("enc:v2:") ||
        task.metaData.toByteArray().size > 16384
    ) {
        return
    }
    BDPlugin.prefsLock.write {
        val storedJson = prefs.getString(BDPlugin.keyTasksMap, "{}") ?: "{}"
        val tasksMap = bdJson.decodeFromString<MutableMap<String, Task>>(storedJson)
        val stored = tasksMap[task.taskId] ?: return@write
        if (stored.url != task.url ||
            !stored.metaData.startsWith("enc:v2:") ||
            stored.metaData == task.metaData
        ) {
            return@write
        }
        tasksMap[task.taskId] = stored.copyWith(metaData = task.metaData)
        prefs.edit {
            putString(
                BDPlugin.keyTasksMap,
                bdJson.encodeToString<MutableMap<String, Task>>(tasksMap)
            )
        }
    }
}

/**
 * Returns a [task] that may be modified through callbacks
 *
 * Callbacks would be attached to the task via its [Task.options] property, and if
 * present will be invoked by starting a taskDispatcher on a background isolate, then
 * sending the callback request via the MethodChannel
 *
 * First test is for auth refresh (the onAuth callback), then the onStart callback. Both
 * callbacks run in a Dart isolate, and may return a modified task, which will be used
 * for the actual task execution
 */
suspend fun getModifiedTask(context: Context, task: Task): Task {
    var workingTask = task
    val initialAuth = workingTask.options?.auth
    if (initialAuth?.hasOnAuthCallback() == true && workingTask.metaData.startsWith("enc:v2:")) {
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        val storedTask = getTaskMap(prefs)[workingTask.taskId]
        if (storedTask != null &&
            storedTask.url == workingTask.url &&
            storedTask.metaData.startsWith("enc:v2:") &&
            storedTask.metaData != workingTask.metaData
        ) {
            // WorkManager's input Data can be older than the durable task record
            // after process death. Use only the rotated encrypted descriptor.
            workingTask = workingTask.copyWith(metaData = storedTask.metaData)
        }
    }

    var authTask: Task? = null
    val auth = workingTask.options?.auth
    if (auth != null) {
        AuthTaskRegistry.remember(workingTask)
        // Refresh token if needed
        if (auth.isTokenExpired() && auth.hasOnAuthCallback()) {
            authTask = withContext(Dispatchers.IO) {
                Callbacks.invokeOnAuthCallback(context, workingTask)
            }
        }
        authTask = authTask ?: workingTask // Either original or newly authorized
        // Save a rotated token before running a request that could be stopped
        // or have its process killed.
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        persistProtectedTaskMetadata(AuthTaskRegistry.persistable(authTask), prefs)
        val newAuth = authTask.options?.auth
        if (newAuth != null) {
            // Insert query parameters and headers when the callback retained Auth.
            // A callback that removes Auth has already supplied the full request.
            val uri = newAuth.addOrUpdateQueryParams(
                url = authTask.url,
                queryParams = newAuth.getExpandedAccessQueryParams()
            )
            val headers =
                authTask.headers.toMutableMap().apply { putAll(newAuth.getExpandedAccessHeaders()) }
            authTask = authTask.copyWith(url = uri.toString(), headers = headers)
        }
    }
    authTask = authTask ?: workingTask
    if (workingTask.options?.hasOnStartCallback() != true) {
        return authTask
    }
    // onStart callback
    val modifiedTask = withContext(Dispatchers.IO) {
        Callbacks.invokeOnTaskStartCallback(context, authTask)
    }
    val result = modifiedTask ?: authTask
    val prefs = PreferenceManager.getDefaultSharedPreferences(context)
    persistProtectedTaskMetadata(AuthTaskRegistry.persistable(result), prefs)
    return result
}

/**
 * Returns the length of the [string] in bytes when utf-8 encoded
 */
fun lengthInBytes(string: String): Int {
    return string.toByteArray().size
}
