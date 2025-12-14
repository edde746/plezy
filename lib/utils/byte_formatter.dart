/// Utility class for formatting byte sizes and speeds
class ByteFormatter {
  ByteFormatter._();

  static const int _kb = 1024;
  static const int _mb = _kb * 1024;
  static const int _gb = _mb * 1024;

  /// Format bytes to human-readable string (e.g., "1.5 GB", "256.3 MB")
  ///
  /// [bytes] The number of bytes to format
  /// [decimals] Number of decimal places (default: 1 for KB/MB, 2 for GB)
  static String formatBytes(int bytes, {int? decimals}) {
    if (bytes < _kb) return '$bytes B';
    if (bytes < _mb) {
      return '${(bytes / _kb).toStringAsFixed(decimals ?? 1)} KB';
    }
    if (bytes < _gb) {
      return '${(bytes / _mb).toStringAsFixed(decimals ?? 1)} MB';
    }
    return '${(bytes / _gb).toStringAsFixed(decimals ?? 2)} GB';
  }

  /// Format speed in bytes per second to human-readable string
  ///
  /// [bytesPerSecond] The speed in bytes per second
  static String formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < _kb) {
      return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    }
    if (bytesPerSecond < _mb) {
      return '${(bytesPerSecond / _kb).toStringAsFixed(1)} KB/s';
    }
    return '${(bytesPerSecond / _mb).toStringAsFixed(1)} MB/s';
  }

  /// Format bitrate in kbps to human-readable string
  ///
  /// [kbps] The bitrate in kilobits per second
  static String formatBitrate(int kbps) {
    if (kbps < 1000) return '$kbps kbps';
    return '${(kbps / 1000).toStringAsFixed(1)} Mbps';
  }

  /// Format bitrate in bps to human-readable string
  ///
  /// [bps] The bitrate in bits per second
  /// Returns formatted string like "8.5 Mbps", "256 Kbps", or "128 bps"
  static String formatBitrateBps(int bps) {
    const kbps = 1000;
    const mbps = kbps * 1000;

    if (bps >= mbps) {
      return '${(bps / mbps).toStringAsFixed(2)} Mbps';
    } else if (bps >= kbps) {
      return '${(bps / kbps).toStringAsFixed(2)} Kbps';
    } else {
      return '$bps bps';
    }
  }
}
