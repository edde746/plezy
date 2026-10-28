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
  final Uri? uri;
  final String? accountId;

  RemoteCloudItem withAccountId(String value) => RemoteCloudItem(
    id: id,
    name: name,
    service: service,
    kind: kind,
    size: size,
    mimeType: mimeType,
    providerId: providerId,
    providerFileId: providerFileId,
    uri: uri,
    accountId: value,
  );
}

enum RemoteProviderFailure { authentication, unavailable, invalidResponse, unsupported, preparationFailed, timeout, cancelled }

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

class RemoteStreamSnapshot {
  const RemoteStreamSnapshot({this.accounts = const [], this.addons = const []});

  final List<RemoteStreamAccount> accounts;
  final List<StremioAddonInstallation> addons;

  Map<String, Object?> toJson() => {
    'version': 1,
    'accounts': accounts.map((account) => account.toJson()).toList(),
    'addons': addons.map((addon) => addon.toJson()).toList(),
  };

  String encode() => jsonEncode(toJson());

  factory RemoteStreamSnapshot.decode(String raw) {
    if (raw.length > 16 * 1024 * 1024) throw const FormatException('Remote-stream snapshot is too large');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    if (json['version'] != 1) throw const FormatException('Unsupported remote-stream snapshot');
    final rawAccounts = json['accounts'] as List? ?? const [];
    final rawAddons = json['addons'] as List? ?? const [];
    if (rawAccounts.length > RemoteStreamService.values.length || rawAddons.length > 50) {
      throw const FormatException('Remote-stream snapshot has too many entries');
    }
    if (rawAccounts.any((row) => row is! Map) || rawAddons.any((row) => row is! Map)) {
      throw const FormatException('Remote-stream snapshot contains an invalid entry');
    }
    return RemoteStreamSnapshot(
      accounts: rawAccounts
          .map((row) => RemoteStreamAccount.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false),
      addons: rawAddons
          .map((row) => StremioAddonInstallation.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false),
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
