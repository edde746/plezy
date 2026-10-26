//
//  Notifications.swift
//  background_downloader
//
//  Created on 3/19/23.
//

import Foundation
import UIKit
import os.log


/// NotificationContents
struct NotificationContents : Codable {
    let title: String
    let body: String
    
    init(json: [String:Any]) {
        title = json["title"] as? String ?? ""
        body = json["body"] as? String ?? ""
    }
}

struct NotificationConfig : Codable {
    let running: NotificationContents?
    let complete: NotificationContents?
    let error: NotificationContents?
    let paused: NotificationContents?
    let canceled: NotificationContents?
    let progressBar: Bool
    let tapOpensFile: Bool
    let groupNotificationId: String
}

enum NotificationType : Int {
    case running,
         complete,
         error,
         paused,
         canceled
}

/// Data and methods related to a notification for a group of tasks
actor GroupNotification {
    private static var registry: [String : GroupNotification] = [:]
    private static let registryLock = NSLock()

    /// Atomically gets (or creates and registers) the notification for this
    /// group. Serialised via a lock: this is called concurrently from
    /// [updateGroupNotification] for every task status update, and
    /// unsynchronised access to the shared dictionary corrupts it
    /// (EXC_BAD_ACCESS).
    static func groupNotification(named name: String, notificationConfig: NotificationConfig) -> GroupNotification {
        registryLock.lock()
        defer { registryLock.unlock() }
        if let existing = registry[name] {
            return existing
        }
        let created = GroupNotification(name: name, notificationConfig: notificationConfig)
        registry[name] = created
        return created
    }

    /// Removes the notification for this group from the registry
    static func remove(named name: String) {
        registryLock.lock()
        defer { registryLock.unlock() }
        registry.removeValue(forKey: name)
    }

    let name: String
    let notificationConfig: NotificationConfig
    
    private var notifications: [Task : NotificationType]
    
    init(name: String, notificationConfig: NotificationConfig) {
        self.name = name
        self.notificationConfig = notificationConfig
        self.notifications = [:]
    }
    
    /// NotificationId derived from group name
    var notificationId: String {
        get {
            return "groupNotification:\(name)"
        }
    }
    
    /// Total number of notifications in this group
    var numTotal: Int {
        get {
            return notifications.count
        }
    }
    
    /// Progress expressed as [numFinished]/[numTotal], except
    /// return 2.0 if numTotal is 0, to suggest that progress
    /// is undetermined
    var progress: Double {
        get {
            if numTotal == 0 {
                return 2.0
            } else {
                return Double(numFinished) / Double(numTotal)
            }
        }
    }
    
    /// Number of "finished" notifications in this group.
    ///
    /// A "finished" notification is one that is not .running,
    /// so includes .complete, .error, .paused
    ///
    var numFinished: Int {
        get {
            return notifications.filter { (_, v) in v != NotificationType.running }.count
        }
    }
    
    /// Number of "failed" notifications in this group.
    ///
    /// A "failed" notification is one of type .error
    ///
    var numFailed: Int {
        get {
            return notifications.filter { (_, v) in v == NotificationType.error }.count
        }
    }
    
    /// True if all tasks finished, regardless of outcome
    var isFinished: Bool {
        get {
            return numFinished == numTotal
        }
    }
    
    ///
    /// Return true if this group has an error
    ///
    var hasError: Bool {
        get {
            return numFailed > 0
        }
    }
    
    /// Returns a Set of running tasks in this notificationGroup
    var runningTasks: Set<Task> {
        get {
            return Set(notifications.filter { (_, notificationType) in
                notificationType == NotificationType.running
            }.keys)
        }
    }
    
    /// Int representing this group's state. If this number
    /// does not change, the group state did not change.
    ///
    /// State is determined by the number of finished notifications
    /// and the number of total notifications
    private var groupState: Int {
        get {
            return 1000 * numTotal + numFinished
        }
    }
    
    /// Update a [task] and [notificationType] to this group,
    /// and return True if this led to change in [groupState]
    func update(task: Task, notificationType: NotificationType) -> Bool {
        guard notifications[task] != notificationType else {
            return false
        }
        let priorState = groupState
        notifications[task] = notificationType
        return priorState != groupState
    }
}


enum NotificationCategory : String, CaseIterable {
    case runningWithPause = "running_with_pause";
    case runningWithoutPause = "running_without_pause";
    case paused = "paused"
    case complete = "complete"
    case error = "error"
    case canceled = "canceled"
}

/// List of all category identifiers
let ourCategories = NotificationCategory.allCases.map { $0.rawValue }

/// Update notification for this [task], based on [notificationType] and [notificationConfig]
func updateNotification(task: Task, notificationType: NotificationType, notificationConfig: NotificationConfig?) {
    _Concurrency.Task { @MainActor in // run using concurrency on main thread
        if (await getPermissionStatus(for: .notifications)) != .granted {
            return
        }
        if !BDPlugin.haveregisteredNotificationCategories {
            registerNotificationCategories()
            BDPlugin.haveregisteredNotificationCategories = true
        }
        let notificationCenter = UNUserNotificationCenter.current()
        if notificationConfig?.groupNotificationId.isEmpty ?? true {
            // regular notification
            var notification: NotificationContents?
            switch notificationType {
            case .running:
                notification = notificationConfig?.running
            case .complete:
                notification = notificationConfig?.complete
            case .error:
                notification = notificationConfig?.error
            case .paused:
                notification = notificationConfig?.paused
            case .canceled:
                notification = notificationConfig?.canceled
            }
            if notification == nil {
                return
            }
            let content = UNMutableNotificationContent()
            content.title = await replaceTokens(input: notification!.title, task: task)
            content.body = await replaceTokens(input: notification!.body, task: task)
            content.userInfo = [
                "task": jsonStringFor(task: task) ?? "",
                "notificationConfig": jsonStringFor(notificationConfig: notificationConfig!) ?? "",
                "notificationType": notificationType.rawValue
            ]
            addNotificationActions(task: task, notificationType: notificationType, content: content, notificationConfig: notificationConfig!)
            let request = UNNotificationRequest(identifier: task.taskId,
                                                content: content, trigger: nil)
            do {
                try await notificationCenter.add(request)
            } catch {
                os_log("Notification error %@", log: log, type: .info, error.localizedDescription)
            }
        } else {
            // group notification
            await updateGroupNotification(task: task, notificationType: notificationType, notificationConfig: notificationConfig!)
        }
    }
}


/**
 * Update notification for this [taskWorker] in group
 * [notificationGroupName] and type [notificationType].
 *
 * A group notification aggregates the state of all tasks in a group and
 * presents a notification based on that value
 */
func updateGroupNotification(
    task: Task,
    notificationType: NotificationType,
    notificationConfig: NotificationConfig
) async {
    let groupNotificationId = notificationConfig.groupNotificationId
    let groupNotification = GroupNotification.groupNotification(named: groupNotificationId, notificationConfig: notificationConfig)
    let stateChange = await groupNotification.update(task: task, notificationType: notificationType)
    if stateChange {
        // need to update the group notification
        let notificationCenter = UNUserNotificationCenter.current()
        let hasError = await groupNotification.hasError
        let isFinished = await groupNotification.isFinished
        var notification: NotificationContents?
        if isFinished {
            if hasError {
                notification = groupNotification.notificationConfig.error
            } else {
                notification = groupNotification.notificationConfig.complete
            }
        } else {
            notification = groupNotification.notificationConfig.running
        }
        guard let notification = notification else
        {
            // remove notification
            let notificationId = await groupNotification.notificationId
            notificationCenter.removeDeliveredNotifications(withIdentifiers: [notificationId])
            return
        }
        // need to show a notification
        let content = UNMutableNotificationContent()
        content.title = await replaceTokens(input: notification.title, task: task, progress: await groupNotification.progress, notificationGroup: groupNotification)
        content.body = await replaceTokens(input: notification.body, task: task, progress: await groupNotification.progress, notificationGroup: groupNotification)
        // check if the notification title or body have changed relative to what may
        // already be delivered, to avoid flashing notifications without change
        let existingNotifications = await notificationCenter.deliveredNotifications()
        let notificationId = await groupNotification.notificationId
        let previousNotification = existingNotifications.filter { 
            $0.request.identifier == notificationId
        }
        if previousNotification.isEmpty || previousNotification.first?.request.content.title != content.title || previousNotification.first?.request.content.body != content.body
        {
            content.categoryIdentifier = !isFinished
                ? NotificationCategory.runningWithoutPause.rawValue
                : (hasError ? NotificationCategory.error.rawValue : NotificationCategory.complete.rawValue)
            let request = UNNotificationRequest(identifier: await groupNotification.notificationId,
                                                content: content, trigger: nil)
            do {
                try await notificationCenter.add(request)
            } catch {
                os_log("Notification error %@", log: log, type: .info, error.localizedDescription)
            }
        }
        if isFinished {
            // remove only if not re-activated within 5 seconds
            try? await _Concurrency.Task.sleep(nanoseconds: 5_000_000_000)
            if await groupNotification.isFinished {
                GroupNotification.remove(named: groupNotificationId)
            }
        }
    }
}


/// Register that [task] was enqueued, with [success] or failure
///
/// This is only relevant for tasks that are part of a group notification, so that the
/// 'numTotal' count is based on enqueued tasks, not on running tasks (which may be limited
/// by holdingQueue or OS restrictions).
/// [notificationConfigJsonString] is only used to detect if this task has a group notification
func registerEnqueue(task: Task, notificationConfigJsonString: String?, success: Bool) async {
    guard let notificationConfigJsonString = notificationConfigJsonString,
          let notificationConfig = notificationConfigFrom(jsonString: notificationConfigJsonString),
          !notificationConfig.groupNotificationId.isEmpty
    else { return }
    await updateGroupNotification(task: task, notificationType: success ? .running : .error, notificationConfig: notificationConfig)
}



/// Add action buttons to the notification
///
/// Which button(s) depends on the [notificationType]. Action buttons are defined when defining the notification categories
func addNotificationActions(task: Task, notificationType: NotificationType, content: UNMutableNotificationContent, notificationConfig: NotificationConfig) {
    BDPlugin.propertyLock.withLock( {
        switch notificationType {
        case .running:
            content.categoryIdentifier = BDPlugin.taskIdsThatCanResume.contains(task.taskId) && notificationConfig.paused != nil ? NotificationCategory.runningWithPause.rawValue : NotificationCategory.runningWithoutPause.rawValue
        case .paused:
            content.categoryIdentifier = NotificationCategory.paused.rawValue
        case .complete:
            content.categoryIdentifier = NotificationCategory.complete.rawValue
        case .error:
            content.categoryIdentifier = NotificationCategory.error.rawValue
        case .canceled:
            content.categoryIdentifier = NotificationCategory.canceled.rawValue
        }
    })
}

/// Returns the notificationType related to this [status]
func notificationTypeForTaskStatus(status: TaskStatus) -> NotificationType {
    switch status {
        case .enqueued, .running: return NotificationType.running
        case .complete: return NotificationType.complete
        case .paused: return NotificationType.paused
        case .canceled: return NotificationType.canceled
        default: return NotificationType.error
    }
}

let displayNameRegEx = try! NSRegularExpression(pattern: "\\{displayName\\}", options: NSRegularExpression.Options.caseInsensitive)
let fileNameRegEx = try! NSRegularExpression(pattern: "\\{filename\\}", options: NSRegularExpression.Options.caseInsensitive)
let metaDataRegEx = try! NSRegularExpression(pattern: "\\{metadata\\}", options: NSRegularExpression.Options.caseInsensitive)
let progressRegEx = try! NSRegularExpression(pattern: "\\{progress\\}", options: NSRegularExpression.Options.caseInsensitive)
let networkSpeedRegEx = try! NSRegularExpression(pattern: "\\{networkSpeed\\}", options: NSRegularExpression.Options.caseInsensitive)
let timeRemainingRegEx = try! NSRegularExpression(pattern: "\\{timeRemaining\\}", options: NSRegularExpression.Options.caseInsensitive)
let numFinishedRegEx = try! NSRegularExpression(pattern: "\\{numFinished\\}", options: NSRegularExpression.Options.caseInsensitive)
let numFailedRegEx = try! NSRegularExpression(pattern: "\\{numFailed\\}", options: NSRegularExpression.Options.caseInsensitive)
let numTotalRegEx = try! NSRegularExpression(pattern: "\\{numTotal\\}", options: NSRegularExpression.Options.caseInsensitive)

/// Replace special tokens {filename} and {metadata} with their respective values
func replaceTokens(input: String, task: Task, progress: Double? = nil, notificationGroup: GroupNotification? = nil) async -> String {
    let inputString = NSMutableString()
    inputString.append(input)

    let unpacked = unpack(packedString: task.filename)
    let safeFilename = unpacked.filename ?? task.filename

    displayNameRegEx.replaceMatches(in: inputString, range: NSMakeRange(0, inputString.length), withTemplate: task.displayName)
    fileNameRegEx.replaceMatches(in: inputString, range: NSMakeRange(0, inputString.length), withTemplate: safeFilename)
    metaDataRegEx.replaceMatches(in: inputString, range: NSMakeRange(0, inputString.length), withTemplate: task.metaData)
    if (progress == nil) {
        progressRegEx.replaceMatches(in: inputString, range: NSMakeRange(0, inputString.length), withTemplate: "")}
    else {
        progressRegEx.replaceMatches(in: inputString, range: NSMakeRange(0, inputString.length), withTemplate: "\(Int(progress! * 100))%")
    }
    networkSpeedRegEx.replaceMatches(in: inputString, range: NSMakeRange(0, inputString.length), withTemplate: "-- MB/s")
    timeRemainingRegEx.replaceMatches(in: inputString, range: NSMakeRange(0, inputString.length), withTemplate: "--:--")
    if (notificationGroup != nil) {
        let numFinished = await notificationGroup!.numFinished
        let numFailed = await notificationGroup!.numFailed
        let numTotal = await notificationGroup!.numTotal
        numFinishedRegEx.replaceMatches(in: inputString, range: NSMakeRange(0, inputString.length), withTemplate: "\(numFinished)")
        numFailedRegEx.replaceMatches(in: inputString, range: NSMakeRange(0, inputString.length), withTemplate: "\(numFailed)")
        numTotalRegEx.replaceMatches(in: inputString, range: NSMakeRange(0, inputString.length), withTemplate: "\(numTotal)")
    }
    return inputString as String
}

/// Registers notification categories and actions for the different notification types
func registerNotificationCategories() {
    // get values from shared preferences
    let defaults = UserDefaults.standard
    let localize = defaults.dictionary(forKey: BDPlugin.keyConfigLocalize)
    
    // define the actions
    let cancelAction = UNNotificationAction(identifier: "cancel_action",
                                            title: localize?["Cancel"] as? String ?? "Cancel",
                                            options: [])
    let cancelInactiveAction = UNNotificationAction(identifier: "cancel_inactive_action",
                                                    title: localize?["Cancel"] as? String ?? "Cancel",
                                                    options: [])
    let pauseAction = UNNotificationAction(identifier: "pause_action",
                                           title: localize?["Pause"] as? String ?? "Pause",
                                           options: [])
    let resumeAction = UNNotificationAction(identifier: "resume_action",
                                            title: localize?["Resume"] as? String ?? "Resume",
                                            options: [])
    // Define the notification categories using these actions
    let runningWithPauseCategory =
    UNNotificationCategory(identifier: NotificationCategory.runningWithPause.rawValue,
                           actions: [cancelAction, pauseAction],
                           intentIdentifiers: [],
                           hiddenPreviewsBodyPlaceholder: "",
                           options: .customDismissAction)
    let runningWithoutPauseCategory =
    UNNotificationCategory(identifier: NotificationCategory.runningWithoutPause.rawValue,
                           actions: [cancelAction],
                           intentIdentifiers: [],
                           hiddenPreviewsBodyPlaceholder: "",
                           options: .customDismissAction)
    let pausedCategory =
    UNNotificationCategory(identifier: NotificationCategory.paused.rawValue,
                           actions: [cancelInactiveAction, resumeAction],
                           intentIdentifiers: [],
                           hiddenPreviewsBodyPlaceholder: "",
                           options: .customDismissAction)
    let completeCategory =
    UNNotificationCategory(identifier: NotificationCategory.complete.rawValue,
                           actions: [],
                           intentIdentifiers: [],
                           hiddenPreviewsBodyPlaceholder: "",
                           options: .customDismissAction)
    let errorCategory =
    UNNotificationCategory(identifier: NotificationCategory.error.rawValue,
                           actions: [],
                           intentIdentifiers: [],
                           hiddenPreviewsBodyPlaceholder: "",
                           options: .customDismissAction)
    let canceledCategory =
    UNNotificationCategory(identifier: NotificationCategory.canceled.rawValue,
                           actions: [],
                           intentIdentifiers: [],
                           hiddenPreviewsBodyPlaceholder: "",
                           options: .customDismissAction)
    // Register the notification type.
    let notificationCenter = UNUserNotificationCenter.current()
    notificationCenter.setNotificationCategories([runningWithPauseCategory, runningWithoutPauseCategory, pausedCategory, completeCategory, errorCategory, canceledCategory])
}

/// Returns a JSON string for this NotificationConfig, or nil
func jsonStringFor(notificationConfig: NotificationConfig) -> String? {
    let jsonEncoder = JSONEncoder()
    guard let jsonResultData = try? jsonEncoder.encode(notificationConfig)
    else {
        return nil
    }
    return String(data: jsonResultData, encoding: .utf8)
    
}

/// Returns a NotificationConfig from the supplied jsonString, or nil
func notificationConfigFrom(jsonString: String) -> NotificationConfig? {
    let decoder = JSONDecoder()
    let notificationConfig: NotificationConfig? = try? decoder.decode(NotificationConfig.self, from: (jsonString).data(using: .utf8)!)
    return notificationConfig
}
