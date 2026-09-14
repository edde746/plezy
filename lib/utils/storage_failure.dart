bool isStorageFullError(Object? error) => isStorageFullMessage(error?.toString());

bool isStorageFullMessage(String? message) {
  if (message == null || message.isEmpty) return false;
  final value = message.toLowerCase();
  return value.contains('sqlite_full') ||
      value.contains('database or disk is full') ||
      value.contains('no space left on device') ||
      value.contains('enospc') ||
      value.contains('errno = 112') ||
      value.contains('not enough space on the disk') ||
      value.contains('insufficient space to store') ||
      value.contains('volume is out of space') ||
      value.contains('nsfilewriteoutofspaceerror');
}
