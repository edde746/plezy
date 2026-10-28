import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../services/playback_coordinator.dart';
import 'workspace_models.dart';
import 'workspace_persistence.dart';

typedef WorkspaceOwnershipHandler = FutureOr<void> Function(bool enabled);

/// A live bridge between a safe-to-store descriptor and its existing owner.
///
/// The adapter must render the current surface and route commands to the
/// original player/reader/game. It must not construct a second owner merely to
/// make a pane. Route/session owners remain authoritative for teardown.
@immutable
class WorkspaceSurfaceRegistration {
  const WorkspaceSurfaceRegistration({
    required this.descriptor,
    required this.buildSurface,
    required this.onRestore,
    this.onClose,
    this.onAudioOwnershipChanged,
    this.onInputOwnershipChanged,
    this.videoPlayerSlot,
  });

  final WorkspaceSessionDescriptor descriptor;
  final WidgetBuilder buildSurface;

  /// Restore the source to its original full-screen route without reopening it.
  final VoidCallback onRestore;

  /// End the underlying session using its existing close policy.
  final VoidCallback? onClose;
  final WorkspaceOwnershipHandler? onAudioOwnershipChanged;
  final WorkspaceOwnershipHandler? onInputOwnershipChanged;
  final VideoPlayerSlot? videoPlayerSlot;
}

/// Profile-scoped state and command surface for app-owned Multiview.
///
/// This controller owns only layout, focus, and adapter references. It does not
/// own player lifetimes. The existing media route or service continues to own
/// playback, source auth, progress, and native teardown.
class MultiviewWorkspaceController extends ChangeNotifier {
  MultiviewWorkspaceController({WorkspaceSnapshotPersistence? persistence, String? profileId})
    : _persistence = persistence,
      _profileId = profileId,
      _hydrated = persistence == null || profileId == null;

  final WorkspaceSnapshotPersistence? _persistence;
  final String? _profileId;
  Timer? _persistenceTimer;
  Future<void> _persistenceQueue = Future<void>.value();
  WorkspaceSnapshot? _pendingSnapshot;
  bool _hydrated;
  bool _hydrating = false;
  final LinkedHashMap<String, WorkspaceSurfaceRegistration> _sessions =
      LinkedHashMap<String, WorkspaceSurfaceRegistration>();
  final Map<String, WorkspacePlacement> _placements = {};
  final Set<String> _parkedSessionIds = <String>{};
  final Set<String> _restoredSessionIds = <String>{};
  final Set<String> _focusedInputSurfaceIds = <String>{};
  String? _fullscreenSessionId;
  bool _sessionTrayVisible = false;
  String? _focusedSessionId;
  String? _audibleSessionId;
  WorkspaceOwnershipHandler? _audibleHandler;
  String? _requestedAudibleSessionId;
  bool _hasExplicitAudioSelection = false;
  String? _inputSessionId;
  WorkspaceOwnershipHandler? _inputHandler;
  String? _requestedInputSessionId;
  String? _positioningSessionId;
  WorkspacePlacement? _placementBeforeMove;
  int _audioRevision = 0;
  int _inputRevision = 0;
  Future<void> _audioQueue = Future<void>.value();
  Future<void> _inputQueue = Future<void>.value();
  bool _disposed = false;
  MultiviewLayoutMode _layoutMode = MultiviewLayoutMode.floating;

  List<WorkspaceSurfaceRegistration> get sessions => List<WorkspaceSurfaceRegistration>.unmodifiable(_sessions.values);
  List<WorkspaceSurfaceRegistration> get visibleSessions {
    final fullscreenId = _fullscreenSessionId;
    if (fullscreenId != null) {
      final registration = _sessions[fullscreenId];
      return registration == null ? const [] : [registration];
    }
    return List<WorkspaceSurfaceRegistration>.unmodifiable(
      _sessions.values.where(
        (registration) =>
            !_parkedSessionIds.contains(registration.descriptor.id) &&
            !_restoredSessionIds.contains(registration.descriptor.id),
      ),
    );
  }

  List<WorkspaceSurfaceRegistration> get parkedSessions => List<WorkspaceSurfaceRegistration>.unmodifiable(
    _sessions.values.where((registration) => _parkedSessionIds.contains(registration.descriptor.id)),
  );
  bool get hasVisibleSessions => visibleSessions.isNotEmpty || _sessionTrayVisible;
  bool hasSessionOfKind(MultiviewMediaKind kind) => _sessions.values.any((session) => session.descriptor.kind == kind);
  bool get hasAudioSelection => _hasExplicitAudioSelection || _requestedAudibleSessionId != null;
  bool get hasCompetingAudioOwner {
    if (_hasExplicitAudioSelection && _requestedAudibleSessionId == null) return true;
    final owner = _requestedAudibleSessionId == null ? null : _sessions[_requestedAudibleSessionId!];
    return owner != null && owner.descriptor.kind != MultiviewMediaKind.music;
  }

  String? get fullscreenSessionId => _fullscreenSessionId;
  bool get sessionTrayVisible => _sessionTrayVisible;
  int get sessionCount => _sessions.length;
  int get videoSessionCount => _sessions.values
      .where(
        (session) =>
            session.descriptor.hasVideo &&
            (session.descriptor.kind == MultiviewMediaKind.video ||
                session.descriptor.kind == MultiviewMediaKind.liveTv),
      )
      .length;
  String? get focusedSessionId => _focusedSessionId;
  String? get audibleSessionId => _audibleSessionId;
  String? get inputSessionId => _inputSessionId;
  String? get requestedAudibleSessionId => _requestedAudibleSessionId;
  String? get requestedInputSessionId => _requestedInputSessionId;
  String? get positioningSessionId => _positioningSessionId;
  bool get isPositioning => _positioningSessionId != null;
  MultiviewLayoutMode get layoutMode => _layoutMode;

  WorkspaceSurfaceRegistration? session(String id) => _sessions[id];

  /// Load the last profile-local layout. Session owners are never recreated;
  /// saved descriptors only restore geometry and ownership preference when the
  /// same live session registers through its normal route or service.
  Future<void> hydrate() async {
    final persistence = _persistence;
    final profileId = _profileId;
    if (_hydrated || _hydrating || persistence == null || profileId == null) return;
    _hydrating = true;
    try {
      final snapshot = await persistence.read(profileId);
      if (_disposed) return;
      _pendingSnapshot = snapshot;
      if (snapshot != null) restoreLayout(snapshot);
    } catch (error, stackTrace) {
      debugPrint('Multiview layout restore failed: $error\\n$stackTrace');
    } finally {
      _hydrating = false;
      _hydrated = true;
    }
  }

  void _publish() {
    if (_disposed) return;
    final coordinator = PlaybackCoordinator.instance;
    coordinator.setWorkspaceRetainsMusic(hasSessionOfKind(MultiviewMediaKind.music));
    coordinator.setWorkspaceVideoSessionCount(videoSessionCount);
    coordinator.setWorkspaceVideoPlayerSlots(
      _sessions.values
          .where(
            (session) =>
                session.descriptor.hasVideo &&
                (session.descriptor.kind == MultiviewMediaKind.video ||
                    session.descriptor.kind == MultiviewMediaKind.liveTv),
          )
          .map((session) => session.videoPlayerSlot)
          .whereType<VideoPlayerSlot>(),
    );
    coordinator.setWorkspaceHasCompetingAudioOwner(hasCompetingAudioOwner);
    notifyListeners();
    _schedulePersistence();
  }

  void _schedulePersistence() {
    final persistence = _persistence;
    final profileId = _profileId;
    if (_disposed || !_hydrated || _hydrating || persistence == null || profileId == null) return;
    _persistenceTimer?.cancel();
    _persistenceTimer = Timer(const Duration(milliseconds: 250), () {
      _persistSnapshot(persistence, profileId, snapshot());
    });
  }

  void _persistSnapshot(WorkspaceSnapshotPersistence persistence, String profileId, WorkspaceSnapshot value) {
    _persistenceQueue = _persistenceQueue.then((_) => persistence.write(profileId, value)).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      debugPrint('Multiview layout save failed: $error\\n$stackTrace');
    });
  }

  bool isRestored(String id) => _restoredSessionIds.contains(id);

  WorkspacePlacement placementFor(String id) => _placements[id] ?? const WorkspacePlacement.initial();

  /// Registers a real live surface. Duplicate IDs are rejected so a late route
  /// cannot replace the adapter currently driving a visible pane.
  bool register(WorkspaceSurfaceRegistration registration) {
    final descriptor = registration.descriptor;
    if (descriptor.id.trim().isEmpty || descriptor.title.trim().isEmpty) return false;
    if (descriptor.hasAudio && registration.onAudioOwnershipChanged == null) return false;
    if (descriptor.acceptsInput && registration.onInputOwnershipChanged == null) return false;
    if (_sessions.containsKey(descriptor.id)) return false;
    if (descriptor.hasVideo &&
        registration.videoPlayerSlot != null &&
        _sessions.values.any(
          (session) => session.descriptor.hasVideo && session.videoPlayerSlot == registration.videoPlayerSlot,
        )) {
      return false;
    }

    final index = _sessions.length;
    _sessions[descriptor.id] = registration;
    final restoredPlacement = _placements[descriptor.id] ?? _pendingSnapshot?.placements[descriptor.id];
    _placements.remove(descriptor.id);
    _placements[descriptor.id] =
        restoredPlacement ??
        const WorkspacePlacement.initial().withDelta(
          left: (0.54 - index * 0.035).clamp(0.0, 0.56).toDouble(),
          top: (0.58 - index * 0.035).clamp(0.0, 0.60).toDouble(),
        );
    _prunePlacements();
    final savedFocusId = _pendingSnapshot?.focusedSessionId;
    if (savedFocusId == descriptor.id) {
      _focusedSessionId = descriptor.id;
    } else if (_focusedSessionId == null || !_sessions.containsKey(_focusedSessionId)) {
      _focusedSessionId = descriptor.id;
    }
    if (descriptor.hasAudio) {
      if (_requestedAudibleSessionId == descriptor.id) {
        unawaited(_enqueueAudioReconcile());
      } else if (_requestedAudibleSessionId == null &&
          !_hasExplicitAudioSelection &&
          registration.videoPlayerSlot != VideoPlayerSlot.companion) {
        _requestedAudibleSessionId = descriptor.id;
        unawaited(_enqueueAudioReconcile());
      } else {
        _queueAudioMute(descriptor.id, registration.onAudioOwnershipChanged);
      }
    }
    if (descriptor.acceptsInput) {
      if (_requestedInputSessionId == descriptor.id && _isVisible(descriptor.id)) {
        unawaited(_enqueueInputReconcile());
      } else if (_requestedInputSessionId == null && _focusedSessionId == descriptor.id && _isVisible(descriptor.id)) {
        _requestedInputSessionId = descriptor.id;
        unawaited(_enqueueInputReconcile());
      } else {
        _queueInputRelease(descriptor.id, registration.onInputOwnershipChanged);
      }
    }
    _publish();
    return true;
  }

  /// Replaces presentation metadata while preserving the live adapter and
  /// identity. Useful when the same player advances to another episode/track.
  bool updateDescriptor(
    WorkspaceSessionDescriptor descriptor, {
    VideoPlayerSlot? videoPlayerSlot,
    bool clearVideoPlayerSlot = false,
  }) {
    final existing = _sessions[descriptor.id];
    if (existing == null ||
        descriptor.id.trim().isEmpty ||
        descriptor.title.trim().isEmpty ||
        (descriptor.hasAudio && existing.onAudioOwnershipChanged == null) ||
        (descriptor.acceptsInput && existing.onInputOwnershipChanged == null)) {
      return false;
    }
    final nextVideoPlayerSlot = clearVideoPlayerSlot ? null : (videoPlayerSlot ?? existing.videoPlayerSlot);
    if (descriptor.hasVideo &&
        nextVideoPlayerSlot != null &&
        _sessions.values.any(
          (session) =>
              session.descriptor.id != descriptor.id &&
              session.descriptor.hasVideo &&
              session.videoPlayerSlot == nextVideoPlayerSlot,
        )) {
      return false;
    }
    if (!descriptor.acceptsInput) _focusedInputSurfaceIds.remove(descriptor.id);
    _sessions[descriptor.id] = WorkspaceSurfaceRegistration(
      descriptor: descriptor,
      buildSurface: existing.buildSurface,
      onRestore: existing.onRestore,
      onClose: existing.onClose,
      onAudioOwnershipChanged: existing.onAudioOwnershipChanged,
      onInputOwnershipChanged: existing.onInputOwnershipChanged,
      videoPlayerSlot: nextVideoPlayerSlot,
    );
    if ((!descriptor.hasAudio && (_requestedAudibleSessionId == descriptor.id || _audibleSessionId == descriptor.id))) {
      _requestedAudibleSessionId = _firstSessionIdWhere(
        (session) => session.descriptor.hasAudio && session.descriptor.id != descriptor.id,
      );
      _hasExplicitAudioSelection = true;
      unawaited(_enqueueAudioReconcile());
    } else if (descriptor.hasAudio && _requestedAudibleSessionId == descriptor.id) {
      unawaited(_enqueueAudioReconcile());
    }
    if (!descriptor.acceptsInput && (_requestedInputSessionId == descriptor.id || _inputSessionId == descriptor.id)) {
      _requestedInputSessionId = _firstSessionIdWhere(
        (session) =>
            session.descriptor.acceptsInput &&
            session.descriptor.id != descriptor.id &&
            _isVisible(session.descriptor.id),
      );
      unawaited(_enqueueInputReconcile());
    } else if (descriptor.acceptsInput && _requestedInputSessionId == descriptor.id) {
      unawaited(_enqueueInputReconcile());
    }
    _publish();
    return true;
  }

  /// Drop a route-owned adapter during normal route teardown. This does not
  /// call restore or close because the owner is already retiring.
  bool unregister(String id) {
    final registration = _remove(id);
    if (registration == null) return false;
    _reconcileOwnershipAfterRemoval(id);
    _publish();
    return true;
  }

  /// Return one session to its original route without shutting it down. The
  /// live adapter and ownership leases remain registered so it can be floated
  /// again without reopening its source.
  bool restore(String id) {
    final registration = _sessions[id];
    if (registration == null || _restoredSessionIds.contains(id)) return false;
    _restoredSessionIds.add(id);
    _parkedSessionIds.remove(id);
    if (_fullscreenSessionId == id) _fullscreenSessionId = null;
    if (_positioningSessionId == id) {
      _positioningSessionId = null;
      _placementBeforeMove = null;
    }
    if (_focusedSessionId == id) _focusedSessionId = _firstVisibleSessionId(excluding: id);
    final restoredInputTarget = registration.descriptor.acceptsInput ? id : null;
    if (_requestedInputSessionId != restoredInputTarget || _inputSessionId != restoredInputTarget) {
      _requestedInputSessionId = restoredInputTarget;
      unawaited(_enqueueInputReconcile());
    }
    _publish();
    registration.onRestore();
    return true;
  }

  /// Move a restored or parked session back into the workspace. When
  /// [fullscreen] is true it becomes the only visible surface until the user
  /// exits fullscreen or chooses another session from the tray.
  bool showSessionInWorkspace(String id, {bool fullscreen = false}) {
    if (!_sessions.containsKey(id)) return false;
    final wasRestored = _restoredSessionIds.remove(id);
    final wasParked = _parkedSessionIds.remove(id);
    final wasFullscreen = fullscreen ? _fullscreenSessionId != id : _fullscreenSessionId == id;
    if (!wasRestored && !wasParked && !wasFullscreen) return false;
    _focusedSessionId = id;
    _fullscreenSessionId = fullscreen ? id : null;
    final registration = _sessions.remove(id)!;
    _sessions[id] = registration;
    _publish();
    return true;
  }

  /// Close the underlying session through its existing owner policy.
  bool close(String id) {
    final registration = _remove(id);
    if (registration == null) return false;
    _reconcileOwnershipAfterRemoval(id);
    _publish();
    final onClose = registration.onClose;
    if (onClose == null) {
      registration.onRestore();
    } else {
      onClose();
    }
    return true;
  }

  WorkspaceSurfaceRegistration? _remove(String id) {
    final registration = _sessions.remove(id);
    if (registration == null) return null;
    _focusedInputSurfaceIds.remove(id);
    _parkedSessionIds.remove(id);
    _restoredSessionIds.remove(id);
    if (_fullscreenSessionId == id) _fullscreenSessionId = null;
    if (_positioningSessionId == id) {
      _positioningSessionId = null;
      _placementBeforeMove = null;
    }
    if (_focusedSessionId == id) {
      _focusedSessionId = _firstVisibleSessionId() ?? (_sessions.isEmpty ? null : _sessions.keys.last);
    }
    if (_sessions.isEmpty) _sessionTrayVisible = false;
    return registration;
  }

  void _prunePlacements() {
    while (_placements.length > 64) {
      final oldestClosedId = _placements.keys.firstWhere((id) => !_sessions.containsKey(id), orElse: () => '');
      if (oldestClosedId.isEmpty) return;
      _placements.remove(oldestClosedId);
    }
  }

  String? _firstSessionIdWhere(bool Function(WorkspaceSurfaceRegistration) predicate) {
    for (final session in _sessions.values) {
      if (predicate(session)) return session.descriptor.id;
    }
    return null;
  }

  bool focus(String id) {
    if (!_sessions.containsKey(id) || _parkedSessionIds.contains(id) || _restoredSessionIds.contains(id)) {
      return false;
    }
    final focusChanged = _focusedSessionId != id;
    if (focusChanged) {
      _focusedSessionId = id;
      if (_layoutMode == MultiviewLayoutMode.floating) {
        final registration = _sessions.remove(id)!;
        _sessions[id] = registration;
      }
    }
    final registration = _sessions[id]!;
    final inputTarget = registration.descriptor.acceptsInput ? id : null;
    final inputChanged = _requestedInputSessionId != inputTarget;
    if (inputChanged) {
      _requestedInputSessionId = inputTarget;
      unawaited(_enqueueInputReconcile());
    }
    if (focusChanged || inputChanged) _publish();
    return focusChanged;
  }

  bool focusNext() {
    final ids = visibleSessions.map((session) => session.descriptor.id).toList(growable: false);
    if (ids.length < 2) return false;
    final current = _focusedSessionId == null ? -1 : ids.indexOf(_focusedSessionId!);
    return focus(ids[(current + 1) % ids.length]);
  }

  Future<bool> setAudibleSession(String? id) {
    if (id != null && _sessions[id]?.descriptor.hasAudio != true) {
      return Future<bool>.value(false);
    }
    final selectionChanged = _requestedAudibleSessionId != id || !_hasExplicitAudioSelection;
    _hasExplicitAudioSelection = true;
    _requestedAudibleSessionId = id;
    if (selectionChanged) _publish();
    if (!selectionChanged && _audibleSessionId == id) return Future<bool>.value(false);
    return _enqueueAudioReconcile();
  }

  /// Mute only this session's pending selection. An action on an old pane
  /// must never cancel a newer request to listen to another media session.
  Future<bool> muteSession(String id) {
    if (_disposed || _requestedAudibleSessionId != id) return Future<bool>.value(false);
    return setAudibleSession(null);
  }

  Future<bool> _enqueueAudioReconcile() {
    final completer = Completer<bool>();
    _audioQueue = _audioQueue
        .then((_) async {
          completer.complete(await _reconcileAudioOwnership());
        })
        .catchError((Object error, StackTrace stackTrace) {
          if (!completer.isCompleted) completer.complete(false);
          debugPrint('Multiview audio ownership queue failed: $error\\n$stackTrace');
        });
    return completer.future;
  }

  Future<bool> _reconcileAudioOwnership() async {
    if (_disposed) return false;
    final targetId = _requestedAudibleSessionId;
    final target = targetId == null ? null : _sessions[targetId];
    if (targetId != null && (target?.descriptor.hasAudio != true || target?.onAudioOwnershipChanged == null)) {
      return false;
    }
    final targetHandler = target?.onAudioOwnershipChanged;
    if (_audibleSessionId == targetId && identical(_audibleHandler, targetHandler)) return false;

    final previousId = _audibleSessionId;
    final previousHandler = _audibleHandler;
    final revision = ++_audioRevision;
    try {
      if (previousHandler != null) await previousHandler(false);
      if (_disposed || revision != _audioRevision) return false;
      if (_requestedAudibleSessionId != targetId) {
        await _applyOwnershipSafely(targetHandler, false);
        await _restorePreviousAudioOwner(previousId, previousHandler);
        return false;
      }
      if (targetHandler != null) await targetHandler(true);
      if (_disposed || revision != _audioRevision) {
        await _applyOwnershipSafely(targetHandler, false);
        return false;
      }
      if (_requestedAudibleSessionId != targetId) {
        await _applyOwnershipSafely(targetHandler, false);
        await _restorePreviousAudioOwner(previousId, previousHandler);
        return false;
      }
      _audibleSessionId = targetId;
      _audibleHandler = targetHandler;
      _publish();
      return true;
    } catch (error, stackTrace) {
      await _applyOwnershipSafely(targetHandler, false);
      final restored = await _restorePreviousAudioOwner(previousId, previousHandler);
      if (_disposed) return false;
      if (_requestedAudibleSessionId == targetId) {
        final fallbackId = restored && previousId != null
            ? previousId
            : _firstSessionIdWhere((session) => session.descriptor.hasAudio && session.descriptor.id != targetId);
        _requestedAudibleSessionId = fallbackId;
        if (fallbackId != null) unawaited(_enqueueAudioReconcile());
      }
      debugPrint('Multiview audio ownership change failed: $error\\n$stackTrace');
      _publish();
      return false;
    }
  }

  Future<bool> _restorePreviousAudioOwner(String? previousId, WorkspaceOwnershipHandler? previousHandler) async {
    final previousStillAvailable =
        previousId != null && _sessions[previousId]?.descriptor.hasAudio == true && previousHandler != null;
    if (previousStillAvailable) {
      final enabled = await _applyOwnershipSafely(previousHandler, true);
      if (enabled) {
        _audibleSessionId = previousId;
        _audibleHandler = previousHandler;
        return true;
      }
    }
    _audibleSessionId = null;
    _audibleHandler = null;
    return previousId == null;
  }

  Future<bool> setInputSession(String? id) {
    if (id != null &&
        (_sessions[id]?.descriptor.acceptsInput != true ||
            _parkedSessionIds.contains(id) ||
            _restoredSessionIds.contains(id) ||
            !_isVisible(id))) {
      return Future<bool>.value(false);
    }
    final selectionChanged = _requestedInputSessionId != id;
    _requestedInputSessionId = id;
    if (selectionChanged) _publish();
    if (!selectionChanged && _inputSessionId == id) return Future<bool>.value(false);
    return _enqueueInputReconcile();
  }

  /// Records whether an input-capable pane still owns Flutter focus.
  ///
  /// Raw gamepad streams bypass Flutter's route focus. Requiring the selected
  /// pane's focus scope to remain active prevents an embedded game from
  /// receiving controller input behind a dialog or another route.
  void setSurfaceInputFocus(String id, bool focused) {
    if (_sessions[id]?.descriptor.acceptsInput != true) return;
    final shouldFocus = focused && _focusedSessionId == id && _isVisible(id);
    final changed = shouldFocus ? _focusedInputSurfaceIds.add(id) : _focusedInputSurfaceIds.remove(id);
    if (!changed || (_requestedInputSessionId != id && _inputSessionId != id)) return;
    unawaited(_enqueueInputReconcile());
  }

  Future<bool> _enqueueInputReconcile() {
    final completer = Completer<bool>();
    _inputQueue = _inputQueue
        .then((_) async {
          completer.complete(await _reconcileInputOwnership());
        })
        .catchError((Object error, StackTrace stackTrace) {
          if (!completer.isCompleted) completer.complete(false);
          debugPrint('Multiview input ownership queue failed: $error\\n$stackTrace');
        });
    return completer.future;
  }

  String? _effectiveInputSessionId() {
    final id = _requestedInputSessionId;
    if (id == null || _positioningSessionId == id || !_focusedInputSurfaceIds.contains(id) || !_isVisible(id)) {
      return null;
    }
    return id;
  }

  Future<bool> _reconcileInputOwnership() async {
    if (_disposed) return false;
    final targetId = _effectiveInputSessionId();
    final target = targetId == null ? null : _sessions[targetId];
    if (targetId != null &&
        (target?.descriptor.acceptsInput != true ||
            target?.onInputOwnershipChanged == null ||
            _parkedSessionIds.contains(targetId) ||
            _restoredSessionIds.contains(targetId) ||
            !_isVisible(targetId))) {
      return false;
    }
    final targetHandler = target?.onInputOwnershipChanged;
    if (_inputSessionId == targetId && identical(_inputHandler, targetHandler)) return false;

    final previousId = _inputSessionId;
    final previousHandler = _inputHandler;
    final revision = ++_inputRevision;
    try {
      if (previousHandler != null) await previousHandler(false);
      if (_disposed || revision != _inputRevision) return false;
      if (_effectiveInputSessionId() != targetId) {
        await _applyOwnershipSafely(targetHandler, false);
        await _restorePreviousInputOwner(previousId, previousHandler);
        return false;
      }
      if (targetHandler != null) await targetHandler(true);
      if (_disposed || revision != _inputRevision) {
        await _applyOwnershipSafely(targetHandler, false);
        return false;
      }
      if (_effectiveInputSessionId() != targetId) {
        await _applyOwnershipSafely(targetHandler, false);
        await _restorePreviousInputOwner(previousId, previousHandler);
        return false;
      }
      _inputSessionId = targetId;
      _inputHandler = targetHandler;
      _publish();
      return true;
    } catch (error, stackTrace) {
      await _applyOwnershipSafely(targetHandler, false);
      final restored = await _restorePreviousInputOwner(previousId, previousHandler);
      if (_disposed) return false;
      if (_requestedInputSessionId == targetId) {
        _requestedInputSessionId = restored ? previousId : null;
      }
      debugPrint('Multiview input ownership change failed: $error\\n$stackTrace');
      _publish();
      return false;
    }
  }

  Future<bool> _restorePreviousInputOwner(String? previousId, WorkspaceOwnershipHandler? previousHandler) async {
    final previousStillAvailable =
        previousId != null &&
        _effectiveInputSessionId() == previousId &&
        _sessions[previousId]?.descriptor.acceptsInput == true &&
        !_parkedSessionIds.contains(previousId) &&
        !_restoredSessionIds.contains(previousId) &&
        previousHandler != null;
    if (previousStillAvailable) {
      final enabled = await _applyOwnershipSafely(previousHandler, true);
      if (enabled) {
        _inputSessionId = previousId;
        _inputHandler = previousHandler;
        return true;
      }
    }
    _inputSessionId = null;
    _inputHandler = null;
    return previousId == null;
  }

  void _queueInputRelease(String id, WorkspaceOwnershipHandler? handler) {
    if (handler == null) return;
    _inputQueue = _inputQueue
        .then((_) async {
          if (_disposed || _requestedInputSessionId == id || _inputSessionId == id) {
            return;
          }
          await _applyOwnershipSafely(handler, false);
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Multiview input release queue failed: $error\\n$stackTrace');
        });
  }

  void _queueAudioMute(String id, WorkspaceOwnershipHandler? handler) {
    if (handler == null) return;
    _audioQueue = _audioQueue
        .then((_) async {
          if (_disposed || _requestedAudibleSessionId == id || _audibleSessionId == id) {
            return;
          }
          await _applyOwnershipSafely(handler, false);
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Multiview audio mute queue failed: $error\\n$stackTrace');
        });
  }

  void _reconcileOwnershipAfterRemoval(String id) {
    final priorAudioRequest = _requestedAudibleSessionId;
    if (priorAudioRequest == id) {
      _requestedAudibleSessionId = _firstSessionIdWhere((session) => session.descriptor.hasAudio);
    }
    final hasAudioSession = _firstSessionIdWhere((session) => session.descriptor.hasAudio) != null;
    if (!hasAudioSession && _requestedAudibleSessionId == null) {
      _hasExplicitAudioSelection = false;
    }
    if (_audibleSessionId == id || priorAudioRequest != _requestedAudibleSessionId) {
      unawaited(_enqueueAudioReconcile());
    }

    final priorInputRequest = _requestedInputSessionId;
    if (priorInputRequest == id) {
      _requestedInputSessionId = _firstSessionIdWhere(
        (session) =>
            session.descriptor.acceptsInput && session.descriptor.id != id && _isVisible(session.descriptor.id),
      );
    }
    if (_inputSessionId == id || priorInputRequest != _requestedInputSessionId) {
      unawaited(_enqueueInputReconcile());
    }
  }

  Future<bool> _applyOwnershipSafely(WorkspaceOwnershipHandler? handler, bool enabled) async {
    if (handler == null) return true;
    try {
      await handler(enabled);
      return true;
    } catch (error, stackTrace) {
      debugPrint('Multiview ownership callback failed: $error\\n$stackTrace');
      return false;
    }
  }

  bool promoteToFullscreen(String id) {
    if (!_sessions.containsKey(id) || _fullscreenSessionId == id) return false;
    if (_positioningSessionId != null) finishPositioning(cancel: false);
    final inputTarget = _sessions[id]?.descriptor.acceptsInput == true ? id : null;
    if (_requestedInputSessionId != inputTarget || _inputSessionId != inputTarget) {
      _requestedInputSessionId = inputTarget;
      unawaited(_enqueueInputReconcile());
    }
    _fullscreenSessionId = id;
    _restoredSessionIds.remove(id);
    _parkedSessionIds.remove(id);
    _focusedSessionId = id;
    _publish();
    return true;
  }

  /// Return from the promoted surface to the previous floating or split layout.
  bool exitFullscreen() {
    if (_fullscreenSessionId == null) return false;
    _fullscreenSessionId = null;
    _publish();
    return true;
  }

  /// Park one live session without stopping its owner. It stays reachable from
  /// [parkedSessions] and can be restored without reopening its source.
  bool park(String id) {
    if (!_sessions.containsKey(id) || _parkedSessionIds.contains(id) || _restoredSessionIds.contains(id)) {
      return false;
    }
    if (_positioningSessionId == id) finishPositioning(cancel: true);
    if (_fullscreenSessionId == id) _fullscreenSessionId = null;
    _parkedSessionIds.add(id);
    if (_focusedSessionId == id) {
      _focusedSessionId = _firstVisibleSessionId(excluding: id);
    }
    // Parking the last visible pane must leave the session tray available so
    // the live session can be brought back without reopening its source.
    if (visibleSessions.isEmpty) _sessionTrayVisible = true;
    if (_requestedInputSessionId == id || _inputSessionId == id) {
      _requestedInputSessionId = _firstSessionIdWhere(
        (session) =>
            session.descriptor.acceptsInput && session.descriptor.id != id && _isVisible(session.descriptor.id),
      );
      unawaited(_enqueueInputReconcile());
    }
    _publish();
    return true;
  }

  String? _firstVisibleSessionId({String? excluding}) {
    for (final id in _sessions.keys) {
      if (id != excluding && !_parkedSessionIds.contains(id) && !_restoredSessionIds.contains(id)) {
        return id;
      }
    }
    return null;
  }

  bool unpark(String id) {
    if (!_sessions.containsKey(id) || !_parkedSessionIds.remove(id)) return false;
    _focusedSessionId = id;
    _publish();
    return true;
  }

  bool toggleSessionTray() {
    _sessionTrayVisible = !_sessionTrayVisible;
    _publish();
    return _sessionTrayVisible;
  }

  bool setSessionTrayVisible(bool visible) {
    if (_sessionTrayVisible == visible) return false;
    _sessionTrayVisible = visible;
    _publish();
    return true;
  }

  bool swapFocusedWithNext() {
    final ids = visibleSessions.map((session) => session.descriptor.id).toList(growable: false);
    if (ids.length < 2) return false;
    final current = _focusedSessionId == null ? -1 : ids.indexOf(_focusedSessionId!);
    final firstId = current < 0 ? ids.first : ids[current];
    final secondId = ids[((current < 0 ? 0 : current) + 1) % ids.length];
    return swapPlacement(firstId, secondId);
  }

  bool swapPlacement(String firstId, String secondId) {
    if (firstId == secondId) return false;
    final first = _placements[firstId];
    final second = _placements[secondId];
    if (first == null || second == null) return false;
    if (_layoutMode == MultiviewLayoutMode.sideBySide) {
      final ids = _sessions.keys.toList(growable: false);
      final firstIndex = ids.indexOf(firstId);
      final secondIndex = ids.indexOf(secondId);
      if (firstIndex < 0 || secondIndex < 0) return false;
      ids[firstIndex] = secondId;
      ids[secondIndex] = firstId;
      final reordered = <String, WorkspaceSurfaceRegistration>{};
      for (final id in ids) {
        final registration = _sessions[id];
        if (registration != null) reordered[id] = registration;
      }
      _sessions
        ..clear()
        ..addAll(reordered);
    } else {
      _placements[firstId] = second;
      _placements[secondId] = first;
      final registration = _sessions.remove(firstId);
      if (registration != null) _sessions[firstId] = registration;
    }
    _focusedSessionId = firstId;
    _publish();
    return true;
  }

  bool setLayoutMode(MultiviewLayoutMode mode) {
    if (_layoutMode == mode) return false;
    if (mode == MultiviewLayoutMode.sideBySide && _positioningSessionId != null) {
      finishPositioning(cancel: true);
    }
    _layoutMode = mode;
    _publish();
    return true;
  }

  bool moveByPixels(String id, Offset delta, Size viewport, {Size? paneSize}) {
    if (!_isVisible(id)) return false;
    final placement = _placements[id];
    if (placement == null || viewport.width <= 0 || viewport.height <= 0) return false;
    final maximumLeft = paneSize == null ? 1.0 - placement.width : (viewport.width - paneSize.width) / viewport.width;
    final maximumTop = paneSize == null
        ? 1.0 - placement.height
        : (viewport.height - paneSize.height) / viewport.height;
    final next = placement.withPosition(
      left: placement.left + delta.dx / viewport.width,
      top: placement.top + delta.dy / viewport.height,
      maximumLeft: maximumLeft,
      maximumTop: maximumTop,
    );
    if (next.left == placement.left && next.top == placement.top) return false;
    _placements[id] = next;
    _publish();
    return true;
  }

  bool resizeByPixels(String id, Offset delta, Size viewport, {Size? paneSize}) {
    if (!_isVisible(id)) return false;
    final placement = _placements[id];
    if (placement == null || viewport.width <= 0 || viewport.height <= 0) return false;
    final next = placement.withDelta(
      width: paneSize == null
          ? placement.width + delta.dx / viewport.width
          : (paneSize.width + delta.dx) / viewport.width,
      height: paneSize == null
          ? placement.height + delta.dy / viewport.height
          : (paneSize.height + delta.dy) / viewport.height,
    );
    if (next.width == placement.width && next.height == placement.height) return false;
    _placements[id] = next;
    _publish();
    return true;
  }

  /// Begins a visible, accessible keyboard or remote move operation.
  bool beginPositioning(String id) {
    if (!_isVisible(id) || _layoutMode != MultiviewLayoutMode.floating || _fullscreenSessionId != null) {
      return false;
    }
    if (_positioningSessionId == id) return false;
    if (_positioningSessionId != null) finishPositioning(cancel: true);
    _positioningSessionId = id;
    _placementBeforeMove = _placements[id];
    _focusedSessionId = id;
    if (_requestedInputSessionId == id || _inputSessionId == id) unawaited(_enqueueInputReconcile());
    _publish();
    return true;
  }

  bool finishPositioning({bool cancel = false}) {
    final id = _positioningSessionId;
    if (id == null) return false;
    if (cancel) {
      final original = _placementBeforeMove;
      if (original != null && _sessions.containsKey(id)) _placements[id] = original;
    }
    _positioningSessionId = null;
    _placementBeforeMove = null;
    if (_requestedInputSessionId == id || _inputSessionId == id) unawaited(_enqueueInputReconcile());
    _publish();
    return true;
  }

  bool movePositionedByPixels(String id, Offset delta, Size viewport, {Size? paneSize}) {
    if (_positioningSessionId != id) return false;
    return moveByPixels(id, delta, viewport, paneSize: paneSize);
  }

  bool _isVisible(String id) =>
      _sessions.containsKey(id) &&
      !_parkedSessionIds.contains(id) &&
      !_restoredSessionIds.contains(id) &&
      (_fullscreenSessionId == null || _fullscreenSessionId == id);

  /// Non-gesture positioning path for remotes and keyboards.
  bool moveToCorner(String id, {required bool right, required bool bottom}) {
    if (!_isVisible(id)) return false;
    final placement = _placements[id];
    if (placement == null) return false;
    final next = placement.withDelta(left: right ? 1 - placement.width : 0, top: bottom ? 1 - placement.height : 0);
    if (next.left == placement.left && next.top == placement.top) return false;
    _placements[id] = next;
    _publish();
    return true;
  }

  WorkspaceSnapshot snapshot() => WorkspaceSnapshot(
    sessions: _sessions.values.map((session) => session.descriptor).toList(growable: false),
    placements: Map<String, WorkspacePlacement>.unmodifiable(_placements),
    layoutMode: _layoutMode,
    focusedSessionId: _focusedSessionId,
    audibleSessionId: _hasExplicitAudioSelection ? _requestedAudibleSessionId : null,
    inputSessionId: _requestedInputSessionId,
    audioSelectionExplicit: _hasExplicitAudioSelection,
  );

  void restoreLayout(WorkspaceSnapshot snapshot) {
    if (_positioningSessionId != null) finishPositioning(cancel: true);
    _pendingSnapshot = snapshot;
    _layoutMode = snapshot.layoutMode;
    _placements.addAll(snapshot.placements);
    _prunePlacements();
    final savedFocusId = snapshot.focusedSessionId;
    _focusedSessionId = savedFocusId != null && (_sessions.isEmpty || _sessions.containsKey(savedFocusId))
        ? savedFocusId
        : _firstVisibleSessionId();
    _requestedAudibleSessionId = snapshot.audibleSessionId;
    _hasExplicitAudioSelection = snapshot.audioSelectionExplicit;
    _requestedInputSessionId = snapshot.inputSessionId;
    if (_focusedSessionId == null &&
        snapshot.focusedSessionId != null &&
        _sessions.containsKey(snapshot.focusedSessionId)) {
      _focusedSessionId = snapshot.focusedSessionId;
    }
    _publish();
    unawaited(_enqueueAudioReconcile());
    unawaited(_enqueueInputReconcile());
  }

  @override
  void dispose() {
    _persistenceTimer?.cancel();
    PlaybackCoordinator.instance
      ..setWorkspaceRetainsMusic(false)
      ..setWorkspaceVideoSessionCount(0)
      ..setWorkspaceVideoPlayerSlots(const <VideoPlayerSlot>{})
      ..setWorkspaceHasCompetingAudioOwner(false);
    final persistence = _persistence;
    final profileId = _profileId;
    if (_hydrated && persistence != null && profileId != null) {
      _persistSnapshot(persistence, profileId, snapshot());
    }
    _disposed = true;
    ++_audioRevision;
    ++_inputRevision;
    final audibleHandler = _audibleHandler;
    final inputHandler = _inputHandler;
    _audioQueue = _audioQueue.then((_) async {
      await _applyOwnershipSafely(audibleHandler, false);
    });
    _inputQueue = _inputQueue.then((_) async {
      await _applyOwnershipSafely(inputHandler, false);
    });
    _audibleSessionId = null;
    _audibleHandler = null;
    _inputSessionId = null;
    _inputHandler = null;
    _positioningSessionId = null;
    _placementBeforeMove = null;
    // The profile route subtree owns teardown of its media routes/services.
    // Avoid calling user callbacks while the provider tree is being dismantled.
    _sessions.clear();
    _placements.clear();
    _parkedSessionIds.clear();
    _restoredSessionIds.clear();
    _focusedInputSurfaceIds.clear();
    _fullscreenSessionId = null;
    _sessionTrayVisible = false;
    super.dispose();
  }
}
