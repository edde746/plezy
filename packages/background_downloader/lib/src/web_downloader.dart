import 'dart:async';

import 'package:http/http.dart' as http;

import 'base_downloader.dart';
import 'models.dart';
import 'task.dart';

/// This is a non-functional stub
///
/// This file is conditionally imported when the compilation target for an
/// application is the Web platform. Without the conditional import, the
/// regular [DesktopDownloader] from desktop_downloader.dart would be used,
/// and it does not compile for Web. This stub prevents that compilation error,
/// but it is not an actual implementation for the Web.

final class DesktopDownloader extends BaseDownloader {
  static var httpClient = http.Client();
  static Duration? requestTimeout;
  static var proxy = <String, dynamic>{}; // 'address' and 'port'
  static var bypassTLSCertificateValidation = false;
  static var mtlsConfigs = <MTLSConfig>[];

  /// Sets the HTTP client used for requests
  ///
  /// This is a stub implementation
  static void setHttpClient(
    Duration? requestTimeout,
    Map<String, dynamic> proxy,
    bool bypassTLSCertificateValidation, [
    List<MTLSConfig>? mtlsConfigs,
  ]) {
    requestTimeout = requestTimeout;
    proxy = proxy;
    bypassTLSCertificateValidation = bypassTLSCertificateValidation;
  }

  /// Returns an [http.Client] configured for the given [url].
  static http.Client httpClientForUrl(String? url) => httpClient;

  /// Returns an [http.Client] configured for the given [host].
  static http.Client httpClientForHost(String? host) => httpClient;

  @override
  Future<bool> cancelPlatformTasksWithIds(List<String> taskIds) {
    throw UnimplementedError();
  }

  @override
  Future<List<DownloadTask>> pauseAll({
    Iterable<DownloadTask>? tasks,
    String? group,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<bool>> pauseTaskList(Iterable<Task> tasksToPause) {
    throw UnimplementedError();
  }

  @override
  Future<(String, String)> configureItem((String, dynamic) configItem) {
    throw UnimplementedError();
  }

  @override
  Future<Duration> getTaskTimeout() {
    throw UnimplementedError();
  }

  @override
  Future<bool> openFile(Task? task, String? filePath, String? mimeType) {
    throw UnimplementedError();
  }

  @override
  Future<bool> pause(Task task) {
    throw UnimplementedError();
  }

  @override
  platformConfig({globalConfig, androidConfig, iOSConfig, desktopConfig}) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, String>> popUndeliveredData(Undelivered dataType) {
    throw UnimplementedError();
  }

  @override
  Future<void> setForceFailPostOnBackgroundChannel(bool value) {
    throw UnimplementedError();
  }

  @override
  Future<String> testSuggestedFilename(
    DownloadTask task,
    String contentDisposition,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<bool>> enqueueAll(Iterable<Task> tasks) {
    throw UnimplementedError();
  }
}
