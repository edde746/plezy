import 'dart:convert';

import 'package:uuid/uuid.dart';

enum RemoteStreamService { realDebrid, allDebrid, premiumize, torbox }

enum RemoteCloudItemKind { folder, file }

/// One bounded inventory page. `nextCursor` is an opaque, provider-local
/// continuation token and is deliberately kept out of persisted settings.
class RemoteCloudPage {
  const RemoteCloudPage({required this.items, this.nextCursor});

  final List<RemoteCloudItem> items;
  final String? nextCursor;
}

/// A short-lived inventory row returned by a debrid account. `uri` and
/// provider identifiers are held only in memory; this type is never persisted.
class RemoteCloudItem {
  const RemoteCloudItem({
    required this.id,
    required this.name,
    required this.service,
    required this.kind,
    this.size,
    this.mimeType,
    this.providerId,
    this.providerFileId,
    this.parentProviderId,
    this.uri,
    this.accountId,
  });

  final String id;
  final String name;
  final RemoteStreamService service;
  final RemoteCloudItemKind kind;
  final int? size;
  final String? mimeType;
  final String? providerId;
  final String? providerFileId;
  final String? parentProviderId;
  final Uri? uri;
  final String? accountId;

  RemoteCloudItem withAccountId(String value, {String? parentProviderId}) => RemoteCloudItem(
    id: id,
    name: name,
    service: service,
    kind: kind,
    size: size,
    mimeType: mimeType,
    providerId: providerId,
    providerFileId: providerFileId,
    parentProviderId: parentProviderId ?? this.parentProviderId,
    uri: uri,
    accountId: value,
  );
}

enum RemoteProviderFailure {
  authentication,
  unavailable,
  invalidResponse,
  unsupported,
  preparationFailed,
  timeout,
  cancelled,
}

class RemoteProviderException implements Exception {
  const RemoteProviderException(this.reason);
  final RemoteProviderFailure reason;
}

class RemoteStreamAccount {
  const RemoteStreamAccount({
    required this.id,
    required this.service,
    required this.displayName,
    required this.accessToken,
    this.refreshToken,
    this.clientId,
    this.clientSecret,
    this.expiresAt,
  });

  factory RemoteStreamAccount.create({
    required RemoteStreamService service,
    required String displayName,
    required String accessToken,
    String? refreshToken,
    String? clientId,
    String? clientSecret,
    int? expiresAt,
  }) => RemoteStreamAccount(
    id: const Uuid().v4(),
    service: service,
    displayName: displayName,
    accessToken: accessToken,
    refreshToken: refreshToken,
    clientId: clientId,
    clientSecret: clientSecret,
    expiresAt: expiresAt,
  );

  final String id;
  final RemoteStreamService service;
  final String displayName;
  final String accessToken;
  final String? refreshToken;
  final String? clientId;
  final String? clientSecret;
  final int? expiresAt;

  RemoteStreamAccount copyWith({String? accessToken, String? refreshToken, int? expiresAt}) => RemoteStreamAccount(
    id: id,
    service: service,
    displayName: displayName,
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    clientId: clientId,
    clientSecret: clientSecret,
    expiresAt: expiresAt ?? this.expiresAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'service': service.name,
    'displayName': displayName,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'clientId': clientId,
    'clientSecret': clientSecret,
    'expiresAt': expiresAt,
  };

  factory RemoteStreamAccount.fromJson(Map<String, dynamic> json) => RemoteStreamAccount(
    id: json['id'] as String,
    service: RemoteStreamService.values.byName(json['service'] as String),
    displayName: json['displayName'] as String? ?? '',
    accessToken: json['accessToken'] as String? ?? '',
    refreshToken: json['refreshToken'] as String?,
    clientId: json['clientId'] as String?,
    clientSecret: json['clientSecret'] as String?,
    expiresAt: (json['expiresAt'] as num?)?.toInt(),
  );
}

class StremioAddonInstallation {
  const StremioAddonInstallation({
    required this.id,
    required this.name,
    required this.manifestUrl,
    required this.manifest,
    this.enabled = true,
    this.allowHttp = false,
  });

  final String id;
  final String name;

  /// May contain an add-on-issued path token. Persisted only inside the
  /// encrypted remote-stream snapshot and never included in diagnostics.
  final String manifestUrl;
  final Map<String, dynamic> manifest;
  final bool enabled;
  final bool allowHttp;

  StremioAddonInstallation copyWith({bool? enabled}) => StremioAddonInstallation(
    id: id,
    name: name,
    manifestUrl: manifestUrl,
    manifest: manifest,
    enabled: enabled ?? this.enabled,
    allowHttp: allowHttp,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'manifestUrl': manifestUrl,
    'manifest': manifest,
    'enabled': enabled,
    'allowHttp': allowHttp,
  };

  factory StremioAddonInstallation.fromJson(Map<String, dynamic> json) => StremioAddonInstallation(
    id: json['id'] as String,
    name: json['name'] as String,
    manifestUrl: json['manifestUrl'] as String,
    manifest: Map<String, dynamic>.from(json['manifest'] as Map),
    enabled: json['enabled'] as bool? ?? true,
    allowHttp: json['allowHttp'] as bool? ?? false,
  );
}

/// A fetched manifest update that is safe to present for user review.
///
/// Instances are created by [RemoteStreamingProvider] after validating the
/// configured endpoint. The captured profile and generation prevent a review
/// dialog opened for one profile from updating a later active profile.
class StremioAddonUpdateCheck {
  const StremioAddonUpdateCheck({
    required this.installed,
    required this.latestManifest,
    required this.hasChanges,
    required this.profileId,
    required this.generation,
  });

  final StremioAddonInstallation installed;
  final Map<String, dynamic> latestManifest;
  final bool hasChanges;
  final String profileId;
  final int generation;

  String get currentVersion => installed.manifest['version'] as String? ?? '';
  String get latestVersion => latestManifest['version'] as String? ?? '';
}

enum RemotePreparationState { preparing, ready, failed, cancelled, interrupted }

typedef RemotePreparationProgress = Future<void> Function({required String stage, String? providerJobId});

/// Durable, non-secret checkpoint for one user-requested debrid preparation.
/// Provider credentials and resolved links never enter this record.
class RemotePreparationJob {
  const RemotePreparationJob({
    required this.id,
    required this.accountId,
    required this.service,
    required this.infoHash,
    required this.title,
    required this.requestId,
    required this.requestType,
    required this.addonId,
    required this.label,
    required this.state,
    required this.stage,
    required this.createdAt,
    required this.updatedAt,
    this.fileIndex,
    this.providerJobId,
    this.errorCode,
  });

  final String id;
  final String accountId;
  final RemoteStreamService service;
  final String infoHash;
  final String title;
  final String requestId;
  final String requestType;
  final String addonId;
  final String label;
  final RemotePreparationState state;
  final String stage;
  final int createdAt;
  final int updatedAt;
  final int? fileIndex;
  final String? providerJobId;
  final String? errorCode;

  RemotePreparationJob copyWith({
    RemotePreparationState? state,
    String? stage,
    int? updatedAt,
    String? providerJobId,
    String? errorCode,
  }) => RemotePreparationJob(
    id: id,
    accountId: accountId,
    service: service,
    infoHash: infoHash,
    title: title,
    requestId: requestId,
    requestType: requestType,
    addonId: addonId,
    label: label,
    state: state ?? this.state,
    stage: stage ?? this.stage,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    fileIndex: fileIndex,
    providerJobId: providerJobId ?? this.providerJobId,
    errorCode: errorCode ?? this.errorCode,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'accountId': accountId,
    'service': service.name,
    'infoHash': infoHash,
    'title': title,
    'requestId': requestId,
    'requestType': requestType,
    'addonId': addonId,
    'label': label,
    'state': state.name,
    'stage': stage,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'fileIndex': fileIndex,
    'providerJobId': providerJobId,
    'errorCode': errorCode,
  };

  factory RemotePreparationJob.fromJson(Map<String, dynamic> json) => RemotePreparationJob(
    id: _requiredRemoteText(json, 'id', 128),
    accountId: _requiredRemoteText(json, 'accountId', 128),
    service: RemoteStreamService.values.byName(_requiredRemoteText(json, 'service', 32)),
    infoHash: _requiredRemoteHash(json),
    title: _requiredRemoteText(json, 'title', 512),
    requestId: _requiredRemoteText(json, 'requestId', 512),
    requestType: _requiredRemoteText(json, 'requestType', 16),
    addonId: _requiredRemoteText(json, 'addonId', 128),
    label: _requiredRemoteText(json, 'label', 512),
    state: RemotePreparationState.values.byName(_requiredRemoteText(json, 'state', 32)),
    stage: _requiredRemoteText(json, 'stage', 64),
    createdAt: _remoteInt(json['createdAt']),
    updatedAt: _remoteInt(json['updatedAt']),
    fileIndex: _optionalRemoteIndex(json['fileIndex']),
    providerJobId: _optionalRemoteText(json, 'providerJobId', 128),
    errorCode: _optionalRemoteText(json, 'errorCode', 64),
  );
}

String _requiredRemoteText(Map<String, dynamic> json, String key, int maxLength) {
  final value = json[key];
  if (value is! String || value.isEmpty || value.length > maxLength || RegExp(r'[\x00-\x1f\x7f]').hasMatch(value)) {
    throw const FormatException('Invalid remote preparation field');
  }
  return value;
}

int _remoteInt(Object? value) => value is int && value >= 0 ? value : throw const FormatException('Invalid timestamp');

String? _optionalRemoteText(Map<String, dynamic> json, String key, int maxLength) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String || value.isEmpty || value.length > maxLength || RegExp(r'[\x00-\x1f\x7f]').hasMatch(value)) {
    throw const FormatException('Invalid optional remote preparation field');
  }
  return value;
}

int? _optionalRemoteIndex(Object? value) {
  if (value == null) return null;
  if (value is int && value >= 0 && value <= 1000000) return value;
  throw const FormatException('Invalid file index');
}

String _requiredRemoteHash(Map<String, dynamic> json) {
  final value = _requiredRemoteText(json, 'infoHash', 40);
  if (!RegExp(r'^[0-9a-fA-F]{40}$').hasMatch(value)) throw const FormatException('Invalid preparation hash');
  return value;
}

class RemoteStreamSnapshot {
  const RemoteStreamSnapshot({this.accounts = const [], this.addons = const [], this.preparations = const []});

  final List<RemoteStreamAccount> accounts;
  final List<StremioAddonInstallation> addons;
  final List<RemotePreparationJob> preparations;

  RemoteStreamSnapshot copyWith({
    List<RemoteStreamAccount>? accounts,
    List<StremioAddonInstallation>? addons,
    List<RemotePreparationJob>? preparations,
  }) => RemoteStreamSnapshot(
    accounts: accounts ?? this.accounts,
    addons: addons ?? this.addons,
    preparations: preparations ?? this.preparations,
  );

  Map<String, Object?> toJson() => {
    'version': 1,
    'accounts': accounts.map((account) => account.toJson()).toList(),
    'addons': addons.map((addon) => addon.toJson()).toList(),
    'preparations': preparations.map((job) => job.toJson()).toList(),
  };

  String encode() => jsonEncode(toJson());

  factory RemoteStreamSnapshot.decode(String raw) {
    if (raw.length > 16 * 1024 * 1024) throw const FormatException('Remote-stream snapshot is too large');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    if (json['version'] != 1) throw const FormatException('Unsupported remote-stream snapshot');
    final rawAccounts = json['accounts'] as List? ?? const [];
    final rawAddons = json['addons'] as List? ?? const [];
    final rawPreparationValue = json['preparations'];
    final rawPreparations = rawPreparationValue is List ? rawPreparationValue : const [];
    if (rawAccounts.length > RemoteStreamService.values.length || rawAddons.length > 50) {
      throw const FormatException('Remote-stream snapshot has too many entries');
    }
    if (rawAccounts.any((row) => row is! Map) || rawAddons.any((row) => row is! Map)) {
      throw const FormatException('Remote-stream snapshot contains an invalid entry');
    }
    // The preparation journal is an optional additive extension. A damaged
    // checkpoint must not make previously valid account credentials unreadable.
    final preparations = <RemotePreparationJob>[];
    for (final row in rawPreparations.take(50)) {
      if (row is! Map) continue;
      try {
        preparations.add(RemotePreparationJob.fromJson(Map<String, dynamic>.from(row)));
      } on Object {
        continue;
      }
    }
    return RemoteStreamSnapshot(
      accounts: rawAccounts
          .map((row) => RemoteStreamAccount.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false),
      addons: rawAddons
          .map((row) => StremioAddonInstallation.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false),
      preparations: preparations,
    );
  }
}

class RemoteStreamRequest {
  const RemoteStreamRequest({
    required this.type,
    required this.id,
    required this.title,
    this.year,
    this.season,
    this.episode,
  });

  final String type;
  final String id;
  final String title;
  final int? year;
  final int? season;
  final int? episode;
}

class RemoteStreamCandidate {
  const RemoteStreamCandidate({
    required this.addonId,
    required this.addonName,
    required this.label,
    this.description,
    this.url,
    this.headers = const {},
    this.infoHash,
    this.fileIndex,
    this.externalUrl,
    this.subtitles = const [],
    this.behaviorHints = const {},
  });

  final String addonId;
  final String addonName;
  final String label;
  final String? description;
  final Uri? url;
  final Map<String, String> headers;
  final String? infoHash;
  final int? fileIndex;
  final Uri? externalUrl;
  final List<RemoteSubtitle> subtitles;
  final Map<String, dynamic> behaviorHints;

  bool get isInAppPlayable => url != null || infoHash != null;
}

class RemoteSubtitle {
  const RemoteSubtitle({required this.id, required this.url, this.lang, this.label});
  final String id;
  final Uri url;
  final String? lang;
  final String? label;
}
