class RemoteAuthContext {
  const RemoteAuthContext({
    required this.id,
    required this.backend,
    required this.connectionId,
    required this.homeSecret,
    required this.discoveryKey,
    required this.clientIdentifier,
    required this.userUuid,
    required this.allowedUserUuids,
  });

  final String id;
  final String backend;
  final String connectionId;
  final List<int> homeSecret;
  final List<int> discoveryKey;
  final String clientIdentifier;
  final String userUuid;
  final List<String> allowedUserUuids;
}
