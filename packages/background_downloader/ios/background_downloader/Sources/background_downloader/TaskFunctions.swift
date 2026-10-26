//
//  TaskFunctions.swift
//  background_downloader
//
//  Created on 2/11/23.
//

import Foundation
import Flutter
import os.log

let updatesQueue = DispatchQueue(label: "updatesProcessingQueue")
let separatorString = "***<<<|>>>***"

/// True if this task expects to provide progress updates
func providesProgressUpdates(task: Task) -> Bool {
    return task.updates == Updates.progressUpdates.rawValue || task.updates == Updates.statusChangeAndProgressUpdates.rawValue
}

/// True if this task expects to provide status updates
func providesStatusUpdates(downloadTask: Task) -> Bool {
    return downloadTask.updates == Updates.statusChange.rawValue || downloadTask.updates == Updates.statusChangeAndProgressUpdates.rawValue
}

/// True if this task is a DownloadTask, UriDownloadTask or ParallelDownloadTask
func isDownloadTask(task: Task) -> Bool {
    return task.taskType == "DownloadTask" || task.taskType == "UriDownloadTask" || task.taskType == "ParallelDownloadTask"
}

/// True if this task is a ParallelDownloadTask, false if not
func isParallelDownloadTask(task: Task) -> Bool
{
    return task.taskType == "ParallelDownloadTask"
}

/// True if this task is an UploadTask, false if not
///
/// A MultiUploadTask is also an UploadTask
func isUploadTask(task: Task) -> Bool {
    return task.taskType == "UploadTask" || task.taskType == "UriUploadTask" || task.taskType == "MultiUploadTask"
}

/// True if this task is a MultiUploadTask, false if not
func isMultiUploadTask(task: Task) -> Bool {
    return task.taskType == "MultiUploadTask"
}

/// True if this task is a binary UploadTask
func isBinaryUploadTask(task: Task) -> Bool {
    return isUploadTask(task: task) && task.post?.lowercased() == "binary"
}

/// True if this is a DataTask
func isDataTask(task: Task) -> Bool {
    return task.taskType == "DataTask"
}

/// True if this state is not a final state (i.e. more changes may happen)
func isNotFinalState(status: TaskStatus) -> Bool {
    return status == .enqueued || status == .running || status == .waitingToRetry || status == .paused
}

/// True if this state is a final state (i.e. no more changes will happen)
func isFinalState(status: TaskStatus) -> Bool {
    return !isNotFinalState(status: status)
}

/// Returns the absolute path to the file represented by this task
/// based on the [Task.filename] (default) or [withFilename]
///
/// If the task is a MultiUploadTask and no [withFilename] is given,
/// returns the empty string, as there is no single path that can be
/// returned
func getFilePath(for task: Task, withFilename: String? = nil) -> String? {
    if isMultiUploadTask(task: task) && withFilename == nil {
        return ""
    }
    guard let directory = try? directoryForTask(task: task)
    else {
        return nil
    }
    return directory.appendingPath(withFilename ?? task.filename).path
}

func stripFileExtension ( _ filename: String ) -> String {
    var components = filename.components(separatedBy: ".")
    guard components.count > 1 else { return filename }
    components.removeLast()
    return components.joined(separator: ".")
}

func headerValue(responseHeaders: [AnyHashable: Any], name: String) -> String? {
    for (key, value) in responseHeaders {
        if String(describing: key).lowercased() == name.lowercased() {
            if let stringValue = value as? String, !stringValue.isEmpty {
                return stringValue
            }
            if let stringValues = value as? [String] {
                return stringValues.first(where: { !$0.isEmpty })
            }
        }
    }
    return nil
}

func headerValue(headers: [String: String], name: String) -> String? {
    for (key, value) in headers {
        if key.lowercased() == name.lowercased() && !value.isEmpty {
            return value
        }
    }
    return nil
}

/// Suggests a filename based on response headers and a URL.
/// If none can be derived, returns an empty string.
///
/// - Parameters:
///   - responseHeaders: The response headers dictionary.
///   - urlString: The URL string the file would be downloaded from.
/// - Returns: A suggested filename, derived from the headers or the URL.
func suggestFilename(responseHeaders: [AnyHashable: Any], urlString: String) -> String {
    if let disposition = headerValue(responseHeaders: responseHeaders, name: "Content-Disposition"),
       let filename = filenameFromContentDisposition(disposition),
       !filename.isEmpty {
        return filename
    }

    os_log("Could not determine suggested filename from server", log: log, type: .debug)

    // Try filename derived from last path segment of the url
    if let url = URL(string: urlString), !url.lastPathComponent.isEmpty {
        return url.lastPathComponent
    }

    os_log("Could not parse URL pathSegment for suggested filename", log: log, type: .debug)
    return "" // Default fallback
}

func filenameFromContentDisposition(_ disposition: String) -> String? {
    let parameters = contentDispositionParameters(disposition)
    if let encodedFilename = parameters["filename*"],
       let decoded = decodeExtendedFilename(encodedFilename),
       !decoded.isEmpty {
        return decoded
    }
    return parameters["filename"]
}

private func decodeExtendedFilename(_ value: String) -> String? {
    guard let firstQuote = value.firstIndex(of: "'") else { return value }
    guard let secondQuote = value[value.index(after: firstQuote)...].firstIndex(of: "'") else { return value }
    let charset = String(value[..<firstQuote]).uppercased()
    let encoded = String(value[value.index(after: secondQuote)...])
    if charset != "UTF-8" { return encoded }
    if let decoded = encoded.removingPercentEncoding {
        return decoded
    }
    os_log("Could not interpret suggested filename (UTF-8 url encoded) %@", log: log, type: .debug, encoded)
    return nil
}

private func contentDispositionParameters(_ disposition: String) -> [String: String] {
    var parameters: [String: String] = [:]
    for segment in splitContentDisposition(disposition).dropFirst() {
        guard let equalsIndex = segment.firstIndex(of: "=") else { continue }
        let key = segment[..<equalsIndex].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let valueStart = segment.index(after: equalsIndex)
        let value = unquoteHeaderValue(String(segment[valueStart...]).trimmingCharacters(in: .whitespacesAndNewlines))
        if !key.isEmpty && !value.isEmpty {
            parameters[key] = value
        }
    }
    return parameters
}

private func splitContentDisposition(_ value: String) -> [String] {
    var segments: [String] = []
    var current = ""
    var inQuotes = false
    var escaped = false
    for char in value {
        if escaped {
            current.append(char)
            escaped = false
            continue
        }
        if char == "\\" && inQuotes {
            escaped = true
            current.append(char)
            continue
        }
        if char == "\"" {
            inQuotes.toggle()
            current.append(char)
            continue
        }
        if char == ";" && !inQuotes {
            segments.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
            current = ""
            continue
        }
        current.append(char)
    }
    segments.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
    return segments
}

private func unquoteHeaderValue(_ value: String) -> String {
    if value.count >= 2 && value.hasPrefix("\"") && value.hasSuffix("\"") {
        let start = value.index(after: value.startIndex)
        let end = value.index(before: value.endIndex)
        return String(value[start..<end])
            .replacingOccurrences(of: "\\\"", with: "\"")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }
    return value
}

/**
 * Returns a copy of the task with the [Task.filename] property changed
 * to the filename suggested by the server, or derived from the url, or
 * unchanged.
 *
 * If [unique] is true, the filename is guaranteed not to already exist. This
 * is accomplished by adding a suffix to the suggested filename with a number,
 * e.g. "data (2).txt"
 *
 * The server-suggested filename is obtained from the  [responseHeaders] entry
 * "Content-Disposition"
 */
func taskWithSuggestedFilenameFromResponseHeaders(
    task: Task,
    responseHeaders: [AnyHashable: Any],
    unique: Bool = false
) -> Task {
    let suggestedFilenameValue = suggestFilename(responseHeaders: responseHeaders, urlString: task.url)
    
    if !suggestedFilenameValue.isEmpty {
        return uniqueFilename(task: task.copyWith(filename: suggestedFilenameValue), unique: unique)
    }
    
    // If everything fails, return the task with an unchanged filename
    // except for possibly making it unique
    return uniqueFilename(task: task, unique: unique)
}

/// Returns [Task] with a filename similar to the one
/// supplied, but unused.
///
/// If [unique], filename will sequence up in "filename (8).txt" format,
/// otherwise returns the [task]
func uniqueFilename(task: Task, unique: Bool) -> Task {
    if !unique {
        return task
    }
    let sequenceRegEx = try! NSRegularExpression(pattern: #"\((\d+)\)\.?[^.]*$"#)
    let extensionRegEx = try! NSRegularExpression(pattern: #"\.[^.]*$"#)
    var newTask = task
    guard let filePath = getFilePath(for: task) else {
        return task
    }
    var exists = FileManager.default.fileExists(atPath: filePath)
    while exists {
        let range = NSMakeRange(0, newTask.filename.utf16.count)
        let extMatch = extensionRegEx.firstMatch(in: newTask.filename, options: [], range: range)
        let extString = extMatch != nil ? String(newTask.filename[Range(extMatch!.range, in: newTask.filename)!]) : ""
        let seqMatch = sequenceRegEx.firstMatch(in: newTask.filename, options: [], range: range)
        let seqString = seqMatch != nil ? String(newTask.filename[Range(seqMatch!.range(at: 1), in: newTask.filename)!]) : ""
        let newSequence = seqString.isEmpty ? 1 : Int(seqString)! + 1
        let newFilename: String
        if seqMatch == nil {
            let baseNameWithoutExtension = stripFileExtension(newTask.filename)
            newFilename = "\(baseNameWithoutExtension) (\(newSequence))\(extString)"
        } else {
            let startOfSeq = seqMatch!.range.location
            let index = newTask.filename.index(newTask.filename.startIndex, offsetBy: startOfSeq)
            newFilename = "\(newTask.filename.prefix(upTo: index))(\(newSequence))\(extString)"
        }
        newTask = newTask.copyWith(filename: newFilename)
        guard let filePath = getFilePath(for: newTask) else {
            return task
        }
        exists = FileManager.default.fileExists(atPath: filePath)
    }
    return newTask
}

/**
 * Parses the range in a Range header, and returns a Pair representing
 * the range. The format needs to be "bytes=10-20"
 *
 * A missing lower range is substituted with 0L, and a missing upper
 * range with null.  If the string cannot be parsed, returns (0L, null)
 */
func parseRange(rangeStr: String) -> (Int64, Int64?) {
    let regex = try! NSRegularExpression(pattern: #"bytes=(\d*)-(\d*)"#)
    let range = NSMakeRange(0, rangeStr.utf16.count)
    if let match = regex.firstMatch(in: rangeStr, options: [], range: range) {
        let startString = String(rangeStr[Range(match.range(at: 1), in: rangeStr)!])
        let endString = String(rangeStr[Range(match.range(at: 2), in: rangeStr)!])
        let start = Int64(startString) ?? 0
        let end = endString.isEmpty ? nil : Int64(endString)
        return (start, end)
    } else {
        return (0, nil)
    }
}

/// Returns the content length extracted from the [responseHeaders], or from
/// the [task] headers
func getContentLength(responseHeaders: [AnyHashable: Any], task: Task) -> Int64 {
    if let contentLength = Int64(headerValue(responseHeaders: responseHeaders, name: "Content-Length") ?? ""), contentLength != -1 {
        return contentLength
    }
    // Try extracting content length from Range header
    let taskRangeHeader = headerValue(headers: task.headers, name: "Range") ?? ""
    let taskRange = parseRange(rangeStr: taskRangeHeader)
    if let end = taskRange.1 {
        let rangeLength = end - taskRange.0 + 1
        os_log("TaskId %@ contentLength set to %d based on Range header", log: log, type: .info, task.taskId, rangeLength)
        return rangeLength
    }

    // try extracting it from a special "Known-Content-Length" header
    let knownLength = Int64(headerValue(headers: task.headers, name: "Known-Content-Length") ?? "-1") ?? -1
    if knownLength != -1 {
        os_log("TaskId %@ contentLength set to %d based on Known-Content-Length header", log: log, type: .info, task.taskId, knownLength)
    } else {
        os_log("TaskId %@ contentLength undetermined", log: log, type: .info, task.taskId)
    }
    return knownLength
}

/// Sets the mimeType and charSet extracted from the Content-Type header
/// in [responseHeaders] and stores in static maps keyed by [task.taskId]
func extractContentType(responseHeaders: [AnyHashable: Any], task: Task)  {
    guard let contentType = headerValue(responseHeaders: responseHeaders, name: "Content-Type") else { return }
    let regEx = try! NSRegularExpression(pattern: #"(.*);\s*charset\s*=(.*)"#)
    let range = NSMakeRange(0, contentType.utf16.count)
    let match = regEx.firstMatch(in: contentType, options: [], range: range)
    BDPlugin.propertyLock.withLock({
        if let match = match {
            let mimeType = String(contentType[Range(match.range(at: 1), in: contentType)!])
            let charSet = String(contentType[Range(match.range(at: 2), in: contentType)!])
            BDPlugin.mimeTypes[task.taskId] = mimeType
            BDPlugin.charSets[task.taskId] = charSet
        } else {
            BDPlugin.mimeTypes[task.taskId] = contentType
        }
    })
}



/// Returns a list of fileData elements, one for each file to upload.
/// Each element is a triple containing fileField, full filePath, mimeType
///
/// The lists are stored in the similarly named String fields as a JSON list,
/// with each list the same length. For the filenames list, if a filename refers
/// to a file that exists (i.e. it is a full path) then that is the filePath used,
/// otherwise the filename is appended to the [Task.baseDirectory] and [Task.directory]
/// to form a full file path
func extractFilesData(task: Task) -> [((String, String, String))] {
    let decoder = JSONDecoder()
    guard
        let fileFields = try? decoder.decode([String].self, from: task.fileField!.data(using: .utf8)!),
        let filenames = try? decoder.decode([String].self, from: task.filename.data(using: .utf8)!),
        let mimeTypes = try? decoder.decode([String].self, from: task.mimeType!.data(using: .utf8)!)
    else {
        os_log("Could not parse filesData from field=%@, filename=%@ and mimeType=%@", log: log, type: .error, task.fileField!, task.filename, task.mimeType!)
        return []
    }
    var result = [(String, String, String)]()
    for i in 0 ..< fileFields.count {
        let fileUrl = URL(string: filenames[i])
        let decodedFileUrl = fileUrl != nil ? decodeToFileUrl(uri: fileUrl!) : nil
        if decodedFileUrl?.scheme == "file" {
            // URI mode, return path
            result.append((fileFields[i], decodedFileUrl!.path, mimeTypes[i]))
        } else {
            // file path mode
            if FileManager.default.fileExists(atPath: filenames[i]) {
                result.append((fileFields[i], filenames[i], mimeTypes[i]))
            } else {
                result.append((
                    fileFields[i],
                    getFilePath(for: task, withFilename: filenames[i]) ?? "",
                    mimeTypes[i]
                ))
            }
        }
    }
    return result
}

/// Return the host name for the task's url or ""
func getHost(_ task: Task) -> String  {
    return URL(string: task.url)?.host ?? ""
}
    
/// Calculate progress, network speed and time remaining, and send this at an appropriate
/// interval to the Dart side
func updateProgress(task: Task, totalBytesExpected: Int64, totalBytesDone: Int64) {
    let info = BDPlugin.propertyLock.withLock({
        return BDPlugin.progressInfo[task.taskId] ?? (lastProgressUpdateTime: 0.0, lastProgressValue: 0.0, lastTotalBytesDone: 0, lastNetworkSpeed: -1.0)
    })
    let now = Date().timeIntervalSince1970
    if totalBytesExpected != NSURLSessionTransferSizeUnknown && now > info.lastProgressUpdateTime + 0.5 {
        let progress = min(Double(totalBytesDone) / Double(totalBytesExpected), 0.999)
        if (progress - info.lastProgressValue > 0.02) || (progress > info.lastProgressValue && now > info.lastProgressUpdateTime + 2.5) {
            // calculate network speed and time remaining
            let now = Date().timeIntervalSince1970
            let timeSinceLastUpdate = now - info.lastProgressUpdateTime
            let bytesSinceLastUpdate = totalBytesDone - info.lastTotalBytesDone
            let currentNetworkSpeed: Double = timeSinceLastUpdate > 3600 ? -1.0 : Double(bytesSinceLastUpdate) / timeSinceLastUpdate / 1000000.0
            let newNetworkSpeed = info.lastNetworkSpeed == -1.0 ? currentNetworkSpeed : (info.lastNetworkSpeed * 3.0 + currentNetworkSpeed) / 4.0
            let remainingBytes = (1.0 - progress) * Double(totalBytesExpected)
            let timeRemaining: TimeInterval = newNetworkSpeed == -1.0 ? -1.0 : (remainingBytes / newNetworkSpeed / 1000000.0)
            BDPlugin.propertyLock.withLock({
                BDPlugin.progressInfo[task.taskId] = (lastProgressUpdateTime: now, lastProgressValue: progress, lastTotalBytesDone: totalBytesDone, lastNetworkSpeed: newNetworkSpeed)
            })
            processProgressUpdate(task: task, progress: progress, expectedFileSize: totalBytesExpected, networkSpeed: newNetworkSpeed, timeRemaining: timeRemaining)
        }
    }
}


/// Processes a change in status for the task
///
/// Sends status update via the background channel to Dart. Dart decides which
/// updates are user-visible and synthesizes terminal progress.
func processStatusUpdate(task: Task, status: TaskStatus, taskException: TaskException? = nil, responseBody: String? = nil, responseHeaders: [AnyHashable:Any]? = nil, responseStatusCode: Int? = nil, mimeType: String? = nil, charSet: String? = nil) {
    let storageFailure = status == .failed && isStorageFailure(taskException)
    let task = storageFailure ? task.copyWith(retriesRemaining: 0) : task
    // Intercept status updates resulting from re-enqueue requests, which
    // themselves are triggered by a change in WiFi requirement
    let intercepted = BDPlugin.propertyLock.withLock {
        if BDPlugin.tasksToReEnqueue.remove(task) != nil {
            defer {
                if BDPlugin.tasksToReEnqueue.isEmpty {
                    WiFiQueue.shared.reEnqueue(nil) // signal end of batch
                }
            }
            if !storageFailure && [TaskStatus.paused, TaskStatus.canceled, TaskStatus.failed].contains(status) {
                let reEnqueueData = EnqueueItem(task: task, notificationConfigJsonString: BDPlugin.notificationConfigJsonStrings[task.taskId], resumeDataAsBase64String: BDPlugin.localResumeData[task.taskId] ?? "")
                WiFiQueue.shared.reEnqueue(reEnqueueData)
                return true // intercepted
            }
        }
        return false // not intercepted
    }
    if intercepted {
        return
    }

    // Normal status update

    // Retry orchestration and terminal progress are generated on the Dart side.
    let retryNeeded = status == TaskStatus.failed && task.retriesRemaining > 0
    // determine the TaskStatusUpdate
    let finalResponseStatusCode = status == .complete || status == .notFound
        ? responseStatusCode
        : nil
    let finalTaskException = taskException == nil
        ? TaskException(type: .general, httpResponseCode: -1, description: "")
        : taskException
    let statusUpdate = isFinalState(status: status)
        ? TaskStatusUpdate(task: task,
                           taskStatus: status,
                           exception: status == .failed ? finalTaskException : nil,
                           responseBody: responseBody,
                           responseStatusCode: (status == .complete || status == .notFound) ? finalResponseStatusCode : nil,
                           responseHeaders: lowerCasedStringStringMap(responseHeaders),
                           mimeType: mimeType,
                           charSet: charSet)
        : TaskStatusUpdate(task: task, taskStatus: status)
    if let onNativeTaskStatusChange = BDPlugin.onNativeTaskStatusChange {
        onNativeTaskStatusChange(task, statusUpdate)
    }
    // Dart decides which status updates are user-visible.
    let arg = statusUpdate.argList()
    if !postOnBackgroundChannel(method: "statusUpdate", task: task, arg: arg) {
        // store update locally as a merged task/status JSON string, without error info
        guard let jsonData = try? JSONEncoder().encode(statusUpdate)
        else {
            os_log("Could not store status update locally", log: log, type: .debug)
            return }
        storeLocally(prefsKey: BDPlugin.keyStatusUpdateMap, taskId: task.taskId, item: jsonData)
    }
    if isFinalState(status: status) {
        // remove references to this task that are no longer needed
        BDPlugin.propertyLock.withLock {
            BDPlugin.progressInfo.removeValue(forKey: task.taskId)
            BDPlugin.localResumeData.removeValue(forKey: task.taskId)
            BDPlugin.tasksWithModifications.removeValue(forKey: task.taskId)
            BDPlugin.tasksWithContentLengthOverride.removeValue(forKey: task.taskId)
            BDPlugin.responseBodyData.removeValue(forKey: task.taskId)
            BDPlugin.notificationConfigJsonStrings.removeValue(forKey: task.taskId)
            BDPlugin.taskIdsThatCanResume.remove(task.taskId)
            BDPlugin.taskIdsProgrammaticallyCanceledAfterStart.remove(task.taskId)
        }
        // invoke onTaskFinished callback if needed
        if !retryNeeded && task.options?.hasOnFinishedCallback() == true {
            _Concurrency.Task {
                if !(await invokeOnTaskFinishedCallback(taskStatusUpdate: statusUpdate)) {
                    os_log("Could not invoke onTaskFinishedCallback", log: log, type: .error)
                }
            }
        }
    }
}


/// Processes a progress update for the task
///
/// Sends progress update via the background channel to Dart, if requested
func processProgressUpdate(task: Task, progress: Double, expectedFileSize: Int64 = -1, networkSpeed: Double = -1.0, timeRemaining: TimeInterval = -1.0) {
    if let onNativeTaskProgressChange = BDPlugin.onNativeTaskProgressChange {
        onNativeTaskProgressChange(task, progress)
    }
    if providesProgressUpdates(task: task) {
        if (!postOnBackgroundChannel(method: "progressUpdate", task: task, arg: [progress, expectedFileSize, networkSpeed, Int(timeRemaining * 1000.0)] as [Any])) {
            // store update locally as a merged task/progress JSON string
            guard let jsonData = try? JSONEncoder().encode(TaskProgressUpdate(task: task, progress: progress, expectedFileSize: expectedFileSize))
            else {
                os_log("Could not store progress update locally", log: log, type: .info)
                return }
            storeLocally(prefsKey: BDPlugin.keyProgressUpdateMap, taskId: task.taskId, item: jsonData)
        }
    }
}

/// Process a 'canResume' message for the task
///
/// Sends the data via the background channel to Dart
func processCanResume(task: Task, taskCanResume: Bool) {
    if !postOnBackgroundChannel(method: "canResume", task: task, arg: taskCanResume) {
        os_log("Could not post CanResume", log: log, type: .info)
    }
}

/// Post resume data for this task
///
/// Returns true if successful.
/// Sends the data via the background channel to Dart
func processResumeData(task: Task, resumeData: Data) -> Bool {
    let resumeDataAsBase64String = resumeData.base64EncodedString()
    BDPlugin.propertyLock.withLock {
        BDPlugin.localResumeData[task.taskId] = resumeDataAsBase64String
    }
    if !postOnBackgroundChannel(method: "resumeData", task: task, arg: resumeDataAsBase64String) {
        // store resume data locally
        guard let jsonData = try? JSONEncoder().encode(ResumeData(task: task, data: resumeDataAsBase64String))
        else {
            os_log("Could not store resume data locally", log: log, type: .info)
            return false}
        storeLocally(prefsKey: BDPlugin.keyResumeDataMap, taskId: task.taskId, item: jsonData)
    }
    return true
}

/// Return the background channel for cummincation to Dart side, or nil
func getBackgroundChannel() -> FlutterMethodChannel? {
    guard let channel = BDPlugin.backgroundChannel else {
        os_log("Could not find background channel", log: log, type: .error)
        return nil
    }
    return channel
}

/// Post method message on backgroundChannel with arguments and return true if this was successful
///
/// [arg] can be a list or a single variable
func postOnBackgroundChannel(method: String, task:Task, arg: Any) -> Bool {
    guard let channel = BDPlugin.backgroundChannel else {
        os_log("Could not find background channel", log: log, type: .error)
        return false
    }
    guard let jsonString = jsonStringFor(task: task) else {
        os_log("Could not convert task to JSON", log: log, type: .error)
        return false
    }
    var argsList: [Any?] = [jsonString]
    if arg is [Any?] {
        argsList.append(contentsOf: arg as! [Any?])
    } else {
        argsList.append(arg)
    }
    if Thread.isMainThread {
        DispatchQueue.main.async {
            channel.invokeMethod(method, arguments: argsList)
        }
        return true
    }
    var success = false
    updatesQueue.sync {
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        DispatchQueue.main.async {
            channel.invokeMethod(method, arguments: argsList, result: {(r: Any?) -> () in
                success = !(r is FlutterError)
                if BDPlugin.forceFailPostOnBackgroundChannel {
                    success = false
                }
                dispatchGroup.leave()
            })
        }
        dispatchGroup.wait()
    }
    return success
}

/// Store the [item] in preferences under [prefsKey], keyed by [taskId]
///
/// [item] is a JsonEncoded Data object
func storeLocally(prefsKey: String, taskId: String,
                  item: Data) {
    let defaults = UserDefaults.standard
    var map = defaults.dictionary(forKey: prefsKey) ?? [:]
    map[taskId] = String(data: item, encoding: .utf8)
    defaults.set(map, forKey: prefsKey)
}

/// Returns a JSON string for this Task, or nil
func jsonStringFor(task: Task) -> String? {
    let jsonEncoder = JSONEncoder()
    guard let jsonResultData = try? jsonEncoder.encode(task)
    else {
        return nil
    }
    return String(data: jsonResultData, encoding: .utf8)
}

/// Returns a JSON string for this TaskStatusUpdate, or nil
func jsonStringFor(taskStatusUpdate: TaskStatusUpdate) -> String? {
    let jsonEncoder = JSONEncoder()
    guard let jsonResultData = try? jsonEncoder.encode(taskStatusUpdate)
    else {
        return nil
    }
    return String(data: jsonResultData, encoding: .utf8)
}

/// Returns a Task from the supplied jsonString, or nil
func taskFrom(jsonString: String) -> Task? {
    let decoder = JSONDecoder()
    let task: Task? = try? decoder.decode(Task.self, from: (jsonString).data(using: .utf8)!)
    return task
}

/// Return the task corresponding to the URLSessionTask, or nil if it cannot be matched
///
/// May return a modified version of the task instead of the original stored with the URLSessionTask, e.g.
/// if the filename has changed
func getTaskFrom(urlSessionTask: URLSessionTask) -> Task? {
    guard let jsonData = getTaskJsonStringFrom(urlSessionTask: urlSessionTask)?.data(using: .utf8)
    else {
        return nil
    }
    let decoder = JSONDecoder()
    if let task = try? decoder.decode(Task.self, from: jsonData) {
        let modifiedTask = BDPlugin.propertyLock.withLock({
            BDPlugin.tasksWithModifications[task.taskId]
        })
        return modifiedTask ?? task
    }
    return nil
}

/// Marks the task as modified such that [getTaskFrom] a UrlSession wlll get the modified task, not the one'
/// immutably stored with the urlSession
func storeModifiedTask(task: Task) {
    BDPlugin.propertyLock.withLock({
        BDPlugin.tasksWithModifications[task.taskId] = task
    })
}

/// Returns the taskJsonString contained in the urlSessionTask
func getTaskJsonStringFrom(urlSessionTask: URLSessionTask) -> String? {
    guard let taskDescription = urlSessionTask.taskDescription else {
        return nil
    }
    if taskDescription.contains(separatorString) {
        return taskDescription.components(separatedBy: separatorString)[0]
    }
    return taskDescription
}

/// Return the notificationConfig corresponding to the URLSessionTask, or nil if it cannot be matched
func getNotificationConfigFrom(urlSessionTask: URLSessionTask) -> NotificationConfig? {
    guard let jsonData = getNotificationConfigJsonStringFrom(urlSessionTask: urlSessionTask)?.data(using: .utf8)
    else {
        return nil
    }
    let decoder = JSONDecoder()
    return try? decoder.decode(NotificationConfig.self, from: jsonData)
}


/// Returns the notificationConfigJsonString contained in the urlSessionTask
func getNotificationConfigJsonStringFrom(urlSessionTask: URLSessionTask) -> String? {
    guard let taskDescription = urlSessionTask.taskDescription else {
        return nil
    }
    if taskDescription.contains(separatorString) {
        return taskDescription.components(separatedBy: separatorString)[1]
    }
    return nil
}

/// Returns the URL of the directory where the file for this task is stored
///
/// This is made up of the baseDirectory and the directory fields of the Task
func directoryForTask(task: Task) throws ->  URL {
    let documentsURL: URL
    if task.baseDirectory != BaseDirectory.root.rawValue {
        var dir: FileManager.SearchPathDirectory
        switch task.baseDirectory {
            case 0:
                dir = .documentDirectory
            case 1:
                dir = .cachesDirectory
            case 2:
                dir = .applicationSupportDirectory
            case 3:
                dir = .libraryDirectory
            default:
                dir = .documentDirectory
        }
        documentsURL =
        try FileManager.default.url(for: dir,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: true)
    } else {
        documentsURL = URL(fileURLWithPath: "/")
    }
    return task.directory.isEmpty
    ? documentsURL
    : documentsURL.appendingPath(task.directory, isDirectory: true)
    
}

/// True if task requires WiFi, based on global and task-specific setting
func taskRequiresWiFi(task: Task) -> Bool {
    return BDPlugin.requireWiFi == .forAllTasks || (BDPlugin.requireWiFi == .asSetByTask && task.requiresWiFi)
}


/// Post result [value] on FlutterResult completer
func postResult(result: FlutterResult?, value: Any) {
    if result != nil {
        result!(value)
    }
}
