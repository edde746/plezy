import 'dart:convert';

const _exceptions = {
  'TaskException': TaskException.new,
  'TaskFileSystemException': TaskFileSystemException.new,
  'TaskUrlException': TaskUrlException.new,
  'TaskConnectionException': TaskConnectionException.new,
  'TaskResumeException': TaskResumeException.new,
  'TaskHttpException': TaskHttpException.new,
};

/// Storage refusals need fresh user action, not an automatic transfer retry.
bool isDownloadStorageFailure(TaskException? exception) {
  if (exception is! TaskFileSystemException) return false;
  final description = exception.description.toLowerCase();
  return description.contains('insufficient space to store') ||
      description.contains('download storage capacity could not be determined') ||
      description.contains('no space left on device') ||
      description.contains('enospc');
}

/// Contains Exception information associated with a failed [Task]
///
/// The [exceptionType] categorizes and describes the exception
/// The [description] is typically taken from the platform-generated
/// exception message, or from the plugin. The localization is undefined
/// For the [TaskHttpException], the [httpResponseCode] is only valid if >0
/// and may offer details about the nature of the error
base class TaskException(final String description) implements Exception {
  String get exceptionType => 'TaskException';

  /// Create object from [json]
  factory TaskException.fromJson(Map<String, dynamic> json) {
    final typeString = json['type'] as String? ?? 'TaskException';
    final exceptionType = _exceptions[typeString];
    final description = json['description'] as String? ?? '';
    if (exceptionType != null) {
      final httpResponseCode =
          (json['httpResponseCode'] as num?)?.toInt() ?? -1;
      return typeString != 'TaskHttpException'
          ? exceptionType(description)
          : exceptionType(description, httpResponseCode);
    }
    return TaskException('Unknown');
  }

  /// Create object from String description of the type, and parameters
  factory TaskException.fromTypeString(
    String typeString,
    String description, [
    int httpResponseCode = -1,
  ]) {
    final exceptionType = _exceptions[typeString] ?? TaskException.new;
    return typeString != 'TaskHttpException'
        ? exceptionType(description)
        : exceptionType(description, httpResponseCode);
  }

  /// Return JSON Map representing object
  Map<String, dynamic> toJson() => {
    'type': exceptionType,
    'description': description,
  };

  /// Return JSON String representing object
  String toJsonString() => jsonEncode(toJson());

  @override
  String toString() => '$exceptionType: $description';
}

/// Exception related to the filesystem, e.g. insufficient space
/// or file not found
final class TaskFileSystemException(super.description) extends TaskException {
  @override
  String get exceptionType => 'TaskFileSystemException';
}

/// Exception related to the url, eg malformed
final class TaskUrlException(super.description) extends TaskException {
  @override
  String get exceptionType => 'TaskUrlException';
}

/// Exception related to the connection, e.g. socket exception
/// or request timeout
final class TaskConnectionException(super.description) extends TaskException {
  @override
  String get exceptionType => 'TaskConnectionException';
}

/// Exception related to an attempt to resume a task, e.g.
/// the temp filename no longer exists, or eTag has changed
final class TaskResumeException(super.description) extends TaskException {
  @override
  String get exceptionType => 'TaskResumeException';
}

/// Exception related to the HTTP response, e.g. a 403
/// response code
final class TaskHttpException(super.description, final int httpResponseCode)
    extends TaskException {
  @override
  String get exceptionType => 'TaskHttpException';

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'httpResponseCode': httpResponseCode,
  };

  @override
  String toString() =>
      '$exceptionType, response code $httpResponseCode: $description';
}
