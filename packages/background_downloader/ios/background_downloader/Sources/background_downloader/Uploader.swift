//
//  Uploader.swift
//  background_downloader
//
//  Created on 2/11/23.
//

import Foundation
import os.log

enum StreamError: Error {
    case Closed
}



/// Uploader associated with one URLSessionUploadTask
public class Uploader : NSObject, URLSessionTaskDelegate, StreamDelegate {
    
    var task: Task
    let outputFilename: String
    var contentDispositionString = ""
    var contentTypeString = ""
    var fieldsString = ""
    var totalBytesWritten: Int64 = 0
    static let boundary = "-----background_downloader-akjhfw281onqciyhnIk"
    let lineFeed = "\r\n"
    let asciiOnly = try! NSRegularExpression(pattern: "^[\\x00-\\x7F]+$")
    let jsonString = try! NSRegularExpression(pattern: "^\\s*(\\{.*\\}|\\[.*\\])\\s*$")
    let newlineRegExp = try! NSRegularExpression(pattern: "\r\n|\r|\n")
    let bufferSize = 2 << 13
    
    
    /// Initialize an Uploader for this Task
    init(task: Task) {
        self.task = task
        outputFilename = NSUUID().uuidString
    }
    
    
    /// Creates the multipart file so it can be uploaded
    ///
    /// Returns true if successful, false otherwise (cleaning up any partial file on failure).
    public func createMultipartFile() -> Bool {
        if writeMultipartFile() {
            return true
        }
        try? FileManager.default.removeItem(at: outputFileUrl())
        return false
    }

    /// Writes the multipart file, returning true if successful
    private func writeMultipartFile() -> Bool {
        // create the output file
        FileManager.default.createFile(atPath: outputFileUrl().path,  contents:Data(" ".utf8), attributes: nil)
        guard let fileHandle = try? FileHandle(forWritingTo: outputFileUrl()) else {
            os_log("Could not open temporary file %@", log: log, type: .error, outputFileUrl().path)
            return false
        }
        // field portion of the multipart, all in one string
        // multiple values should be encoded as '"value1", "value2", ...'
        let multiValueRegEx = try! NSRegularExpression(pattern: #"^(?:"[^"]+"\s*,\s*)+"[^"]+"$"#, options: [])
        for entry in task.fields ?? [:] {
            let value = entry.value
            let fullRange = NSRange(location: 0, length: value.utf16.count)
            // Check if the value matches the multi-value format
            if multiValueRegEx.firstMatch(in: value, options: [], range: fullRange) != nil {
                // Extract multiple values from entry.value
                let valueMatchRegEx = try! NSRegularExpression(pattern: #""([^"]+)""#, options: [])
                valueMatchRegEx.enumerateMatches(in: value, options: [], range: fullRange) { match, _, _ in
                    if let matchRange = match?.range(at: 1), // Capture group 1
                       let swiftRange = Range(matchRange, in: value) {
                        let matchedString = String(value[swiftRange])
                        fieldsString += fieldEntry(name: entry.key, value: matchedString)
                    }
                }
            } else {
                // Handle single value for key
                fieldsString += fieldEntry(name: entry.key, value: entry.value)
            }
        }
        if (!writeFields(fileHandle: fileHandle)) {
            os_log("Could not write to temporary file %@", log: log, type: .error, outputFileUrl().path)
            return false
        }
        // File portion of the multi-part
        // Assumes list of files. If only one file, that becomes a list of length one.
        // For each file, determine contentDispositionString, contentTypeString
        // and file length, so that we can calculate total size of upload
        let separator = "\(lineFeed)--\(Uploader.boundary)\(lineFeed)" // between files
        let terminator = "\(lineFeed)--\(Uploader.boundary)--\(lineFeed)" // after last file
        let maybeFileUri = uriFromStringValue(maybePacked: task.filename)
        let maybeDecodedFileUri = maybeFileUri != nil ? decodeToFileUrl(uri: maybeFileUri!) : nil
        guard let filePath = getFilePath(for: task) else {return false}
        let filesData = filePath.isEmpty
        ? extractFilesData(task: task) // MultiUpload case
        : [(task.fileField!,maybeDecodedFileUri?.path ?? filePath, task.mimeType!)] // one file Upload case
        for (fileField, path, mimeType) in filesData {
            if !FileManager.default.fileExists(atPath: path) {
                os_log("File to upload does not exist at %@", log: log, type: .error, path)
                return false
            }
            let derivedFilename = path.components(separatedBy: "/").last!
            if filesData.count == 1 && task.taskType != "MultiUploadTask" {
                // only for single file uploads do we set the task's filename property
                let newTask = task.copyWith(filename: maybeFileUri != nil
                                            ? pack(filename: derivedFilename, uri: maybeFileUri!)
                                            : derivedFilename)
                storeModifiedTask(task: newTask)
            }
            let contentDispositionString =
            "Content-Disposition: form-data; name=\"\(browserEncode(fileField))\"; "
            + "filename=\"\(browserEncode(derivedFilename))\"\(lineFeed)"
            let resolvedMimeType = mimeType.isEmpty ? getMimeType(fromFilename: path) : mimeType
            let contentTypeString = "Content-Type: \(resolvedMimeType)\(lineFeed)\(lineFeed)"
            let fileUrl = URL(fileURLWithPath: path)
            guard let inputStream = InputStream(url: fileUrl) else {
                os_log("Could not open file to upload at %@", log: log, type: .error, path)
                return false
            }
            if (!writeFileBytes(fileHandle: fileHandle, inputStream: inputStream, contentDisposition: contentDispositionString, contentType: contentTypeString)) {
                os_log("Could not upload file at %@", log: log, type: .error, path)
                return false
            }
            if (!writeText(fileHandle: fileHandle, text: path == filesData.last!.1 ?
                           terminator : separator)) {
                os_log("Could not write separator for file at %@", log: log, type: .error, path)
                return false
            }
        }
        return true
    }
    
    /// Return the URL of the generated outputfile with multipart data
    ///
    /// Callers outside this class should only use this after calling
    /// createMultipartFile, and only when that returns true
    func outputFileUrl() -> URL {
        return FileManager.default.temporaryDirectory.appendingPath(outputFilename)
    }
    
    /// Write form fields
    ///
    /// Returns true if successful, false otherwise
    private func writeFields(fileHandle: FileHandle) -> Bool {
        // construct the preamble
        return writeText(fileHandle: fileHandle, text: "\(fieldsString)--\(Uploader.boundary)\(lineFeed)")
    }
    
    /// Write the data bytes from the provided inputStream to the fileHandle
    ///
    /// Retruns true if successful, false otherwise
    private func writeFileBytes(fileHandle: FileHandle, inputStream: InputStream, contentDisposition: String, contentType: String) -> Bool {
        // multipart file header
        if !(writeText(fileHandle: fileHandle, text: contentDisposition) &&
             writeText(fileHandle: fileHandle, text: contentType)) {
            return false
        }
        // file bytes
        inputStream.open()
        while inputStream.hasBytesAvailable {
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer {
                buffer.deallocate()
            }
            let bytesRead = inputStream.read(buffer, maxLength: bufferSize)
            if bytesRead < 0 {
                // Stream error occured
                os_log("Error reading from file for taskId %@", log: log, type: .error, task.taskId)
                inputStream.close()
                return false
            } else if bytesRead == 0 {
                inputStream.close()
                return true
            }
            let data = Data.init(bytesNoCopy: buffer, count: bytesRead, deallocator: .none)
            do {
                try fileHandle.write(contentsOf: data)
            } catch {
                os_log("Error writing to file for taskId %@: %@", log: log, type: .error, task.taskId, error.localizedDescription)
                inputStream.close()
                return false
            }
        }
        inputStream.close()
        return true
    }
    
    /// Write text to the [fileHandle] and return true if successful
    private func writeText(fileHandle: FileHandle, text: String) -> Bool {
        guard let epilogue = text.data(using: .utf8) else {
            return false
        }
        do {
            try fileHandle.write(contentsOf: epilogue)
        } catch {
            os_log("Error writing to file for taskId %@: %@", log: log, type: .error, task.taskId, error.localizedDescription)
            return false
        }
        totalBytesWritten += Int64(epilogue.count)
        return true
    }
    
    
    /// Returns the multipart entry for one field name/value pair
    private func fieldEntry(name: String, value: String) -> String {
        return "--\(Uploader.boundary)\(lineFeed)\(headerForField(name: name, value: value))\(value)\(lineFeed)"
    }
    
    /// Returns the header string for a field
    ///
    /// The return value is guaranteed to contain only ASCII characters
    private func headerForField(name: String, value: String) -> String {
         var header = "Content-Disposition: form-data; name=\"\(browserEncode(name))\""
        if isJsonString(value) {
            header = "\(header)\r\n" +
            "Content-Type: application/json; charset=utf-8"
        } else if !isPlainAscii(value) {
            header = "\(header)\r\n" +
            "Content-Type: text/plain; charset=utf-8\r\n" +
            "Content-Transfer-Encoding: binary"
        }
        return "\(header)\r\n\r\n"
    }
    
    
    /// Returns whether [string] is composed entirely of ASCII-compatible characters
    private func isPlainAscii(_ string: String)-> Bool {
        let result = asciiOnly.matches(in: string,
                                       range: NSMakeRange(0, (string as NSString).length))
        return !result.isEmpty
    }
    
    /// Returns whether [string] is a JSON formatted string
    private func isJsonString(_ string: String)-> Bool {
        let result = jsonString.matches(in: string,
                                        range: NSMakeRange(0, (string as NSString).length))
        return !result.isEmpty
    }
    
    /// Encode [value] in the same way browsers do
    private func browserEncode(_ value: String)-> String {
        // http://tools.ietf.org/html/rfc2388 mandates some complex encodings for
        // field names and file names, but in practice user agents seem not to
        // follow this at all. Instead, they URL-encode `\r`, `\n`, and `\r\n` as
        // `\r\n`; URL-encode `"`; and do nothing else (even for `%` or non-ASCII
        // characters). We follow their behavior.
        let newlinesReplaced = newlineRegExp.stringByReplacingMatches(
            in: value,
            options: [],
            range: NSMakeRange(0, (value as NSString).length), withTemplate: "%0D%0A")
        return newlinesReplaced.replacingOccurrences(of: "\"", with: "%22")
    }
    
}


