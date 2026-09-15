import 'dart:async';
import 'dart:io';

import 'package:provider/provider.dart';

import '../connection/connection.dart';
import '../connection/connection_registry.dart';
import '../media/ids.dart';
import '../media/media_filter.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_library.dart';
import '../media/media_server_client.dart';
import '../media/playback_rate.dart';
import '../models/player_setting_scope.dart';
import '../profiles/active_profile_binder.dart';
import '../profiles/active_profile_provider.dart';
import '../profiles/profile_connection_registry.dart';
import '../profiles/profile_registry.dart';
import '../profiles/profile_merge.dart';
import '../providers/catalog_sources_provider.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/libraries_provider.dart';
import '../providers/multi_server_provider.dart';
import '../providers/shader_provider.dart';
import '../screens/libraries/libraries_screen.dart' show visibleLibraryTabs;
import '../screens/libraries/library_browse_grouping.dart';
import '../utils/global_key_utils.dart';
import '../utils/video_player_navigation.dart';
import 'agent_control_protocol.dart';
import 'plex_client.dart';
import 'scoped_player_prefs.dart';
import 'settings_service.dart';
import 'shader_service.dart';
import 'storage_service.dart';

typedef _ApplySetting = Future<Map<String, dynamic>> Function();

class _ScopedSetting {
  const _ScopedSetting(this.descriptor, this.read, this.prepare);
  final Map<String, dynamic> descriptor;
  final Future<Map<String, dynamic>> Function() read;
  final Future<_ApplySetting> Function(Object? value, bool reset) prepare;
  String get key => descriptor['key'] as String;
}

/// Semantic adapters over the existing profile/library/player owners. No caller
/// supplied object is ever used as a persisted preference map or provider DTO.
class AgentScopedSettingsCommands {
  const AgentScopedSettingsCommands();

  Future<Object?> read(String command, Map<String, dynamic> arguments, AgentCommandContext context) async {
    final scope = agentSettingScope(arguments);
    final guard = _ScopedGuard(context, scope);
    final key = command == 'settings.get' ? agentString(arguments, 'key') : null;
    final entries = await _entries(scope, guard, key);
    guard.check();
    if (command == 'settings.list') {
      return {'scope': scope, 'settings': entries.map((e) => e.descriptor).toList()};
    }
    if (command != 'settings.get') {
      throw const AgentControlException('unsupportedCommand', 'Unsupported settings read.');
    }
    final entry = _find(entries, key!);
    final result = await entry.read();
    guard.check();
    return {'key': key, 'scope': scope, 'application': entry.descriptor['application'], ...result};
  }

  Future<AgentSettingMutation> prepare(
    String command,
    Map<String, dynamic> arguments,
    AgentCommandContext context,
  ) async {
    if (command != 'settings.set' && command != 'settings.reset') {
      throw const AgentControlException('unsupportedCommand', 'Unsupported settings mutation.');
    }
    final scope = agentSettingScope(arguments);
    final key = agentString(arguments, 'key');
    final guard = _ScopedGuard(context, scope);
    final entry = _find(await _entries(scope, guard, key), key);
    guard.check();
    final reset = command == 'settings.reset';
    if (!reset && !arguments.containsKey('value')) _invalid('A value is required.');
    final apply = await entry.prepare(arguments['value'], reset);
    guard.check();
    return AgentSettingMutation(
      key: key,
      scope: scope,
      apply: () async {
        guard.check();
        try {
          return {'key': key, 'scope': scope, 'application': entry.descriptor['application'], ...await apply()};
        } on AgentControlException {
          rethrow;
        } catch (_) {
          throw const AgentControlException(
            'settingMutationFailed',
            'The setting could not be persisted or applied.',
            details: {'persistence': 'unconfirmed', 'inMemoryMayHaveChanged': true},
          );
        }
      },
    );
  }

  _ScopedSetting _find(List<_ScopedSetting> entries, String key) =>
      entries.where((e) => e.key == key).firstOrNull ??
      (throw const AgentControlException('unsupportedSetting', 'The setting is not supported in this scope.'));

  Future<List<_ScopedSetting>> _entries(Map<String, dynamic> scope, _ScopedGuard guard, String? key) async {
    switch (scope['type']) {
      case 'player':
        return _playerEntries(scope, guard);
      case 'server':
        final client = guard.server(agentString(scope, 'serverId'));
        return [
          _readOnly(
            'watched_threshold',
            'number',
            'backendOwned',
            () => {'value': client.watchedThreshold * 100, 'ownership': 'server', 'unit': 'percent'},
            'The backend owns this threshold; the local preference is only an offline cache.',
          ),
        ];
      case 'library':
        return _libraryEntries(scope, guard, key);
      case 'profile':
        return _profileEntries(scope, guard);
      case 'catalog':
        return _catalogEntries(guard);
      default:
        throw const AgentControlException('unsupportedScope', 'Unsupported scoped setting target.');
    }
  }

  Future<List<_ScopedSetting>> _playerEntries(Map<String, dynamic> scope, _ScopedGuard guard) async {
    final shaderProvider = guard.context.context.read<ShaderProvider>();
    final settings = await SettingsService.getInstance();
    guard.check();
    if (scope.containsKey('serverId')) guard.server(agentString(scope, 'serverId'));
    MediaItem? item;
    MediaLibrary? library;
    if (scope.containsKey('itemId')) {
      final client = guard.server(agentString(scope, 'serverId'));
      item = await client.fetchItem(agentString(scope, 'itemId'));
      guard.check();
      if (item == null) throw const AgentControlException('itemUnavailable', 'The requested item is unavailable.');
      if (item.serverId != client.serverId.value) {
        throw const AgentControlException('itemUnavailable', 'The item does not belong to the requested server.');
      }
      if (!const {MediaKind.movie, MediaKind.show, MediaKind.episode, MediaKind.clip}.contains(item.kind)) {
        throw const AgentControlException(
          'unsupportedTarget',
          'Scoped player preferences require a video title or series.',
        );
      }
    }
    if (scope.containsKey('libraryId')) library = guard.library(scope);
    if (library != null && item != null && item.libraryId != library.id) {
      throw const AgentControlException('invalidScope', 'The item does not belong to the requested library.');
    }
    final explicit = scope['persistence'];
    final persistence = explicit == null ? null : PlayerSettingScope.values.asNameMap()[explicit];
    if (explicit != null && persistence == null) _invalid('persistence must be off, global, library, or title.');
    final entries = <_ScopedSetting>[
      _playerValue(
        ScopedPlayerPrefs.playbackSpeed,
        settings,
        guard,
        item,
        library,
        persistence,
        type: 'number',
        defaultValue: SettingsService.defaultPlaybackSpeed.defaultValue,
        constraints: {'minimum': minimumPlaybackRate, 'maximum': maximumPlaybackRate},
        decode: (v) {
          if (v is! num || !v.isFinite || v < minimumPlaybackRate || v > maximumPlaybackRate) {
            _invalid('Playback speed is outside the supported range.');
          }
          return (v).toDouble();
        },
      ),
      _playerValue(
        ScopedPlayerPrefs.shaderPreset,
        settings,
        guard,
        item,
        library,
        persistence,
        type: 'string',
        defaultValue: SettingsService.globalShaderPreset.defaultValue,
        choices: shaderProvider.allPresets.map((p) => p.id).toList(),
        isSupported: () =>
            ShaderService.isPlatformSupported && !(Platform.isAndroid && settings.read(SettingsService.useExoPlayer)),
        decode: (v) {
          if (v is! String || shaderProvider.findPresetById(v) == null) _invalid('Select an available shader preset.');
          return v;
        },
      ),
      _playerValue(
        ScopedPlayerPrefs.boxFitMode,
        settings,
        guard,
        item,
        library,
        persistence,
        type: 'integer',
        defaultValue: SettingsService.defaultBoxFitMode.defaultValue,
        choices: const [0, 1, 2],
        decode: (v) => _integer(v, min: 0, max: 2),
      ),
      _playerValue(
        ScopedPlayerPrefs.audioSyncOffset,
        settings,
        guard,
        item,
        library,
        persistence,
        type: 'integer',
        defaultValue: SettingsService.audioSyncOffset.defaultValue,
        constraints: const {
          'unit': 'milliseconds',
          'minimum': ScopedPlayerPrefs.minimumSyncOffsetMs,
          'maximum': ScopedPlayerPrefs.maximumSyncOffsetMs,
        },
        decode: (v) =>
            _integer(v, min: ScopedPlayerPrefs.minimumSyncOffsetMs, max: ScopedPlayerPrefs.maximumSyncOffsetMs),
      ),
      _playerValue(
        ScopedPlayerPrefs.subtitleSyncOffset,
        settings,
        guard,
        item,
        library,
        persistence,
        type: 'integer',
        defaultValue: SettingsService.subtitleSyncOffset.defaultValue,
        constraints: const {
          'unit': 'milliseconds',
          'minimum': ScopedPlayerPrefs.minimumSyncOffsetMs,
          'maximum': ScopedPlayerPrefs.maximumSyncOffsetMs,
        },
        decode: (v) =>
            _integer(v, min: ScopedPlayerPrefs.minimumSyncOffsetMs, max: ScopedPlayerPrefs.maximumSyncOffsetMs),
      ),
    ];
    for (final pref in [
      SettingsService.playbackSpeedScope,
      SettingsService.shaderPresetScope,
      SettingsService.boxFitScope,
      SettingsService.syncOffsetScope,
    ]) {
      entries.add(
        _valueEntry(
          guard,
          pref.key,
          'string',
          'nextPlayback',
          defaultValue: pref.resolvedDefault.name,
          choices: PlayerSettingScope.values.map((e) => e.name).toList(),
          extra: const {'storageOwnership': 'sharedAcrossProfiles'},
          read: () => {'value': settings.read(pref).name},
          normalize: (v) {
            if (v is! String || !PlayerSettingScope.values.asNameMap().containsKey(v)) {
              _invalid('Invalid player persistence scope.');
            }
            return PlayerSettingScope.values.asNameMap()[v]!;
          },
          write: (v, reset) async {
            if (reset) {
              await settings.reset(pref, checkCurrent: guard.check);
            } else {
              await settings.write(pref, v as PlayerSettingScope, checkCurrent: guard.check);
            }
          },
        ),
      );
    }
    if (item == null) {
      entries.add(
        _readOnly(
          'media_version',
          'object',
          'nextPlayback',
          () => throw const AgentControlException('invalidScope', 'An explicit serverId and itemId are required.'),
          'An explicit serverId and itemId are required.',
          code: 'invalidScope',
          extra: const {
            'requiredScopeFields': ['serverId', 'itemId'],
          },
        ),
      );
    } else {
      final target = item;
      final versions = target.mediaVersions ?? const [];
      Future<Map<String, dynamic>> readVersion() async {
        final saved = await savedMediaVersionPreferenceFor(target);
        guard.check();
        final index = saved?.resolveIndex(versions);
        return {
          'value': saved == null
              ? null
              : {'versionId': saved.versionId, 'signature': saved.signature, 'index': saved.index},
          'resolvedValue': index == null ? null : {'versionId': versions[index].id, 'index': index},
          'storageOwnership': 'sharedAcrossProfiles',
        };
      }

      entries.add(
        _ScopedSetting(
          {
            'key': 'media_version',
            'type': 'object',
            'default': null,
            'application': 'nextPlayback',
            'applicability': {'supported': versions.isNotEmpty},
            'choices': [
              for (var i = 0; i < versions.length; i++) {'versionId': versions[i].id, 'index': i},
            ],
            'storageOwnership': 'sharedAcrossProfiles',
            'precedence': 'seriesOrStandaloneItem',
          },
          readVersion,
          (value, reset) async {
            int? index;
            if (!reset) {
              final object = agentObject(value, 'value');
              _only(object, const {'versionId'});
              final id = agentString(object, 'versionId');
              index = versions.indexWhere((v) => v.id == id);
              if (index < 0) _invalid('The version is not available on this item.');
            }
            return () async {
              guard.check();
              if (reset) {
                await resetSavedMediaVersionPreferenceFor(target, checkCurrent: guard.check);
              } else {
                await saveMediaVersionPreferenceFor(
                  target,
                  index: index!,
                  versions: versions,
                  checkCurrent: guard.check,
                );
              }
              guard.check();
              return {'persisted': true, ...await readVersion()};
            };
          },
        ),
      );
    }
    return entries;
  }

  _ScopedSetting _playerValue<T>(
    ScopedPlayerPref<T> pref,
    SettingsService settings,
    _ScopedGuard guard,
    MediaItem? item,
    MediaLibrary? library,
    PlayerSettingScope? explicit, {
    required String type,
    required Object? defaultValue,
    required T Function(Object?) decode,
    Map<String, dynamic>? constraints,
    List<Object?>? choices,
    bool Function()? isSupported,
  }) {
    final supported = isSupported?.call() ?? true;
    final selected = explicit ?? settings.read<PlayerSettingScope>(pref.scope);
    final hasIdentity = selected != PlayerSettingScope.title || item != null;
    final hasLibrary = selected != PlayerSettingScope.library || library != null || item?.libraryGlobalKey != null;
    final hasTarget = hasIdentity && hasLibrary && selected != PlayerSettingScope.off;
    final writable = supported && hasTarget;
    Map<String, dynamic> values() {
      final configured = settings.read(pref.scope);
      T? override;
      if (hasIdentity && hasLibrary) override = ScopedPlayerPrefs.overrideAt(pref, selected, item, library: library);
      T resolved = settings.read(pref.global);
      if (configured == PlayerSettingScope.library && library != null) {
        resolved = ScopedPlayerPrefs.overrideAt(pref, configured, item, library: library) ?? resolved;
      } else if (item != null) {
        resolved = ScopedPlayerPrefs.resolve(pref, item);
      }
      return {
        'value': override ?? settings.read(pref.global),
        'storedOverride': override,
        'resolvedValue': resolved,
        'configuredPersistence': configured.name,
        'persistence': selected.name,
        'storageOwnership': 'sharedAcrossProfiles',
        'runningPlayerApplied': false,
      };
    }

    return _ScopedSetting(
      {
        'key': pref.id,
        'type': type,
        'default': defaultValue,
        'application': 'nextPlayback',
        'applicability': {
          'supported': writable,
          if (!writable)
            'reason': !supported
                ? 'The selected player engine does not support this setting.'
                : 'This persistence level requires an item/library identity or has persistence disabled.',
        },
        'resetSupported': hasTarget,
        'constraints': ?constraints,
        'choices': ?choices,
        'configuredPersistence': settings.read(pref.scope).name,
        'persistence': selected.name,
        'storageOwnership': 'sharedAcrossProfiles',
        'precedence': 'configuredOverrideThenGlobal',
      },
      () async => values(),
      (value, reset) async {
        if (!hasTarget) {
          throw const AgentControlException('invalidScope', 'The selected persistence level has no writable target.');
        }
        if (!reset && !supported) {
          throw const AgentControlException(
            'unsupportedSetting',
            'The selected player engine or platform does not support this setting.',
          );
        }
        final normalized = reset ? null : decode(value);
        return () async {
          guard.check();
          if (!reset && !(isSupported?.call() ?? true)) {
            throw const AgentControlException(
              'unsupportedSetting',
              'The selected player engine no longer supports this setting.',
            );
          }
          if (!reset) decode(normalized);
          if (reset) {
            await ScopedPlayerPrefs.resetAt(pref, selected, item, library: library, checkCurrent: guard.check);
          } else {
            await ScopedPlayerPrefs.writeAt(
              pref,
              selected,
              item,
              normalized as T,
              library: library,
              checkCurrent: guard.check,
            );
          }
          guard.check();
          return {'persisted': true, ...values()};
        };
      },
    );
  }

  Future<List<_ScopedSetting>> _libraryEntries(
    Map<String, dynamic> scope,
    _ScopedGuard guard,
    String? requested,
  ) async {
    final libraries = guard.context.context.read<LibrariesProvider>();
    final hidden = guard.context.context.read<HiddenLibrariesProvider>();
    final storage = await StorageService.getInstance();
    guard.check();
    await hidden.ensureInitialized();
    guard.check();
    if (hidden.profileId != null && hidden.profileId != guard.profileId) {
      throw const AgentControlException('sessionChanged', 'The library profile changed.');
    }
    final entries = <_ScopedSetting>[];
    // Ordering/selection are profile-wide resources, expressed as identity pairs.
    if (!scope.containsKey('libraryId')) {
      List<MediaLibrary> visible() => libraries.libraries
          .where(
            (l) =>
                l.serverId != null &&
                guard.isVisible(l.serverId!) &&
                (scope['serverId'] == null || scope['serverId'] == l.serverId),
          )
          .toList();
      if (scope.containsKey('serverId')) guard.server(agentString(scope, 'serverId'));
      Map<String, dynamic> identity(MediaLibrary l) => {'serverId': l.serverId, 'libraryId': l.id};
      entries.add(
        _valueEntry(
          guard,
          'order',
          'array',
          'immediate',
          defaultValue: null,
          constraints: {
            'items': 'Unique visible {serverId,libraryId} pairs; unspecified libraries retain their order.',
          },
          resetApplication: 'nextLibraryLoad',
          read: () {
            final available = {for (final l in visible()) l.globalKey: l};
            final saved = storage.getLibraryOrder();
            return {
              'value': saved == null
                  ? null
                  : [
                      for (final key in saved)
                        if (available[key] != null) identity(available[key]!),
                    ],
              'resolvedValue': visible().map(identity).toList(),
            };
          },
          normalize: (v) {
            if (v is! List) _invalid('Library order must be an array.');
            final result = <MediaLibrary>[];
            final keys = <String>{};
            for (final raw in v) {
              _only(agentObject(raw, 'library'), const {'serverId', 'libraryId'});
              final target = guard.library(agentObject(raw, 'library'));
              if (!visible().any((l) => l.globalKey == target.globalKey) || !keys.add(target.globalKey)) {
                _invalid('Library order contains an unavailable or duplicate target.');
              }
              result.add(target);
            }
            return result;
          },
          write: (v, reset) async {
            if (reset) {
              if (scope.containsKey('serverId')) {
                throw const AgentControlException(
                  'unsupportedReset',
                  'Reset library order in the profile-wide library scope.',
                );
              }
              await storage.clearLibraryOrder(profileId: guard.profileId, checkCurrent: guard.check);
            } else {
              final requested = v as List<MediaLibrary>;
              final current = libraries.libraries;
              final byKey = {for (final l in current) l.globalKey: l};
              if (requested.any((l) => !byKey.containsKey(l.globalKey))) {
                throw const AgentControlException(
                  'libraryUnavailable',
                  'A library disappeared before the order was saved.',
                );
              }
              final selected = requested.map((l) => l.globalKey).toSet();
              final ordered = [
                ...requested.map((l) => byKey[l.globalKey]!),
                ...current.where((l) => !selected.contains(l.globalKey)),
              ];
              await libraries.updateLibraryOrder(ordered, profileId: guard.profileId, checkCurrent: guard.check);
            }
          },
          resetSupported: !scope.containsKey('serverId'),
        ),
      );
      entries.add(
        _valueEntry(
          guard,
          'selection',
          'object',
          'nextLibraryOpen',
          defaultValue: null,
          choices: visible().map(identity).toList(),
          read: () {
            final selected = storage.getSelectedLibraryKey();
            final target = visible().where((l) => l.globalKey == selected).firstOrNull;
            return {'value': target == null ? null : identity(target)};
          },
          normalize: (v) {
            _only(agentObject(v, 'value'), const {'serverId', 'libraryId'});
            final target = guard.library(agentObject(v, 'value'));
            if (hidden.hiddenLibraryKeys.contains(target.globalKey) ||
                !visible().any((l) => l.globalKey == target.globalKey)) {
              _invalid('The selected library is hidden or outside this scope.');
            }
            return target;
          },
          write: (v, reset) async {
            if (reset) {
              await storage.clearSelectedLibraryKey(profileId: guard.profileId, checkCurrent: guard.check);
            } else {
              final target = v as MediaLibrary;
              if (hidden.hiddenLibraryKeys.contains(target.globalKey) ||
                  !visible().any((l) => l.globalKey == target.globalKey)) {
                throw const AgentControlException('libraryUnavailable', 'The selected library is no longer visible.');
              }
              await storage.saveSelectedLibraryKey(target.globalKey, profileId: guard.profileId);
            }
          },
        ),
      );
      for (final entry in const {
        'hidden': 'boolean',
        'grouping': 'string',
        'tab': 'string',
        'sort': 'object',
        'filters': 'array',
      }.entries) {
        entries.add(
          _readOnly(
            entry.key,
            entry.value,
            entry.key == 'hidden' ? 'immediate' : 'nextLibraryOpen',
            () => throw const AgentControlException('invalidScope', 'An explicit serverId and libraryId are required.'),
            'An explicit serverId and libraryId are required.',
            code: 'invalidScope',
            extra: const {
              'requiredScopeFields': ['serverId', 'libraryId'],
            },
          ),
        );
      }
      return entries;
    }
    final library = guard.library(scope);
    final client = guard.server(library.serverId!);
    final globalKey = library.globalKey;
    final folders = !library.isShared && client.capabilities.folderGrouping;
    final groupingOptions = libraryBrowseGroupingOptions(library, canGroupByFolders: folders);
    final defaultGrouping = defaultLibraryBrowseGrouping(library, canGroupByFolders: folders);
    entries.add(
      _valueEntry(
        guard,
        'hidden',
        'boolean',
        'immediate',
        defaultValue: false,
        read: () => {'value': hidden.hiddenLibraryKeys.contains(globalKey)},
        normalize: _boolean,
        write: (v, reset) => hidden.setLibraryHidden(globalKey, reset ? false : v as bool, checkCurrent: guard.check),
      ),
    );
    entries.add(
      _valueEntry(
        guard,
        'grouping',
        'string',
        'nextLibraryOpen',
        defaultValue: defaultGrouping,
        choices: groupingOptions,
        read: () => {
          'value': normalizeLibraryBrowseGrouping(
            library,
            storage.getLibraryGrouping(globalKey),
            canGroupByFolders: folders,
          ),
          'storedOverride': storage.getLibraryPreferenceOverride(
            globalKey,
            LibraryPreference.grouping,
            profileId: guard.profileId,
          ),
        },
        normalize: (v) => _choice(v, groupingOptions),
        write: (v, reset) => reset
            ? storage.resetLibraryPreference(
                globalKey,
                LibraryPreference.grouping,
                profileId: guard.profileId,
                checkCurrent: guard.check,
              )
            : storage.saveLibraryGrouping(globalKey, v as String, profileId: guard.profileId),
      ),
    );
    final tabs = visibleLibraryTabs(library).map((t) => t.name).toList();
    entries.add(
      _valueEntry(
        guard,
        'tab',
        'string',
        'nextLibraryOpen',
        defaultValue: tabs.first,
        choices: tabs,
        read: () => {
          'value': storage.getLibraryTab(globalKey) ?? tabs.first,
          'storedOverride': storage.getLibraryPreferenceOverride(
            globalKey,
            LibraryPreference.tab,
            profileId: guard.profileId,
          ),
        },
        normalize: (v) => _choice(v, tabs),
        write: (v, reset) => reset
            ? storage.resetLibraryPreference(
                globalKey,
                LibraryPreference.tab,
                profileId: guard.profileId,
                checkCurrent: guard.check,
              )
            : storage.saveLibraryTab(globalKey, v as String, profileId: guard.profileId),
      ),
    );
    if (requested == null || requested == 'sort') {
      final grouping = normalizeLibraryBrowseGrouping(
        library,
        storage.getLibraryGrouping(globalKey),
        canGroupByFolders: folders,
      );
      final sorts = await client.fetchSortOptions(
        library.id,
        libraryType: switch (grouping) {
          browseGroupingAlbums => MediaKind.album.id,
          browseGroupingTracks => MediaKind.track.id,
          _ => library.kind.id,
        },
      );
      guard.check();
      entries.add(
        _valueEntry(
          guard,
          'sort',
          'object',
          'nextLibraryOpen',
          defaultValue: null,
          choices: sorts.map((s) => {'sortId': s.key}).toList(),
          read: () {
            final saved = storage.getLibrarySort(globalKey);
            return {
              'value': saved == null ? null : {'sortId': saved['key'], 'descending': saved['descending'] ?? false},
            };
          },
          normalize: (v) {
            final value = agentObject(v, 'value');
            _only(value, const {'sortId', 'descending'});
            final sortId = agentString(value, 'sortId');
            if (!sorts.any((s) => s.key == sortId)) _invalid('The sort is unavailable for this library grouping.');
            return {
              'sortId': sortId,
              'descending': value.containsKey('descending') ? _boolean(value['descending']) : false,
            };
          },
          write: (v, reset) async {
            if (reset) {
              await storage.resetLibraryPreference(
                globalKey,
                LibraryPreference.sort,
                profileId: guard.profileId,
                checkCurrent: guard.check,
              );
            } else {
              final currentGrouping = normalizeLibraryBrowseGrouping(
                library,
                storage.getLibraryGrouping(globalKey),
                canGroupByFolders: folders,
              );
              if (currentGrouping != grouping) {
                throw const AgentControlException(
                  'settingChanged',
                  'The library grouping changed; discover its sort options again.',
                );
              }
              final value = v as Map<String, dynamic>;
              await storage.saveLibrarySort(
                globalKey,
                value['sortId'] as String,
                descending: value['descending'] as bool,
                profileId: guard.profileId,
              );
            }
          },
        ),
      );
    }
    if (requested == null || requested == 'filters') {
      final result = await client.fetchLibraryFiltersWithValues(library.id, libraryKind: library.kind);
      guard.check();
      final choices = <String, List<String>>{};
      for (final filter in result.filters) {
        if (filter.filterType == 'boolean') {
          choices[filter.filter] = const ['1'];
        } else {
          final values =
              result.cachedValues[filter.filter] ??
              (client is PlexClient ? await client.getFilterValues(filter.key) : const <MediaFilterValue>[]);
          guard.check();
          choices[filter.filter] = values.map((v) => libraryFilterValueId(v.key, filter.filter)).toList();
        }
      }
      List<Map<String, dynamic>> domain(Map<String, String> values) => [
        for (final entry in values.entries) {'filterId': entry.key, 'valueId': entry.value},
      ];
      entries.add(
        _valueEntry(
          guard,
          'filters',
          'array',
          'nextLibraryOpen',
          defaultValue: const [],
          choices: [
            for (final filter in result.filters) {'filterId': filter.filter, 'valueIds': choices[filter.filter]},
          ],
          read: () {
            final resolved = domain(storage.getLibraryFilters(sectionId: globalKey));
            final stored = storage.getLibraryPreferenceOverride(
              globalKey,
              LibraryPreference.filters,
              profileId: guard.profileId,
            );
            final override = stored is Map
                ? domain({for (final entry in stored.entries) entry.key.toString(): entry.value.toString()})
                : null;
            return {'value': resolved, 'storedOverride': override, 'resolvedValue': resolved};
          },
          normalize: (v) {
            if (v is! List || v.length > result.filters.length) {
              _invalid('Filters must be a bounded array of filter/value pairs.');
            }
            final selected = <String, String>{};
            for (final raw in v) {
              final value = agentObject(raw, 'filter');
              _only(value, const {'filterId', 'valueId'});
              final id = agentString(value, 'filterId');
              final valueId = agentString(value, 'valueId');
              if (selected.containsKey(id) || !(choices[id]?.contains(valueId) ?? false)) {
                _invalid('An unavailable or duplicate filter was selected.');
              }
              selected[id] = valueId;
            }
            return selected;
          },
          write: (v, reset) => reset
              ? storage.resetLibraryPreference(
                  globalKey,
                  LibraryPreference.filters,
                  profileId: guard.profileId,
                  checkCurrent: guard.check,
                )
              : storage.saveLibraryFilters(v as Map<String, String>, sectionId: globalKey, profileId: guard.profileId),
        ),
      );
    }
    return entries;
  }

  List<_ScopedSetting> _catalogEntries(_ScopedGuard guard) {
    final provider = guard.context.context.read<CatalogSourcesProvider>();
    return [
      _valueEntry(
        guard,
        'active_source',
        'string',
        'immediate',
        defaultValue: null,
        choices: provider.connectedSources.map((s) => s.id.name).toList(),
        read: () => {'value': provider.activeSource?.id.name, 'storedOverride': provider.preferredSourceId?.name},
        normalize: (v) {
          if (v is! String) _invalid('A connected catalog source id is required.');
          final source = provider.connectedSources.where((s) => s.id.name == v).firstOrNull;
          if (source == null) {
            throw const AgentControlException(
              'sourceUnavailable',
              'The catalog source is not connected to this profile.',
            );
          }
          return source;
        },
        write: (v, reset) async {
          if (reset) {
            await provider.setActiveSource(null, checkCurrent: guard.check);
          } else {
            if (!provider.connectedSources.any((s) => identical(s, v))) {
              throw const AgentControlException('sessionChanged', 'The catalog source binding changed.');
            }
            final id = provider.connectedSources.firstWhere((s) => identical(s, v)).id;
            await provider.setActiveSource(id, checkCurrent: guard.check);
          }
        },
      ),
    ];
  }

  Future<List<_ScopedSetting>> _profileEntries(Map<String, dynamic> scope, _ScopedGuard guard) async {
    final active = guard.active;
    final profile = active.active!;
    final registry = guard.context.context.read<ProfileRegistry>();
    final links = guard.context.context.read<ProfileConnectionRegistry>();
    final connections = guard.context.context.read<ConnectionRegistry>();
    final binder = guard.context.context.read<ActiveProfileBinder>();
    final rows = visibleProfileConnections(profile, await links.listForProfile(guard.profileId));
    guard.check();
    final entries = <_ScopedSetting>[
      if (profile.isLocal)
        _valueEntry(
          guard,
          'name',
          'string',
          'immediate',
          defaultValue: null,
          resetSupported: false,
          constraints: const {'nonEmpty': true, 'trim': true},
          read: () async => {
            'value': (await registry.list()).where((p) => p.id == guard.profileId).firstOrNull?.displayName,
          },
          normalize: (v) {
            if (v is! String || v.trim().isEmpty) _invalid('A nonempty profile name is required.');
            return (v).trim();
          },
          write: (v, reset) => registry.rename(guard.profileId, v as String, checkCurrent: guard.check),
        )
      else
        _readOnly(
          'name',
          'string',
          'backendOwned',
          () => {'value': profile.displayName},
          'Plex owns this profile name.',
        ),
      _valueEntry(
        guard,
        'default_connection',
        'string',
        'nextProfileBinding',
        defaultValue: null,
        resetSupported: false,
        choices: rows.map((r) => r.connectionId).toList(),
        read: () async => {
          'value': (await links.listForProfile(guard.profileId)).where((r) => r.isDefault).firstOrNull?.connectionId,
        },
        normalize: (v) {
          if (v is! String || !rows.any((r) => r.connectionId == v)) {
            _invalid('The connection is not assigned to the active profile.');
          }
          return v;
        },
        write: (v, reset) => links.setDefault(guard.profileId, v as String, checkCurrent: guard.check),
      ),
    ];
    if (!scope.containsKey('connectionId')) {
      entries.add(
        _readOnly(
          'endpoints',
          'array',
          'profileRebind',
          () => throw const AgentControlException('invalidScope', 'An explicit MediaBrowser connectionId is required.'),
          'An explicit MediaBrowser connectionId is required.',
          code: 'invalidScope',
          extra: {
            'requiredScopeFields': const ['connectionId'],
            'connectionIds': [
              for (final row in rows)
                if (active.connectionsById[row.connectionId] is JellyfinConnection) row.connectionId,
            ],
          },
        ),
      );
      return entries;
    }
    final connectionId = agentString(scope, 'connectionId');
    if (!rows.any((r) => r.connectionId == connectionId)) {
      throw const AgentControlException(
        'connectionUnavailable',
        'The connection is not assigned to the active profile.',
      );
    }
    final connection = await connections.get(connectionId);
    guard.check();
    if (connection is! JellyfinConnection) {
      entries.add(
        _readOnly(
          'endpoints',
          'array',
          'backendOwned',
          () => {'value': null},
          'Only MediaBrowser endpoint lists are editable.',
        ),
      );
      return entries;
    }
    guard.server(connection.serverMachineId);
    entries.add(
      _ScopedSetting(
        {
          'key': 'endpoints',
          'type': 'array',
          'default': null,
          'application': 'profileRebind',
          'applicability': const {'supported': true},
          'resetSupported': false,
          'constraints': const {
            'minItems': 1,
            'maxItems': 16,
            'items': 'HTTP(S) base URL without credentials, query, or fragment',
          },
          'storageOwnership': 'connectionSharedByLinkedProfiles',
          'explicitReadRequired': true,
        },
        () async {
          final current = await connections.get(connectionId);
          guard.check();
          if (current is! JellyfinConnection) {
            throw const AgentControlException('connectionUnavailable', 'The connection is unavailable.');
          }
          return {'value': current.baseUrls.map(_safeEndpoint).toList()};
        },
        (value, reset) async {
          if (reset) {
            throw const AgentControlException(
              'unsupportedReset',
              'An endpoint list has no default and cannot be cleared.',
            );
          }
          if (value is! List || value.isEmpty || value.length > 16) {
            _invalid('Endpoints must contain between one and sixteen URLs.');
          }
          final urls = <String>[];
          for (final raw in value) {
            if (raw is! String) _invalid('Every endpoint must be a URL string.');
            final uri = Uri.tryParse((raw).trim());
            if (uri == null ||
                !const ['http', 'https'].contains(uri.scheme) ||
                uri.host.isEmpty ||
                uri.userInfo.isNotEmpty ||
                uri.hasQuery ||
                uri.hasFragment) {
              _invalid('Endpoints must be credential-free HTTP(S) base URLs.');
            }
            urls.add(uri.toString());
          }
          JellyfinConnection updated;
          try {
            updated = await connections.prepareMediaBrowserEndpoints(connection, urls);
          } catch (_) {
            guard.check();
            throw const AgentControlException(
              'endpointValidationFailed',
              'The endpoint list could not be verified for this server.',
            );
          }
          guard.check();
          return () async {
            final current = await connections.get(connectionId);
            guard.check();
            if (current == null || !connections.hasSameConfig(current, connection)) {
              throw const AgentControlException('settingChanged', 'The connection changed after validation.');
            }
            await connections.upsert(updated, expected: connection, checkCurrent: guard.check);
            guard.checkProfileIdentity();
            // This is the existing edit-screen rebind path. It deliberately changes
            // the captured session; do not reinterpret its own invalidation as an
            // unsaved write or attempt any further commits through the old context.
            try {
              await binder.rebindIfActive(guard.profileId);
            } catch (_) {
              throw const AgentControlException(
                'settingEffectFailed',
                'Endpoints were saved, but profile rebinding failed.',
                details: {'persisted': true, 'application': 'profileRebind'},
              );
            }
            return {
              'value': updated.baseUrls.map(_safeEndpoint).toList(),
              'persisted': true,
              'bindingSucceeded': active.activeId == guard.profileId && active.lastBindingSucceeded,
            };
          };
        },
      ),
    );
    return entries;
  }

  _ScopedSetting _valueEntry(
    _ScopedGuard guard,
    String key,
    String type,
    String application, {
    required Object? defaultValue,
    List<Object?>? choices,
    Map<String, dynamic>? constraints,
    Map<String, dynamic>? extra,
    bool resetSupported = true,
    String? resetApplication,
    required FutureOr<Map<String, dynamic>> Function() read,
    required Object? Function(Object?) normalize,
    required Future<void> Function(Object? value, bool reset) write,
  }) => _ScopedSetting(
    {
      'key': key,
      'type': type,
      'default': defaultValue,
      'application': application,
      'applicability': const {'supported': true},
      'resetSupported': resetSupported,
      'choices': ?choices,
      'constraints': ?constraints,
      ...?extra,
    },
    () async => await read(),
    (value, reset) async {
      if (reset && !resetSupported) {
        throw const AgentControlException('unsupportedReset', 'This setting has no reset-to-default operation.');
      }
      final normalized = reset ? null : normalize(value);
      return () async {
        guard.check();
        await write(normalized, reset);
        guard.check();
        final result = await read();
        guard.check();
        return {'persisted': true, if (reset && resetApplication != null) 'application': resetApplication, ...result};
      };
    },
  );

  _ScopedSetting _readOnly(
    String key,
    String type,
    String application,
    Map<String, dynamic> Function() read,
    String reason, {
    String code = 'unsupportedSetting',
    Map<String, dynamic>? extra,
  }) => _ScopedSetting(
    {
      'key': key,
      'type': type,
      'default': null,
      'application': application,
      'applicability': {'supported': false, 'reason': reason},
      'readOnly': true,
      ...?extra,
    },
    () async => read(),
    (_, _) async => throw AgentControlException(code, reason),
  );
}

/// The active profile and its committed authentication identity are authority;
/// manager client presence alone is not. Main additionally fences binding/route
/// generations, including a same-profile rebind that completes between awaits.
class _ScopedGuard {
  _ScopedGuard(this.context, Map<String, dynamic> scope)
    : active = context.context.read<ActiveProfileProvider>(),
      multi = context.context.read<MultiServerProvider>() {
    final fields = switch (scope['type']) {
      'player' => const {'type', 'profileId', 'serverId', 'itemId', 'libraryId', 'persistence'},
      'server' => const {'type', 'profileId', 'serverId'},
      'library' => const {'type', 'profileId', 'serverId', 'libraryId'},
      'profile' => const {'type', 'profileId', 'connectionId'},
      'catalog' => const {'type', 'profileId'},
      _ => throw const AgentControlException('unsupportedScope', 'Unsupported scoped setting target.'),
    };
    _only(scope, fields);
    context.checkCurrent(requireProfile: true);
    profileId =
        active.activeId ?? (throw const AgentControlException('noActiveSession', 'An active profile is required.'));
    identity = active.identityMutationGeneration;
    committedIdentity = active.committedIdentityGeneration;
    if (scope['profileId'] != null && scope['profileId'] != profileId) {
      throw const AgentControlException('invalidScope', 'Only the active profile may be targeted.');
    }
    _profileLinks = {
      for (final row in active.connectionsByProfile[profileId] ?? const []) row.connectionId: row.userIdentifier,
    };
    final connectionIds = {..._profileLinks.keys, if (active.active?.parentConnectionId case final String id) id};
    _connections = {
      for (final id in connectionIds)
        if (active.connectionsById[id] != null) id: active.connectionsById[id]!,
    };
    check();
  }
  final AgentCommandContext context;
  final ActiveProfileProvider active;
  final MultiServerProvider multi;
  late final String profileId;
  late final int identity;
  late final int committedIdentity;
  final Map<String, ({MediaServerClient client, Object authentication})> _clients = {};
  final Map<String, MediaLibrary> _libraries = {};
  late final Map<String, String> _profileLinks;
  late final Map<String, Connection> _connections;

  bool isVisible(String id) =>
      multi.hasExplicitVisibleServerFilter &&
      multi.serverIds.contains(id) &&
      multi.expectedServerIds.contains(id) &&
      !multi.authErrorServerIds.contains(id);

  void checkProfileIdentity() {
    context.checkCurrent(requireProfile: true);
    if (active.activeId != profileId ||
        active.identityMutationGeneration != identity ||
        active.committedIdentityGeneration != committedIdentity ||
        active.isBinding ||
        !active.lastBindingSucceeded) {
      throw const AgentControlException('sessionChanged', 'The active profile binding changed or is not ready.');
    }
  }

  void check() {
    checkProfileIdentity();
    final links = active.connectionsByProfile[profileId] ?? const [];
    if (links.length != _profileLinks.length ||
        links.any((row) => _profileLinks[row.connectionId] != row.userIdentifier)) {
      throw const AgentControlException('sessionChanged', 'The profile connection assignments changed.');
    }
    final registry = context.context.read<ConnectionRegistry>();
    for (final entry in _connections.entries) {
      final current = active.connectionsById[entry.key];
      if (current == null || !registry.hasSameConfig(entry.value, current)) {
        throw const AgentControlException('sessionChanged', 'The profile connection configuration changed.');
      }
    }
    for (final entry in _clients.entries) {
      if (!isVisible(entry.key) ||
          !identical(multi.getClientForServer(ServerId(entry.key)), entry.value.client) ||
          !identical(entry.value.client.authenticationSessionId, entry.value.authentication)) {
        throw const AgentControlException('sessionChanged', 'The server authentication binding changed.');
      }
    }
    if (_libraries.isNotEmpty) {
      final provider = context.context.read<LibrariesProvider>();
      for (final key in _libraries.keys) {
        if (provider.libraryByGlobalKey(key) == null) {
          throw const AgentControlException('libraryUnavailable', 'The requested library is no longer available.');
        }
      }
    }
  }

  MediaServerClient server(String id) {
    check();
    if (!isVisible(id)) {
      throw const AgentControlException(
        'serverUnavailable',
        'The server is not visible and authenticated for this profile.',
      );
    }
    final client = multi.getClientForServer(ServerId(id));
    if (client == null) throw const AgentControlException('serverUnavailable', 'The server client is unavailable.');
    _clients.putIfAbsent(id, () => (client: client, authentication: client.authenticationSessionId));
    check();
    return client;
  }

  MediaLibrary library(Map<String, dynamic> scope) {
    final serverId = agentString(scope, 'serverId');
    server(serverId);
    final id = agentString(scope, 'libraryId');
    final key = buildGlobalKey(ServerId(serverId), id);
    final library = context.context.read<LibrariesProvider>().libraryByGlobalKey(key);
    if (library == null || library.serverId != serverId) {
      throw const AgentControlException('libraryUnavailable', 'The library is not available to the active profile.');
    }
    _libraries[key] = library;
    return library;
  }
}

Never _invalid(String message) => throw AgentControlException('invalidArguments', message);

int _integer(Object? value, {int? min, int? max}) {
  if (value is! int || (min != null && value < min) || (max != null && value > max)) {
    _invalid('An integer in the supported range is required.');
  }
  return value;
}

bool _boolean(Object? value) {
  if (value is! bool) _invalid('A boolean value is required.');
  return value;
}

String _choice(Object? value, List<String> choices) {
  if (value is! String || !choices.contains(value)) _invalid('Choose a supported value.');
  return value;
}

void _only(Map<String, dynamic> value, Set<String> keys) {
  if (value.keys.any((key) => !keys.contains(key))) _invalid('The value contains unsupported fields.');
}

String _safeEndpoint(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null || uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) return '[redacted endpoint]';
  return uri.toString();
}
