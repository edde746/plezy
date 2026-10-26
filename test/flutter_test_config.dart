import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:plezy/services/credential_key_store.dart';

/// Tests never use the host OS credential store. Do not initialize a widget
/// binding here: that changes HTTP behavior for the real loopback network tests.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  FlutterSecureStorage.setMockInitialValues({});
  CredentialKeyStore.useFederatedStoreForTesting = true;
  await testMain();
}
