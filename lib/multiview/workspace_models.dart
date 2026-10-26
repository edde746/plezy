import 'dart:ui' show Offset, Size;

import 'package:flutter/foundation.dart';

/// The content families a workspace can retain independently of their route.
enum MultiviewMediaKind { video, liveTv, music, audiobook, publication, comic, game }

enum MultiviewLayoutMode { floating, sideBySide }

/// A normalized rectangle. Values are relative to the app viewport and survive
/// window resize and display scale changes.
@immutable
class WorkspacePlacement {
  const WorkspacePlacement({required this.left, required this.top, required this.width, required this.height})
    : assert(left >= 0 && left <= 1),
      assert(top >= 0 && top <= 1),
      assert(width > 0 && width <= 1),
      assert(height > 0 && height <= 1);

  const WorkspacePlacement.initial() : left = 0.54, top = 0.58, width = 0.44, height = 0.34;

  final double left;
  final double top;
  final double width;
  final double height;

  WorkspacePlacement withDelta({double? left, double? top, double? width, double? height}) {
    final nextWidth = (width ?? this.width).clamp(0.2, 1.0).toDouble();
    final nextHeight = (height ?? this.height).clamp(0.18, 1.0).toDouble();
    return WorkspacePlacement(
      left: (left ?? this.left).clamp(0.0, 1.0 - nextWidth).toDouble(),
      top: (top ?? this.top).clamp(0.0, 1.0 - nextHeight).toDouble(),
      width: nextWidth,
      height: nextHeight,
    );
  }

  /// Converts normalized top-left placement into viewport pixels.
  ///
  /// [left] and [top] are fractions of the full viewport, while the bounds
  /// clamp the top-left point to keep the complete pane on screen.
  Offset resolveTopLeft(Size viewport, {required double windowWidth, required double windowHeight}) {
    if (viewport.width <= 0 || viewport.height <= 0) return Offset.zero;
    final maxLeft = (viewport.width - windowWidth).clamp(0.0, viewport.width).toDouble();
    final maxTop = (viewport.height - windowHeight).clamp(0.0, viewport.height).toDouble();
    return Offset(
      (viewport.width * left).clamp(0.0, maxLeft).toDouble(),
      (viewport.height * top).clamp(0.0, maxTop).toDouble(),
    );
  }

  /// Moves a pane using the visible window size for this viewport.
  ///
  /// Layouts with a platform minimum or maximum window size can differ from
  /// the saved normalized size. This keeps movement smooth on the current
  /// viewport without rewriting the user's saved size.
  WorkspacePlacement withPosition({
    required double left,
    required double top,
    double? maximumLeft,
    double? maximumTop,
  }) {
    final leftLimit = (maximumLeft ?? 1.0 - width).clamp(0.0, 1.0).toDouble();
    final topLimit = (maximumTop ?? 1.0 - height).clamp(0.0, 1.0).toDouble();
    return WorkspacePlacement(
      left: left.clamp(0.0, leftLimit).toDouble(),
      top: top.clamp(0.0, topLimit).toDouble(),
      width: width,
      height: height,
    );
  }

  Map<String, Object> toJson() => {'left': left, 'top': top, 'width': width, 'height': height};

  factory WorkspacePlacement.fromJson(Map<String, Object?> json) {
    double number(String key) {
      final value = json[key];
      if (value is! num || !value.isFinite) {
        throw FormatException('Invalid workspace placement field: $key');
      }
      return value.toDouble();
    }

    return const WorkspacePlacement.initial().withDelta(
      left: number('left'),
      top: number('top'),
      width: number('width'),
      height: number('height'),
    );
  }
}

/// Safe-to-store identity and presentation metadata for a live session.
///
/// Renderer objects, player instances, source URLs, request headers, tokens,
/// and native handles are deliberately kept out of this descriptor. Those
/// remain owned by a runtime adapter and are never serialized in snapshots.
@immutable
class WorkspaceSessionDescriptor {
  const WorkspaceSessionDescriptor({
    required this.id,
    required this.kind,
    required this.title,
    this.subtitle,
    this.mediaKey,
    this.progressOwner,
    this.hasAudio = false,
    this.hasVideo = false,
    this.acceptsInput = false,
    required this.openedAt,
  }) : assert(id != ''),
       assert(title != '');

  final String id;
  final MultiviewMediaKind kind;
  final String title;
  final String? subtitle;

  /// A stable, non-secret item identity such as server-id plus library key.
  /// It is not a playback URL and must not contain credentials.
  final String? mediaKey;

  /// Stable progress owner used to prevent duplicate history/scrobble writes.
  final String? progressOwner;
  final bool hasAudio;
  final bool hasVideo;
  final bool acceptsInput;
  final DateTime openedAt;

  WorkspaceSessionDescriptor copyWith({
    MultiviewMediaKind? kind,
    String? title,
    String? subtitle,
    bool clearSubtitle = false,
    String? mediaKey,
    String? progressOwner,
    bool? hasAudio,
    bool? hasVideo,
    bool? acceptsInput,
  }) => WorkspaceSessionDescriptor(
    id: id,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    subtitle: clearSubtitle ? null : (subtitle ?? this.subtitle),
    mediaKey: mediaKey ?? this.mediaKey,
    progressOwner: progressOwner ?? this.progressOwner,
    hasAudio: hasAudio ?? this.hasAudio,
    hasVideo: hasVideo ?? this.hasVideo,
    acceptsInput: acceptsInput ?? this.acceptsInput,
    openedAt: openedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    if (subtitle != null) 'subtitle': subtitle,
    if (mediaKey != null) 'mediaKey': mediaKey,
    if (progressOwner != null) 'progressOwner': progressOwner,
    'hasAudio': hasAudio,
    'hasVideo': hasVideo,
    'acceptsInput': acceptsInput,
    'openedAt': openedAt.toUtc().toIso8601String(),
  };

  factory WorkspaceSessionDescriptor.fromJson(Map<String, Object?> json) {
    String requiredString(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Invalid workspace session field: $key');
      }
      return value;
    }

    String? optionalString(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is! String) throw FormatException('Invalid workspace session field: $key');
      return value;
    }

    bool optionalBool(String key) {
      final value = json[key];
      if (value == null) return false;
      if (value is! bool) throw FormatException('Invalid workspace session field: $key');
      return value;
    }

    final kindName = requiredString('kind');
    final kind = MultiviewMediaKind.values.where((value) => value.name == kindName);
    if (kind.isEmpty) throw FormatException('Unknown workspace media kind: $kindName');

    final openedAtString = requiredString('openedAt');
    final openedAt = DateTime.tryParse(openedAtString);
    if (openedAt == null) throw const FormatException('Invalid workspace openedAt');

    return WorkspaceSessionDescriptor(
      id: requiredString('id'),
      kind: kind.first,
      title: requiredString('title'),
      subtitle: optionalString('subtitle'),
      mediaKey: optionalString('mediaKey'),
      progressOwner: optionalString('progressOwner'),
      hasAudio: optionalBool('hasAudio'),
      hasVideo: optionalBool('hasVideo'),
      acceptsInput: optionalBool('acceptsInput'),
      openedAt: openedAt.toUtc(),
    );
  }
}

/// Versioned, profile-local workspace layout metadata.
///
/// A snapshot can restore layout and descriptions after a restart. Runtime
/// adapters must re-resolve sources and authenticate through existing flows;
/// a snapshot never reopens a stream or launches a game automatically.
@immutable
class WorkspaceSnapshot {
  const WorkspaceSnapshot({
    this.schemaVersion = currentSchemaVersion,
    required this.sessions,
    required this.placements,
    required this.layoutMode,
    this.focusedSessionId,
    this.audibleSessionId,
    this.inputSessionId,
    this.audioSelectionExplicit = false,
  }) : assert(schemaVersion == currentSchemaVersion);

  static const int currentSchemaVersion = 2;

  final int schemaVersion;
  final List<WorkspaceSessionDescriptor> sessions;
  final Map<String, WorkspacePlacement> placements;
  final MultiviewLayoutMode layoutMode;
  final String? focusedSessionId;
  final String? audibleSessionId;
  final String? inputSessionId;
  final bool audioSelectionExplicit;

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'sessions': sessions.map((session) => session.toJson()).toList(growable: false),
    'placements': {for (final entry in placements.entries) entry.key: entry.value.toJson()},
    'layoutMode': layoutMode.name,
    if (focusedSessionId != null) 'focusedSessionId': focusedSessionId,
    if (audibleSessionId != null) 'audibleSessionId': audibleSessionId,
    if (inputSessionId != null) 'inputSessionId': inputSessionId,
    'audioSelectionExplicit': audioSelectionExplicit,
  };

  factory WorkspaceSnapshot.fromJson(Map<String, Object?> json) {
    final version = json['schemaVersion'];
    if (version is! int || (version != 1 && version != currentSchemaVersion)) {
      throw FormatException('Unsupported workspace snapshot version: $version');
    }

    final rawSessions = json['sessions'];
    if (rawSessions is! List) throw const FormatException('Invalid workspace sessions');
    final sessions = rawSessions
        .map((value) {
          if (value is! Map) throw const FormatException('Invalid workspace session');
          return WorkspaceSessionDescriptor.fromJson(Map<String, Object?>.from(value));
        })
        .toList(growable: false);

    final ids = sessions.map((session) => session.id).toSet();
    if (ids.length != sessions.length) throw const FormatException('Duplicate workspace session id');

    final rawPlacements = json['placements'];
    if (rawPlacements is! Map) throw const FormatException('Invalid workspace placements');
    final placements = <String, WorkspacePlacement>{};
    for (final entry in rawPlacements.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw const FormatException('Invalid workspace placement');
      }
      final id = entry.key as String;
      placements[id] = WorkspacePlacement.fromJson(Map<String, Object?>.from(entry.value as Map));
    }

    final layoutName = json['layoutMode'];
    final layout = MultiviewLayoutMode.values.where((value) => value.name == layoutName);
    if (layout.isEmpty) throw const FormatException('Unknown workspace layout');

    String? optionalSessionId(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is! String) throw FormatException('Invalid workspace field: $key');
      return ids.contains(value) ? value : null;
    }

    final audioSelectionExplicit = json['audioSelectionExplicit'];
    if (audioSelectionExplicit != null && audioSelectionExplicit is! bool) {
      throw const FormatException('Invalid workspace audio selection');
    }

    return WorkspaceSnapshot(
      schemaVersion: currentSchemaVersion,
      sessions: sessions,
      placements: placements,
      layoutMode: layout.first,
      focusedSessionId: optionalSessionId('focusedSessionId'),
      audibleSessionId: optionalSessionId('audibleSessionId'),
      inputSessionId: optionalSessionId('inputSessionId'),
      audioSelectionExplicit: audioSelectionExplicit as bool? ?? optionalSessionId('audibleSessionId') != null,
    );
  }
}
