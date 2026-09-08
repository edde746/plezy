import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../media/ids.dart';
import '../profiles/active_profile_provider.dart';
import '../providers/multi_server_provider.dart';
import '../utils/platform_detector.dart';
import 'agent_control_protocol.dart';
import 'agent_playback_commands.dart';
import 'agent_resource_settings_commands.dart';
import 'agent_scoped_settings_commands.dart';
import 'agent_settings_commands.dart';
import 'settings_mutation_service.dart';

const agentControlEnabled = !kReleaseMode && bool.fromEnvironment('PLEZY_AGENT_CONTROL');

/// An opt-in adapter to existing app owners, reachable only through the
/// authenticated Dart VM service. No listener or adapter is created when off.
class AgentControlService {
  AgentControlService._();

  static final instance = AgentControlService._();
  static const extensionName = 'ext.plezy.agent';
  static const protocolVersion = 1;
  static const maxPayloadBytes = 1024 * 1024;
  static const scopeTypes = [
    'app',
    'player',
    'server',
    'library',
    'profile',
    'catalog',
    'account',
    'syncRule',
    'liveTvFavorites',
    'dvrRule',
  ];
  static const _readCommands = {
    'app.status',
    'settings.list',
    'settings.get',
    'media.servers',
    'media.search',
    'media.get',
    'media.children',
    'playback.status',
  };
  static const _mutationCommands = {
    'settings.set',
    'settings.reset',
    'settings.apply',
    'playback.start',
    'playback.stop',
  };

  bool _registered = false;
  bool _mutating = false;
  int _generation = 0;
  final String _instanceId = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  _AgentOwner? _root;
  _AgentOwner? _profile;
  ActiveProfileProvider? _activeProfile;
  MultiServerProvider? _multiServer;
  Object? _identity;
  Map<String, (Object?, Object?)> _clientIdentities = {};
  AgentPlaybackCommands? _playback;
  Timer? _rebuildTimer;
  String? _lastEffectError;
  late final _settings = AgentSettingsCommands();
  late final _scopedSettings = AgentScopedSettingsCommands();
  late final _resourceSettings = AgentResourceSettingsCommands();

  void register() {
    if (!agentControlEnabled || _registered) return;
    developer.registerExtension(extensionName, (_, parameters) async {
      AgentCommandContext? pendingRebuild;
      final response = await executePayload(
        parameters['payload'],
        onRootRebuild: (context) => pendingRebuild = context,
      );
      final encoded = jsonEncode(response);
      final rebuild = pendingRebuild;
      if (rebuild != null) {
        _rebuildTimer?.cancel();
        _rebuildTimer = Timer(Duration.zero, () {
          _rebuildTimer = null;
          if (!rebuild.context.mounted || !rebuild.isCurrent()) return;
          try {
            SettingsMutationService.rebuild(rebuild.context);
          } catch (_) {
            _lastEffectError = 'rootRebuildFailed';
          }
        });
      }
      return developer.ServiceExtensionResponse.result(encoded);
    });
    _registered = true;
  }

  void attachRoot({
    required Object owner,
    required BuildContext? Function() commandContext,
    required ActiveProfileProvider activeProfile,
    required MultiServerProvider multiServer,
  }) {
    final previous = _root;
    if (previous != null) detachRoot(previous.owner);
    _root = _AgentOwner(owner, commandContext, () => true);
    _activeProfile = activeProfile;
    _multiServer = multiServer;
    activeProfile.addListener(_observeIdentity);
    multiServer.addListener(_observeIdentity);
    _invalidate();
    _observeIdentity();
  }

  void detachRoot(Object owner) {
    if (!identical(_root?.owner, owner)) return;
    _rebuildTimer?.cancel();
    _rebuildTimer = null;
    _removeIdentityListeners();
    _root = null;
    _profile = null;
    _activeProfile = null;
    _multiServer = null;
    _identity = null;
    _clientIdentities = {};
    _invalidate();
  }

  void attachProfile({
    required Object owner,
    required BuildContext? Function() commandContext,
    required bool Function() uncovered,
  }) {
    if (identical(_profile?.owner, owner)) return;
    _profile = _AgentOwner(owner, commandContext, uncovered);
    _invalidate();
  }

  void detachProfile(Object owner) {
    if (!identical(_profile?.owner, owner)) return;
    _profile = null;
    _invalidate();
  }

  void profileVisibilityChanged(Object owner) {
    if (identical(_profile?.owner, owner)) _invalidate();
  }

  void _removeIdentityListeners() {
    _activeProfile?.removeListener(_observeIdentity);
    _multiServer?.removeListener(_observeIdentity);
  }

  void _observeIdentity() {
    final active = _activeProfile;
    final identity = (
      active?.activeId,
      active?.identityMutationGeneration,
      active?.committedIdentityGeneration,
      active?.isBinding,
      active?.lastBindingSucceeded,
    );
    final multi = _multiServer;
    final clients = <String, (Object?, Object?)>{
      if (multi != null)
        for (final id in multi.serverIds)
          id: (multi.getClientForServer(ServerId(id)), multi.getClientForServer(ServerId(id))?.authenticationSessionId),
    };
    if (_identity == identity && mapEquals(_clientIdentities, clients)) return;
    _identity = identity;
    _clientIdentities = clients;
    _invalidate();
  }

  void _invalidate() {
    _generation++;
    _playback?.dispose();
    _playback = null;
  }

  String? get _sessionToken => _profile == null ? null : '$_instanceId-$_generation';

  bool get _profileReady =>
      _root?.context()?.mounted == true &&
      _profile?.context()?.mounted == true &&
      _profile!.uncovered() &&
      _activeProfile?.activeId != null &&
      _activeProfile?.isBinding == false &&
      _activeProfile?.lastBindingSucceeded == true;

  String? get _blocker {
    if (_root?.context()?.mounted != true) return 'starting';
    if (_activeProfile?.isBinding == true) return 'profileBinding';
    if (_profile != null && !_profile!.uncovered()) return 'profileCovered';
    if (_activeProfile?.lastBindingSucceeded == false) return 'authenticationRequired';
    if (!_profileReady) return 'noActiveSession';
    return null;
  }

  Map<String, dynamic> _status() => {
    'protocolVersion': protocolVersion,
    'buildMode': kProfileMode ? 'profile' : 'debug',
    'platform': Platform.operatingSystem,
    'isTV': PlatformDetector.isTV(),
    'ready': _root?.context()?.mounted == true,
    'profileReady': _profileReady,
    'profileId': _activeProfile?.activeId,
    'sessionToken': _sessionToken,
    'mutationInProgress': _mutating,
    'blocker': _blocker,
    if (_lastEffectError != null) 'lastEffectError': _lastEffectError,
    'commands': [..._readCommands, ..._mutationCommands],
    'scopeTypes': scopeTypes,
    'maxPayloadBytes': maxPayloadBytes,
    'maxBatchChanges': 100,
  };

  /// Also used by focused protocol tests; registration itself remains opt-in.
  Future<Map<String, dynamic>> executePayload(
    String? payload, {
    void Function(AgentCommandContext)? onRootRebuild,
  }) async {
    String? requestId;
    var acquiredMutation = false;
    try {
      if (payload == null || payload.length > maxPayloadBytes || utf8.encode(payload).length > maxPayloadBytes) {
        throw const AgentControlException('invalidRequest', 'A payload of at most 1 MiB is required.');
      }
      final Map<String, dynamic> request;
      try {
        request = agentObject(jsonDecode(payload), 'request');
      } on FormatException {
        throw const AgentControlException('invalidRequest', 'The payload must be valid JSON.');
      }
      requestId = agentString(request, 'requestId');
      if (requestId.length > 128) {
        throw const AgentControlException('invalidRequest', 'requestId is too long.');
      }
      if (request['version'] is! int || request['version'] != protocolVersion) {
        throw const AgentControlException('unsupportedVersion', 'Protocol version 1 is required.');
      }
      final command = agentString(request, 'command');
      if (!_readCommands.contains(command) && !_mutationCommands.contains(command)) {
        throw const AgentControlException('unknownCommand', 'The command is not supported.');
      }
      final arguments = request['arguments'] == null
          ? <String, dynamic>{}
          : agentObject(request['arguments'], 'arguments');
      _observeIdentity();
      if (command == 'app.status') return _success(requestId, _status());
      final mutation = _mutationCommands.contains(command);
      final context = _captureContext(requestId, requireProfile: _requiresProfile(command, arguments));
      if (mutation) {
        if (_mutating) throw const AgentControlException('busy', 'Another mutation is in progress.');
        if (_profile != null && !_profile!.uncovered()) {
          throw const AgentControlException('blocked', 'A root profile or authentication route covers the app.');
        }
        if (request['sessionToken'] != context.sessionToken) {
          throw const AgentControlException('sessionChanged', 'Refresh app.status before changing this session.');
        }
        _mutating = true;
        acquiredMutation = true;
      }
      final result = command.startsWith('settings.')
          ? await _settingsCommand(command, arguments, context, onRootRebuild: onRootRebuild)
          : await (_playback ??= AgentPlaybackCommands()).handle(command, arguments, context);
      return _success(requestId, result);
    } on AgentControlException catch (error) {
      return _failure(requestId, error);
    } catch (_) {
      // Third-party exception messages may contain URLs or tokens. The command
      // receipt deliberately contains no raw exception or stack trace.
      return _failure(requestId, const AgentControlException('commandFailed', 'The command failed.'));
    } finally {
      if (acquiredMutation) _mutating = false;
    }
  }

  bool _requiresProfile(String command, Map<String, dynamic> arguments) {
    if (!command.startsWith('settings.')) return true;
    if (command == 'settings.apply') {
      final changes = arguments['changes'];
      if (changes is! List) return false; // The batch validator reports its shape.
      return changes.any((change) => agentSettingScope(agentObject(change, 'change'))['type'] != 'app');
    }
    return agentSettingScope(arguments)['type'] != 'app';
  }

  AgentCommandContext _captureContext(String requestId, {required bool requireProfile}) {
    final ready = _profileReady;
    if (requireProfile && !ready) {
      throw AgentControlException(
        _blocker ?? 'noActiveSession',
        'An uncovered, authenticated profile session is required.',
      );
    }
    final owner = ready ? _profile : _root;
    final context = owner?.context();
    if (context == null || !context.mounted) {
      throw const AgentControlException('notReady', 'Application startup has not completed.');
    }
    final generation = _generation;
    final token = _sessionToken;
    final clients = _clientIdentities;
    final active = _activeProfile;
    final activeId = active?.activeId;
    final identityMutation = active?.identityMutationGeneration;
    final committedIdentity = active?.committedIdentityGeneration;
    final isBinding = active?.isBinding;
    final lastBindingSucceeded = active?.lastBindingSucceeded;
    return AgentCommandContext(
      context: context,
      requestId: requestId,
      sessionToken: token,
      hasProfile: ready,
      isCurrent: () {
        if (generation != _generation || !context.mounted) return false;
        // Identity preparation reserves a generation before it notifies any
        // listeners. Compare the live authority, not just the observed epoch.
        if (!identical(active, _activeProfile) ||
            active?.activeId != activeId ||
            active?.identityMutationGeneration != identityMutation ||
            active?.committedIdentityGeneration != committedIdentity ||
            active?.isBinding != isBinding ||
            active?.lastBindingSucceeded != lastBindingSucceeded) {
          return false;
        }
        for (final entry in clients.entries) {
          final client = _multiServer?.getClientForServer(ServerId(entry.key));
          if (!identical(client, entry.value.$1) || client?.authenticationSessionId != entry.value.$2) return false;
        }
        return identical(owner, _root) || (identical(owner, _profile) && _profileReady);
      },
    );
  }

  Future<Object?> _settingsCommand(
    String command,
    Map<String, dynamic> arguments,
    AgentCommandContext context, {
    void Function(AgentCommandContext)? onRootRebuild,
  }) async {
    if (command == 'settings.apply') {
      final raw = arguments['changes'];
      if (raw is! List || raw.isEmpty || raw.length > 100) {
        throw const AgentControlException('invalidArguments', 'changes must contain between 1 and 100 settings.');
      }
      final mutations = <AgentSettingMutation>[];
      for (final value in raw) {
        context.checkCurrent();
        final change = agentObject(value, 'change');
        if (change.containsKey('reset') && change['reset'] is! bool) {
          throw const AgentControlException('invalidArguments', 'reset must be a boolean.');
        }
        mutations.add(await _prepare(change['reset'] == true ? 'settings.reset' : 'settings.set', change, context));
      }
      final results = <Map<String, dynamic>>[];
      for (final mutation in mutations) {
        try {
          context.checkCurrent();
          final result = await mutation.apply();
          _recordEffects(result, context, onRootRebuild);
          results.add({'ok': true, 'result': result});
        } catch (error) {
          final failure = error is AgentControlException
              ? error
              : const AgentControlException('commandFailed', 'The setting could not be applied.');
          results.add({'ok': false, 'key': mutation.key, 'scope': mutation.scope, 'error': failure.toJson()});
          throw AgentControlException(
            'batchFailed',
            'The batch stopped after a setting failed.',
            details: {'results': results, 'notAttempted': mutations.length - results.length},
          );
        }
      }
      return {'results': results};
    }
    if (command == 'settings.set' || command == 'settings.reset') {
      final mutation = await _prepare(command, arguments, context);
      context.checkCurrent();
      final result = await mutation.apply();
      _recordEffects(result, context, onRootRebuild);
      return result;
    }
    final scope = agentSettingScope(arguments);
    final Object? result = switch (scope['type']) {
      'app' => await _settings.read(command, arguments, context),
      'player' ||
      'server' ||
      'library' ||
      'profile' ||
      'catalog' => await _scopedSettings.read(command, arguments, context),
      'account' ||
      'syncRule' ||
      'liveTvFavorites' ||
      'dvrRule' => await _resourceSettings.read(command, arguments, context),
      _ => throw const AgentControlException('unsupportedScope', 'The settings scope is not supported.'),
    };
    return command == 'settings.list' && result is Map<String, dynamic>
        ? {...result, 'scopeTypes': scopeTypes}
        : result;
  }

  void _recordEffects(
    Map<String, dynamic> result,
    AgentCommandContext context,
    void Function(AgentCommandContext)? onRootRebuild,
  ) {
    final effects = result['pendingEffects'];
    if (effects is List && effects.contains('rootRebuild')) {
      onRootRebuild?.call(context);
      _lastEffectError = null;
    }
  }

  Future<AgentSettingMutation> _prepare(String command, Map<String, dynamic> arguments, AgentCommandContext context) {
    agentString(arguments, 'key');
    if (command == 'settings.set' && !arguments.containsKey('value')) {
      throw const AgentControlException('invalidArguments', 'Setting a preference requires an explicit value.');
    }
    if (command == 'settings.reset' && arguments.containsKey('value')) {
      throw const AgentControlException('invalidArguments', 'Reset does not accept a value.');
    }
    final scope = agentSettingScope(arguments);
    return switch (scope['type']) {
      'app' => _settings.prepare(command, arguments, context),
      'player' ||
      'server' ||
      'library' ||
      'profile' ||
      'catalog' => _scopedSettings.prepare(command, arguments, context),
      'account' ||
      'syncRule' ||
      'liveTvFavorites' ||
      'dvrRule' => _resourceSettings.prepare(command, arguments, context),
      _ => throw const AgentControlException('unsupportedScope', 'The settings scope is not supported.'),
    };
  }

  Map<String, dynamic> _success(String requestId, Object? result) => {
    'version': protocolVersion,
    'requestId': requestId,
    'sessionToken': _sessionToken,
    'ok': true,
    'result': result,
  };

  Map<String, dynamic> _failure(String? requestId, AgentControlException error) => {
    'version': protocolVersion,
    'requestId': requestId,
    'sessionToken': _sessionToken,
    'ok': false,
    'error': error.toJson(),
  };
}

class _AgentOwner {
  const _AgentOwner(this.owner, this.context, this.uncovered);

  final Object owner;
  final BuildContext? Function() context;
  final bool Function() uncovered;
}
