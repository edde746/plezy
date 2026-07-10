import 'saf_util_platform_interface.dart';

class SafUtil {
  /// Shows a folder picker dialog and returns the selected folder as [SafDocumentFile].
  ///
  /// [initialUri] is the initial URI to show in the dialog.
  /// [writePermission] is true if the folder should have write permission.
  /// [persistablePermission] is true if the permission should be persistable.
  Future<SafDocumentFile?> pickDirectory(
      {String? initialUri,
      bool? writePermission,
      bool? persistablePermission}) {
    return SafUtilPlatform.instance.pickDirectory(
        initialUri: initialUri,
        writePermission: writePermission,
        persistablePermission: persistablePermission);
  }

  /// Shows a file picker dialog and returns the selected file [SafDocumentFile].
  /// This calls [pickFiles] with [multiple] set to false.
  ///
  /// [initialUri] is the initial URI to show in the dialog.
  /// [mimeTypes] is a list of MIME types to filter the files.
  Future<SafDocumentFile?> pickFile({
    String? initialUri,
    List<String>? mimeTypes,
  }) {
    return SafUtilPlatform.instance.pickFile(
      initialUri: initialUri,
      mimeTypes: mimeTypes,
    );
  }

  /// Shows a file picker dialog and returns a list of selected file [SafDocumentFile].
  ///
  /// [initialUri] is the initial URI to show in the dialog.
  /// [mimeTypes] is a list of MIME types to filter the files.
  /// [multiple] is true if multiple files can be selected.
  Future<List<SafDocumentFile>?> pickFiles({
    String? initialUri,
    List<String>? mimeTypes,
    multiple = true,
  }) {
    return SafUtilPlatform.instance.pickFiles(
      initialUri: initialUri,
      mimeTypes: mimeTypes,
      multiple: multiple,
    );
  }

  /// Lists the contents of the specified directory URI.
  /// Returns a list of [SafDocumentFile] objects.
  ///
  /// [uri] is the URI of the directory.
  Future<List<SafDocumentFile>> list(String uri) {
    return SafUtilPlatform.instance.list(uri);
  }

  /// Gets a [SafDocumentFile] object from the specified URI.
  ///
  /// [uri] is the URI of the file or directory.
  /// [isDir] is true if the URI is a directory. [null] means
  /// auto-detect.
  Future<SafDocumentFile?> documentFileFromUri(String uri, bool? isDir) {
    return SafUtilPlatform.instance.documentFileFromUri(uri, isDir);
  }

  /// Gets a [SafDocumentFile] object from the specified URI.
  /// Unlike [documentFileFromUri], this method returns null
  /// if the URI does not exist.
  ///
  /// [uri] is the URI of the file or directory.
  /// [isDir] is true if the URI is a directory. [null] means
  /// auto-detect.
  Future<SafDocumentFile?> stat(String uri, bool? isDir) {
    return SafUtilPlatform.instance.stat(uri, isDir);
  }

  /// Checks if the specified file or directory exists.
  ///
  /// [uri] is the URI of the file or directory.
  /// [isDir] is true if the URI is a directory.
  Future<bool> exists(String uri, bool isDir) {
    return SafUtilPlatform.instance.exists(uri, isDir);
  }

  /// Deletes the specified file or directory.
  ///
  /// [uri] is the URI of the file or directory.
  /// [isDir] is true if the URI is a directory.
  Future<void> delete(String uri, bool isDir) {
    return SafUtilPlatform.instance.delete(uri, isDir);
  }

  /// Creates a directory and all its parent directories.
  /// Returns the created directory as a [SafDocumentFile] object.
  ///
  /// [uri] is the URI of the directory to create.
  /// [names] is a list of directory names to create.
  Future<SafDocumentFile> mkdirp(String uri, List<String> names) {
    return SafUtilPlatform.instance.mkdirp(uri, names);
  }

  /// Gets the child file or directory with the specified name.
  ///
  /// [uri] is the URI of the parent directory.
  /// [names] is a list of directory names to traverse.
  Future<SafDocumentFile?> child(String uri, List<String> names) {
    return SafUtilPlatform.instance.child(uri, names);
  }

  /// Renames the specified file or directory.
  /// Returns the renamed file or directory as a [SafDocumentFile] object.
  ///
  /// [uri] is the URI of the file or directory.
  /// [isDir] is true if the URI is a directory.
  /// [newName] is the new name of the file or directory.
  Future<SafDocumentFile> rename(String uri, bool isDir, String newName) {
    return SafUtilPlatform.instance.rename(uri, isDir, newName);
  }

  /// Moves the specified file or directory to a new parent directory.
  /// Returns the moved file or directory as a [SafDocumentFile] object.
  ///
  /// [uri] is the URI of the file or directory.
  /// [parentUri] is the URI of the current parent directory.
  /// [newParentUri] is the URI of the new parent directory.
  Future<SafDocumentFile> moveTo(
      String uri, bool isDir, String parentUri, String newParentUri) {
    return SafUtilPlatform.instance.moveTo(uri, isDir, parentUri, newParentUri);
  }

  /// Copies the specified file or directory to a new parent directory.
  /// Returns the copied file or directory as a [SafDocumentFile] object.
  ///
  /// [uri] is the URI of the file or directory.
  /// [newParentUri] is the URI of the new parent directory.
  Future<SafDocumentFile> copyTo(String uri, bool isDir, String newParentUri) {
    return SafUtilPlatform.instance.copyTo(uri, isDir, newParentUri);
  }

  /// Saves the thumbnail of the specified document [uri] to a local file [destPath].
  /// Image and video thumbnails are supported.
  /// Returns true if the thumbnail is saved successfully, or false if no
  /// thumbnail found in the document.
  ///
  /// [uri] is the URI of the document.
  /// [destPath] is the destination file path to save the thumbnail.
  /// [width] is the max width of the thumbnail.
  /// [height] is the max height of the thumbnail.
  /// [format] is the format of the thumbnail file, default is 'jpeg'.
  /// Supported formats are 'jpeg' and 'png'.
  /// [quality] is the quality of the thumbnail file,
  /// defaults to 80 for 'jpeg' and 100 for 'png'.
  Future<bool> saveThumbnailToFile({
    required String uri,
    required int width,
    required int height,
    required String destPath,
    String? format,
    int? quality,
  }) {
    return SafUtilPlatform.instance.saveThumbnailToFile(
      uri: uri,
      width: width,
      height: height,
      destPath: destPath,
      format: format,
      quality: quality,
    );
  }

  /** Deprecated functions. */

  /// Shows a folder picker dialog and returns the selected folder URI.
  ///
  /// [initialUri] is the initial URI to show in the dialog.
  /// [writePermission] is true if the folder should have write permission.
  /// [persistablePermission] is true if the permission should be persistable.
  @Deprecated('Use [pickDirectory] instead, which returns a [SafDocumentFile].')
  Future<String?> openDirectory(
      {String? initialUri,
      bool? writePermission,
      bool? persistablePermission}) {
    return SafUtilPlatform.instance.openDirectory(
        initialUri: initialUri,
        writePermission: writePermission,
        persistablePermission: persistablePermission);
  }

  /// Shows a file picker dialog and returns the selected file URI.
  /// This calls [openFiles] with [multiple] set to false.
  ///
  /// [initialUri] is the initial URI to show in the dialog.
  /// [mimeTypes] is a list of MIME types to filter the files.
  @Deprecated('Use [pickFile] instead, which returns a [SafDocumentFile].')
  Future<String?> openFile({
    String? initialUri,
    List<String>? mimeTypes,
  }) {
    return SafUtilPlatform.instance.openFile(
      initialUri: initialUri,
      mimeTypes: mimeTypes,
    );
  }

  /// Shows a file picker dialog and returns a list of selected file URIs.
  ///
  /// [initialUri] is the initial URI to show in the dialog.
  /// [mimeTypes] is a list of MIME types to filter the files.
  @Deprecated('Use [pickFiles] instead, which returns a [SafDocumentFile].')
  Future<List<String>?> openFiles({
    String? initialUri,
    List<String>? mimeTypes,
    multiple = true,
  }) {
    return SafUtilPlatform.instance.openFiles(
      initialUri: initialUri,
      mimeTypes: mimeTypes,
      multiple: multiple,
    );
  }

  /// Gets the file descriptor of the specified URI.
  Future<int> getFileDescriptor(String uri) {
    return SafUtilPlatform.instance.getFileDescriptor(uri);
  }

  /// Closes the specified file descriptor.
  Future<void> closeFileDescriptor(int fd) {
    return SafUtilPlatform.instance.closeFileDescriptor(fd);
  }

  /// Checks if the specified URI has persisted permission.
  /// Use [checkRead] and [checkWrite] to specify the type of permission to check.
  /// [checkRead] defaults to true.
  /// [checkWrite] defaults to false.
  Future<bool> hasPersistedPermission(
    String uri, {
    bool checkRead = true,
    bool checkWrite = false,
  }) {
    return SafUtilPlatform.instance.hasPersistedPermission(uri,
        checkRead: checkRead, checkWrite: checkWrite);
  }

  /// Releases the persisted permission of the specified URI.
  /// Use [read] and [write] to specify the type of permission to release.
  /// [read] defaults to true.
  /// [write] defaults to false.
  Future<void> releasePersistedPermission(String uri,
      {bool read = true, bool write = false}) async {
    return SafUtilPlatform.instance
        .releasePersistedPermission(uri, read: read, write: write);
  }
}
