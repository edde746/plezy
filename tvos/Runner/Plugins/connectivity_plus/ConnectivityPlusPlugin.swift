// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source is governed by a BSD-style license that can
// be found in the LICENSE file.

import Flutter
import UIKit

private final class ConnectivityListenerEpoch {}

public class ConnectivityPlusPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private let connectivityProvider: ConnectivityProvider
  private let notificationCenter: NotificationCenter
  private let applicationState: () -> UIApplication.State
  private var eventSink: FlutterEventSink?
  private var activationObserver: NSObjectProtocol?
  private var pendingConnectivity: [String]?
  private var lastDeliveredConnectivity: [String]?
  private var activeListenerEpoch: ConnectivityListenerEpoch?

  init(
    connectivityProvider: ConnectivityProvider,
    notificationCenter: NotificationCenter = .default,
    applicationState: @escaping () -> UIApplication.State = {
      UIApplication.shared.applicationState
    }
  ) {
    self.connectivityProvider = connectivityProvider
    self.notificationCenter = notificationCenter
    self.applicationState = applicationState
    super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let binaryMessenger = registrar.messenger()

    let channel = FlutterMethodChannel(
      name: "dev.fluttercommunity.plus/connectivity",
      binaryMessenger: binaryMessenger)

    let streamChannel = FlutterEventChannel(
      name: "dev.fluttercommunity.plus/connectivity_status",
      binaryMessenger: binaryMessenger)

    let connectivityProvider = PathMonitorConnectivityProvider()
    let instance = ConnectivityPlusPlugin(connectivityProvider: connectivityProvider)
    streamChannel.setStreamHandler(instance)

    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  private func onMain<T>(_ block: () -> T) -> T {
    if Thread.isMainThread {
      return block()
    }
    return DispatchQueue.main.sync(execute: block)
  }

  private func installProviderHandler() -> ConnectivityListenerEpoch {
    let epoch = ConnectivityListenerEpoch()
    activeListenerEpoch = epoch
    connectivityProvider.connectivityUpdateHandler = { [weak self] connectivityTypes in
      self?.connectivityUpdateHandler(connectivityTypes: connectivityTypes, epoch: epoch)
    }
    return epoch
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    onMain {
      stopListening(preservePendingConnectivity: false)
    }
  }

  deinit {
    let observer = activationObserver
    let provider = connectivityProvider
    let center = notificationCenter
    let cleanup = {
      if let observer {
        center.removeObserver(observer)
      }
      provider.connectivityUpdateHandler = nil
    }
    if Thread.isMainThread {
      cleanup()
    } else {
      DispatchQueue.main.sync(execute: cleanup)
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "check":
      result(statusFrom(connectivityTypes: connectivityProvider.currentConnectivityTypes))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func statusFrom(connectivityType: ConnectivityType) -> String {
    switch connectivityType {
    case .wifi:
      return "wifi"
    case .cellular:
      return "mobile"
    case .wiredEthernet:
      return "ethernet"
    case .other:
      return "other"
    case .none:
      return "none"
    }
  }

  private func statusFrom(connectivityTypes: [ConnectivityType]) -> [String] {
    return connectivityTypes.map {
      self.statusFrom(connectivityType: $0)
    }
  }

  public func onListen(
    withArguments _: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    onMain {
      eventSink = events
      let listenerEpoch = installProviderHandler()
      if activationObserver == nil {
        activationObserver = notificationCenter.addObserver(
          forName: UIApplication.didBecomeActiveNotification,
          object: nil,
          queue: .main
        ) { [weak self] _ in
          self?.replayPendingConnectivityIfNeeded()
        }
      }
      connectivityProvider.start()
      guard applicationState() != .background else { return nil }
      let replayedConnectivity = pendingConnectivity
      if let replayedConnectivity {
        pendingConnectivity = nil
        lastDeliveredConnectivity = replayedConnectivity
        events(replayedConnectivity)
      }
      let currentConnectivity = statusFrom(
        connectivityTypes: connectivityProvider.currentConnectivityTypes)
      if currentConnectivity != replayedConnectivity {
        connectivityUpdateHandler(
          connectivityTypes: connectivityProvider.currentConnectivityTypes,
          epoch: listenerEpoch
        )
      }
      return nil
    }
  }

  private func connectivityUpdateHandler(
    connectivityTypes: [ConnectivityType],
    epoch: ConnectivityListenerEpoch
  ) {
    let status = statusFrom(connectivityTypes: connectivityTypes)
    DispatchQueue.main.async { [weak self] in
      guard let self, self.activeListenerEpoch === epoch else { return }
      guard self.applicationState() != .background, let eventSink = self.eventSink else {
        // Keep only the newest user-visible state. Connectivity changes are
        // snapshots, not telemetry; one bounded slot is sufficient.
        self.pendingConnectivity = status
        return
      }
      self.pendingConnectivity = nil
      guard status != self.lastDeliveredConnectivity else { return }
      self.lastDeliveredConnectivity = status
      eventSink(status)
    }
  }

  private func replayPendingConnectivityIfNeeded() {
    guard applicationState() == .active, let pendingConnectivity, let eventSink else { return }
    self.pendingConnectivity = nil
    guard pendingConnectivity != lastDeliveredConnectivity else { return }
    lastDeliveredConnectivity = pendingConnectivity
    eventSink(pendingConnectivity)
  }

  private func stopListening(preservePendingConnectivity: Bool) {
    eventSink = nil
    activeListenerEpoch = nil
    connectivityProvider.connectivityUpdateHandler = nil
    if !preservePendingConnectivity {
      pendingConnectivity = nil
    }
    lastDeliveredConnectivity = nil
    if let activationObserver {
      notificationCenter.removeObserver(activationObserver)
      self.activationObserver = nil
    }
    connectivityProvider.stop()
  }

  public func onCancel(withArguments _: Any?) -> FlutterError? {
    onMain {
      stopListening(preservePendingConnectivity: true)
      return nil
    }
  }
}
