package dev.fluttercommunity.plus.wakelock

import IsEnabledMessage
import ToggleMessage
import WakelockPlusApi

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/** WakelockPlusPlugin */
class WakelockPlusPlugin: FlutterPlugin, WakelockPlusApi, ActivityAware {
  private var wakelock: Wakelock? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    WakelockPlusApi.setUp(flutterPluginBinding.binaryMessenger, this)
    wakelock = Wakelock()
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    WakelockPlusApi.setUp(binding.binaryMessenger, null)
    wakelock = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    wakelock?.activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    wakelock?.activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity()
  }

  override fun toggle(msg: ToggleMessage) {
    wakelock!!.toggle(msg)
  }

  override fun isEnabled(): IsEnabledMessage {
    return wakelock!!.isEnabled()
  }
}
