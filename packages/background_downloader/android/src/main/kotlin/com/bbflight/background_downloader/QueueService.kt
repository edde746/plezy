package com.bbflight.background_downloader

import android.util.Log
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Queue service that executes things on a queue, to ensure ordered execution
 * and potentially manage delay
 */
@Suppress("ConstPropertyName")
object QueueService {
    private val scope = CoroutineScope(Dispatchers.Default)

    private val taskIdDeletionQueue = Channel<String>(capacity = Channel.UNLIMITED)
    private var lastTaskIdAdditionTime: Long = 0
    private const val minTaskIdDeletionDelay: Long = 2000L //ms

    private val backgroundPostQueue = Channel<BackgroundPost>(capacity = Channel.UNLIMITED)


    /**
     * Starts listening to the queues and processes each item
     *
     * taskIdDeletionQueue:
     *    Each item is a taskId and it will be removed from the BDPlugin.pluginByTaskId,
     *    BDPlugin.bgChannelByTaskId, BDPlugin.localResumeData
     *    and BDPlugin.notificationConfigs maps
     *
     * backgroundPostQueue:
     *    Each item is a [BackgroundPost] that will be posted on the UI thread, and its
     *    success completer will complete with true if successfully posted
     */
    init {
        scope.launch {
            for (taskId in taskIdDeletionQueue) {
                val now = System.currentTimeMillis()
                val elapsed = now - lastTaskIdAdditionTime
                if (elapsed < minTaskIdDeletionDelay) {
                    delay(minTaskIdDeletionDelay - elapsed)
                }
                BDPlugin.flutterEngineByTaskId.remove(taskId)
                BDPlugin.bgChannelByTaskId.remove(taskId)
                BDPlugin.localResumeData.remove(taskId)
                BDPlugin.notificationConfigJsonStrings.remove(taskId)
            }
        }
        scope.launch {
            for (bgPost in backgroundPostQueue) {
                val success = CompletableDeferred<Boolean>()
                launch(Dispatchers.Main) {
                    try {
                        val argList = mutableListOf<Any>(
                            TaskWorker.taskToJsonString(bgPost.task)
                        )
                        if (bgPost.arg is ArrayList<*>) {
                            argList.addAll(bgPost.arg)
                        } else {
                            argList.add(bgPost.arg)
                        }
                        val bgChannel = BDPlugin.backgroundChannel(taskId = bgPost.task.taskId)
                        if (bgChannel != null) {
                            bgChannel.invokeMethod(
                                bgPost.method, argList, FlutterBooleanResultHandler(success)
                            )
                        } else {
                            Log.i(
                                TaskRunner.TAG,
                                "Could not post ${bgPost.method} to background channel"
                            )
                            success.complete(false)
                        }
                    } catch (e: Exception) {
                        Log.w(
                            TaskRunner.TAG,
                            "Exception trying to post ${bgPost.method} to background channel: ${e.message}"
                        )
                        if (!success.isCompleted) {
                            success.complete(false)
                        }
                    }
                    val onFail = bgPost.onFail
                    if (onFail != null && (BDPlugin.forceFailPostOnBackgroundChannel || !success.await())) {
                        onFail.invoke()
                    }
                }
            }
        }
    }


    /**
     * Remove this [taskId] from the [BDPlugin.bgChannelByTaskId] map and the
     * [BDPlugin.localResumeData] map
     */
    suspend fun cleanupTaskId(taskId: String) {
        lastTaskIdAdditionTime = System.currentTimeMillis()
        taskIdDeletionQueue.send(taskId)
    }

    /**
     * Post this [BackgroundPost] on the background channel
     */
    suspend fun postOnBackgroundChannel(bgPost: BackgroundPost) {
        backgroundPostQueue.send(bgPost)
    }
}

/**
 * BackgroundPost to be sent via backgroundChannel to Flutter, used in [QueueService]
 */
data class BackgroundPost(
    val task: Task,
    val method: String,
    val arg: Any,
    val onFail: (suspend () -> Unit)? = null
)
