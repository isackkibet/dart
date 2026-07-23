import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/features/feed/controllers/overlay_visibility_controller.dart';

void main() {
  group('OverlayVisibilityController', () {
    late OverlayVisibilityController controller;

    setUp(() {
      controller = OverlayVisibilityController(
        hideDelay: const Duration(milliseconds: 100),
      );
    });

    tearDown(() => controller.dispose());

    test('starts visible', () {
      expect(controller.visible, isTrue);
    });

    test('start() makes visible and notifies', () {
      controller.hideImmediately();
      var notified = false;
      controller.addListener(() => notified = true);
      controller.start();
      expect(controller.visible, isTrue);
      expect(notified, isTrue);
    });

    test('hideImmediately() hides and notifies', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.hideImmediately();
      expect(controller.visible, isFalse);
      expect(notified, isTrue);
    });

    test('keepVisible() cancels auto-hide', () async {
      controller.start();
      controller.keepVisible();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(controller.visible, isTrue);
    });

    test('auto-hides after hideDelay', () async {
      controller.start();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(controller.visible, isFalse);
    });

    test('showTemporarily() re-shows and re-arms the timer', () async {
      controller.hideImmediately();
      controller.showTemporarily();
      expect(controller.visible, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(controller.visible, isFalse);
    });

    test('toggle() flips visibility', () {
      expect(controller.visible, isTrue);
      controller.toggle();
      expect(controller.visible, isFalse);
      controller.toggle();
      expect(controller.visible, isTrue);
    });

    test('toggle() to true re-arms auto-hide', () async {
      controller.hideImmediately();
      controller.toggle();
      expect(controller.visible, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(controller.visible, isFalse);
    });

    test('toggle() to false cancels auto-hide', () async {
      controller.start();
      controller.toggle(); // hide immediately
      expect(controller.visible, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(controller.visible, isFalse);
    });

    test('dispose cancels pending timer without throwing', () {
      final local = OverlayVisibilityController(
        hideDelay: const Duration(milliseconds: 100),
      );
      local.start();
      expect(() => local.dispose(), returnsNormally);
    });
  });
}
