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
  private var methodChannel: MethodChannel? = null
  private var eventChannel: EventChannel? = null
  private var eventSink: EventChannel.EventSink? = null

  val mainHandler = Handler(Looper.getMainLooper())

  fun attach(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel = MethodChannel(binding.binaryMessenger, channelBase).also {
      it.setMethodCallHandler(methodCallHandler)
    }

    eventChannel = EventChannel(binding.binaryMessenger, "$channelBase/events").also {
      it.setStreamHandler(streamHandler)
    }
    Log.d(logTag, "Attached to engine")
  }

  fun detach() {
    methodChannel?.setMethodCallHandler(null)
    eventChannel?.setStreamHandler(null)
    methodChannel = null
    eventChannel = null
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
