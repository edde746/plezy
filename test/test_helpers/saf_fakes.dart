import 'package:plezy/services/saf_storage_service.dart';
import 'package:saf_util/saf_util_platform_interface.dart';

/// Narrow [SafStorageOperations] fake for suites that only need SAF
/// reachability answers — chiefly "is this downloaded `content://` copy still
/// there", which decides local playback versus streaming.
///
/// Every other operation throws: a suite that reaches one of them wants the
/// richer fake beside `download_manager_service_test.dart`, not this one.
class FakeSafStorage implements SafStorageOperations {
  FakeSafStorage({this.reachable = true, this.existing});

  /// Answer for every URI when [existing] was not supplied.
  final bool reachable;

  /// When supplied, the authoritative set of reachable URIs; membership alone
  /// decides and [reachable] is ignored.
  final Set<String>? existing;

  /// URIs passed to [exists], in call order.
  final List<String> existsCalls = [];

  @override
  Future<bool> exists(String uri, {required bool isDir}) async {
    existsCalls.add(uri);
    return existing?.contains(uri) ?? reachable;
  }

  @override
  Future<SafDocumentFile?> getChild(String parentUri, List<String> names) => throw UnsupportedError('getChild');

  @override
  Future<String?> createNestedDirectories(String parentUri, List<String> pathComponents) =>
      throw UnsupportedError('createNestedDirectories');

  @override
  Future<bool> delete(String uri, {required bool isDir}) => throw UnsupportedError('delete');

  @override
  Future<List<SafDocumentFile>?> list(String uri) => throw UnsupportedError('list');

  @override
  Future<String?> resolvePersistedPermissionUri(String uri) => throw UnsupportedError('resolvePersistedPermissionUri');

  @override
  Future<List<String>?> getPersistedPermissionUris() => throw UnsupportedError('getPersistedPermissionUris');

  @override
  Future<bool> releasePersistedPermission(String uri) => throw UnsupportedError('releasePersistedPermission');
}
