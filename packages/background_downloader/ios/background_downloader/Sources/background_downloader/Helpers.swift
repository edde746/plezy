//
//  Helpers.swift
//  background_downloader
//
//  Created by Bram on 12/31/23.
//

import Foundation
import UIKit
import UniformTypeIdentifiers
import os.log

extension URL {
    /// Uses .appending for iOS 16 and up, and .appendingPathComponent
    /// for earlier versions
    func appendingPath(_ component: String, isDirectory: Bool = false) -> URL {
        if #available(iOS 16.0, *) {
            return appending(path: component, directoryHint: isDirectory ? .isDirectory : .notDirectory)
        } else {
            return appendingPathComponent(component, isDirectory: isDirectory)
        }
    }
    
    /// Excludes URL from backup
    mutating func setCloudBackup(exclude: Bool) throws {
        var resource = URLResourceValues()
        resource.isExcludedFromBackup = exclude
        try self.setResourceValues(resource)
    }
}

/// Returns the task's URL if it can be parsed, otherwise null
func validateUrl(_ task: Task) -> URL? {
    let url: URL?
    // encodingInvalidCharacters is only available when compiling with Xcode 15, which uses Swift version 5.9
#if swift(>=5.9)
    if #available(iOS 17.0, *) {
        url = URL(string: task.url, encodingInvalidCharacters: false)
    } else {
        url = URL(string: task.url)
    }
#else
    url = URL(string: task.url)
#endif
    return url
}

/// Converts the [map] to a [String:String] map with lowercased keys
func lowerCasedStringStringMap(_ map: [AnyHashable: Any]?) -> [String: String]? {
    if map == nil {return nil}
    var result: [String: String] = [:]
    for (key, value) in map! {
        if let stringKey = key as? String, let stringValue = value as? String {
            result[stringKey.lowercased()] = stringValue
        }
    }
    return result
}

/// Create a temp file that contains a subset of the [fileURL] based on [start] and [contentLength]
///
/// Returns the URL of the temp file, or nil if there was a problem (problem is logged)
func createTempFileWithRange(from fileURL: URL, start: UInt64, contentLength: UInt64) -> URL? {
    let fileManager = FileManager.default
    let tempDir = fileManager.temporaryDirectory
    let tempFileURL = tempDir.appendingPathComponent(UUID().uuidString) // Create a unique temporary file

    // Create the temporary file
    fileManager.createFile(atPath: tempFileURL.path, contents: nil, attributes: nil)
    guard let inputHandle = try? FileHandle(forReadingFrom: fileURL),
          let outputHandle = try? FileHandle(forWritingTo: tempFileURL) else {
        os_log("Cannot open file handles for partial upload temporary file creation", log: log, type: .error)
        return nil
    }
    defer {
        try? inputHandle.close()
        try? outputHandle.close()
    }
    let bufferSize = 1024 * 1024 // 1MB chunks
    var remainingBytes = contentLength
    do {
        // Seek to the start position
        try inputHandle.seek(toOffset: start)
        while remainingBytes > 0 {
            let bytesToRead = Int(min(UInt64(bufferSize), remainingBytes))
            guard let data = try inputHandle.read(upToCount: bytesToRead), !data.isEmpty else {
                break // EOF
            }
            try outputHandle.write(contentsOf: data)
            remainingBytes -= UInt64(data.count)
        }
    } catch {
        os_log("Cannot create temporary file for partial upload: %@", log: log, type: .error,
               error.localizedDescription)
        return nil
    }
    return tempFileURL
}


/**
 Returns mimetype of a filename based on its extension, or application/octet-stream
 */
func getMimeType(fromFilename filename: String) -> String {
    // Extract the file extension from the filename
    let fileExtension = (filename as NSString).pathExtension
    if let type = UTType(filenameExtension: fileExtension) {
        return type.preferredMIMEType ?? "application/octet-stream"
    }
    // Default MIME type if unable to determine
    return "application/octet-stream"
}

/// Returns the root view controller of the app, or nil if it cannot be found
/// Handles both the old AppDelegate (window) and the new SceneDelegate (connectedScenes) ways of getting the window
func getRootViewController() -> UIViewController? {
    if #available(iOS 13, *) {
        let window = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        if let root = window?.rootViewController {
            return root
        }
    }
    return UIApplication.shared.keyWindow?.rootViewController ?? UIApplication.shared.delegate?.window??.rootViewController
}
