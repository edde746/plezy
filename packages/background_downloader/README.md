# A background file downloader and uploader for iOS, Android, MacOS, Windows and Linux

A robust, multi-platform background file transfer plugin for Flutter supporting background downloads, uploads, and data tasks across iOS, Android, MacOS, Windows, and Linux.

Uses native `URLSession` on iOS and MacOS, and `DownloadWorker` (WorkManager) / `JobService` (UIDT) on Android, ensuring transfers continue even when your app is in the background or terminated by the OS.

---

## 🌟 The Modern Transfer API (Recommended)

The easiest and most powerful way to use `background_downloader` is via the **Transfer API**.

On app startup (e.g. in `main()` or your top-level `initState()`), call `FileDownloader().start(autoCleanDatabase: true)` to activate persistent database tracking, automatically purge old task records, and reconcile transfers that completed or were interrupted while the app was suspended or closed. Then simply define a [`DownloadTask`](doc/downloads.md) or [`UploadTask`](doc/uploads.md), start it using `FileDownloader().transfers.start`, and receive a reactive [`Transfer`](doc/transfers.md) handle:

```dart
// 1. Activate database tracking & auto-cleanup on app launch (recommended)
await FileDownloader().start(autoCleanDatabase: true);

// 2. Configure notifications (recommended for userInitiated / UIDT tasks)
FileDownloader().configureNotification(
  running: const TaskNotification('Downloading', '{filename}'),
  complete: const TaskNotification('Complete', '{filename}'),
  progressBar: true,
  tapOpensFile: true,
);

// 3. Define the task with smart hints
final task = DownloadTask(
  url: 'https://example.com/large_video.mp4',
  filename: 'video.mp4',
  transferHints: {TransferHint.userInitiated, TransferHint.largeFile},
);

// 4. Start the transfer
final transfer = await FileDownloader().transfers.start(task);

// 5. Directly await the completed File:
final file = await transfer.file;
print('Downloaded to: ${file.path}');
```

### Why use `Transfer`?

- **Awaitable Futures**: Await [`transfer.file`](doc/transfers.md#awaitable-futures) for the completed `File`, [`transfer.result`](doc/transfers.md#awaitable-futures) for the `TaskStatusUpdate`, or [`transfer.responseBody`](doc/transfers.md#awaitable-futures) for server response text.
- **Reactive UI Notifiers**: Direct `ValueNotifier` bindings for Flutter widgets: `transfer.progressNotifier` (clean `0.0`–`1.0`), `transfer.statusNotifier`, `transfer.networkSpeedNotifier`, `transfer.timeRemainingNotifier`, and `transfer.notificationTapNotifier`.
- **Plug-and-Play Widgets**: Pre-built UI components including [`TransferProgressBar`](doc/transfers.md#transferprogressbar), [`TransferButton`](doc/transfers.md#transferbutton), and [`TransferListTile`](doc/transfers.md#transferlisttile).
- **Direct Controls**: Pause, resume, cancel, or allow cellular without managing task IDs: `await transfer.pause()`, `await transfer.resume()`, `await transfer.cancel()`.
- **Batch Processing**: Enqueue hundreds of transfers with aggregate progress using `FileDownloader().transfers.startAll(tasks, onProgress: ...)`.
- **Smart Auto-Tuning & Android 14+ UIDT**: Use [`TransferHint`](doc/transfers.md#6-smart-tuning-with-transferhint--android-14-uidt) (`userInitiated`, `largeFile`, `smallFile`, `lowPriority`, `useSuggestedFilename`, `binaryUpload`) to configure optimal priority, Android 14+ UIDT, and pause resilience automatically.
- **Notification Tap Integration**: React directly to user notification taps per transfer via `transfer.notificationTapNotifier` or open downloaded files automatically with `tapOpensFile: true`.
- **Scoping & Isolation**: Modularize downloads in plugins or sub-features with isolated namespaces using [`FileDownloader.scoped('my_feature')`](doc/transfers.md#7-scoping-with-filedownloaderscoped).
- **Network Resilience**: Automatic offline holding and resume, plus configurable stall detection (`stallTimeout`).

👉 **[Read the complete Transfers Guide](doc/transfers.md)**

---

## 🛠️ Lower-Level APIs

For specialized workflows or legacy integration, `FileDownloader` continues to provide direct lower-level methods:

### Direct Awaitable Download (`download`)
Execute a task and wait for completion in a single call with inline callbacks:

```dart
final result = await FileDownloader().download(
  task,
  onProgress: (progress) => print('Progress: ${progress * 100}%'),
  onStatus: (status) => print('Status: $status'),
);

if (result.status == TaskStatus.complete) {
  print('Download finished!');
}
```

### Queue & Event Streams (`enqueue` / `enqueueAll`)
For pipeline architectures where you monitor tasks centrally via a global stream or callbacks:

```dart
// 1. Listen centrally to task updates (typically in initState)
FileDownloader().updates.listen((update) {
  switch (update) {
    case TaskStatusUpdate():
      print('Task ${update.task.taskId} status: ${update.status}');
    case TaskProgressUpdate():
      print('Task ${update.task.taskId} progress: ${update.progress * 100}%');
  }
});

// 2. Start the downloader and activate persistent database tracking
FileDownloader().start();

// 3. Enqueue background tasks
final enqueued = await FileDownloader().enqueue(task);
```

---

## 📁 File Locations

To ensure file paths work robustly across platform restarts (especially on iOS and Android where container paths can change between app launches), the downloader uses a combination of `BaseDirectory`, `directory` (subdirectory) and `filename`:

* **`BaseDirectory`**: One of `.applicationDocuments`, `.temporary`, `.applicationSupport`, or `.applicationLibrary`.
* **`directory`**: An optional subdirectory within the base directory.
* **`filename`**: The name of the file (or `DownloadTask.suggestedFilename` / `'?'` to use the server's `Content-Disposition` header).

See [File Storage](doc/storage.md) for details on shared and scoped storage.

---

## 📚 Documentation Index

Check the **[Topic Index](doc/topic_index.md)** or specific guides:

* **[Transfers & High-Level API](doc/transfers.md)**: `Transfer` handles, reactive notifiers, UI widgets, batches, and scoping.
* **[Downloads](doc/downloads.md)**: Normal and parallel chunked downloads.
* **[Uploads](doc/uploads.md)**: Multipart, binary, and multi-file uploads.
* **[Notifications](doc/notifications.md)**: Native progress and completion notifications.
* **[Database & Central Monitoring](doc/database.md)**: Event streams, callbacks, and persistent database tracking.
* **[Status & Progress Updates](doc/status_updates.md)**: Status lifecycles and progress events.
* **[File Storage & Locations](doc/storage.md)**: Scoped storage, app directories, moving files to Photos/Downloads.
* **[Lifecycle & Queue Management](doc/lifecycle.md)**: Pausing, resuming, canceling, task queues, holding queues, and auth callbacks.
* **[Permissions](doc/permissions.md)**: Android & iOS permissions setup.
* **[Server Requests & Cookies](doc/requests.md)**: Immediate HTTP requests and cookie handling.
* **[Optional Parameters](doc/parameters.md)**: Headers, retries, priority, metadata, hints, and timeouts.
* **[Configuration](doc/CONFIG.md)**: Timeouts, proxies, bypass TLS, etc.
* **[Working with URIs](doc/URI.md)**: Content URIs, URL Bookmarks, and platform pickers.

---

## ⚙️ Initial Setup

No setup is required for Windows or Linux.

### Android
Requires Kotlin 2.1.0 or above. For modern Flutter projects, ensure your `android/settings.gradle` has:
```gradle
plugins {
    id "org.jetbrains.kotlin.android" version "2.1.0" apply false
}
```

### iOS
No special setup is required. By default iOS requires HTTPS connections (see [Apple ATS Configuration](https://developer.apple.com/documentation/security/preventing_insecure_network_connections) if HTTP is required).

### MacOS
Add the client network entitlement to `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:
```xml
<key>com.apple.security.network.client</key>
<true/>
```

---

## ⚠️ Platform Notes & Limitations

* **iOS**: Minimum iOS 14.0. Background transfers must complete within the system resource timeout (defaults to 4 hours, configurable via [CONFIG.md](doc/CONFIG.md)).
* **Android**: Minimum API 21. Standard background tasks are limited to 9 minutes by WorkManager. To allow longer downloads, set `allowPause: true` (or `TransferHint.largeFile` / `userInitiated`), which automatically resumes across 9-minute cycles, or set `priority: 0` on Android 14+ to use UIDT (see [parameters.md](doc/parameters.md#priority)).
* **OS Termination**: If the user forcefully swipes the app away from the iOS App Switcher or Android Recents, the OS may terminate background transfers without notification.
