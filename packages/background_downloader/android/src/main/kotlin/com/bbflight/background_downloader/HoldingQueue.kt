package com.bbflight.background_downloader

import android.content.Context
import android.util.Log
import androidx.preference.PreferenceManager
import androidx.work.WorkManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.util.Date
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.PriorityBlockingQueue
import java.util.concurrent.atomic.AtomicInteger
import android.app.job.JobScheduler
import android.os.Build
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * Queue that holds [EnqueueItem] items before they are actually enqueued as a WorkManager job
 *
 * Configure [maxConcurrent], [maxConcurrentByHost] and [maxConcurrentByGroup] to limit which items
 * can be enqueued simultaneously.
 *
 * Call:
 * [add] to add an [EnqueueItem]
 * [taskFinished] for all tasks that finish, so we may start a new one
 * [cancelAllTasks] to empty the queue (sends status updates)
 * [cancelTasksWithIds] to remove specific tasks (sends status updates)
 * [allTasks] for a list of [Task] matching a group
 * [taskForId] to get the task for a specific taskId
 */
class HoldingQueue(private val context: Context, private val workManager: WorkManager) {

    var maxConcurrent: Int = 1 shl 20
    var maxConcurrentByHost: Int = 1 shl 20
    var maxConcurrentByGroup: Int = 1 shl 20
    val hostByTaskId = ConcurrentHashMap<String, String>()
    // concurrent set: mutated under [stateMutex] but also read from other threads
    val enqueuedTaskIds: MutableSet<String> = ConcurrentHashMap.newKeySet()

    private val concurrent = AtomicInteger(0)
    private val concurrentByHost = ConcurrentHashMap<String, AtomicInteger>()
    private val concurrentByGroup = ConcurrentHashMap<String, AtomicInteger>()

    // taskIds currently counted in [concurrent]/[concurrentByHost]/[concurrentByGroup],
    // populated on queue promotion and by [calculateState]. Guards [executeTaskFinished]
    // against decrementing for a task that was never counted (or was already finished
    // once), which would drift [concurrent] negative and permanently raise the
    // effective concurrency
    private val activeTaskIds: MutableSet<String> = ConcurrentHashMap.newKeySet()

    private val queue = PriorityBlockingQueue<EnqueueItem>()
    private val taskFinishedQueue = Channel<Task>(capacity = Channel.UNLIMITED)


    private var job: Job? = null // timer job
    private val scope = CoroutineScope(Dispatchers.Default)
    private val processSignal = Channel<Unit>(Channel.UNLIMITED)
    val stateMutex = Mutex()

    init {
        // coroutine to process the queue
        scope.launch {
            for (signal in processSignal) {  // signal comes from [advanceQueue]
                stateMutex.withLock {
                    val mustWait = ArrayList<EnqueueItem>()
                    while (concurrent.get() < maxConcurrent && queue.isNotEmpty()) {
                        val item = queue.poll() ?: break
                        val host = item.task.host()
                        val group = item.task.group
                        if ((concurrentByHost[host]?.get()
                                ?: 0) < maxConcurrentByHost && (concurrentByGroup[group]?.get()
                                ?: 0) < maxConcurrentByGroup
                        ) {
                            // enqueue this item after incrementing counters
                            concurrent.incrementAndGet()
                            concurrentByHost.computeIfAbsent(host) { AtomicInteger(0) }.incrementAndGet()
                            concurrentByGroup.computeIfAbsent(group) { AtomicInteger(0) }.incrementAndGet()
                            activeTaskIds.add(item.task.taskId)
                            item.enqueue(afterDelayMillis = 0)
                        } else {
                            // this item has to wait
                            mustWait.add(item)
                        }
                    }
                    // add mustWait items back to the queue
                    queue.addAll(mustWait)
                }
            }
        }

        // coroutine to process 'taskFinished' messages
        scope.launch {
            for (task in taskFinishedQueue) {
                executeTaskFinished(task)
            }
        }

        // initial state calculation
        scope.launch {
            calculateState()
        }
    }

    /**
     * Add [EnqueueItem] [item] to the queue and advance the queue if possible
     *
     * Returns true if the item was accepted, false if it was dropped as a
     * duplicate of an already queued or active task. Items carrying resume data
     * are continuations of an existing task, so they are never dropped: the
     * WorkManager layer enqueues them with APPEND_OR_REPLACE
     */
    suspend fun add(item: EnqueueItem): Boolean {
        var shouldAdvance = false
        var accepted = true
        stateMutex.withLock {
            val taskId = item.task.taskId
            val queuedDuplicates = queue.filter { it.task.taskId == taskId }
            when {
                queuedDuplicates.isNotEmpty() -> {
                    queuedDuplicates.forEach { queue.remove(it) }
                    queue.add(item)
                    if (!enqueuedTaskIds.contains(taskId)) {
                        enqueuedTaskIds.add(taskId)
                        NotificationService.registerEnqueue(item, success = true)
                    }
                    Log.i(BDPlugin.TAG, "Replaced queued duplicate task with id $taskId")
                    shouldAdvance = true
                }
                item.resumeData == null &&
                        (enqueuedTaskIds.contains(taskId) || isTaskIdActive(taskId)) -> {
                    Log.i(BDPlugin.TAG, "Ignoring duplicate active task with id $taskId")
                    accepted = false
                }
                else -> {
                    queue.add(item)
                    if (!enqueuedTaskIds.contains(taskId)) {
                        enqueuedTaskIds.add(taskId)
                        NotificationService.registerEnqueue(
                            item,
                            success = true
                        ) // for group notification count
                    }
                    shouldAdvance = true
                }
            }
        }
        if (shouldAdvance) advanceQueue()
        return accepted
    }

    private suspend fun isTaskIdActive(taskId: String): Boolean {
        try {
            val workInfos = withContext(Dispatchers.IO) {
                workManager.getWorkInfosByTag("taskId=$taskId").get()
            }
            if (workInfos.any { !it.state.isFinished }) return true

            if (Build.VERSION.SDK_INT >= 34) {
                val jobScheduler = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler
                val jobInfo = jobScheduler.getPendingJob(taskId.hashCode()) ?: return false
                val taskJson = jobInfo.extras.getString(TaskWorker.keyTask) ?: return false
                return try {
                    Json.decodeFromString<Task>(taskJson).taskId == taskId
                } catch (_: Exception) {
                    false
                }
            }

            return false
        } catch (e: Exception) {
            Log.w(BDPlugin.TAG, "Could not check active state for taskId $taskId: $e")
            return false
        }
    }

    /**
     * Signals to the holdingQueue that a [task] has finished
     *
     * The processing is done async, so this method only adds
     * the task to the processing queue
     */
    suspend fun taskFinished(task: Task) {
        taskFinishedQueue.send(task)
    }

    /**
     * Removes all [EnqueueItem] where their taskId is in [taskIds], sends a
     * [TaskStatus.canceled] update and returns a list of
     * taskIds that were cancelled this way
     *
     * Because this is used in combination with the WorkManager tasks, use of this method
     * requires the caller to acquire the [stateMutex]
     */
    suspend fun cancelTasksWithIds(context: Context, taskIds: Iterable<String>): List<String> {
        val removedTaskIds: List<String>
        val toRemove = queue.filter { taskIds.contains(it.task.taskId) }
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        toRemove.forEach {
            queue.remove(it)
            enqueuedTaskIds.remove(it.task.taskId)
            TaskWorker.processStatusUpdate(it.task, TaskStatus.canceled, prefs, context = context)
            if (it.notificationConfigJsonString != null) {
                NotificationService.createUpdateNotificationWorker(
                    context,
                    bdJson.encodeToString(it.task),
                    it.notificationConfigJsonString,
                    TaskStatus.canceled.ordinal
                )
            }
            Log.i(BDPlugin.TAG, "Canceled task with id ${it.task.taskId}")
        }
        removedTaskIds = toRemove.map { it.task.taskId }.toMutableList()
        enqueuedTaskIds.removeAll(removedTaskIds.toSet())
        removedTaskIds.forEach { hostByTaskId.remove(it) }
        return removedTaskIds
    }

    /**
     * Cancel (delete) all [EnqueueItem] matching [group], send a
     * [TaskStatus.canceled] for each and return the number of items cancelled
     *
     * Because this is used in combination with the WorkManager tasks, use of this method
     * requires the caller to acquire the [stateMutex]
     */
    suspend fun cancelAllTasks(context: Context, group: String): Int {
        val taskIds =
            queue.filter { it.task.group == group }.map { it.task.taskId }.toMutableList()
        cancelTasksWithIds(context, taskIds)
        return taskIds.size
    }

    /**
     * Return task matching [taskId], or null
     *
     * Because this is used in combination with the WorkManager tasks, use of this method
     * requires the caller to acquire the [stateMutex]
     */
    fun taskForId(taskId: String): Task? {
        val tasks = queue.filter { it.task.taskId == taskId }.map { it.task }
        if (tasks.isNotEmpty()) {
            return tasks.first()
        }
        return null
    }

    /**
     * Return list of [Task] for this [group]. If [group] is null, all tasks will be returned
     *
     * Because this is used in combination with the WorkManager tasks, use of this method
     * requires the caller to acquire the [stateMutex]
     */
    fun allTasks(group: String?): List<Task> {
        return queue.filter { group == null || it.task.group == group }.map { it.task }
    }

    /**
     * Advance the queue by signalling the queue processing coroutine
     *
     * Also restarts a timer that will advance the queue in 10 seconds, in case
     * it dries up
     */
    private fun advanceQueue() {
        processSignal.trySend(Unit)
        if (queue.isNotEmpty()) {
            advanceQueueInFuture()
        }
    }

    /**
     * Calls [advanceQueue] in 10 seconds, thus ensuring it never dries up
     *
     * If called again before the timer fires, cancels the original timer and
     * resets to 10 seconds
     */
    private fun advanceQueueInFuture() {
        job?.cancel()
        job = scope.launch {
            delay(10000)
            // recalculate state from the OS view (iOS does the same); heals any
            // residual counter drift while the queue is active
            calculateState()
            advanceQueue()
        }
    }

    /**
     * Signals to the holdingQueue that a [task] has finished
     *
     * Adjusts the state variables and advances the queue
     */
    private suspend fun executeTaskFinished(task: Task) {
        hostByTaskId.remove(task.taskId)
        val host = task.host()
        val group = task.group
        stateMutex.withLock {
            // under the mutex because [add] reads/writes this list under the same lock
            enqueuedTaskIds.remove(task.taskId)
            // Only adjust counters for a task this queue actually counted: finish
            // reports also arrive for tasks that never went through promotion (e.g.
            // enqueued before the queue was configured) and could arrive twice for
            // one promotion (pause of a run that re-enqueued itself). Unconditional
            // decrements drift [concurrent] negative and break maxConcurrent
            if (activeTaskIds.remove(task.taskId)) {
                concurrent.decrementAndGet()
                concurrentByHost[host]?.decrementAndGet()
                concurrentByGroup[group]?.decrementAndGet()
            }
        }
        advanceQueue()
    }

    /**
     * Calculates the [concurrent], [concurrentByHost] and [concurrentByGroup] values
     * and rebuilds [activeTaskIds] from the observed jobs
     *
     * This is expensive, so is only done when the queue is created and when the
     * [advanceQueueInFuture] timer fires
     */
    private suspend fun calculateState() {
        stateMutex.withLock {
            val workInfos = workManager.getWorkInfosByTag(BDPlugin.TAG).get()
                .filter { !it.state.isFinished }
            var totalCount = workInfos.size
            concurrentByHost.clear()
            concurrentByGroup.clear()
            activeTaskIds.clear()
            for (workInfo in workInfos) {
                // update concurrentByHost
                try {
                    val taskIdTag = workInfo.tags.first { it.startsWith("taskId=") }
                    val taskId = taskIdTag.substring(startIndex = 7)
                    activeTaskIds.add(taskId)
                    val host = hostByTaskId[taskId] ?: ""
                    if (!concurrentByHost.containsKey(host)) {
                        concurrentByHost[host] = AtomicInteger(0)
                    }
                    concurrentByHost[host]?.incrementAndGet()
                } catch (_: NoSuchElementException) {
                }
                // update concurrentByGroup
                try {
                    val groupTag = workInfo.tags.first { it.startsWith("group=") }
                    val group = groupTag.substring(startIndex = 6)
                    if (!concurrentByGroup.containsKey(group)) {
                        concurrentByGroup[group] = AtomicInteger(0)
                    }
                    concurrentByGroup[group]?.incrementAndGet()
                } catch (_: NoSuchElementException) {
                }
            }
            // JobScheduler (UIDT)
            if (Build.VERSION.SDK_INT >= 34) {
                 val jobScheduler = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler
                 val jobs = jobScheduler.allPendingJobs
                 for (job in jobs) {
                      if (job.service.className == UIDTJobService::class.java.name) {
                          val taskJson = job.extras.getString(TaskWorker.keyTask)
                          if (taskJson != null) {
                              try {
                                  val task = bdJson.decodeFromString<Task>(taskJson)
                                  totalCount++
                                  activeTaskIds.add(task.taskId)
                                  
                                  val host = task.host()
                                  val group = task.group

                                  if (!concurrentByHost.containsKey(host)) {
                                      concurrentByHost[host] = AtomicInteger(0)
                                  }
                                  concurrentByHost[host]?.incrementAndGet()

                                  if (!concurrentByGroup.containsKey(group)) {
                                      concurrentByGroup[group] = AtomicInteger(0)
                                  }
                                  concurrentByGroup[group]?.incrementAndGet()
                              } catch (e: Exception) {
                                  Log.w(BDPlugin.TAG, "Could not decode task from job info: $e")
                              }
                          }
                      }
                 }
            }
            concurrent.set(totalCount)
        }
    }
}


/**
 * Holds data related to enqueueing a task
 *
 * Used in the context of changing the RequireWiFi setting (where tasks need to be re-enqueued)
 * and in the context of the [HoldingQueue]
 */
class EnqueueItem(
    val context: Context,
    val task: Task,
    val notificationConfigJsonString: String?,
    val resumeData: ResumeData? = null,
    private val plugin: BDPlugin? = null,
    private val created: Date = Date()
) : Comparable<EnqueueItem> {

    /** Execute the re-enqueue after an appropriate delay */
    suspend fun enqueue(afterDelayMillis: Int = 1000) {
        val timeSinceCreatedMillis = Date().time - created.time
        if (timeSinceCreatedMillis < afterDelayMillis) {
            delay(afterDelayMillis - timeSinceCreatedMillis)
        }
        if (!BDPlugin.doEnqueue(
                context = context,
                task = task,
                notificationConfigJsonString = notificationConfigJsonString,
                resumeData = resumeData,
                plugin = plugin
            )
        ) {
            Log.w(BDPlugin.TAG, "Delayed or retried enqueue failed for taskId ${task.taskId}")
            TaskWorker.processStatusUpdate(
                task, TaskStatus.failed, PreferenceManager.getDefaultSharedPreferences(context),
                taskException = TaskException(
                    type = ExceptionType.general,
                    description = "Delayed or retried enqueue failed"
                ), context = context
            )
            BDPlugin.holdingQueue?.taskFinished(task)
            NotificationService.registerEnqueue(this, success = false)
        }
        delay(20)
    }

    /**
     * Items are sorted based on task priority first, then by task creation time
     */
    override fun compareTo(other: EnqueueItem) = compareValuesBy(this, other,
        { it.task.priority },
        { it.task.creationTime })
}
