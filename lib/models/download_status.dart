enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
  partial, // Some episodes downloaded, but not all (for shows/seasons)
}
