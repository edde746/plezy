import Foundation
import Darwin

/// A capacity refusal is terminal, including when the volume cannot be queried.
struct DownloadStorageError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

func isStorageFailure(_ exception: TaskException?) -> Bool {
    guard let description = exception?.description else { return false }
    return description.hasPrefix("Insufficient space to store") ||
        description.hasPrefix("Download storage capacity could not be determined")
}

func storageException(_ error: Error) -> TaskException {
    let nsError = error as NSError
    let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError
    let noSpace = (nsError.domain == NSPOSIXErrorDomain && nsError.code == Int(ENOSPC)) ||
        (nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileWriteOutOfSpaceError) ||
        (underlying?.domain == NSPOSIXErrorDomain && underlying?.code == Int(ENOSPC))
    return TaskException(type: .fileSystem, description: noSpace
        ? "Insufficient space to store the downloaded file: \(error.localizedDescription)"
        : error.localizedDescription)
}

private func existingStorageURL(_ url: URL) -> URL {
    var ancestor = url.standardizedFileURL
    while !FileManager.default.fileExists(atPath: ancestor.path) && ancestor.path != "/" {
        ancestor.deleteLastPathComponent()
    }
    return ancestor.resolvingSymlinksInPath()
}

/// Live free bytes already reflect downloaded data; charge only this operation's
/// remaining bytes. Never sum tasks (which can reside on different volumes).
func checkDownloadStorage(at url: URL, remainingBytes: Int64 = 0) throws {
    let config = UserDefaults.standard.integer(forKey: BDPlugin.keyConfigCheckAvailableSpace)
    guard config == -1 || config > 0 else { return }
    do {
        let values = try existingStorageURL(url).resourceValues(forKeys: [
            .volumeAvailableCapacityKey, .volumeTotalCapacityKey
        ])
        guard let free = values.volumeAvailableCapacity, free >= 0,
              let total = values.volumeTotalCapacity, total > 0 else {
            throw DownloadStorageError(message: "Download storage capacity could not be determined for \(url.path)")
        }
        let floor: Int64
        if config == -1 {
            floor = max(256 * 1024 * 1024, Int64(total) / 100 + (total % 100 == 0 ? 0 : 1))
        } else {
            floor = Int64(min(config, Int(Int64.max / (1024 * 1024)))) * 1024 * 1024
        }
        guard Int64(free) >= floor, max(0, remainingBytes) <= Int64(free) - floor else {
            throw DownloadStorageError(message: "Insufficient space to store the downloaded file on \(url.path)")
        }
    } catch let error as DownloadStorageError {
        throw error
    } catch {
        throw DownloadStorageError(message: "Download storage capacity could not be determined for \(url.path): \(error.localizedDescription)")
    }
}

func sameStorageVolume(_ first: URL, _ second: URL) -> Bool {
    guard let a = try? existingStorageURL(first).resourceValues(forKeys: [.volumeURLKey]).volume,
          let b = try? existingStorageURL(second).resourceValues(forKeys: [.volumeURLKey]).volume else { return false }
    return a == b
}

/// URLSession does not expose its private temporary file until completion.
/// Its background daemon can write while our process is suspended, so these
/// callback checks are best effort, not a hard write bound for network data.
func checkDownloadStorage(task: Task, expected: Int64 = -1, written: Int64 = 0) throws {
    let config = UserDefaults.standard.integer(forKey: BDPlugin.keyConfigCheckAvailableSpace)
    guard !isUploadTask(task: task), config == -1 || config > 0 else { return }
    let temporary = FileManager.default.temporaryDirectory
    let remaining = expected > written ? expected - max(0, written) : 0
    try checkDownloadStorage(at: temporary, remainingBytes: remaining)
    guard isDownloadTask(task: task) || isParallelDownloadTask(task: task) else { return }
    let destination: URL
    if let uri = uriFromStringValue(maybePacked: task.directory) {
        guard let decoded = decodeToFileUrl(uri: uri), decoded.isFileURL else {
            if UserDefaults.standard.integer(forKey: BDPlugin.keyConfigCheckAvailableSpace) != 0 {
                throw DownloadStorageError(message: "Download storage capacity could not be determined for destination")
            }
            return
        }
        destination = decoded
    } else {
        destination = try directoryForTask(task: task)
    }
    let accessed = destination.startAccessingSecurityScopedResource()
    defer { if accessed { destination.stopAccessingSecurityScopedResource() } }
    try checkDownloadStorage(at: destination, remainingBytes:
        sameStorageVolume(temporary, destination) ? remaining : max(max(0, expected), written))
}

/// Copy in bounded blocks, checking live capacity before each write. Input stays
/// intact and a unique sibling staging file is the only output removed on error.
func copyDownloadBytes(from source: URL, to output: FileHandle, at destination: URL, remaining: inout Int64) throws {
    let input = try FileHandle(forReadingFrom: source)
    defer { try? input.close() }
    while let data = try input.read(upToCount: 256 * 1024), !data.isEmpty {
        try checkDownloadStorage(at: destination, remainingBytes: max(remaining, Int64(data.count)))
        try output.write(contentsOf: data)
        remaining = max(0, remaining - Int64(data.count))
    }
}

func commitDownloadFile(_ source: URL, to destination: URL, replace: Bool) throws {
    if !replace && FileManager.default.fileExists(atPath: destination.path) {
        throw CocoaError(.fileWriteFileExists)
    }
    // Atomic rename on one filesystem never deletes the previous destination
    // before the replacement is ready. Staging files are always siblings.
    let result = source.withUnsafeFileSystemRepresentation { from in
        destination.withUnsafeFileSystemRepresentation { to in
            replace ? rename(from!, to!) : renamex_np(from!, to!, UInt32(RENAME_EXCL))
        }
    }
    if result != 0 { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno)) }
}

func transferDownloadFile(from source: URL, to destination: URL, move: Bool, replace: Bool = false) throws {
    let directory = destination.deletingLastPathComponent()
    let sourceAccess = source.startAccessingSecurityScopedResource()
    let destinationAccess = directory.startAccessingSecurityScopedResource()
    defer {
        if sourceAccess { source.stopAccessingSecurityScopedResource() }
        if destinationAccess { directory.stopAccessingSecurityScopedResource() }
    }
    let attributes = try FileManager.default.attributesOfItem(atPath: source.path)
    var remaining = (attributes[.size] as? NSNumber)?.int64Value ?? 0
    let renameOnly = move && sameStorageVolume(source, directory)
    try checkDownloadStorage(at: directory, remainingBytes: renameOnly ? 0 : remaining)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    if renameOnly {
        try commitDownloadFile(source, to: destination, replace: replace)
        return
    }
    let staging = directory.appendingPathComponent(".background_downloader-\(UUID().uuidString).partial")
    defer { try? FileManager.default.removeItem(at: staging) }
    guard FileManager.default.createFile(atPath: staging.path, contents: nil) else { throw CocoaError(.fileWriteUnknown) }
    let output = try FileHandle(forWritingTo: staging)
    defer { try? output.close() }
    try copyDownloadBytes(from: source, to: output, at: staging, remaining: &remaining)
    try output.synchronize()
    try output.close()
    try checkDownloadStorage(at: staging)
    try commitDownloadFile(staging, to: destination, replace: replace)
    if move { try FileManager.default.removeItem(at: source) }
}
