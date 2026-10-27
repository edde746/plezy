//
//  Callbacks.swift
//  background_downloader
//
//  Created by Bram on 10/26/24.
//

import Foundation
import Flutter
import os.log

import UIKit

/// Helper function to get the callback channel with retry
private func getCallbackChannel() async -> FlutterMethodChannel? {
    var retries = 0
    while BDPlugin.callbackChannel == nil && retries < 5 {
        try? await _Concurrency.Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        retries += 1
    }
    return BDPlugin.callbackChannel
}

/// Invoke a callback in Dart (via the method channel) and return the returned Task value or nil
private func invokeCallback(withMethod methodName: String, forTask task: Task) async -> Any? {
    guard let callbackChannel = await getCallbackChannel() else {
        os_log("Could not invoke %{public}@ for taskId %@: callbackChannel not set", log: log, type: .error, methodName, task.taskId)
        return nil
    }
    return await withCheckedContinuation { continuation in
        os_log("Invoking %{public}@ for taskId %@", log: log, type: .info, methodName, task.taskId)
        callbackChannel.invokeMethod(methodName, arguments: jsonStringFor(task: task), result: { result in
            guard let jsonString = result as? String else {
                if let error = result as? FlutterError {
                    os_log("Error invoking %{public}@: %@", log: log, type: .error, methodName, error.message ?? "nil")
                }
                continuation.resume(returning: nil)
                return
            }
            if methodName == "beforeTaskStartCallback" {
                continuation.resume(returning: try? JSONDecoder().decode(TaskStatusUpdate.self, from: (jsonString).data(using: .utf8)!))
            }
            else {
                continuation.resume(returning: taskFrom(jsonString: jsonString))
            }
        })
    }
}

/// Invoke the onTaskStartCallback in Dart (via the method channel) and return the returned Task value or nil
func invokeBeforeTaskStartCallback(task: Task) async -> TaskStatusUpdate? {
    return await invokeCallback(withMethod: "beforeTaskStartCallback", forTask: task) as? TaskStatusUpdate
}

/// Invoke the onTaskStartCallback in Dart (via the method channel) and return the returned Task value or nil
func invokeOnTaskStartCallback(task: Task) async -> Task? {
    return await invokeCallback(withMethod: "onTaskStartCallback", forTask: task) as? Task
}

/// Invoke the onAuthCallback in Dart (via the method channel) and return the returned Task value or nil
func invokeOnAuthCallback(task: Task) async -> Task? {
    return await invokeCallback(withMethod: "onAuthCallback", forTask: task) as? Task
}

/// Invoke the onTaskFinishedCallback in Dart (via the method channel) and return true if successful
func invokeOnTaskFinishedCallback(taskStatusUpdate: TaskStatusUpdate) async -> Bool {
    guard let callbackChannel = await getCallbackChannel() else {
        os_log("Could not invoke onTaskFinishedCallback: callbackChannel not set", log: log, type: .error)
        return false
    }
    return await withCheckedContinuation { continuation in
        callbackChannel.invokeMethod("onTaskFinishedCallback", arguments: jsonStringFor(taskStatusUpdate: taskStatusUpdate), result: { result in
            if let error = result as? FlutterError {
                os_log("Error invoking onTaskFinishedCallback: %@", log: log, type: .error, error.message ?? "nil")
                continuation.resume(returning: false)
            }  else {
                continuation.resume(returning: true)
            }
        })
    }
}
