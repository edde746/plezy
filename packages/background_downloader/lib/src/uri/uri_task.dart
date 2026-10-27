part of '../task.dart';

/// Interface for tasks that operate with [Uri] instead of file and directory
/// paths.
///
/// This allows the Uri version of the different tasks to be testable using
/// `task is UriTask`
abstract interface class UriTask {
  /// Returns the URI of the directory associated with the task, or null
  Uri? get directoryUri;

  /// Returns the URI of the file associated with the task, or null
  Uri? get fileUri;
}

/// Mixin that implements [UriTask] with the standard implementation, which
/// implements the getters for [directoryUri] and [fileUri], and overrides
/// the getters for [directory] and [filename] because the actual contents
/// of those properties contain encoded information that should not be
/// interpreted directly
base mixin _UriTaskMixin on Task implements UriTask {
  @override
  Uri? get directoryUri =>
      super.directory.isNotEmpty ? Uri.tryParse(super.directory) : null;

  @override
  Uri? get fileUri {
    final (:filename, :uri) = unpack(super.filename);
    return uri;
  }

  @override
  String get directory => '';

  @override
  String get filename {
    final (:filename, :uri) = unpack(super.filename);
    return filename ?? '';
  }

  /// Creates JSON map of this object
  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'filename': super.filename, // replace with raw string
    'directory': super.directory, // replace with raw string
  };
}

final class UriDownloadTask extends DownloadTask with _UriTaskMixin {
  /// Creates [UriDownloadTask] using a URI as the destination directory
  ///
  /// For Android:
  /// Content URIs are related to the Android Storage Framework that makes it
  /// easier to get access to a file system location without the need for
  /// app permissions, provided the user has chosen that location using a
  /// file picker.  They follow the content:// scheme, and can be obtained
  /// by calling [UriUtils.pickDirectory].
  ///
  /// For other platforms:
  /// File URIs follow the file:// scheme and point to a destination on the
  /// file system. A file:// URI is returned from [UriUtils.pickDirectory] on platforms
  /// other than Android.
  ///
  /// The [directoryUri] can be obtained using the
  /// [directoryUri] getter. [directory] will always return the empty string
  ///
  /// Note that the result of [Task.filePath] is undefined when using a URI, as
  /// not all Uri types can be converted to a file name
  UriDownloadTask({
    super.taskId,
    required super.url,
    super.urlQueryParameters,
    String? filename,
    super.headers,
    super.httpRequestMethod,
    super.post,
    required Uri directoryUri,
    super.group,
    super.updates,
    super.requiresWiFi,
    super.retries,
    super.allowPause,
    super.priority,
    super.metaData,
    super.displayName,
    super.creationTime,
    super.options,
    super.transferHints,
    super.notificationConfig,
    super.stallTimeout,
  }) : super(
         baseDirectory: BaseDirectory.root,
         directory: directoryUri.toString(),
         filename: switch ((filename, directoryUri)) {
           (DownloadTask.suggestedFilename, _) =>
             DownloadTask.suggestedFilename,
           (null, Uri(scheme: 'file')) => () {
             final randomFilename = Random().nextInt(1 << 32).toString();
             return pack(
               randomFilename,
               Uri.file(
                 '${directoryUri.path}/$randomFilename',
                 windows: Platform.isWindows,
               ),
             );
           }(),
           (String filename, Uri(scheme: 'file')) => pack(
             filename,
             Uri.file(
               '${directoryUri.path}/$filename',
               windows: Platform.isWindows,
             ),
           ),
           _ => filename,
         },
       ) {
    assert(
      Task.allowedUriSchemes.contains(directoryUri.scheme),
      'Directory URI scheme must be one of ${Task.allowedUriSchemes}',
    );
    if (_pathSeparatorRegExp.hasMatch(filename ?? '')) {
      throw ArgumentError('Filename cannot contain path separators');
    }
  }

  /// Creates [Task] object from JsonMap
  ///
  /// Only used by subclasses. Use [Task.createFromJson] to create a properly
  /// subclassed [Task] from the [json]
  UriDownloadTask.fromJson(super.json) : super.fromJson();

  @override
  UriDownloadTask copyWith({
    String? taskId,
    String? url,
    String? filename,
    Map<String, String>? headers,
    String? httpRequestMethod,
    Object? post,
    Uri? directoryUri,
    String? directory,
    BaseDirectory? baseDirectory,
    String? group,
    Updates? updates,
    bool? requiresWiFi,
    int? retries,
    int? retriesRemaining,
    bool? allowPause,
    int? priority,
    String? metaData,
    String? displayName,
    DateTime? creationTime,
    TaskOptions? options,
    Set<TransferHint>? transferHints,
    TaskNotificationConfig? notificationConfig,
    Duration? stallTimeout,
  }) => UriDownloadTask(
    taskId: taskId ?? this.taskId,
    url: url ?? this.url,
    filename: filename ?? this.filename,
    headers: headers ?? this.headers,
    httpRequestMethod: httpRequestMethod ?? this.httpRequestMethod,
    post: post ?? this.post,
    directoryUri: directoryUri ?? this.directoryUri ?? Uri.base,
    group: group ?? this.group,
    updates: updates ?? this.updates,
    requiresWiFi: requiresWiFi ?? this.requiresWiFi,
    retries: retries ?? this.retries,
    allowPause: allowPause ?? this.allowPause,
    priority: priority ?? this.priority,
    metaData: metaData ?? this.metaData,
    displayName: displayName ?? this.displayName,
    creationTime: creationTime ?? this.creationTime,
    options: options ?? this.options,
    transferHints: transferHints ?? this.transferHints,
    notificationConfig: notificationConfig ?? this.notificationConfig,
    stallTimeout: stallTimeout ?? this.stallTimeout,
  )..retriesRemaining = retriesRemaining ?? this.retriesRemaining;

  @override
  String get taskType => 'UriDownloadTask';
}

final class UriUploadTask extends UploadTask with _UriTaskMixin {
  /// Creates [UploadTask] from a URI
  ///
  /// The [fileUri] will can be obtained
  /// using [fileUri] (do not access the [filename] property directly).
  /// If a [filename] argument is supplied in this constructor,
  /// it will be used, otherwise the filename will be derived from the URL
  UriUploadTask({
    required Uri fileUri,
    super.taskId,
    required super.url,
    super.urlQueryParameters,
    String? filename,
    super.headers,
    String? httpRequestMethod,
    super.post,
    super.fileField = 'file',
    String? mimeType,
    Map<String, String>? fields,
    super.group,
    super.updates,
    super.requiresWiFi,
    super.retries,
    super.priority,
    super.metaData,
    super.displayName,
    super.creationTime,
    super.options,
    super.transferHints,
    super.notificationConfig,
    super.stallTimeout,
  }) : super(
         baseDirectory: BaseDirectory.root,
         filename: filename != null
             ? pack(filename, fileUri)
             : fileUri.toString(),
         httpRequestMethod: httpRequestMethod ?? 'POST',
         mimeType: mimeType ?? 'application/octet-stream',
         fields: fields ?? {},
       ) {
    assert(
      Task.allowedUriSchemes.contains(fileUri.scheme),
      'URI scheme must be one of ${Task.allowedUriSchemes}',
    );
  }

  /// Creates [Task] object from JsonMap
  ///
  /// Only used by subclasses. Use [Task.createFromJson] to create a properly
  /// subclassed [Task] from the [json]
  UriUploadTask.fromJson(super.json) : super.fromJson();

  @override
  UriUploadTask copyWith({
    Uri? fileUri,
    String? taskId,
    String? url,
    String? filename,
    Map<String, String>? headers,
    String? httpRequestMethod,
    Object? post,
    String? fileField,
    String? mimeType,
    Map<String, String>? fields,
    String? directory,
    BaseDirectory? baseDirectory,
    String? group,
    Updates? updates,
    bool? requiresWiFi,
    int? priority,
    int? retries,
    int? retriesRemaining,
    bool? allowPause,
    String? metaData,
    String? displayName,
    DateTime? creationTime,
    TaskOptions? options,
    Set<TransferHint>? transferHints,
    TaskNotificationConfig? notificationConfig,
    Duration? stallTimeout,
  }) => UriUploadTask(
    fileUri: fileUri ?? this.fileUri ?? Uri.base,
    taskId: taskId ?? this.taskId,
    url: url ?? this.url,
    filename: filename ?? this.filename,
    headers: headers ?? this.headers,
    httpRequestMethod: httpRequestMethod ?? this.httpRequestMethod,
    post: post as String? ?? this.post,
    fileField: fileField ?? this.fileField,
    mimeType: mimeType ?? this.mimeType,
    fields: fields ?? this.fields,
    group: group ?? this.group,
    updates: updates ?? this.updates,
    requiresWiFi: requiresWiFi ?? this.requiresWiFi,
    priority: priority ?? this.priority,
    retries: retries ?? this.retries,
    metaData: metaData ?? this.metaData,
    displayName: displayName ?? this.displayName,
    creationTime: creationTime ?? this.creationTime,
    options: options ?? this.options,
    transferHints: transferHints ?? this.transferHints,
    notificationConfig: notificationConfig ?? this.notificationConfig,
    stallTimeout: stallTimeout ?? this.stallTimeout,
  )..retriesRemaining = retriesRemaining ?? this.retriesRemaining;

  @override
  String get taskType => 'UriUploadTask';
}
