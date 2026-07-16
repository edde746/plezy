package com.edde746.plezy.shared

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/** Owns the identical MethodChannel/EventChannel lifecycle for native players. */
internal class PlayerChannelBinding(
  private val channelBase: String,
  private val methodCallHandler: MethodChannel.MethodCallHandler,
  private val streamHandler: EventChannel.StreamHandler,
  private val logTag: String
) {
  private lateinit var methodChannel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private var eventSink: EventChannel.EventSink? = null

  val mainHandler = Handler(Looper.getMainLooper())

  fun attach(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel = MethodChannel(binding.binaryMessenger, channelBase)
    methodChannel.setMethodCallHandler(methodCallHandler)

    eventChannel = EventChannel(binding.binaryMessenger, "$channelBase/events")
    eventChannel.setStreamHandler(streamHandler)

    Log.d(logTag, "Attached to engine")
  }

  fun detach() {
    methodChannel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
    eventSink = null
    Log.d(logTag, "Detached from engine")
  }

  fun listen(events: EventChannel.EventSink?) {
    eventSink = events
    Log.d(logTag, "Event stream connected")
  }

  fun cancel() {
    eventSink = null
    Log.d(logTag, "Event stream disconnected")
  }

  fun runOnMain(block: () -> Unit) {
    if (Looper.myLooper() == Looper.getMainLooper()) {
      block()
    } else {
      mainHandler.post(block)
    }
  }

  fun emitProperty(id: Int, value: Any?) {
    runOnMain { eventSink?.success(listOf(id, value)) }
  }

  fun emitEvent(name: String, data: Map<String, Any>? = null) {
    val event = mutableMapOf<String, Any>(
      "type" to "event",
      "name" to name
    )
    data?.let { event["data"] = it }
    runOnMain { eventSink?.success(event) }
  }
}
