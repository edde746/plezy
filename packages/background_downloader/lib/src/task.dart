import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'file_downloader.dart';
import 'models.dart';
import 'options/task_options.dart';
import 'transfer_hint.dart';
import 'uri/uri_helpers.dart';
import 'utils.dart';
import 'web_downloader.dart'
    if (dart.library.io) 'desktop/desktop_downloader.dart';

part 'uri/uri_task.dart';

final _log = Logger('FileDownloader');
final _random = Random();

/// A server Request
///
/// An equality test on a [Request] is an equality test on the [url]
base class Request {
  /// List of valid HTTP methods
  final validHttpMethods = ['GET', 'POST', 'HEAD', 'PUT', 'DELETE', 'PATCH'];

  /// String representation of the url, urlEncoded
  final String url;

  /// potential additional headers to send with the request
  final Map<String, String> headers;

  /// HTTP request method to use
  final String httpRequestMethod;

  /// Set [post] to make the request using POST instead of GET.
  /// In the constructor, [post] must be one of the following:
  /// - a String: POST request with [post] as the body, encoded in utf8
  /// - a Map: will be jsonEncoded to a String and set as the POST body
  /// - a List of bytes: will be converted to a String using String.fromCharCodes
  ///   and set as the POST body
  /// - a List: map will be jsonEncoded to a String and set as the POST body
  ///
  /// The field [post] will be a String
  final String? post;

  /// Maximum number of retries the downloader should attempt
  ///
  /// Defaults to 0, meaning no retry will be attempted
  final int retries;

  /// Number of retries remaining
  int retriesRemaining;

  /// Time at which this request was first created
  final DateTime creationTime;

  /// Creates a [Request]
  ///
  /// [url] must not be encoded and can include query parameters
  /// [urlQueryParameters] may be added and will be appended to the [url]
  /// [headers] an optional map of HTTP request headers
  /// [post] if set, uses POST instead of GET. Post must be one of the
  /// following:
  /// - a String: POST request with [post] as the body, encoded in utf8
  /// - a Map: will be jsonEncoded to a String and set as the POST body
  /// - a List of bytes: will be converted to a String using String.fromCharCodes
  ///   and set as the POST body
  /// - a List: map will be jsonEncoded to a String and set as the POST body
  ///
  /// [retries] if >0 will retry a failed download this many times
  Request({
    required String url,
    Map<String, String>? urlQueryParameters,
    Map<String, String>? headers,
    String? httpRequestMethod,
    post,
    this.retries = 0,
    DateTime? creationTime,
  }) : url = urlWithQueryParameters(url, urlQueryParameters),
       headers = headers ?? {},
       httpRequestMethod =
           httpRequestMethod?.toUpperCase() ?? (post == null ? 'GET' : 'POST'),
       post = post is Uint8List
           ? String.fromCharCodes(post)
           : post is Map || post is List
           ? jsonEncode(post)
           : post,
       retriesRemaining = retries,
       creationTime = creationTime ?? DateTime.now() {
    if (retries < 0 || retries > 10) {
      throw ArgumentError('Number of retries must be in range 1 through 10');
    }
    if (!validHttpMethods.contains(this.httpRequestMethod)) {
      throw ArgumentError(
        'Invalid httpRequestMethod "${this.httpRequestMethod}": Must be one of ${validHttpMethods.join(', ')}',
      );
    }
  }

  /// Creates object from [json]
  Request.fromJson(Map<String, dynamic> json)
    : url = json['url'] ?? '',
      headers = Map<String, String>.from(json['headers'] ?? {}),
      httpRequestMethod =
          json['httpRequestMethod'] as String? ??
          (json['post'] == null ? 'GET' : 'POST'),
      post = json['post'] as String?,
      retries = (json['retries'] as num?)?.toInt() ?? 0,
      retriesRemaining = (json['retriesRemaining'] as num?)?.toInt() ?? 0,
      creationTime = DateTime.fromMillisecondsSinceEpoch(
        (json['creationTime'] as num?)?.toInt() ?? 0,
      );

  /// Creates JSON map of this object
  Map<String, dynamic> toJson() => {
    'url': url,
    'headers': headers,
    'httpRequestMethod': httpRequestMethod,
    'post': post,
    'retries': retries,
    'retriesRemaining': retriesRemaining,
    'creationTime': creationTime.millisecondsSinceEpoch,
  };

  /// The regex pattern to split the cookies in `Set-Cookie`.
  static final _splitSetCookiesRegExp = RegExp(',(?=[^ ])');

  /// Returns the cookie header appropriate for this [Request],
  /// taken from the [cookies] list.
  ///
  /// [cookies] can be a `List<Cookie>` or the 'Set-Cookie' header value
  ///
  /// The returned map is the 'Cookie:' header, with the
  /// value=name; value2=name2 as the value.
  static Map<String, String> cookieHeader(dynamic cookies, String url) {
    final Uri uri;
    try {
      uri = Uri.parse(url);
    } catch (e) {
      _log.fine('Invalid url: $url error: $e');
      return {};
    }
    final List<Cookie> cookieList = switch (cookies) {
      final http.Response response => cookiesFromSetCookie(
        response.headers['set-cookie'] ?? '',
      ),
      final List<Cookie> list => list,
      String _ => cookiesFromSetCookie(cookies),
      _ => throw ArgumentError(
        'cookies parameter must be a http.Response object, a String or a List<Cookie>',
      ),
    };
    final path = uri.path.isNotEmpty ? uri.path : '/';
    final validCookies = cookieList.where(
      (cookie) =>
          (cookie.maxAge == null || cookie.maxAge! > 0) &&
          (cookie.domain == null ||
              uri.host.endsWith(cookie.domain!) ||
              (cookie.domain!.startsWith('.') &&
                  uri.host == cookie.domain!.substring(1))) &&
          (cookie.path == null || path.startsWith(cookie.path!)) &&
          (cookie.expires == null || cookie.expires!.isAfter(DateTime.now())) &&
          (!cookie.secure || uri.scheme == 'https'),
    );
    final cookieHeaderValue = validCookies
        .map((c) => c.name.isNotEmpty ? '${c.name}=${c.value}' : c.value)
        .join('; ');
    return cookieHeaderValue.isNotEmpty ? {'Cookie': cookieHeaderValue} : {};
  }

  /// Returns a list of Cookies extracted from the [setCookie] string,
  /// which is the value of the 'Set-Cookie' header of a server response
  ///
  /// Based on https://github.com/dart-lang/http/pull/688/files
  static List<Cookie> cookiesFromSetCookie(String setCookie) {
    final cookies = <Cookie>[];
    if (setCookie.isNotEmpty) {
      for (final cookie in setCookie.split(_splitSetCookiesRegExp)) {
        cookies.add(Cookie.fromSetCookieValue(cookie));
      }
    }
    return cookies;
  }

  /// Decrease [retriesRemaining] by one
  void decreaseRetriesRemaining() => retriesRemaining--;

  /// Hostname represented by the url. Throws [FormatException] if url cannot
  /// be parsed, and returns empty string if no host in url
  String get hostName => Uri.parse(url).host;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Request && runtimeType == other.runtimeType && url == other.url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() =>
      'Request{url: $url, headers: $headers, httpRequestMethod: '
      '$httpRequestMethod, post: ${post == null ? "null" : "not null"}, '
      'retries: $retries, retriesRemaining: $retriesRemaining}';
}

/// RegExp to match a path separator and root directory
final _pathSeparatorRegExp = RegExp(r'[/\\]');
final _startsWithPathSeparatorRegExp = RegExp(r'^[/\\]');
final _rootDirectoryRegExp = RegExp(r'^(/|\\|([a-zA-Z]:[\\/]))');

/// Information related to a [Task]
///
/// A [Task] is the base class for [DownloadTask] and
/// [UploadTask]
///
/// An equality test on a [Task] is a test on the [taskId]
/// only - all other fields are ignored in that test
sealed class Task extends Request implements Comparable {
  /// Identifier for the task - auto generated if omitted
  final String taskId;

  /// Filename of the file to store - use {filename} in notification
  final String filename;

  /// Optional directory, relative to the base directory
  final String directory;

  /// Base directory
  final BaseDirectory baseDirectory;

  /// Group that this task belongs to
  final String group;

  /// Type of progress updates desired
  final Updates updates;

  /// If true, task is restricted to non-metered / non-cellular connections
  /// (on Android, requires an unmetered network connection; on iOS, disables cellular access).
  final bool requiresWiFi;

  /// If true, task will pause if the task fails partly through the execution,
  /// when some but not all bytes have transferred, provided the server supports
  /// partial transfers. Such failures are typically temporary, eg due to
  /// connectivity issues, and may be resumed when connectivity returns.
  /// If false, task fails on any issue, and task cannot be paused
  final bool allowPause;

  /// Priority of this task, relative to other tasks.
  /// Range 0 <= priority <= 10 with 0 being the highest priority.
  /// Not all platforms will have the same actual granularity, and how
  /// priority is considered is inconsistent across platforms.
  final int priority;

  /// User-defined metadata - use {metaData} in notification
  final String metaData;

  /// Human readable name for this task - use {displayName} in notification
  final String displayName;

  /// Optional task-specific configuration using [TaskOptions]
  final TaskOptions? options;

  /// Optional hints provided to tune the task's properties
  final Set<TransferHint>? transferHints;

  /// Optional notification configuration associated with this task
  final TaskNotificationConfig? notificationConfig;

  /// Optional stall timeout. If running and no progress is observed within this duration,
  /// the transfer is restarted/resumed.
  final Duration? stallTimeout;

  static bool useExternalStorage = false; // for Android configuration only

  static final _baseDirectoryPathCache = <(BaseDirectory, bool), String>{};

  static const _androidBaseDirs = [
    BaseDirectory.temporary,
    BaseDirectory.applicationLibrary,
    BaseDirectory.applicationSupport,
    BaseDirectory.applicationDocuments,
  ];

  static const _otherBaseDirs = [
    BaseDirectory.temporary,
    BaseDirectory.applicationSupport,
    BaseDirectory.applicationLibrary,
    BaseDirectory.applicationDocuments,
  ];

  /// Uri schemes that are supported by the downloader in the context of
  /// a [Task] download directory or upload file
  static const allowedUriSchemes = ['file', 'content', 'urlbookmark', 'media'];

  /// Creates a [Task]
  ///
  /// [taskId] must be unique. A unique id will be generated if omitted
  /// [url] properly encoded if necessary, can include query parameters
  /// [urlQueryParameters] may be added and will be appended to the [url], must
  ///   be properly encoded if necessary
  /// [filename] of the file to save. If omitted, a random filename will be
  /// generated
  /// [headers] an optional map of HTTP request headers
  /// [httpRequestMethod] the HTTP request method used (e.g. GET, POST)
  /// [post] if set, uses POST instead of GET. Post must be one of the
  /// following:
  /// - a String: POST request with [post] as the body, encoded in utf8
  /// - a Map: will be jsonEncoded to a String and set as the POST body
  /// - a List of bytes: will be converted to a String using String.fromCharCodes
  ///   and set as the POST body
  /// - a List: map will be jsonEncoded to a String and set as the POST body
  /// [directory] optional directory name, precedes [filename]
  /// [baseDirectory] one of the base directories, precedes [directory]
  /// [group] if set allows different callbacks or processing for different
  /// groups
  /// [updates] the kind of progress updates requested
  /// [requiresWiFi] if set, restricts task to non-metered / non-cellular connections
  /// (on Android API 28+, requires a Wi-Fi or Ethernet connection; on older Android versions, requires an unmetered connection; on iOS, disables cellular access).
  /// If not set, task may execute over cellular or metered networks.
  /// [retries] if >0 will retry a failed download this many times
  /// [allowPause]
  /// If true, task will pause if the task fails partly through the execution,
  /// when some but not all bytes have transferred, provided the server supports
  /// partial transfers. Such failures are typically temporary, eg due to
  /// connectivity issues, and may be resumed when connectivity returns
  /// [priority] in range 0 <= priority <= 10 with 0 highest, defaults to 5.
  /// On Android 14+, setting priority to 0 requires the
  /// `android.permission.RUN_USER_INITIATED_JOBS` permission in AndroidManifest.xml.
  /// If the permission is missing, the downloader will automatically fall back to normal operation (which may include a foreground service if configured).
  /// [metaData] user data
  /// [displayName] human readable name for this task
  /// [creationTime] time of task creation, 'now' by default.
  /// [options] optional task-specific configuration using [TaskOptions]
  /// [transferHints] optional hints to auto-tune task priority, updates, and pause behavior
  /// [notificationConfig] optional system notification configuration
  /// [stallTimeout] optional duration after which an inactive running transfer is kicked/resumed
  Task({
    String? taskId,
    required super.url,
    super.urlQueryParameters,
    String? filename,
    super.headers,
    super.httpRequestMethod,
    super.post,
    String directory = '',
    this.baseDirectory = BaseDirectory.applicationDocuments,
    this.group = 'default',
    Updates updates = Updates.status,
    this.requiresWiFi = false,
    super.retries,
    this.metaData = '',
    this.displayName = '',
    bool allowPause = false,
    int priority = 5,
    super.creationTime,
    this.options,
    this.transferHints,
    this.notificationConfig,
    this.stallTimeout,
  }) : taskId = taskId ?? _random.nextInt(1 << 32).toString(),
       filename =
           filename ??
           ((transferHints?.contains(TransferHint.useSuggestedFilename) == true)
               ? DownloadTask.suggestedFilename
               : _random.nextInt(1 << 32).toString()),
       directory = _startsWithPathSeparatorRegExp.hasMatch(directory)
           ? directory.substring(1)
           : directory,
       updates = (transferHints?.contains(TransferHint.smallFile) == true)
           ? Updates.status
           : updates,
       allowPause =
           allowPause ||
           (transferHints?.contains(TransferHint.userInitiated) == true) ||
           (transferHints?.contains(TransferHint.largeFile) == true),
       priority =
           (transferHints?.contains(TransferHint.userInitiated) == true &&
               priority == 5)
           ? 0
           : (transferHints?.contains(TransferHint.lowPriority) == true &&
                 priority == 5)
           ? 10
           : priority {
    if (filename?.isEmpty == true) {
      throw ArgumentError('Filename cannot be empty');
    }
    if (this is! UriTask &&
        this is! MultiUploadTask &&
        _pathSeparatorRegExp.hasMatch(this.filename)) {
      throw ArgumentError('Filename cannot contain path separators');
    }
    if (allowPause && post != null) {
      throw ArgumentError('Tasks that can pause must be GET requests');
    }
    if (priority < 0 || priority > 10) {
      throw ArgumentError('Priority must be 0 <= priority <= 10');
    }
  }

  /// Create a new [Task] subclass from the provided [json]
  ///
  /// Use [Task.createFromJson] to create a properly subclassed [Task] from the [json]
  factory Task.createFromJson(Map<String, dynamic> json) =>
      switch (json['taskType']) {
        'DownloadTask' => DownloadTask.fromJson(json),
        'UriDownloadTask' => UriDownloadTask.fromJson(json),
        'UploadTask' => UploadTask.fromJson(json),
        'UriUploadTask' => UriUploadTask.fromJson(json),
        'MultiUploadTask' => MultiUploadTask.fromJson(json),
        'ParallelDownloadTask' => ParallelDownloadTask.fromJson(json),
        'DataTask' => DataTask.fromJson(json),
        _ => throw ArgumentError(
          'taskType not in [DownloadTask, UploadTask, MultiUploadTask, ParallelDownloadTask, DataTask]',
        ),
      };

  /// Create a new [Task] subclass from provided [jsonString]
  factory Task.createFromJsonString(String jsonString) =>
      Task.createFromJson(jsonDecode(jsonString));

  /// Returns the absolute path to the file represented by this task
  /// based on the [Task.filename] (default) or [withFilename]
  ///
  /// If the task is a MultiUploadTask and no [withFilename] is given,
  /// returns the empty string, as there is no single path that can be
  /// returned.
  ///
  /// Throws a FileSystemException if using external storage on Android (via
  /// configuration at startup), and external storage is not available.
  ///
  /// If called when the task is a [UriTask], will return the filePath of a file
  /// scheme Uri, but may throw if unavailable or the scheme is not 'file'
  Future<String> filePath({String? withFilename}) async {
    if (this is MultiUploadTask && withFilename == null) {
      return '';
    }
    switch (this) {
      case final UriTask t:
        if (t.fileUri != null) {
          assert(
            t.fileUri?.scheme == 'file',
            'fileUri must be a URI scheme to return a path',
          );
          return t.fileUri!.toFilePath(
            windows: defaultTargetPlatform == TargetPlatform.windows,
          );
        } else {
          assert(
            t.directoryUri?.scheme == 'file',
            'directoryUri must be a URI scheme to return a path',
          );
          return '${t.directoryUri!.toFilePath(windows: defaultTargetPlatform == TargetPlatform.windows)}${Platform.pathSeparator}${withFilename ?? filename}';
        }
      default:
        return p.join(
          await baseDirectoryPath(baseDirectory),
          directory,
          withFilename ?? filename,
        );
    }
  }

  /// Returns the path to the directory represented by [baseDirectory]
  ///
  /// On Windows, if [baseDirectory] is .root, returns the empty string
  /// because the drive letter is required to be included in the directory
  /// path
  static Future<String> baseDirectoryPath(BaseDirectory baseDirectory) async {
    final cacheKey = (baseDirectory, Task.useExternalStorage);
    if (_baseDirectoryPathCache.containsKey(cacheKey)) {
      return _baseDirectoryPathCache[cacheKey]!;
    }
    Directory? externalStorageDirectory;
    Directory? externalCacheDirectory;
    if (Task.useExternalStorage) {
      externalStorageDirectory = await getExternalStorageDirectory();
      externalCacheDirectory = (await getExternalCacheDirectories())?.first;
      if (externalStorageDirectory == null || externalCacheDirectory == null) {
        throw const FileSystemException(
          'Android external storage is not available',
        );
      }
    }
    final baseDir = switch ((baseDirectory, Task.useExternalStorage)) {
      (.applicationDocuments, false) =>
        await getApplicationDocumentsDirectory(),
      (.temporary, false) => await getTemporaryDirectory(),
      (.applicationSupport, false) => await getApplicationSupportDirectory(),
      (.applicationLibrary, false)
          when defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.iOS =>
        await getLibraryDirectory(),
      (.applicationLibrary, false) => Directory(
        p.join((await getApplicationSupportDirectory()).path, 'Library'),
      ),
      (.root, _) => Directory('/'),
      // Android only: external storage variants
      (.applicationDocuments, true) => externalStorageDirectory!,
      (.temporary, true) => externalCacheDirectory!,
      (.applicationSupport, true) => Directory(
        p.join(externalStorageDirectory!.path, 'Support'),
      ),
      (.applicationLibrary, true) => Directory(
        p.join(externalStorageDirectory!.path, 'Library'),
      ),
    };
    final path =
        (defaultTargetPlatform == TargetPlatform.windows &&
            baseDirectory == BaseDirectory.root)
        ? ''
        : baseDir.absolute.path;
    _baseDirectoryPathCache[cacheKey] = path;
    return path;
  }

  /// Extract the baseDirectory, directory and filename from
  /// the provided [filePath] or [file], and return this as a record
  ///
  /// Either [filePath] or [file] must be provided, not both.
  ///
  /// Throws a FileSystemException if using external storage on Android (via
  /// configuration at startup), and external storage is not available.
  static Future<
    (BaseDirectory baseDirectory, String directory, String filename)
  >
  split({String? filePath, File? file}) async {
    assert(
      (filePath != null) ^ (file != null),
      'Either filePath or file must be given and not both',
    );
    final path = filePath ?? file!.absolute.path;
    final absoluteDirectoryPath = p.dirname(path);
    final filename = p.basename(path);
    // try to match the start of the absoluteDirectory to one of the
    // directories represented by the BaseDirectory enum.
    // Order matters, as some may be subdirs of others
    final testSequence =
        defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows
        ? _androidBaseDirs
        : _otherBaseDirs;
    for (final baseDirectoryEnum in testSequence) {
      final baseDirPath = await baseDirectoryPath(baseDirectoryEnum);
      final (match, directory) = _contains(baseDirPath, absoluteDirectoryPath);
      if (match) {
        return (baseDirectoryEnum, directory, filename);
      }
    }
    // if no match, return a BaseDirectory.root with the absoluteDirectory
    // minus the leading characters that designate the root (differs by platform)
    final match = _rootDirectoryRegExp.firstMatch(absoluteDirectoryPath);
    return (
      BaseDirectory.root,
      absoluteDirectoryPath.substring(match?.end ?? 0),
      filename,
    );
  }

  /// Returns the subdirectory of the given [baseDirPath] within [dirPath],
  /// if [dirPath] starts with [baseDirPath].
  ///
  /// If found, returns (true, subdir) otherwise returns (false, '').
  ///
  /// [dirPath] should not contain a filename - if it does, it is returned
  /// as part of the subdir.
  static (bool, String) _contains(String baseDirPath, String dirPath) {
    final escapedBaseDirPath = '$baseDirPath${Platform.pathSeparator}?'
        .replaceAll(r'\', r'\\');
    final match = RegExp('^$escapedBaseDirPath(.*)').firstMatch(dirPath);
    return (match != null, match?.group(1) ?? '');
  }

  /// Returns a copy of the [Task] with optional changes to specific fields
  Task copyWith({
    String? taskId,
    String? url,
    String? filename,
    Map<String, String>? headers,
    String? httpRequestMethod,
    Object? post,
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
  });

  /// Creates [Task] object from JsonMap
  ///
  /// Only used by subclasses. Use [Task.createFromJson] to create a properly
  /// subclassed [Task] from the [json]
  Task.fromJson(super.json)
    : taskId = json['taskId'] ?? '',
      filename = json['filename'] ?? '',
      directory = json['directory'] ?? '',
      baseDirectory =
          BaseDirectory.values[(json['baseDirectory'] as num?)?.toInt() ?? 0],
      group = json['group'] ?? FileDownloader.defaultGroup,
      updates = Updates.values[(json['updates'] as num?)?.toInt() ?? 0],
      requiresWiFi = json['requiresWiFi'] ?? false,
      allowPause = json['allowPause'] ?? false,
      priority = (json['priority'] as num?)?.toInt() ?? 5,
      metaData = json['metaData'] ?? '',
      displayName = json['displayName'] ?? '',
      options = json['options'] != null
          ? TaskOptions.fromJson(json['options'])
          : null,
      transferHints = json['transferHints'] != null
          ? (json['transferHints'] as List)
                .map((e) => TransferHint.values[(e as num).toInt()])
                .toSet()
          : null,
      notificationConfig = null,
      stallTimeout = json['stallTimeout'] != null
          ? Duration(milliseconds: (json['stallTimeout'] as num).toInt())
          : null,
      super.fromJson();

  /// Creates JSON map of this object
  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'taskId': taskId,
    'filename': filename,
    'directory': directory,
    'baseDirectory': baseDirectory.index, // stored as int
    'group': group,
    'updates': updates.index, // stored as int
    'requiresWiFi': requiresWiFi,
    'allowPause': allowPause,
    'priority': priority,
    'metaData': metaData,
    'displayName': displayName,
    'options': options?.toJson(),
    if (transferHints != null)
      'transferHints': transferHints!.map((h) => h.index).toList(),
    if (stallTimeout != null) 'stallTimeout': stallTimeout!.inMilliseconds,
    'taskType': taskType,
  };

  /// If true, task expects progress updates
  bool get providesProgressUpdates =>
      updates == Updates.progress || updates == Updates.statusAndProgress;

  /// If true, task expects status updates
  bool get providesStatusUpdates =>
      updates == Updates.status || updates == Updates.statusAndProgress;

  /// Returns the type of task as a String
  ///
  /// Used to identify the task type in JSON format
  String get taskType => 'Task';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          taskId == other.taskId;

  @override
  int get hashCode => taskId.hashCode;

  /// Returns this.priority - other.priority if not the same
  /// Returns this.creationTime - other.creationTime if priorities the same
  /// Returns 0 if other is not a [Task]
  @override
  int compareTo(other) {
    if (other is Task) {
      final diff = priority - other.priority;
      if (diff != 0) {
        return diff;
      }
      return creationTime.difference(other.creationTime).inMicroseconds;
    }
    return 0;
  }

  @override
  String toString() =>
      '$taskType{taskId: $taskId, url: $url, filename: $filename, headers: '
      '$headers, httpRequestMethod: $httpRequestMethod, post: ${post == null ? "null" : "not null"}, directory: $directory, baseDirectory: $baseDirectory, group: $group, updates: $updates, requiresWiFi: $requiresWiFi, retries: $retries, retriesRemaining: $retriesRemaining, allowPause: $allowPause, priority: $priority, metaData: $metaData, displayName: $displayName}';
}

/// Information related to a download task
///
/// An equality test on a [DownloadTask] is a test on the [taskId]
/// only - all other fields are ignored in that test
final class DownloadTask extends Task {
  /// Creates a [DownloadTask]
  ///
  /// [taskId] must be unique. A unique id will be generated if omitted
  /// [url] properly encoded if necessary, can include query parameters
  /// [urlQueryParameters] may be added and will be appended to the [url], must
  ///   be properly encoded if necessary
  /// [filename] of the file to save. If omitted, a random filename will be
  /// generated
  /// [headers] an optional map of HTTP request headers
  /// [httpRequestMethod] the HTTP request method used (e.g. GET, POST)
  /// [post] if set, uses POST instead of GET. Post must be one of the
  /// following:
  /// - a String: POST request with [post] as the body, encoded in utf8
  /// - a Map: will be jsonEncoded to a String and set as the POST body
  /// - a List of bytes: will be converted to a String using String.fromCharCodes
  ///   and set as the POST body
  /// - a List: map will be jsonEncoded to a String and set as the POST body
  ///
  /// [directory] optional directory name, precedes [filename]
  /// [baseDirectory] one of the base directories, precedes [directory]
  /// [group] if set allows different callbacks or processing for different
  /// groups
  /// [updates] the kind of progress updates requested
  /// [requiresWiFi] if set, restricts task to non-metered / non-cellular connections
  /// (on Android API 28+, requires a Wi-Fi or Ethernet connection; on older Android versions, requires an unmetered connection; on iOS, disables cellular access).
  /// If not set, task may execute over cellular or metered networks.
  /// [retries] if >0 will retry a failed download this many times
  /// [allowPause] if true, allows pause command
  /// [priority] in range 0 <= priority <= 10 with 0 highest, defaults to 5.
  /// On Android 14+, setting priority to 0 requires the
  /// `android.permission.RUN_USER_INITIATED_JOBS` permission in AndroidManifest.xml.
  /// If the permission is missing, the downloader will automatically fall back to normal operation (which may include a foreground service if configured).
  /// [metaData] user data
  /// [displayName] human readable name for this task
  /// [creationTime] time of task creation, 'now' by default.
  /// [options] optional task-specific configuration using [TaskOptions]
  /// [transferHints] optional hints to auto-tune task priority, updates, and pause behavior
  /// [notificationConfig] optional system notification configuration
  /// [stallTimeout] optional duration after which an inactive running transfer is kicked/resumed
  DownloadTask({
    super.taskId,
    required super.url,
    super.urlQueryParameters,
    super.filename,
    super.headers,
    super.httpRequestMethod,
    super.post,
    super.directory,
    super.baseDirectory,
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
  });

  /// List of task types supported by [DownloadTask.fromJson]
  static final _taskTypes = [
    'DownloadTask',
    'ParallelDownloadTask',
    'UriDownloadTask',
  ];

  /// Creates [DownloadTask] object from [json]
  DownloadTask.fromJson(super.json)
    : assert(
        _taskTypes.contains(json['taskType']),
        'The provided JSON map is not an UploadTask, '
        'because key "taskType" is not in ${_taskTypes.join(',')}',
      ),
      super.fromJson();

  @override
  String get taskType => 'DownloadTask';

  @override
  DownloadTask copyWith({
    String? taskId,
    String? url,
    String? filename,
    Map<String, String>? headers,
    String? httpRequestMethod,
    Object? post,
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
  }) => DownloadTask(
    taskId: taskId ?? this.taskId,
    url: url ?? this.url,
    filename: filename ?? this.filename,
    headers: headers ?? this.headers,
    httpRequestMethod: httpRequestMethod ?? this.httpRequestMethod,
    post: post ?? this.post,
    directory: directory ?? this.directory,
    baseDirectory: baseDirectory ?? this.baseDirectory,
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

  /// Returns a copy of the task with the [Task.filename] property changed
  /// to the filename suggested by the server, or derived from the url, or
  /// unchanged.
  ///
  /// If [unique] is true, the filename is guaranteed not to already exist. This
  /// is accomplished by adding a suffix to the suggested filename with a number,
  /// e.g. "data (2).txt"
  /// If a [taskWithFilenameBuilder] is supplied, this is the function called to
  /// convert the task, response headers and [unique] values into a new [DownloadTask]
  /// with the suggested filename. By default, [taskWithSuggestedFilename] is used,
  /// which parses the Content-Disposition according to RFC6266, or takes the last
  /// path segment of the URL, or leaves the filename unchanged
  ///
  /// The suggested filename is obtained by making a HEAD request to the url
  /// represented by the [DownloadTask], including urlQueryParameters and headers
  Future<DownloadTask> withSuggestedFilename({
    bool unique = false,
    Future<DownloadTask> Function(
          DownloadTask task,
          Map<String, String> headers,
          bool unique,
        )
        taskWithFilenameBuilder =
        taskWithSuggestedFilename,
  }) async {
    try {
      final response = await DesktopDownloader.httpClient.head(
        Uri.parse(url),
        headers: headers,
      );
      if ([200, 201, 202, 203, 204, 205, 206].contains(response.statusCode)) {
        return await taskWithFilenameBuilder(this, response.headers, unique);
      }
    } catch (e) {
      _log.finer('Error connecting to server');
    }
    return taskWithFilenameBuilder(this, {}, unique);
  }

  /// Return the expected file size for this task, or -1 if unknown
  ///
  /// The expected file size is obtained by making a HEAD request to the url
  /// represented by the [DownloadTask], including urlQueryParameters and headers
  Future<int> expectedFileSize() async {
    try {
      final response = await DesktopDownloader.httpClient.head(
        Uri.parse(url),
        headers: headers,
      );
      if ([200, 201, 202, 203, 204, 205, 206].contains(response.statusCode)) {
        return getContentLength(response.headers, this);
      }
    } catch (e) {
      // no content length available
    }
    return -1;
  }

  /// Constant used with `filename` field to indicate server suggestion requested
  static const suggestedFilename = '?';

  /// True if this task has a filename, or false if set to `suggest`
  bool get hasFilename => filename != suggestedFilename;
}

/// Information related to an upload task
///
/// An equality test on a [UploadTask] is a test on the [taskId]
/// only - all other fields are ignored in that test
final class UploadTask extends Task {
  /// Name of the field used for multi-part file upload
  final String fileField;

  /// mimeType of the file to upload
  final String mimeType;

  /// Map of name/value pairs to encode as form fields in a multi-part upload.
  /// To specify multiple values for a single name, format the value as
  /// '"value1", "value2", "value3"' so that it matches the following
  /// RegEx: `^(?:"[^"]+"\s*,\s*)+"[^"]+"$`
  final Map<String, String> fields;

  /// Creates [UploadTask]
  ///
  /// [taskId] must be unique. A unique id will be generated if omitted
  /// [url] properly encoded if necessary, can include query parameters
  /// [urlQueryParameters] may be added and will be appended to the [url], must
  ///   be properly encoded if necessary
  /// [filename] of the file to upload
  /// [headers] an optional map of HTTP request headers
  /// [httpRequestMethod] the HTTP request method used (e.g. GET, POST)
  /// [post] if set to 'binary' will upload as binary file, otherwise multi-part
  /// [fileField] for multi-part uploads, name of the file field or 'file' by
  /// default
  /// [mimeType] the mimeType of the file, or derived from filename extension
  /// by default
  /// [fields] for multi-part uploads, optional map of name/value pairs to upload
  ///   along with the file as form fields
  /// [directory] optional directory name, precedes [filename]
  /// [baseDirectory] one of the base directories, precedes [directory]
  /// [group] if set allows different callbacks or processing for different
  /// groups
  /// [updates] the kind of progress updates requested
  /// [requiresWiFi] if set, restricts task to non-metered / non-cellular connections
  /// (on Android API 28+, requires a Wi-Fi or Ethernet connection; on older Android versions, requires an unmetered connection; on iOS, disables cellular access).
  /// If not set, task may execute over cellular or metered networks.
  /// [priority] in range 0 <= priority <= 10 with 0 highest, defaults to 5.
  /// On Android 14+, setting priority to 0 requires the
  /// `android.permission.RUN_USER_INITIATED_JOBS` permission in AndroidManifest.xml.
  /// If the permission is missing, the downloader will automatically fall back to normal operation (which may include a foreground service if configured).
  /// [retries] if >0 will retry a failed upload this many times
  /// [metaData] user data
  /// [displayName] human readable name for this task
  /// [creationTime] time of task creation, 'now' by default.
  /// [options] optional task-specific configuration using [TaskOptions]
  UploadTask({
    super.taskId,
    required super.url,
    super.urlQueryParameters,
    required String super.filename,
    super.headers,
    String? httpRequestMethod,
    String? post,
    this.fileField = 'file',
    String? mimeType,
    Map<String, String>? fields,
    super.directory,
    super.baseDirectory,
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
  }) : assert(filename.isNotEmpty, 'A filename is required'),
       assert(
         (post ??
                     (transferHints?.contains(TransferHint.binaryUpload) == true
                         ? 'binary'
                         : null)) ==
                 null ||
             (post ??
                     (transferHints?.contains(TransferHint.binaryUpload) == true
                         ? 'binary'
                         : null)) ==
                 'binary',
         'post field must be null, or "binary" for binary file upload',
       ),
       assert(
         fields == null ||
             fields.isEmpty ||
             (post ??
                     (transferHints?.contains(TransferHint.binaryUpload) == true
                         ? 'binary'
                         : null)) !=
                 'binary',
         'fields only allowed for multi-part uploads',
       ),
       fields = fields ?? {},
       mimeType =
           mimeType ?? lookupMimeType(filename) ?? 'application/octet-stream',
       super(
         post:
             post ??
             (transferHints?.contains(TransferHint.binaryUpload) == true
                 ? 'binary'
                 : null),
         httpRequestMethod: httpRequestMethod ?? 'POST',
         allowPause: false,
       );

  /// Creates [UploadTask] from a [File] object, using the [file] absolute path.
  ///
  /// Note that using absolute paths is discouraged on mobile, as the path to
  /// files in an application's directory scope is not stable between application
  /// starts. Use the combination of [baseDirectory], [directory] and [filename]
  /// whenever possible to prevent hard to debug errors.
  UploadTask.fromFile({
    required File file,
    super.taskId,
    required super.url,
    super.urlQueryParameters,
    super.headers,
    String? httpRequestMethod,
    String? post,
    this.fileField = 'file',
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
  }) : fields = fields ?? {},
       mimeType =
           mimeType ?? lookupMimeType(file.path) ?? 'application/octet-stream',
       super(
         baseDirectory: BaseDirectory.root,
         directory: p.dirname(file.absolute.path),
         filename: p.basename(file.absolute.path),
         post:
             post ??
             (transferHints?.contains(TransferHint.binaryUpload) == true
                 ? 'binary'
                 : null),
         httpRequestMethod: httpRequestMethod ?? 'POST',
         allowPause: false,
       );

  /// List of task types  supported by [UploadTask.fromJson]
  static final _taskTypes = ['UploadTask', 'MultiUploadTask', 'UriUploadTask'];

  /// Creates [UploadTask] object from [json]
  UploadTask.fromJson(super.json)
    : assert(
        _taskTypes.contains(json['taskType']),
        'The provided JSON map is not an UploadTask, '
        'because key "taskType" is not in ${_taskTypes.join(',')}',
      ),
      fileField = json['fileField'] ?? 'file',
      mimeType = json['mimeType'] ?? 'application/octet-stream',
      fields = Map<String, String>.from(json['fields'] ?? {}),
      super.fromJson();

  /// Returns a list of fileData elements, one for each file to upload.
  /// Each element is a triple containing fileField, full filePath, mimeType
  ///
  /// The lists are stored in the similarly named String fields as a JSON list,
  /// with each list the same length. For the filenames list, if a filename refers
  /// to a file that exists (i.e. it is a full path) then that is the filePath used,
  /// otherwise the filename is appended to the [Task.baseDirectory] and [Task.directory]
  /// to form a full file path. If the filename is represented as a file:// uri
  /// then that Uri's filePath is used
  Future<List<(String, String, String)>> extractFilesData() async {
    final List<String> fileFields = List.from(jsonDecode(fileField));
    final List<String> filenames = List.from(jsonDecode(filename));
    final List<String> mimeTypes = List.from(jsonDecode(mimeType));
    final result = <(String, String, String)>[];
    for (int i = 0; i < fileFields.length; i++) {
      final fileUri = Uri.tryParse(filenames[i]);
      final filenameOrPath = (fileUri?.scheme == 'file')
          ? fileUri!.toFilePath(
              windows: defaultTargetPlatform == TargetPlatform.windows,
            )
          : filenames[i];
      final file = File(filenameOrPath);
      if (await file.exists()) {
        result.add((fileFields[i], filenameOrPath, mimeTypes[i]));
      } else {
        // if file does not exist, assume it is a filename only relative path) and
        // append to baseDirectory and directory
        result.add((
          fileFields[i],
          await filePath(withFilename: filenameOrPath),
          mimeTypes[i],
        ));
      }
    }
    return result;
  }

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'fileField': fileField,
    'mimeType': mimeType,
    'fields': fields,
  };

  @override
  String get taskType => 'UploadTask';

  @override
  UploadTask copyWith({
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
  }) => UploadTask(
    taskId: taskId ?? this.taskId,
    url: url ?? this.url,
    filename: filename ?? this.filename,
    headers: headers ?? this.headers,
    httpRequestMethod: httpRequestMethod ?? this.httpRequestMethod,
    post: post as String? ?? this.post,
    fileField: fileField ?? this.fileField,
    mimeType: mimeType ?? this.mimeType,
    fields: fields ?? this.fields,
    directory: directory ?? this.directory,
    baseDirectory: baseDirectory ?? this.baseDirectory,
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
  String toString() =>
      '${super.toString()} and fileField $fileField, '
      'mimeType $mimeType and fields $fields';
}

/// Information related to an UploadTask, containing multiple files to upload
///
/// An equality test on a [UploadTask] is a test on the [taskId]
/// only - all other fields are ignored in that test
///
/// A [MultiUploadTask] is initialized with a list representing the files to upload.
/// Each element is either a filename/path/Uri, or a (fileField, filename/path/Uri),
/// or a (fileField, filename/path/Uri, mimeType).
/// When instantiating a [MultiUploadTask], this list is converted into
/// three lists: [fileFields], [filenames], and [mimeTypes], available
/// as fields. These lists are also encoded to a JSON string representation in
/// the fields [fileField], [filename] and [mimeType],so - different from
/// a single [UploadTask] - these fields now contain a JSON object representing all
/// files.
/// filename/path/Uri means either a filename without directory (and the
/// directory will be based on the [Task.baseDirectory] and [Task.directory]
/// fields), or you specify a full file path or a Uri (which will be converted
/// to a Uri string). For example: "hello.txt" or
/// "/data/com.myapp/data/dir/hello.txt" or "content://some/path/to/file.txt"
final class MultiUploadTask extends UploadTask {
  final List<String> fileFields, filenames, mimeTypes;

  static const _filesArgumentError =
      'files must be a list of filenames, or a list of records of type '
      '(fileField, filename) or (fileField, filename, mimeType)';

  /// Creates [MultiUploadTask] to upload more than one file using
  /// multipart/form-data
  ///
  /// [taskId] must be unique. A unique id will be generated if omitted
  /// [url] properly encoded if necessary, can include query parameters
  /// [urlQueryParameters] may be added and will be appended to the [url], must
  ///   be properly encoded if necessary
  /// [files] list of objects representing each file to upload. If not using Uri,
  ///   The object must
  ///   be either a String representing the filename/path (and the fileField will
  ///   be the filename without extension), a Record of type
  ///   (String fileField, String filename/path) or a Record with a third String
  ///   for the mimeType (if omitted, mimeType will be derived from the filename
  ///   extension).
  ///   If using Uri, the object must be a Uri (and the fileField will be
  ///   "file1", "file2" etc), or a Record with fileField and Uri, and the
  ///   mimeType will be attempted to be derived from the Uri, or
  ///   a Record with fileField, Uri and mimetype
  ///   Each file must be based in the directory represented by the combination
  ///   of [baseDirectory] and [directory], unless a full filepath is given
  ///   instead of only the filename. For example: "hello.txt" or
  ///   "/data/com.myapp/data/dir/hello.txt"
  /// [headers] an optional map of HTTP request headers
  /// [httpRequestMethod] the HTTP request method used (e.g. GET, POST)
  /// [fields] optional map of name/value pairs to upload
  ///   along with the file as form fields
  /// [directory] optional directory name, precedes [filename]
  /// [baseDirectory] one of the base directories, precedes [directory]
  /// [group] if set allows different callbacks or processing for different
  /// groups
  /// [updates] the kind of progress updates requested
  /// [requiresWiFi] if set, will not start upload until WiFi is available.
  /// If not set may start upload over cellular network
  /// [priority] in range 0 <= priority <= 10 with 0 highest, defaults to 5.
  /// On Android 14+, setting priority to 0 requires the
  /// `android.permission.RUN_USER_INITIATED_JOBS` permission in AndroidManifest.xml.
  /// If the permission is missing, the downloader will automatically fall back to normal operation (which may include a foreground service if configured).
  /// [retries] if >0 will retry a failed upload this many times
  /// [metaData] user data
  /// [displayName] human readable name for this task
  /// [creationTime] time of task creation, 'now' by default.
  /// [options] optional task-specific configuration using [TaskOptions]
  MultiUploadTask({
    super.taskId,
    required super.url,
    super.urlQueryParameters,
    required List<dynamic> files,
    super.headers,
    super.httpRequestMethod,
    super.fields = const {},
    super.directory,
    super.baseDirectory,
    super.group,
    super.updates,
    super.requiresWiFi,
    super.priority,
    super.retries,
    super.metaData,
    super.displayName,
    super.creationTime,
    super.options,
    super.transferHints,
    super.notificationConfig,
    super.stallTimeout,
  }) : fileFields = files
           .map(
             (e) => switch (e) {
               final String filename => p.basenameWithoutExtension(filename),
               (final String fileField, String _) ||
               (final String fileField, String _, String _) ||
               (final String fileField, Uri _) ||
               (final String fileField, Uri _, String _) => fileField,
               Uri _ => 'file${files.indexOf(e) + 1}',
               _ => throw ArgumentError(_filesArgumentError),
             },
           )
           .toList(growable: false),
       filenames = files
           .map(
             (e) => switch (e) {
               final String filename ||
               (String _, final String filename) ||
               (String _, final String filename, String _) => filename,
               final Uri uri ||
               (String _, final Uri uri) ||
               (String _, final Uri uri, String _) => uri.toString(),
               _ => throw ArgumentError(_filesArgumentError),
             },
           )
           .toList(growable: false),
       mimeTypes = files
           .map(
             (e) => switch (e) {
               final String filename || (String _, final String filename) =>
                 lookupMimeType(filename) ?? 'application/octet-stream',
               (String _, String _, final String mimeType) ||
               (String _, Uri _, final String mimeType) => mimeType,
               Uri _ || (String _, Uri _) => '',
               _ => throw ArgumentError(_filesArgumentError),
             },
           )
           .toList(growable: false),
       super(filename: 'multi-upload', fileField: '', mimeType: '');

  /// For [MultiUploadTask], returns jsonEncoded list of [fileFields]
  @override
  String get fileField => jsonEncode(fileFields);

  /// For [MultiUploadTask], returns jsonEncoded list of [filenames]
  @override
  String get filename => jsonEncode(filenames);

  /// For [MultiUploadTask], returns jsonEncoded list of [mimeTypes]
  @override
  String get mimeType => jsonEncode(mimeTypes);

  /// Creates [MultiUploadTask] object from [json]
  MultiUploadTask.fromJson(super.json)
    : assert(
        json['taskType'] == 'MultiUploadTask',
        'The provided JSON map is not'
        ' a MultiUploadTask, because key "taskType" is not "MultiUploadTask".',
      ),
      fileFields = List.from(jsonDecode(json['fileField'] as String? ?? '[]')),
      filenames = List.from(jsonDecode(json['filename'] as String? ?? '[]')),
      mimeTypes = List.from(jsonDecode(json['mimeType'] as String? ?? '[]')),
      super.fromJson();

  @override
  MultiUploadTask copyWith({
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
  }) => MultiUploadTask(
    taskId: taskId ?? this.taskId,
    url: url ?? this.url,
    files: fileFields.indexed.map(_toRecord).toList(),
    headers: headers ?? this.headers,
    httpRequestMethod: httpRequestMethod ?? this.httpRequestMethod,
    fields: fields ?? this.fields,
    directory: directory ?? this.directory,
    baseDirectory: baseDirectory ?? this.baseDirectory,
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

  /// Zips the fileField, filename and mimeType at an index to
  /// a record
  (String, String, String) _toRecord((int, String) record) =>
      (fileFields[record.$1], filenames[record.$1], mimeTypes[record.$1]);

  @override
  String get taskType => 'MultiUploadTask';
}

final class ParallelDownloadTask extends DownloadTask {
  /// List of URLs to download the file from
  final List<String> urls;

  /// Number of chunks per URL
  final int chunks;

  /// Creates a [ParallelDownloadTask]
  ///
  /// A [ParallelDownloadTask] is a [DownloadTask] that downloads the file
  /// from one or more URLs, and in one or more chunks per URL. The parallel
  /// download may speed up download from slow or restrictive servers.
  ///
  /// [taskId] must be unique. A unique id will be generated if omitted
  /// [url] properly encoded if necessary, can include query parameters
  ///   and can be a list of urls, each providing the same file. The same
  ///   [urlQueryParameters] and [headers] will be applied to all urls in the list
  /// [urlQueryParameters] may be added and will be appended to the [url], must
  ///   be properly encoded if necessary
  /// [filename] of the file to save. If omitted, a random filename will be
  /// generated
  /// [headers] an optional map of HTTP request headers
  /// [httpRequestMethod] the HTTP request method used (e.g. GET)
  /// [chunks] the number of chunks to break the download into, i.e. the
  ///   number of downloads that will happen in parallel
  /// [directory] optional directory name, precedes [filename]
  /// [baseDirectory] one of the base directories, precedes [directory]
  /// [group] if set allows different callbacks or processing for different
  /// groups
  /// [updates] the kind of progress updates requested
  /// [requiresWiFi] if set, will not start download until WiFi is available.
  /// If not set may start download over cellular network
  /// [retries] if >0 will retry a failed download this many times
  /// [allowPause] if true, allows pause command
  /// [priority] in range 0 <= priority <= 10 with 0 highest, defaults to 5.
  /// On Android 14+, setting priority to 0 requires the
  /// `android.permission.RUN_USER_INITIATED_JOBS` permission in AndroidManifest.xml.
  /// If the permission is missing, the downloader will automatically fall back to normal operation (which may include a foreground service if configured).
  /// [metaData] user data
  /// [displayName] human readable name for this task
  /// [creationTime] time of task creation, 'now' by default.
  /// [options] optional task-specific configuration using [TaskOptions]
  /// [transferHints] optional hints to auto-tune task priority, updates, and pause behavior
  /// [notificationConfig] optional system notification configuration
  /// [stallTimeout] optional duration after which an inactive running transfer is kicked/resumed
  ///
  /// A [ParallelDownloadTask] cannot be paused or resumed on failure
  ParallelDownloadTask({
    super.taskId,
    required dynamic url,
    super.urlQueryParameters,
    super.filename,
    super.headers,
    super.httpRequestMethod,
    this.chunks = 1,
    super.directory,
    super.baseDirectory,
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
  }) : assert(
         url is String || url is List<String>,
         'The `url` parameter must be a string or a list of strings',
       ),
       assert(
         url is String || (url is List<String> && url.isNotEmpty),
         'The list of urls must not be empty',
       ),
       urls = url is String
           ? [urlWithQueryParameters(url, urlQueryParameters)]
           : List.from(
               url.map((e) => urlWithQueryParameters(e, urlQueryParameters)),
             ),
       super(url: url is String ? url : url.first) {
    retriesRemaining = 0; // chunk tasks will retry instead, based on [retries]
  }

  /// Creates [ParallelDownloadTask] object from [json]
  ParallelDownloadTask.fromJson(super.json)
    : assert(
        json['taskType'] == 'ParallelDownloadTask',
        'The provided JSON map is not a ParallelDownloadTask, '
        'because key "taskType" is not "ParallelDownloadTask".',
      ),
      urls = List.from(json['urls'] as List<dynamic>? ?? []),
      chunks = json['chunks'] as int? ?? 1,
      super.fromJson();

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'urls': urls,
    'chunks': chunks,
  };

  @override
  String get taskType => 'ParallelDownloadTask';

  @override
  ParallelDownloadTask copyWith({
    String? taskId,
    String? url,
    String? filename,
    Map<String, String>? headers,
    String? httpRequestMethod,
    Object? post,
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
  }) => ParallelDownloadTask(
    taskId: taskId ?? this.taskId,
    url: url ?? urls,
    filename: filename ?? this.filename,
    headers: headers ?? this.headers,
    httpRequestMethod: httpRequestMethod ?? this.httpRequestMethod,
    chunks: chunks,
    directory: directory ?? this.directory,
    baseDirectory: baseDirectory ?? this.baseDirectory,
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
}

/// Class for background requests that do not involve a file
///
/// Closely resembles a Task, with  fewer fields available during construction
final class DataTask extends Task {
  /// Creates a [DataTask] that runs in the background, but does not involve a
  /// file
  ///
  /// [taskId] must be unique. A unique id will be generated if omitted
  /// [url] properly encoded if necessary, can include query parameters
  /// [urlQueryParameters] may be added and will be appended to the [url], must
  ///   be properly encoded if necessary
  /// [headers] an optional map of HTTP request headers
  /// [httpRequestMethod] the HTTP request method used (e.g. GET, POST)
  /// [post] String post body, encoded in utf8
  /// [json] if given will encode [json] to string and use as the [post] data
  /// [contentType] sets the Content-Type header to this value. If omitted and
  ///   [post] is given, it will be set to 'text-plain; charset=utf-8' and if
  ///   [json] is given, it will be set to 'application/json]
  /// [group] if set allows different callbacks or processing for different
  /// groups
  /// [updates] the kind of progress updates requested (only .status or none)
  /// [requiresWiFi] if set, restricts task to non-metered / non-cellular connections
  /// (on Android API 28+, requires a Wi-Fi or Ethernet connection; on older Android versions, requires an unmetered connection; on iOS, disables cellular access).
  /// If not set, task may execute over cellular or metered networks.
  /// [retries] if >0 will retry a failed download this many times
  /// [priority] in range 0 <= priority <= 10 with 0 highest, defaults to 5.
  /// On Android 14+, setting priority to 0 requires the
  /// `android.permission.RUN_USER_INITIATED_JOBS` permission in AndroidManifest.xml.
  /// If the permission is missing, the downloader will automatically fall back to normal operation (which may include a foreground service if configured).
  /// [metaData] user data
  /// [displayName] human readable name for this task
  /// [creationTime] time of task creation, 'now' by default.
  /// [options] optional task-specific configuration using [TaskOptions]
  /// [transferHints] optional hints to auto-tune task priority, updates, and pause behavior
  /// [notificationConfig] optional system notification configuration
  /// [stallTimeout] optional duration after which an inactive running transfer is kicked/resumed
  DataTask({
    super.taskId,
    required super.url,
    super.urlQueryParameters,
    super.headers,
    super.httpRequestMethod,
    String? post,
    Map<String, dynamic>? json,
    String? contentType,
    super.group,
    super.updates = Updates.status,
    super.requiresWiFi,
    super.retries,
    super.metaData,
    super.displayName,
    super.priority,
    super.creationTime,
    super.options,
    super.transferHints,
    super.notificationConfig,
    super.stallTimeout,
  }) : assert(
         const [Updates.status, Updates.none].contains(updates),
         'DataTasks can only provide status updates',
       ),
       super(
         post: json != null ? jsonEncode(json) : post,
         baseDirectory: BaseDirectory.temporary,
         allowPause: false,
       ) {
    // if no content-type header set, it is set to [contentType] or
    // (if post or json is given) to text/plain or application/json
    if (!headers.containsKey('Content-Type') &&
        !headers.containsKey('content-type')) {
      try {
        if (contentType != null) {
          headers['Content-Type'] = contentType;
        } else if ((post != null || json != null)) {
          assert(
            (post != null) ^ (json != null),
            'Only post or json can be set, not both',
          );
          headers['Content-Type'] = json != null
              ? 'application/json'
              : 'text/plain; charset=utf-8';
        }
      } on UnsupportedError {
        _log.warning(
          'Could not add Content-Type header as supplied header is const',
        );
      }
    }
  }

  @override
  Task copyWith({
    String? taskId,
    String? url,
    String? filename,
    Map<String, String>? headers,
    String? httpRequestMethod,
    Object? post,
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
  }) => DataTask(
    taskId: taskId ?? this.taskId,
    url: url ?? this.url,
    headers: headers ?? this.headers,
    httpRequestMethod: httpRequestMethod ?? this.httpRequestMethod,
    post: post as String? ?? this.post,
    group: group ?? this.group,
    updates: updates ?? this.updates,
    requiresWiFi: requiresWiFi ?? this.requiresWiFi,
    retries: retries ?? this.retries,
    priority: priority ?? this.priority,
    metaData: metaData ?? this.metaData,
    displayName: displayName ?? this.displayName,
    creationTime: creationTime ?? this.creationTime,
    options: options ?? this.options,
    transferHints: transferHints ?? this.transferHints,
    notificationConfig: notificationConfig ?? this.notificationConfig,
    stallTimeout: stallTimeout ?? this.stallTimeout,
  )..retriesRemaining = retriesRemaining ?? this.retriesRemaining;

  /// Creates [DataTask] object from [json]
  DataTask.fromJson(super.json)
    : assert(
        json['taskType'] == 'DataTask',
        'The provided JSON map is not a DataTask, '
        'because key "taskType" is not "DataTask".',
      ),
      super.fromJson();

  @override
  String get taskType => 'DataTask';
}
