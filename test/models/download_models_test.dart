import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/download_models.dart';

void main() {
  group('DownloadProgress.determinateProgress', () {
    DownloadProgress p({required DownloadStatus status, int progress = 0, int totalBytes = 0}) =>
        DownloadProgress(globalKey: 'k', status: status, progress: progress, totalBytes: totalBytes);

    test('aggregate (real percent, no totalBytes) stays determinate', () {
      // Regression guard: show/season download buttons read an aggregate
      // DownloadProgress with totalBytes:0 but a meaningful percent — it must
      // not collapse to an indeterminate spinner.
      expect(p(status: DownloadStatus.downloading, progress: 50).determinateProgress, 0.5);
    });

    test('live transcode (no total, no percent) is indeterminate', () {
      expect(p(status: DownloadStatus.downloading).determinateProgress, isNull);
    });

    test('download with a known total is determinate', () {
      expect(p(status: DownloadStatus.downloading, progress: 8, totalBytes: 1000).determinateProgress, 0.08);
    });

    test('non-downloading status keeps its percent', () {
      expect(p(status: DownloadStatus.completed, progress: 100).determinateProgress, 1.0);
    });
  });

  group('DownloadProgress.displayStatus', () {
    DownloadProgress p(DownloadStatus status, {bool running = false}) =>
        DownloadProgress(globalKey: 'k', status: status, running: running);

    test('a held (enqueued, not running) download reads as queued', () {
      // The hard invariant: a queued/held item must never render as Downloading.
      expect(p(DownloadStatus.downloading, running: false).displayStatus, DownloadStatus.queued);
    });

    test('an actively-running download reads as downloading', () {
      expect(p(DownloadStatus.downloading, running: true).displayStatus, DownloadStatus.downloading);
    });

    test('other statuses pass through unchanged regardless of running', () {
      expect(p(DownloadStatus.paused).displayStatus, DownloadStatus.paused);
      expect(p(DownloadStatus.completed).displayStatus, DownloadStatus.completed);
      expect(p(DownloadStatus.queued).displayStatus, DownloadStatus.queued);
    });
  });
}
