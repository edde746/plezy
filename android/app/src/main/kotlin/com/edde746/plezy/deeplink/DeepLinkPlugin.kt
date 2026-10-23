package com.edde746.plezy.deeplink

import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Hands every `plezy:` link to Dart unchanged. The link grammar lives only in
 * `lib/services/deep_links/deep_link.dart`, so nothing here reads hosts or
 * query parameters.
 */
class DeepLinkPlugin :
  FlutterPlugin,
  MethodChannel.MethodCallHandler {
  companion object {
    private const val METHOD_CHANNEL = "com.plezy/deep_link"
    private const val SCHEME = "plezy"

    // One slot, latest link wins. It lives here rather than on the instance so a
    // link Dart has not accepted yet survives the engine being re-created.
    private var retainedLink: String? = null

    fun linkFrom(intent: Intent?): String? {
      val data = intent?.data ?: return null
      if (!SCHEME.equals(data.scheme, ignoreCase = true)) return null
      return data.toString()
    }
  }

  private var methodChannel: MethodChannel? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL).also {
      it.setMethodCallHandler(this)
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel?.setMethodCallHandler(null)
    methodChannel = null
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "getInitialLink" -> {
        val url = retainedLink
        retainedLink = null
        result.success(url)
      }
      else -> result.notImplemented()
    }
  }

  fun notifyLink(url: String) {
    retainedLink = url
    // Not attached to an engine yet: Dart collects the link through getInitialLink.
    val channel = methodChannel ?: return
    channel.invokeMethod(
      "onLink",
      mapOf("url" to url),
      object : MethodChannel.Result {
        // Dart answers true only once it took the link; until then it stays
        // retained for getInitialLink. Clearing it here keeps the next startup
        // path (profile switch, sign-in, a re-created engine) from replaying it,
        // and the equality check keeps a late answer for an older link from
        // dropping a newer one.
        override fun success(result: Any?) {
          if (result == true && retainedLink == url) retainedLink = null
        }

        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}

        override fun notImplemented() {}
      }
    )
  }
}
