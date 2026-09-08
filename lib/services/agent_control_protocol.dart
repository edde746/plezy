import 'package:flutter/widgets.dart';

/// Payload-safe command failure. Never put provider URLs, credentials or raw
/// exceptions in [message] or [details].
class AgentControlException implements Exception {
  const AgentControlException(this.code, this.message, {this.details});

  final String code;
  final String message;
  final Map<String, dynamic>? details;

  Map<String, dynamic> toJson() => {'code': code, 'message': message, if (details != null) 'details': details};
}

/// Captured command lifetime, not an alternative provider or session owner.
class AgentCommandContext {
  const AgentCommandContext({
    required this.context,
    required this.requestId,
    required this.sessionToken,
    required this.hasProfile,
    required this.isCurrent,
  });

  final BuildContext context;
  final String requestId;
  final String? sessionToken;
  final bool hasProfile;
  final bool Function() isCurrent;

  void checkCurrent({bool requireProfile = false}) {
    if (!context.mounted || !isCurrent()) {
      throw const AgentControlException('sessionChanged', 'The application session changed.');
    }
    if (requireProfile && !hasProfile) {
      throw const AgentControlException('noActiveSession', 'An active profile session is required.');
    }
  }
}

/// Prepared and validated before a batch starts writing. The owner still checks
/// the captured session immediately before every asynchronous commit.
class AgentSettingMutation {
  const AgentSettingMutation({required this.key, required this.scope, required this.apply});

  final String key;
  final Map<String, dynamic> scope;
  final Future<Map<String, dynamic>> Function() apply;
}

Map<String, dynamic> agentObject(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  throw AgentControlException('invalidArguments', '$field must be an object.');
}

String agentString(Map<String, dynamic> arguments, String key) {
  final value = arguments[key];
  if (value is String && value.trim().isNotEmpty) return value;
  throw AgentControlException('invalidArguments', '$key must be a nonempty string.');
}

Map<String, dynamic> agentSettingScope(Map<String, dynamic> arguments) {
  final raw = arguments['scope'];
  if (raw == null) return const {'type': 'app'};
  final scope = agentObject(raw, 'scope');
  agentString(scope, 'type');
  return scope;
}
