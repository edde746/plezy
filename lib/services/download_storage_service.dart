import 'dart:convert';

import '../utils/io_helpers.dart';
import '../utils/platform_helper.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../models/plex_metadata.dart';
import '../utils/formatters.dart';
import 'settings_service.dart';
import 'saf_storage_service.dart';

class DownloadStorageService {
  static DownloadStorageService? _instance;
  static DownloadStorageService get instance => _instance ??= DownloadStorageService._();
  DownloadStorageService._();

  Directory? _baseDownloadsDir;
  String? _artworkDirectoryPath;

  // Custom path configuration
  SettingsService? _settingsService;
  String? _customDownloadPath;
  String _customPathType = 'file';

  /// Check if currently using SAF mode (Android only)
  bool get isUsingSaf => AppPlatform.isAndroid && _customPathType == 'saf' && _customDownloadPath != null;

  /// Get the SAF base URI (only valid when isUsingSaf is true)
  String? get safBaseUri => isUsingSaf ? _customDownloadPath : null;

  /// Get artwork directory path (cached, synchronous after first call)
  String? get artworkDirectoryPath => _artworkDirectoryPath;

  /// Initialize with settings service (call during app startup)
  Future<void> initialize(SettingsService settingsService) async {
    _settingsService = settingsService;
    _customDownloadPath = settingsService.getCustomDownloadPath();
    _customPathType = settingsService.getCustomDownloadPathType();
    // Reset cached directories to force recalculation
    _baseDownloadsDir = null;
    _artworkDirectoryPath = null;
  }

  /// Refresh custom path from settings (call when settings change)
  Future<void> refreshCustomPath() async {
    if (_settingsService != null) {
      _customDownloadPath = _settingsService!.getCustomDownloadPath();
      _customPathType = _settingsService!.getCustomDownloadPathType();
      _baseDownloadsDir = null;
      _artworkDirectoryPath = null;
    }
  }

  /// Get the base app directory for storing data.
  /// Uses ApplicationDocumentsDirectory on mobile, ApplicationSupportDirectory on desktop.
  Future<Directory> _getBaseAppDir() async {
    if (AppPlatform.isAndroid || AppPlatform.isIOS) {
      return getApplicationDocumentsDirectory();
    }
    return getApplicationSupportDirectory();
  }

  /// Format episode filename base: S{XX}E{XX} - {Title}
  String _formatEpisodeFileName(PlexMetadata episode) {
    final season = padNumber(episode.parentIndex ?? 0, 2);
    final ep = padNumber(episode.index ?? 0, 2);
    final episodeName = _sanitizeFileName(episode.title);
    return 'S${season}E$ep - $episodeName';
  }

  /// Check if using custom download path
  bool isUsingCustomPath() => _customDownloadPath != null;

  /// Get current download path for display in settings
  Future<String> getCurrentDownloadPathDisplay() async {
    if (_customDownloadPath != null) {
      return _customDownloadPath!;
    }
    final dir = await getDownloadsDirectory();
    return dir.path;
  }

  /// Get default download path (for "Reset to Default" functionality)
  Future<String> getDefaultDownloadPath() async {
    final baseDir = await _getBaseAppDir();
    return path.join(baseDir.path, 'downloads');
  }

  /// Check if a directory is writable
  Future<bool> isDirectoryWritable(Directory dir) async {
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      // Test write access with a temp file
      final testFile = File(path.join(dir.path, '.write_test_${DateTime.now().millisecondsSinceEpoch}'));
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Initialize and get base downloads directory
  Future<Directory> getDownloadsDirectory() async {
    if (_baseDownloadsDir != null) return _baseDownloadsDir!;

    // Check for custom path first (file type only - SAF handled differently)
    if (_customDownloadPath != null && _customPathType == 'file') {
      final customDir = Directory(_customDownloadPath!);
      if (await isDirectoryWritable(customDir)) {
        _baseDownloadsDir = customDir;
        return _baseDownloadsDir!;
      }
      // Fall through to default if custom path is not writable
    }

    // Default path logic
    final baseDir = await _getBaseAppDir();
    _baseDownloadsDir = await _ensureDirectoryExists(Directory(path.join(baseDir.path, 'downloads')));
    return _baseDownloadsDir!;
  }

  /// Get centralized artwork directory for offline artwork caching
  /// This directory stores artwork files with hashed filenames for deduplication
  Future<Directory> getArtworkDirectory() async {
    // If custom download path is set, put artwork alongside downloads
    if (_customDownloadPath != null && _customPathType == 'file') {
      final customDir = Directory(_customDownloadPath!);
      final parent = customDir.parent;
      final artworkDir = Directory(path.join(parent.path, 'artwork'));
      try {
        // Validate writeability for custom artwork path
        if (await isDirectoryWritable(artworkDir)) {
          _artworkDirectoryPath = artworkDir.path;
          return artworkDir;
        }
      } catch (e) {
        // Fall through to default if we can't create artwork dir
      }
    }

    // Default: Get the app base directory directly (not downloads directory)
    final baseDir = await _getBaseAppDir();
    final artworkDir = await _ensureDirectoryExists(Directory(path.join(baseDir.path, 'artwork')));
    // Cache the path for synchronous access
    _artworkDirectoryPath = artworkDir.path;
    return artworkDir;
  }

  /// Get artwork file path from Plex thumb path (synchronous, requires initialization)
  /// Returns path to cached artwork file using hash of the thumb URL
  /// Example: artwork/a1b2c3d4e5f6.jpg
  String getArtworkPathSync(String serverId, String thumbPath) {
    if (_artworkDirectoryPath == null) {
      throw StateError('Artwork directory not initialized. Call getArtworkDirectory() first.');
    }
    // Create hash from serverId:thumbPath for deduplication
    final hash = _hashArtworkPath(serverId, thumbPath);
    return path.join(_artworkDirectoryPath!, '$hash.jpg');
  }

  /// Get artwork file path from Plex thumb path (async version)
  Future<String> getArtworkPathFromThumb(String serverId, String thumbPath) async {
    final artworkDir = await getArtworkDirectory();
    final hash = _hashArtworkPath(serverId, thumbPath);
    return path.join(artworkDir.path, '$hash.jpg');
  }

  /// Check if artwork already exists (for deduplication)
  Future<bool> artworkExists(String serverId, String thumbPath) async {
    final artworkPath = await getArtworkPathFromThumb(serverId, thumbPath);
    return File(artworkPath).exists();
  }

  /// Hash artwork path for filename using MD5 for stability across app restarts
  String _hashArtworkPath(String serverId, String thumbPath) {
    final combined = '$serverId:$thumbPath';
    return md5.convert(utf8.encode(combined)).toString();
  }

  /// Get directory for a specific media item
  Future<Directory> getMediaDirectory(String serverId, String ratingKey) async {
    final baseDir = await getDownloadsDirectory();
    return _ensureDirectoryExists(Directory(path.join(baseDir.path, serverId, ratingKey)));
  }

  /// Get video file path
  Future<String> getVideoFilePath(String serverId, String ratingKey, String extension) async {
    final mediaDir = await getMediaDirectory(serverId, ratingKey);
    return path.join(mediaDir.path, 'video.$extension');
  }

  /// Get artwork file path (poster, art, thumb)
  Future<String> getArtworkPath(String serverId, String ratingKey, String artworkType) async {
    final mediaDir = await getMediaDirectory(serverId, ratingKey);
    return path.join(mediaDir.path, '$artworkType.jpg');
  }

  /// Get subtitles directory
  Future<Directory> getSubtitlesDirectory(String serverId, String ratingKey) async {
    final mediaDir = await getMediaDirectory(serverId, ratingKey);
    final subtitlesDir = Directory(path.join(mediaDir.path, 'subtitles'));
    if (!await subtitlesDir.exists()) {
      await subtitlesDir.create(recursive: true);
    }
    return subtitlesDir;
  }

  /// Get subtitle file path
  Future<String> getSubtitlePath(String serverId, String ratingKey, int trackId, String extension) async {
    final subtitlesDir = await getSubtitlesDirectory(serverId, ratingKey);
    return path.join(subtitlesDir.path, '$trackId.$extension');
  }

  // ============================================================
  // USER-FRIENDLY PATH METHODS (for Files app visibility)
  // ============================================================

  /// Sanitize a filename by removing invalid filesystem characters
  String _sanitizeFileName(String name) {
    // Remove invalid filesystem characters: < > : " / \ | ? *
    // Also remove leading/trailing whitespace and dots
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '').replaceAll(RegExp(r'^\.+|\.+$'), '').trim();
  }

  /// Ensure a directory exists, creating it if necessary
  Future<Directory> _ensureDirectoryExists(Directory dir) async {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Format a media title with optional year: "Title (YYYY)" or "Title"
  String _formatTitleWithYear(String title, int? year) {
    final sanitized = _sanitizeFileName(title);
    return year != null ? '$sanitized ($year)' : sanitized;
  }

  /// Get the folder name for a movie: "Movie Name (YYYY)"
  String _getMovieFolderName(PlexMetadata movie) {
    return _formatTitleWithYear(movie.title, movie.year);
  }

  /// Get the folder name for a TV show: "Show Name (YYYY)"
  /// [showYear]: Pass explicitly for episodes (episode.year may differ from show's year)
  String _getShowFolderName(PlexMetadata metadata, {int? showYear}) {
    final title = metadata.grandparentTitle ?? metadata.title;
    final year = showYear ?? metadata.year;
    return _formatTitleWithYear(title, year);
  }

  /// Get movie directory: downloads/Movies/{Movie Name} ({Year})/
  Future<Directory> getMovieDirectory(PlexMetadata movie) async {
    final baseDir = await getDownloadsDirectory();
    final movieFolder = _getMovieFolderName(movie);
    return _ensureDirectoryExists(Directory(path.join(baseDir.path, 'Movies', movieFolder)));
  }

  /// Get movie video file path: .../Movie Name (YYYY)/Movie Name (YYYY).{ext}
  Future<String> getMovieVideoPath(PlexMetadata movie, String extension) async {
    final movieDir = await getMovieDirectory(movie);
    final fileName = _getMovieFolderName(movie);
    return path.join(movieDir.path, '$fileName.$extension');
  }

  /// Get movie artwork path: .../Movie Name (YYYY)/{artworkType}.jpg
  Future<String> getMovieArtworkPath(PlexMetadata movie, String artworkType) async {
    final movieDir = await getMovieDirectory(movie);
    return path.join(movieDir.path, '$artworkType.jpg');
  }

  /// Get show directory: downloads/TV Shows/{Show Name} ({Year})/
  /// [showYear]: Pass the show's premiere year explicitly (for episodes, the episode's
  /// year may differ from the show's year). If not provided, uses metadata.year.
  Future<Directory> getShowDirectory(PlexMetadata metadata, {int? showYear}) async {
    final baseDir = await getDownloadsDirectory();
    final showFolder = _getShowFolderName(metadata, showYear: showYear);
    return _ensureDirectoryExists(Directory(path.join(baseDir.path, 'TV Shows', showFolder)));
  }

  /// Get show artwork path: downloads/TV Shows/{Show}/poster.jpg
  Future<String> getShowArtworkPath(PlexMetadata metadata, String artworkType, {int? showYear}) async {
    final showDir = await getShowDirectory(metadata, showYear: showYear);
    return path.join(showDir.path, '$artworkType.jpg');
  }

  /// Get season directory: .../TV Shows/{Show}/Season {XX}/
  /// [showYear]: Pass the show's premiere year (not episode or season year)
  Future<Directory> getSeasonDirectory(PlexMetadata metadata, {int? showYear}) async {
    final showDir = await getShowDirectory(metadata, showYear: showYear);
    final seasonNum = padNumber(metadata.parentIndex ?? 0, 2);
    return _ensureDirectoryExists(Directory(path.join(showDir.path, 'Season $seasonNum')));
  }

  /// Get season artwork path: .../Season XX/poster.jpg
  Future<String> getSeasonArtworkPath(PlexMetadata metadata, String artworkType, {int? showYear}) async {
    final seasonDir = await getSeasonDirectory(metadata, showYear: showYear);
    return path.join(seasonDir.path, '$artworkType.jpg');
  }

  /// Get base path info for episode files (season directory path and formatted filename).
  /// [showYear]: Pass the show's premiere year (not episode year)
  Future<({String seasonDirPath, String fileName})> _getEpisodeBasePath(PlexMetadata episode, {int? showYear}) async {
    final seasonDir = await getSeasonDirectory(episode, showYear: showYear);
    final fileName = _formatEpisodeFileName(episode);
    return (seasonDirPath: seasonDir.path, fileName: fileName);
  }

  /// Get episode video file path: .../Season XX/S{XX}E{XX} - {Title}.{ext}
  /// [showYear]: Pass the show's premiere year (not episode year)
  Future<String> getEpisodeVideoPath(PlexMetadata episode, String extension, {int? showYear}) async {
    final base = await _getEpisodeBasePath(episode, showYear: showYear);
    return path.join(base.seasonDirPath, '${base.fileName}.$extension');
  }

  /// Get episode thumbnail path: .../Season XX/S{XX}E{XX} - {Title}.jpg
  /// [showYear]: Pass the show's premiere year (not episode year)
  Future<String> getEpisodeThumbnailPath(PlexMetadata episode, {int? showYear}) async {
    final base = await _getEpisodeBasePath(episode, showYear: showYear);
    return path.join(base.seasonDirPath, '${base.fileName}.jpg');
  }

  /// Get subtitles directory for episode: .../Season XX/S{XX}E{XX} - {Title}_subs/
  /// [showYear]: Pass the show's premiere year (not episode year)
  Future<Directory> getEpisodeSubtitlesDirectory(PlexMetadata episode, {int? showYear}) async {
    final base = await _getEpisodeBasePath(episode, showYear: showYear);
    return _ensureDirectoryExists(Directory(path.join(base.seasonDirPath, '${base.fileName}_subs')));
  }

  /// Get episode subtitle path
  /// [showYear]: Pass the show's premiere year (not episode year)
  Future<String> getEpisodeSubtitlePath(PlexMetadata episode, int trackId, String extension, {int? showYear}) async {
    final subsDir = await getEpisodeSubtitlesDirectory(episode, showYear: showYear);
    return path.join(subsDir.path, '$trackId.$extension');
  }

  /// Get subtitles directory for movie
  Future<Directory> getMovieSubtitlesDirectory(PlexMetadata movie) async {
    final movieDir = await getMovieDirectory(movie);
    final baseName = _getMovieFolderName(movie);
    return _ensureDirectoryExists(Directory(path.join(movieDir.path, '${baseName}_subs')));
  }

  /// Get movie subtitle path
  Future<String> getMovieSubtitlePath(PlexMetadata movie, int trackId, String extension) async {
    final subsDir = await getMovieSubtitlesDirectory(movie);
    return path.join(subsDir.path, '$trackId.$extension');
  }

  /// Delete all files for a media item
  Future<void> deleteMediaFiles(String serverId, String ratingKey) async {
    final mediaDir = await getMediaDirectory(serverId, ratingKey);
    if (await mediaDir.exists()) {
      await mediaDir.delete(recursive: true);
    }
  }

  /// Convert an absolute file path to a relative path (for database storage)
  /// This ensures paths remain valid across app reinstalls on iOS where
  /// the container UUID can change.
  /// Returns a path relative to the app's documents directory.
  Future<String> toRelativePath(String absolutePath) async {
    final baseDir = await _getBaseAppDir();

    // If the path starts with the base directory, strip it
    if (absolutePath.startsWith(baseDir.path)) {
      // Remove the base path and any leading separator
      var relative = absolutePath.substring(baseDir.path.length);
      if (relative.startsWith('/') || relative.startsWith('\\')) {
        relative = relative.substring(1);
      }
      return relative;
    }

    // Already relative or from a different base - return as-is
    return absolutePath;
  }

  /// Convert a relative file path to an absolute path (for file operations)
  /// Reconstructs the full path using the current app documents directory.
  Future<String> toAbsolutePath(String relativePath) async {
    // If it's already an absolute path, return as-is
    if (path.isAbsolute(relativePath)) {
      return relativePath;
    }

    final baseDir = await _getBaseAppDir();
    return path.join(baseDir.path, relativePath);
  }

  /// Convert a potentially absolute path (from old database entries) to absolute
  /// This handles both old absolute paths and new relative paths
  Future<String> ensureAbsolutePath(String storedPath) async {
    if (path.isAbsolute(storedPath)) {
      // Already absolute - check if file exists at this path
      if (await File(storedPath).exists()) {
        return storedPath;
      }
      // File doesn't exist at absolute path - try to reconstruct
      // Extract the relative portion (everything after 'downloads/')
      final downloadsIndex = storedPath.indexOf('downloads/');
      if (downloadsIndex != -1) {
        final relativePart = storedPath.substring(downloadsIndex);
        return await toAbsolutePath(relativePart);
      }
      // Can't reconstruct, return original
      return storedPath;
    }
    // Relative path - convert to absolute
    return await toAbsolutePath(storedPath);
  }

  /// Calculate total storage used by downloads
  Future<int> getTotalStorageUsed() async {
    final baseDir = await getDownloadsDirectory();
    return _calculateDirectorySize(baseDir);
  }

  Future<int> _calculateDirectorySize(Directory dir) async {
    int size = 0;
    if (!await dir.exists()) return size;

    await for (var entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          size += await entity.length();
        } catch (_) {
          // Ignore errors reading file size
        }
      }
    }
    return size;
  }

  /// Format bytes to human readable string
  static String formatBytes(int bytes) => ByteFormatter.formatBytes(bytes);

  // ============================================================
  // SAF (Storage Access Framework) SUPPORT FOR ANDROID
  // ============================================================

  /// Get temporary cache directory for initial downloads
  /// Files are downloaded here first, then copied to SAF if using SAF mode
  Future<Directory> getCacheDownloadDirectory() async {
    final cacheDir = await getApplicationDocumentsDirectory();
    return _ensureDirectoryExists(Directory(path.join(cacheDir.path, '.download_cache')));
  }

  /// Get temporary file path for downloading (before copying to SAF)
  Future<String> getTempDownloadPath(String fileName) async {
    final cacheDir = await getCacheDownloadDirectory();
    return path.join(cacheDir.path, fileName);
  }

  /// Copy a file from temp cache to SAF and return the SAF URI
  /// Returns null if SAF is not available or copy fails
  /// Always cleans up temp file regardless of success/failure
  Future<String?> copyToSaf(String tempFilePath, List<String> pathComponents, String fileName, String mimeType) async {
    if (!isUsingSaf || _customDownloadPath == null) return null;

    final safService = SafStorageService.instance;

    try {
      // Create nested directory structure in SAF
      final targetDirUri = await safService.createNestedDirectories(_customDownloadPath!, pathComponents);

      if (targetDirUri == null) {
        return null;
      }

      // Copy the file to SAF using native copy
      final safUri = await safService.copyFileToSaf(tempFilePath, targetDirUri, fileName, mimeType);

      return safUri;
    } finally {
      // Always clean up temp file regardless of success/failure
      try {
        final tempFile = File(tempFilePath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {
        // Ignore cleanup errors
      }
    }
  }

  /// Get the MIME type for a file extension
  String getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'mp4':
        return 'video/mp4';
      case 'mkv':
        return 'video/x-matroska';
      case 'm4v':
        return 'video/x-m4v';
      case 'avi':
        return 'video/x-msvideo';
      case 'ogv':
        return 'video/ogg';
      case 'webm':
        return 'video/webm';
      case 'srt':
        return 'application/x-subrip';
      case 'vtt':
        return 'text/vtt';
      case 'ass':
      case 'ssa':
        return 'text/x-ssa';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  /// Get path components for SAF based on media type
  /// Returns list of directory names to create under the SAF base
  List<String> getMovieSafPathComponents(PlexMetadata movie) {
    return ['Movies', _getMovieFolderName(movie)];
  }

  /// Get path components for episode SAF storage
  List<String> getEpisodeSafPathComponents(PlexMetadata episode, {int? showYear}) {
    final showFolder = _getShowFolderName(episode, showYear: showYear);
    final seasonNum = padNumber(episode.parentIndex ?? 0, 2);
    return ['TV Shows', showFolder, 'Season $seasonNum'];
  }

  /// Get SAF file name for a movie
  String getMovieSafFileName(PlexMetadata movie, String extension) {
    return '${_getMovieFolderName(movie)}.$extension';
  }

  /// Get SAF file name for an episode
  String getEpisodeSafFileName(PlexMetadata episode, String extension) {
    final fileName = _formatEpisodeFileName(episode);
    return '$fileName.$extension';
  }

  /// Check if a path is a SAF content URI
  bool isSafUri(String storedPath) {
    return storedPath.startsWith('content://');
  }

  /// Get a readable path for a stored path (handles both SAF URIs and file paths)
  /// For SAF URIs, returns the URI as-is (content:// URIs work with media players)
  /// For file paths, ensures the path is absolute
  Future<String> getReadablePath(String storedPath) async {
    if (isSafUri(storedPath)) {
      // SAF content:// URIs are already readable by media players
      return storedPath;
    }
    return await ensureAbsolutePath(storedPath);
  }
}
