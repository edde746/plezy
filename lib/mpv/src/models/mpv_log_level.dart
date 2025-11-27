/// Log level for MPV player messages.
enum MpvLogLevel {
  /// No logging.
  none,

  /// Fatal errors only.
  fatal,

  /// Errors.
  error,

  /// Warnings.
  warn,

  /// Informational messages.
  info,

  /// Verbose output.
  verbose,

  /// Debug messages.
  debug,

  /// Trace-level output (very verbose).
  trace,
}
