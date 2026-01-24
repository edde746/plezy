import 'dart:async';

import '../models.dart';
import 'player_streams.dart';

/// Mixin providing stream controllers for player state changes.
///
/// This mixin contains the 16 stream controllers used by both
/// [PlayerAndroid] and [PlayerNative] implementations.
mixin PlayerStreamControllersMixin {
  // Stream controllers
  final playingController = StreamController<bool>.broadcast();
  final completedController = StreamController<bool>.broadcast();
  final bufferingController = StreamController<bool>.broadcast();
  final positionController = StreamController<Duration>.broadcast();
  final durationController = StreamController<Duration>.broadcast();
  final bufferController = StreamController<Duration>.broadcast();
  final volumeController = StreamController<double>.broadcast();
  final rateController = StreamController<double>.broadcast();
  final tracksController = StreamController<Tracks>.broadcast();
  final trackController = StreamController<TrackSelection>.broadcast();
  final logController = StreamController<PlayerLog>.broadcast();
  final errorController = StreamController<String>.broadcast();
  final audioDeviceController = StreamController<AudioDevice>.broadcast();
  final audioDevicesController = StreamController<List<AudioDevice>>.broadcast();
  final playbackRestartController = StreamController<void>.broadcast();
  final backendSwitchedController = StreamController<void>.broadcast();

  /// Creates a [PlayerStreams] instance from the stream controllers.
  PlayerStreams createStreams() {
    return PlayerStreams(
      playing: playingController.stream,
      completed: completedController.stream,
      buffering: bufferingController.stream,
      position: positionController.stream,
      duration: durationController.stream,
      buffer: bufferController.stream,
      volume: volumeController.stream,
      rate: rateController.stream,
      tracks: tracksController.stream,
      track: trackController.stream,
      log: logController.stream,
      error: errorController.stream,
      audioDevice: audioDeviceController.stream,
      audioDevices: audioDevicesController.stream,
      playbackRestart: playbackRestartController.stream,
      backendSwitched: backendSwitchedController.stream,
    );
  }

  /// Closes all stream controllers.
  Future<void> closeStreamControllers() async {
    await playingController.close();
    await completedController.close();
    await bufferingController.close();
    await positionController.close();
    await durationController.close();
    await bufferController.close();
    await volumeController.close();
    await rateController.close();
    await tracksController.close();
    await trackController.close();
    await logController.close();
    await errorController.close();
    await audioDeviceController.close();
    await audioDevicesController.close();
    await playbackRestartController.close();
    await backendSwitchedController.close();
  }
}
