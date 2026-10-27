//
//  Permissions.swift
//  background_downloader
//
//  Created by Bram on 11/30/23.
//

import Foundation
import Photos
import UserNotifications
import os.log

public enum PermissionType: Int {
    case notifications,
         androidSharedStorage,
         iosAddToPhotoLibrary,
         iosChangePhotoLibrary
}

public enum PermissionStatus: Int {
    case undetermined,
         denied,
         granted,
         partial,
         requestError }

/// Get current permission status for this [request]
///
/// Unknown permissions resturn .granted
public func getPermissionStatus(for permissionType: PermissionType) async -> PermissionStatus {
    if permissionType == .notifications {
#if BYPASS_PERMISSION_NOTIFICATIONS
        return .denied
#else
        let center = UNUserNotificationCenter.current()
        let status = (await center.notificationSettings()).authorizationStatus
        switch status {
            case .authorized:
                return .granted
                
            case .denied:
                return .denied
                
            case .notDetermined:
                return .undetermined
                
            default:
                return .partial
        }
#endif
    }
    if (permissionType == .iosAddToPhotoLibrary || permissionType == .iosChangePhotoLibrary) {
        let status: PHAuthorizationStatus
        if permissionType == .iosAddToPhotoLibrary {
#if BYPASS_PERMISSION_IOSADDTOPHOTOLIBRARY
            status = .denied
#else
            if #available(iOS 14, *) {
                status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            } else {
                status = PHPhotoLibrary.authorizationStatus()
            }
#endif
        } else { // readwrite
#if BYPASS_PERMISSION_IOSCHANGEPHOTOLIBRARY
            status = .denied
#else
            if #available(iOS 14, *) {
                status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            } else {
                status = PHPhotoLibrary.authorizationStatus()
            }
#endif
        }
        switch status {
            case .authorized:
                return .granted
                
            case .denied:
                return .denied
                
            case .notDetermined:
                return .undetermined
                
            default:
                return .partial
        }
    }
    return .granted // default return if irrelevant permission for iOS
}

/// Request permission from user and return the [PermissionResult]
///
/// Unknown permissions are granted
public func requestPermission(for permissionType: PermissionType) async -> PermissionStatus {
    if permissionType == .notifications {
#if BYPASS_PERMISSION_NOTIFICATIONS
        return .denied
#else
        let center = UNUserNotificationCenter.current()
        guard let granted = try? await center.requestAuthorization(options: [.alert]) else {
            return .requestError
        }
        return granted ? .granted : .denied
#endif
    }
    if (permissionType == .iosAddToPhotoLibrary || permissionType == .iosChangePhotoLibrary) {
        let status: PHAuthorizationStatus
        if permissionType == .iosAddToPhotoLibrary {
#if BYPASS_PERMISSION_IOSADDTOPHOTOLIBRARY
            status = .denied
#else
            if #available(iOS 14, *) {
                status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            } else {
                status = await withCheckedContinuation { continuation in
                    PHPhotoLibrary.requestAuthorization {status in
                        continuation.resume(returning: status)
                    }
                }
            }
#endif
        } else { // readwrite
#if BYPASS_PERMISSION_IOSCHANGEPHOTOLIBRARY
            status = .denied
#else
            if #available(iOS 14, *) {
                status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            } else {
                status = await withCheckedContinuation { continuation in
                    PHPhotoLibrary.requestAuthorization {status in
                        continuation.resume(returning: status)
                    }
                }
            }
#endif
        }
        switch status {
            case .authorized:
                return .granted
                
            case .denied:
                return .denied
                
            case .notDetermined:
                return .undetermined
                
            default:
                return .partial
        }
    }
    return .granted
    
}
