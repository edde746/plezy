package com.edde746.plezy

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.View
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/** Flutter adapter for the optional retained Steam view in the :steam module. */
internal class SteamStreamPlatformViewFactory(private val messenger: BinaryMessenger) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
  companion object {
    const val VIEW_TYPE = "com.plezy/games/steam_stream"
  }

  override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
    val parameters = args as? Map<*, *> ?: throw IllegalArgumentException("Missing Steam stream arguments")
    val viewClass = Class.forName("org.snapetech.plezyng.games.steam.SteamStreamView")
    val streamView = viewClass.getConstructor(Context::class.java, Map::class.java).newInstance(context, parameters)
    return SteamStreamPlatformView(viewId, streamView as View, streamView)
  }

  private inner class SteamStreamPlatformView(viewId: Int, private val view: View, private val target: Any) :
    PlatformView,
    MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "com.plezy/games/steam_stream/$viewId")
    private val booleanType = Boolean::class.javaPrimitiveType!!

    init {
      channel.setMethodCallHandler(this)
      invoke("setOnStateChanged", arrayOf(Runnable::class.java), Runnable {
        channel.invokeMethod("sessionState", target.javaClass.getMethod("getSessionState").invoke(target))
      })
    }

    override fun getView(): View = view

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
      try {
        when (call.method) {
          "disconnect" -> {
            invoke("close")
            Thread({
              val stopped = runCatching { invoke("awaitTermination") }.isSuccess
              Handler(Looper.getMainLooper()).post {
                if (stopped) result.success(null)
                else result.error("STREAM_STOP_PENDING", "The previous stream is still stopping", null)
              }
            }, "PlezySteamDisconnect").apply { isDaemon = true }.start()
            return
          }
          "getSessionState" -> {
            result.success(target.javaClass.getMethod("getSessionState").invoke(target))
            return
          }
          "setAudioEnabled" -> invoke("setAudioEnabled", arrayOf(booleanType), call.argument<Boolean>("enabled") == true)
          "setInputEnabled" -> invoke("setInputEnabled", arrayOf(booleanType), call.argument<Boolean>("enabled") == true)
          "setControllerState" -> invoke(
            "setControllerState",
            arrayOf(Map::class.java, Map::class.java),
            call.argument<Map<*, *>>("buttons") ?: emptyMap<Any, Any>(),
            call.argument<Map<*, *>>("axes") ?: emptyMap<Any, Any>()
          )
          "setControllerDeviceState" -> invoke(
            "setControllerDeviceState",
            arrayOf(Int::class.javaPrimitiveType!!, Map::class.java, Map::class.java),
            call.argument<Int>("deviceId") ?: throw IllegalArgumentException("Missing controller"),
            call.argument<Map<*, *>>("buttons") ?: emptyMap<Any, Any>(),
            call.argument<Map<*, *>>("axes") ?: emptyMap<Any, Any>()
          )
          "disconnectController" -> invoke(
            "disconnectController",
            arrayOf(Int::class.javaPrimitiveType!!),
            call.argument<Int>("deviceId") ?: throw IllegalArgumentException("Missing controller")
          )
          "inputKey" -> invoke(
            "inputKey",
            arrayOf(String::class.java, booleanType),
            call.argument<String>("key") ?: "",
            call.argument<Boolean>("down") == true
          )
          "resetInput" -> invoke("resetInput")
          else -> {
            result.notImplemented()
            return
          }
        }
        result.success(null)
      } catch (error: Exception) {
        result.error("STREAM_CONTROL_FAILED", "The game stream control could not be applied", null)
      }
    }

    private fun invoke(name: String, types: Array<Class<*>> = emptyArray(), vararg arguments: Any) {
      target.javaClass.getMethod(name, *types).invoke(target, *arguments)
    }

    override fun dispose() {
      channel.setMethodCallHandler(null)
      runCatching { invoke("setOnStateChanged", arrayOf(Runnable::class.java), Runnable {}) }
      runCatching { invoke("close") }
    }
  }
}
