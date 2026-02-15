import 'dart:io' show ProcessInfo;

/// Returns the current resident set size (RSS) of the process in bytes.
int getProcessMemoryRss() {
  try {
    return ProcessInfo.currentRss;
  } catch (_) {
    return 0;
  }
}
