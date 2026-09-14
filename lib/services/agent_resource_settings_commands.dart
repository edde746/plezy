import 'package:provider/provider.dart';

import '../database/app_database.dart';
import '../exceptions/media_server_exceptions.dart';
import '../media/account_preferences.dart';
import '../media/ids.dart';
import '../media/live_tv_support.dart';
import '../media/media_server_client.dart';
import '../media/media_server_user_profile.dart';
import '../models/livetv_channel.dart';
import '../models/media_subscription.dart';
import '../profiles/active_profile_provider.dart';
import '../providers/account_preferences_controller.dart';
import '../providers/download_provider.dart';
import '../providers/multi_server_provider.dart';
import 'account_preferences_accounts.dart';
import 'account_preferences_repository.dart';
import 'agent_control_protocol.dart';

/// Configuration of existing, explicitly identified resources. Discovery only
/// projects non-secret domain identities; all writes remain with their owners.
class AgentResourceSettingsCommands {
  const AgentResourceSettingsCommands();

  Future<Object?> read(String command, Map<String, dynamic> arguments, AgentCommandContext context) => _safe(() async {
    if (command != 'settings.list' && command != 'settings.get') {
      throw const AgentControlException('unsupportedOperation', 'Unsupported resource settings read.');
    }
    final scope = agentSettingScope(arguments);
    final profileId = _profile(context, scope, requireIdentity: command == 'settings.get');
    final discovery = command == 'settings.list';
    return switch (scope['type']) {
      'account' => _readAccount(arguments, scope, profileId, context, discovery),
      'syncRule' => _readSync(arguments, scope, profileId, context, discovery),
      'liveTvFavorites' => _readFavorites(arguments, scope, profileId, context, discovery),
      'dvrRule' => _readDvr(arguments, scope, profileId, context, discovery),
      _ => throw const AgentControlException('unsupportedScope', 'Unsupported resource scope.'),
    };
  });

  Future<AgentSettingMutation> prepare(String command, Map<String, dynamic> arguments, AgentCommandContext context) =>
      _safe(() async {
        if (command != 'settings.set' && command != 'settings.reset') {
          throw const AgentControlException('unsupportedOperation', 'Unsupported resource settings mutation.');
        }
        final scope = Map<String, dynamic>.unmodifiable(agentSettingScope(arguments));
        _profile(context, scope, requireIdentity: true);
        final key = agentString(arguments, 'key');
        final reset = command == 'settings.reset';
        if (!reset && !arguments.containsKey('value')) {
          throw const AgentControlException('invalidArguments', 'value is required.');
        }
        return switch (scope['type']) {
          'account' => _prepareAccount(key, scope, arguments['value'], reset, context),
          'syncRule' => _prepareSync(key, scope, arguments['value'], reset, context),
          'liveTvFavorites' => _prepareFavorites(key, scope, arguments['value'], reset, context),
          'dvrRule' => _prepareDvr(key, scope, arguments['value'], reset, context),
          _ => throw const AgentControlException('unsupportedScope', 'Unsupported resource scope.'),
        };
      });

  String _profile(AgentCommandContext context, Map<String, dynamic> scope, {required bool requireIdentity}) {
    context.checkCurrent(requireProfile: true);
    final profileId = context.context.read<ActiveProfileProvider>().activeId;
    if (profileId == null) throw const AgentControlException('noActiveSession', 'An active profile is required.');
    if (requireIdentity) agentString(scope, 'profileId');
    if (scope.containsKey('profileId') && scope['profileId'] != profileId) {
      throw const AgentControlException('sessionChanged', 'The resource belongs to a different profile.');
    }
    return profileId;
  }

  void _scopeFields(Map<String, dynamic> scope, Set<String> fields) {
    if (scope.keys.any((key) => key != 'type' && key != 'profileId' && !fields.contains(key))) {
      throw const AgentControlException('invalidArguments', 'Unexpected resource scope field.');
    }
  }

  Future<Object?> _readAccount(
    Map<String, dynamic> arguments,
    Map<String, dynamic> scope,
    String profileId,
    AgentCommandContext context,
    bool list,
  ) async {
    _scopeFields(scope, {'accountId'});
    final controller = context.context.read<AccountPreferencesController>();
    if (list && !scope.containsKey('accountId')) {
      return {
        'scope': {'type': 'account', 'profileId': profileId},
        'settings': <Object?>[],
        'targets': [
          for (final account in controller.accounts)
            {
              'scope': {'type': 'account', 'profileId': profileId, 'accountId': account.ref.key},
              'label': account.target.label,
              'backend': account.ref.backend.id,
            },
        ],
      };
    }
    final target = _account(scope, context);
    final capabilities = target.controller.repository.capabilitiesFor(target.account.ref);
    if (list) {
      return {
        'scope': scope,
        'settings': [for (final key in AccountPreferenceKey.values) _accountDescriptor(key, capabilities)],
      };
    }
    final key = _accountKey(agentString(arguments, 'key'));
    _requireAccountSupport(key, capabilities);
    final snapshot = await target.controller.repository.load(target.account.ref, forceRefresh: true);
    target.guard();
    return _result(key.name, scope, _jsonValue(snapshot[key]), _accountTiming(key));
  }

  ({AccountPreferencesController controller, AccountPreferenceAccount account, void Function() guard}) _account(
    Map<String, dynamic> scope,
    AgentCommandContext context,
  ) {
    _scopeFields(scope, {'accountId'});
    _profile(context, scope, requireIdentity: true);
    final id = agentString(scope, 'accountId');
    final controller = context.context.read<AccountPreferencesController>();
    final account = controller.accounts.where((account) => account.ref.key == id).firstOrNull;
    if (account == null) {
      throw const AgentControlException('resourceNotFound', 'Account is not editable by this profile.');
    }
    final current = controller.captureAccountIdentity(account);
    void guard() {
      _profile(context, scope, requireIdentity: true);
      if (!current()) throw const AgentControlException('sessionChanged', 'Account identity changed.');
    }

    return (controller: controller, account: account, guard: guard);
  }

  Future<AgentSettingMutation> _prepareAccount(
    String name,
    Map<String, dynamic> scope,
    Object? raw,
    bool reset,
    AgentCommandContext context,
  ) async {
    final target = _account(scope, context);
    final key = _accountKey(name);
    final capabilities = target.controller.repository.capabilitiesFor(target.account.ref);
    _requireAccountSupport(key, capabilities);
    if (reset && key.valueKind != AccountPreferenceValueKind.languageCode) {
      throw const AgentControlException('unsupportedOperation', 'This account preference has no inherited reset.');
    }
    final value = _decodeAccount(key, reset ? null : raw);
    final patch = AccountPreferencesPatch.of(key, value);
    capabilities.validate(patch);
    return _mutation(name, scope, () async {
      target.guard();
      final updated = await target.controller.repository.update(target.account.ref, patch, checkCurrent: target.guard);
      target.guard();
      return _result(name, scope, _jsonValue(updated[key]), _accountTiming(key), persisted: true);
    });
  }

  AccountPreferenceKey _accountKey(String name) =>
      AccountPreferenceKey.values.where((key) => key.name == name).firstOrNull ??
      (throw const AgentControlException('unknownSetting', 'Unknown account preference.'));

  void _requireAccountSupport(AccountPreferenceKey key, AccountPreferencesCapabilities capabilities) {
    if (!capabilities.supports(key)) {
      throw const AgentControlException('unsupportedSetting', 'This backend does not support the account preference.');
    }
  }

  String _accountTiming(AccountPreferenceKey key) => switch (key) {
    AccountPreferenceKey.preferredAudioLanguage ||
    AccountPreferenceKey.autoSelectAudio ||
    AccountPreferenceKey.preferredSubtitleLanguage ||
    AccountPreferenceKey.subtitleMode => 'nextPlayback',
    _ => 'nextCatalogRefresh',
  };

  Map<String, dynamic> _accountDescriptor(AccountPreferenceKey key, AccountPreferencesCapabilities capabilities) => {
    'key': key.name,
    'type': switch (key.valueKind) {
      AccountPreferenceValueKind.boolean => 'boolean',
      AccountPreferenceValueKind.languageCode => 'string',
      _ => 'enum',
    },
    'nullable': key.valueKind == AccountPreferenceValueKind.languageCode,
    'default': null,
    'defaultMeaning': key.valueKind == AccountPreferenceValueKind.languageCode ? 'noPreference' : 'serverOwned',
    'resetSupported': capabilities.supports(key) && key.valueKind == AccountPreferenceValueKind.languageCode,
    if (key.valueKind == AccountPreferenceValueKind.languageCode)
      'constraints': {'format': 'ISO-639-1-or-backend-language-code'},
    'choices': ?_accountChoices(key, capabilities),
    'applicability': {
      'supported': capabilities.supports(key),
      if (!capabilities.supports(key)) 'reason': 'Not supported by this account backend.',
    },
    'application': _accountTiming(key),
    'storage': 'serverAccount',
  };

  List<String>? _accountChoices(AccountPreferenceKey key, AccountPreferencesCapabilities capabilities) =>
      switch (key.valueKind) {
        AccountPreferenceValueKind.subtitleMode => capabilities.subtitleModes.map((value) => value.name).toList(),
        AccountPreferenceValueKind.watchedIndicator => WatchedIndicatorScope.values.map((value) => value.name).toList(),
        AccountPreferenceValueKind.mediaReviewsVisibility =>
          MediaReviewsVisibility.values.map((value) => value.name).toList(),
        AccountPreferenceValueKind.subtitleAccessibility =>
          SubtitleAccessibilityPreference.values.map((value) => value.name).toList(),
        AccountPreferenceValueKind.forcedSubtitles =>
          ForcedSubtitlePreference.values.map((value) => value.name).toList(),
        _ => null,
      };

  Object? _decodeAccount(AccountPreferenceKey key, Object? value) => switch (key.valueKind) {
    AccountPreferenceValueKind.boolean || AccountPreferenceValueKind.languageCode => value,
    AccountPreferenceValueKind.subtitleMode => _enumValue(SubtitlePlaybackMode.values, value),
    AccountPreferenceValueKind.watchedIndicator => _enumValue(WatchedIndicatorScope.values, value),
    AccountPreferenceValueKind.mediaReviewsVisibility => _enumValue(MediaReviewsVisibility.values, value),
    AccountPreferenceValueKind.subtitleAccessibility => _enumValue(SubtitleAccessibilityPreference.values, value),
    AccountPreferenceValueKind.forcedSubtitles => _enumValue(ForcedSubtitlePreference.values, value),
  };

  T _enumValue<T extends Enum>(List<T> values, Object? value) =>
      values.where((entry) => entry.name == value).firstOrNull ??
      (throw const AgentControlException('invalidArguments', 'Unknown account preference choice.'));

  Object? _jsonValue(Object? value) => value is Enum ? value.name : value;

  Future<Object?> _readSync(
    Map<String, dynamic> arguments,
    Map<String, dynamic> scope,
    String profileId,
    AgentCommandContext context,
    bool list,
  ) async {
    _scopeFields(scope, {'serverId', 'ruleId'});
    final downloads = context.context.read<DownloadProvider>();
    final servers = context.context.read<MultiServerProvider>();
    await downloads.ensureInitialized();
    context.checkCurrent(requireProfile: true);
    if (list && !scope.containsKey('ruleId')) {
      if (scope.containsKey('serverId') && !servers.expectedServerIds.contains(agentString(scope, 'serverId'))) {
        throw const AgentControlException('serverUnavailable', 'Server is not bound to the active profile.');
      }
      return {
        'scope': scope,
        'settings': <Object?>[],
        'applicability': {
          'supported': downloads.syncRulesSupported,
          if (!downloads.syncRulesSupported) 'reason': 'Downloads are not supported on this platform.',
        },
        'targets': [
          for (final rule in downloads.syncRules.values)
            if (rule.profileId == profileId &&
                servers.expectedServerIds.contains(rule.serverId) &&
                (!scope.containsKey('serverId') || scope['serverId'] == rule.serverId))
              {
                'scope': {
                  'type': 'syncRule',
                  'profileId': profileId,
                  'serverId': rule.serverId,
                  'ruleId': '${rule.id}',
                },
                'itemId': rule.ratingKey,
                'targetType': rule.targetType,
                'enabled': rule.enabled,
              },
        ],
      };
    }
    final rule = _syncRule(scope, context);
    if (list) {
      return {
        'scope': scope,
        'settings': [
          for (final descriptor in _syncDescriptors(rule))
            if (downloads.syncRulesSupported)
              descriptor
            else
              {
                ...descriptor,
                'resetSupported': false,
                'applicability': {'supported': false, 'reason': 'Downloads are not supported on this platform.'},
              },
        ],
      };
    }
    final key = agentString(arguments, 'key');
    _syncDescriptor(rule, key);
    return _result(key, scope, _syncValue(rule, key), 'nextSync');
  }

  SyncRuleItem _syncRule(Map<String, dynamic> scope, AgentCommandContext context) {
    _scopeFields(scope, {'serverId', 'ruleId'});
    final profileId = _profile(context, scope, requireIdentity: true);
    final serverId = agentString(scope, 'serverId');
    final ruleId = agentString(scope, 'ruleId');
    if (!context.context.read<MultiServerProvider>().expectedServerIds.contains(serverId)) {
      throw const AgentControlException('serverUnavailable', 'Server is not bound to the active profile.');
    }
    final rule = context.context
        .read<DownloadProvider>()
        .syncRules
        .values
        .where((rule) => '${rule.id}' == ruleId && rule.serverId == serverId && rule.profileId == profileId)
        .firstOrNull;
    if (rule == null) throw const AgentControlException('resourceNotFound', 'Sync rule was not found in this profile.');
    return rule;
  }

  List<Map<String, dynamic>> _syncDescriptors(SyncRuleItem rule) {
    final list = rule.targetType == 'collection' || rule.targetType == 'playlist';
    return [
      _descriptor(
        'count',
        'integer',
        null,
        supported: !list,
        reset: false,
        constraints: {'minimum': 0, 'zeroMeaning': 'allUnwatched'},
      ),
      _descriptor('filter', 'enum', 'unwatched', supported: list, choices: ['all', 'unwatched']),
      _descriptor('enabled', 'boolean', true),
      _descriptor('includeSpecials', 'boolean', true, supported: rule.targetType == 'show'),
      _descriptor(
        'version',
        'object',
        {'index': 0},
        supported: !list,
        constraints: {
          'properties': {
            'index': {'type': 'integer', 'minimum': 0},
          },
          'meaning': 'Preferred version index for future episodes; existing per-episode fallback remains in effect.',
        },
      ),
    ];
  }

  Map<String, dynamic> _descriptor(
    String key,
    String type,
    Object? defaultValue, {
    bool supported = true,
    bool reset = true,
    List<String>? choices,
    Map<String, dynamic>? constraints,
  }) => {
    'key': key,
    'type': type,
    'default': defaultValue,
    'resetSupported': reset && supported,
    'application': 'nextSync',
    'applicability': {'supported': supported, if (!supported) 'reason': 'Not consumed by this sync-rule type.'},
    'choices': ?choices,
    'constraints': ?constraints,
  };

  Map<String, dynamic> _syncDescriptor(SyncRuleItem rule, String key) {
    final descriptor = _syncDescriptors(rule).where((entry) => entry['key'] == key).firstOrNull;
    if (descriptor == null) throw const AgentControlException('unknownSetting', 'Unknown sync-rule setting.');
    if ((descriptor['applicability'] as Map)['supported'] != true) {
      throw const AgentControlException('unsupportedSetting', 'This option is not used by this sync-rule type.');
    }
    return descriptor;
  }

  Object _syncValue(SyncRuleItem rule, String key) => switch (key) {
    'count' => rule.episodeCount,
    'filter' => rule.downloadFilter,
    'enabled' => rule.enabled,
    'includeSpecials' => rule.includeSpecials,
    'version' => {'index': rule.mediaIndex},
    _ => throw const AgentControlException('unknownSetting', 'Unknown sync-rule setting.'),
  };

  Future<AgentSettingMutation> _prepareSync(
    String key,
    Map<String, dynamic> scope,
    Object? raw,
    bool reset,
    AgentCommandContext context,
  ) async {
    final downloads = context.context.read<DownloadProvider>();
    if (!downloads.syncRulesSupported) {
      throw const AgentControlException('unsupportedSetting', 'Downloads are not supported on this platform.');
    }
    await downloads.ensureInitialized();
    final rule = _syncRule(scope, context);
    final descriptor = _syncDescriptor(rule, key);
    if (reset && descriptor['resetSupported'] != true) {
      throw const AgentControlException('unsupportedOperation', 'This sync option has no reset default.');
    }
    final value = reset ? descriptor['default'] : raw;
    int? count;
    String? filter;
    bool? enabled;
    bool? specials;
    int? version;
    switch (key) {
      case 'count':
        count = _nonnegativeInt(value, 'count');
      case 'filter':
        if (value != 'all' && value != 'unwatched') {
          throw const AgentControlException('invalidArguments', 'filter must be all or unwatched.');
        }
        filter = value as String;
      case 'enabled':
        enabled = _boolean(value, key);
      case 'includeSpecials':
        specials = _boolean(value, key);
      case 'version':
        final object = agentObject(value, 'version');
        if (object.length != 1) throw const AgentControlException('invalidArguments', 'version requires only index.');
        version = _nonnegativeInt(object['index'], 'version.index');
    }
    DownloadProvider.validateSyncRuleOptions(
      rule,
      episodeCount: count,
      downloadFilter: filter,
      includeSpecials: specials,
      mediaIndex: version,
    );
    void guard() {
      final current = _syncRule(scope, context);
      if (current.id != rule.id || current.globalKey != rule.globalKey) {
        throw const AgentControlException('resourceNotFound', 'Sync rule identity changed.');
      }
    }

    return _mutation(key, scope, () async {
      guard();
      final updated = await downloads.updateSyncRuleOptions(
        rule.globalKey,
        episodeCount: count,
        downloadFilter: filter,
        enabled: enabled,
        includeSpecials: specials,
        mediaIndex: version,
        checkCurrent: guard,
      );
      guard();
      return _result(key, scope, _syncValue(updated, key), 'nextSync', persisted: true);
    });
  }

  ({MediaServerClient client, void Function() guard}) _server(Map<String, dynamic> scope, AgentCommandContext context) {
    _profile(context, scope, requireIdentity: true);
    final id = agentString(scope, 'serverId');
    final servers = context.context.read<MultiServerProvider>();
    if (!servers.hasExplicitVisibleServerFilter || !servers.serverIds.contains(id)) {
      throw const AgentControlException('serverUnavailable', 'Server is not visible to the active profile.');
    }
    final client = servers.getClientForServer(ServerId(id));
    if (client == null) throw const AgentControlException('serverUnavailable', 'Server client is unavailable.');
    final authentication = client.authenticationSessionId;
    void guard() {
      _profile(context, scope, requireIdentity: true);
      if (!servers.serverIds.contains(id) ||
          !identical(servers.getClientForServer(ServerId(id)), client) ||
          !identical(client.authenticationSessionId, authentication)) {
        throw const AgentControlException('sessionChanged', 'Server authentication or visibility changed.');
      }
    }

    guard();
    return (client: client, guard: guard);
  }

  ({LiveTvSupport live, LiveTvServerInfo info, void Function() guard}) _favorites(
    Map<String, dynamic> scope,
    AgentCommandContext context,
  ) {
    _scopeFields(scope, {'serverId', 'dvrId'});
    final server = _server(scope, context);
    final dvrId = agentString(scope, 'dvrId');
    final servers = context.context.read<MultiServerProvider>();
    final info = servers.liveTvServers
        .where((entry) => entry.serverId == scope['serverId'] && entry.dvrKey == dvrId)
        .firstOrNull;
    final live = server.client.liveTv;
    if (info == null) {
      throw const AgentControlException('resourceNotFound', 'Live-TV lineup was not found.');
    }
    void guard() {
      server.guard();
      if (!servers.liveTvServers.any(
        (entry) => entry.serverId == info.serverId && entry.dvrKey == info.dvrKey && entry.lineup == info.lineup,
      )) {
        throw const AgentControlException('sessionChanged', 'Live-TV lineup changed.');
      }
    }

    return (live: live, info: info, guard: guard);
  }

  Future<Object?> _readFavorites(
    Map<String, dynamic> arguments,
    Map<String, dynamic> scope,
    String profileId,
    AgentCommandContext context,
    bool list,
  ) async {
    _scopeFields(scope, {'serverId', 'dvrId'});
    if (list && !scope.containsKey('dvrId')) {
      final servers = context.context.read<MultiServerProvider>();
      if (scope.containsKey('serverId')) _server({...scope, 'profileId': profileId}, context);
      return {
        'scope': scope,
        'settings': <Object?>[],
        'servers': [
          for (final id in servers.serverIds)
            if (!scope.containsKey('serverId') || scope['serverId'] == id)
              {
                'serverId': id,
                'supported': servers.liveTvServers.any((entry) => entry.serverId == id),
                if (!servers.liveTvServers.any((entry) => entry.serverId == id))
                  'reason': 'No configured live-TV lineup.',
              },
        ],
        'targets': [
          for (final entry in servers.liveTvServers)
            if (servers.serverIds.contains(entry.serverId) &&
                (!scope.containsKey('serverId') || scope['serverId'] == entry.serverId))
              {
                'scope': {
                  'type': 'liveTvFavorites',
                  'profileId': profileId,
                  'serverId': entry.serverId,
                  'dvrId': entry.dvrKey,
                },
              },
        ],
      };
    }
    final target = _favorites(scope, context);
    final source = await target.live.buildFavoriteChannelSource(lineup: target.info.lineup);
    target.guard();
    if (list) {
      final channels = await target.live.fetchChannels(lineup: target.info.lineup);
      target.guard();
      return {
        'scope': scope,
        'settings': [
          {
            'key': 'channels',
            'type': 'object',
            'default': null,
            'resetSupported': false,
            'constraints': {
              'properties': {
                'channelIds': {'type': 'array', 'items': 'string', 'uniqueItems': true, 'maxItems': 2000},
              },
            },
            'application': 'nextLiveTvRefresh',
            'applicability': {'supported': true},
            'storage': target.live.favoritePersistenceMode == FavoriteChannelPersistenceMode.sharedFullList
                ? 'sharedAccountSourceSlice'
                : 'serverUserWithLocalOrder',
          },
        ],
        'channels': [
          for (final channel in channels) {'channelId': channel.key, 'label': channel.displayName},
        ],
      };
    }
    _key(agentString(arguments, 'key'), 'channels');
    final favorites = await target.live.fetchFavoriteChannels(migrate: false, checkCurrent: target.guard);
    target.guard();
    return _result('channels', scope, _favoriteValue(favorites, source), 'nextLiveTvRefresh');
  }

  Map<String, dynamic> _favoriteValue(List<FavoriteChannel> favorites, String source) => {
    'channelIds': favorites.where((entry) => entry.source == source).map((entry) => entry.id).toList(),
  };

  Future<AgentSettingMutation> _prepareFavorites(
    String key,
    Map<String, dynamic> scope,
    Object? raw,
    bool reset,
    AgentCommandContext context,
  ) async {
    _key(key, 'channels');
    if (reset) throw const AgentControlException('unsupportedOperation', 'Favorite membership has no inherited reset.');
    final target = _favorites(scope, context);
    final value = agentObject(raw, 'channels');
    final rawIds = value['channelIds'];
    if (value.length != 1 ||
        rawIds is! List ||
        rawIds.length > 2000 ||
        rawIds.any((id) => id is! String || id.isEmpty)) {
      throw const AgentControlException('invalidArguments', 'channels requires a bounded channelIds string array.');
    }
    final ids = rawIds.cast<String>().toList(growable: false);
    if (ids.toSet().length != ids.length) {
      throw const AgentControlException('invalidArguments', 'Channel IDs must be unique.');
    }
    final source = await target.live.buildFavoriteChannelSource(lineup: target.info.lineup);
    target.guard();
    // Pure reads: do not migrate local favorites during batch preparation.
    final current = await target.live.fetchFavoriteChannels(migrate: false, checkCurrent: target.guard);
    target.guard();
    final channels = await target.live.fetchChannels(lineup: target.info.lineup);
    target.guard();
    final known = {
      ...channels.map((entry) => entry.key),
      ...current.where((entry) => entry.source == source).map((entry) => entry.id),
    };
    if (ids.any((id) => !known.contains(id))) {
      throw const AgentControlException(
        'resourceNotFound',
        'A requested channel is not in this lineup or its current favorites.',
      );
    }
    return _mutation(key, scope, () async {
      target.guard();
      final fresh = await target.live.fetchFavoriteChannels(migrate: false, checkCurrent: target.guard);
      target.guard();
      final freshChannels = await target.live.fetchChannels(lineup: target.info.lineup);
      target.guard();
      final byId = {for (final entry in fresh.where((entry) => entry.source == source)) entry.id: entry};
      final channelsById = {for (final entry in freshChannels) entry.key: entry};
      final replacement = <FavoriteChannel>[];
      for (final id in ids) {
        final existing = byId[id];
        final channel = channelsById[id];
        if (existing == null && channel == null) {
          throw const AgentControlException('resourceNotFound', 'A requested channel disappeared before the write.');
        }
        replacement.add(existing ?? FavoriteChannel.fromLiveTvChannel(channel!, source));
      }
      // Replace this source's slots in order, preserving every other source and
      // all server-provided display fields on retained favorites.
      final merged = <FavoriteChannel>[];
      var next = 0;
      for (final entry in fresh) {
        if (entry.source != source) {
          merged.add(entry);
        } else if (next < replacement.length) {
          merged.add(replacement[next++]);
        }
      }
      merged.addAll(replacement.skip(next));
      target.guard();
      await target.live.setFavoriteChannels(
        target.live.favoritePersistenceMode == FavoriteChannelPersistenceMode.sharedFullList ? merged : replacement,
        checkCurrent: target.guard,
      );
      target.guard();
      final confirmed = await target.live.fetchFavoriteChannels(migrate: false, checkCurrent: target.guard);
      target.guard();
      return _result(key, scope, _favoriteValue(confirmed, source), 'nextLiveTvRefresh', persisted: true);
    });
  }

  Future<Object?> _readDvr(
    Map<String, dynamic> arguments,
    Map<String, dynamic> scope,
    String profileId,
    AgentCommandContext context,
    bool list,
  ) async {
    _scopeFields(scope, {'serverId', 'ruleId'});
    if (list && !scope.containsKey('ruleId')) {
      final servers = context.context.read<MultiServerProvider>();
      if (scope.containsKey('serverId')) _server({...scope, 'profileId': profileId}, context);
      final targets = <Map<String, dynamic>>[];
      final failures = <Map<String, dynamic>>[];
      final capabilities = <Map<String, dynamic>>[];
      for (final id in servers.serverIds) {
        if (scope.containsKey('serverId') && scope['serverId'] != id) continue;
        final targetScope = {'type': 'dvrRule', 'profileId': profileId, 'serverId': id};
        final server = _server(targetScope, context);
        final dvr = server.client.liveTvDvr;
        capabilities.add({
          'serverId': id,
          'supported': dvr != null,
          if (dvr == null) 'reason': 'No DVR configuration API.',
        });
        if (dvr == null) continue;
        try {
          final rules = await _safe(() => dvr.fetchRecordingRules(includeGrabs: false, includeStorage: false));
          server.guard();
          for (final rule in rules) {
            targets.add({
              'scope': {...targetScope, 'ruleId': rule.key},
              'label': rule.title,
              'type': rule.type,
            });
          }
        } on AgentControlException catch (error) {
          context.checkCurrent(requireProfile: true);
          failures.add({'serverId': id, 'error': error.toJson()});
        }
      }
      return {
        'scope': scope,
        'settings': <Object?>[],
        'targets': targets,
        'servers': capabilities,
        'complete': failures.isEmpty,
        if (failures.isNotEmpty) 'failures': failures,
      };
    }
    final target = _server(scope, context);
    final dvr = target.client.liveTvDvr;
    if (dvr == null) {
      throw const AgentControlException('unsupportedSetting', 'This server has no DVR configuration API.');
    }
    final rule = await _dvrRule(dvr, agentString(scope, 'ruleId'));
    target.guard();
    if (list) {
      return {
        'scope': scope,
        'settings': [_dvrDescriptor(rule)],
      };
    }
    _key(agentString(arguments, 'key'), 'options');
    return _result('options', scope, _dvrValue(rule), 'serverImmediate');
  }

  Future<MediaSubscription> _dvrRule(LiveTvDvrSupport dvr, String id) async {
    final rules = await dvr.fetchRecordingRules(includeGrabs: false, includeStorage: false);
    return rules.where((rule) => rule.key == id).firstOrNull ??
        (throw const AgentControlException('resourceNotFound', 'Recording rule was not found.'));
  }

  Map<String, Object?> _dvrValue(MediaSubscription rule) => {
    for (final setting in rule.settings)
      if (setting.isEditable) setting.id: setting.domainValue(setting.value ?? setting.defaultValue),
  };

  Map<String, dynamic> _dvrDescriptor(MediaSubscription rule) => {
    'key': 'options',
    'type': 'object',
    'default': null,
    'resetSupported':
        rule.settings.where((setting) => setting.isEditable).isNotEmpty &&
        rule.settings.where((setting) => setting.isEditable).every((setting) => setting.defaultValue != null),
    'application': 'serverImmediate',
    'applicability': {
      'supported': rule.settings.any((setting) => setting.isEditable),
      if (!rule.settings.any((setting) => setting.isEditable)) 'reason': 'The rule exposes no editable options.',
    },
    'constraints': {
      'patch': true,
      'properties': {
        for (final setting in rule.settings)
          if (!setting.hidden && setting.id.isNotEmpty)
            setting.id: {
              'type': setting.domainType,
              'applicability': {
                'supported': setting.isEditable,
                if (!setting.isEditable) 'reason': 'Unsupported backend option type.',
              },
              'default': setting.isEditable ? setting.domainValue(setting.defaultValue) : null,
              'resetSupported': setting.isEditable && setting.defaultValue != null,
              if (setting.minimum != null) 'minimum': setting.minimum,
              if (setting.options.isNotEmpty) 'choices': setting.options.map((option) => option.value).toList(),
            },
      },
    },
  };

  Future<AgentSettingMutation> _prepareDvr(
    String key,
    Map<String, dynamic> scope,
    Object? raw,
    bool reset,
    AgentCommandContext context,
  ) async {
    _scopeFields(scope, {'serverId', 'ruleId'});
    _key(key, 'options');
    final server = _server(scope, context);
    final id = agentString(scope, 'ruleId');
    final dvr = server.client.liveTvDvr;
    if (dvr == null) {
      throw const AgentControlException('unsupportedSetting', 'This server has no DVR configuration API.');
    }
    final rule = await _dvrRule(dvr, id);
    server.guard();
    final Map<String, Object?> values;
    if (reset) {
      if (_dvrDescriptor(rule)['resetSupported'] != true) {
        throw const AgentControlException(
          'unsupportedOperation',
          'The backend does not provide defaults for these options.',
        );
      }
      values = {
        for (final setting in rule.settings)
          if (setting.isEditable) setting.id: setting.domainValue(setting.defaultValue),
      };
    } else {
      values = Map<String, Object?>.from(agentObject(raw, 'options'));
      if (values.isEmpty) {
        throw const AgentControlException('invalidArguments', 'options must name at least one option.');
      }
    }
    final patch = rule.validatePrefs(values);
    return _mutation(key, scope, () async {
      server.guard();
      final fresh = await _dvrRule(dvr, id);
      server.guard();
      fresh.validatePrefs(patch);
      final response = await dvr.updateRecordingRule(id, patch, checkCurrent: server.guard);
      server.guard();
      // Empty backend acknowledgements are not an authoritative configuration.
      final updated = response != null && response.key == id && response.settings.isNotEmpty
          ? response
          : await _dvrRule(dvr, id);
      server.guard();
      return _result(
        key,
        scope,
        _dvrValue(updated),
        'serverImmediate',
        persisted: true,
        extra: {
          'pendingEffects': ['liveTvScreenRefresh'],
        },
      );
    });
  }

  void _key(String actual, String expected) {
    if (actual != expected) throw const AgentControlException('unknownSetting', 'Unknown resource setting.');
  }

  int _nonnegativeInt(Object? value, String name) {
    if (value is! int || value < 0) {
      throw AgentControlException('invalidArguments', '$name must be a nonnegative integer.');
    }
    return value;
  }

  bool _boolean(Object? value, String name) {
    if (value is! bool) throw AgentControlException('invalidArguments', '$name must be a boolean.');
    return value;
  }

  AgentSettingMutation _mutation(
    String key,
    Map<String, dynamic> scope,
    Future<Map<String, dynamic>> Function() apply,
  ) => AgentSettingMutation(key: key, scope: scope, apply: () => _safe(apply, mutation: true));

  Map<String, dynamic> _result(
    String key,
    Map<String, dynamic> scope,
    Object? value,
    String application, {
    bool? persisted,
    Map<String, dynamic> extra = const {},
  }) => {'key': key, 'scope': scope, 'value': value, 'application': application, 'persisted': ?persisted, ...extra};

  Future<T> _safe<T>(Future<T> Function() action, {bool mutation = false}) async {
    try {
      return await action();
    } on AgentControlException catch (error) {
      if (!mutation) rethrow;
      throw AgentControlException(error.code, error.message, details: {...?error.details, 'stateMayHaveChanged': true});
    } on AccountPreferencesUnavailableException {
      throw AgentControlException(
        'serverUnavailable',
        'Account preferences are currently unavailable.',
        details: {if (mutation) 'stateMayHaveChanged': true},
      );
    } on SyncRuleCleanupBusyException {
      throw const AgentControlException('resourceBusy', 'Sync rules are currently executing or being removed.');
    } on UnsupportedError {
      throw const AgentControlException(
        'unsupportedOperation',
        'The resource does not support this option or operation.',
      );
    } on ArgumentError {
      throw const AgentControlException('invalidArguments', 'Invalid resource configuration value.');
    } on MediaServerHttpException catch (error) {
      throw AgentControlException(
        error.statusCode == 401 || error.statusCode == 403 ? 'permissionDenied' : 'serverRequestFailed',
        'The server did not complete the resource request.',
        details: {'statusCode': error.statusCode, if (mutation) 'stateMayHaveChanged': true},
      );
    } catch (_) {
      throw AgentControlException(
        mutation ? 'mutationFailed' : 'readFailed',
        mutation ? 'The resource update could not be confirmed.' : 'The resource configuration could not be read.',
        details: {if (mutation) 'stateMayHaveChanged': true},
      );
    }
  }
}
