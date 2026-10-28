package com.edde746.plezy.deeplink

import android.content.Context
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCodec
import io.flutter.plugin.common.StandardMethodCodec
import java.lang.reflect.Proxy
import java.nio.ByteBuffer
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment

@RunWith(RobolectricTestRunner::class)
class DeepLinkPluginTest {
  private companion object {
    const val CHANNEL = "com.plezy/deep_link"
    val codec: MethodCodec = StandardMethodCodec.INSTANCE
  }

  // The retained slot is process-wide on purpose, so every test starts and ends empty.
  @Before
  @After
  fun clearRetainedLink() {
    takeInitialLink(DeepLinkPlugin())
  }

  @Test
  fun everyPlezyLinkIsForwardedVerbatim() {
    val links = listOf(
      "plezy://open",
      "plezy://open?profile=Kids",
      "plezy://play?server=srv-1&id=42&mode=shuffle&profile=Kids",
      "plezy://play?type=show&tvdb=81189&mode=next",
      "plezy://play?content_id=plezy_srv-1_42",
      "plezy://live?channel=News%20HD&server=srv-1&start=beginning",
      "plezy://external-player/success/session-7?position=1234&duration=5678",
      "plezy://future-host/some/path?param=value#fragment"
    )

    for (link in links) {
      assertEquals(link, DeepLinkPlugin.linkFrom(viewIntent(link)))
    }
  }

  @Test
  fun schemeMatchIgnoresCaseAndKeepsTheUrlUnchanged() {
    for (link in listOf("PLEZY://open", "Plezy://play?server=srv-1&id=42")) {
      assertEquals(link, DeepLinkPlugin.linkFrom(viewIntent(link)))
    }
  }

  @Test
  fun intentsWithoutAPlezyLinkAreIgnored() {
    assertNull(DeepLinkPlugin.linkFrom(null))
    assertNull(DeepLinkPlugin.linkFrom(Intent(Intent.ACTION_MAIN)))
    for (link in listOf("https://plezy.app/play?server=srv-1&id=42", "plezyx://open", "content://plezy/open", "play?id=42")) {
      assertNull(link, DeepLinkPlugin.linkFrom(viewIntent(link)))
    }
  }

  @Test
  fun linkIsSentToDartAndStaysRetainedUntilDartAcceptsIt() {
    val dart = FakeDart()
    val plugin = DeepLinkPlugin()
    plugin.onAttachedToEngine(dart.binding())
    val link = "plezy://play?server=srv-1&id=42"
    val declines = listOf<(BinaryMessenger.BinaryReply) -> Unit>(
      { it.reply(codec.encodeSuccessEnvelope(false).rewound()) },
      { it.reply(codec.encodeSuccessEnvelope(null).rewound()) },
      { it.reply(codec.encodeErrorEnvelope("UNAVAILABLE", null, null).rewound()) },
      // No Dart handler registered: the channel answers notImplemented.
      { it.reply(null) }
    )

    for (decline in declines) {
      plugin.notifyLink(link)
      val sent = dart.sent.last()
      assertEquals(CHANNEL, sent.channel)
      assertEquals("onLink", sent.call.method)
      assertEquals(mapOf("url" to link), sent.call.arguments)
      decline(sent.reply)
      assertEquals(link, takeInitialLink(plugin))
    }

    plugin.notifyLink(link)
    dart.sent.last().reply.reply(codec.encodeSuccessEnvelope(true).rewound())
    assertNull(takeInitialLink(plugin))
    assertEquals(declines.size + 1, dart.sent.size)
  }

  @Test
  fun lateAcceptanceOfAnOlderLinkKeepsTheNewerOneRetained() {
    val dart = FakeDart()
    val plugin = DeepLinkPlugin()
    plugin.onAttachedToEngine(dart.binding())
    val older = "plezy://play?server=srv-1&id=1"
    val newer = "plezy://live?channel=7"

    plugin.notifyLink(older)
    plugin.notifyLink(newer)
    dart.sent.first().reply.reply(codec.encodeSuccessEnvelope(true).rewound())

    assertEquals(newer, takeInitialLink(plugin))
  }

  @Test
  fun getInitialLinkReturnsALinkThatArrivedBeforeTheEngineOnce() {
    val plugin = DeepLinkPlugin()
    val link = "plezy://open?profile=Kids"

    plugin.notifyLink(link)

    assertEquals(link, takeInitialLink(plugin))
    assertNull(takeInitialLink(plugin))
  }

  @Test
  fun unacceptedLinkSurvivesEngineRecreation() {
    val firstDart = FakeDart()
    val firstBinding = firstDart.binding()
    val first = DeepLinkPlugin()
    first.onAttachedToEngine(firstBinding)
    val link = "plezy://play?type=movie&imdb=tt0111161"

    first.notifyLink(link)
    firstDart.sent.single().reply.reply(null)
    first.onDetachedFromEngine(firstBinding)

    val second = DeepLinkPlugin()
    second.onAttachedToEngine(FakeDart().binding())
    assertEquals(link, takeInitialLink(second))
  }

  private fun viewIntent(link: String) = Intent(Intent.ACTION_VIEW, Uri.parse(link))

  private fun takeInitialLink(plugin: DeepLinkPlugin): Any? {
    val result = RecordingResult()
    plugin.onMethodCall(MethodCall("getInitialLink", null), result)
    assertTrue(result.succeeded)
    return result.successValue
  }

  private class SentCall(val channel: String, val call: MethodCall, val reply: BinaryMessenger.BinaryReply)

  private class FakeDart {
    val sent = mutableListOf<SentCall>()

    private val messenger = Proxy.newProxyInstance(
      BinaryMessenger::class.java.classLoader,
      arrayOf(BinaryMessenger::class.java)
    ) { _, method, args ->
      if (method.name == "send" && args != null && args.size == 3) {
        val message = (args[1] as ByteBuffer).rewound()
        sent += SentCall(args[0] as String, codec.decodeMethodCall(message), args[2] as BinaryMessenger.BinaryReply)
      }
      null
    } as BinaryMessenger

    fun binding(): FlutterPlugin.FlutterPluginBinding {
      val constructor = FlutterPlugin.FlutterPluginBinding::class.java.constructors.single()
      val arguments = constructor.parameterTypes.map { type ->
        when {
          Context::class.java.isAssignableFrom(type) -> RuntimeEnvironment.getApplication()
          BinaryMessenger::class.java.isAssignableFrom(type) -> messenger
          else -> null
        }
      }.toTypedArray()
      return constructor.newInstance(*arguments) as FlutterPlugin.FlutterPluginBinding
    }
  }

  private class RecordingResult : MethodChannel.Result {
    var succeeded = false
    var successValue: Any? = null

    override fun success(result: Any?) {
      succeeded = true
      successValue = result
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}

    override fun notImplemented() {}
  }
}

// The codec leaves a freshly encoded buffer positioned at its end, while the
// engine hands every receiver the bytes from the start.
private fun ByteBuffer.rewound(): ByteBuffer = also { it.rewind() }
