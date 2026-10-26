import 'package:flutter/widgets.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/multiview/workspace_controller.dart';
import 'package:plezy/multiview/workspace_models.dart';
import 'package:plezy/multiview/workspace_persistence.dart';
import 'package:plezy/services/playback_coordinator.dart';

class _MemoryWorkspacePersistence implements WorkspaceSnapshotPersistence {
  WorkspaceSnapshot? snapshot;
  final List<String> writtenProfiles = <String>[];

  @override
  Future<WorkspaceSnapshot?> read(String profileId) async => snapshot;

  @override
  Future<void> write(String profileId, WorkspaceSnapshot value) async {
    writtenProfiles.add(profileId);
    snapshot = value;
  }
}

WorkspaceSessionDescriptor _descriptor(
  String id, {
  bool hasAudio = false,
  bool hasVideo = false,
  bool acceptsInput = false,
  MultiviewMediaKind? kind,
}) => WorkspaceSessionDescriptor(
  id: id,
  kind: kind ?? (hasVideo ? MultiviewMediaKind.video : MultiviewMediaKind.publication),
  title: id,
  hasAudio: hasAudio,
  hasVideo: hasVideo,
  acceptsInput: acceptsInput,
  openedAt: DateTime.utc(2026, 1, 1),
);

WorkspaceSurfaceRegistration _registration(
  WorkspaceSessionDescriptor descriptor, {
  void Function()? onRestore,
  void Function()? onClose,
  WorkspaceOwnershipHandler? onAudioOwnershipChanged,
  WorkspaceOwnershipHandler? onInputOwnershipChanged,
}) => WorkspaceSurfaceRegistration(
  descriptor: descriptor,
  buildSurface: (_) => const SizedBox.shrink(),
  onRestore: onRestore ?? () {},
  onClose: onClose,
  onAudioOwnershipChanged: onAudioOwnershipChanged ?? (descriptor.hasAudio ? (_) {} : null),
  onInputOwnershipChanged: onInputOwnershipChanged ?? (descriptor.acceptsInput ? (_) {} : null),
);

void main() {
  group('WorkspacePlacement', () {
    test('clamps movement and resize into the normalized viewport', () {
      final placement = const WorkspacePlacement.initial().withDelta(left: 0.95, top: 0.95, width: 0.9, height: 0.9);

      expect(placement.left, closeTo(0.1, 0.0001));
      expect(placement.top, closeTo(0.1, 0.0001));
      expect(placement.width, 0.9);
      expect(placement.height, 0.9);
    });

    test('resolves normalized placement directly against the viewport', () {
      expect(
        const WorkspacePlacement.initial().resolveTopLeft(const Size(800, 600), windowWidth: 352, windowHeight: 204),
        const Offset(432, 348),
      );
      expect(
        const WorkspacePlacement(
          left: 0.9,
          top: 0.9,
          width: 0.5,
          height: 0.5,
        ).resolveTopLeft(const Size(800, 600), windowWidth: 400, windowHeight: 300),
        const Offset(400, 300),
      );
    });

    test('round trips a versioned snapshot without runtime surfaces', () {
      final descriptor = _descriptor(
        'movie-1',
        hasAudio: true,
        hasVideo: true,
      ).copyWith(mediaKey: 'server-a:movie-1', progressOwner: 'profile-a:movie-1');
      final snapshot = WorkspaceSnapshot(
        sessions: [descriptor],
        placements: const {'movie-1': WorkspacePlacement.initial()},
        layoutMode: MultiviewLayoutMode.floating,
        focusedSessionId: 'movie-1',
        audibleSessionId: 'movie-1',
      );

      final decoded = WorkspaceSnapshot.fromJson(snapshot.toJson());

      expect(decoded.schemaVersion, WorkspaceSnapshot.currentSchemaVersion);
      expect(decoded.sessions.single.id, 'movie-1');
      expect(decoded.sessions.single.mediaKey, 'server-a:movie-1');
      expect(decoded.placements['movie-1']?.left, closeTo(0.54, 0.0001));
      expect(decoded.audibleSessionId, 'movie-1');
      expect(decoded.toJson().toString(), isNot(contains('headers')));
      expect(decoded.toJson().toString(), isNot(contains('token')));
    });

    test('reads legacy layout snapshots and preserves an explicit muted choice', () {
      final legacy = WorkspaceSnapshot.fromJson({
        'schemaVersion': 1,
        'sessions': [_descriptor('a', hasAudio: true).toJson()],
        'placements': {'a': const WorkspacePlacement.initial().toJson()},
        'layoutMode': 'floating',
        'audibleSessionId': 'a',
      });
      expect(legacy.schemaVersion, WorkspaceSnapshot.currentSchemaVersion);
      expect(legacy.audioSelectionExplicit, isTrue);

      final muted = WorkspaceSnapshot(
        sessions: [_descriptor('a', hasAudio: true)],
        placements: const {},
        layoutMode: MultiviewLayoutMode.floating,
        audioSelectionExplicit: true,
      );
      expect(WorkspaceSnapshot.fromJson(muted.toJson()).audioSelectionExplicit, isTrue);
    });

    test('keeps geometry history for sessions that are not reopened automatically', () {
      final saved = WorkspaceSnapshot(
        sessions: [_descriptor('music:active', hasAudio: true)],
        placements: const {
          'music:active': WorkspacePlacement(left: 0.1, top: 0.2, width: 0.5, height: 0.3),
          'video:server:item': WorkspacePlacement(left: 0.3, top: 0.4, width: 0.4, height: 0.35),
        },
        layoutMode: MultiviewLayoutMode.floating,
      );

      final decoded = WorkspaceSnapshot.fromJson(saved.toJson());

      expect(decoded.placements.keys, contains('video:server:item'));
    });

    test('rejects duplicate IDs and unsupported snapshot versions', () {
      final descriptor = _descriptor('same');
      final duplicate = WorkspaceSnapshot(
        sessions: [descriptor, descriptor],
        placements: const {},
        layoutMode: MultiviewLayoutMode.floating,
      );

      expect(() => WorkspaceSnapshot.fromJson(duplicate.toJson()), throwsFormatException);
      expect(() => WorkspaceSnapshot.fromJson({'schemaVersion': 99}), throwsFormatException);
    });
  });

  group('MultiviewWorkspaceController', () {
    test('descriptor copyWith updates the media kind', () {
      final descriptor = _descriptor('reader', hasAudio: true, kind: MultiviewMediaKind.audiobook);

      final updated = descriptor.copyWith(kind: MultiviewMediaKind.video, hasVideo: true);

      expect(updated.kind, MultiviewMediaKind.video);
      expect(updated.hasVideo, isTrue);
      expect(updated.id, 'reader');
    });

    test('hydrates profile layout before matching live sessions and saves changes', () async {
      final persistence = _MemoryWorkspacePersistence()
        ..snapshot = WorkspaceSnapshot(
          sessions: [_descriptor('music', hasAudio: true, kind: MultiviewMediaKind.music)],
          placements: const {'music': WorkspacePlacement(left: 0.1, top: 0.2, width: 0.5, height: 0.3)},
          layoutMode: MultiviewLayoutMode.sideBySide,
          focusedSessionId: 'music',
          audioSelectionExplicit: true,
        );
      final controller = MultiviewWorkspaceController(persistence: persistence, profileId: 'profile-a');

      await controller.hydrate();
      controller.register(_registration(_descriptor('music', hasAudio: true, kind: MultiviewMediaKind.music)));
      await Future<void>.delayed(Duration.zero);

      expect(controller.layoutMode, MultiviewLayoutMode.sideBySide);
      expect(controller.placementFor('music').left, closeTo(0.1, 0.0001));
      expect(controller.focusedSessionId, 'music');
      expect(controller.audibleSessionId, isNull);

      controller.moveToCorner('music', right: false, bottom: false);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(persistence.writtenProfiles, ['profile-a']);
      expect(persistence.snapshot!.placements['music']!.left, 0);
      controller.dispose();
    });

    test('requires audio and input ownership handlers for those capabilities', () {
      final controller = MultiviewWorkspaceController();
      final audioWithoutOwner = WorkspaceSurfaceRegistration(
        descriptor: _descriptor('audio', hasAudio: true),
        buildSurface: (_) => const SizedBox.shrink(),
        onRestore: () {},
      );
      final inputWithoutOwner = WorkspaceSurfaceRegistration(
        descriptor: _descriptor('game', acceptsInput: true, kind: MultiviewMediaKind.game),
        buildSurface: (_) => const SizedBox.shrink(),
        onRestore: () {},
      );

      expect(controller.register(audioWithoutOwner), isFalse);
      expect(controller.register(inputWithoutOwner), isFalse);
      expect(controller.sessionCount, 0);
      controller.dispose();
    });

    test('rejects duplicate IDs without replacing the live adapter', () {
      final controller = MultiviewWorkspaceController();
      var firstRestores = 0;
      var secondRestores = 0;
      final descriptor = _descriptor('same');

      expect(controller.register(_registration(descriptor, onRestore: () => firstRestores++)), isTrue);
      expect(controller.register(_registration(descriptor, onRestore: () => secondRestores++)), isFalse);

      controller.restore('same');

      expect(firstRestores, 1);
      expect(secondRestores, 0);
      controller.dispose();
    });

    test('keeps one explicit audible and input owner', () async {
      final controller = MultiviewWorkspaceController();
      controller.register(_registration(_descriptor('video', hasAudio: true, hasVideo: true)));
      controller.register(_registration(_descriptor('game', acceptsInput: true)));
      await Future<void>.delayed(Duration.zero);

      expect(controller.audibleSessionId, 'video');
      expect(controller.inputSessionId, isNull);
      expect(await controller.setAudibleSession('game'), isFalse);
      expect(await controller.setInputSession('video'), isFalse);
      expect(await controller.setInputSession('game'), isTrue);
      expect(await controller.setAudibleSession(null), isTrue);

      controller.dispose();
    });

    test('publishes the selected audio owner to playback claims', () async {
      final controller = MultiviewWorkspaceController();
      controller.register(_registration(_descriptor('video', hasAudio: true, hasVideo: true)));
      controller.register(_registration(_descriptor('music', hasAudio: true, kind: MultiviewMediaKind.music)));
      await Future<void>.delayed(Duration.zero);

      expect(PlaybackCoordinator.instance.workspaceHasCompetingAudioOwner, isTrue);
      await controller.setAudibleSession('music');
      expect(PlaybackCoordinator.instance.workspaceHasCompetingAudioOwner, isFalse);
      await controller.setAudibleSession(null);
      expect(PlaybackCoordinator.instance.workspaceHasCompetingAudioOwner, isTrue);

      controller.dispose();
      expect(PlaybackCoordinator.instance.workspaceHasCompetingAudioOwner, isFalse);
    });

    test('only the focused game receives workspace input', () async {
      final controller = MultiviewWorkspaceController();
      final gameInput = <bool>[];
      controller.register(
        _registration(_descriptor('game', acceptsInput: true), onInputOwnershipChanged: gameInput.add),
      );
      await controller.setInputSession('game');
      controller.register(_registration(_descriptor('video')));
      await Future<void>.delayed(Duration.zero);

      expect(controller.inputSessionId, 'game');
      controller.focus('video');
      await Future<void>.delayed(Duration.zero);
      expect(controller.inputSessionId, isNull);

      controller.focus('game');
      await Future<void>.delayed(Duration.zero);
      expect(controller.inputSessionId, 'game');
      expect(gameInput, [true, false, true]);

      controller.dispose();
    });

    test('focus and layout are independent from audio ownership', () async {
      final controller = MultiviewWorkspaceController();
      controller.register(_registration(_descriptor('a', hasAudio: true)));
      controller.register(_registration(_descriptor('b', hasAudio: true)));

      await controller.setAudibleSession('a');
      controller.focus('b');
      controller.setLayoutMode(MultiviewLayoutMode.sideBySide);

      expect(controller.focusedSessionId, 'b');
      expect(controller.audibleSessionId, 'a');
      expect(controller.layoutMode, MultiviewLayoutMode.sideBySide);
      expect(controller.focusNext(), isTrue);
      expect(controller.focusedSessionId, 'a');

      controller.dispose();
    });

    test('restore returns the exact session and removes its overlay entry', () {
      final controller = MultiviewWorkspaceController();
      var restored = 0;
      controller.register(_registration(_descriptor('movie', hasVideo: true), onRestore: () => restored++));

      expect(controller.hasVisibleSessions, isTrue);
      expect(controller.restore('movie'), isTrue);
      expect(controller.hasVisibleSessions, isFalse);
      expect(restored, 1);
      expect(controller.restore('movie'), isFalse);

      controller.dispose();
    });

    test('close uses the session close policy and repairs owners', () async {
      final controller = MultiviewWorkspaceController();
      var closes = 0;
      controller.register(_registration(_descriptor('music', hasAudio: true)));
      controller.register(_registration(_descriptor('book'), onClose: () => closes++));
      await controller.setAudibleSession('music');

      expect(await controller.setAudibleSession('book'), isFalse); // The book has no audio.
      expect(controller.audibleSessionId, 'music');
      expect(controller.close('book'), isTrue);
      expect(closes, 1);
      expect(controller.sessionCount, 1);

      controller.dispose();
    });

    test('promote, park, restore and tray keep session owners alive', () {
      final controller = MultiviewWorkspaceController();
      controller.register(_registration(_descriptor('video', hasAudio: true, hasVideo: true)));
      controller.register(_registration(_descriptor('book')));

      expect(controller.promoteToFullscreen('video'), isTrue);
      expect(controller.visibleSessions.map((s) => s.descriptor.id), ['video']);
      expect(controller.toggleSessionTray(), isTrue);
      expect(controller.park('video'), isTrue);
      expect(controller.fullscreenSessionId, isNull);
      expect(controller.visibleSessions.map((s) => s.descriptor.id), ['book']);
      expect(controller.unpark('video'), isTrue);
      expect(controller.sessions.length, 2);

      controller.dispose();
    });

    test('keyboard and remote move mode commits or cancels placement', () {
      final controller = MultiviewWorkspaceController();
      controller.register(_registration(_descriptor('movie')));
      final initial = controller.placementFor('movie');

      expect(controller.beginPositioning('movie'), isTrue);
      expect(controller.isPositioning, isTrue);
      expect(controller.movePositionedByPixels('movie', const Offset(48, 24), const Size(800, 600)), isTrue);
      expect(controller.placementFor('movie'), isNot(initial));
      expect(controller.finishPositioning(cancel: true), isTrue);
      expect(controller.placementFor('movie'), initial);

      expect(controller.beginPositioning('movie'), isTrue);
      controller.movePositionedByPixels('movie', const Offset(48, 24), const Size(800, 600));
      expect(controller.finishPositioning(), isTrue);
      expect(controller.placementFor('movie'), isNot(initial));
      expect(controller.finishPositioning(), isFalse);
      controller.dispose();
    });

    test('focus navigation skips parked and restored sessions', () {
      final controller = MultiviewWorkspaceController();
      controller.register(_registration(_descriptor('a')));
      controller.register(_registration(_descriptor('b')));
      controller.register(_registration(_descriptor('c')));

      expect(controller.restore('c'), isTrue);
      expect(controller.park('b'), isTrue);
      expect(controller.focusNext(), isFalse);
      expect(controller.unpark('b'), isTrue);
      expect(controller.focus('a'), isTrue);
      expect(controller.focusNext(), isTrue);
      expect(controller.focusedSessionId, 'b');

      controller.dispose();
    });

    test('audio handoff gates the previous and next owner', () async {
      final controller = MultiviewWorkspaceController();
      final calls = <String>[];
      controller.register(
        _registration(_descriptor('a', hasAudio: true), onAudioOwnershipChanged: (enabled) => calls.add('a:$enabled')),
      );
      controller.register(
        _registration(_descriptor('b', hasAudio: true), onAudioOwnershipChanged: (enabled) => calls.add('b:$enabled')),
      );
      await Future<void>.delayed(Duration.zero);
      expect(calls, ['a:true', 'b:false']);

      expect(await controller.setAudibleSession('b'), isTrue);
      expect(controller.audibleSessionId, 'b');
      expect(calls, ['a:true', 'b:false', 'a:false', 'b:true']);
      controller.dispose();
    });

    test('descriptor capability loss releases audio and input ownership', () async {
      final controller = MultiviewWorkspaceController();
      final audio = <bool>[];
      final input = <bool>[];
      controller.register(
        _registration(
          _descriptor('media', hasAudio: true, acceptsInput: true),
          onAudioOwnershipChanged: audio.add,
          onInputOwnershipChanged: input.add,
        ),
      );
      await controller.setInputSession('media');
      await Future<void>.delayed(Duration.zero);

      expect(controller.audibleSessionId, 'media');
      expect(controller.inputSessionId, 'media');
      controller.updateDescriptor(_descriptor('media'));
      await Future<void>.delayed(Duration.zero);

      expect(controller.audibleSessionId, isNull);
      expect(controller.inputSessionId, isNull);
      expect(audio, [true, false]);
      expect(input, [true, false]);
      controller.dispose();
    });

    test('failed audio handoff restores the prior owner', () async {
      final controller = MultiviewWorkspaceController();
      var firstEnabled = false;
      controller.register(
        _registration(_descriptor('a', hasAudio: true), onAudioOwnershipChanged: (enabled) => firstEnabled = enabled),
      );
      controller.register(
        _registration(
          _descriptor('b', hasAudio: true),
          onAudioOwnershipChanged: (enabled) {
            if (enabled) throw StateError('audio output unavailable');
          },
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(await controller.setAudibleSession('b'), isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(controller.audibleSessionId, 'a');
      expect(firstEnabled, isTrue);
      controller.dispose();
    });

    test('uses the rendered pane size for pixel movement and resize', () {
      final controller = MultiviewWorkspaceController();
      controller.register(_registration(_descriptor('video', hasVideo: true)));

      controller.moveByPixels('video', const Offset(300, 0), const Size(1920, 1080), paneSize: const Size(520, 367.2));
      expect(controller.placementFor('video').left, closeTo(0.69625, 0.0001));

      controller.resizeByPixels(
        'video',
        const Offset(-20, 0),
        const Size(1920, 1080),
        paneSize: const Size(520, 367.2),
      );
      expect(controller.placementFor('video').width, closeTo(500 / 1920, 0.0001));
      expect(controller.placementFor('video').height, closeTo(0.34, 0.0001));
      controller.dispose();
    });

    test('pixel movement and resize stay inside bounds for any display size', () {
      final controller = MultiviewWorkspaceController();
      controller.register(_registration(_descriptor('movie')));

      for (var i = 0; i < 30; i++) {
        controller.moveByPixels('movie', const Offset(800, 600), const Size(200, 150));
        controller.resizeByPixels('movie', const Offset(800, 600), const Size(200, 150));
      }

      final placement = controller.placementFor('movie');
      expect(placement.left + placement.width, lessThanOrEqualTo(1));
      expect(placement.top + placement.height, lessThanOrEqualTo(1));
      expect(placement.width, lessThanOrEqualTo(1));
      expect(placement.height, lessThanOrEqualTo(1));
      expect(controller.moveToCorner('missing', right: false, bottom: false), isFalse);

      controller.dispose();
    });
  });
}
