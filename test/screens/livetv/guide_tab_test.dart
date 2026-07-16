import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/dpad_navigator.dart';
import 'package:plezy/focus/dpad_select_long_press_controller.dart';
import 'package:plezy/models/livetv_channel.dart';
import 'package:plezy/models/livetv_program.dart';
import 'package:plezy/screens/livetv/tabs/guide_tab.dart';

const _selectDown = KeyDownEvent(
  physicalKey: PhysicalKeyboardKey.enter,
  logicalKey: LogicalKeyboardKey.enter,
  timeStamp: Duration.zero,
);

LiveTvChannel _channel({String key = 'channel/7'}) =>
    LiveTvChannel(key: key, identifier: 'station-7', callSign: 'SEVEN', serverId: 'server-a', liveDvrKey: 'dvr-a');

LiveTvProgram _program({String ratingKey = 'program/42', int beginsAt = 1_800_000_000, int endsAt = 1_800_003_600}) =>
    LiveTvProgram(
      ratingKey: ratingKey,
      title: 'Evening News',
      beginsAt: beginsAt,
      endsAt: endsAt,
      channelIdentifier: 'station-7',
      serverId: 'server-a',
      liveDvrKey: 'dvr-a',
    );

void main() {
  tearDown(SelectKeyUpSuppressor.clearSuppression);

  test('SELECT hold survives equivalent fresh guide objects and opens details once', () {
    fakeAsync((async) {
      final controller = DpadSelectLongPressController();
      var focusedChannel = _channel();
      var focusedProgram = _program();
      final pressedIdentity = guideAiringIdentity(focusedChannel, focusedProgram);
      var detailsOpened = 0;

      controller.handleKeyEvent(
        _selectDown,
        isOwnerActive: () => guideAiringIdentity(focusedChannel, focusedProgram) == pressedIdentity,
        onShortPress: () {},
        onLongPress: () {
          controller.reset();
          detailsOpened++;
        },
      );

      async.elapse(const Duration(milliseconds: 250));
      final replacementChannel = _channel();
      final replacementProgram = _program();
      expect(identical(replacementChannel, focusedChannel), isFalse);
      expect(identical(replacementProgram, focusedProgram), isFalse);
      focusedChannel = replacementChannel;
      focusedProgram = replacementProgram;

      async.elapse(const Duration(milliseconds: 249));
      expect(detailsOpened, 0);
      async.elapse(const Duration(milliseconds: 1));
      expect(detailsOpened, 1);

      async.elapse(const Duration(seconds: 1));
      expect(detailsOpened, 1);
      controller.dispose();
    });
  });

  test('SELECT hold does not open details after focus moves to a different airing', () {
    fakeAsync((async) {
      final controller = DpadSelectLongPressController();
      final focusedChannel = _channel();
      var focusedProgram = _program();
      final pressedIdentity = guideAiringIdentity(focusedChannel, focusedProgram);
      var detailsOpened = 0;

      controller.handleKeyEvent(
        _selectDown,
        isOwnerActive: () => guideAiringIdentity(focusedChannel, focusedProgram) == pressedIdentity,
        onShortPress: () {},
        onLongPress: () => detailsOpened++,
      );

      async.elapse(const Duration(milliseconds: 250));
      focusedProgram = _program(beginsAt: 1_800_003_600, endsAt: 1_800_007_200);
      expect(guideAiringIdentity(focusedChannel, focusedProgram), isNot(pressedIdentity));

      async.elapse(const Duration(milliseconds: 250));
      expect(detailsOpened, 0);
      async.elapse(const Duration(seconds: 1));
      expect(detailsOpened, 0);
      controller.dispose();
    });
  });
}
