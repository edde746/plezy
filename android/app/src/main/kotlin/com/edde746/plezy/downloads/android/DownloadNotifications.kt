package com.edde746.plezy.downloads.android

import android.Manifest
import android.app.Notification
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.work.ForegroundInfo
import com.edde746.plezy.PlezyActivity
import com.edde746.plezy.PlezyApplication
import com.edde746.plezy.R
import com.edde746.plezy.downloads.TaskNotification
import com.edde746.plezy.strings.T
import com.edde746.plezy.strings.isolate

/**
 * The downloads' notifications on the [CHANNEL] channel, as the downloader describes each task ([TaskNotification]):
 * the running task's in the download worker's foreground notification, with its progress bar, Pause (a task that
 * allows it) and Cancel; a task that completed, failed or paused in a notification of its own; a tap opens the app.
 * Built from the task's display name only: never a URL.
 */
internal class DownloadNotifications(private val context: Context) {
    private val notifications = NotificationManagerCompat.from(context)

    /** The running task's notification; null while none runs. Main thread. */
    private var running: TaskNotification? = null

    /** Creates the channel, or renames it in the interface language now. */
    fun ensureChannel() {
        notifications.createNotificationChannel(
            NotificationChannelCompat.Builder(CHANNEL, NotificationManagerCompat.IMPORTANCE_LOW)
                .setName(T.downloads.notification.channel)
                .setShowBadge(false)
                .build(),
        )
    }

    /** What the worker's foreground service shows. Main thread. */
    fun foregroundInfo(waitingForNetwork: Boolean): ForegroundInfo =
        ForegroundInfo(ID, foreground(waitingForNetwork), ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)

    /** A task's notification changed. Main thread. */
    fun show(notification: TaskNotification) {
        val id = notification.task.taskId
        when (notification.state) {
            TaskNotification.State.RUNNING -> {
                running = notification
                post(ID, foreground(waitingForNetwork = false))
            }
            TaskNotification.State.GONE -> {
                if (running?.task?.taskId == id) running = null
                notifications.cancel(id, TASK_ID)
            }
            TaskNotification.State.COMPLETE, TaskNotification.State.ERROR, TaskNotification.State.PAUSED -> {
                if (running?.task?.taskId == id) running = null
                post(TASK_ID, ended(notification), tag = id)
            }
        }
    }

    private fun post(id: Int, notification: Notification, tag: String? = null) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        notifications.notify(tag, id, notification)
    }

    /** The worker's notification: the running task with its progress, else that the downloads prepare or wait. */
    private fun foreground(waitingForNetwork: Boolean): Notification {
        val builder = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setShowWhen(false)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setContentIntent(openApp())
        val task = running
        if (task == null) {
            builder.setContentTitle(if (waitingForNetwork) T.downloads.notification.waiting else T.downloads.notification.preparing)
            builder.setProgress(0, 0, !waitingForNetwork)
            return builder.build()
        }
        builder.setContentTitle(isolate(task.title)).setContentText(task.body)
        val progress = task.progress
        if (progress != null) builder.setProgress(PROGRESS_MAX, (progress * PROGRESS_MAX).toInt().coerceIn(0, PROGRESS_MAX), false) else builder.setProgress(0, 0, true)
        if (task.task.allowPause) builder.addAction(0, T.downloads.notification.pause, broadcast(REQUEST_PAUSE, ACTION_PAUSE, task.task.taskId))
        builder.addAction(0, T.downloads.notification.cancel, broadcast(REQUEST_CANCEL, ACTION_CANCEL, task.task.taskId))
        return builder.build()
    }

    /** A task's end, or its pause: its name and what happened. */
    private fun ended(notification: TaskNotification): Notification = NotificationCompat.Builder(context, CHANNEL)
        .setSmallIcon(R.drawable.ic_notification)
        .setContentTitle(isolate(notification.title))
        .setContentText(notification.body)
        .setSilent(true)
        .setAutoCancel(true)
        .setContentIntent(openApp())
        .build()

    /** The app as the launcher opens it: the running task comes back as it was. */
    private fun openApp(): PendingIntent {
        val intent = Intent(context, PlezyActivity::class.java)
            .setAction(Intent.ACTION_MAIN)
            .addCategory(Intent.CATEGORY_LAUNCHER)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return PendingIntent.getActivity(context, REQUEST_OPEN, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
    }

    private fun broadcast(request: Int, action: String, taskId: String): PendingIntent = PendingIntent.getBroadcast(
        context,
        request,
        Intent(action).setClass(context, DownloadActionReceiver::class.java).putExtra(EXTRA_TASK, taskId),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    companion object {
        /** The downloads' channel: the earlier releases' id, so its settings (and diagnostics reading them) carry over. */
        const val CHANNEL = "background_downloader"
        private const val ID = 0x7D01
        private const val TASK_ID = 0x7D02
        private const val PROGRESS_MAX = 100
        private const val REQUEST_OPEN = 0
        private const val REQUEST_PAUSE = 1
        private const val REQUEST_CANCEL = 2

        const val ACTION_PAUSE = "com.edde746.plezy.downloads.PAUSE"
        const val ACTION_CANCEL = "com.edde746.plezy.downloads.CANCEL"
        const val EXTRA_TASK = "task"
    }
}

/** The notification's actions, in this process (not exported): Pause and Cancel of the task it showed. */
internal class DownloadActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val downloads = (context.applicationContext as PlezyApplication).downloads
        val taskId = intent.getStringExtra(DownloadNotifications.EXTRA_TASK) ?: return
        when (intent.action) {
            DownloadNotifications.ACTION_PAUSE -> downloads.pause(taskId)
            DownloadNotifications.ACTION_CANCEL -> downloads.cancel(taskId)
        }
    }
}
