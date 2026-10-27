//
//  SharedStorage.swift
//  background_downloader
//
//  Created on 3/26/23.
//

import Foundation
import os.log
import Photos
import Combine

public enum SharedStorage: Int {
    case downloads,
         images,
         video,
         audio,
         files,
         external
}

/// Check if photos permissions have been granted
///
/// if [addOnly] is true, checks .addOnly permission, otherwise checks
/// full .readWrite permission.
///
/// Returns true if granted

/// .addOnly requires the "NSPhotoLibraryAddUsageDescription" to be set in Info.plist
/// .readWrite requires the "NSPhotoLibraryUsageDescription" to be set in Info.plist
/// Prior to iOS 14, use NSPhotoLibraryUsageDescription
public func photosAccessAuthorized(addOnly: Bool) async -> Bool {
    let permissionType: PermissionType = addOnly ? .iosAddToPhotoLibrary : .iosChangePhotoLibrary
    var authStatus = await getPermissionStatus(for: permissionType)
    if (authStatus == .granted) {
        return true
    }
    return false
}

/// Move file at [filePath] to shared storage [destination] with optional [directory]
public func moveToSharedStorage(filePathOrUriString: String, destination: SharedStorage, directory: String, asUriString: Bool) async -> String? {
    let fileUrl = URL(string: filePathOrUriString)
    let filePath = fileUrl?.scheme == "file" ? fileUrl!.path : filePathOrUriString
    guard FileManager().fileExists(atPath: filePath)
    else {
        os_log("Cannot move to shared storage: file %@ does not exist", log: log, type: .error, filePathOrUriString)
        return nil
    }
    switch destination {
        case .images, .video:
            return await moveToPhotoLibrary(filePath: filePath, destination: destination)
        default:
        return moveToFakeSharedStorage(filePath: filePath, destination: destination, directory: directory, asUriString: asUriString)
    }
}

/// Saves the file at [filePath] to the photolibrary [destination] and removes the original
///
/// The returned path is the 'localId'
private func moveToPhotoLibrary(filePath: String, destination: SharedStorage) async -> String? {
    var localId: String?
    guard await photosAccessAuthorized(addOnly: true) else {
        os_log("Cannot move to shared storage: permission to add to photos library denied by user", log: log, type: .info)
        return nil
    }
#if BYPASS_PERMISSION_IOSADDTOPHOTOLIBRARY
    return nil
#else
    let fileURL = URL(fileURLWithPath: filePath)
    do {
        // PhotoKit owns the actual destination and asynchronous write. It does
        // not expose a volume URL or progress callback: only preflight is possible.
        let size = try FileManager.default.attributesOfItem(atPath: filePath)[.size] as? NSNumber
        try checkDownloadStorage(at: FileManager.default.temporaryDirectory, remainingBytes: size?.int64Value ?? 0)
    } catch {
        os_log("Cannot move to Photos Library: %@", log: log, type: .error, error.localizedDescription)
        return nil
    }
    let result = await withCheckedContinuation { continuation in
        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequest = destination == .video ? PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL) :
            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL)
            localId = assetChangeRequest?.placeholderForCreatedAsset?.localIdentifier
        })
        { (success, error: Error?) in
            guard success, let unwrappedId = localId else {
                if let unwrappedError = error {
                    os_log("Could not save to Photos Library: %@", log: log, type: .info, String(describing: unwrappedError))
                }
                continuation.resume(returning: "")
                return
            }
            try? FileManager.default.removeItem(at: fileURL)
            continuation.resume(returning: unwrappedId)
        }
    }
    return result.isEmpty ? nil : result
#endif
}

/// Returns the path to the file at [filePath] in shared storage [destination] subdir [directory], or null
public func pathInSharedStorage(filePath: String, destination: SharedStorage, directory: String, asUriString: Bool) async -> String? {
    if destination == .images || destination == .video {
        return await pathInPhotoLibrary(localId: filePath, destination: destination)
    }
    // regular 'faked' sharedStorage
    guard let directory = try? directoryForSharedStorage(destination: destination, directory: directory) else {
        os_log("Cannot determine path in shared storage: no permission for directory %@", log: log, type: .info, directory)
        return nil
    }
    let destUrl = directory.appendingPath((filePath as NSString).lastPathComponent)
    return asUriString ? destUrl.absoluteString : destUrl.path
}

/// Returns the file path associated with the [localId] in the Photos library
///
/// This requires .readWrite PhotoLibrary access, and therefore the filepath is NOT returned
/// when moving a photo or video to the PhotoLibrary using [moveToSharedStorage].
/// Instead, the local identifier is returned, and if the full file path is required, this identifier needs to
/// be passed to the [pathInSharedStorage] call
///
/// Returns the path to the photo/video asset, or nil if unsuccessful
public func pathInPhotoLibrary(localId: String, destination: SharedStorage) async -> String? {
    guard await photosAccessAuthorized(addOnly: false) else {
        os_log("Cannot get path in shared storage: permission to access photos library denied by user", log: log, type: .info)
        return nil
    }
#if BYPASS_PERMISSION_IOSCHANGEPHOTOLIBRARY
    return nil
#else
    let assetResult = PHAsset.fetchAssets(withLocalIdentifiers: [localId], options: nil)
    guard let asset = assetResult.firstObject else {
        os_log("Photos asset not found", log: log, type: .info)
        return nil
    }
    let result = await withCheckedContinuation { continuation in
        asset.requestContentEditingInput(with: nil, completionHandler: { input, _ in
            if (destination == .video) {
                if let urlAsset = input?.audiovisualAsset as? AVURLAsset {
                    continuation.resume(returning: urlAsset.url.path)
                } else {
                    continuation.resume(returning: "")
                }
            } else {
                continuation.resume(returning: input?.fullSizeImageURL?.path ?? "")
            }
        })
    }
    return result.isEmpty ? nil : result
#endif
}


/// Returns the URL of the directory associated with the [destination] and [directory], or nil
public func directoryForSharedStorage(destination: SharedStorage, directory: String) throws ->  URL? {
    var dir: String
    switch destination {
        case .downloads:
            dir = "Downloads"
        case .audio:
            dir = "Music"
        case .images, .video:
            os_log("Destination .images and .video should use PhotoLibrary functions", log: log, type: .error)
            return nil
        case .files, .external:
            os_log("Destination .files and .external are not supported on iOS", log: log, type: .info)
            return nil
            
    }
    let documentsURL =
    try? FileManager.default.url(for: FileManager.SearchPathDirectory.documentDirectory,
                                 in: .userDomainMask,
                                 appropriateFor: nil,
                                 create: true)
    return directory.isEmpty
    ? documentsURL?.appendingPath(dir, isDirectory: true)
    : documentsURL?.appendingPath(dir, isDirectory: true).appendingPath(directory, isDirectory: true)
}

private func moveToFakeSharedStorage(filePath: String, destination: SharedStorage, directory: String, asUriString: Bool) -> String? {
    let fileUrl = NSURL(fileURLWithPath: filePath)
    guard let directory = try? directoryForSharedStorage(destination: destination, directory: directory) else {
        os_log("Cannot move to shared storage: no permission for directory %@", log: log, type: .error, directory)
        return nil
    }
    if !FileManager.default.fileExists(atPath: directory.path) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            os_log("Cannot move to shared storage: failed to create directory %@: %@", log: log, type: .error, directory.path, error.localizedDescription)
            return nil
        }
    }
    let destUrl = directory.appendingPath((filePath as NSString).lastPathComponent)
    do {
        try transferDownloadFile(from: fileUrl as URL, to: destUrl, move: true, replace: true)
    } catch {
        os_log("Failed to move file %@ to %@: %@", log: log, type: .error, filePath, destUrl.path, error.localizedDescription)
        return nil
    }
    return asUriString ? destUrl.absoluteString : destUrl.path
}
