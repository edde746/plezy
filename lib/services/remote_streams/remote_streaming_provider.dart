import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'additional_debrid_clients.dart';
import 'real_debrid_client.dart';
import 'remote_stream_models.dart';
import 'remote_stream_store.dart';
import 'stremio_addon_client.dart';

class RemoteStreamSearchResult {
  const RemoteStreamSearchResult({required this.candidates, required this.failedAddons});
  final List<RemoteStreamCandidate> candidates;
  final int failedAddons;
}

/// Profile-bound owner for remote stream settings and add-on requests.
/// Switching profile invalidates in-flight discovery before it can publish or
/// persist results into the next profile.
class RemoteStreamingProvider extends ChangeNotifier {
  String? _profileId;
  int _generation = 0;
  bool loading = false;
  bool loadFailed = false;
  bool settingsUnreadable = false;
  bool _disposed = false;
  RemoteStreamSnapshot _snapshot = const RemoteStreamSnapshot();
  Future<void> _mutationQueue = Future.value();

  String? get profileId => _profileId;
  bool get isReady => !loading && !loadFailed && _profileId != null;
  List<RemoteStreamAccount> get accounts => _snapshot.accounts;
  List<StremioAddonInstallation> get addons => _snapshot.addons;

  RemoteStreamAccount? accountFor(RemoteStreamService service) =>
      accounts.where((account) => account.service == service).firstOrNull;

  void attachProfile(String? profileId, {bool blocked = false}) {
    if (blocked || profileId == null) {
      if (_profileId != null || loading) {
        _profileId = null;
        _generation++;
        loading = false;
        loadFailed = false;
        settingsUnreadable = false;
        _snapshot = const RemoteStreamSnapshot();
        _notify();
      }
      return;
    }
    if (_profileId == profileId) return;
    _profileId = profileId;
    final generation = ++_generation;
    loading = true;
    loadFailed = false;
    settingsUnreadable = false;
    _snapshot = const RemoteStreamSnapshot();
    _notify();
    unawaited(_load(profileId, generation));
  }

  Future<void> _load(String profileId, int generation) async {
    try {
      final snapshot = await RemoteStreamStore.load(profileId);
      if (!_current(profileId, generation)) return;
      _snapshot = snapshot;
      loadFailed = false;
      settingsUnreadable = false;
    } on Object catch (error) {
      if (!_current(profileId, generation)) return;
      _snapshot = const RemoteStreamSnapshot();
      loadFailed = true;
      settingsUnreadable = error is RemoteStreamStoreException;
    } finally {
      if (_current(profileId, generation)) {
        loading = false;
        _notify();
      }
    }
  }

  void retrySettingsLoad() {
    final profile = _profileId;
    if (profile == null || loading || !loadFailed) return;
    final generation = ++_generation;
    loading = true;
    loadFailed = false;
    settingsUnreadable = false;
    _snapshot = const RemoteStreamSnapshot();
    _notify();
    unawaited(_load(profile, generation));
  }

  Future<void> clearUnreadableSettings() async {
    final profile = _profileId;
    if (profile == null || loading || !loadFailed || !settingsUnreadable) {
      throw StateError('Remote streaming settings are not in a recoverable state');
    }
    final generation = _generation;
    const empty = RemoteStreamSnapshot();
    await _serializeMutation(() async {
      if (!_current(profile, generation)) return;
      await RemoteStreamStore.save(profile, empty);
      if (!_current(profile, generation)) return;
      _snapshot = empty;
      loadFailed = false;
      settingsUnreadable = false;
      _notify();
    });
  }

  Future<StremioAddonInstallation> installAddon(String address, {required bool allowHttp}) async {
    final (profile, generation) = _requireProfile();
    final existing = addons.where((addon) => addon.manifestUrl == address).firstOrNull;
    if (existing != null) return existing;
    if (addons.length >= 50) throw const StremioAddonException(StremioAddonFailure.unavailable);
    final client = StremioAddonClient();
    try {
      final manifest = await client.fetchManifest(address, allowHttp: allowHttp);
      if (!_current(profile, generation)) throw const StremioAddonException(StremioAddonFailure.unavailable);
      late StremioAddonInstallation installed;
      await _commit(profile, generation, (current) {
        final existing = current.addons.where((addon) => addon.manifestUrl == address).firstOrNull;
        if (existing != null) {
          installed = existing;
          return current;
        }
        if (current.addons.length >= 50) throw const StremioAddonException(StremioAddonFailure.unavailable);
        installed = StremioAddonInstallation(
          id: const Uuid().v4(),
          name: (manifest['name'] as String).trim(),
          manifestUrl: address,
          manifest: manifest,
          allowHttp: allowHttp,
        );
        return RemoteStreamSnapshot(addons: [...current.addons, installed], accounts: current.accounts);
      });
      return installed;
    } finally {
      client.close();
    }
  }

  Future<void> setAddonEnabled(String id, bool enabled) async {
    final (profile, generation) = _requireProfile();
    await _commit(profile, generation, (current) {
      final next = current.addons
          .map((addon) => addon.id == id ? addon.copyWith(enabled: enabled) : addon)
          .toList(growable: false);
      return RemoteStreamSnapshot(addons: next, accounts: current.accounts);
    });
  }

  Future<void> removeAddon(String id) async {
    final (profile, generation) = _requireProfile();
    await _commit(
      profile,
      generation,
      (current) => RemoteStreamSnapshot(
        addons: current.addons.where((addon) => addon.id != id).toList(growable: false),
        accounts: current.accounts,
      ),
    );
  }

  Future<void> saveAccount(RemoteStreamAccount account) async {
    final (profile, generation) = _requireProfile();
    await _commit(profile, generation, (current) {
      final next = [...current.accounts.where((saved) => saved.service != account.service), account];
      return RemoteStreamSnapshot(addons: current.addons, accounts: next);
    });
  }

  Future<void> removeAccount(RemoteStreamService service) async {
    final (profile, generation) = _requireProfile();
    await _commit(
      profile,
      generation,
      (current) => RemoteStreamSnapshot(
        addons: current.addons,
        accounts: current.accounts.where((account) => account.service != service).toList(growable: false),
      ),
    );
  }

  Future<void> _persistRefreshedAccount(
    String profile,
    int generation,
    String accountId,
    RemoteStreamAccount updated,
  ) async {
    if (!_current(profile, generation)) return;
    await _commit(profile, generation, (current) {
      if (current.accounts.where((account) => account.service == updated.service).firstOrNull?.id != accountId) {
        return current;
      }
      return RemoteStreamSnapshot(
        addons: current.addons,
        accounts: [for (final account in current.accounts) if (account.service != updated.service) account, updated],
      );
    });
  }

  Future<ResolvedRemoteStream> resolveTorrent(RemoteStreamCandidate candidate, {RemoteStreamService? service}) async {
    final hash = candidate.infoHash;
    if (hash == null) throw const RealDebridException(RealDebridFailure.unsupported);
    final profile = _profileId;
    final generation = _generation;
    if (profile == null || loading) throw const RealDebridException(RealDebridFailure.cancelled);
    // One provider receives each preparation request. A failed provider call
    // may have created a remote job, so silently fanning out to every account
    // would create duplicate transfers and consume multiple quotas.
    final orderedServices = [
      RemoteStreamService.realDebrid,
      RemoteStreamService.allDebrid,
      RemoteStreamService.premiumize,
      RemoteStreamService.torbox,
    ];
    final selectedService = service ?? orderedServices.where((value) => accountFor(value) != null).firstOrNull;
    if (selectedService == null) throw const RealDebridException(RealDebridFailure.authentication);
    final account = accountFor(selectedService);
    if (account == null) throw const RealDebridException(RealDebridFailure.authentication);
    switch (selectedService) {
      case RemoteStreamService.realDebrid:
        final client = RealDebridClient(
          account: account,
          onAccountRefreshed: (updated) => _persistRefreshedAccount(profile, generation, account.id, updated),
        );
        try {
          return await client.resolveTorrentHash(
            hash,
            fileIndex: candidate.fileIndex,
            shouldCancel: () => !_current(profile, generation),
          );
        } finally {
          client.close();
        }
      case RemoteStreamService.allDebrid:
        final client = AllDebridClient(account: account);
        try {
          return await client.resolveTorrentHash(
            hash,
            fileIndex: candidate.fileIndex,
            shouldCancel: () => !_current(profile, generation),
          );
        } finally {
          client.close();
        }
      case RemoteStreamService.premiumize:
        final client = PremiumizeClient(account: account);
        try {
          return await client.resolveTorrentHash(
            hash,
            fileIndex: candidate.fileIndex,
            shouldCancel: () => !_current(profile, generation),
          );
        } finally {
          client.close();
        }
      case RemoteStreamService.torbox:
        final client = TorBoxClient(account: account);
        try {
          return await client.resolveTorrentHash(
            hash,
            fileIndex: candidate.fileIndex,
            shouldCancel: () => !_current(profile, generation),
          );
        } finally {
          client.close();
        }
    }
  }

  Future<List<RemoteCloudItem>> browseCloud(RemoteStreamService service, {String? parentId}) async {
    final (profile, generation) = _requireProfile();
    final account = accountFor(service);
    if (account == null) throw const RemoteProviderException(RemoteProviderFailure.authentication);
    List<RemoteCloudItem> items;
    switch (service) {
      case RemoteStreamService.realDebrid:
        final client = RealDebridClient(
          account: account,
          onAccountRefreshed: (updated) => _persistRefreshedAccount(profile, generation, account.id, updated),
        );
        try {
          items = await client.browseCloud(torrentId: parentId);
        } finally {
          client.close();
        }
        break;
      case RemoteStreamService.allDebrid:
        final client = AllDebridClient(account: account);
        try {
          items = await client.browseCloud(magnetId: parentId);
        } finally {
          client.close();
        }
        break;
      case RemoteStreamService.premiumize:
        final client = PremiumizeClient(account: account);
        try {
          items = await client.browseCloud(folderId: parentId);
        } finally {
          client.close();
        }
        break;
      case RemoteStreamService.torbox:
        final client = TorBoxClient(account: account);
        try {
          items = await client.browseCloud(torrentId: parentId);
        } finally {
          client.close();
        }
        break;
    }
    if (!_current(profile, generation)) throw const RemoteProviderException(RemoteProviderFailure.cancelled);
    return List.unmodifiable(items.map((item) => item.withAccountId(account.id)));
  }

  Future<ResolvedRemoteStream> resolveCloudFile(RemoteCloudItem item) async {
    final (profile, generation) = _requireProfile();
    if (item.kind != RemoteCloudItemKind.file) throw const RemoteProviderException(RemoteProviderFailure.unsupported);
    final account = accountFor(item.service);
    if (account == null) throw const RemoteProviderException(RemoteProviderFailure.authentication);
    if (item.accountId != account.id) throw const RemoteProviderException(RemoteProviderFailure.cancelled);
    late final ResolvedRemoteStream resolved;
    switch (item.service) {
      case RemoteStreamService.realDebrid:
        final link = item.uri;
        if (link == null) throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
        final client = RealDebridClient(
          account: account,
          onAccountRefreshed: (updated) => _persistRefreshedAccount(profile, generation, account.id, updated),
        );
        try {
          resolved = await client.resolveHosterLink(link);
        } finally {
          client.close();
        }
        break;
      case RemoteStreamService.allDebrid:
        final link = item.uri;
        if (link == null) throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
        final client = AllDebridClient(account: account);
        try {
          resolved = await client.resolveHosterLink(link);
        } finally {
          client.close();
        }
        break;
      case RemoteStreamService.premiumize:
        final link = item.uri;
        if (link == null || link.scheme != 'https' || link.host.isEmpty || link.userInfo.isNotEmpty) {
          throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
        }
        resolved = ResolvedRemoteStream(uri: link, fileName: item.name, size: item.size);
        break;
      case RemoteStreamService.torbox:
        final client = TorBoxClient(account: account);
        try {
          resolved = await client.resolveCloudFile(item);
        } finally {
          client.close();
        }
    }
    if (!_current(profile, generation)) throw const RemoteProviderException(RemoteProviderFailure.cancelled);
    return resolved;
  }

  Future<ResolvedRemoteStream> resolveHosterLink(Uri link, {required RemoteStreamService service}) async {
    if (link.scheme != 'https' || link.host.isEmpty || link.userInfo.isNotEmpty || link.toString().length > 4096) {
      throw const RemoteProviderException(RemoteProviderFailure.unsupported);
    }
    final profile = _profileId;
    final generation = _generation;
    if (profile == null || loading) throw const RemoteProviderException(RemoteProviderFailure.cancelled);
    final account = accountFor(service);
    if (account == null) throw const RemoteProviderException(RemoteProviderFailure.authentication);
    switch (service) {
      case RemoteStreamService.realDebrid:
        final client = RealDebridClient(
          account: account,
          onAccountRefreshed: (updated) => _persistRefreshedAccount(profile, generation, account.id, updated),
        );
        try {
          return await client.resolveHosterLink(link);
        } finally {
          client.close();
        }
      case RemoteStreamService.allDebrid:
        final client = AllDebridClient(account: account);
        try {
          return await client.resolveHosterLink(link);
        } finally {
          client.close();
        }
      case RemoteStreamService.premiumize:
        final client = PremiumizeClient(account: account);
        try {
          return await client.resolveHosterLink(link);
        } finally {
          client.close();
        }
      case RemoteStreamService.torbox:
        throw const RemoteProviderException(RemoteProviderFailure.unsupported);
    }
  }

  Future<RemoteStreamSearchResult> streamsFor(RemoteStreamRequest request) async {
    final profile = _profileId;
    if (profile == null || loading) return const RemoteStreamSearchResult(candidates: [], failedAddons: 0);
    final generation = _generation;
    final enabled = addons.where((addon) => addon.enabled).toList(growable: false);
    if (enabled.isEmpty) return const RemoteStreamSearchResult(candidates: [], failedAddons: 0);
    final results = await Future.wait(enabled.map((addon) async {
      final client = StremioAddonClient();
      try {
        return await client.fetchStreams(addon, request).timeout(const Duration(seconds: 22));
      } on Object {
        return null;
      } finally {
        client.close();
      }
    }));
    if (!_current(profile, generation)) return const RemoteStreamSearchResult(candidates: [], failedAddons: 0);
    final candidates = <RemoteStreamCandidate>[
      for (final result in results)
        if (result != null) ...result,
    ];
    return RemoteStreamSearchResult(
      candidates: List.unmodifiable(candidates),
      failedAddons: results.where((result) => result == null).length,
    );
  }

  Future<void> _commit(
    String profile,
    int generation,
    RemoteStreamSnapshot Function(RemoteStreamSnapshot current) update,
  ) => _serializeMutation(() async {
    if (!_current(profile, generation)) throw const StremioAddonException(StremioAddonFailure.unavailable);
    final snapshot = update(_snapshot);
    await RemoteStreamStore.save(profile, snapshot);
    if (!_current(profile, generation)) return;
    _snapshot = snapshot;
    _notify();
  });

  Future<T> _serializeMutation<T>(Future<T> Function() operation) {
    final next = _mutationQueue.then((_) => operation());
    _mutationQueue = next.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return next;
  }

  (String, int) _requireProfile() {
    final profile = _profileId;
    if (profile == null || loading) throw StateError('Remote streaming is unavailable for the active profile');
    return (profile, _generation);
  }

  bool _current(String profile, int generation) => !_disposed && _profileId == profile && _generation == generation;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
