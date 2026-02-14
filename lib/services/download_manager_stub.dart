/// Stub download manager for web platforms where downloads are not available.
///
/// All methods are no-ops or return empty values.
/// This allows the DownloadProvider to be instantiated on web without
/// importing dart:io-dependent code.
library;

import 'dart:async';

import '../models/download_models.dart';
import '../models/plex_metadata.dart';
import '../services/plex_client.dart';
import '../database/app_database.dart';

/// Progress update for a download operation.
class DownloadProgress {
  final String globalKey;
  final double progress;
  final DownloadStatus status;
  final String? error;

  const DownloadProgress({
    required this.globalKey,
    this.progress = 0,
    this.status = DownloadStatus.pending,
    this.error,
  });
}

/// Progress update for a deletion operation.
class DeletionProgress {
  final String globalKey;
  final bool completed;

  const DeletionProgress({required this.globalKey, this.completed = false});
}

/// No-op download manager for platforms without filesystem access.
class DownloadManagerServiceStub {
  final AppDatabase database;

  DownloadManagerServiceStub({required this.database});

  Future<void>? recoveryFuture;

  Stream<DownloadProgress> get progressStream => const Stream.empty();
  Stream<DeletionProgress> get deletionProgressStream => const Stream.empty();

  Future<void> recoverInterruptedDownloads() async {}
  Future<void> queueDownload(PlexClient client, PlexMetadata metadata, {int mediaIndex = 0}) async {}
  Future<void> cancelDownload(String globalKey) async {}
  Future<void> deleteDownload(String globalKey) async {}
  Future<void> resumeQueuedDownloads(PlexClient client) async {}
}
