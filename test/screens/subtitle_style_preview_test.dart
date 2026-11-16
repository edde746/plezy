import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/screens/settings/subtitle_style_preview.dart';

void main() {
  group('SubtitleStylePreviewController', () {
    test('starts with nothing provisional', () {
      expect(SubtitleStylePreviewController().value, isEmpty);
    });

    test('publishing a value notifies once and withdrawing it notifies again', () {
      final controller = SubtitleStylePreviewController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.set('subtitle_font_size', 55);
      expect(controller.value, {'subtitle_font_size': 55});

      controller.set('subtitle_font_size', null);
      expect(controller.value, isEmpty);
      expect(notifications, 2);
    });

    test('republishing the same value does not rebuild the preview', () {
      // A slider fires continuously while it is dragged; a rebuild per event
      // for an unchanged value is the one thing a live preview cannot afford.
      final controller = SubtitleStylePreviewController();
      controller.set('subtitle_font_size', 55);

      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.set('subtitle_font_size', 55);
      expect(notifications, 0);
    });

    test('withdrawing a key that was never published does nothing', () {
      final controller = SubtitleStylePreviewController();
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.set('subtitle_font_size', null);
      expect(notifications, 0);
    });

    test('keys do not disturb each other', () {
      final controller = SubtitleStylePreviewController();
      controller.set('subtitle_font_size', 55);
      controller.set('subtitle_text_color', 'FFFFFF');
      controller.set('subtitle_font_size', null);
      expect(controller.value, {'subtitle_text_color': 'FFFFFF'});
    });

    test('clear drops everything a still-open dialog would never withdraw', () {
      final controller = SubtitleStylePreviewController();
      controller.set('subtitle_font_size', 55);
      controller.set('subtitle_text_color', 'FFFFFF');
      controller.clear();
      expect(controller.value, isEmpty);
    });

    test('clearing an empty controller does not notify', () {
      final controller = SubtitleStylePreviewController();
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.clear();
      expect(notifications, 0);
    });
  });
}
