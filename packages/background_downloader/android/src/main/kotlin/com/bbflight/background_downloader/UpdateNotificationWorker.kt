package com.bbflight.background_downloader

import android.content.Context
import androidx.core.app.NotificationManagerCompat
import androidx.work.WorkerParameters
import kotlinx.serialization.json.Json

/**
 * Worker that updates the notification for a task, given a
 * NotificationConfig and a TaskStatus.
 *
 * Used to update a task notification initiated from the Dart side, when
 * no actual TaskWorker is active for the task, e.g. when failing for the
 * last time on retry.  We need a [TaskWorker] in order to call the
 * [NotificationService] to update the associated notification.
 *
 * Note this implementation is only valid for two situations:
 * - taskStatus is null -> deletes the notification
 * - taskStatus is TaskStatus.failed -> displays error notification if needed
 */
class UpdateNotificationWorker(applicationContext: Context, workerParams: WorkerParameters) :
    TaskWorker(applicationContext, workerParams) {

    companion object {
        const val keyTaskStatusOrdinal = "taskStatusOrdinal"
    }

    override suspend fun doWork(): Result {
        task = bdJson.decodeFromString(inputData.getString(keyTask)!!)
        notificationConfigJsonString = inputData.getString(keyNotificationConfig)
        notificationConfig =
            if (notificationConfigJsonString != null) bdJson.decodeFromString(notificationConfigJsonString!!) else null
        val taskStatusOrdinal = inputData.getInt(keyTaskStatusOrdinal, -1)
        notificationId = task.taskId.hashCode()
        if (taskStatusOrdinal == -1) {
            // delete notification
            with(NotificationManagerCompat.from(applicationContext)) {
                cancel(notificationId)
            }
        } else {
            // update notification for this taskStatus
            val taskStatus = TaskStatus.entries[taskStatusOrdinal]
            NotificationService.updateNotification(this, taskStatus)
        }
        return Result.success()
    }
}
