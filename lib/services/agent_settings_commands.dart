import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../models/external_player_models.dart';
import '../models/hotkey_model.dart';
import '../models/shader_preset.dart';
import '../navigation/navigation_tabs.dart';
import '../providers/download_provider.dart';
import '../providers/companion_remote_provider.dart';
import '../providers/shader_provider.dart';
import '../utils/platform_detector.dart';
import 'agent_control_protocol.dart';
import 'discord_rpc_service.dart';
import 'download_storage_service.dart';
import 'keyboard_shortcuts_service.dart';
import 'music/music_playback_service.dart';
import 'saf_storage_service.dart';
import 'scoped_player_prefs.dart';
import 'settings_mutation_service.dart';
import 'settings_service.dart';
import 'shader_service.dart';
import 'shortcut_action.dart';
import 'update_service.dart';

/// Typed app configuration over the existing preferences and resource owners.
/// Discovery never reads user-authored documents, paths or integration endpoints.
class AgentSettingsCommands {
  const AgentSettingsCommands();

  static const maxResourceBytes = 512 * 1024;
  static const _scope = <String, dynamic>{'type': 'app'};
  static final _prefs = {for (final pref in SettingsService.editableAppPrefs) pref.key: pref};
  static const _resources = {
    'keyboard_hotkeys',
    'mpv_config_presets',
    'custom_shaders',
    'global_shader_preset',
    'external_players',
    'selected_external_player',
    'download_location',
  };

  Future<Object?> read(String command, Map<String, dynamic> arguments, AgentCommandContext context) async {
    context.checkCurrent();
    _checkScope(arguments);
    if (command == 'settings.list') {
      return {
        'scope': _scope,
        'settings': [
          for (final pref in _prefs.values) _descriptor(pref, context.context),
          for (final key in _resources) _resourceDescriptor(key, context.context),
        ],
      };
    }
    if (command != 'settings.get') {
      throw const AgentControlException('unsupportedCommand', 'Unsupported settings read.');
    }
    final key = agentString(arguments, 'key');
    _requireKey(key);
    return _result(key, context);
  }

  Future<AgentSettingMutation> prepare(
    String command,
    Map<String, dynamic> arguments,
    AgentCommandContext context,
  ) async {
    context.checkCurrent();
    _checkScope(arguments);
    if (command != 'settings.set' && command != 'settings.reset') {
      throw const AgentControlException('unsupportedCommand', 'Unsupported settings mutation.');
    }
    final key = agentString(arguments, 'key');
    _requireKey(key);
    _checkSupported(key, context.context);
    final reset =
        command == 'settings.reset' ||
        (key == 'download_location' && arguments.containsKey('value') && arguments['value'] == null);
    if (!reset && !arguments.containsKey('value')) {
      throw const AgentControlException(
        'invalidArguments',
        'value is required; use null explicitly for nullable settings.',
      );
    }
    try {
      final pref = _prefs[key];
      if (pref != null) {
        final value = reset ? pref.resolvedDefault : pref.fromJson(arguments['value']);
        if (!reset) {
          SettingsService.validateEditableValue(pref, value);
          _validatePlatformValue(key, value);
          if (value is String && utf8.encode(value).length > maxResourceBytes) {
            throw const AgentControlException('invalidArguments', 'Text exceeds the 512 KiB limit.');
          }
        }
        return _mutation(key, context, () async {
          final settings = SettingsService.instance;
          context.checkCurrent();
          _checkSupported(key, context.context);
          try {
            if (reset) {
              await settings.reset(pref, checkCurrent: context.checkCurrent);
            } else {
              await settings.write(pref, value, checkCurrent: context.checkCurrent);
            }
          } on AgentControlException {
            rethrow;
          } catch (_) {
            throw const AgentControlException(
              'persistenceFailed',
              'The preference could not be saved.',
              details: {'persisted': false, 'cacheMayDiffer': true},
            );
          }
          context.checkCurrent();
          if (key == 'enable_companion_remote_server' && value == true && !context.hasProfile) return;
          if (!context.context.mounted) return;
          try {
            await const SettingsMutationService().applyEffects(
              context.context,
              pref,
              checkCurrent: context.checkCurrent,
              rebuildRoot: false,
            );
          } on AgentControlException {
            rethrow;
          } catch (_) {
            throw const AgentControlException(
              'effectFailed',
              'The preference was saved but its runtime effect failed.',
              details: {'persisted': true},
            );
          }
        });
      }
      return await _prepareResource(key, arguments['value'], reset, context);
    } on AgentControlException {
      rethrow;
    } on HotkeyConflictException catch (error) {
      throw AgentControlException(
        'invalidArguments',
        'A shortcut is already assigned.',
        details: {'action': error.action},
      );
    } catch (_) {
      throw const AgentControlException('invalidArguments', 'The setting value does not match its domain schema.');
    }
  }

  static void _checkScope(Map<String, dynamic> arguments) {
    final scope = agentSettingScope(arguments);
    if (scope['type'] != 'app' || scope.length != 1) {
      throw const AgentControlException('invalidArguments', 'App settings require scope {type: app}.');
    }
  }

  static void _requireKey(String key) {
    if (!_prefs.containsKey(key) && !_resources.contains(key)) {
      throw const AgentControlException('unknownSetting', 'Unknown user-editable app setting.');
    }
  }

  static void _checkSupported(String key, BuildContext context) {
    final reason = unsupportedReason(key, context);
    if (reason != null) throw AgentControlException('unsupportedSetting', reason);
  }

  /// Mirrors the existing settings surface and backend capabilities, without
  /// enabling any native feature that the selected player does not implement.
  static String? unsupportedReason(String key, BuildContext context) {
    final tv = PlatformDetector.isTV();
    final desktop = PlatformDetector.isDesktopOS();
    final mobile = (Platform.isAndroid || Platform.isIOS) && !tv;
    final exo = Platform.isAndroid && SettingsService.instance.read(SettingsService.useExoPlayer);
    switch (key) {
      case 'keyboard_hotkeys':
        if (!KeyboardShortcutsService.isPlatformSupported()) {
          return 'Keyboard customization requires a desktop platform.';
        }
      case 'enable_discord_rpc':
        if (!DiscordRPCService.isAvailable) return 'Discord rich presence is unavailable on this platform.';
      case 'auto_check_updates_on_startup':
        if (!UpdateService.isUpdateCheckAvailable) return 'Updates are managed externally on this platform.';
      case 'force_tv_mode':
        if (!desktop && !Platform.isAndroid) return 'Forced TV mode requires Android or a desktop platform.';
      case 'visual_effects':
        if (!Platform.isAndroid) return 'Visual-effects tier selection is Android-only.';
      case 'automotive_ui_scale':
        if (!PlatformDetector.isAutomotive()) return 'Display scale customization is for automotive displays.';
      case 'tv_full_card_layout' || 'tv_corner_spotlight_backdrop' || 'focus_glow':
        if (!tv) return 'This setting is used by the TV layout.';
      case 'show_hero_section' || 'show_season_posters_on_tabs':
        if (tv) return 'This setting is not used by the TV layout.';
      case 'always_keep_sidebar_open' || 'group_libraries_by_server' || 'libraries_section_expanded':
        if (!PlatformDetector.shouldUseSideNavigation(context)) return 'This setting requires the sidebar layout.';
      case 'show_nav_bar_labels':
        if (PlatformDetector.shouldUseSideNavigation(context)) return 'This setting requires bottom navigation.';
      case 'enable_companion_remote_server':
        if (!PlatformDetector.shouldActAsRemoteHost(context)) {
          return 'This device is a companion controller, not a host.';
        }
      case 'start_in_fullscreen' || 'exit_fullscreen_on_player_close' || 'player_always_on_top':
        if (!desktop) return 'Window behavior requires a desktop platform.';
      case 'auto_pip':
        if (!PlatformDetector.supportsPictureInPicture()) return 'Picture in picture is unavailable on this device.';
      case 'use_external_player' || 'external_players' || 'selected_external_player':
        if (!PlatformDetector.supportsExternalPlayers()) return 'External players are unavailable on this device.';
      case 'audio_passthrough':
        if (!PlatformDetector.supportsAudioPassthrough()) return 'Audio passthrough is unavailable on this device.';
      case 'android_use_exoplayer' || 'match_content_frame_rate' || 'dv_conversion_mode':
        if (!Platform.isAndroid) return 'This setting is Android-only.';
      case 'match_content_resolution':
        if (!Platform.isAndroid || !tv) return 'Content resolution matching requires Android TV.';
      case 'match_refresh_rate' || 'match_dynamic_range':
        if (!Platform.isWindows) return 'This display matching setting is Windows-only.';
      case 'display_switch_delay':
        if (!PlatformDetector.isAppleTV() && !Platform.isWindows && !Platform.isAndroid) {
          return 'Display switching delay is unavailable on this platform.';
        }
      case 'enable_hdr':
        if (Platform.isAndroid) return 'Android HDR output is controlled by the platform, not this setting.';
      case 'ambient_lighting':
        if (exo || Platform.isIOS) return 'Ambient lighting requires mpv on a non-Apple-mobile platform.';
      case 'hdr_tone_mapping':
        if (!Platform.isLinux) return 'HDR tone mapping selection requires the Linux native video plane.';
      case 'tunneled_playback' || 'playback_buffer_tier' || 'subtitle_anchor_to_screen':
        if (!exo) return 'This setting requires the existing Android ExoPlayer backend.';
      case 'custom_shaders' || 'global_shader_preset':
        if (exo || !ShaderService.isPlatformSupported) {
          return 'Shaders are unavailable on the current platform or player backend.';
        }
      case 'mpv_config_text' || 'mpv_config_presets' || 'deinterlace' || 'subtitle_use_margins':
        if (exo) return 'This setting requires the mpv backend.';
      case 'subtitle_render_resolution':
        if (!Platform.isAndroid && !Platform.isIOS) return 'Subtitle render resolution is Android/Apple-only.';
      case 'gesture_brightness_swipe' ||
          'gesture_volume_swipe' ||
          'gesture_pinch_to_zoom' ||
          'remember_brightness_level' ||
          'remembered_brightness_level' ||
          'rotation_locked' ||
          'cellular_quality_preset':
        if (!mobile) return 'This setting requires a mobile device.';
      case 'click_video_toggles_playback':
        if (mobile) return 'Mobile playback uses touch gestures instead.';
      case 'download_location':
        if (Platform.isIOS) return 'Apple sandbox download location selection is not supported by the current app.';
      case 'download_on_wifi_only' || 'auto_remove_watched_downloads' || 'download_include_specials':
        if (PlatformDetector.isAppleTV()) return 'Downloads are unavailable on Apple TV.';
    }
    return null;
  }

  static void _validatePlatformValue(String key, Object? value) {
    if (key == 'subtitle_render_resolution') {
      final choices = Platform.isIOS
          ? [SubtitleRenderResolution.screen, SubtitleRenderResolution.video]
          : [
              SubtitleRenderResolution.screen,
              SubtitleRenderResolution.threeQuarter,
              SubtitleRenderResolution.half,
              SubtitleRenderResolution.third,
              SubtitleRenderResolution.quarter,
            ];
      if (!choices.contains(value)) throw const FormatException('Unsupported subtitle resolution on this platform');
    }
    if ((key == 'audio_sync_offset' || key == 'subtitle_sync_offset') &&
        value is int &&
        (value < ScopedPlayerPrefs.minimumSyncOffsetMs || value > ScopedPlayerPrefs.maximumSyncOffsetMs)) {
      throw const FormatException('Sync offset is outside the supported range');
    }
  }

  static String _application(String key) {
    if (key == 'app_locale' || key == 'force_tv_mode' || key == 'visual_effects') return 'rootRebuild';
    if (key == 'start_in_fullscreen' ||
        key == 'startup_section' ||
        key == 'require_profile_selection_on_open' ||
        key == 'resume_music_on_launch') {
      return 'processRestart';
    }
    if (key == 'custom_relay_url') return 'nextConnection';
    if (key == 'download_location') return 'nextDownload';
    if (_nextPlayback.contains(key)) return 'nextPlayback';
    return 'immediate';
  }

  static const _nextPlayback = {
    'enable_hardware_decoding',
    'enable_hdr',
    'hdr_tone_mapping',
    'audio_sync_offset',
    'subtitle_sync_offset',
    'subtitle_search_language',
    'volume',
    'subtitle_font_size',
    'subtitle_text_color',
    'subtitle_border_size',
    'subtitle_border_color',
    'subtitle_background_color',
    'subtitle_background_opacity',
    'sub_ass_override',
    'subtitle_render_resolution',
    'subtitle_bold',
    'subtitle_italic',
    'subtitle_anchor_to_screen',
    'subtitle_use_margins',
    'match_content_frame_rate',
    'match_content_resolution',
    'tunneled_playback',
    'dv_conversion_mode',
    'default_quality_preset',
    'cellular_quality_preset',
    'music_quality_preset',
    'direct_play_covered_quality',
    'audio_passthrough',
    'audio_normalization',
    'audio_downmix',
    'audio_downmix_normalize',
    'max_volume',
    'downmix_center_boost',
    'subtitle_position',
    'default_playback_speed',
    'default_box_fit_mode',
    'global_shader_preset',
    'custom_shaders',
    'mpv_config_text',
    'mpv_config_presets',
    'use_external_player',
    'external_players',
    'selected_external_player',
    'android_use_exoplayer',
    'playback_buffer_tier',
    'deinterlace',
    'player_always_on_top',
    'match_refresh_rate',
    'match_dynamic_range',
    'display_switch_delay',
    'remember_brightness_level',
    'remembered_brightness_level',
    'ambient_lighting',
    'rotation_locked',
  };

  static Map<String, dynamic> _descriptor(Pref<Object?> pref, BuildContext context) {
    final bounds = pref == SettingsService.audioSyncOffset || pref == SettingsService.subtitleSyncOffset
        ? (ScopedPlayerPrefs.minimumSyncOffsetMs, ScopedPlayerPrefs.maximumSyncOffsetMs)
        : SettingsService.numericBounds(pref);
    final reason = unsupportedReason(pref.key, context);
    var choices = pref.jsonChoices;
    if (pref == SettingsService.startupSection) {
      choices = [
        NavigationTabId.discover.name,
        NavigationTabId.libraries.name,
        NavigationTabId.liveTv.name,
        NavigationTabId.search.name,
      ];
    }
    if (pref == SettingsService.subtitleRenderResolution && (Platform.isIOS || Platform.isAndroid)) {
      choices =
          (Platform.isIOS
                  ? [SubtitleRenderResolution.screen, SubtitleRenderResolution.video]
                  : [
                      SubtitleRenderResolution.screen,
                      SubtitleRenderResolution.threeQuarter,
                      SubtitleRenderResolution.half,
                      SubtitleRenderResolution.third,
                      SubtitleRenderResolution.quarter,
                    ])
              .map((v) => v.name)
              .toList();
    }
    return {
      'key': pref.key,
      'type': pref.jsonType,
      'default': pref.toJson(pref.resolvedDefault),
      'choices': ?choices,
      'constraints': {
        if (bounds != null) ...{'min': bounds.$1, 'max': bounds.$2},
        if (pref == SettingsService.introPattern || pref == SettingsService.creditsPattern)
          'format': 'nonempty regular expression',
        if (pref == SettingsService.subtitleTextColor ||
            pref == SettingsService.subtitleBorderColor ||
            pref == SettingsService.subtitleBackgroundColor)
          'format': '#RRGGBB',
        if (pref == SettingsService.subtitleSearchLanguage) 'format': 'ISO 639 language code or null',
        if (pref == SettingsService.customRelayUrl)
          'format': 'HTTP(S) base URL without user info, query or fragment; null uses the default relay',
        if (pref.jsonType == 'string' || pref.jsonType == 'string|null') 'maxUtf8Bytes': maxResourceBytes,
        if (pref is StringListPref) ...{'items': 'unique nonempty identifiers', 'uniqueItems': true},
      },
      'applicability': {'supported': reason == null, 'reason': ?reason},
      'application': _application(pref.key),
      if (pref == SettingsService.crashReporting)
        'note': 'Controls event submission; reporting must also be compiled into this build.',
      if (pref == SettingsService.directPlayCoveredQuality) 'note': 'Only Plex uses this startup quality decision.',
      if (pref == SettingsService.customRelayUrl || pref == SettingsService.mpvConfigText)
        'valueRequiresExplicitGet': true,
    };
  }

  static Map<String, dynamic> _resourceDescriptor(String key, BuildContext context) {
    final reason = unsupportedReason(key, context);
    final (type, defaultValue, schema) = switch (key) {
      'keyboard_hotkeys' => (
        'object',
        _hotkeysJson(SettingsService.keyboardHotkeys.resolvedDefault),
        {
          'actions': ShortcutAction.values.map((a) => a.id).toList(),
          'binding': {'key': '8-digit USB HID hex', 'modifiers': HotKeyModifier.values.map((m) => m.name).toList()},
          'nullDisables': true,
          'missingUsesDefault': true,
          'uniqueBindings': true,
        },
      ),
      'mpv_config_presets' => (
        'object',
        {
          'presets': [
            for (final p in SettingsService.mpvPresets.resolvedDefault) {'name': p.name, 'text': p.text},
          ],
        },
        {
          'presets': [
            {'name': 'unique nonempty string', 'text': 'full mpv document'},
          ],
          'maxTextBytes': maxResourceBytes,
        },
      ),
      'custom_shaders' => (
        'object',
        {'presets': SettingsService.customShaderPresets.resolvedDefault},
        {
          'oneOf': [
            {
              'import': {'fileName': 'safe .glsl filename', 'name': 'display name', 'base64': 'file bytes'},
            },
            {'delete': 'custom preset id'},
          ],
          'maxFileBytes': maxResourceBytes,
        },
      ),
      'global_shader_preset' => (
        'string',
        SettingsService.globalShaderPreset.resolvedDefault,
        {'builtInChoices': ShaderPreset.allPresets.map((p) => p.id).toList(), 'customChoicesFrom': 'custom_shaders'},
      ),
      'external_players' => (
        'object',
        {
          'players': [for (final p in SettingsService.customExternalPlayers.resolvedDefault) _playerJson(p)],
        },
        {
          'players': [
            {
              'id': 'unique custom identifier',
              'name': 'display name',
              'type': ['command', 'urlScheme'],
              'value': 'command, Android package or URL scheme',
            },
          ],
        },
      ),
      'selected_external_player' => (
        'object',
        {'id': SettingsService.selectedExternalPlayer.resolvedDefault.id},
        {'id': 'available known or configured custom player id'},
      ),
      'download_location' => (
        'object|null',
        null,
        {
          'path': 'device-local absolute path or authorized SAF URI',
          'type': ['file', 'saf'],
          'requiresExistingAccess': true,
        },
      ),
      _ => throw StateError('Unknown resource'),
    };
    return {
      'key': key,
      'type': type,
      'default': defaultValue,
      'constraints': schema,
      'applicability': {'supported': reason == null, 'reason': ?reason},
      'application': _application(key),
      if (key == 'custom_shaders' || key == 'global_shader_preset' || key == 'download_location')
        'requiresProfile': true,
      if (key != 'global_shader_preset') 'valueRequiresExplicitGet': true,
    };
  }

  Future<Map<String, dynamic>> _result(String key, AgentCommandContext context) async {
    final settings = SettingsService.instance;
    final pref = _prefs[key];
    final musicOwner = key == 'music_volume' ? context.context.read<MusicPlaybackService?>() : null;
    final companionOwner = key == 'enable_companion_remote_server'
        ? context.context.read<CompanionRemoteProvider?>()
        : null;
    final Object? value;
    final bool hasOverride;
    final additional = <String, dynamic>{};
    if (pref != null) {
      value = pref.toJson(settings.read(pref));
      hasOverride = settings.prefs.containsKey(pref.key);
    } else {
      switch (key) {
        case 'keyboard_hotkeys':
          value = _hotkeysJson(settings.read(SettingsService.keyboardHotkeys));
          hasOverride = settings.prefs.containsKey(SettingsService.keyboardHotkeys.key);
        case 'mpv_config_presets':
          value = {
            'presets': [
              for (final p in settings.read(SettingsService.mpvPresets)) {'name': p.name, 'text': p.text},
            ],
          };
          hasOverride = settings.prefs.containsKey(SettingsService.mpvPresets.key);
        case 'external_players':
          value = {
            'players': [for (final p in settings.read(SettingsService.customExternalPlayers)) _playerJson(p)],
          };
          hasOverride = settings.prefs.containsKey(SettingsService.customExternalPlayers.key);
        case 'selected_external_player':
          final known = await KnownPlayers.getForCurrentPlatform();
          context.checkCurrent();
          value = {'id': settings.read(SettingsService.selectedExternalPlayer).id};
          additional['available'] = [
            for (final p in [...known, ...settings.read(SettingsService.customExternalPlayers)])
              {'id': p.id, 'name': p.name},
          ];
          hasOverride = settings.prefs.containsKey(SettingsService.selectedExternalPlayer.key);
        case 'custom_shaders':
          context.checkCurrent(requireProfile: true);
          final provider = _shaders(context);
          value = {
            'presets': [
              for (final preset in provider.customPresets)
                {'id': preset.id, 'name': preset.name, 'fileName': preset.fileName},
            ],
          };
          hasOverride = settings.prefs.containsKey(SettingsService.customShaderPresets.key);
        case 'global_shader_preset':
          value = settings.read(SettingsService.globalShaderPreset);
          hasOverride = settings.prefs.containsKey(SettingsService.globalShaderPreset.key);
        case 'download_location':
          final location = settings.read(SettingsService.customDownloadPath);
          value = location == null
              ? null
              : {'path': location, 'type': settings.read(SettingsService.customDownloadPathType) ?? 'file'};
          hasOverride =
              settings.prefs.containsKey(SettingsService.customDownloadPath.key) ||
              settings.prefs.containsKey(SettingsService.customDownloadPathType.key);
        default:
          throw const AgentControlException('unknownSetting', 'Unknown app setting.');
      }
    }
    context.checkCurrent();
    final needsProfileSession =
        (key == 'enable_companion_remote_server' && value == true && !context.hasProfile) ||
        (key == 'music_volume' && musicOwner == null);
    final application = needsProfileSession ? 'nextProfileSession' : _application(key);
    final runtime = <String, dynamic>{
      'state': application == 'immediate' ? 'ownerManaged' : 'deferred',
      if (application == 'nextPlayback')
        'note': 'Saved default; this does not apply native properties to an already running player.',
    };
    if (key == 'enable_discord_rpc') {
      final owner = DiscordRPCService.instance;
      runtime.addAll({
        'enabled': owner.isEnabled,
        'connected': owner.isConnected,
        'state': owner.isEnabled && !owner.isConnected ? 'waitingForDiscord' : 'applied',
      });
    }
    if (key == 'enable_companion_remote_server') {
      final owner = companionOwner;
      runtime.addAll({
        'hostRunning': owner?.isHostServerRunning ?? false,
        'state': application == 'nextProfileSession'
            ? 'pendingProfileSession'
            : owner?.status.name ?? 'ownerUnavailable',
        if (settings.read(SettingsService.enableCompanionRemoteServer) && owner?.isCryptoReady != true)
          'blocker': 'An active companion-compatible account identity is required.',
      });
    }
    if (key == 'music_volume') {
      final owner = musicOwner;
      runtime.addAll({
        'state': owner == null ? 'pendingProfileSession' : 'applied',
        if (owner != null) 'ownerVolume': owner.volume,
      });
    }
    return {
      'key': key,
      'scope': _scope,
      'value': value,
      'hasOverride': hasOverride,
      'storedOverride': hasOverride ? (pref == null ? value : settings.prefs.get(pref.key)) : null,
      'application': application,
      'runtime': runtime,
      ...additional,
    };
  }

  AgentSettingMutation _mutation(
    String key,
    AgentCommandContext context,
    Future<void> Function() apply,
  ) => AgentSettingMutation(
    key: key,
    scope: _scope,
    apply: () async {
      context.checkCurrent();
      _checkSupported(key, context.context);
      try {
        await apply();
        context.checkCurrent();
        final result = await _result(key, context);
        return {
          ...result,
          'persisted': true,
          if (_application(key) == 'rootRebuild') 'pendingEffects': ['rootRebuild'],
          if (_application(key) == 'processRestart') 'pendingEffects': ['processRestart'],
          if (result['application'] == 'nextProfileSession') 'pendingEffects': ['profileSession'],
        };
      } on AgentControlException {
        rethrow;
      } on DownloadStorageException {
        throw const AgentControlException(
          'storageUnavailable',
          'The download location could not be accessed. Use the native folder picker to authorize access where required.',
          details: {'persisted': 'unknown', 'cacheMayDiffer': true},
        );
      } catch (_) {
        throw const AgentControlException(
          'mutationFailed',
          'The resource owner could not complete the setting change.',
          details: {'persisted': 'unknown', 'cacheMayDiffer': true},
        );
      }
    },
  );

  Future<AgentSettingMutation> _prepareResource(
    String key,
    Object? raw,
    bool reset,
    AgentCommandContext context,
  ) async {
    final settings = SettingsService.instance;
    switch (key) {
      case 'keyboard_hotkeys':
        final value = reset
            ? SettingsService.keyboardHotkeys.resolvedDefault
            : KeyboardShortcutsService.hotkeysFromJson(raw);
        return _mutation(key, context, () async {
          final owner = await KeyboardShortcutsService.getInstance();
          context.checkCurrent();
          if (reset) {
            await owner.resetToDefaults(checkCurrent: context.checkCurrent);
          } else {
            await owner.replaceHotkeys(value, checkCurrent: context.checkCurrent);
          }
        });
      case 'mpv_config_presets':
        final values = <({String name, String text})>[];
        if (!reset) {
          final map = _object(raw, {'presets'});
          final names = <String>{};
          for (final item in map['presets'] as List) {
            final preset = _object(item, {'name', 'text'});
            final name = agentString(preset, 'name').trim();
            final text = preset['text'] as String;
            if (!names.add(name) || utf8.encode(text).length > maxResourceBytes) {
              throw const FormatException('Invalid preset');
            }
            values.add((name: name, text: text));
          }
        }
        return _mutation(
          key,
          context,
          () => reset
              ? settings.reset(SettingsService.mpvPresets, checkCurrent: context.checkCurrent)
              : settings.replaceMpvPresets(values, checkCurrent: context.checkCurrent),
        );
      case 'external_players':
        final players = <ExternalPlayer>[];
        if (!reset) {
          final map = _object(raw, {'players'});
          for (final item in map['players'] as List) {
            final player = _object(item, {'id', 'name', 'type', 'value'});
            final type = CustomPlayerType.values.firstWhere((t) => t.name == player['type']);
            players.add(
              ExternalPlayer.custom(
                id: agentString(player, 'id'),
                name: agentString(player, 'name').trim(),
                value: agentString(player, 'value').trim(),
                type: type,
              ),
            );
          }
          SettingsService.validateCustomExternalPlayers(players);
        }
        return _mutation(
          key,
          context,
          () =>
              settings.replaceCustomExternalPlayers(players, checkCurrent: context.checkCurrent, resetOverride: reset),
        );
      case 'selected_external_player':
        final id = reset
            ? SettingsService.selectedExternalPlayer.resolvedDefault.id
            : agentString(_object(raw, {'id'}), 'id');
        final available = await KnownPlayers.getForCurrentPlatform();
        context.checkCurrent();
        ExternalPlayer? selected;
        for (final player in [...available, ...settings.read(SettingsService.customExternalPlayers)]) {
          if (player.id == id) selected = player;
        }
        if (selected == null) {
          throw const AgentControlException('invalidArguments', 'The selected player is not available.');
        }
        final player = selected;
        return _mutation(
          key,
          context,
          () => settings.selectExternalPlayer(player, checkCurrent: context.checkCurrent, resetOverride: reset),
        );
      case 'global_shader_preset':
        context.checkCurrent(requireProfile: true);
        final owner = _shaders(context);
        final id = reset ? SettingsService.globalShaderPreset.resolvedDefault : raw as String;
        final preset = owner.findPresetById(id);
        if (preset == null) throw const AgentControlException('invalidArguments', 'Unknown shader preset.');
        return _mutation(key, context, () {
          _checkShaderOwner(context, owner);
          if (owner.findPresetById(id) == null) {
            throw const AgentControlException('resourceChanged', 'The shader was removed.');
          }
          return owner.setPreset(preset, checkCurrent: () => _checkShaderOwner(context, owner), reset: reset);
        });
      case 'custom_shaders':
        context.checkCurrent(requireProfile: true);
        final owner = _shaders(context);
        if (reset) {
          return _mutation(key, context, () async {
            _checkShaderOwner(context, owner);
            for (final preset in owner.customPresets.toList()) {
              await owner.deleteCustomShader(preset, checkCurrent: () => _checkShaderOwner(context, owner));
            }
            _checkShaderOwner(context, owner);
            await settings.reset(
              SettingsService.customShaderPresets,
              checkCurrent: () => _checkShaderOwner(context, owner),
            );
          });
        }
        final map = _object(raw, {'import', 'delete'}, exact: false);
        if (map.length != 1) throw const FormatException('Choose import or delete');
        if (map.containsKey('delete')) {
          final id = agentString(map, 'delete');
          final preset = owner.customPresets.where((p) => p.id == id).firstOrNull;
          if (preset == null) throw const AgentControlException('invalidArguments', 'Unknown custom shader.');
          return _mutation(
            key,
            context,
            () => owner.deleteCustomShader(preset, checkCurrent: () => _checkShaderOwner(context, owner)),
          );
        }
        final input = _object(map['import'], {'name', 'fileName', 'base64'});
        final name = agentString(input, 'name').trim();
        final fileName = agentString(input, 'fileName');
        if (fileName.length > 128 ||
            fileName.startsWith('.') ||
            !RegExp(r'^[^<>:"/\\|?*\x00-\x1f]+\.glsl$', caseSensitive: false).hasMatch(fileName)) {
          throw const FormatException('Expected a safe .glsl filename');
        }
        final encoded = agentString(input, 'base64');
        if (encoded.length > ((maxResourceBytes + 2) ~/ 3) * 4) throw const FormatException('Shader too large');
        final bytes = base64Decode(encoded);
        if (bytes.isEmpty || bytes.length > maxResourceBytes) throw const FormatException('Invalid shader file size');
        return _mutation(key, context, () => _importShader(owner, context, fileName, name, bytes));
      case 'download_location':
        context.checkCurrent(requireProfile: true);
        final owner = context.context.read<DownloadProvider?>();
        if (owner == null) throw const AgentControlException('notReady', 'The download owner is unavailable.');
        String? location;
        String? type;
        if (!reset) {
          final map = _object(raw, {'path', 'type'});
          location = agentString(map, 'path');
          type = agentString(map, 'type');
          if (type == 'saf') {
            if (!Platform.isAndroid || Uri.tryParse(location)?.scheme != 'content') {
              throw const FormatException('Invalid SAF location');
            }
            final grant = await SafStorageService.instance.resolvePersistedPermissionUri(location);
            context.checkCurrent(requireProfile: true);
            if (grant == null) {
              throw const AgentControlException(
                'permissionRequired',
                'Select this folder in the native Android directory picker first.',
              );
            }
          } else if (type == 'file') {
            if (Platform.isAndroid) {
              throw const AgentControlException(
                'permissionRequired',
                'Android download locations require an existing SAF grant from the native folder picker.',
              );
            }
            if (!path.isAbsolute(location) || location.contains('\u0000')) {
              throw const FormatException('Expected an absolute device path');
            }
          } else {
            throw const FormatException('Unknown download location type');
          }
        }
        void checkOwner() {
          context.checkCurrent(requireProfile: true);
          if (!identical(context.context.read<DownloadProvider>(), owner)) {
            throw const AgentControlException('sessionChanged', 'The download owner changed.');
          }
        }
        return _mutation(key, context, () {
          checkOwner();
          return reset
              ? owner.resetDownloadLocation(checkCurrent: checkOwner)
              : owner.setDownloadLocation(path: location!, pathType: type!, checkCurrent: checkOwner);
        });
      default:
        throw const AgentControlException('unknownSetting', 'Unknown resource setting.');
    }
  }

  static Map<String, dynamic> _object(Object? raw, Set<String> keys, {bool exact = true}) {
    final map = agentObject(raw, 'value');
    if (map.keys.any((key) => !keys.contains(key)) || (exact && map.length != keys.length)) {
      throw const AgentControlException('invalidArguments', 'The resource object has missing or unknown fields.');
    }
    return map;
  }

  static Map<String, dynamic> _hotkeysJson(Map<String, HotKey?> values) => {
    for (final entry in values.entries)
      entry.key: entry.value == null ? null : SettingsService.serializeHotKey(entry.value!),
  };

  static Map<String, dynamic> _playerJson(ExternalPlayer player) => {
    'id': player.id,
    'name': player.name,
    'type': player.customType?.name,
    'value': player.customValue,
  };

  static ShaderProvider _shaders(AgentCommandContext context) {
    final owner = context.context.read<ShaderProvider?>();
    if (owner == null || !owner.initialized) {
      throw const AgentControlException('notReady', 'The shader owner is still loading.');
    }
    return owner;
  }

  static void _checkShaderOwner(AgentCommandContext context, ShaderProvider owner) {
    context.checkCurrent(requireProfile: true);
    if (!identical(context.context.read<ShaderProvider>(), owner)) {
      throw const AgentControlException('sessionChanged', 'The shader owner changed.');
    }
  }

  static Future<void> _importShader(
    ShaderProvider owner,
    AgentCommandContext context,
    String fileName,
    String name,
    Uint8List bytes,
  ) async {
    _checkShaderOwner(context, owner);
    final temporary = await Directory.systemTemp.createTemp('plezy-agent-shader-');
    try {
      _checkShaderOwner(context, owner);
      final input = File(path.join(temporary.path, fileName));
      await input.writeAsBytes(bytes, flush: true);
      _checkShaderOwner(context, owner);
      await owner.importCustomShader(input.path, name, checkCurrent: () => _checkShaderOwner(context, owner));
    } finally {
      // Delete only the unique directory and transferred input owned by this call.
      await temporary.delete(recursive: true);
    }
  }
}
