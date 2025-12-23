import 'package:flutter_discord_rpc/flutter_discord_rpc.dart';
import '../utils/app_logger.dart';
import 'settings_service.dart';

class DiscordRPCService {
  static final DiscordRPCService _instance = DiscordRPCService._internal();

  factory DiscordRPCService() {
    return _instance;
  }

  DiscordRPCService._internal();

  bool _isInitialized = false;
  bool _isEnabled = true;

  // Discord Application ID from environment variables
  // Pass with --dart-define=DISCORD_APP_ID=your_id_here
  static const String _applicationId = String.fromEnvironment('DISCORD_APP_ID');

  Future<void> initialize() async {
    final settings = await SettingsService.getInstance();
    _isEnabled = settings.getEnableDiscordRpc();

    if (!_isEnabled || _isInitialized || _applicationId.isEmpty) {
      if (_applicationId.isEmpty && _isEnabled) {
        appLogger.w('Discord RPC initialized without Application ID. Use --dart-define=DISCORD_APP_ID=...');
      }
      return;
    }

    try {
      await FlutterDiscordRPC.initialize(_applicationId);
      FlutterDiscordRPC.instance.connect();
      _isInitialized = true;
      appLogger.d('Discord RPC initialized');
    } catch (e) {
      appLogger.e('Failed to initialize Discord RPC', error: e);
    }
  }

  Future<void> updateSettings(bool enabled) async {
    if (_isEnabled == enabled) return;
    _isEnabled = enabled;

    if (enabled) {
      await initialize();
    } else {
      dispose();
    }
  }

  void updatePresence({
    required String title,
    String? subtitle,
    String? state,
    int? startTime,
    int? endTime,
    String? largeImageKey,
    String? largeImageText,
    String? smallImageKey,
    String? smallImageText,
  }) {
    if (!_isInitialized || !_isEnabled) return;

    try {
      FlutterDiscordRPC.instance.setActivity(
        activity: RPCActivity(
          details: title,
          state: subtitle ?? state,
          timestamps: (startTime != null || endTime != null)
              ? RPCTimestamps(
                  start: startTime,
                  end: endTime,
                )
              : null,
          // Note: Image keys refer to assets uploaded to the Discord Developer Portal application
          assets: RPCAssets(
            largeImage: largeImageKey,
            largeText: largeImageText,
            smallImage: smallImageKey,
            smallText: smallImageText,
          ),
        ),
      );
    } catch (e) {
      appLogger.w('Failed to update Discord presence', error: e);
    }
  }

  void clearActivity() {
    if (!_isInitialized) return;
    try {
      FlutterDiscordRPC.instance.clearActivity();
    } catch (e) {
      appLogger.w('Failed to clear Discord activity', error: e);
    }
  }

  void dispose() {
    if (_isInitialized) {
      FlutterDiscordRPC.instance.disconnect();
      FlutterDiscordRPC.instance.dispose();
      _isInitialized = false;
    }
  }
}
