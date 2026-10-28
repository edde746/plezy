import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'remote_stream_store.dart';
import 'remote_streaming_provider.dart';
import 'preparation_scheduler.dart';

@pragma('vm:entry-point')
Future<void> remotePreparationEntrypoint() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  final success = await runRemotePreparationWorker();
  await const MethodChannel('org.plezy/preparation.worker').invokeMethod<void>('complete', success);
}

Future<bool> runRemotePreparationWorker() async {
  final worker = RemoteStreamingProvider(backgroundWorker: true);
  try {
    final deadline = DateTime.now().add(const Duration(minutes: 6));
    for (final profile in await RemoteStreamStore.profiles()) {
      if (DateTime.now().isAfter(deadline)) return false;
      await worker.runBackgroundProfile(profile, deadline);
    }
    await RemoteStreamStore.cancelRecoveryWhenIdle(PreparationScheduler.cancel);
    return true;
  } on Object {
    return false;
  } finally {
    worker.dispose();
  }
}

Future<void> runDesktopPreparationWorker() async {
  // Native runners leave the worker window hidden. No app navigation, media
  // server binding, tracking or playback services are started by this entry.
  final success = await runRemotePreparationWorker();
  exit(success ? 0 : 1);
}
