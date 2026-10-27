package com.bbflight.background_downloader

import android.annotation.SuppressLint
import android.app.ForegroundServiceStartNotAllowedException
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ActivityNotFoundException
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.annotation.Keep
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationCompat.Builder
import androidx.core.app.NotificationManagerCompat
import androidx.work.Data
import androidx.work.ForegroundInfo
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.bbflight.background_downloader.BDPlugin.Companion.TAG
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.InternalSerializationApi
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import java.util.Locale
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.roundToInt
import kotlin.text.Regex.Companion.escapeReplacement

/**
 * Notification specification
 *
 * [body] may contain special string {filename] to insert the filename
 *   and/or special string {progress} to insert progress in %
 *
 * Actual appearance of notification is dependent on the platform, e.g.
 * on iOS {progress} and progressBar are not available and ignored
 */
@OptIn(InternalSerializationApi::class)
@Serializable
class TaskNotification(val title: String, val body: String) {
    override fun toString(): String {
        return "Notification(title='$title', body='$body')"
    }
}

/**
 * Notification configuration object
 *
 * [running] is the notification used while the task is in progress
 * [complete] is the notification used when the task completed
 * [error] is the notification used when something went wrong,
 * including pause, failed and notFound status
 */
@OptIn(InternalSerializationApi::class)
@Serializable
class NotificationConfig(
    val running: TaskNotification?,
    val complete: TaskNotification?,
    val error: TaskNotification?,
    val paused: TaskNotification?,
    val canceled: TaskNotification?,
    val progressBar: Boolean,
    val tapOpensFile: Boolean,
    val groupNotificationId: String
) {
    override fun toString(): String {
        return "NotificationConfig(running=$running, complete=$complete, error=$error, paused=$paused, progressBar=$progressBar, tapOpensFile=$tapOpensFile, groupNotificationId=$groupNotificationId)"
    }
}

/**
 * Data associated with a groupNotification
 */
class GroupNotification(
    val name: String,
    val notificationConfig: NotificationConfig
) {
    private var notifications = ConcurrentHashMap<Task, NotificationType>()

    /** NotificationId derived from group name */
    val notificationId get() = "groupNotification$name".hashCode()

    /** Total number of notifications in this group */
    val numTotal get() = notifications.size

    /** Progress expressed as [numFinished]/[numTotal], except
     * return 2.0 if numTotal is 0, to suggest that progress
     * is undetermined
     */
    val progress get() = if (numTotal == 0) 2.0 else numFinished.toDouble() / numTotal.toDouble()

    /** Number of "finished" notifications in this group.
     *
     * A "finished" notification is one that is not .running,
     * so includes .complete, .error, .paused
     * */
    val numFinished get() = notifications.filter { (_, v) -> v != NotificationType.running }.size

    /** Number of "failed" notifications in this group.
     *
     * A "failed" notification is one of type .error
     * */
    val numFailed get() = notifications.filter { (_, v) -> v == NotificationType.error }.size

    /** True if all tasks finished, regardless of outcome */
    val isFinished get() = numFinished == numTotal

    /**
     * Return true if this group has an error
     */
    val hasError get() = numFailed > 0

    /** Returns a Set of running tasks in this groupNotification */
    val runningTasks
        get() = notifications.filter { (_, notificationType) ->
            notificationType == NotificationType.running
        }.keys

    /** Int representing this group's state. If this number
     * does not change, the group state did not change.
     *
     * State is determined by the number of finished notifications
     * and the number of total notifications
     */
    private val groupState get() = 1000 * numTotal + numFinished

    /** Update a [task] and [notificationType] to this group,
     * and return True if this led to change in [groupState]
     *
     * Must be synchronized to avoid concurrent modification
     */
    fun update(task: Task, notificationType: NotificationType): Boolean {
        if (notifications[task] == notificationType) {
            return false
        }
        val priorState = groupState
        notifications[task] = notificationType
        return priorState != groupState
    }
}

@Suppress("EnumEntryName")
enum class NotificationType { running, complete, error, paused, canceled }

/**
 * Receiver for messages from notification, sent via intent
 *
 * Note the two cancellation actions: one for active tasks (running and managed by a
 * [WorkManager] and one for inactive (paused) tasks. Because the latter is not running in a
 * [WorkManager] job, cancellation is simpler, but the [NotificationReceiver] must remove the
 * notification that asked for cancellation directly from here. If an 'error' notification
 * was configured for the task, then it will NOT be shown (as it would when cancelling an active
 * task)
 */
@Suppress("ConstPropertyName")
@Keep
class NotificationReceiver : BroadcastReceiver() {

    companion object {
        const val actionCancelActive = "com.bbflight.background_downloader.cancelActive"
        const val actionCancelInactive = "com.bbflight.background_downloader.cancelInactive"
        const val actionPause = "com.bbflight.background_downloader.pause"
        const val actionResume = "com.bbflight.background_downloader.resume"
        const val actionTap = "com.bbflight.background_downloader.tap"
        const val keyBundle = "com.bbflight.background_downloader.bundle"
        const val keyTaskId = "com.bbflight.background_downloader.taskId"
        const val keyTask = "com.bbflight.background_downloader.task" // as JSON string
        const val keyGroupNotificationName =
            "com.bbflight.background_downloader.groupNotificationName"
        const val keyNotificationConfig =
            "com.bbflight.background_downloader.notificationConfig" // as JSON string
        const val keyNotificationType =
            "com.bbflight.background_downloader.notificationType" // ordinal of enum
        const val keyNotificationId = "com.bbflight.background_downloader.notificationId"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val bundle = intent.getBundleExtra(keyBundle)
        val taskId = bundle?.getString(keyTaskId)
        if (taskId != null) {
            // Run on a background dispatcher via goAsync() to avoid blocking the main thread
            val pendingResult = goAsync()
            CoroutineScope(Dispatchers.Default).launch {
                try {
                    handleAction(context, intent, bundle, taskId)
                } finally {
                    pendingResult.finish()
                }
            }
        } else {
            // no taskId -> groupNotification, and can only be a cancel action so
            // no need to check
            val groupNotificationName = bundle?.getString(keyGroupNotificationName)
            if (groupNotificationName != null) {
                // cancel all tasks associated with this group that have not yet completed
                val groupNotification =
                    NotificationService.groupNotifications[groupNotificationName]
                if (groupNotification != null) {
                    val pendingResult = goAsync()
                    CoroutineScope(Dispatchers.Default).launch {
                        try {
                            BDPlugin.cancelTasksWithIds(
                                context,
                                groupNotification.runningTasks.map { task -> task.taskId })
                        } finally {
                            pendingResult.finish()
                        }
                    }
                }
            }
        }
    }

    private suspend fun handleAction(
        context: Context,
        intent: Intent,
        bundle: Bundle,
        taskId: String
    ) {
        when (intent.action) {
            actionCancelActive -> {
                BDPlugin.cancelActiveTaskWithId(
                    context, taskId, WorkManager.getInstance(context)
                )
            }

            actionCancelInactive -> {
                val taskJsonString = bundle.getString(keyTask)
                if (taskJsonString != null) {
                    val task = bdJson.decodeFromString<Task>(taskJsonString)
                    BDPlugin.cancelInactiveTask(context, task)
                    with(NotificationManagerCompat.from(context)) {
                        cancel(task.taskId.hashCode())
                    }
                } else {
                    Log.d(TAG, "task was null")
                }
            }

            actionPause -> {
                BDPlugin.pauseTaskWithId(taskId)
            }

            actionResume -> {
                val resumeData = BDPlugin.localResumeData[taskId]
                if (resumeData != null) {
                    val notificationConfigJsonString = bundle.getString(
                        keyNotificationConfig
                    )
                    if (notificationConfigJsonString != null) {
                        try {
                            attemptResume(
                                context,
                                taskId,
                                resumeData,
                                notificationConfigJsonString
                            )
                        } catch (e: Exception) {
                            if (Build.VERSION.SDK_INT > Build.VERSION_CODES.S && e is ForegroundServiceStartNotAllowedException) {
                                // If resume button is clicked when app is in background,
                                // bring app to foreground before attempting resume.
                                val launchIntent =
                                    context.packageManager.getLaunchIntentForPackage(
                                        context.packageName
                                    )?.apply {
                                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    }
                                if (launchIntent != null) {
                                    CoroutineScope(Dispatchers.Main).launch {
                                        try {
                                            // Start the activity, wait, then resume
                                            context.startActivity(launchIntent)
                                            delay(3000)
                                            attemptResume(
                                                context,
                                                taskId,
                                                resumeData,
                                                notificationConfigJsonString
                                            )
                                        } catch (activityException: ActivityNotFoundException) {
                                            Log.e(
                                                TAG,
                                                "When resuming taskId $taskId, could not find activity to launch for package ${context.packageName}",
                                                activityException
                                            )
                                        } catch (securityException: SecurityException) {
                                            Log.e(
                                                TAG,
                                                "When resuming taskId $taskId, SecurityException starting activity: ${securityException.message}",
                                                securityException
                                            )
                                        } catch (e: Exception) {
                                            Log.e(
                                                TAG,
                                                "Exception resuming taskId $taskId: ${e.message}",
                                                e
                                            )
                                        }
                                    }
                                } else {
                                    Log.e(
                                        TAG,
                                        "When resuming taskId $taskId, could not get launch intent for package ${context.packageName}"
                                    )
                                }
                            } else {
                                Log.e(
                                    TAG,
                                    "Error resuming taskId $taskId: ${e.message}",
                                    e
                                )
                            }
                        }
                    } else {
                        BDPlugin.cancelActiveTaskWithId(
                            context, taskId, WorkManager.getInstance(context)
                        )
                    }
                } else {
                    BDPlugin.cancelActiveTaskWithId(
                        context, taskId, WorkManager.getInstance(context)
                    )
                }
            }

            else -> {}
        }
    }

    private suspend fun attemptResume(
        context: Context,
        taskId: String,
        resumeData: ResumeData,
        notificationConfigJsonString: String?
    ) {
        val holdingQueue = BDPlugin.holdingQueue
        if (holdingQueue != null) {
            // Route the resume through the holding queue so the task competes for
            // a slot under maxConcurrent; a direct doEnqueue would run it outside
            // the queue's accounting
            holdingQueue.add(
                EnqueueItem(
                    context = context,
                    task = resumeData.task,
                    notificationConfigJsonString = notificationConfigJsonString,
                    resumeData = resumeData
                )
            )
            Log.i(TAG, "Queued taskId $taskId to resume")
            return
        }
        if (!BDPlugin.doEnqueue(
                context,
                resumeData.task,
                notificationConfigJsonString,
                resumeData
            )
        ) {
            Log.i(TAG, "Could not enqueue taskId $taskId to resume")
        }
    }
}

/**
 * Singleton service to manage notifications
 */
@Suppress("ConstPropertyName")
object NotificationService {
    var groupNotifications = ConcurrentHashMap<String, GroupNotification>()

    private const val notificationChannelId = "background_downloader"

    private val mutex = Mutex()
    private val queue = Channel<Unit>(Channel.CONFLATED)
    private val pendingNotifications = java.util.ArrayDeque<NotificationData>()
    private val scope = CoroutineScope(Dispatchers.Default)
    private var lastNotificationTime: Long = 0
    private var createdNotificationChannel = false
    private const val MIN_NOTIFICATION_INTERVAL_MS = 300L

    /**
     * Starts listening to the queue and processes each item
     *
     * Each item is a NotificationData object that represents a
     * new or updated notification
     */
    init {
        scope.launch {
            for (event in queue) processQueue()
        }
    }

    /**
     * Process the queue, one by one, but collapsing progress updates
     * for the same notificationId
     */
    private suspend fun processQueue() {
        while (true) {
            val timeSinceLastNotification = System.currentTimeMillis() - lastNotificationTime
            if (timeSinceLastNotification < MIN_NOTIFICATION_INTERVAL_MS) {
                delay(MIN_NOTIFICATION_INTERVAL_MS - timeSinceLastNotification)
            }
            val notificationData = mutex.withLock {
                if (pendingNotifications.isEmpty()) {
                    return@withLock null
                }
                var candidate = pendingNotifications.removeFirst()
                // if the candidate is a progress update, check if there are more
                // progress updates for the same notificationId in the queue
                // and if so, use the last one
                if (candidate.notificationType == NotificationType.running) {
                    val iterator = pendingNotifications.iterator()
                    while (iterator.hasNext()) {
                        val next = iterator.next()
                        if (next.taskWorker.notificationId == candidate.taskWorker.notificationId) {
                            if (next.notificationType == NotificationType.running) {
                                // Found a newer progress update, supersede the current candidate
                                candidate = next
                                iterator.remove()
                            } else {
                                // Found a non-running update (barrier), stop looking for this task
                                break
                            }
                        }
                    }
                }
                candidate
            }
            if (notificationData != null) {
                processNotificationData(notificationData)
                lastNotificationTime = System.currentTimeMillis()
            } else {
                break
            }
        }
    }

    /**
     * Creates an [UpdateNotificationWorker] to update the notification associated with
     * this task
     *
     * This is used when we do not have access to the [TaskWorker] object, i.e.
     * when called from outside an actively running worker.
     */
    fun createUpdateNotificationWorker(
        context: Context,
        taskJson: String,
        notificationConfigJson: String?,
        taskStatusOrdinal: Int?
    ) {
        // create dummy TaskWorker
        val requestBuilder = OneTimeWorkRequestBuilder<UpdateNotificationWorker>()
        val dataBuilder =
            Data.Builder().putString(TaskWorker.keyTask, taskJson)
                .putString(TaskWorker.keyNotificationConfig, notificationConfigJson)
        if (taskStatusOrdinal != null) {
            dataBuilder.putInt(UpdateNotificationWorker.keyTaskStatusOrdinal, taskStatusOrdinal)
        }
        requestBuilder.setInputData(dataBuilder.build())
        val workManager = WorkManager.getInstance(context)
        workManager.enqueue(requestBuilder.build())
    }

    /**
     * Create or update the notification for this [taskWorker], associated with this [taskStatus]
     * [progress] and [timeRemaining]
     *
     * [taskStatus] determines the type of notification, and whether absence of one will
     * cancel the notification
     * The [progress] field is only relevant for [NotificationType.running]. If progress is
     * negative no progress bar will be shown. If progress > 1 an indeterminate progress bar
     * will be shown
     * [timeRemaining] is only relevant for [NotificationType.running]
     *
     * If this notification is part of a group, then the notification will be built
     * using [updateGroupNotification] and enqueued to avoid overloading the
     * notification system.
     *
     * For normal notification, the caller must throttle the notifications to a
     * reasonable rate
     */
    @SuppressLint("MissingPermission")
    suspend fun updateNotification(
        taskWorker: TaskJobContext,
        taskStatus: TaskStatus,
        progress: Double = 2.0,
        timeRemaining: Long = -1000
    ) {
        val notificationType = notificationTypeForTaskStatus(taskStatus)
        val groupNotificationId = taskWorker.notificationConfig?.groupNotificationId
        if (groupNotificationId?.isNotEmpty() == true) {
            if (progress == 2.0 && timeRemaining == -1000L) {
                // filter out progress updates, as they are irrelevant for group notifications
                updateGroupNotification(taskWorker, groupNotificationId, notificationType)
            }
            return
        }
        // Ignore 'enqueued' status for normal notifications
        if (taskStatus == TaskStatus.enqueued) {
            return
        }
        // regular notification
        val notification = when (notificationType) {
            NotificationType.running -> taskWorker.notificationConfig?.running
            NotificationType.complete -> taskWorker.notificationConfig?.complete
            NotificationType.error -> taskWorker.notificationConfig?.error
            NotificationType.paused -> taskWorker.notificationConfig?.paused
            NotificationType.canceled -> taskWorker.notificationConfig?.canceled
        }
        if (notification == null) {
            addToNotificationQueue(taskWorker) // removes notification
            return
        }
        // need to show a notification
        taskWorker.notificationId = taskWorker.task.taskId.hashCode()
        if (!createdNotificationChannel) {
            createNotificationChannel(taskWorker.appContext)
        }
        val iconDrawable = when (notificationType) {
            NotificationType.running -> if (taskWorker.task.isDownloadTask()) R.drawable.outline_file_download_24 else R.drawable.outline_file_upload_24
            NotificationType.complete -> R.drawable.outline_download_done_24
            NotificationType.error -> R.drawable.outline_error_outline_24
            NotificationType.paused -> R.drawable.outline_pause_24
            NotificationType.canceled -> R.drawable.outline_cancel_24
        }
        val builder = Builder(
            taskWorker.appContext, notificationChannelId
        ).setPriority(NotificationCompat.PRIORITY_LOW).setSmallIcon(iconDrawable)
            .setShowWhen(notificationType != NotificationType.running)
        if (notificationType == NotificationType.running) {
            // Keep concurrent download notifications in a stable order
            builder.setWhen(taskWorker.task.creationTime)
                .setSortKey(taskWorker.task.taskId)
                .setOnlyAlertOnce(true)
        }
        // use stored progress if notificationType is .paused
        taskWorker.notificationProgress =
            if (notificationType == NotificationType.paused) taskWorker.notificationProgress else progress
        // title and body interpolation of {filename}, {progress} and {metadata}
        val title = replaceTokens(
            notification.title,
            taskWorker.task,
            taskWorker.notificationProgress,
            networkSpeed = taskWorker.networkSpeed,
            timeRemaining = timeRemaining
        )
        if (title.isNotEmpty()) {
            builder.setContentTitle(title)
        }
        val body = replaceTokens(
            notification.body,
            taskWorker.task,
            taskWorker.notificationProgress,
            networkSpeed = taskWorker.networkSpeed,
            timeRemaining = timeRemaining
        )
        if (body.isNotEmpty()) {
            builder.setContentText(body)
        }
        // progress bar
        val progressBar =
            taskWorker.notificationConfig?.progressBar == true && (notificationType == NotificationType.running || notificationType == NotificationType.paused)
        if (progressBar && taskWorker.notificationProgress >= 0) {
            if (taskWorker.notificationProgress <= 1) {
                builder.setProgress(
                    100, (taskWorker.notificationProgress * 100).roundToInt(), false
                )
            } else { // > 1 means indeterminate
                builder.setProgress(100, 0, true)
            }
        }
        addNotificationActions(taskWorker, notificationType, builder)
        addToNotificationQueue(taskWorker, notificationType, builder)
    }

    /**
     * Register that [item] was enqueued, with [success] or failure
     *
     * This is only relevant for tasks that are part of a group notification, so that the
     * 'numTotal' count is based on enqueued tasks, not on running tasks (which may be limited
     * by holdingQueue or OS restrictions).
     */
    fun registerEnqueue(item: EnqueueItem, success: Boolean) {
        val notificationConfigJsonString = item.notificationConfigJsonString ?: return
        val notificationConfig =
            bdJson.decodeFromString<NotificationConfig>(notificationConfigJsonString)
        val groupNotificationId = notificationConfig.groupNotificationId
        if (groupNotificationId.isNotEmpty()) {
            // update the notification status for this task (requires a worker because we are
            // not within a worker when this function is called)
            createUpdateNotificationWorker(
                context = item.context,
                taskJson = bdJson.encodeToString(item.task),
                notificationConfigJson = notificationConfigJsonString,
                taskStatusOrdinal = if (success) TaskStatus.enqueued.ordinal else TaskStatus.failed.ordinal
            )
        }
    }

    /**
     * Update notification for this [taskWorker] in group
     * [groupNotificationId] and type [notificationType].
     *
     * A group notification aggregates the state of all tasks in a group and
     * presents a notification based on that value
     */
    private suspend fun updateGroupNotification(
        taskWorker: TaskJobContext, groupNotificationId: String, notificationType: NotificationType
    ) {
        val stateChange: Boolean
        val groupNotification: GroupNotification
        mutex.withLock {
            groupNotification =
                groupNotifications[groupNotificationId] ?: GroupNotification(
                    groupNotificationId, taskWorker.notificationConfig!!
                )
            stateChange = groupNotification.update(taskWorker.task, notificationType)
            groupNotifications[groupNotificationId] = groupNotification
        }
        if (stateChange || taskWorker.runInForeground) {
            // need to update the group notification
            taskWorker.notificationId = groupNotification.notificationId
            val hasError = groupNotification.hasError
            val isFinished = groupNotification.isFinished
            val notification = if (isFinished) {
                if (hasError) groupNotification.notificationConfig.error else groupNotification.notificationConfig.complete
            } else groupNotification.notificationConfig.running
            if (notification == null) {
                addToNotificationQueue(taskWorker) // removes notification
            } else {
                // need to show a notification
                if (!createdNotificationChannel) {
                    createNotificationChannel(taskWorker.appContext)
                }
                val iconDrawable = if (isFinished) {
                    if (hasError) R.drawable.outline_error_outline_24 else R.drawable.outline_download_done_24
                } else {
                    if (taskWorker.task.isDownloadTask()) R.drawable.outline_file_download_24 else R.drawable.outline_file_upload_24
                }
                val builder = Builder(
                    taskWorker.appContext, notificationChannelId
                ).setPriority(NotificationCompat.PRIORITY_LOW).setSmallIcon(iconDrawable)
                    .setShowWhen(isFinished)
                // title and body interpolation of tokens
                val progress = groupNotification.progress
                val title = replaceTokens(
                    notification.title,
                    taskWorker.task,
                    progress,
                    groupNotification = groupNotification
                )
                if (title.isNotEmpty()) {
                    builder.setContentTitle(title)
                }
                val body = replaceTokens(
                    notification.body,
                    taskWorker.task,
                    progress,
                    groupNotification = groupNotification
                )
                if (body.isNotEmpty()) {
                    builder.setContentText(body)
                }
                // progress bar
                val progressBar =
                    groupNotification.notificationConfig.progressBar && (notification == groupNotification.notificationConfig.running)
                if (progressBar && progress >= 0) {
                    if (progress <= 1) {
                        builder.setProgress(100, (progress * 100).roundToInt(), false)
                    } else { // > 1 means indeterminate
                        builder.setProgress(100, 0, true)
                    }
                }
                addGroupNotificationActions(
                    taskWorker,
                    notificationType,
                    groupNotification,
                    builder
                )
                addToNotificationQueue(
                    taskWorker,
                    notificationType,
                    builder
                ) // shows notification
            }
            if (isFinished) {
                // remove only if not re-activated within 5 seconds
                withContext(Dispatchers.Default) {
                    launch {
                        delay(5000)
                        if (groupNotification.isFinished) {
                            groupNotifications.remove(groupNotificationId)
                        }
                    }
                }
            }
        }
    }

    /**
     * Add action to notification via buttons or tap
     *
     * Which button(s) depends on the [notificationType], and the actions require
     * access to [taskWorker] and the [builder]
     */
    private fun addNotificationActions(
        taskWorker: TaskJobContext, notificationType: NotificationType, builder: Builder
    ) {
        val taskJsonString = bdJson.encodeToString<Task>(taskWorker.task)
        // add tap action for all notifications
        addTapIntent(taskWorker, taskJsonString, notificationType, builder)
        // add buttons depending on notificationType
        when (notificationType) {
            NotificationType.running -> {
                // cancel button when running
                val cancelOrPauseBundle = Bundle().apply {
                    putString(NotificationReceiver.keyTaskId, taskWorker.task.taskId)
                }
                val cancelIntent =
                    Intent(taskWorker.appContext, NotificationReceiver::class.java).apply {
                        action = NotificationReceiver.actionCancelActive
                        putExtra(NotificationReceiver.keyBundle, cancelOrPauseBundle)
                    }
                val cancelPendingIntent: PendingIntent = PendingIntent.getBroadcast(
                    taskWorker.appContext,
                    taskWorker.notificationId,
                    cancelIntent,
                    PendingIntent.FLAG_IMMUTABLE
                )
                builder.addAction(
                    R.drawable.outline_cancel_24,
                    BDPlugin.notificationButtonText["Cancel"],
                    cancelPendingIntent
                )
                if (taskWorker.taskCanResume && (taskWorker.notificationConfig?.paused != null)) {
                    // pause button when running and paused notification configured
                    val pauseIntent = Intent(
                        taskWorker.appContext, NotificationReceiver::class.java
                    ).apply {
                        action = NotificationReceiver.actionPause
                        putExtra(NotificationReceiver.keyBundle, cancelOrPauseBundle)
                    }
                    val pausePendingIntent: PendingIntent = PendingIntent.getBroadcast(
                        taskWorker.appContext,
                        taskWorker.notificationId,
                        pauseIntent,
                        PendingIntent.FLAG_IMMUTABLE
                    )
                    builder.addAction(
                        R.drawable.outline_pause_24,
                        BDPlugin.notificationButtonText["Pause"],
                        pausePendingIntent
                    )
                }
            }

            NotificationType.paused -> {
                // cancel button
                val cancelBundle = Bundle().apply {
                    putString(NotificationReceiver.keyTaskId, taskWorker.task.taskId)
                    putString(
                        NotificationReceiver.keyTask, taskJsonString
                    )
                }
                val cancelIntent = Intent(
                    taskWorker.appContext, NotificationReceiver::class.java
                ).apply {
                    action = NotificationReceiver.actionCancelInactive
                    putExtra(NotificationReceiver.keyBundle, cancelBundle)
                }
                val cancelPendingIntent: PendingIntent = PendingIntent.getBroadcast(
                    taskWorker.appContext,
                    taskWorker.notificationId,
                    cancelIntent,
                    PendingIntent.FLAG_IMMUTABLE
                )
                builder.addAction(
                    R.drawable.outline_cancel_24,
                    BDPlugin.notificationButtonText["Cancel"],
                    cancelPendingIntent
                )
                // resume button
                val resumeBundle = Bundle().apply {
                    putString(NotificationReceiver.keyTaskId, taskWorker.task.taskId)
                    putString(
                        NotificationReceiver.keyTask, taskJsonString
                    )
                    putString(
                        NotificationReceiver.keyNotificationConfig,
                        taskWorker.notificationConfigJsonString
                    )
                }
                val resumeIntent = Intent(
                    taskWorker.appContext, NotificationReceiver::class.java
                ).apply {
                    action = NotificationReceiver.actionResume
                    putExtra(NotificationReceiver.keyBundle, resumeBundle)
                }
                val resumePendingIntent: PendingIntent = PendingIntent.getBroadcast(
                    taskWorker.appContext,
                    taskWorker.notificationId,
                    resumeIntent,
                    PendingIntent.FLAG_IMMUTABLE
                )
                builder.addAction(
                    R.drawable.outline_play_arrow_24,
                    BDPlugin.notificationButtonText["Resume"],
                    resumePendingIntent
                )
            }

            NotificationType.complete -> {}
            NotificationType.error -> {}
            NotificationType.canceled -> {}
        }
    }

    /**
     * Add tap intent to the [builder] for this notification
     *
     * If [taskJsonString] is not empty, information will be added such that
     * the activity can send a "notificationTap" message to Flutter
     */
    private fun addTapIntent(
        taskWorker: TaskJobContext,
        taskJsonString: String,
        notificationType: NotificationType,
        builder: Builder
    ) {
        val tapIntent = taskWorker.appContext.packageManager.getLaunchIntentForPackage(
            taskWorker.appContext.packageName
        )
        if (tapIntent != null) {
            tapIntent.apply {
                setPackage(null)
                action = NotificationReceiver.actionTap
                addCategory(Intent.CATEGORY_LAUNCHER)
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra(NotificationReceiver.keyTask, taskJsonString)
                putExtra(
                    NotificationReceiver.keyNotificationConfig,
                    taskWorker.notificationConfigJsonString
                )
                putExtra(NotificationReceiver.keyNotificationType, notificationType.ordinal)
                putExtra(NotificationReceiver.keyNotificationId, taskWorker.notificationId)
            }
            val tapPendingIntent: PendingIntent = PendingIntent.getActivity(
                taskWorker.appContext,
                taskWorker.notificationId,
                tapIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            builder.setContentIntent(tapPendingIntent)
        }
    }

    /**
     * Add Cancel action to groupNotification notification
     */
    private fun addGroupNotificationActions(
        taskWorker: TaskJobContext,
        notificationType: NotificationType,
        groupNotification: GroupNotification,
        builder: Builder
    ) {
        // add tap action for all notifications
        addTapIntent(taskWorker, "", notificationType, builder)
        // add cancel button for running notification
        if (notificationType == NotificationType.running) {
            val cancelBundle = Bundle().apply {
                putString(NotificationReceiver.keyGroupNotificationName, groupNotification.name)
            }
            val cancelIntent =
                Intent(taskWorker.appContext, NotificationReceiver::class.java).apply {
                    action = NotificationReceiver.actionCancelActive
                    putExtra(NotificationReceiver.keyBundle, cancelBundle)
                }
            val cancelPendingIntent: PendingIntent = PendingIntent.getBroadcast(
                taskWorker.appContext,
                groupNotification.notificationId,
                cancelIntent,
                PendingIntent.FLAG_IMMUTABLE
            )
            builder.addAction(
                R.drawable.outline_cancel_24,
                BDPlugin.notificationButtonText["Cancel"],
                cancelPendingIntent
            )
        }
    }

    /**
     * Display the notification presented by the [builder], for this
     * [notificationType]
     *
     * Checks for permissions, and if necessary asks for it
     */
    @SuppressLint("MissingPermission")
    private suspend fun displayNotification(
        taskWorker: TaskJobContext, notificationType: NotificationType, builder: Builder
    ) {
        with(NotificationManagerCompat.from(taskWorker.appContext)) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                // On Android 33+, check/ask for permission
                val status = PermissionsService.getPermissionStatus(
                    taskWorker.appContext,
                    PermissionType.notifications
                )
                if (status != PermissionStatus.granted) {
                    return
                }
            }
            val androidNotification = builder.build()
            if (taskWorker.runInForeground) {
                if (notificationType == NotificationType.running && taskWorker.isActive) {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                            taskWorker.setForegroundNotification(
                                taskWorker.notificationId,
                                androidNotification,
                                FOREGROUND_SERVICE_TYPE_DATA_SYNC
                            )
                        } else {
                            taskWorker.setForegroundNotification(
                                taskWorker.notificationId, androidNotification, 0
                            )
                        }
                    } catch (e: Exception) {
                        Log.w(TAG, "Could not set foreground notification: ${e.message}")
                        taskWorker.runInForeground = false
                        notify(taskWorker.notificationId, androidNotification)
                    }
                } else {
                    // to prevent the 'not running' notification getting killed as the foreground
                    // process is terminated, this notification is shown regularly, but with
                    // a delay
                    delay(200)
                    notify(taskWorker.notificationId, androidNotification)
                }
            } else {
                notify(taskWorker.notificationId, androidNotification)
            }
        }
    }


    /**
     * Create the notification channel to use for download notifications
     */
    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = context.getString(R.string.bg_downloader_notification_channel_name)
            val descriptionText = context.getString(
                R.string.bg_downloader_notification_channel_description
            )
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(
                notificationChannelId, name, importance
            ).apply {
                description = descriptionText
            }
            // Register the channel with the system
            val notificationManager: NotificationManager = context.getSystemService(
                Context.NOTIFICATION_SERVICE
            ) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
        createdNotificationChannel = true
    }

    /**
     * Returns the notificationType related to this [status]
     */
    private fun notificationTypeForTaskStatus(status: TaskStatus): NotificationType {
        return when (status) {
            TaskStatus.enqueued, TaskStatus.running -> NotificationType.running
            TaskStatus.complete -> NotificationType.complete
            TaskStatus.paused -> NotificationType.paused
            TaskStatus.canceled -> NotificationType.canceled
            else -> NotificationType.error
        }
    }

    // RegExes for token replacement
    private val displayNameRegEx = Regex("""\{displayName\}""", RegexOption.IGNORE_CASE)
    private val fileNameRegEx = Regex("""\{filename\}""", RegexOption.IGNORE_CASE)
    private val progressRegEx = Regex("""\{progress\}""", RegexOption.IGNORE_CASE)
    private val networkSpeedRegEx = Regex("""\{networkSpeed\}""", RegexOption.IGNORE_CASE)
    private val timeRemainingRegEx = Regex("""\{timeRemaining\}""", RegexOption.IGNORE_CASE)
    private val metaDataRegEx = Regex("""\{metadata\}""", RegexOption.IGNORE_CASE)
    private val numFinishedRegEx = Regex("""\{numFinished\}""", RegexOption.IGNORE_CASE)
    private val numFailedRegEx = Regex("""\{numFailed\}""", RegexOption.IGNORE_CASE)
    private val numTotalRegEx = Regex("""\{numTotal\}""", RegexOption.IGNORE_CASE)


    /**
     * Replace special tokens {displayName}, {filename}, {metadata}, {progress}, {networkSpeed},
     * {timeRemaining}, {numFinished} and {numTotal} with their respective values.
     */
    private fun replaceTokens(
        input: String,
        task: Task,
        progress: Double,
        networkSpeed: Double = -1.0,
        timeRemaining: Long? = null,
        groupNotification: GroupNotification? = null
    ): String {
        val (unpackedFilename, _) = UriUtils.unpack(task.filename)
        val safeFilename = unpackedFilename ?: task.filename

        // filename and metadata
        val output = displayNameRegEx.replace(
            fileNameRegEx.replace(
                metaDataRegEx.replace(
                    input, escapeReplacement(task.metaData)

                ), escapeReplacement(safeFilename)
            ), escapeReplacement(task.displayName)
        )

        // progress
        val progressString =
            if (progress in 0.0..1.0) (progress * 100).roundToInt().toString() + "%"
            else ""
        val output2 = progressRegEx.replace(output, progressString)
        // download speed
        val networkSpeedString =
            if (networkSpeed <= 0.0) "-- MB/s" else if (networkSpeed > 1) "${networkSpeed.roundToInt()} MB/s" else "${(networkSpeed * 1000).roundToInt()} kB/s"
        val output3 = networkSpeedRegEx.replace(output2, networkSpeedString)
        // time remaining
        var output4 = output3
        if (timeRemaining != null) {
            val hours = timeRemaining.div(3600000L)
            val minutes = (timeRemaining.mod(3600000L)).div(60000L)
            val seconds = (timeRemaining.mod(60000L)).div(1000L)
            val timeRemainingString =
                if (timeRemaining < 0) "--:--" else if (hours > 0) String.format(
                    Locale.US,
                    "%02d:%02d:%02d", hours, minutes, seconds
                ) else String.format(
                    Locale.US,
                    "%02d:%02d", minutes, seconds
                )
            output4 = timeRemainingRegEx.replace(output3, timeRemainingString)
        }
        return if (groupNotification != null) {
            numFailedRegEx.replace(
                numFinishedRegEx.replace(
                    numTotalRegEx.replace(output4, "${groupNotification.numTotal}"),
                    "${groupNotification.numFinished}"
                ), "${groupNotification.numFailed}"
            )
        } else {
            output4
        }
    }

    /** Add display notification request to the queue, and start the
     * queue if needed
     */
    private suspend fun addToNotificationQueue(
        taskWorker: TaskJobContext,
        notificationType: NotificationType? = null,
        builder: Builder? = null
    ) {
        mutex.withLock {
            pendingNotifications.add(NotificationData(taskWorker, notificationType, builder))
        }
        queue.send(Unit)
    }

    /**
     * Process the [notificationData], i.e. send the notification
     */
    private suspend fun processNotificationData(notificationData: NotificationData) {
        if (notificationData.notificationType != null && notificationData.builder != null) {
            displayNotification(
                notificationData.taskWorker,
                notificationData.notificationType,
                notificationData.builder
            )
        } else {
            // remove the notification
            with(NotificationManagerCompat.from(notificationData.taskWorker.appContext)) {
                cancel(notificationData.taskWorker.notificationId)
            }
        }
    }

    /**
     * Return the [GroupNotification] this [taskId] belongs to, or
     * null if not part of a [GroupNotification]
     */
    fun groupNotificationWithTaskId(taskId: String): GroupNotification? {
        for (group in groupNotifications.values) {
            if (group.runningTasks.any { task -> task.taskId == taskId }) {
                return group
            }
        }
        return null
    }
}

/** Holds data required to construct a notification */
data class NotificationData(
    val taskWorker: TaskJobContext,
    val notificationType: NotificationType?,
    val builder: Builder?
)
