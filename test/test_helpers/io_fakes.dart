import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Routes path-provider lookups to isolated directories below [root].
class FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  FakePathProvider(this.root);

  final Directory root;

  @override
  Future<String?> getApplicationDocumentsPath() async => _ensure('documents');

  @override
  Future<String?> getApplicationSupportPath() async => _ensure('support');

  @override
  Future<String?> getApplicationCachePath() async => _ensure('cache');

  @override
  Future<String?> getTemporaryPath() async => _ensure('temp');

  String _ensure(String name) {
    final path = p.join(root.path, name);
    Directory(path).createSync(recursive: true);
    return path;
  }
}

/// Returns one deterministic streamed response for every request.
class FakeHttpClient extends http.BaseClient {
  FakeHttpClient(this.statusCode, this.body);

  final int statusCode;
  final List<int> body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(Stream<List<int>>.value(body), statusCode, request: request);
  }
}
