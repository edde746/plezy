import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit/widget tests never read or mutate the host user's OS credential store.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('com.plezy/credential_keys'),
    (call) async {
      final args = call.arguments as Map;
      const storage = FlutterSecureStorage();
      if (call.method == 'read') return storage.read(key: args['key'] as String);
      if (call.method == 'write') {
        await storage.write(key: args['key'] as String, value: args['value'] as String);
        return null;
      }
      throw MissingPluginException();
    },
  );
  await testMain();
}
