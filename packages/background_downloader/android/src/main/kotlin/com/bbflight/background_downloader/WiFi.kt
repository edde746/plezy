package com.bbflight.background_downloader

import android.content.Context
import android.util.Log
import androidx.preference.PreferenceManager
import androidx.work.WorkInfo
import androidx.work.WorkManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex

/**
 * Processes WiFi requirement changes
 *
 * requireWiFiQueue:
 *    Each item is a [RequireWiFiChange] data object, and each workInfo
 *    will be either rescheduled (if enqueued) or paused and resumed (if running and
 *    possible) or cancelled and re-enqueued (if running and pause not possible
 *
 * reEnqueueQueue:
 *    Each item is a [ReEnqueue] data object represent one task re-enqueue. The task
 *    will be re-enqueued with an appropriate delay
 */
object WiFi {
    private val scope = CoroutineScope(Dispatchers.Default)

    private val requireWiFiQueue =
        Channel<RequireWiFiChange>(capacity = Channel.UNLIMITED)
    private val reEnqueueQueue = Channel<EnqueueItem?>(capacity = Channel.UNLIMITED)
    private val requireWiFiLock = Mutex()

    init {
        scope.launch {
            for (change in requireWiFiQueue) {
                requireWiFiLock.lock()
                try {
                    val haveReEnqueued = change.execute()
                    if (!haveReEnqueued && requireWiFiLock.isLocked) {
                        // no re-enqueues, so unblock the requireWiFiQueue immediately
                        requireWiFiLock.unlock()
                    } else if (haveReEnqueued) {
                        // Launch a watchdog timeout so requireWiFiLock is never permanently stuck
                        scope.launch {
                            delay(15000)
                            if (requireWiFiLock.isLocked) {
                                Log.w(BDPlugin.TAG, "WiFi re-enqueue watchdog timeout; unlocking requireWiFiLock")
                                BDPlugin.tasksToReEnqueue.clear()
                                try {
                                    requireWiFiLock.unlock()
                                } catch (_: IllegalStateException) {}
                            }
                        }
                    }
                } catch (e: Exception) {
                    Log.e(BDPlugin.TAG, "Exception during requireWiFiChange execution: $e")
                    if (requireWiFiLock.isLocked) {
                        try {
                            requireWiFiLock.unlock()
                        } catch (_: IllegalStateException) {}
                    }
                }
            }
        }

        scope.launch {
            for (reEnqueue in reEnqueueQueue) {
                try {
                    reEnqueue?.enqueue()
                } catch (e: Exception) {
                    Log.e(BDPlugin.TAG, "Exception during WiFi reEnqueue: $e")
                } finally {
                    if (reEnqueue == null && requireWiFiLock.isLocked) {
                        // null signals all reEnqueue items are enqueued
                        try {
                            requireWiFiLock.unlock()
                        } catch (_: IllegalStateException) {}
                    }
                }
            }
        }
    }

    /**
     * Execute the requireWiFi change request
     */
    suspend fun requireWiFiChange(change: RequireWiFiChange) {
        requireWiFiQueue.send(change)
    }

    /**
     * Re-enqueue this task and associated data. Null signals end of batch
     */
    suspend fun reEnqueue(enqueueItem: EnqueueItem?) {
        reEnqueueQueue.send(enqueueItem)
    }
}

/**
 * Change the global WiFi requirement setting
 */
class RequireWiFiChange(
    private val applicationContext: Context,
    private val requireWifi: RequireWiFi,
    private val rescheduleRunningTasks: Boolean,
    private val alsoRestartUploads: Boolean
) {
    /**
     * Execute the change in WiFi requirement and return
     * true if one or more tasks have been scheduled for re-enqueue
     */
    suspend fun execute(): Boolean {
        BDPlugin.requireWifi = requireWifi
        val prefs = PreferenceManager.getDefaultSharedPreferences(applicationContext)
        prefs.edit().apply {
            putInt(BDPlugin.keyRequireWiFi, requireWifi.ordinal)
            apply()
        }
        val tasksMap = getTaskMap(prefs)
        val workManager = WorkManager.getInstance(applicationContext)
        val workInfos = workManager.getWorkInfosByTag(BDPlugin.TAG).get()
            .filter { !it.state.isFinished }
        var haveReEnqueued = false
        for (workInfo in workInfos) {
            val tags = workInfo.tags.filter { it.contains("taskId=") }
            if (tags.isNotEmpty()) {
                val taskId = tags.first().substring(7)
                val task = tasksMap[taskId]
                if (task != null && (task.isDownloadTask() || task.isUploadTask())) {
                    if (BDPlugin.taskRequiresWifi(task) != BDPlugin.taskIdsRequiringWiFi.contains(
                            task.taskId
                        )
                    ) {
                        when (BDPlugin.taskRequiresWifi(task)) {
                            false -> BDPlugin.taskIdsRequiringWiFi.remove(task.taskId)
                            true -> BDPlugin.taskIdsRequiringWiFi.add(task.taskId)
                        }
                        when (workInfo.state) {
                            WorkInfo.State.ENQUEUED -> {
                                haveReEnqueued = true
                                BDPlugin.tasksToReEnqueue.add(task)
                                if (!BDPlugin.cancelActiveTaskWithId(
                                        applicationContext,
                                        task.taskId,
                                        workManager
                                    )
                                ) {
                                    BDPlugin.tasksToReEnqueue.remove(task)
                                }
                            }

                            WorkInfo.State.RUNNING -> {
                                if (rescheduleRunningTasks && task.isDownloadTask()) {
                                    haveReEnqueued = true
                                    BDPlugin.tasksToReEnqueue.add(task)
                                    BDPlugin.pauseTaskWithId(task.taskId)
                                } else if (alsoRestartUploads && task.isUploadTask()) {
                                    haveReEnqueued = true
                                    BDPlugin.tasksToReEnqueue.add(task)
                                    if (!BDPlugin.cancelActiveTaskWithId(
                                            applicationContext,
                                            task.taskId,
                                            workManager
                                        )
                                    ) {
                                        BDPlugin.tasksToReEnqueue.remove(task)
                                    }
                                }
                            }

                            else -> {}
                        }
                    }
                }
            }
        }
        return haveReEnqueued
    }
}