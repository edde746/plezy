import 'package:flutter/foundation.dart';

/// No share-intent receiver is available on this platform.
final class IncomingSubtitleShareService {
  IncomingSubtitleShareService._();

  static final IncomingSubtitleShareService instance = IncomingSubtitleShareService._();
  static final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  Future<void> start() async {}
  Future<List<String>> takeAll() async => const <String>[];
  Future<void> dispose() async {}
}
