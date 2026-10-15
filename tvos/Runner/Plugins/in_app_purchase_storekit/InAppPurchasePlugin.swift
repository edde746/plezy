// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// Plezy tvOS copy: a trimmed InAppPurchasePlugin from in_app_purchase_storekit
// 0.4.13+3 (pub.dev), file darwin/.../InAppPurchasePlugin.swift, serving only
// the plugin's StoreKit 2 API. The upstream class also implements StoreKit 1
// on top of the plugin's Objective-C module, whose podspec declares only iOS
// and macOS. The Dart side uses StoreKit 2 by default, which every supported
// tvOS has, so the StoreKit 1 channel is never registered here.
//
// Local delta: keep only the members the StoreKit 2 extension uses (the
// registrar, the Transaction.updates listener task and the transaction
// callback API) and register only the StoreKit 2 Pigeon API. The three
// StoreKit2*.swift files beside this one carry their own small deltas in their
// headers.
//
// To update: copy StoreKit2/InAppPurchasePlugin+StoreKit2.swift,
// StoreKit2Messages.g.swift and StoreKit2Translators.swift from the newly
// locked package version, reapply the deltas their headers list, check the
// upstream class's StoreKit 2 members against this one, then build Runner for
// Apple TV simulator and device.

import Flutter
import Foundation
import StoreKit

public class InAppPurchasePlugin: NSObject, FlutterPlugin {
  public var registrar: FlutterPluginRegistrar?

  // This should be an Task, but Task is on available >= iOS 13
  private var _updateListenerTask: Any?

  var updateListenerTask: Task<(), Never> {
    return self._updateListenerTask as! Task<(), Never>
  }

  func setListenerTaskAsTask(task: Task<(), Never>) {
    self._updateListenerTask = task
  }

  var transactionCallbackAPI: InAppPurchase2CallbackAPIProtocol? = nil

  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger()
    let instance = InAppPurchasePlugin()
    instance.registrar = registrar
    instance.transactionCallbackAPI = InAppPurchase2CallbackAPI(binaryMessenger: messenger)
    InAppPurchase2APISetup.setUp(binaryMessenger: messenger, api: instance)
  }
}
