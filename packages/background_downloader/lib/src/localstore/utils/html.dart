import 'dart:async';

import 'utils_impl.dart';

/// Utils class
class Utils implements UtilsImpl {
  Utils._();

  static final Utils _utils = Utils._();

  static Utils get instance => _utils;

  @override
  void clearCache() {
    throw UnimplementedError('Web is not supported');
  }

  @override
  Future<Map<String, dynamic>?> get(
    String path, [
    bool? isCollection = false,
    List<List>? conditions,
  ]) async {
    throw UnimplementedError('Web is not supported');
  }

  @override
  Future<dynamic>? set(Map<String, dynamic> data, String path) {
    throw UnimplementedError('Web is not supported');
  }

  @override
  Future delete(String path) async {
    throw UnimplementedError('Web is not supported');
  }

  @override
  Stream<Map<String, dynamic>> stream(String path, [List<List>? conditions]) {
    throw UnimplementedError('Web is not supported');
  }
}
