//
//  WiFi.swift
//  background_downloader
//
//  Created by Bram on 1/19/24.
//

import Foundation
import os.log

/// WiFi requirement modes at the application level
enum RequireWiFi: Int {
    case
    asSetByTask,
    forAllTasks,
    forNoTasks
}

/// Manages changes to WiFi requirement, by re-enqueuing tasks if needed
class WiFiQueue {
    static let shared = WiFiQueue()
    private let requireWiFiChangeQueue = DispatchQueue(label: "com.bbflight.background_downloader.requireWiFiChangeQueue", target: DispatchQueue.global())
    private let reEnqueueQueue = DispatchQueue(label: "com.bbflight.background_downloader.reEnqueueQueue", target: DispatchQueue.global())
    private let requireWiFiChangeSemaphore = DispatchSemaphore(value: 0)

    // Private initializer to prevent creating new instances
    private init() {}
    
    // Change the application level WiFi requirement and re-enqueue tasks as necessary
    func requireWiFiChange(requireWiFi: RequireWiFi, rescheduleRunningTasks: Bool, alsoRestartUploads: Bool) {
        requireWiFiChangeQueue.async {
            _Concurrency.Task {
                BDPlugin.requireWiFi = requireWiFi
                let defaults = UserDefaults.standard
                defaults.setValue(requireWiFi.rawValue, forKey: BDPlugin.keyRequireWiFi)
                UrlSessionDelegate.createUrlSession()
                guard let urlSessionTasks = await UrlSessionDelegate.urlSession?.allTasks
                else {
                    self.reEnqueuesDone()
                    return
                }
                var haveReEnqueued = false
                urlSessionTasks.forEach { urlSessionTask in
                    if ((urlSessionTask is URLSessionDownloadTask || urlSessionTask is URLSessionUploadTask) && (urlSessionTask.state == .running || urlSessionTask.state == .suspended)) {
                        guard let task = getTaskFrom(urlSessionTask: urlSessionTask) else {
                            return
                        }
                        BDPlugin.propertyLock.withLock {
                            if taskRequiresWiFi(task: task) != BDPlugin.taskIdsRequiringWiFi.contains(task.taskId) {
                                // requirement differs, so we need to re-enqueue
                                if taskRequiresWiFi(task: task) {
                                    BDPlugin.taskIdsRequiringWiFi.insert(task.taskId)
                                } else {
                                    BDPlugin.taskIdsRequiringWiFi.remove(task.taskId)
                                }
                                if BDPlugin.progressInfo[task.taskId] == nil {
                                    // enqueued only, so ensure it is re-enqueued and cancel
                                    haveReEnqueued = true
                                    BDPlugin.tasksToReEnqueue.insert(task)
                                    urlSessionTask.cancel()
                                } else {
                                    if rescheduleRunningTasks && isDownloadTask(task: task) {
                                        // already running, so pause instead of cancel
                                        haveReEnqueued = true
                                        BDPlugin.tasksToReEnqueue.insert(task)
                                        _Concurrency.Task{
                                            await (urlSessionTask as! URLSessionDownloadTask).cancelByProducingResumeData()
                                        }
                                    } else if alsoRestartUploads && isUploadTask(task: task) {
                                        haveReEnqueued = true
                                        BDPlugin.tasksToReEnqueue.insert(task)
                                        urlSessionTask.cancel()
                                    }
                                }
                            }
                        }
                    }
                }
                if !haveReEnqueued {
                    self.reEnqueuesDone() // nothing left to do
                }
            }
            self.requireWiFiChangeSemaphore.wait() // wait for re-enqueues to complete
        }
    }
    
    func reEnqueuesDone() {
        self.requireWiFiChangeSemaphore.signal()
    }
    
    
    /// Re-enqueue this task and associated data. Nil signals end of batch
    func reEnqueue(_ enqueueItem: EnqueueItem?) {
        reEnqueueQueue.async {
            _Concurrency.Task {
                guard let reEnqueueData = enqueueItem else {
                    // nil value indicates end of batch of re-enqueues
                    self.reEnqueuesDone()
                    return
                }
                let timeSinceCreated = Date().timeIntervalSince(reEnqueueData.created)
                if timeSinceCreated < 0.3 {
                    try await _Concurrency.Task.sleep(nanoseconds: UInt64((0.3 - timeSinceCreated) * 1_000_000_000))
                }
                await enqueueItem?.enqueue()
                try await _Concurrency.Task.sleep(nanoseconds: 20_000_000)
            }
        }
    }
}
