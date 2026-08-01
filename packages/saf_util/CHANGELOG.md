## 3.1.0 (Plezy vendored patch)

Vendored from `flutter-cavalry/saf_util` at
`e300a03ea34b49414b42f309e02531ece57cd0d1`. The local Result-lifecycle patch
take-and-clears picker replies, ignores unrelated request codes, reattaches the
listener across configuration changes, and clears state after launch failures.
When updating, reapply those behaviors to every picker request code and run the
Android plugin tests.

## 3.1.0

- Set `length` to -1 when the length is unknown, matching Android `DocumentFile.length()`.

## 3.0.0

- **Breaking**: Migrate to AGP 9.
- **Breaking**: Minimum Flutter version is 3.44.0.

## 2.2.0

- Add `pickMedia`.

## 2.1.0

- Add the `throws` parameter to `stat`.

## 2.0.0

- Update to Kotlin 2.2.0

## 1.0.0

- No changes. This is just a version bump to mark the stable release.

## 0.12.0

- Add `releasePersistedPermission` to release the persisted permission of a URI.

## 0.11.0

- Allow empty names in `.child`, which returns a [DocumentFile] from the first path param (like `stat`).

## 0.10.0

- Add `stat`. Unlike [documentFileFromUri], `stat` returns null if uri does not exist.

## 0.9.0

- Auto detect path type when `documentFileFromUri.isDir` is null.

## 0.8.0

- Add `hasPersistedPermission`.

## 0.7.0

- Add file descriptor support.

## 0.6.2

- Fix length overflow.

## 0.6.1

- Update docs.

## 0.6.0

- Add `pickFiles` and `pickDirectory` to replace `openFile` and `openDirectory`. The new methods return [DocumentFile] instead of Uri string.

## 0.5.0

- Add `openFile` and `openFiles` to open file picker dialog.
- Make sure read permission is always set when write permission is on.

## 0.4.0

- Relax minimum Dart and Flutter versions (Fixes #2).

## 0.3.0

- `saveThumbnailToFile` width and height params should be int.

## 0.2.0

- Add `saveThumbnailToFile`, which supports extracting image and video thumbnails from an SAF [DocumentFile].

## 0.1.0

- Add `writePermission` and `persistablePermission` to openDirectory
- Support renaming on file `DocumentFile`

## 0.0.1

- Initial release.
