@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_plus/src/wakelock_plus_web_plugin.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';
import 'package:web/web.dart' as web;

@JS('wakeLockTest.reset')
external void resetWakeLockTest();

@JS('wakeLockTest.setVisibility')
external void setTestVisibility(String value, bool dispatchEvent);

@JS('wakeLockTest.releaseSentinel')
external void releaseTestSentinel(int index);

@JS('wakeLockTest.delayNextRequest')
external void delayNextWakeLockRequest();

@JS('wakeLockTest.resolvePendingRequest')
external void resolvePendingWakeLockRequest();

@JS('wakeLockTest.failNextRequest')
external void failNextWakeLockRequest();

@JS('wakeLockTest.delayNextRelease')
external void delayNextWakeLockRelease();

@JS('wakeLockTest.resolvePendingRelease')
external void resolvePendingWakeLockRelease();

@JS('wakeLockTest.failNextRelease')
external void failNextWakeLockRelease();

@JS('wakeLockTest.requestCount')
external int get wakeLockRequestCount;

@JS('wakeLockTest.releaseCount')
external int get wakeLockReleaseCount;

void installFakeWakeLock() {
  final script = web.document.createElement('script') as web.HTMLScriptElement;
  script.text = r'''
    (() => {
      let visibility = 'visible';
      let requests = 0;
      let releases = 0;
      let delayRequest = false;
      let delayRelease = false;
      let rejectRequest = false;
      let rejectRelease = false;
      let pendingRequest = null;
      let pendingRelease = null;
      let sentinels = [];

      class FakeWakeLockSentinel extends EventTarget {
        constructor() {
          super();
          this.released = false;
        }

        release() {
          releases++;
          if (rejectRelease) {
            rejectRelease = false;
            return Promise.reject(new Error('release failed'));
          }
          if (delayRelease) {
            delayRelease = false;
            return new Promise((resolve) => {
              pendingRelease = () => {
                pendingRelease = null;
                this.released = true;
                this.dispatchEvent(new Event('release'));
                resolve();
              };
            });
          }
          this.released = true;
          this.dispatchEvent(new Event('release'));
          return Promise.resolve();
        }
      }

      Object.defineProperty(document, 'visibilityState', {
        configurable: true,
        get: () => visibility,
      });
      Object.defineProperty(navigator, 'wakeLock', {
        configurable: true,
        value: {
          request(type) {
            if (type !== 'screen') {
              return Promise.reject(new Error(`unexpected type: ${type}`));
            }
            requests++;
            if (rejectRequest) {
              rejectRequest = false;
              return Promise.reject(new Error('request failed'));
            }
            const sentinel = new FakeWakeLockSentinel();
            sentinels.push(sentinel);
            if (!delayRequest) {
              return Promise.resolve(sentinel);
            }
            delayRequest = false;
            return new Promise((resolve) => {
              pendingRequest = () => {
                pendingRequest = null;
                resolve(sentinel);
              };
            });
          },
        },
      });

      window.wakeLockTest = {
        reset() {
          visibility = 'visible';
          requests = 0;
          releases = 0;
          delayRequest = false;
          delayRelease = false;
          rejectRequest = false;
          rejectRelease = false;
          pendingRequest = null;
          pendingRelease = null;
          sentinels = [];
        },
        setVisibility(value, dispatchEvent) {
          visibility = value;
          if (dispatchEvent) {
            document.dispatchEvent(new Event('visibilitychange'));
          }
        },
        releaseSentinel(index) {
          const sentinel = sentinels[index];
          sentinel.released = true;
          sentinel.dispatchEvent(new Event('release'));
        },
        delayNextRequest() {
          delayRequest = true;
        },
        resolvePendingRequest() {
          if (pendingRequest === null) {
            throw new Error('no pending wake lock request');
          }
          pendingRequest();
        },
        failNextRequest() {
          rejectRequest = true;
        },
        delayNextRelease() {
          delayRelease = true;
        },
        resolvePendingRelease() {
          if (pendingRelease === null) {
            throw new Error('no pending wake lock release');
          }
          pendingRelease();
        },
        failNextRelease() {
          rejectRelease = true;
        },
        get requestCount() {
          return requests;
        },
        get releaseCount() {
          return releases;
        },
      };
    })();
  ''';
  web.document.head!.appendChild(script);
}

Future<void> flushBrowserTasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('$WakelockPlusWebPlugin', () {
    setUpAll(() {
      installFakeWakeLock();
      WakelockPlusPlatformInterface.instance = WakelockPlusWebPlugin();
    });

    tearDown(() async {
      await WakelockPlus.disable();
      resetWakeLockTest();
    });

    test('$WakelockPlusWebPlugin is the platform instance', () {
      expect(WakelockPlusPlatformInterface.instance, isA<WakelockPlusWebPlugin>());
    });

    test('enable then disable releases a pending acquisition', () async {
      delayNextWakeLockRequest();
      final enabling = WakelockPlus.enable();
      await flushBrowserTasks();
      expect(wakeLockRequestCount, 1);

      final disabling = WakelockPlus.disable();
      await flushBrowserTasks();
      resolvePendingWakeLockRequest();
      await Future.wait([enabling, disabling]);

      expect(wakeLockReleaseCount, 1);
      expect(await WakelockPlus.enabled, isFalse);
    });

    test('disable then enable reacquires after the release completes', () async {
      await WakelockPlus.enable();
      delayNextWakeLockRelease();

      final disabling = WakelockPlus.disable();
      await flushBrowserTasks();
      final enabling = WakelockPlus.enable();
      await flushBrowserTasks();
      expect(wakeLockRequestCount, 1);

      resolvePendingWakeLockRelease();
      await Future.wait([disabling, enabling]);
      await flushBrowserTasks();

      expect(wakeLockRequestCount, 2);
      expect(await WakelockPlus.enabled, isTrue);
    });

    test('acquisition failure remains retryable', () async {
      failNextWakeLockRequest();

      await expectLater(WakelockPlus.enable(), throwsA(anything));
      expect(await WakelockPlus.enabled, isFalse);

      await WakelockPlus.enable();
      expect(wakeLockRequestCount, 2);
      expect(await WakelockPlus.enabled, isTrue);
    });

    test('release failure retains the sentinel for teardown retry', () async {
      await WakelockPlus.enable();
      failNextWakeLockRelease();

      await expectLater(WakelockPlus.disable(), throwsA(anything));
      expect(await WakelockPlus.enabled, isTrue);

      await WakelockPlus.disable();
      expect(wakeLockReleaseCount, 2);
      expect(await WakelockPlus.enabled, isFalse);
    });

    test('reacquires after a browser release when still requested', () async {
      await WakelockPlus.enable();
      expect(wakeLockRequestCount, 1);

      setTestVisibility('hidden', false);
      releaseTestSentinel(0);
      expect(await WakelockPlus.enabled, isFalse);

      setTestVisibility('visible', true);
      await flushBrowserTasks();

      expect(wakeLockRequestCount, 2);
      expect(await WakelockPlus.enabled, isTrue);
    });

    test('does not reacquire after explicit teardown', () async {
      await WakelockPlus.enable();
      setTestVisibility('hidden', false);
      releaseTestSentinel(0);

      await WakelockPlus.disable();
      setTestVisibility('visible', true);
      web.document.dispatchEvent(web.Event('fullscreenchange'));
      await flushBrowserTasks();

      expect(wakeLockRequestCount, 1);
      expect(await WakelockPlus.enabled, isFalse);
    });

    test('releases a reacquisition that resolves after disable', () async {
      await WakelockPlus.enable();
      setTestVisibility('hidden', false);
      releaseTestSentinel(0);
      delayNextWakeLockRequest();
      setTestVisibility('visible', true);
      await flushBrowserTasks();
      expect(wakeLockRequestCount, 2);

      final disabling = WakelockPlus.disable();
      await flushBrowserTasks();
      resolvePendingWakeLockRequest();
      await disabling;

      expect(wakeLockReleaseCount, 1);
      expect(await WakelockPlus.enabled, isFalse);

      setTestVisibility('visible', true);
      web.document.dispatchEvent(web.Event('fullscreenchange'));
      await flushBrowserTasks();
      expect(wakeLockRequestCount, 2);
    });

    test('an old sentinel release cannot clear its replacement', () async {
      await WakelockPlus.enable();
      setTestVisibility('hidden', false);
      releaseTestSentinel(0);
      setTestVisibility('visible', true);
      await flushBrowserTasks();
      expect(await WakelockPlus.enabled, isTrue);

      releaseTestSentinel(0);
      await flushBrowserTasks();

      expect(wakeLockRequestCount, 2);
      expect(await WakelockPlus.enabled, isTrue);
    });
  });
}
