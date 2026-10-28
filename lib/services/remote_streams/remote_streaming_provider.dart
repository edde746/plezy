import 'dart:async';
import 'dart:convert';

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
  static const _maxAutomaticRecoveryAttempts = 3;
  static const _retryableRecoveryErrors = {'unavailable', 'timeout', 'preparationFailed'};

  RemoteStreamingProvider({StremioAddonClient Function()? stremioAddonClientFactory})
    : _stremioAddonClientFactory = stremioAddonClientFactory ?? StremioAddonClient.new;

  final StremioAddonClient Function() _stremioAddonClientFactory;
  String? _profileId;
  int _generation = 0;
  bool loading = false;
  bool loadFailed = false;
  bool settingsUnreadable = false;
  bool _disposed = false;
  RemoteStreamSnapshot _snapshot = const RemoteStreamSnapshot();
  Future<void> _mutationQueue = Future.value();
  final Set<String> _cancelledPreparationIds = {};

  String? get profileId => _profileId;
  bool get isReady => !loading && !loadFailed && _profileId != null;
  List<RemoteStreamAccount> get accounts => _snapshot.accounts;
  List<StremioAddonInstallation> get addons => _snapshot.addons;
  List<RemotePreparationJob> get preparationJobs => _snapshot.preparations;
  final Map<String, Future<ResolvedRemoteStream>> _activeTorrentPreparations = {};

  /// Stops this device from polling or retrying a preparation. This does not
  /// delete the corresponding torrent or file from the remote provider.
  Future<void> cancelPreparation(String id) async {
    final (profile, generation) = _requireProfile();
    final job = _snapshot.preparations.where((candidate) => candidate.id == id).firstOrNull;
    if (job == null ||
        (job.state != RemotePreparationState.preparing && job.state != RemotePreparationState.interrupted)) {
      return;
    }

    // Signal first so active provider polling stops without waiting for I/O.
    _cancelledPreparationIds.add(id);
    final cancelledAt = DateTime.now().millisecondsSinceEpoch;
    await _commit(profile, generation, (current) => current.copyWith(
      preparations: [
        for (final candidate in current.preparations)
          if (candidate.id == id &&
              (candidate.state == RemotePreparationState.preparing ||
                  candidate.state == RemotePreparationState.interrupted))
            candidate.copyWith(
              state: RemotePreparationState.cancelled,
              stage: 'cancelled',
              updatedAt: cancelledAt,
              clearErrorCode: true,
            )
          else
            candidate,
      ],
    ));
  }

  RemoteStreamAccount? accountFor(RemoteStreamService service) =>
      accounts.where((account) => account.service == service).firstOrNull;

  void attachProfile(String? profileId, {bool blocked = false}) {
    if (blocked || profileId == null) {
      if (_profileId != null || loading) {
        _profileId = null;
        _generation++;
        _cancelledPreparationIds.clear();
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
    _cancelledPreparationIds.clear();
    final generation = ++_generation;
    loading = true;
    loadFailed = false;
    settingsUnreadable = false;
    _snapshot = const RemoteStreamSnapshot();
    _notify();
    unawaited(_load(profileId, generation));
  }

  Future<void> _load(String profileId, int generation) async {
    var recoverablePreparations = <RemotePreparationJob>[];
    try {
      final snapshot = await RemoteStreamStore.load(profileId);
      if (!_current(profileId, generation)) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      recoverablePreparations = snapshot.preparations
          .where(
            (job) =>
                (job.state == RemotePreparationState.preparing ||
                    (job.state == RemotePreparationState.interrupted &&
                        ((job.stage == 'interrupted' && job.errorCode == null) ||
                            (job.stage == 'resume_failed' &&
                                _retryableRecoveryErrors.contains(job.errorCode) &&
                                job.recoveryAttempts < _maxAutomaticRecoveryAttempts)))) &&
                job.providerJobId != null &&
                (job.service == RemoteStreamService.realDebrid ||
                    job.service == RemoteStreamService.allDebrid ||
                    job.service == RemoteStreamService.torbox),
          )
          .toList(growable: false);
      final recovered = snapshot.preparations
          .map(
            (job) => job.state == RemotePreparationState.preparing
                ? job.copyWith(state: RemotePreparationState.interrupted, stage: 'interrupted', updatedAt: now)
                : job,
          )
          .toList(growable: false);
      final restored = snapshot.copyWith(preparations: recovered);
      if (snapshot.preparations.any((job) => job.state == RemotePreparationState.preparing)) {
        try {
          await RemoteStreamStore.save(profileId, restored);
        } on Object {
          // A read-only settings store must not hide valid provider accounts.
        }
      }
      if (!_current(profileId, generation)) return;
      _snapshot = restored;
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
        if (!loadFailed && recoverablePreparations.isNotEmpty) {
          // Reconciliation is app-owned background work: it survives leaving
          // the picker and resumes after process restart, but never stores a
          // signed playback URL or starts a replacement provider job.
          unawaited(_recoverInterruptedPreparations(profileId, generation, recoverablePreparations));
        }
      }
    }
  }

  Future<void> _recoverInterruptedPreparations(
    String profile,
    int generation,
    List<RemotePreparationJob> jobs,
  ) async {
    // A tiny concurrency cap keeps profile startup responsive and limits
    // provider pressure if several preparation requests were interrupted.
    var nextJob = 0;
    Future<void> runWorker() async {
      while (_current(profile, generation) && nextJob < jobs.length) {
        final job = jobs[nextJob++];
        await _recoverWithBackoff(profile, generation, job);
      }
    }

    await Future.wait([runWorker(), runWorker()]);
  }

  Future<void> _recoverWithBackoff(
    String profile,
    int generation,
    RemotePreparationJob job,
  ) async {
    var candidate = job;
    while (_current(profile, generation) && candidate.recoveryAttempts < _maxAutomaticRecoveryAttempts) {
      if (candidate.stage == 'resume_failed') {
        final wait = _recoveryBackoff(candidate.recoveryAttempts) -
            DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(candidate.updatedAt));
        if (wait > Duration.zero) await Future<void>.delayed(wait);
      }
      if (!_current(profile, generation)) return;
      await _recoverInterruptedPreparation(profile, generation, candidate);
      final updated = _snapshot.preparations.where((item) => item.id == candidate.id).firstOrNull;
      if (updated == null ||
          updated.state != RemotePreparationState.interrupted ||
          updated.stage != 'resume_failed' ||
          !_retryableRecoveryErrors.contains(updated.errorCode)) {
        return;
      }
      candidate = updated;
    }
  }

  Duration _recoveryBackoff(int attempts) => Duration(seconds: switch (attempts) {
    <= 0 => 15,
    1 => 30,
    2 => 60,
    _ => 120,
  });

  Future<void> _recoverInterruptedPreparation(
    String profile,
    int generation,
    RemotePreparationJob job,
  ) async {
    if (_shouldCancelPreparation(profile, generation, job.id)) return;
    final saved = _snapshot.preparations.where((candidate) => candidate.id == job.id).firstOrNull;
    if (saved == null || saved.state != RemotePreparationState.interrupted || saved.providerJobId == null) return;
    final account = _snapshot.accounts
        .where((candidate) => candidate.service == saved.service && candidate.id == saved.accountId)
        .firstOrNull;
    if (account == null) return;

    final startedAt = DateTime.now().millisecondsSinceEpoch;
    try {
      await _commit(profile, generation, (current) => current.copyWith(
        preparations: [
          for (final candidate in current.preparations)
            if (candidate.id == saved.id && !_cancelledPreparationIds.contains(saved.id))
              candidate.copyWith(
                state: RemotePreparationState.preparing,
                stage: 'reconnecting',
                updatedAt: startedAt,
                clearErrorCode: true,
              )
            else
              candidate,
        ],
      ));
    } on Object {
      return;
    }
    if (_shouldCancelPreparation(profile, generation, saved.id)) return;

    String lastStage = 'reconnecting';
    Future<void> onProgress({required String stage, String? providerJobId}) async {
      if (_shouldCancelPreparation(profile, generation, saved.id)) {
        throw const RemoteProviderException(RemoteProviderFailure.cancelled);
      }
      final normalized = _journalText(stage, 64, 'preparing');
      if (providerJobId != null &&
          (providerJobId.isEmpty || providerJobId.length > 128 || RegExp(r'[\x00-\x1f\x7f]').hasMatch(providerJobId))) {
        throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
      }
      if (normalized == lastStage && providerJobId == saved.providerJobId) return;
      lastStage = normalized;
      final updatedAt = DateTime.now().millisecondsSinceEpoch;
      await _commit(profile, generation, (current) => current.copyWith(
        preparations: [
          for (final candidate in current.preparations)
            if (candidate.id == saved.id)
              candidate.copyWith(stage: normalized, updatedAt: updatedAt, providerJobId: providerJobId)
            else
              candidate,
        ],
      ));
    }

    try {
      late final ResolvedRemoteStream resolved;
      switch (saved.service) {
        case RemoteStreamService.realDebrid:
          final client = RealDebridClient(
            account: account,
            onAccountRefreshed: (updated) => _persistRefreshedAccount(profile, generation, account.id, updated),
          );
          try {
            resolved = await client.resolveTorrentHash(
              saved.infoHash,
              fileIndex: saved.fileIndex,
              shouldCancel: () => _shouldCancelPreparation(profile, generation, saved.id),
              onProgress: onProgress,
              existingJobId: saved.providerJobId,
            );
          } finally {
            client.close();
          }
          break;
        case RemoteStreamService.allDebrid:
          final client = AllDebridClient(account: account);
          try {
            resolved = await client.resolveTorrentHash(
              saved.infoHash,
              fileIndex: saved.fileIndex,
              shouldCancel: () => _shouldCancelPreparation(profile, generation, saved.id),
              onProgress: onProgress,
              existingJobId: saved.providerJobId,
            );
          } finally {
            client.close();
          }
          break;
        case RemoteStreamService.torbox:
          final client = TorBoxClient(account: account);
          try {
            resolved = await client.resolveTorrentHash(
              saved.infoHash,
              fileIndex: saved.fileIndex,
              shouldCancel: () => _shouldCancelPreparation(profile, generation, saved.id),
              onProgress: onProgress,
              existingJobId: saved.providerJobId,
              allowCreate: false,
            );
          } finally {
            client.close();
          }
          break;
        case RemoteStreamService.premiumize:
          return;
      }
      // Keep only the durable job state. The newly resolved URL is a short-
      // lived bearer capability and must never enter the journal.
      if (resolved.uri.scheme != 'https' || resolved.uri.userInfo.isNotEmpty) {
        throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
      }
      if (_shouldCancelPreparation(profile, generation, saved.id)) {
        throw const RemoteProviderException(RemoteProviderFailure.cancelled);
      }
      final completedAt = DateTime.now().millisecondsSinceEpoch;
      await _commit(profile, generation, (current) => current.copyWith(
        preparations: [
          for (final candidate in current.preparations)
            if (candidate.id == saved.id && !_cancelledPreparationIds.contains(saved.id))
              candidate.copyWith(
                state: RemotePreparationState.ready,
                stage: 'ready',
                updatedAt: completedAt,
                clearErrorCode: true,
              )
            else
              candidate,
        ],
      ));
    } on Object catch (error) {
      if (!_current(profile, generation)) return;
      if (_cancelledPreparationIds.contains(saved.id)) return;
      final failedAt = DateTime.now().millisecondsSinceEpoch;
      final code = error is RemoteProviderException
          ? error.reason.name
          : error is RealDebridException
          ? error.reason.name
          : 'unavailable';
      try {
        await _commit(profile, generation, (current) => current.copyWith(
          preparations: [
            for (final candidate in current.preparations)
              if (candidate.id == saved.id && !_cancelledPreparationIds.contains(saved.id))
                candidate.copyWith(
                  state: RemotePreparationState.interrupted,
                  stage: 'resume_failed',
                  updatedAt: failedAt,
                  errorCode: code,
                  recoveryAttempts: saved.recoveryAttempts + 1,
                )
              else
                candidate,
          ],
        ));
      } on Object {
        // Leave the last durable checkpoint untouched if reconciliation cannot
        // persist its retryable outcome.
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
    final client = _stremioAddonClientFactory();
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
        return current.copyWith(addons: [...current.addons, installed]);
      });
      return installed;
    } finally {
      client.close();
    }
  }

  /// Fetches a fresh manifest without changing the saved installation.
  /// Callers can show the proposed version and ask before applying it.
  Future<StremioAddonUpdateCheck> checkAddonUpdate(String id) async {
    final (profile, generation) = _requireProfile();
    final installed = addons.where((addon) => addon.id == id).firstOrNull;
    if (installed == null) throw const StremioAddonException(StremioAddonFailure.unsupportedResource);
    final client = _stremioAddonClientFactory();
    try {
      final latestManifest = await client.fetchManifest(installed.manifestUrl, allowHttp: installed.allowHttp);
      if (!_current(profile, generation)) {
        throw const StremioAddonException(StremioAddonFailure.unavailable);
      }
      // A manifest URL is a signed endpoint for a particular add-on. A change
      // of identity needs an explicit remove/reinstall action instead of
      // silently replacing the source behind an existing catalog identity.
      if (latestManifest['id'] != installed.manifest['id']) {
        throw const StremioAddonException(StremioAddonFailure.invalidResponse);
      }
      return StremioAddonUpdateCheck(
        installed: installed,
        latestManifest: latestManifest,
        hasChanges: _canonicalManifest(installed.manifest) != _canonicalManifest(latestManifest),
        profileId: profile,
        generation: generation,
      );
    } finally {
      client.close();
    }
  }

  /// Applies only a previously reviewed update, keeping installation ID,
  /// enabled state, endpoint and explicit HTTP opt-in intact.
  Future<void> applyAddonUpdate(StremioAddonUpdateCheck check) async {
    if (!check.hasChanges) return;
    final profile = check.profileId;
    final generation = check.generation;
    if (!_current(profile, generation)) {
      throw const StremioAddonException(StremioAddonFailure.unavailable);
    }
    if (check.latestManifest['id'] != check.installed.manifest['id']) {
      throw const StremioAddonException(StremioAddonFailure.invalidResponse);
    }
    await _commit(profile, generation, (current) {
      final saved = current.addons.where((addon) => addon.id == check.installed.id).firstOrNull;
      if (saved == null ||
          saved.manifestUrl != check.installed.manifestUrl ||
          saved.allowHttp != check.installed.allowHttp ||
          _canonicalManifest(saved.manifest) != _canonicalManifest(check.installed.manifest)) {
        throw const StremioAddonException(StremioAddonFailure.unavailable);
      }
      final replacement = StremioAddonInstallation(
        id: saved.id,
        name: (check.latestManifest['name'] as String).trim(),
        manifestUrl: saved.manifestUrl,
        manifest: check.latestManifest,
        enabled: saved.enabled,
        allowHttp: saved.allowHttp,
      );
      return current.copyWith(
        addons: [
          for (final addon in current.addons)
            if (addon.id == saved.id) replacement else addon,
        ],
      );
    });
  }

  Future<void> setAddonEnabled(String id, bool enabled) async {
    final (profile, generation) = _requireProfile();
    await _commit(profile, generation, (current) {
      final next = current.addons
          .map((addon) => addon.id == id ? addon.copyWith(enabled: enabled) : addon)
          .toList(growable: false);
      return current.copyWith(addons: next);
    });
  }

  Future<void> removeAddon(String id) async {
    final (profile, generation) = _requireProfile();
    await _commit(
      profile,
      generation,
      (current) => current.copyWith(addons: current.addons.where((addon) => addon.id != id).toList(growable: false)),
    );
  }

  Future<void> saveAccount(RemoteStreamAccount account) async {
    final (profile, generation) = _requireProfile();
    await _commit(profile, generation, (current) {
      final next = [...current.accounts.where((saved) => saved.service != account.service), account];
      return current.copyWith(accounts: next);
    });
  }

  Future<void> removeAccount(RemoteStreamService service) async {
    final (profile, generation) = _requireProfile();
    await _commit(
      profile,
      generation,
      (current) => current.copyWith(
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
      return current.copyWith(
        accounts: [
          for (final account in current.accounts)
            if (account.service != updated.service) account,
          updated,
        ],
      );
    });
  }

  Future<ResolvedRemoteStream> resolveTorrent(
    RemoteStreamCandidate candidate, {
    RemoteStreamService? service,
    RemoteStreamRequest? request,
  }) async {
    final hash = candidate.infoHash;
    if (hash == null ||
        !RegExp(r'^[0-9a-fA-F]{40}$').hasMatch(hash) ||
        (candidate.fileIndex != null && (candidate.fileIndex! < 0 || candidate.fileIndex! > 1000000))) {
      throw const RealDebridException(RealDebridFailure.unsupported);
    }
    final profile = _profileId;
    final generation = _generation;
    if (profile == null || loading) throw const RealDebridException(RealDebridFailure.cancelled);
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

    final requestKey = sourceDigest(jsonEncode([profile, account.id, hash.toLowerCase(), candidate.fileIndex]));
    final existing = _activeTorrentPreparations[requestKey];
    if (existing != null) return existing;
    final preparation = _resolveTorrentWithJournal(
      candidate,
      hash: hash,
      selectedService: selectedService,
      account: account,
      profile: profile,
      generation: generation,
      request: request,
    );
    _activeTorrentPreparations[requestKey] = preparation;
    try {
      return await preparation;
    } finally {
      if (identical(_activeTorrentPreparations[requestKey], preparation)) {
        _activeTorrentPreparations.remove(requestKey);
      }
    }
  }

  Future<ResolvedRemoteStream> _resolveTorrentWithJournal(
    RemoteStreamCandidate candidate, {
    required String hash,
    required RemoteStreamService selectedService,
    required RemoteStreamAccount account,
    required String profile,
    required int generation,
    required RemoteStreamRequest? request,
  }) async {
    final previous = _snapshot.preparations
        .where(
          (job) =>
              job.service == selectedService &&
              job.accountId == account.id &&
              job.infoHash.toLowerCase() == hash.toLowerCase() &&
              job.fileIndex == candidate.fileIndex &&
              // Local cancellation leaves the provider-side job intact. A
              // later explicit play request should reconnect to that saved ID
              // instead of creating a duplicate provider transfer.
              job.state != RemotePreparationState.failed &&
              job.providerJobId != null,
        )
        .firstOrNull;
    final now = DateTime.now().millisecondsSinceEpoch;
    final job = RemotePreparationJob(
      id: const Uuid().v4(),
      accountId: account.id,
      service: selectedService,
      infoHash: hash.toLowerCase(),
      title: _journalText(request?.title ?? candidate.label, 512, 'Video'),
      requestId: _journalText(request?.id ?? hash.toLowerCase(), 512, hash.toLowerCase()),
      requestType: _journalText(request?.type ?? 'torrent', 16, 'torrent'),
      addonId: _journalText(candidate.addonId, 128, 'addon'),
      label: _journalText(candidate.label, 512, 'Video'),
      state: RemotePreparationState.preparing,
      stage: 'starting',
      createdAt: now,
      updatedAt: now,
      fileIndex: candidate.fileIndex,
      providerJobId: previous?.providerJobId,
    );
    await _commit(profile, generation, (current) {
      final retained = current.preparations.where((old) => now - old.updatedAt < const Duration(days: 14).inMilliseconds);
      return current.copyWith(preparations: [job, ...retained.take(19)]);
    });

    String? lastStage = 'starting';
    String? lastProviderJobId = job.providerJobId;
    Future<void> onProgress({required String stage, String? providerJobId}) async {
      if (_shouldCancelPreparation(profile, generation, job.id)) {
        throw const RemoteProviderException(RemoteProviderFailure.cancelled);
      }
      final normalized = stage.trim();
      final safeStage = normalized.isEmpty
          ? 'preparing'
          : normalized.substring(0, normalized.length.clamp(0, 64).toInt());
      if (providerJobId != null &&
          (providerJobId.isEmpty || providerJobId.length > 128 || RegExp(r'[\x00-\x1f\x7f]').hasMatch(providerJobId))) {
        throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
      }
      if (safeStage == lastStage && (providerJobId == null || providerJobId == lastProviderJobId)) return;
      lastStage = safeStage;
      if (providerJobId != null) lastProviderJobId = providerJobId;
      final updatedAt = DateTime.now().millisecondsSinceEpoch;
      await _commit(profile, generation, (current) => current.copyWith(
        preparations: [
          for (final old in current.preparations)
            if (old.id == job.id)
              old.copyWith(stage: safeStage, updatedAt: updatedAt, providerJobId: providerJobId)
            else
              old,
        ],
      ));
    }

    try {
      late final ResolvedRemoteStream resolved;
      switch (selectedService) {
        case RemoteStreamService.realDebrid:
          final client = RealDebridClient(
            account: account,
            onAccountRefreshed: (updated) => _persistRefreshedAccount(profile, generation, account.id, updated),
          );
          try {
            resolved = await client.resolveTorrentHash(
              hash,
              fileIndex: candidate.fileIndex,
              shouldCancel: () => _shouldCancelPreparation(profile, generation, job.id),
              onProgress: onProgress,
              existingJobId: job.providerJobId,
            );
          } finally {
            client.close();
          }
          break;
        case RemoteStreamService.allDebrid:
          final client = AllDebridClient(account: account);
          try {
            resolved = await client.resolveTorrentHash(
              hash,
              fileIndex: candidate.fileIndex,
              shouldCancel: () => _shouldCancelPreparation(profile, generation, job.id),
              onProgress: onProgress,
              existingJobId: job.providerJobId,
            );
          } finally {
            client.close();
          }
          break;
        case RemoteStreamService.premiumize:
          final client = PremiumizeClient(account: account);
          try {
            resolved = await client.resolveTorrentHash(
              hash,
              fileIndex: candidate.fileIndex,
              shouldCancel: () => _shouldCancelPreparation(profile, generation, job.id),
              onProgress: onProgress,
            );
          } finally {
            client.close();
          }
          break;
        case RemoteStreamService.torbox:
          final client = TorBoxClient(account: account);
          try {
            resolved = await client.resolveTorrentHash(
              hash,
              fileIndex: candidate.fileIndex,
              shouldCancel: () => _shouldCancelPreparation(profile, generation, job.id),
              onProgress: onProgress,
              existingJobId: job.providerJobId,
            );
          } finally {
            client.close();
          }
          break;
      }
      if (_shouldCancelPreparation(profile, generation, job.id)) {
        throw const RemoteProviderException(RemoteProviderFailure.cancelled);
      }
      final completedAt = DateTime.now().millisecondsSinceEpoch;
      await _commit(profile, generation, (current) => current.copyWith(
        preparations: [
          for (final old in current.preparations)
            if (old.id == job.id && !_cancelledPreparationIds.contains(job.id))
              old.copyWith(state: RemotePreparationState.ready, stage: 'ready', updatedAt: completedAt)
            else
              old,
        ],
      ));
      return resolved;
    } on Object catch (error) {
      if (_current(profile, generation) && !_cancelledPreparationIds.contains(job.id)) {
        final cancelled = (error is RemoteProviderException && error.reason == RemoteProviderFailure.cancelled) ||
            (error is RealDebridException && error.reason == RealDebridFailure.cancelled);
        final failedAt = DateTime.now().millisecondsSinceEpoch;
        final code = error is RemoteProviderException
            ? error.reason.name
            : error is RealDebridException
            ? error.reason.name
            : 'unavailable';
        try {
          await _commit(profile, generation, (current) => current.copyWith(
            preparations: [
              for (final old in current.preparations)
                if (old.id == job.id)
                  old.copyWith(
                    state: cancelled ? RemotePreparationState.cancelled : RemotePreparationState.failed,
                    stage: cancelled ? 'cancelled' : 'failed',
                    updatedAt: failedAt,
                    errorCode: code,
                  )
                else
                  old,
            ],
          ));
        } on Object {
          // Preserve the provider failure even if the profile store is closing.
        }
      }
      rethrow;
    }
  }

  Future<RemoteCloudPage> browseCloud(RemoteStreamService service, {String? parentId, String? cursor}) async {
    final (profile, generation) = _requireProfile();
    final account = accountFor(service);
    if (account == null) throw const RemoteProviderException(RemoteProviderFailure.authentication);
    late RemoteCloudPage page;
    switch (service) {
      case RemoteStreamService.realDebrid:
        final client = RealDebridClient(
          account: account,
          onAccountRefreshed: (updated) => _persistRefreshedAccount(profile, generation, account.id, updated),
        );
        try {
          page = await client.browseCloud(torrentId: parentId, offset: parentId == null ? _parseOffset(cursor) : 0);
        } finally {
          client.close();
        }
        break;
      case RemoteStreamService.allDebrid:
        final client = AllDebridClient(account: account);
        try {
          page = await client.browseCloud(magnetId: parentId);
        } finally {
          client.close();
        }
        break;
      case RemoteStreamService.premiumize:
        final client = PremiumizeClient(account: account);
        try {
          page = await client.browseCloud(folderId: parentId);
        } finally {
          client.close();
        }
        break;
      case RemoteStreamService.torbox:
        final client = TorBoxClient(account: account);
        try {
          page = await client.browseCloud(torrentId: parentId, offset: parentId == null ? _parseOffset(cursor) : 0);
        } finally {
          client.close();
        }
        break;
    }
    if (!_current(profile, generation)) throw const RemoteProviderException(RemoteProviderFailure.cancelled);
    return RemoteCloudPage(
      items: List.unmodifiable(page.items.map((item) => item.withAccountId(account.id, parentProviderId: parentId))),
      nextCursor: page.nextCursor,
    );
  }

  int _parseOffset(String? cursor) {
    final value = cursor == null ? 0 : int.tryParse(cursor);
    if (value == null || value < 0 || value > 1000000000) {
      throw const RemoteProviderException(RemoteProviderFailure.unsupported);
    }
    return value;
  }

  Future<ResolvedRemoteStream> resolveCloudFile(RemoteCloudItem item) async {
    final (profile, generation) = _requireProfile();
    if (item.kind != RemoteCloudItemKind.file) throw const RemoteProviderException(RemoteProviderFailure.unsupported);
    final account = accountFor(item.service);
    if (account == null) throw const RemoteProviderException(RemoteProviderFailure.authentication);
    if (item.accountId != account.id) throw const RemoteProviderException(RemoteProviderFailure.cancelled);
    // Cloud rows and cached source entries deliberately contain no signed
    // links. Re-list the same provider folder each time a lease is requested
    // so an open, resume, or gateway 401/403 retry receives a fresh link for
    // the same provider file rather than reusing an expired URL.
    final currentPage = await browseCloud(item.service, parentId: item.parentProviderId);
    if (!_current(profile, generation)) throw const RemoteProviderException(RemoteProviderFailure.cancelled);
    final currentItem = currentPage.items
        .where(
          (candidate) =>
              candidate.accountId == account.id &&
              candidate.service == item.service &&
              candidate.kind == RemoteCloudItemKind.file &&
              candidate.id == item.id &&
              candidate.providerId == item.providerId &&
              candidate.providerFileId == item.providerFileId,
        )
        .firstOrNull;
    if (currentItem == null ||
        (item.size != null && currentItem.size != null && item.size != currentItem.size)) {
      throw const RemoteProviderException(RemoteProviderFailure.unavailable);
    }
    late final ResolvedRemoteStream resolved;
    switch (item.service) {
      case RemoteStreamService.realDebrid:
        final link = currentItem.uri;
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
        final link = currentItem.uri;
        if (link == null) throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
        final client = AllDebridClient(account: account);
        try {
          resolved = await client.resolveHosterLink(link);
        } finally {
          client.close();
        }
        break;
      case RemoteStreamService.premiumize:
        final link = currentItem.uri;
        if (link == null || link.scheme != 'https' || link.host.isEmpty || link.userInfo.isNotEmpty) {
          throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
        }
        resolved = ResolvedRemoteStream(uri: link, fileName: currentItem.name, size: currentItem.size);
        break;
      case RemoteStreamService.torbox:
        final client = TorBoxClient(account: account);
        try {
          resolved = await client.resolveCloudFile(currentItem);
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
    final results = await Future.wait(
      enabled.map((addon) async {
        final client = StremioAddonClient();
        try {
          return await client.fetchStreams(addon, request).timeout(const Duration(seconds: 22));
        } on Object {
          return null;
        } finally {
          client.close();
        }
      }),
    );
    if (!_current(profile, generation)) return const RemoteStreamSearchResult(candidates: [], failedAddons: 0);
    final candidates = <RemoteStreamCandidate>[];
    for (final result in results) {
      if (result != null) candidates.addAll(result);
    }
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
    final retainedIds = snapshot.preparations.map((job) => job.id).toSet();
    _cancelledPreparationIds.removeWhere((id) => !retainedIds.contains(id));
    _notify();
  });

  Future<T> _serializeMutation<T>(Future<T> Function() operation) {
    final next = _mutationQueue.then((_) => operation());
    _mutationQueue = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  String _canonicalManifest(Map<String, dynamic> manifest) => jsonEncode(_canonicalJson(manifest));

  String _journalText(String value, int maxLength, String fallback) {
    final clean = value.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '').trim();
    if (clean.isEmpty) return fallback;
    return clean.length <= maxLength ? clean : clean.substring(0, maxLength);
  }

  Object? _canonicalJson(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return {for (final key in keys) key: _canonicalJson(value[key])};
    }
    if (value is List) return [for (final item in value) _canonicalJson(item)];
    return value;
  }

  (String, int) _requireProfile() {
    final profile = _profileId;
    if (profile == null || loading) throw StateError('Remote streaming is unavailable for the active profile');
    return (profile, _generation);
  }

  bool _current(String profile, int generation) => !_disposed && _profileId == profile && _generation == generation;

  bool _shouldCancelPreparation(String profile, int generation, String id) {
    if (!_current(profile, generation) || _cancelledPreparationIds.contains(id)) return true;
    return _snapshot.preparations.where((job) => job.id == id).firstOrNull?.state == RemotePreparationState.cancelled;
  }

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
