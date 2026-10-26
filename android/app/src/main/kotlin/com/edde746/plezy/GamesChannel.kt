package com.edde746.plezy

import android.app.Activity
import android.content.Context
import android.net.wifi.WifiManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.lang.reflect.InvocationTargetException
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger

/** Only engines bundled in this APK may handle a game session. */
internal class GamesChannel(private val activity: Activity) {
  private val executor = Executors.newSingleThreadExecutor()
  private val generation = AtomicInteger()
  private val artworkExecutor = Executors.newFixedThreadPool(2)
  private val artworkResults = mutableMapOf<Int, MethodChannel.Result>()
  private var artworkId = 0
  private var channel: MethodChannel? = null
  private var pending: MethodChannel.Result? = null
  private var multicast: WifiManager.MulticastLock? = null
  private val engine: Class<*>? by lazy {
    try {
      Class.forName("org.snapetech.plezyng.games.EmbeddedGameStream")
    } catch (_: ClassNotFoundException) {
      null
    }
  }

  private val steamEngine: Class<*>? by lazy {
    try {
      Class.forName("org.snapetech.plezyng.games.steam.EmbeddedSteam")
    } catch (_: ClassNotFoundException) {
      null
    }
  }

  private fun bridge(protocol: String?): Class<*>? = when (protocol) {
    "gameStream" -> engine
    "steam" -> steamEngine
    else -> null
  }

  fun attach(messenger: BinaryMessenger) {
    channel = MethodChannel(messenger, "com.plezy/games").also { it.setMethodCallHandler(::handle) }
  }

  private fun handle(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "cancel" -> {
        cancel()
        result.success(null)
      }
      "multicast" -> {
        releaseMulticast()
        if (call.argument<Boolean>("enabled") == true) {
          try {
            val wifi = activity.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            multicast = wifi?.createMulticastLock("plezy-games-discovery")?.apply {
              setReferenceCounted(false)
              acquire()
            }
          } catch (_: SecurityException) {
            // The bounded scan still has manual entry and unicast fallbacks.
          }
        }
        result.success(null)
      }
      "capabilities" -> {
        val protocol = call.argument<String>("protocol")
        val available = bridge(protocol) != null
        result.success(mapOf("available" to available, "inlinePairing" to available, "library" to (available && protocol == "gameStream")))
      }
      "artwork" -> {
        val bridge = engine
        if (bridge == null || call.argument<String>("protocol") != "gameStream" || artworkResults.size >= 16) {
          result.success(null)
          return
        }
        val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
        val epoch = generation.get()
        val id = ++artworkId
        artworkResults[id] = result
        artworkExecutor.execute {
          val bytes = try {
            if (epoch == generation.get()) {
              bridge.getMethod("artwork", Context::class.java, Map::class.java)
                .invoke(null, activity.applicationContext, args)
            } else {
              null
            }
          } catch (_: Exception) {
            null
          }
          activity.runOnUiThread {
            artworkResults.remove(id)?.success(if (epoch == generation.get()) bytes else null)
          }
        }
      }
      "open", "pair", "games" -> {
        val bridge = bridge(call.argument<String>("protocol"))
        if (bridge == null) {
          result.error("UNAVAILABLE", "No embedded engine for this service", null)
          return
        }
        if (pending != null) {
          result.error("BUSY", "A connection operation is already in progress", null)
          return
        }
        val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
        try {
          if (call.method == "open") {
            result.success(bridge.getMethod("open", Activity::class.java, Map::class.java).invoke(null, activity, args))
            return
          }
          val epoch = generation.get()
          pending = result
          executor.execute {
            try {
              val value = if (epoch == generation.get()) {
                bridge.getMethod("execute", Context::class.java, String::class.java, Map::class.java)
                  .invoke(null, activity.applicationContext, call.method, args)
              } else {
                null
              }
              activity.runOnUiThread {
                if (epoch == generation.get() && pending === result) {
                  pending = null
                  result.success(value)
                }
              }
            } catch (error: Exception) {
              activity.runOnUiThread {
                if (epoch == generation.get() && pending === result) {
                  pending = null
                  failure(result, error)
                }
              }
            }
          }
        } catch (error: Exception) {
          pending = null
          failure(result, error)
        }
      }
      else -> result.notImplemented()
    }
  }

  private fun failure(result: MethodChannel.Result, error: Exception) {
    val cause = (error as? InvocationTargetException)?.targetException ?: error
    result.error(if (cause is SecurityException) "PAIRING_REQUIRED" else "UNAVAILABLE", "Connection could not complete", null)
  }

  private fun cancel() {
    generation.incrementAndGet()
    pending?.error("CANCELLED", "Connection cancelled", null)
    pending = null
    artworkResults.values.forEach { it.success(null) }
    artworkResults.clear()
    listOf(engine, steamEngine).forEach { bridge ->
      try {
        bridge?.getMethod("cancel")?.invoke(null)
      } catch (_: Exception) {
        // A failure in one optional engine must not prevent the other cancelling.
      }
    }
  }

  private fun releaseMulticast() {
    multicast?.let { if (it.isHeld) it.release() }
    multicast = null
  }

  fun dispose() {
    channel?.setMethodCallHandler(null)
    cancel()
    releaseMulticast()
    executor.shutdownNow()
    artworkExecutor.shutdownNow()
  }
}
