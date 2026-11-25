#if !os(tvOS)
import Foundation
import os
import OSLog
import PlezyKit

private let log = Logger(subsystem: "com.edde746.plezy", category: "downloads")

/// The shared core's `DownloadTransport` on iPhone, iPad and the Mac: background `URLSession` download tasks, which go
/// on while the app is suspended or killed (the system moves the bytes) and relaunch it in the background when they end
/// (iOS: `AppDelegate`'s background-events hook, `handleEvents`). Two sessions, the same but for the network they may
/// use.
///
/// A task's body arrives as a file of its own: it moves beside the part file at once (the system deletes it when the
/// delegate call returns) as `<part>.incoming`, which `TransferFiles.adopt` puts into the part file with the answer
/// that describes it (`Answer.describing`).
///
/// Stopping (and a failed task that left resume data) puts the bytes the system kept into the part file (`salvage`),
/// so the next start continues from the part's size with `Range` and `If-Range` whatever its URL (a download
/// asked for again comes with a fresh one; resume data only resumes the URL it came from). Resume data is never kept:
/// its requests hold their URL, and with it the server's token. When its bytes can't be put into the part file, it is
/// dropped with them and the next start asks again from the part file's end.
///
/// A link that dies mid-transfer leaves nothing to salvage: the system asks it for the rest by itself, gets the 403 and
/// ends the task with that answer, deleting what it had received. After such a loss the download's tasks ask for
/// chunks (`chunks`), each put into the part file as it arrives, so a link that dies again takes at most one chunk with
/// it; a download that never lost bytes runs as one task, which the system finishes while the app is suspended.
///
/// Transfers outlive the process: each one's record (the request without its URL and headers, which carry credentials)
/// is kept in the user defaults, so a task that ends while no listener is attached (a background relaunch, the app
/// starting) has its body adopted and its result kept for `reattach`.
///
/// One per process (`shared`), made at launch before the system delivers any event. Its state is confined to `queue`,
/// the sessions' delegate queue.
final class BackgroundTransport: NSObject, DownloadTransport, @unchecked Sendable {
    static let shared = BackgroundTransport()

    /// The sessions: any network, and Wi-Fi only (no expensive or constrained network).
    private static let anyNetwork = "com.edde746.plezy.downloads"
    private static let unmetered = "com.edde746.plezy.downloads.wifi"
    private static let recordsKey = "downloads.transfers"
    private static let chunksKey = "downloads.chunks"
    /// The least time between two progress reports of a transfer.
    private static let progressInterval: UInt64 = 500_000_000
    /// The statuses of a link that expired.
    private static let expired: Set<Int> = [403, 404, 410]

    private let queue = DispatchQueue(label: "com.edde746.plezy.downloads")
    private var sessions: [String: URLSession] = [:]
    private var transfers: [String: Transfer] = [:]
    /// The downloads that lost bytes to a dying link, by id: the size of the chunks their tasks ask for. Kept in the
    /// user defaults until the download completes.
    private var chunks: [String: Int64] = [:]

    private override init() {
        super.init()
        let records = Self.loadRecords()
        let chunks = (UserDefaults.standard.dictionary(forKey: Self.chunksKey) as? [String: NSNumber])?.mapValues(\.int64Value) ?? [:]
        queue.sync {
            for record in records { transfers[record.id] = Transfer(record) }
            self.chunks = chunks
        }
        let delegateQueue = OperationQueue()
        delegateQueue.underlyingQueue = queue
        delegateQueue.maxConcurrentOperationCount = 1
        for (identifier, wifiOnly) in [(Self.anyNetwork, false), (Self.unmetered, true)] {
            let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
            configuration.sessionSendsLaunchEvents = true
            configuration.isDiscretionary = false
            configuration.allowsExpensiveNetworkAccess = !wifiOnly
            configuration.allowsConstrainedNetworkAccess = !wifiOnly
            configuration.urlCache = nil
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            let session = URLSession(configuration: configuration, delegate: self, delegateQueue: delegateQueue)
            queue.sync { sessions[identifier] = session }
        }
    }

    /// The system woke or relaunched the app for the events of the session `identifier` (iOS: the app delegate's
    /// `application(_:handleEventsForBackgroundURLSession:completionHandler:)`): `completion` runs once they are delivered
    /// (`urlSessionDidFinishEvents`), letting the system suspend the app again.
    @MainActor
    static func handleEvents(of identifier: String, completion: @escaping () -> Void) {
        guard identifier == anyNetwork || identifier == unmetered else { return completion() }
        log.notice("background events of \(identifier, privacy: .public): delivering")
        BackgroundEvents.handlers[identifier] = completion
        // The sessions exist from launch on; made here otherwise, so the system can deliver the events.
        _ = shared
    }

    // MARK: DownloadTransport

    func start(request: TransferRequest, listener: any TransferListener) {
        let call = UncheckedBox((request, listener))
        queue.async { self.begin(call.value.0, call.value.1) }
    }

    func stop(id: String) {
        queue.async {
            guard let transfer = self.transfers[id], transfer.record.outcome == nil, !transfer.stopping,
                  let task = transfer.task as? URLSessionDownloadTask else { return }
            transfer.stopping = true
            task.cancel { data in
                self.queue.async {
                    if let data { self.salvage(data, of: transfer) }
                    self.finish(transfer, .stopped)
                }
            }
        }
    }

    func reattach(ids: [String], listener: any TransferListener, done: @escaping ([String]) -> Void) {
        let call = UncheckedBox((listener, done))
        queue.async {
            let sessions = self.sessions
            Task {
                var found: [(String, [URLSessionTask])] = []
                for (identifier, session) in sessions { found.append((identifier, await session.allTasks)) }
                let tasks = UncheckedBox(found)
                self.queue.async { self.attach(Set(ids), call.value.0, call.value.1, tasks.value) }
            }
        }
    }

    // MARK: Transfers

    /// Starts `request` as a new task, which asks for one chunk when the download lost bytes before (`chunks`).
    /// `delivered`: what the URL gave the chunks before this one.
    private func begin(_ request: TransferRequest, _ listener: any TransferListener, delivered: Int64 = 0) {
        if let previous = transfers.removeValue(forKey: request.id) { previous.task?.cancel() }
        let identifier = request.wifiOnly ? Self.unmetered : Self.anyNetwork
        guard let session = sessions[identifier] else { return }
        guard let url = URL(string: request.url) else {
            saveRecords()
            return listener.onResult(id: request.id, result: TransferResultNetwork(kind: "BadURL"))
        }
        var last: Int64?
        if let chunk = chunks[request.id] {
            last = min(request.offset + chunk, request.expectedSize?.int64Value ?? .max) - 1
        }
        let task = session.downloadTask(with: Self.urlRequest(request, url, last: last))
        task.taskDescription = request.id
        if let end = last.map({ $0 + 1 }) ?? request.expectedSize?.int64Value, end > request.offset {
            task.countOfBytesClientExpectsToReceive = end - request.offset
        }
        let transfer = Transfer(Record(request, session: identifier, task: task.taskIdentifier, last: last))
        transfer.request = request
        transfer.listener = listener
        transfer.task = task
        transfer.delivered = delivered
        transfers[request.id] = transfer
        saveRecords()
        task.resume()
    }

    /// `last`: a chunk's last byte; nil asks for the rest of the file.
    private static func urlRequest(_ request: TransferRequest, _ url: URL, last: Int64?) -> URLRequest {
        var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        for (name, value) in request.headers { urlRequest.setValue(value, forHTTPHeaderField: name) }
        // Offsets count the file's own bytes, never a compressed transfer of them.
        urlRequest.setValue("identity", forHTTPHeaderField: "Accept-Encoding")
        if request.offset > 0 || last != nil {
            urlRequest.setValue("bytes=\(request.offset)-\(last.map(String.init) ?? "")", forHTTPHeaderField: "Range")
            if let validator = request.validator { urlRequest.setValue(validator, forHTTPHeaderField: "If-Range") }
        }
        if request.wifiOnly {
            urlRequest.allowsExpensiveNetworkAccess = false
            urlRequest.allowsConstrainedNetworkAccess = false
        }
        return urlRequest
    }

    /// A chunk of `transfer` is in the part file, which holds `bytes` now: the next chunk starts from there, sending
    /// the chunk's `validator` as `If-Range`. A transfer an earlier process started has no URL here: it ends as
    /// stopped (what arrived is kept) and the manager starts it again.
    private func next(_ transfer: Transfer, from bytes: Int64, validator: String?) {
        guard let request = transfer.request, let listener = transfer.listener else { return finish(transfer, .stopped) }
        let following = TransferRequest(
            id: request.id, url: request.url, headers: request.headers, partPath: request.partPath, offset: bytes,
            expectedSize: request.expectedSize, validator: validator ?? request.validator, title: request.title,
            wifiOnly: request.wifiOnly
        )
        begin(following, listener, delivered: transfer.delivered + bytes - transfer.record.offset)
    }

    /// The transfer `task` of `session` belongs to, unless it ended or another task took its place.
    private func transfer(of task: URLSessionTask, in session: URLSession) -> Transfer? {
        guard let id = task.taskDescription, let transfer = transfers[id], transfer.record.outcome == nil,
              transfer.record.session == session.configuration.identifier,
              transfer.record.task == task.taskIdentifier else { return nil }
        if transfer.task == nil { transfer.task = task }
        return transfer
    }

    /// Reports how `transfer` ended, or keeps it for `reattach` while no listener is attached.
    private func finish(_ transfer: Transfer, _ outcome: Outcome) {
        let id = transfer.record.id
        guard transfers[id] === transfer, transfer.record.outcome == nil else { return }
        transfer.task = nil
        updateChunks(transfer, outcome)
        guard let listener = transfer.listener else {
            transfer.record.outcome = outcome
            return saveRecords()
        }
        transfers.removeValue(forKey: id)
        saveRecords()
        listener.onResult(id: id, result: outcome.result)
    }

    /// A link that expired or failed after bytes arrived that nothing salvaged: the download's next tasks ask for
    /// chunks of half what the link gave before it died (it is expected to give about as much again), from 1 to
    /// 16 MiB, never more than before. Completed, the download no longer does.
    private func updateChunks(_ transfer: Transfer, _ outcome: Outcome) {
        let id = transfer.record.id
        switch outcome {
        case .completed:
            guard chunks.removeValue(forKey: id) != nil else { return }
        case .http(let status) where Self.expired.contains(status):
            guard transfer.received > 0, !transfer.salvaged else { return }
            chunkAfterLoss(transfer)
        case .network:
            guard transfer.received > 0, !transfer.salvaged else { return }
            chunkAfterLoss(transfer)
        default:
            return
        }
        UserDefaults.standard.set(chunks.mapValues { NSNumber(value: $0) }, forKey: Self.chunksKey)
    }

    private func chunkAfterLoss(_ transfer: Transfer) {
        let id = transfer.record.id
        let given = transfer.delivered + transfer.received
        let size = min(max(given / 2, 1 << 20), 16 << 20, chunks[id] ?? .max)
        chunks[id] = size
        log.notice("chunks: \(id, privacy: .public) lost \(transfer.received) bytes to a dying link (\(given) from it); chunks of \(size) from now on")
    }

    /// At launch: attaches `listener` to the tasks of `ids` still running, reports those `done` (with the ones that
    /// ended while no listener was attached, whose results follow), and cancels tasks no transfer wants.
    private func attach(
        _ ids: Set<String>, _ listener: any TransferListener, _ done: ([String]) -> Void, _ found: [(String, [URLSessionTask])]
    ) {
        var running: [String] = []
        var live = Set<String>()
        for (session, tasks) in found {
            for task in tasks {
                guard let id = task.taskDescription, let transfer = transfers[id], transfer.record.outcome == nil,
                      transfer.record.session == session, transfer.record.task == task.taskIdentifier,
                      transfer.listener != nil || ids.contains(id) else {
                    task.cancel()
                    continue
                }
                live.insert(id)
                if transfer.task == nil { transfer.task = task }
                if transfer.listener == nil {
                    transfer.listener = listener
                    running.append(id)
                }
            }
        }
        var ended: [(String, Outcome)] = []
        for (id, transfer) in transfers where transfer.listener == nil && !live.contains(id) {
            transfers.removeValue(forKey: id)
            if let outcome = transfer.record.outcome, ids.contains(id) {
                ended.append((id, outcome))
                running.append(id)
            }
        }
        saveRecords()
        log.notice("reattach: \(running.count - ended.count) running, \(ended.count) ended, of \(ids.count)")
        done(running)
        for (id, outcome) in ended { listener.onResult(id: id, result: outcome.result) }
    }

    /// Puts the body at `path` into the part file, described by `answer`.
    private func adopt(_ transfer: Transfer, _ path: String, _ answer: Answer) -> Outcome {
        let result = TransferFiles.shared.adopt(
            request: transfer.request ?? transfer.record.request,
            last: transfer.record.last.map { KotlinLong(value: $0) },
            incomingPath: path,
            status: Int32(answer.status),
            contentRange: answer.contentRange,
            contentLength: answer.contentLength.map { KotlinLong(value: $0) },
            etag: answer.etag,
            lastModified: answer.lastModified
        )
        return Outcome(result)
    }

    /// Puts the bytes resume data holds into the part file, so the next start continues from the part's size whatever
    /// its URL. Their file is the system's, named in the resume data, in the app's temporary directory once the task
    /// stopped (the session's download folder while it ran); it holds the bytes from the task's offset, which its first
    /// answer describes, and goes into the part file by `TransferFiles.adopt`'s rules. When the file isn't there, or
    /// the resume data says nothing usable, the resume data and the file are dropped.
    private func salvage(_ data: Data, of transfer: Transfer) {
        let id = transfer.record.id
        guard let info = ResumeInfo(data) else {
            return log.notice("salvage: \(id, privacy: .public): the resume data doesn't name its file; dropped")
        }
        guard let path = Self.systemFile(named: info.file), let size = Self.fileSize(path) else {
            return log.notice("salvage: \(id, privacy: .public): the system's file isn't there; the resume data dropped")
        }
        if info.bytes == 0 {
            try? FileManager.default.removeItem(atPath: path)
            return
        }
        guard let answer = transfer.record.answer, answer.accepts(offset: transfer.record.offset), size >= info.bytes else {
            try? FileManager.default.removeItem(atPath: path)
            return log.notice("salvage: \(id, privacy: .public): \(size) bytes there of \(info.bytes) received, no answer to describe them; dropped")
        }
        if size > info.bytes {
            do {
                let handle = try FileHandle(forWritingTo: URL(filePath: path))
                defer { try? handle.close() }
                try handle.truncate(atOffset: UInt64(info.bytes))
            } catch {
                try? FileManager.default.removeItem(atPath: path)
                return log.notice("salvage: \(id, privacy: .public): the system's file can't be cut to its \(info.bytes) bytes; dropped")
            }
        }
        // The file goes into the part file, or is gone.
        let outcome = adopt(transfer, path, answer)
        if case .completed(let bytes, _) = outcome {
            transfer.salvaged = true
            log.notice("salvage: \(id, privacy: .public): \(info.bytes) bytes from \(transfer.record.offset) into the part file, now \(bytes)")
        } else {
            log.notice("salvage: \(id, privacy: .public): the \(info.bytes) bytes don't continue the part file (\(String(describing: outcome), privacy: .public))")
        }
    }

    /// Where the system keeps a stopped or failed task's file `name`: the app's temporary directory, or the session's
    /// download folder (in the app's container on iPhone and iPad; the user's caches on the unsandboxed Mac).
    private static func systemFile(named name: String) -> String? {
        let name = (name as NSString).lastPathComponent
        let folders = [
            NSTemporaryDirectory(),
            home + "/Library/Caches/com.apple.nsurlsessiond/Downloads/" + (Bundle.main.bundleIdentifier ?? ""),
        ]
        return folders.map { ($0 as NSString).appendingPathComponent(name) }.first { FileManager.default.fileExists(atPath: $0) }
    }

    private static func fileSize(_ path: String) -> Int64? {
        (try? FileManager.default.attributesOfItem(atPath: path)[.size] as? NSNumber)?.int64Value
    }

    // MARK: Failures

    /// A failed task's outcome. A network failure is named by its error's domain and code: the error's text and user
    /// info hold the URL.
    private static func outcome(of error: NSError, partPath: String) -> Outcome {
        if isOutOfSpace(error) { return .diskFull }
        let fileErrors = [
            NSURLErrorCannotCreateFile, NSURLErrorCannotOpenFile, NSURLErrorCannotCloseFile, NSURLErrorCannotWriteToFile,
            NSURLErrorCannotRemoveFile, NSURLErrorCannotMoveFile,
        ]
        if error.domain == NSURLErrorDomain, fileErrors.contains(error.code) {
            return StorageFloor.shared.refuses(capacity: capacity(atPath: partPath, required: 0), required: 0) ? .diskFull : .writeFailed
        }
        return .network("\(error.domain) \(error.code)")
    }

    private static func writeOutcome(_ error: any Error) -> Outcome {
        isOutOfSpace(error as NSError) ? .diskFull : .writeFailed
    }

    private static func isOutOfSpace(_ error: NSError) -> Bool {
        var next: NSError? = error
        while let error = next {
            if error.domain == NSPOSIXErrorDomain, error.code == Int(ENOSPC) { return true }
            if error.domain == NSCocoaErrorDomain, error.code == NSFileWriteOutOfSpaceError { return true }
            next = error.userInfo[NSUnderlyingErrorKey] as? NSError
        }
        return false
    }

    /// The volume holding `path` (or its nearest existing parent): its size and the bytes free for data the user asked
    /// for. Plain free space leaves out what the system purges on demand (caches, optimized photos, local snapshots);
    /// the volume's capacity for important usage counts it, but takes milliseconds to read where free space takes
    /// microseconds. So when `required` more bytes fit above `StorageFloor` in plain free space, that is the answer;
    /// otherwise (or with no `required`) the important-usage figure, when larger. A reading of it serves for 30 seconds,
    /// charged with the free space lost since, while it admits `required`: a refusal rests on a fresh one. Nil when the
    /// volume can't be read.
    static func capacity(atPath path: String, required: Int64? = nil) -> VolumeCapacity? {
        var url = URL(filePath: path)
        while !FileManager.default.fileExists(atPath: url.path(percentEncoded: false)), url.pathComponents.count > 1 {
            url.deleteLastPathComponent()
        }
        guard let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityKey, .volumeTotalCapacityKey]),
              let free = values.volumeAvailableCapacity.map(Int64.init), let total = values.volumeTotalCapacity.map(Int64.init)
        else { return nil }
        let admits = { (available: Int64) in
            required.map { StorageFloor.shared.fits(capacity: VolumeCapacity(available: available, total: total), required: $0) } ?? false
        }
        if admits(free) { return VolumeCapacity(available: free, total: total) }
        let volume = (try? url.resourceValues(forKeys: [.volumeURLKey]).volume) ?? url
        let now = ProcessInfo.processInfo.systemUptime
        if let reading = importantUsage.withLock({ $0[volume] }), now - reading.at < 30 {
            let estimate = reading.bytes - max(0, reading.free - free)
            if admits(estimate) { return VolumeCapacity(available: max(estimate, free), total: total) }
        }
        let important = (try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]))?
            .volumeAvailableCapacityForImportantUsage.flatMap { $0 > 0 ? $0 : nil }
        importantUsage.withLock { $0[volume] = important.map { ImportantUsage(bytes: $0, free: free, at: now) } }
        return VolumeCapacity(available: max(important ?? free, free), total: total)
    }

    /// A reading of a volume's capacity for important usage, with the plain free space and system uptime it was taken at.
    private struct ImportantUsage {
        let bytes: Int64
        let free: Int64
        let at: TimeInterval
    }

    /// The latest reading of each volume's capacity for important usage.
    private static let importantUsage = OSAllocatedUnfairLock(initialState: [URL: ImportantUsage]())

    // MARK: Records

    /// The transfers this process or an earlier one started. Records that don't decode (a `Record` change between
    /// builds) are logged: without them the tasks they describe are cancelled as unknown, and the queue starts them
    /// again.
    private static func loadRecords() -> [Record] {
        guard let data = UserDefaults.standard.data(forKey: recordsKey) else { return [] }
        do {
            return try JSONDecoder().decode([Record].self, from: data)
        } catch {
            log.error("transfer records don't decode (\(data.count) bytes): \(String(describing: error), privacy: .public)")
            return []
        }
    }

    private func saveRecords() {
        do {
            UserDefaults.standard.set(try JSONEncoder().encode(transfers.values.map(\.record)), forKey: Self.recordsKey)
        } catch {
            log.error("transfer records not saved: \(String(describing: error), privacy: .public)")
        }
    }

    /// Paths in the home directory are kept relative to it: an app's container moves between installs and updates.
    private static let home = NSHomeDirectory()

    fileprivate static func portable(_ path: String) -> String {
        path.hasPrefix(home + "/") ? "~" + path.dropFirst(home.count) : path
    }

    fileprivate static func absolute(_ path: String) -> String {
        path.hasPrefix("~/") ? home + path.dropFirst() : path
    }
}

// MARK: - URLSessionDownloadDelegate

extension BackgroundTransport: URLSessionDownloadDelegate {
    func urlSession(
        _ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let transfer = transfer(of: downloadTask, in: session) else { return downloadTask.cancel() }
        if transfer.record.answer == nil, let response = downloadTask.response as? HTTPURLResponse {
            let answer = Answer(response)
            transfer.record.answer = answer
            saveRecords()
            if answer.accepts(offset: transfer.record.offset) {
                transfer.listener?.onResponse(id: transfer.record.id, validator: answer.validator)
            }
        }
        // An error answer's body isn't the file's (a link that died: the system asked it for the rest by itself).
        guard ((downloadTask.response as? HTTPURLResponse)?.statusCode ?? 0) < 400 else { return }
        transfer.received = totalBytesWritten
        // The volume, once per MiB the task receives: a body that would leave it below the floor stops here. The system
        // also writes while the app is suspended, when no sample runs: these samples are best effort.
        if totalBytesWritten >= transfer.nextSample {
            let sample = StorageFloor.shared.SAMPLE_BYTES
            transfer.nextSample = totalBytesWritten + sample
            let required = totalBytesExpectedToWrite > 0 ? max(totalBytesExpectedToWrite - totalBytesWritten, 0) : sample
            let volume = Self.capacity(atPath: Self.absolute(transfer.record.partPath), required: required)
            if StorageFloor.shared.refuses(capacity: volume, required: required) {
                log.notice("\(transfer.record.id, privacy: .public): the volume would fall below its floor; stopped")
                transfer.stopping = true
                downloadTask.cancel()
                return finish(transfer, .diskFull)
            }
        }
        guard let listener = transfer.listener else { return }
        let now = DispatchTime.now().uptimeNanoseconds
        guard now - transfer.lastProgress >= Self.progressInterval else { return }
        transfer.lastProgress = now
        let offset = transfer.record.offset
        let total = transfer.record.expectedSize ?? transfer.record.answer?.total
            ?? (totalBytesExpectedToWrite > 0 ? offset + totalBytesExpectedToWrite : nil)
        listener.onProgress(id: transfer.record.id, bytes: offset + totalBytesWritten, totalBytes: total.map { KotlinLong(value: $0) })
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let transfer = transfer(of: downloadTask, in: session) else { return }
        guard let response = downloadTask.response as? HTTPURLResponse else {
            transfer.arrival = .outcome(.network("NoResponse"))
            return
        }
        let answer = Answer(response)
        if transfer.record.answer == nil { transfer.record.answer = answer }
        if answer.status >= 400 {
            transfer.arrival = .outcome(.http(answer.status))
            return
        }
        // The system deletes the file when this returns.
        let path = Self.absolute(transfer.record.partPath) + ".incoming"
        do {
            try? FileManager.default.removeItem(atPath: path)
            try FileManager.default.moveItem(at: location, to: URL(filePath: path))
            transfer.arrival = .body(path: path, answer: answer)
        } catch {
            transfer.arrival = .outcome(Self.writeOutcome(error))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        guard let transfer = transfer(of: task, in: session) else { return }
        let arrival = transfer.arrival
        transfer.arrival = nil
        if let error = error as NSError? {
            // Stopping: the cancel's completion reports it.
            if transfer.stopping { return }
            if let data = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data { salvage(data, of: transfer) }
            if error.domain == NSURLErrorDomain, error.code == NSURLErrorCancelled,
               error.userInfo[NSURLErrorBackgroundTaskCancelledReasonKey] != nil, transfer.listener == nil {
                // The system cancelled it while the app wasn't running (quit from the app switcher): no longer running,
                // so `reattach` leaves it to the manager, which starts it again from what was kept.
                transfers.removeValue(forKey: transfer.record.id)
                return saveRecords()
            }
            return finish(transfer, Self.outcome(of: error, partPath: Self.absolute(transfer.record.partPath)))
        }
        switch arrival {
        case .body(let path, let answer):
            let used = Answer.describing(first: transfer.record.answer, last: answer, bodySize: Self.fileSize(path))
            let outcome = adopt(transfer, path, used)
            // A chunk: the next one follows until the file is whole.
            if case .completed(let bytes, let validator) = outcome, transfer.record.last != nil,
               let total = transfer.record.expectedSize ?? used.total, bytes < total {
                guard bytes > transfer.record.offset else { return finish(transfer, .network("EmptyChunk")) }
                return next(transfer, from: bytes, validator: validator)
            }
            finish(transfer, outcome)
        case .outcome(let outcome):
            finish(transfer, outcome)
        case nil:
            finish(transfer, .writeFailed)
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        guard let identifier = session.configuration.identifier else { return }
        Task { @MainActor in
            guard let completion = BackgroundEvents.handlers.removeValue(forKey: identifier) else { return }
            log.notice("background events of \(identifier, privacy: .public): delivered; the system may suspend the app")
            completion()
        }
    }
}

/// The completion handlers of background-session events the system is waiting on, by session.
@MainActor
private enum BackgroundEvents {
    static var handlers: [String: () -> Void] = [:]
}

// MARK: - State

/// One transfer, confined to the transport's queue.
private final class Transfer: @unchecked Sendable {
    var record: Record
    /// The request as started in this process; nil for a transfer recorded by an earlier one.
    var request: TransferRequest?
    var listener: (any TransferListener)?
    var task: URLSessionTask?
    /// What `didFinishDownloadingTo` left for `didCompleteWithError`.
    var arrival: Arrival?
    var stopping = false
    var lastProgress: UInt64 = 0
    /// The bytes of the file this task has received (an error answer's body aside).
    var received: Int64 = 0
    /// What the chunks before this one took from its URL, in this process.
    var delivered: Int64 = 0
    /// The resume data's bytes went into the part file.
    var salvaged = false
    /// The bytes received when the volume is next sampled.
    var nextSample: Int64 = 0

    init(_ record: Record) {
        self.record = record
    }
}

private enum Arrival {
    case body(path: String, answer: Answer)
    case outcome(Outcome)
}

/// What survives the process of a transfer: its request without the URL and headers.
private struct Record: Codable {
    let id: String
    /// Portable (`BackgroundTransport.portable`).
    let partPath: String
    let offset: Int64
    let expectedSize: Int64?
    let validator: String?
    let title: String
    let wifiOnly: Bool
    /// The task's session and identifier.
    let session: String
    let task: Int
    /// A chunk's last byte; nil when the task asks for the rest of the file.
    let last: Int64?
    /// The task's first answer: what its body begins with.
    var answer: Answer?
    /// How it ended while no listener was attached; `reattach` reports it.
    var outcome: Outcome?

    init(_ request: TransferRequest, session: String, task: Int, last: Int64?) {
        id = request.id
        partPath = BackgroundTransport.portable(request.partPath)
        offset = request.offset
        expectedSize = request.expectedSize?.int64Value
        validator = request.validator
        title = request.title
        wifiOnly = request.wifiOnly
        self.session = session
        self.task = task
        self.last = last
    }

    /// The request for `TransferFiles.adopt`, which reads neither URL nor headers.
    var request: TransferRequest {
        TransferRequest(
            id: id, url: "", headers: [:], partPath: BackgroundTransport.absolute(partPath), offset: offset,
            expectedSize: expectedSize.map { KotlinLong(value: $0) }, validator: validator, title: title, wifiOnly: wifiOnly
        )
    }
}

/// An HTTP answer's status and the headers `TransferFiles.adopt` reads.
private struct Answer: Codable, Equatable {
    let status: Int
    let contentRange: String?
    let contentLength: Int64?
    let etag: String?
    let lastModified: String?

    init(_ response: HTTPURLResponse) {
        status = response.statusCode
        contentRange = response.value(forHTTPHeaderField: "Content-Range")
        contentLength = response.value(forHTTPHeaderField: "Content-Length").flatMap { Int64($0) }
        etag = response.value(forHTTPHeaderField: "ETag")
        lastModified = response.value(forHTTPHeaderField: "Last-Modified")
    }

    /// A 206's range: `first-last` of `bytes first-last/total`.
    private var range: (first: Int64, last: Int64)? {
        guard status == 206, let spec = contentRange?.split(separator: " ").last?.split(separator: "/").first else { return nil }
        let bounds = spec.split(separator: "-").compactMap { Int64($0) }
        return bounds.count == 2 ? (bounds[0], bounds[1]) : nil
    }

    /// The body's length as announced: a 206's range, else its Content-Length.
    var bodyLength: Int64? {
        if let range { return range.last - range.first + 1 }
        return contentLength
    }

    /// The file's size as announced: a 206's `Content-Range` total, a 200's Content-Length.
    var total: Int64? {
        switch status {
        case 206: contentRange?.split(separator: "/").last.flatMap { Int64($0) }
        case 200: contentLength
        default: nil
        }
    }

    /// The server took a request from `offset`: a 200, or a 206 continuing from there.
    func accepts(offset: Int64) -> Bool {
        status == 200 || range?.first == offset
    }

    /// What a later resume sends as `If-Range`.
    var validator: String? { etag ?? lastModified }

    /// The answer a task's body file is described by. A task the system continued by itself after its connection
    /// dropped delivers the whole body the first answer announced, when the server continued it (its last answer then
    /// covers only the rest); a server that sent the whole file again instead is described by the last answer.
    static func describing(first: Answer?, last: Answer, bodySize: Int64?) -> Answer {
        guard let first, first != last else { return last }
        if let expected = first.bodyLength { return expected == bodySize ? first : last }
        return last.status == 206 ? first : last
    }
}

/// A transfer's result, kept across processes.
private enum Outcome: Codable {
    case completed(bytes: Int64, validator: String?)
    case http(Int)
    case changed
    case network(String)
    case diskFull
    case writeFailed
    case stopped

    init(_ result: TransferResult) {
        switch onEnum(of: result) {
        case .completed(let completed): self = .completed(bytes: completed.bytes, validator: completed.validator)
        case .http(let http): self = .http(Int(http.status))
        case .changed: self = .changed
        case .network(let network): self = .network(network.kind)
        case .diskFull: self = .diskFull
        case .writeFailed: self = .writeFailed
        case .stopped: self = .stopped
        }
    }

    var result: TransferResult {
        switch self {
        case .completed(let bytes, let validator): TransferResultCompleted(bytes: bytes, validator: validator)
        case .http(let status): TransferResultHttp(status: Int32(status))
        case .changed: TransferResultChanged.shared
        case .network(let kind): TransferResultNetwork(kind: kind)
        case .diskFull: TransferResultDiskFull.shared
        case .writeFailed: TransferResultWriteFailed.shared
        case .stopped: TransferResultStopped.shared
        }
    }
}

/// What a task's resume data says of the bytes it kept: the system's file holding them and how many there are.
private struct ResumeInfo {
    let file: String
    let bytes: Int64

    init?(_ data: Data) {
        // A keyed archive of a dictionary (its root under the key's name, not `root`), or a plain property list.
        var dictionary: [String: Any]?
        if let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: data) {
            let classes: [AnyClass] = [NSDictionary.self, NSString.self, NSNumber.self, NSData.self]
            dictionary = (unarchiver.decodeObject(of: classes, forKey: "NSKeyedArchiveRootObjectKey")
                ?? unarchiver.decodeObject(of: classes, forKey: NSKeyedArchiveRootObjectKey)) as? [String: Any]
            unarchiver.finishDecoding()
        }
        if dictionary == nil {
            dictionary = (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any]
        }
        guard let dictionary, let file = dictionary["NSURLSessionResumeInfoTempFileName"] as? String,
              let bytes = (dictionary["NSURLSessionResumeBytesReceived"] as? NSNumber)?.int64Value else { return nil }
        self.file = file
        self.bytes = bytes
    }
}
#endif
