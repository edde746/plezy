//
//  ParallelDownloader.swift
//  background_downloader
//
//  Created on 9/18/23.
//

import Foundation
import os.log

let chunkGroup = "chunk"

func scheduleParallelDownload(task: Task, taskDescription: String, baseRequest: URLRequest, resumeData: String) async -> Bool
{
    let isResume = !resumeData.isEmpty
    let parallelDownload = ParallelDownloader(task: task)
    if !isResume {
        return await withCheckedContinuation { continuation in
            let dataTask = URLSession.shared.dataTask(with: baseRequest) { (data, response, error) in
                if let httpResponse = response as? HTTPURLResponse, error == nil {
                    if httpResponse.statusCode == 404 {
                        os_log("URL not found for taskId %@", log: log, type: .info, task.taskId)
                    }
                    else if !parallelDownload.start(responseStatusCode: httpResponse.statusCode, contentLengthFromHeader: Int64(httpResponse.value(forHTTPHeaderField: "Content-Length") ?? "-1") ?? -1, responseHeaders: httpResponse.allHeaderFields ) {
                        os_log("Cannot chunk or enqueue download", log: log, type: .info)
                    } else {
                        if BDPlugin.holdingQueue?.enqueuedTaskIds.contains(task.taskId) != true {
                            // only send .enqueued if we didn't already do that when
                            // enqueueing with the holdingQueue
                            processStatusUpdate(task: task, status: TaskStatus.enqueued)
                        }
                        continuation.resume(returning: true)
                        return
                    }
                } else {
                    os_log("Error making HEAD request for taskId %@", log: log, type: .info, task.taskId)
                }
                continuation.resume(returning: false)
            }
            dataTask.priority = 1 - Float(task.priority) / 10
            dataTask.resume()
        }
    } else {
        // resume
        return parallelDownload.resume(resumeData: resumeData)
    }
}

/**
 / Manages a parallel download
 /
 / A ParallelDownloadTask pings the server to get the content-length of the
 / download, then creates a list of [Chunk]s, each representing a portion
 / of the download.  Each chunk-task has its group set to 'chunk' and
 / has the taskId of the parent ParallelDownloadTask in its
 / [Task.metaData] field.
 / The ParallelDownloader sends 'enqueue' messages back to the NativeDownloader to
 / start each chunk-task, just like any other download task.
 / Messages with group 'chunk' are intercepted in the NativeDownloader,
 / and the update is sent to the ParallelDownloader.
 / In the ParallelDownloader, the update is processed and the new status/progress
 / of the ParallelDownloadTask is determined. If the status/progress has
 / changed, an update is sent and the status is processed (e.g., a complete
 / status triggers the piecing together of the downloaded file from
 / its chunk pieces).
 /
 / Similarly, pause and cancel commands are sent to all chunk tasks before
 / updating the status of the parent ParallelDownloadTask
 */
public class ParallelDownloader: NSObject {
    // downloads is the list of active parallel downloads, used to route child
    // status and progress updates
    static var downloads: [String : ParallelDownloader] = [:] // keyed by parentTask.taskId
    var parentTask: Task
    var chunks: [Chunk] = []
    var parallelDownloadContentLength: Int64 = 0
    var lastTaskStatus: TaskStatus = .enqueued
    var lastProgress: Double = 0
    var nextProgressUpdateTime = Date()
    var taskException: TaskException? = nil
    var responseBody: String? = nil
    var responseHeaders: [AnyHashable : Any]? = nil
    var initialResponseStatusCode: Int? = nil
    
    /// Create a new ParallelDownloader
    init(task:Task) {
        self.parentTask = task
    }
    
    /// Start the parallel download by creating and enqueueing chunks based on
    /// the content length and header fields
    ///
    /// Returns false if start was unsuccessful
    public func start(responseStatusCode: Int, contentLengthFromHeader: Int64, responseHeaders: [AnyHashable: Any]) -> Bool {
        if !(200...206).contains(responseStatusCode) {
            os_log("TaskId %@ returned response code %d", log: log, type: .info, parentTask.taskId, responseStatusCode)
            return false
        }
        initialResponseStatusCode = responseStatusCode // may change due to chunk errors
        self.responseHeaders = responseHeaders
        // get suggested filename if needed
        if parentTask.filename == "?" {
            let newTask = taskWithSuggestedFilenameFromResponseHeaders(task: parentTask, responseHeaders: responseHeaders)
            if newTask.filename != parentTask.filename {
                // store for future replacement, and replace now
                storeModifiedTask(task: newTask)
                parentTask = newTask
            }
        }
        parallelDownloadContentLength = contentLengthFromHeader > 0
            ? contentLengthFromHeader
            : getContentLength(responseHeaders: responseHeaders, task: self.parentTask)
        if parallelDownloadContentLength <= 0 {
            os_log("Server does not provide content length - cannot chunk download. If you know the length, set Range or Known-Content-Length header", log: log, type: .info)
            return false
        }
        if responseHeaders.first(where: { entry in (entry.key as! String).lowercased() == "accept-ranges" && entry.value as! String == "bytes"}) == nil {
            os_log("Server does not accept ranges - cannot chunk download", log: log, type: .info)
            return false
        }
        extractContentType(responseHeaders: responseHeaders, task: self.parentTask)
        ParallelDownloader.downloads[parentTask.taskId] = self
        chunks = createChunks(task: parentTask, contentLength: parallelDownloadContentLength)
        let success = !chunks.isEmpty && enqueueChunkTasks()
        if !success {
            ParallelDownloader.downloads.removeValue(forKey: parentTask.taskId)
        }
        return success
    }
    
    /// resume: reconstruct [chunks] and wait for all chunk tasks to complete.
    /// The Dart side will resume each chunk task, so we just wait for the
    /// completer to complete
    func resume(resumeData: String) -> Bool {
        ParallelDownloader.downloads[parentTask.taskId] = self
        let decoder = JSONDecoder()
        guard
            let chunkList = try? decoder.decode([Chunk].self, from: resumeData.data(using: .utf8)!)
        else {
            os_log("Could not decode resumeData for taskid %@", log: log, type: .info, parentTask.taskId)
            return false
        }
        chunks = chunkList
        parallelDownloadContentLength = chunks.reduce(0, { partialResult, chunk in
            partialResult + chunk.toByte - chunk.fromByte + 1
        })
        lastTaskStatus = .paused
        return true
    }
    
    /// Returns a list of chunk information for this task, and sets
    /// [parallelDownloadContentLength] to the total length of the download
    ///
    /// Throws a StateError if any information is missing, which should lead
    /// to a failure of the [ParallelDownloadTask]
    func createChunks(task: Task, contentLength: Int64) -> [Chunk] {
        let numChunks = task.urls!.count * task.chunks!
        if contentLength <= 0 {
            os_log("Server does not provide content length - cannot chunk download", log: log, type: .info)
            return []
        }
        parallelDownloadContentLength = contentLength
        let chunkSize = (contentLength / Int64(numChunks)) + 1
        var chunksList: [Chunk] = []
        for i in 0..<numChunks {
            chunksList.append(Chunk(
                parentTask: task,
                url: task.urls![i % task.urls!.count],
                filename: "\(Int.random(in: 1..<1 << 32))",
                fromByte: Int64(i) * chunkSize,
                toByte: min(Int64(i) * chunkSize + chunkSize - 1, contentLength - 1)))
        }
        return chunksList
    }
    
    /// Enqueues all chunk tasks and returns true if successful
    ///
    /// Enqueue request is posted to Dart side
    func enqueueChunkTasks() -> Bool {
        let jsonEncoder = JSONEncoder()
        for chunk in chunks {
            guard let taskAsJsonData = try? jsonEncoder.encode(chunk.task)
            else {
                return false
            }
            if !postOnBackgroundChannel(method: "enqueueChild", task: parentTask, arg: String(data: taskAsJsonData, encoding: .utf8) as Any) {
                os_log("Could not enqueue child task for chunk", log: log, type: .info)
                return false
            }
        }
        return true
    }
    
    /// Process incoming [status] update for a chunk with [chunkTaskId]
    ///
    /// If status is failure, may include [taskException] and [responseBody]
    func chunkStatusUpdate(chunkTaskId: String, status: TaskStatus, taskException: TaskException?, responseBody: String?) {
        // Confirm chunk is part of this parent task
        guard let chunk = chunks.first(where: { $0.task.taskId == chunkTaskId }) else { return }
        // first check for fail -> retry
        if status == .failed && chunk.task.retriesRemaining > 0 && !isStorageFailure(taskException) {
            chunk.task.retriesRemaining -= 1
            let waitTimeSeconds = 2 << min(chunk.task.retries - chunk.task.retriesRemaining - 1, 8)
            os_log("Chunk with taskId %@ failed, waiting %d seconds to retry; %d retries remaining", log: log, type: .info, chunk.task.taskId, waitTimeSeconds, chunk.task.retriesRemaining)
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(waitTimeSeconds)) {
                if !postOnBackgroundChannel(
                    method: "enqueueChild",
                    task: self.parentTask,
                    arg: jsonStringFor(task: chunk.task)!
                ) {
                    self.chunkStatusUpdate(chunkTaskId: chunkTaskId, status: .failed, taskException: taskException, responseBody: responseBody)
                }
            }
        } else {
            // no retry
            let newStatusUpdate = updateChunkStatus(chunk: chunk, status: status)
            if let newStatusUpdate = newStatusUpdate {
                switch newStatusUpdate {
                    case .running:
                        processStatusUpdate(task: parentTask, status: .running)
                    case .complete:
                        let stitchResult = stitchChunks()
                        if stitchResult == TaskStatus.complete {
                            os_log("Finished task with id %@", log: log, type: .info, parentTask.taskId)
                        }
                        finishTask(status: stitchResult)
                    case .failed:
                        self.taskException = taskException
                        cancelAllChunkTasks()
                        finishTask(status: .failed)
                    case .notFound:
                        self.responseBody = responseBody
                        cancelAllChunkTasks()
                        finishTask(status: .notFound)
                    default:
                        // ignore all other status updates
                        break
                }
            }
        }
    }
    
    /// Process incoming [progress] update for a chunk with [chunkTaskId].
    ///
    /// Recalculates overall task progress (based on the average of the chunk
    /// task progress) and sends an updatre to the Dart isde and updates the
    /// notification at the appropriate interval
    func chunkProgressUpdate(chunkTaskId: String, progress: Double) {
        guard let chunk = chunks.first(where: { $0.task.taskId == chunkTaskId }) else {
            return  // chunk is not part of this parent task
        }
        if progress > 0 && progress < 1 {
            let parentProgress = updateChunkProgress(chunk: chunk, progress: progress)
            let totalBytesDone = Int64(parentProgress * Double(parallelDownloadContentLength))
            updateProgress(task: parentTask, totalBytesExpected: parallelDownloadContentLength, totalBytesDone: totalBytesDone)
        }
    }
    
    /// Update the status for this chunk, and return the status for the parent task
    /// as derived from the sum of the child tasks, or null if undefined
    ///
    /// The updates are received from the NativeDownloader, which intercepts
    /// status updates for the chunkGroup
    private func updateChunkStatus(chunk: Chunk, status: TaskStatus) -> TaskStatus? {
        chunk.status = status
        let parentStatus = parentTaskStatus()
        if let parentStatus = parentStatus, parentStatus != lastTaskStatus {
            lastTaskStatus = parentStatus
            return parentStatus
        }
        return nil
    }
    
    /// Returns the [TaskStatus] for the parent of this chunk, as derived from
    /// the 'sum' of the child tasks, or nil if undetermined
    ///
    /// The updates are received from the NativeDownloader, which intercepts
    /// status updates for the chunkGroup
    private func parentTaskStatus() -> TaskStatus? {
        if chunks.first(where: { $0.status == .failed }) != nil {
            return .failed
        }
        if chunks.first(where: { $0.status == .notFound }) != nil {
            return .notFound
        }
        if (chunks.reduce(into: 0) { previousValue, chunk in
            if chunk.status == .running {
                previousValue += 1
            }
        }) == 1 {
            return .running // if exactly one chunk task is running
        }
        if chunks.allSatisfy({ $0.status == .complete }) {
            return .complete
        }
        return nil
    }
    
    /// Updates the chunk's progress and returns the average progress
    ///
    /// Returns the [progress] for the parent of this chunk, as derived from
    /// its children by averaging
    private func updateChunkProgress(chunk: Chunk, progress: Double) -> Double {
        chunk.progress = progress
        return chunks.reduce(into: 0.0) { previousValue, chunk in
            previousValue += chunk.progress
        } / Double(chunks.count)
    }
    
    /// Stitch all chunks together into one file, per the [parentTask]
    private func stitchChunks() -> TaskStatus {
        let fileManager = FileManager.default
        let inputFiles = chunks.sorted(by: { $0.fromByte < $1.fromByte }).compactMap {
            getFilePath(for: $0.task).map { URL(fileURLWithPath: $0) }
        }
        defer {
            for file in inputFiles { try? fileManager.removeItem(at: file) }
        }
        do {
            guard inputFiles.count == chunks.count, let path = getFilePath(for: parentTask) else {
                throw CocoaError(.fileReadNoSuchFile)
            }
            let outputFile = URL(fileURLWithPath: path)
            let directory = outputFile.deletingLastPathComponent()
            let accessed = directory.startAccessingSecurityScopedResource()
            defer { if accessed { directory.stopAccessingSecurityScopedResource() } }
            var remaining = parallelDownloadContentLength
            try checkDownloadStorage(at: directory, remainingBytes: remaining)
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let staging = directory.appendingPathComponent(".background_downloader-\(UUID().uuidString).partial")
            defer { try? fileManager.removeItem(at: staging) }
            guard fileManager.createFile(atPath: staging.path, contents: nil) else { throw CocoaError(.fileWriteUnknown) }
            let output = try FileHandle(forWritingTo: staging)
            defer { try? output.close() }
            for input in inputFiles {
                try copyDownloadBytes(from: input, to: output, at: staging, remaining: &remaining)
            }
            try output.synchronize()
            try output.close()
            try checkDownloadStorage(at: staging)
            try commitDownloadFile(staging, to: outputFile, replace: true)
        } catch {
            os_log("Error stitching chunks: %@", log: log, type: .info, error.localizedDescription)
            taskException = storageException(error)
            return .failed
        }
        return .complete
    }
    
    /// Cancel this task
    ///
    /// Cancels all chunk tasks and completes the task with [TaskStatus.canceled]
    func cancelTask() {
        cancelAllChunkTasks()
        finishTask(status: .canceled)
    }
    
    /// Pause this task
    ///
    /// Pauses all chunk tasks
    func pauseTask() async -> Bool {
        let encoder = JSONEncoder()
        guard
            let chunkTasksData = try? encoder.encode(chunks.map({ chunk in
                chunk.task })),
            let chunksData = try? encoder.encode(chunks)
        else {
            return false
        }
        if !postOnBackgroundChannel(method: "pauseTasks", task: parentTask, arg: String(data: chunkTasksData, encoding: .utf8)!)
        {
            os_log("Could not pause chunk tasks for taskId %@", log: log, type: .info, parentTask.taskId)
            return false
        }
        if !postOnBackgroundChannel(method: "resumeData", task: parentTask, arg: String(data: chunksData, encoding: .utf8)!) {
            os_log("Could not post resume data for taskId %@", log: log, type: .info, parentTask.taskId)
            // because we already paused the 
            cancelAllChunkTasks()
            processStatusUpdate(task: parentTask, status: .failed)
            return false
        }
        processStatusUpdate(task: parentTask, status: .paused)
        return true
    }
    
    /// Cancel the tasks associated with each chunk
    ///
    /// Accomplished by sending list of taskIds to cancel to the NativeDownloader
    private func cancelAllChunkTasks() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(chunks.map({ $0.task.taskId })) else {
            os_log("Could not encode chunk ids", log: log, type: .error)
            return
        }
        if !postOnBackgroundChannel(method: "cancelTasksWithId", task: parentTask, arg: String(data: data, encoding: .utf8)!) {
            os_log("Could not cancel chunk tasks related to taskId %@", log: log, type: .info, parentTask.taskId)
        }
    }
    
    /// Finish the [ParallelDownloadTask] by posting a statusUpdate and clearning up
    private func finishTask(status: TaskStatus) {
        let taskId = parentTask.taskId
        let (mimeType, charSet) = BDPlugin.propertyLock.withLock({
            (BDPlugin.mimeTypes[taskId], BDPlugin.charSets[taskId])
        })
        var responseStatusCode: Int? = nil
        switch status {
            case .complete:
                responseStatusCode = initialResponseStatusCode
                
            case .notFound:
                responseStatusCode = 404
                
            default:
                responseStatusCode = nil
        }
        processStatusUpdate(task: parentTask, status: status, taskException: taskException, responseBody: responseBody, responseHeaders: responseHeaders, responseStatusCode: responseStatusCode, mimeType: mimeType, charSet: charSet)
        BDPlugin.propertyLock.withLock({
            BDPlugin.mimeTypes.removeValue(forKey: taskId)
            BDPlugin.charSets.removeValue(forKey: taskId)
            BDPlugin.tasksWithModifications.removeValue(forKey: taskId)
            ParallelDownloader.downloads.removeValue(forKey: taskId)
        })
    }
}

/// Represents one chunk of a parallel download
///
/// Initialized to a specific range of the parent task.
/// Holds state (status and progress) of the chunk
public class Chunk: NSObject, Codable {
    let parentTaskId: String
    let url: String
    let filename: String
    let fromByte: Int64
    let toByte: Int64
    var task: Task
    var status: TaskStatus = TaskStatus.enqueued
    var progress = 0.0
    
    
    init(parentTask: Task, url: String, filename: String, fromByte: Int64, toByte: Int64) {
        self.parentTaskId = parentTask.taskId
        self.url = url
        self.filename = filename
        self.fromByte = fromByte
        self.toByte = toByte
        var headers = parentTask.headers
        headers["Range"] = "bytes=\(fromByte)-\(toByte)"
        let jsonEncoder = JSONEncoder()
        let data = try? jsonEncoder.encode(["parentTaskId": self.parentTaskId, "from": String(fromByte), "to": String(toByte)])
        let metaData = data != nil ? String(data: data!, encoding: .utf8) ?? "" : ""
        self.task = Task(url: url, filename: filename, headers: headers, baseDirectory: BaseDirectory.temporary.rawValue, group: chunkGroup, updates: Chunk.updatesBasedOnParent(parentTask), retries: parentTask.retries, retriesRemaining: parentTask.retries, allowPause: parentTask.allowPause, priority: parentTask.priority, metaData: metaData, taskType: "DownloadTask")
    }
    
    /// Returns [Updates] enum rawValue based on its parent
    static func updatesBasedOnParent(_ parentTask: Task) -> Int {
        return parentTask.updates == Updates.none.rawValue || parentTask.updates == Updates.statusChange.rawValue ? Updates.statusChange.rawValue : Updates.statusChangeAndProgressUpdates.rawValue
    }
}
