//
//  UrlSessionDelegate.swift
//  background_downloader
//
//  Created by Bram on 11/12/23.
//

import Foundation
import os.log


public class UrlSessionDelegate : NSObject, URLSessionDelegate, URLSessionDownloadDelegate, URLSessionDataDelegate {
    
    static let instance = UrlSessionDelegate()
    static var urlSession: URLSession?
    public static var sessionIdentifier = "com.bbflight.background_downloader.Downloader"
    public static var backgroundCompletionHandler: (() -> Void)?
    
    private var storageFailures = [Int: TaskException]()

    private func cancelForStorage(_ downloadTask: URLSessionTask, error: Error) {
        let shouldCancel = BDPlugin.propertyLock.withLock {
            guard storageFailures[downloadTask.taskIdentifier] == nil else { return false }
            storageFailures[downloadTask.taskIdentifier] = storageException(error)
            return true
        }
        guard shouldCancel else { return }
        // Do not request resume data: URLSession owns and discards the partial.
        downloadTask.cancel()
    }
    //MARK: URLSessionTaskDelegate

    /// Prevent credentials from crossing origins or being sent after a TLS downgrade.
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        guard let sourceURL = response.url, let destinationURL = request.url else {
            completionHandler(nil)
            return
        }
        if sourceURL.scheme?.lowercased() == "https",
           destinationURL.scheme?.lowercased() != "https" {
            completionHandler(nil)
            return
        }
        let sameOrigin = hasSameOrigin(sourceURL, destinationURL)
        let authenticatedLease =
            getTaskFrom(urlSessionTask: task)?.options?.auth?.hasOnAuthCallback() == true
        if authenticatedLease && !sameOrigin {
            completionHandler(nil)
            return
        }
        guard !sameOrigin else {
            completionHandler(request)
            return
        }
        var sanitizedRequest = request
        for header in ["Authorization", "Proxy-Authorization", "Cookie", "If-Match", "Range"] {
            sanitizedRequest.setValue(nil, forHTTPHeaderField: header)
        }
        completionHandler(sanitizedRequest)
    }

    private func hasSameOrigin(_ first: URL, _ second: URL) -> Bool {
        first.scheme?.lowercased() == second.scheme?.lowercased() &&
            first.host?.lowercased() == second.host?.lowercased() &&
            effectivePort(first) == effectivePort(second)
    }

    private func effectivePort(_ url: URL) -> Int? {
        if let port = url.port { return port }
        switch url.scheme?.lowercased() {
        case "http": return 80
        case "https": return 443
        default: return nil
        }
    }

    /// Called before the task starts, and may continue, cancel or modify the original request, based on native callbacks in the [TaskOptions] of the task
    public func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest) async -> (URLSession.DelayedRequestDisposition, URLRequest?) {
        guard let bgdTask = getTaskFrom(urlSessionTask: task)
        else {
            return (.continueLoading, nil)
        }
        do {
            try checkDownloadStorage(task: bgdTask, expected: task.countOfBytesExpectedToReceive,
                                     written: task.countOfBytesReceived)
        } catch {
            cancelForStorage(task, error: error)
            return (.cancel, nil)
        }
        // check & process beforeTaskStartCallback and cancel the task if returned value is not nil
        if bgdTask.options?.hasBeforeStartCallback() == true {
            if let statusUpdate = await invokeBeforeTaskStartCallback(task: bgdTask) {
                os_log("TaskId %@ interrupted by beforeTaskStart callback", log: log, type: .info, bgdTask.taskId)
                BDPlugin.propertyLock.withLock( {
                    BDPlugin.taskIdsProgrammaticallyCanceledBeforeStart.insert(bgdTask.taskId)
                })
                processStatusUpdate(task: bgdTask,
                                    status: statusUpdate.taskStatus,
                                    taskException: statusUpdate.exception,
                                    responseBody: statusUpdate.responseBody,
                                    responseHeaders: statusUpdate.responseHeaders,
                                    responseStatusCode: statusUpdate.responseStatusCode)
                return (.cancel, nil)
            }
        }
        // check & process onStartCalback and onAuthCallback
        guard bgdTask.options?.hasOnStartCallback() == true || bgdTask.options?.auth?.hasOnAuthCallback() == true
        else {
            return (.continueLoading, nil)
        }
        let (newTask, taskWasModified) = await getModifiedTask(task: bgdTask) // processes both onStart and onAuth
        if !taskWasModified {
            return (.continueLoading, nil)
        }
        // modify the request, copying the unmodified data from the original request
        guard let url = validateUrl(newTask)
        else {
            os_log("Invalid url in modified task", log: log, type: .info)
            return (.continueLoading, nil)
        }
        var newRequest = URLRequest(url: url)
        // all original request headers are copied, then the newTask headers are set:
        // you can change or add a header, but not remove one
        if request.allHTTPHeaderFields != nil {
            for (key, value) in request.allHTTPHeaderFields! {
                newRequest.setValue(value, forHTTPHeaderField: key)
            }}
        for (key, value) in newTask.headers {
            newRequest.setValue(value, forHTTPHeaderField: key)
        }
        newRequest.httpMethod = request.httpMethod
        newRequest.httpBody = request.httpBody
        newRequest.allowsCellularAccess = request.allowsCellularAccess
        return (URLSession.DelayedRequestDisposition.useNewRequest, newRequest)
    }
    
    /// Handle task completion
    ///
    /// DownloadTasks handle task completion in the :didFinishDownloadingTo function, so for download tasks
    /// we only process status updates if there was an error.
    /// For other tasks we handle error, or send .complete
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let bgdTask = getTaskFrom(urlSessionTask: task) else { // refers to "our" task, not a URLSessionTask
            os_log("Could not find task related to urlSessionTask %d", log: log, type: .error, task.taskIdentifier)
            return
        }
        if BDPlugin.propertyLock.withLock( {
            BDPlugin.taskIdsProgrammaticallyCanceledBeforeStart.remove(bgdTask.taskId) != nil
        }) {
            // task was canceled before start and the
            // status update already generated, so simply return without any further processing
            return
        }
        let multipartUploader = BDPlugin.propertyLock.withLock {
            BDPlugin.uploaderForUrlSessionTaskIdentifier.removeValue(forKey: task.taskIdentifier)
        }
        if let uploader = multipartUploader {
            try? FileManager.default.removeItem(at: uploader.outputFileUrl())
        }
        let responseStatusCode = (task.response as? HTTPURLResponse)?.statusCode ?? 0
        let responseStatusDescription = HTTPURLResponse.localizedString(forStatusCode: responseStatusCode)
        let responseHeaders = (task.response as? HTTPURLResponse)?.allHeaderFields
        let notificationConfig = getNotificationConfigFrom(urlSessionTask: task)
        if let tempUploadUrl = BDPlugin.propertyLock.withLock({ BDPlugin.tasksWithTempUploadFile.removeValue(forKey: bgdTask.taskId) }) {
            try? FileManager.default.removeItem(at: tempUploadUrl)
        }
        if BDPlugin.holdingQueue != nil {
            _Concurrency.Task {
                await BDPlugin.holdingQueue?.taskFinished(bgdTask)
            }
        }
        let responseBody = getResponseBody(taskId: bgdTask.taskId)
        let taskWasProgramaticallyCanceledAfterStart = BDPlugin.propertyLock.withLock( {
            BDPlugin.taskIdsProgrammaticallyCanceledAfterStart.remove(bgdTask.taskId) != nil
        })
        if let failure = BDPlugin.propertyLock.withLock({ storageFailures.removeValue(forKey: task.taskIdentifier) }) {
            processStatusUpdate(task: bgdTask, status: .failed, taskException: failure)
            updateNotification(task: bgdTask, notificationType: .error, notificationConfig: notificationConfig)
            return
        }
        if isDownloadTask(task: bgdTask), let error = error,
           isStorageFailure(storageException(error)) {
            processStatusUpdate(task: bgdTask, status: .failed, taskException: storageException(error))
            updateNotification(task: bgdTask, notificationType: .error, notificationConfig: notificationConfig)
            return
        }
        guard error == nil else {
            var notificationType = taskWasProgramaticallyCanceledAfterStart ? nil : NotificationType.error
            // handle the error if this task wasn't programatically cancelled (in which
            // case the error has been handled already)
            if !taskWasProgramaticallyCanceledAfterStart {
                // check if we have resume data, and if so, process it
                let userInfo = (error! as NSError).userInfo
                let resumeData = userInfo[NSURLSessionDownloadTaskResumeData] as? Data
                let canResume = resumeData != nil && processResumeData(task: bgdTask, resumeData: resumeData!)
                // check different error codes
                if (error! as NSError).code == NSURLErrorTimedOut {
                    os_log("Task with id %@ timed out", log: log, type: .info, bgdTask.taskId)
                    processStatusUpdate(task: bgdTask, status: .failed, taskException: TaskException(type: .connection, httpResponseCode: -1, description: error!.localizedDescription))
                    return
                }
                if (error! as NSError).code == NSURLErrorCancelled {
                    // cancelled with resumedata implies 'pause'
                    if canResume {
                        os_log("Paused task with id %@", log: log, type: .info, bgdTask.taskId)
                        processStatusUpdate(task: bgdTask, status: .paused)
                        if isDownloadTask(task: bgdTask) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                updateNotification(task: bgdTask, notificationType: .paused, notificationConfig: notificationConfig)
                            }
                        }
                        BDPlugin.propertyLock.withLock({
                            _ = BDPlugin.progressInfo.removeValue(forKey: bgdTask.taskId) // ensure .running update on resume
                            BDPlugin.initialResponseDataProcessed.remove(bgdTask.taskId)
                        })
                        return
                    }
                    // cancelled without resumedata implies 'cancel'
                    os_log("Canceled task with id %@", log: log, type: .info, bgdTask.taskId)
                    processStatusUpdate(task: bgdTask, status: .canceled)
                    notificationType = .canceled
                }
                else {
                    os_log("Error for taskId %@: %@", log: log, type: .error, bgdTask.taskId, error!.localizedDescription)
                    processStatusUpdate(task: bgdTask, status: .failed, taskException: TaskException(type: .general, httpResponseCode: -1, description: error!.localizedDescription))
                }
            }
            if isDownloadTask(task: bgdTask) && notificationType != nil {
                updateNotification(task: bgdTask, notificationType: notificationType!, notificationConfig: notificationConfig)
            }
            return
        }
        // there was no error
        os_log("Finished task with id %@", log: log, type: .info, bgdTask.taskId)
        // if this is an upload task, send final TaskStatus (based on HTTP status code).
        // for download tasks, this is done in urlSession(downloadTask:, didFinishDownloadingTo:)
        if isUploadTask(task: bgdTask) {
            let taskException = TaskException(type: .httpResponse, httpResponseCode: responseStatusCode, description: responseStatusDescription)
            let finalStatus = (200...206).contains(responseStatusCode)
            ? TaskStatus.complete
            : responseStatusCode == 404
            ? TaskStatus.notFound
            : TaskStatus.failed
            let notificationType = finalStatus == .complete ? NotificationType.complete : NotificationType.error 
            updateNotification(task: bgdTask, notificationType: notificationType, notificationConfig: notificationConfig)
            processStatusUpdate(task: bgdTask, status: finalStatus, taskException: taskException, responseBody: responseBody, responseHeaders: responseHeaders, responseStatusCode: responseStatusCode)
        }
    }
    
    //MARK: URLSessionDownloadTaskDelegate
    
    
    
    /// Process taskdelegate progress update for download task
    ///
    /// If the task requires progress updates, provides these at a reasonable interval
    /// If this is the first update for this file, also emits a 'running' status update
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        // task is var because the filename can be changed on the first 'didWriteData' call
        guard var task = getTaskFrom(urlSessionTask: downloadTask) else { return }
        guard BDPlugin.propertyLock.withLock({ storageFailures[downloadTask.taskIdentifier] == nil }) else { return }
        let progressInfo = BDPlugin.propertyLock.withLock({
            BDPlugin.progressInfo[task.taskId]
        })
        if progressInfo == nil {
            // first 'didWriteData' call, so send 'running' status update and show notification
            os_log("Starting/resuming taskId %@", log: log, type: .info, task.taskId)
            processStatusUpdate(task: task, status: TaskStatus.running)
            processProgressUpdate(task: task, progress: 0.0)
            BDPlugin.propertyLock.withLock({
                BDPlugin.progressInfo[task.taskId] = (lastProgressUpdateTime: 0, lastProgressValue: 0.0, lastTotalBytesDone: 0, lastNetworkSpeed: -1.0)
            })
            let notificationConfig = getNotificationConfigFrom(urlSessionTask: downloadTask)
            if (notificationConfig != nil) {
                updateNotification(task: task, notificationType: .running, notificationConfig: notificationConfig)
            }
        }
        if !BDPlugin.propertyLock.withLock({ BDPlugin.initialResponseDataProcessed.contains(task.taskId) }) {
            // response can be nil in cases when progressInfo is nil due to app resuming in foreground
            if let response = downloadTask.response as? HTTPURLResponse {
                BDPlugin.propertyLock.withLock( {
                    BDPlugin.initialResponseDataProcessed.insert(task.taskId)
                })
                // get suggested filename if needed
                let (filename, uri) = unpack(packedString: task.filename)
                if filename == "?" {
                    if (uri == nil) {
                        let newTask = taskWithSuggestedFilenameFromResponseHeaders(task: task, responseHeaders: response.allHeaderFields)
                        if newTask.filename != task.filename {
                            storeModifiedTask(task: newTask)
                            task = newTask
                        }
                    } else {
                        let suggestedFilename = suggestFilename(responseHeaders: response.allHeaderFields, urlString: task.url)
                        let packed = pack(filename: suggestedFilename.isEmpty ? "unknown" : suggestedFilename, uri: uri!)
                        let newTask = task.copyWith(filename: packed)
                        storeModifiedTask(task: newTask)
                        task = newTask
                    }
                }
                extractContentType(responseHeaders: response.allHeaderFields, task: task)
                // obtain content length override, if needed and available
                if totalBytesExpectedToWrite == -1 {
                    let contentLength = getContentLength(responseHeaders: response.allHeaderFields, task: task)
                    if contentLength != -1 {
                        BDPlugin.propertyLock.withLock({
                            BDPlugin.tasksWithContentLengthOverride[task.taskId] = contentLength
                        })
                    }
                }
                // check if the task is resumable
                if task.allowPause {
                    let acceptRangesHeader = (downloadTask.response as? HTTPURLResponse)?.allHeaderFields["Accept-Ranges"]
                    let taskCanResume = acceptRangesHeader as? String == "bytes"
                    processCanResume(task: task, taskCanResume: taskCanResume)
                    if taskCanResume {
                        BDPlugin.propertyLock.withLock({
                            _ = BDPlugin.taskIdsThatCanResume.insert(task.taskId)
                        })
                    }
                }
            }
        }
        let contentLength = BDPlugin.propertyLock.withLock({
            totalBytesExpectedToWrite != -1 ? totalBytesExpectedToWrite : BDPlugin.tasksWithContentLengthOverride[task.taskId] ?? -1
        })
        do {
            try checkDownloadStorage(task: task, expected: contentLength, written: totalBytesWritten)
        } catch {
            cancelForStorage(downloadTask, error: error)
            return
        }
        updateProgress(task: task, totalBytesExpected: contentLength, totalBytesDone: totalBytesWritten)
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                           didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        guard let task = getTaskFrom(urlSessionTask: downloadTask) else { return }
        do {
            try checkDownloadStorage(task: task, expected: expectedTotalBytes, written: fileOffset)
        } catch {
            cancelForStorage(downloadTask, error: error)
        }
    }
    
    /// Process taskdelegate progress update for upload task
    ///
    /// If the task requires progress updates, provide these at a reasonable interval
    /// If this is the first update for this file, also emit a 'running' status update
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let urlSessionTask = task
        guard let task = getTaskFrom(urlSessionTask: task) else {return}
        let taskId = task.taskId
        let progressInfo = BDPlugin.propertyLock.withLock({
            return BDPlugin.progressInfo[taskId]
        })
        if progressInfo == nil {
            // first call to this method: send 'running' status update
            processStatusUpdate(task: task, status: TaskStatus.running)
            processProgressUpdate(task: task, progress: 0.0)
            BDPlugin.propertyLock.withLock({
                BDPlugin.progressInfo[task.taskId] = (lastProgressUpdateTime: 0, lastProgressValue: 0.0, lastTotalBytesDone: 0, lastNetworkSpeed: -1.0)
            })
            // notify if needed
            let notificationConfig = getNotificationConfigFrom(urlSessionTask: urlSessionTask)
            if (notificationConfig != nil) {
                updateNotification(task: task, notificationType: .running, notificationConfig: notificationConfig)
            }
        }
        updateProgress(task: task, totalBytesExpected: totalBytesExpectedToSend, totalBytesDone: totalBytesSent)
    }
    
    /// Process end of downloadTask sent by the urlSession.
    ///
    /// If successful, (over)write file to final destination per Task info
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didFinishDownloadingTo location: URL) {
        if BDPlugin.propertyLock.withLock({ storageFailures[downloadTask.taskIdentifier] != nil }) {
            try? FileManager.default.removeItem(at: location)
            return
        }
        guard var task = getTaskFrom(urlSessionTask: downloadTask),
              let response = downloadTask.response as? HTTPURLResponse
        else {
            os_log("Could not find task associated urlSessionTask %d, or did not get HttpResponse", log: log,  type: .info, downloadTask.taskIdentifier)
            return}
        let responseHeaders = response.allHeaderFields
        let taskId = task.taskId
        let (mimeType, charSet) = BDPlugin.propertyLock.withLock({
            let mimeType = BDPlugin.mimeTypes.removeValue(forKey: taskId)
            let charSet = BDPlugin.charSets.removeValue(forKey: taskId)
            BDPlugin.tasksWithModifications.removeValue(forKey: taskId)
            BDPlugin.tasksWithContentLengthOverride.removeValue(forKey: taskId)
            BDPlugin.initialResponseDataProcessed.remove(taskId)
            return (mimeType, charSet)
        })
        let notificationConfig = getNotificationConfigFrom(urlSessionTask: downloadTask)
        if response.statusCode == 404 {
            let responseBody = readFile(url: location)
            processStatusUpdate(task: task, status: TaskStatus.notFound, responseBody: responseBody, responseHeaders: responseHeaders, responseStatusCode: response.statusCode)
            updateNotification(task: task, notificationType: .error, notificationConfig: notificationConfig)
            return
        }
        if !(200...206).contains(response.statusCode)   {
            os_log("TaskId %@ returned response code %d", log: log,  type: .info, task.taskId, response.statusCode)
            let responseBody = readFile(url: location)
            processStatusUpdate(task: task, status: TaskStatus.failed, taskException: TaskException(type: .httpResponse, httpResponseCode: response.statusCode, description: responseBody?.isEmpty == false ? responseBody! : HTTPURLResponse.localizedString(forStatusCode: response.statusCode)))
            if task.retriesRemaining == 0 {
                // update notification only if no retries remaining
                updateNotification(task: task, notificationType: .error, notificationConfig: notificationConfig)
            }
            return
        }
        do {
            var finalStatus = TaskStatus.failed
            var taskException: TaskException? = nil
            var responseBody: String? = nil
            defer {
                processStatusUpdate(task: task,
                                    status: finalStatus,
                                    taskException: taskException,
                                    responseBody: responseBody,
                                    responseHeaders: responseHeaders,
                                    responseStatusCode: response.statusCode,
                                    mimeType: mimeType,
                                    charSet: charSet)
                if finalStatus != TaskStatus.failed || task.retriesRemaining == 0 || isStorageFailure(taskException) {
                    // update notification only if not failed, or no retries remaining
                    updateNotification(task: task, notificationType: notificationTypeForTaskStatus(status: finalStatus), notificationConfig: notificationConfig)
                }
            }
            if (isDownloadTask(task: task)) {
                // Determine directoryUri and fileUrl based on URI mode or filepath mode
                var directoryUrl: URL?
                var fileUrl: URL?
                
                // filename field can contain filename and/or a file url (if already started)
                let unpackedFilename = unpack(packedString: task.filename)
                let filename = unpackedFilename.filename ?? "unknown"
                fileUrl = unpackedFilename.uri
                // directory may contain a path or a Uri representing the full destination directory
                if let directoryUri = uriFromStringValue(maybePacked: task.directory) {
                    // URI mode
                    let uri = decodeToFileUrl(uri: directoryUri)
                    guard let uri = uri else {
                        os_log("Invalid directory URI (could not convert bookmark): %@", log: log, type: .error, directoryUri.absoluteString)
                        taskException = TaskException(type: .fileSystem, httpResponseCode: -1,
                                                      description: "Invalid directory URI (could not convert bookmark): %@ \(directoryUri.absoluteString)")
                        return
                    }
                    guard uri.isFileURL else {
                        os_log("Invalid directory URI (not a file URL): %@", log: log, type: .error, uri.absoluteString)
                        taskException = TaskException(type: .fileSystem, httpResponseCode: -1,
                                                      description: "Invalid directory URI (not a file URL): \(uri.absoluteString)")
                        return
                    }
                    directoryUrl = uri
                    fileUrl = uri.appendingPathComponent(filename)
                    // store the full Uri in the task.filename so it can be retrieved
                    let newTask = task.copyWith(filename: pack(filename: filename, uri: fileUrl!))
                    task = newTask
                } else {
                    // Filepath mode
                    directoryUrl = try directoryForTask(task: task)
                    fileUrl = directoryUrl?.appendingPathComponent(filename)
                }
                
                // Guard against directoryUri or fileUrl being nil
                guard let directoryUri = directoryUrl, var fileUrl = fileUrl else {
                    os_log("Could not determine directory Uri or file Uri", log: log, type: .error)
                    taskException = TaskException(type: .fileSystem, httpResponseCode: -1,
                                                  description: "Could not determine directory or file Uri")
                    return
                }
                
                do {
                    try checkDownloadStorage(at: location)
                    try transferDownloadFile(from: location, to: fileUrl, move: true, replace: true)
                    
                    do {
                        if UserDefaults.standard.bool(forKey: BDPlugin.keyConfigExcludeFromCloudBackup)
                        {
                            try fileUrl.setCloudBackup(exclude: true)
                            os_log("Excluded from iCloud backup: %@", log: log, type: .info, fileUrl.path)
                        }
                    } catch {
                        os_log("Could not exclude from iCloud backup: %@ - %@", log: log, type: .info, fileUrl.path, error.localizedDescription)
                    }
                    finalStatus = TaskStatus.complete
                    
                } catch {
                    os_log("File operation failed: %@", log: log, type: .error, error.localizedDescription)
                    taskException = storageException(error)
                    try? FileManager.default.removeItem(at: location)
                    return
                }
            } else {
                // this is a DataTask, so we read the file as the responseBody
                responseBody = readFile(url: location)
                try? FileManager.default.removeItem(at: location);
                finalStatus = .complete
            }
        } catch {
            os_log("Uncaught file download error for taskId %@ and file %@: %@", log: log, type: .error, task.taskId, task.filename, error.localizedDescription)
            try? FileManager.default.removeItem(at: location)
        }
    }
    
    //MARK: URLSessionDataDelegate
    
    /// Collects incoming data following a file upload, by appending the data block to a static dictionary keyed by taskId
    public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    )
    {
        guard let task = getTaskFrom(urlSessionTask: dataTask)
        else {
            os_log("Could not find task associated urlSessionTask %d", log: log,  type: .info, dataTask.taskIdentifier)
            return
        }
        BDPlugin.propertyLock.withLock({
            var dataList = BDPlugin.responseBodyData[task.taskId] ?? []
            dataList.append(data)
            BDPlugin.responseBodyData[task.taskId] = dataList
        })
    }
    
    //MARK: URLSessionDelegate
    
    /// Upon completion of download of all files, call the completion handler
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            guard
                let handler = UrlSessionDelegate.backgroundCompletionHandler,
                session.configuration.identifier == UrlSessionDelegate.sessionIdentifier
            else {
                os_log("No handler or no identifier match in urlSessionDidFinishEvents", log: log, type: .info)
                return
            }
            handler()
        }
    }
    
    //MARK: Helpers
    
    /// Read the contents of a file to a String, or nil if unable
    private func readFile(url: URL) -> String? {
        do {
            let data = try Data(contentsOf: url)
            let string = String(data: data, encoding: .utf8)
            return string
        } catch {
            return nil
        }
    }
    
    /// Get response body for upload task with this [taskId]
    private func getResponseBody(taskId: String) -> String? {
        guard let dataList = BDPlugin.propertyLock.withLock( { BDPlugin.responseBodyData[taskId] }) else {
            return nil
        }
        var allData: Data? = nil
        dataList.forEach { data in
            if allData == nil {
                allData = data
            } else {
                allData?.append(data)
            }
        }
        if (allData == nil) {
            return nil
        }
        return String(data: allData!, encoding: .utf8)!
    }
    
    //MARK: UrlSession and related Task helpers
    
    /// Creates a urlSession
    ///
    /// Configures defaultResourceTimeout, defaultRequestTimeout and proxy based on configuration parameters,
    /// or defaults
    static func createUrlSession() -> Void {
        if UrlSessionDelegate.urlSession != nil {
            return
        }
        let config = URLSessionConfiguration.background(withIdentifier: UrlSessionDelegate.sessionIdentifier)
        let defaults = UserDefaults.standard
        let storedTimeoutIntervalForResource = defaults.double(forKey: BDPlugin.keyConfigResourceTimeout) // seconds
        let timeOutIntervalForResource = storedTimeoutIntervalForResource > 0 ? storedTimeoutIntervalForResource : BDPlugin.defaultResourceTimeout
        os_log("timeoutIntervalForResource = %d seconds", log: log, type: .info, Int(timeOutIntervalForResource))
        config.timeoutIntervalForResource = timeOutIntervalForResource
        let storedTimeoutIntervalForRequest = defaults.double(forKey: BDPlugin.keyConfigRequestTimeout) // seconds
        let timeoutIntervalForRequest = storedTimeoutIntervalForRequest > 0 ? storedTimeoutIntervalForRequest : BDPlugin.defaultRequestTimeout
        os_log("timeoutIntervalForRequest = %d seconds", log: log, type: .info, Int(timeoutIntervalForRequest))
        config.timeoutIntervalForRequest = timeoutIntervalForRequest
        let proxyAddress = defaults.string(forKey: BDPlugin.keyConfigProxyAdress)
        let proxyPort = defaults.integer(forKey: BDPlugin.keyConfigProxyPort)
        if (proxyAddress != nil && proxyPort != 0) {
            config.connectionProxyDictionary = [
                kCFNetworkProxiesHTTPEnable: true,
                kCFNetworkProxiesHTTPProxy: proxyAddress!,
                kCFNetworkProxiesHTTPPort: proxyPort,
                "HTTPSEnable": true,
                "HTTPSProxy": proxyAddress!,
                "HTTPSPort": proxyPort
            ]
            os_log("Using proxy %@:%d for all tasks", log: log, type: .info, proxyAddress!, proxyPort)
        } else {
            os_log("Not using proxy for any task", log: log, type: .info)
        }
        UrlSessionDelegate.urlSession = URLSession(configuration: config, delegate: UrlSessionDelegate.instance, delegateQueue: nil)
    }
    
    /// Return all tasks in this urlSession
    static func getAllTasks() async -> [Task] {
        UrlSessionDelegate.createUrlSession()
        guard let urlSessionTasks = await UrlSessionDelegate.urlSession?.allTasks else { return [] }
        return urlSessionTasks.compactMap({ getTaskFrom(urlSessionTask: $0) })
    }
    
    /// Return the active task with this taskId, or nil
    static func getTaskWithId(taskId: String) async -> Task? {
        return await getAllTasks().first(where: { $0.taskId == taskId })
    }
    
    /// Return all urlSessionsTasks in this urlSession
    static func getAllUrlSessionTasks(group: String? = nil) async -> [URLSessionTask] {
        UrlSessionDelegate.createUrlSession()
        if (group == nil) {
            guard let urlSessionTasks = await UrlSessionDelegate.urlSession?.allTasks else { return [] }
            return urlSessionTasks
        }
        guard let urlSessionTasks = await UrlSessionDelegate.urlSession?.allTasks else { return [] }
        let urlSessionTasksInGroup = urlSessionTasks.filter({
            guard let task = getTaskFrom(urlSessionTask: $0) else { return false }
            return task.group == group
        })
        return urlSessionTasksInGroup
    }
    
    /// Return the urlSessionTask matching this taskId, or nil
    static func getUrlSessionTaskWithId(taskId: String) async -> URLSessionTask? {
        guard let urlSessionTask = await getAllUrlSessionTasks().first(where: {
            guard let task = getTaskFrom(urlSessionTask: $0) else { return false }
            return task.taskId == taskId
        }) else { return nil }
        return urlSessionTask
    }
    
    /// Returns a `task` that may be modified through callbacks, and a bool to indicate that the task was modified.
    ///
    /// Callbacks would be attached to the task via its `Task.options` property, and if
    /// present will be invoked by starting a taskDispatcher on a background isolate, then
    /// sending the callback request via the MethodChannel.
    ///
    /// First test is for auth refresh (the onAuth callback), then the onStart callback. Both
    /// callbacks run in a Dart isolate, and may return a modified task, which will be used
    /// for the actual task execution.
    func getModifiedTask(task: Task) async -> (Task, Bool) {
        var authTask: Task?
        var taskWasModified: Bool = false
        if let auth = task.options?.auth {
            // Refresh token if needed
            if auth.isTokenExpired() && auth.hasOnAuthCallback() == true {
                authTask = await invokeOnAuthCallback(task: task)
            }
            taskWasModified = authTask != nil
            authTask = authTask ?? task // Either original or newly authorized
            guard let newAuth = authTask?.options?.auth else { return (authTask ?? task, taskWasModified) }
            // Insert query parameters and headers
            taskWasModified = true
            let uri = newAuth.addOrUpdateQueryParams(
                url: authTask!.url,
                queryParams: newAuth.getExpandedAccessQueryParams()
            )
            var headers = authTask!.headers
            headers.merge(newAuth.getExpandedAccessHeaders()) { (_, new) in new }
            authTask = authTask!.copyWith(url: uri.absoluteString, headers: headers)
        }
        authTask = authTask ?? task
        guard task.options?.hasOnStartCallback() == true else { return (authTask!, taskWasModified) }
        // onStart callback
        let modifiedTask = await invokeOnTaskStartCallback(task: authTask!)
        taskWasModified = taskWasModified || modifiedTask != nil
        return (modifiedTask ?? authTask!, taskWasModified)
    }
}
