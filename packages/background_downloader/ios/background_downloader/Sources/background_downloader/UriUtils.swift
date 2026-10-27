//
//  UriUtils.swift
//  background_downloader
//
//  Created by Bram on 1/18/25.
//

import Flutter
import UIKit
import UniformTypeIdentifiers
import MobileCoreServices
import PhotosUI
import os.log



public class UriUtilsMethodCallHelper: NSObject,
                                       FlutterPlugin,
                                       UIDocumentPickerDelegate,
                                       PHPickerViewControllerDelegate {
    private var flutterResult: FlutterResult?
    private var persistedUriPermission: Bool = false
    private var multipleAllowed: Bool = false
    private var allowVideos = false
    private var localFileUrls: [String] = [] // for media picker
    private var accessedSecurityScopedUrls: Set<URL> = Set()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.bbflight.background_downloader.uriutils", binaryMessenger: registrar.messenger())
        let instance = UriUtilsMethodCallHelper()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "pickDirectory":
            pickDirectory(call, result: result)
        case "pickFiles":
            pickFiles(call, result: result)
        case "createDirectory":
            createDirectory(call, result: result)
        case "activateUri":
            activateUri(call, result: result)
        case "getFileBytes":
            getFileBytes(call, result: result)
        case "copyFile":
            copyFile(call, result: result)
        case "moveFile":
            moveFile(call, result: result)
        case "deleteFile":
            deleteFile(call, result: result)
        case "openFile":
            openFile(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func pickDirectory(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [Any],
              let persistedUriPermission = args[2] as? Bool else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for pickDirectory", details: nil))
            return
        }
        
        self.persistedUriPermission = persistedUriPermission
        self.flutterResult = result
        
        var startLocation: URL? = nil
        
        if let startLocationUriString = args[1] as? String,
           let startLocationUri = decodeToFileUrl(uriString: startLocationUriString) {
            startLocation = startLocationUri
        } else if let startLocationOrdinal = args[0] as? Int,
                  let sharedStorage = SharedStorage(rawValue: startLocationOrdinal) {
            startLocation = getInitialDirectoryUrl(location: sharedStorage)
        }
        
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.folder], asCopy: false)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        
        // Set the initial directory if available
        if #available(iOS 14.0, *), let startLocation = startLocation {
            documentPicker.directoryURL = startLocation
        }
        
        // Present the document picker
        if let rootViewController = getRootViewController() {
            rootViewController.present(documentPicker, animated: true, completion: nil)
        } else {
            completeFlutterResult(FlutterError(code: "NO_ROOT_VIEW_CONTROLLER", message: "Could not find root view controller", details: nil))
        }
    }
    
    
    private func pickFiles(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [Any],
              let multipleAllowed = args[3] as? Bool,
              let persistedUriPermission = args[4] as? Bool else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for pickFiles", details: nil))
            return
        }
        
        self.persistedUriPermission = persistedUriPermission
        self.multipleAllowed = multipleAllowed
        self.flutterResult = result
        
        var startLocation: URL? = nil
        
        if let startLocationUriString = args[1] as? String,
           let startLocationUri = decodeToFileUrl(uriString: startLocationUriString) {
            startLocation = startLocationUri
        } else if let startLocationOrdinal = args[0] as? Int,
                  let sharedStorage = SharedStorage(rawValue: startLocationOrdinal) {
            if sharedStorage == .images || sharedStorage == .video {
                pickMedia(startLocation: sharedStorage)
                return
            }
            startLocation = getInitialDirectoryUrl(location: sharedStorage)
        }
        
        // Convert allowed extensions to UTTypes
        var allowedContentTypes: [UTType] = []
        if let allowedExtensions = args[2] as? [String] {
            for ext in allowedExtensions {
                if let utType = UTType(filenameExtension: ext) {
                    allowedContentTypes.append(utType)
                }
            }
        }
        if allowedContentTypes.isEmpty {
            allowedContentTypes = [UTType.item]  // Allow all types if no valid extensions are provided
        }
        
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes, asCopy: false)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = multipleAllowed
        
        // Set the initial directory if available
        if let startLocation = startLocation {
            documentPicker.directoryURL = startLocation
        }
        
        // Present the document picker
        if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
            rootViewController.present(documentPicker, animated: true, completion: nil)
        } else {
            completeFlutterResult(FlutterError(code: "NO_ROOT_VIEW_CONTROLLER", message: "Could not find root view controller", details: nil))
        }
    }
    
    /**
     * Launches the photo picker to select one or more media files (images or videos).
     *
     * Called only from [pickFiles] where argument
     * parsing has already happened
     *
     * @param startLocation The shared storage location to start the picker in (images or video).
     *
     * The result posted back is either a list of URIs as a String, or null (if the user has
     * cancelled the picker) or an error
     */
    private func pickMedia(startLocation: SharedStorage) {
        var configuration = PHPickerConfiguration()
        configuration.filter = startLocation == .images ? .images : .videos
        configuration.selectionLimit = multipleAllowed ? 0 : 1  // 0 means unlimited
        let pickerViewController = PHPickerViewController(configuration: configuration)
        pickerViewController.delegate = self
        
        if let rootViewController = getRootViewController() {
            rootViewController.present(pickerViewController, animated: true, completion: nil)
        } else {
            completeFlutterResult(FlutterError(code: "NO_ROOT_VIEW_CONTROLLER", message: "Could not find root view controller", details: nil))
        }
    }
    
    
    /**
     * Creates a new directory at the specified path within the given parent directory URI.
     * The parent directory URI must be resolvable to a file:// URI.  Supports creating intermediate directories.
     *
     * - Parameters:
     *   - call: The Flutter method call.  The arguments are expected to be a list
     *     containing: the parent directory URI (String), the new directory name (String),
     *     and a boolean indicating whether to request persisted URI permission.
     *   - result: The Flutter result callback.  On success, the URI of the newly
     *     created directory (String) is returned.  On failure, a `FlutterError` is returned.
     */
    private func createDirectory(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [Any],
              let parentDirectoryUriString = args[0] as? String,
              let newDirectoryName = args[1] as? String,
              let persistedUriPermission = args[2] as? Bool,
              let parentDirectoryUri = decodeToFileUrl(uriString: parentDirectoryUriString)
        else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for createDirectory", details: nil))
            return
        }
        
        do {
            let newDirectoryURL = parentDirectoryUri.appendingPathComponent(newDirectoryName, isDirectory: true)
            
            // Ensure we have access to the parent directory before attempting to create a subdirectory.
            if !parentDirectoryUri.startAccessingSecurityScopedResource() {
                result(FlutterError(code: "ACCESS_DENIED", message: "Failed to access parent directory: \(parentDirectoryUri)", details: nil))
                return
            }
            accessedSecurityScopedUrls.insert(parentDirectoryUri)
            
            // Create the directory
            try FileManager.default.createDirectory(at: newDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            
            // If persistence is requested, we will also need to stop accessing and deallocate the URL when done.
            if persistedUriPermission {
                accessedSecurityScopedUrls.insert(newDirectoryURL)
                // Return the persisted URI (bookmark)
                let bookmarkUri = try createBookmarkUriFromUrl(fileURL: newDirectoryURL)
                result(bookmarkUri.absoluteString)
            } else {
                // Return the regular file URI
                result(newDirectoryURL.absoluteString)
            }
            
        } catch {
            result(FlutterError(code: "CREATE_DIRECTORY_FAILED", message: "Failed to create directory: \(error.localizedDescription)", details: nil))
        }
    }
    
    /**
     * Activates a previously accessed directory or file (represented by a URI string)
     * by calling `startAccessingSecurityScopedResource`.  This is necessary on iOS
     * to regain access to resources outside the app's sandbox that were previously
     * granted access (e.g., through a document picker).  Also decodes `urlbookmark://`
     * and `media://` URIs to `file://` URIs.
     *
     * - Parameters:
     *   - call: The Flutter method call.  The argument is expected to be the URI string.
     *   - result: The Flutter result callback.  On success, the (potentially decoded)
     *     `file://` URI string is returned. On failure (e.g., invalid URI, access denied),
     *      a `FlutterError` is returned. If the URI is decoded, it is also added to
     *      `accessedSecurityScopedUrls`
     */
    private func activateUri(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let uriString = call.arguments as? String,
              let uri = decodeToFileUrl(uriString: uriString)
        else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for activateUri", details: nil))
            return
        }
        // Start accessing the security-scoped resource.
        if !uri.startAccessingSecurityScopedResource() {
            completeFlutterResult(FlutterError(code: "ACCESS_DENIED", message: "activateUri failed to access security-scoped resource: \(uri)", details: nil))
            return
        }
        accessedSecurityScopedUrls.insert(uri)
        result(uri.absoluteString)
    }
    
    /**
     * Retrieves the file data (bytes) for a given URI string.
     *
     * - Parameters:
     *    - call: The Flutter method call containing the arguments. The argument is
     *      expected to be the URI string. This string will be decoded using `decodeToFileUrl`.
     *    - result: The Flutter result callback to be invoked with the resul---t.  On success
     *      the file data as a `FlutterStandardTypedData` is returned. On failure,
     *      a `FlutterError` is returned.
     */
    private func getFileBytes(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let uriString = call.arguments as? String,
              let fileUrl = decodeToFileUrl(uriString: uriString) else {
            result(FlutterError(code: "INVALID_URI", message: "Invalid or unresolvable URI: \(call.arguments)", details: nil))
            return
        }
        
        // If this is a bookmark URI, we need to start accessing the security-scoped resource.
        if uriString.starts(with: "urlbookmark://") {
            if !fileUrl.startAccessingSecurityScopedResource() {
                result(FlutterError(code: "ACCESS_DENIED", message: "Failed to access security-scoped resource: \(fileUrl)", details: nil))
                return
            }
            accessedSecurityScopedUrls.insert(fileUrl)
        }
        
        do {
            let fileData = try Data(contentsOf: fileUrl)
            result(FlutterStandardTypedData(bytes: fileData))
        } catch {
            result(FlutterError(code: "FILE_READ_ERROR", message: "Failed to read file data: \(error.localizedDescription)", details: nil))
        }
    }
    
    /**
     * Copies the file at the given source URI to the destination URI.
     * Both the source and destination URIs must be resolvable to file:// URIs.
     *
     * - Parameters:
     *   - call: The Flutter method call containing the arguments.  The arguments
     *     are expected to be a list containing two strings: the source URI and
     *     the destination URI.
     *   - result: The Flutter result callback to be invoked with the result
     *     of the copy operation.  On success, the destination URI string is
     *     returned.  On failure, a `FlutterError` is returned.
     */
    private func copyFile(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [Any],
              let sourceUriString = args[0] as? String,
              let destinationUriString = args[1] as? String,
              let sourceUrl = decodeToFileUrl(uriString: sourceUriString), // Decode to file URL
              let destinationUrl = decodeToFileUrl(uriString: destinationUriString) // Decode to file URL
        else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for copyFile", details: nil))
            return
        }
        do {
            try transferDownloadFile(from: sourceUrl, to: destinationUrl, move: false)
            result(destinationUrl.absoluteString)
        } catch {
            result(FlutterError(code: "COPY_FAILED", message: "Failed to copy file: \(error.localizedDescription)", details: nil))
        }
    }
    
    /**
     * Moves the file at the given source URI to the destination URI.
     * Both the source and destination URIs must be resolvable to file:// URIs.
     *
     * - Parameters:
     *   - call: The Flutter method call containing the arguments.  The arguments
     *     are expected to be a list containing two strings: the source URI and
     *     the destination URI.
     *   - result: The Flutter result callback to be invoked with the result
     *     of the move operation.  On success, the destination URI string is
     *     returned.  On failure, a `FlutterError` is returned.
     */
    private func moveFile(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [Any],
              let sourceUriString = args[0] as? String,
              let destinationUriString = args[1] as? String,
              let sourceUrl = decodeToFileUrl(uriString: sourceUriString), // Decode!
              let destinationUrl = decodeToFileUrl(uriString: destinationUriString) // Decode!
        else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for moveFile", details: nil))
            return
        }
        do {
            try transferDownloadFile(from: sourceUrl, to: destinationUrl, move: true)
            result(destinationUrl.absoluteString)
        } catch {
            result(FlutterError(code: "MOVE_FAILED", message: "Failed to move file: \(error.localizedDescription)", details: nil))
        }
    }
    
    /**
     * Deletes the file at the given URI. The URI must be resolvable to a file:// URI.
     *
     * - Parameters:
     *   - call: The Flutter method call containing the arguments. The argument
     *     is expected to be a string representing the file URI.
     *   - result: The Flutter result callback.  `true` is returned on success,
     *     and a `FlutterError` is returned on failure.
     */
    private func deleteFile(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let uriString = call.arguments as? String,
              let fileUrl = decodeToFileUrl(uriString: uriString),
              fileUrl.scheme == "file" else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid or non-file URI provided for deleteFile", details: nil))
            return
        }
        do {
            try FileManager.default.removeItem(at: fileUrl)
            result(true)
        } catch {
            result(FlutterError(code: "DELETE_FILE_FAILED", message: "Failed to delete file: \(error.localizedDescription)", details: nil))
        }
    }
    
    /**
     * Opens the file at the given URI using the system's default application for the file type.
     *
     * - Parameters:
     *   - call: The Flutter method call containing the arguments. The arguments are
     *     expected to be a list where the first element is the URI string, and the
     *     optional second element is the MIME type (as a String).
     *   - result: The Flutter result callback. `true` is returned on successful launch,
     *     and a `FlutterError` is returned on failure.
     */
    private func openFile(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [Any],
              let uriString = args[0] as? String,
              let mimeType = args[1] as? String?,
              let fileUrl = decodeToFileUrl(uriString: uriString)
        else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for openFile", details: nil))
            return
        }
        let filePath = fileUrl.path
        if !FileManager.default.fileExists(atPath: fileUrl.path) {
            os_log("File does not exist at %@", log: log, type: .info, filePath)
            result(FlutterError(code: "FILE_NOT_FOUND", message: "File does not exist at \(filePath)", details: nil))
            return
        }
        result(doOpenFile(filePath: filePath, mimeType: mimeType != nil ? mimeType : getMimeType(fromFilename: filePath)))
    }
    
    /**
     * Complete the flutter result callback and destroy the result object
     */
    private func completeFlutterResult(_ result: Any?) {
        self.flutterResult?(result)
        self.flutterResult = nil
    }
    
    // MARK: - UIDocumentPickerDelegate
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        if multipleAllowed {
            var resultUrls: [String] = []
            
            for url in urls {
                // Start accessing the security-scoped resource.
                if !url.startAccessingSecurityScopedResource() {
                    // Handle access error (e.g., by skipping this URL and logging an error message)
                    os_log("Failed to access security-scoped resource for %@", log: log, type: .info, url.absoluteString)
                    continue
                }
                accessedSecurityScopedUrls.insert(url)
                
                let pickedUrl: URL
                if persistedUriPermission {
                    do {
                        pickedUrl = try createBookmarkUriFromUrl(fileURL: url)
                    } catch {
                        completeFlutterResult(FlutterError(code: "CREATE_PERSISTED_URI_FAILED", message: "Failed to create persisted URI: \(error.localizedDescription)", details: nil))
                        return
                    }
                } else {
                    pickedUrl = url
                }
                
                resultUrls.append(pickedUrl.absoluteString)
            }
            
            completeFlutterResult(resultUrls)
        } else {
            // Single selection
            guard let url = urls.first else {
                completeFlutterResult(nil) // User cancelled
                return
            }
            
            // Start accessing the security-scoped resource.
            if !url.startAccessingSecurityScopedResource() {
                completeFlutterResult(FlutterError(code: "ACCESS_DENIED", message: "Failed to access security-scoped resource: \(url)", details: nil))
                return
            }
            accessedSecurityScopedUrls.insert(url)
            
            let pickedUrl: URL
            if persistedUriPermission {
                do {
                    pickedUrl = try createBookmarkUriFromUrl(fileURL: url)
                } catch {
                    completeFlutterResult(FlutterError(code: "CREATE_PERSISTED_URI_FAILED", message: "Failed to create persisted URI: \(error.localizedDescription)", details: nil))
                    return
                }
            } else {
                pickedUrl = url
            }
            completeFlutterResult(pickedUrl.absoluteString)
        }
    }
    
    
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        completeFlutterResult(nil)
    }
    
    
    // MARK: PHickerViewControllerelegate
    
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard !results.isEmpty else {
            completeFlutterResult(nil)
            return
        }
        let group = DispatchGroup()
        for result in results {
            group.enter()
            let itemProvider = result.itemProvider
            
            // Determine the preferred order based on what is allowed
            var typeIdentifiers: [String] = []
            if allowVideos {
                typeIdentifiers.append(UTType.movie.identifier)
            }
            typeIdentifiers.append(UTType.image.identifier)
            
            var handled = false
            for typeIdentifier in typeIdentifiers {
                if itemProvider.hasRepresentationConforming(toTypeIdentifier: typeIdentifier) {
                    handleLoadedFile(for: itemProvider, typeIdentifier: typeIdentifier, group: group)
                    handled = true
                    break // Break after handling the first matching type
                }
            }
            
            // Leave the group if no suitable representation was found
            if !handled {
                group.leave()
            }
        }
        // after all files have been copied, post the result
        group.notify(queue: .main) {
            picker.dismiss(animated: true)
            if self.localFileUrls.isEmpty {
                self.completeFlutterResult(nil)
            } else {
                self.completeFlutterResult(self.localFileUrls)
            }
        }
    }
    
    /// Handles the loading of a file representation from an `NSItemProvider`.
    ///
    /// This function attempts to load a file of the specified `typeIdentifier` from the given `itemProvider`.
    /// If successful, it copies the file to the app's local storage and appends the local file URL to the `localFileUrls` array.
    /// This function is designed to be used within the `PHPickerViewControllerDelegate`'s `didFinishPicking` method to process selected assets.
    ///
    /// - Parameters:
    ///   - itemProvider: The `NSItemProvider` representing the asset to load.
    ///   - typeIdentifier: The UTI (Uniform Type Identifier) representing the desired file type (e.g., `public.image`, `public.movie`).
    ///   - group: The `DispatchGroup` to which the asynchronous file loading operation belongs. `group.leave()` is called when the operation is completed (either successfully or with an error).
    ///
    /// - Important: This function uses an escaping closure to handle the asynchronous loading of the file.
    ///   The `localFileUrls` array is a class property and is modified within the escaping closure.
    private func handleLoadedFile(for itemProvider: NSItemProvider, typeIdentifier: String, group: DispatchGroup) {
        itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { [weak self] url, error in
            guard let self = self, let url = url, error == nil else {
                group.leave()
                return
            }
            let localUrl = self.copyFileToLocalStorage(url: url)
            if let localUrl = localUrl {
                self.localFileUrls.append(localUrl.absoluteString)
            }
            group.leave()
        }
    }
    
    /// Copies a file from the provided URL into the app's temporary storage directory, returning the new URL relative to the storage root. This URL will have the "support" scheme and
    /// itspath is the last pathsegment of the file URL. It will be converted to a proper file:// URL using `decodeToFileUrl`
    ///
    /// This function creates a unique filename for the copied file to avoid collisions. The file is stored in a location that is:
    /// 1. **Private to the application:** Other apps cannot access this directory.
    /// 2. **Temporary:** The system may delete files in this directory when the app is not running to free up space. Your app should be prepared to recreate these files as needed.
    /// 3. **Not backed up:** Files in this directory are not backed up to iCloud or other backup services.
    /// 4. **Persistent across app launches:** The relative file paths are consistent between app launches.
    ///
    /// - Parameter url: The source URL of the file to copy. This should be a file URL (e.g., obtained from a `PHPickerResult`).
    /// - Returns: The relative path (as a String) to the copied file within the temporary storage directory if the copy is successful, otherwise `nil`.
    ///            You can reconstruct the full URL using `constructPersistentFileURL(for:)`.
    private func copyFileToLocalStorage(url: URL) -> URL? {
        let fileManager = FileManager.default
        
        // Use the Application Support directory, which is private to the app but persistent.
        // Create a custom subdirectory for temporary files.
        guard let storageDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("com.bbflight.downloader.media", isDirectory: true) else {
            completeFlutterResult(FlutterError(code: "PICK_FAILED", message: "Could not find Application Support directory", details: nil))
            return nil
        }
        
        // Ensure the storage directory exists
        do {
            try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            completeFlutterResult(FlutterError(code: "PICK_FAILED", message: "Error creating storage directory: \(error)", details: nil))
            return nil
        }
        
        // Create a unique filename
        let uniqueFilename = "\(UUID().uuidString).\(url.pathExtension)"
        let destinationURL = storageDirectory.appendingPathComponent(uniqueFilename)
        
        do {
            // Copy the file from source to destination, and return the media URI to this location
            try transferDownloadFile(from: url, to: destinationURL, move: false)
            return URL(string: "media://support/\(destinationURL.lastPathComponent)")
        } catch {
            completeFlutterResult(FlutterError(code: "PICK_FAILED", message: "Error copying file: \(error)", details: nil))
            return nil
        }
    }
    
    
    // MARK: - Helper Functions
    
    private func getInitialDirectoryUrl(location: SharedStorage) -> URL? {
        switch location {
        case SharedStorage.downloads:
            return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        case SharedStorage.images:
            return FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first
        case SharedStorage.video:
            return FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first
        case SharedStorage.audio:
            return FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first
        case SharedStorage.files:
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        default:
            return nil
        }
    }
    
    // Stop accessing security-scoped resources when appropriate.
    deinit {
        // Iterate through all stored URLs and stop accessing the security-scoped resources.
        for url in accessedSecurityScopedUrls {
            url.stopAccessingSecurityScopedResource()
        }
    }
}


/// Packs `filename` and `uri` into a single String
///
/// use `unpack` to retrieve the filename and uri from the packed String
func pack(filename: String, uri: URL) -> String {
    return ":::\(filename)::::::\(uri.absoluteString):::"
}

/// Unpacks `packedString` into a (filename, uri) tuple. If this is not a packed
/// string, returns the original `packedString` as (filename, nil) or,
/// if it is a Uri as (nil, the uri)
func unpack(packedString: String) -> (filename: String?, uri: URL?) {
    let regex = try! NSRegularExpression(pattern: ":::([\\s\\S]*?)::::::([\\s\\S]*?):::")
    let range = NSRange(packedString.startIndex..<packedString.endIndex, in: packedString)
    
    if let match = regex.firstMatch(in: packedString, range: range) {
        let filenameRange = match.range(at: 1)
        let uriStringRange = match.range(at: 2)
        
        if filenameRange.location != NSNotFound && uriStringRange.location != NSNotFound {
            let filename = String(packedString[Range(filenameRange, in: packedString)!])
            let uriString = String(packedString[Range(uriStringRange, in: packedString)!])
            
            if let uri = URL(string: uriString), uri.scheme != nil {
                return (filename: filename, uri: uri)
            } else {
                return (filename: filename, uri: nil)
            }
        }
    } else {
        if let uri = URL(string: packedString), uri.scheme != nil {
            return (filename: nil, uri: uri)
        }
    }
    return (filename: packedString, uri: nil)
}

/// Returns the Uri represented by `maybePacked`, or nil if the String is not a
/// valid Uri or packed Uri string.
///
/// `maybePacked` should be a full Uri string, or a packed String containing
/// a Uri (see `pack`)
func uriFromStringValue(maybePacked: String) -> URL? {
    let unpacked = unpack(packedString: maybePacked)
    return unpacked.uri
}

/// Returns true if `maybePacked` is a valid Uri or packed Uri string.
///
/// `maybePacked` should be a full Uri string, or a packed String containing
/// a Uri (see `pack`)
func containsUri(maybePacked: String) -> Bool {
    return uriFromStringValue(maybePacked: maybePacked) != nil
}

/// Creates a urlboomark://authority/ URL containing encoded data representing the bookmark for this URL, which
/// can then be used later
private func createBookmarkUriFromUrl(fileURL: URL) throws -> URL {
    let bookmarkData = try fileURL.bookmarkData(options: .suitableForBookmarkFile, includingResourceValuesForKeys: nil, relativeTo: nil)
    let bookmarkDataBase64 = bookmarkData.base64EncodedString()
    let bookmarkUriString = "urlbookmark://authority/\(bookmarkDataBase64)"
    guard let bookmarkUri = URL(string: bookmarkUriString) else {
        throw NSError(domain: "UriUtilsMethodCallHelper", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create bookmark URI from '\(bookmarkUriString)'"])
    }
    return bookmarkUri
}

/**
 * Decodes a URI parameter on iOS.
 *
 * If the URI string starts with `urlbookmark://authority/`, it decodes the base64 encoded bookmark data to a file URL
 * If the URI string starts with `media://support/` it will convert it to a file URL relateive to the applicationSupport directory
 * Otherwise, it returns the original URI as a URL.
 *
 * - Parameter uriString: The URI string to decode.
 * - Returns: The decoded `URL` or `nil` if the URI string is invalid or the bookmark data cannot be resolved.
 */
private func decodeToFileUrl(uriString: String) -> URL? {
    guard let uri = URL(string: uriString) else { return nil }
    if uri.scheme == "urlbookmark" {
        // Decode base64 bookmark data
        let base64String = String(uri.path.dropFirst())
        guard let bookmarkData = Data(base64Encoded: base64String) else {
            return nil
        }
        do {
            var isStale = false
            let resolvedUrl = try URL(resolvingBookmarkData: bookmarkData, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &isStale)
            
            if isStale {
                os_log("Warning: Bookmark data is stale for %@", log: log, type: .info, resolvedUrl.absoluteString)
                return nil
            }
            
            // Access to resolved URLs that are not persisted, is started when they are actually used
            // (i.e. when creating a subdirectory in it, or picking it)
            // And stopped in the deinit
            return resolvedUrl
        } catch {
            os_log("Error resolving bookmark data: %@", log: log, type: .info, error.localizedDescription)
            return nil
        }
    } else if uri.scheme == "media" {
        guard let storageDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("com.bbflight.downloader.media", isDirectory: true) else {
            os_log("Could not determine application support directory - required to decode support:// scheme URL", log: log, type: .error)
            return nil
        }
        return storageDirectory.appendingPathComponent(uri.lastPathComponent, isDirectory: false)
    } else {
        // Regular file URL
        return uri
    }
}

/**
 Returns a file URI, or nil if not possible.
 
 Decodes a bookmark URI or a media scheme uri
 */
func decodeToFileUrl(uri: URL) -> URL? {
    return uri.scheme == "file" ? uri : decodeToFileUrl(uriString: uri.absoluteString)
}
