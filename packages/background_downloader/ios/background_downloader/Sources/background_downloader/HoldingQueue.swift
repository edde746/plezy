//
//  HoldingQueue.swift
//  background_downloader
//
//  Created by Bram on 3/16/24.
//

import Foundation
import os.log

/**
 * Queue that holds [EnqueueItem] items before they are actually enqueued as a URLSessionTask
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
class HoldingQueue {
    var maxConcurrent: Int = 1000000
    var maxConcurrentByHost: Int = 1000000
    var maxConcurrentByGroup: Int = 1000000
    var enqueuedTaskIds = [String]()
    
    private var concurrent = 0
    private var concurrentByHost = [String: Int]()
    private var concurrentByGroup = [String: Int]()

    // taskIds currently counted in concurrent/concurrentByHost/concurrentByGroup,
    // populated on queue promotion and by calculateState. Guards taskFinished
    // against decrementing for a task that was never counted (or was already
    // finished once), which would drift concurrent negative and raise the
    // effective concurrency
    private var activeTaskIds = Set<String>()
    
    private var queue = [EnqueueItem]()  // Using an array as a substitute for a priority queue
    
    let stateLock = AsyncLock()
    private var job: DispatchWorkItem? = nil // for advanceQueue in future
    
    /**
     * Add [EnqueueItem] [item] to the queue and advance the queue if possible
     */
    func add(item: EnqueueItem) async {
        await stateLock.lock()
        queue.append(item)
        queue.sort()
        enqueuedTaskIds.append(item.task.taskId)
        await registerEnqueue(task: item.task,
                              notificationConfigJsonString: item.notificationConfigJsonString,
                              success: true) // for accurate groupnotification count
        advanceQueue()
        await stateLock.unlock()
    }
    
    /**
     * Signals to the holdingQueue that a [task] has finished
     *
     * Adjusts the state variables and advances the queue
     *
     * To prevent deadlock when called when the lock is already obtained, set [reEntry]
     */
    func taskFinished(_ task: Task, reEntry: Bool = false) async {
        if !reEntry {
            await stateLock.lock()
        }
        let host = getHost(task)
        // Only adjust counters for a task this queue actually counted: finish
        // reports also arrive for tasks that never went through promotion and
        // could arrive twice for one promotion
        if activeTaskIds.remove(task.taskId) != nil {
            concurrent -= 1
            concurrentByHost[host]? -= 1
            concurrentByGroup[task.group]? -= 1
        }
        if let index = enqueuedTaskIds.firstIndex(of: task.taskId) {
            enqueuedTaskIds.remove(at: index)
        }
        advanceQueue()
        if (!reEntry) {
            await stateLock.unlock()
        }
    }
    
    /**
     * Removes all [EnqueueItem] where their taskId is in [taskIds], sends a
     * [TaskStatus.canceled] update and returns a list of
     * taskIds that were cancelled this way.
     *
     * Because this is used in combination with the UrlSessions tasks, use of this method
     * requires the caller to acquire the [stateLock]
     */
    func cancelTasksWithIds(_ taskIds: [String]) -> [String] {
        let toRemove = queue.filter( { taskIds.contains($0.task.taskId) } )
        toRemove.forEach { item in
            processStatusUpdate(task: item.task, status: .canceled)
            if let configString = item.notificationConfigJsonString,
               let config = notificationConfigFrom(jsonString: configString) {
                _Concurrency.Task {
                    await updateGroupNotification(task: item.task, notificationType: .canceled, notificationConfig: config)
                }
            }
            os_log("Canceled task with id %@", log: log, type: .info, item.task.taskId)
        }
        queue.removeAll(where: { taskIds.contains($0.task.taskId)})
        enqueuedTaskIds.removeAll(where: { taskIds.contains($0) })
        return toRemove.map { $0.task.taskId }
    }
    
    /**
     * Cancel (delete) all [EnqueueItem] matching [group], send a
     * [TaskStatus.canceled] for each and return the number of items cancelled
     *
     * Because this is used in combination with the UrlSessions tasks, use of this method
     * requires the caller to acquire the [stateLock]
     */
    func cancelAllTasks(group: String) -> Int {
        let taskIds = queue.filter({ $0.task.group == group }).map { $0.task.taskId }
        return cancelTasksWithIds(taskIds).count
    }
    
    /**
     * Return task matching [taskId], or null
     *
     * Because this is used in combination with the UrlSessions tasks, use of this method
     * requires the caller to acquire the [stateLock]
     */
    func taskForId(_ taskId: String) -> Task? {
        let tasks = queue.filter( { $0.task.taskId == taskId } ).map { $0.task }
        if !tasks.isEmpty {
            return tasks.first
        }
        return nil
    }
    
    /**
     * Return list of [Task] for this [group]. If [group] is nil al tasks are returned
     *
     * Because this is used in combination with the UrlSessions tasks, use of this method
     * requires the caller to acquire the [stateLock]
     */
    func allTasks(group: String?) -> [Task] {
        return queue.filter( { group == nil || $0.task.group == group } ).map { $0.task }
    }
    
    /**
     * Advance the queue by signalling the queue processing coroutine
     *
     * Also restarts a timer that will advance the queue in 10 seconds, in case
     * it dries up
     */
    private func advanceQueue() {
        DispatchQueue.global().async {
            _Concurrency.Task {
                await self.processQueue()
            }
        }
        advanceQueueInFuture()
    }
    
    private func advanceQueueInFuture() {
        job?.cancel()
        job = DispatchWorkItem {
            _Concurrency.Task {
                await self.calculateState()
                self.advanceQueue()
            }
        }
        guard let job = job else { return }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 10, execute: job)
        
    }
    
    /// Processes items in the queue, if possible
    private func processQueue() async {
        await stateLock.lock()
        var itemsToEnqueue = [EnqueueItem]()
        while concurrent < maxConcurrent && !queue.isEmpty {
            var mustWait = [EnqueueItem]()
            var foundItem: EnqueueItem? = nil
            while !queue.isEmpty {
                let item = queue.removeFirst()
                let host = getHost(item.task)
                if (concurrentByHost[host] ?? 0) < maxConcurrentByHost &&
                    (concurrentByGroup[item.task.group] ?? 0) < maxConcurrentByGroup {
                    concurrent += 1
                    concurrentByHost[host, default: 0] += 1
                    concurrentByGroup[item.task.group, default: 0] += 1
                    activeTaskIds.insert(item.task.taskId)
                    foundItem = item
                    break
                } else {
                    mustWait.append(item)
                }
            }
            queue.append(contentsOf: mustWait)
            queue.sort()
            if let item = foundItem {
                itemsToEnqueue.append(item)
            } else {
                break
            }
        }
        await stateLock.unlock()
        
        // Enqueue items outside the stateLock to avoid blocking during network HEAD requests
        for item in itemsToEnqueue {
            await item.enqueue()
        }
    }
    
    /**
     * Calculates the [concurrent], [concurrentByHost] and [concurrentByGroup] values
     *
     * This is expensive, so is only done initially and when the [advanceQueueInFuture] timer
     * fires
     */
    private func calculateState() async {
        await stateLock.lock()
        UrlSessionDelegate.createUrlSession()
        guard let urlSessionTasks = await UrlSessionDelegate.urlSession?.allTasks else {
            await stateLock.unlock()
            return
        }
        let tasks: [Task] = urlSessionTasks.filter({ $0.state != .completed }).compactMap({ getTaskFrom(urlSessionTask: $0)})
        concurrent = tasks.count
        concurrentByHost.removeAll()
        concurrentByGroup.removeAll()
        activeTaskIds = Set(tasks.map { $0.taskId })
        for task in tasks {
            let host = getHost(task)
            concurrentByHost[host, default: 0] += 1
            concurrentByGroup[task.group, default: 0] += 1
        }
        await stateLock.unlock()
    }
}



/**
 * Holds data related to enqueueing a task
 *
 * Used in the context of changing the RequireWiFi setting (where tasks need to be re-enqueued)
 * and in the context of the [HoldingQueue]
 */
struct EnqueueItem : Comparable {
    let task: Task
    let notificationConfigJsonString: String?
    let resumeDataAsBase64String: String
    let created = Date()
    
    // Comparable implementation to sort based on task priority and creation time
    static func < (lhs: EnqueueItem, rhs: EnqueueItem) -> Bool {
        return lhs.task.priority == rhs.task.priority ? lhs.task.creationTime < rhs.task.creationTime : lhs.task.priority < rhs.task.priority
    }
    
    static func == (lhs: EnqueueItem, rhs: EnqueueItem) -> Bool {
        return lhs.task.priority == rhs.task.priority && lhs.task.creationTime == rhs.task.creationTime
    }
    
    func enqueue() async {
        let success = await BDPlugin.instance.doEnqueue(taskJsonString: jsonStringFor(task: task) ?? "", notificationConfigJsonString: notificationConfigJsonString, resumeDataAsBase64String: resumeDataAsBase64String)
        if !success {
            os_log("Delayed or retried enqueue failed for taskId %@", log: log, type: .info, task.taskId)
            processStatusUpdate(task: task, status: .failed, taskException: TaskException(type: .general, description: "Delayed or retried enqueue failed"))
            await BDPlugin.holdingQueue?.taskFinished(task, reEntry: true)
            // register the failure with the notification service (for accurate groupnotification count)
            await registerEnqueue(task: task, notificationConfigJsonString: notificationConfigJsonString, success: false)
        }
    }
}

/// Traditional lock for asyn/await environment
actor AsyncLock {
    private var isLocked = false
    
    func lock() async {
        while isLocked {
            await _Concurrency.Task.yield()
        }
        isLocked = true
    }
    
    func unlock() async {
        isLocked = false
    }
}
