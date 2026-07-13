import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/companion_remote/remote_command.dart';

void main() {
  test('playMedia round-trips its payload through JSON', () {
    const command = RemoteCommand(type: RemoteCommandType.playMedia, data: {'serverId': 'srv1', 'ratingKey': '42'});

    final decoded = RemoteCommand.fromJson(command.toJson());

    expect(decoded.type, RemoteCommandType.playMedia);
    expect(decoded.data, {'serverId': 'srv1', 'ratingKey': '42'});
  });

  test('out-of-range command index decodes to ping so older clients ignore unknown commands', () {
    final decoded = RemoteCommand.fromJson({'t': 9999});

    expect(decoded.type, RemoteCommandType.ping);
  });
}
