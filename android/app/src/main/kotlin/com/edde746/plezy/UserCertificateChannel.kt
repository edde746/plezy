package com.edde746.plezy

import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import java.security.cert.X509Certificate

/**
 * Hands the certificate authorities the device owner installed (Settings > Security > User
 * credentials) to Dart.
 *
 * dart:io does its own TLS with BoringSSL and reads only the system store on disk, so the
 * `<certificates src="user" />` anchor in network_security_config.xml never reaches it. A
 * self-hosted Jellyfin behind a private CA therefore failed every handshake even though the
 * device trusted that CA (#1564 fixed this for Cronet; #2339 is the same fault after the move
 * to the dart:io client). Android exposes both stores through the `AndroidCAStore` KeyStore,
 * with user-installed entries under a `user:` alias prefix.
 */
internal class UserCertificateChannel {
  companion object {
    private const val TAG = "UserCertificateChannel"
    private const val CHANNEL = "com.plezy/user_certificates"
    private const val USER_ALIAS_PREFIX = "user:"
    private const val PEM_LINE_LENGTH = 64

    /**
     * Every user-installed authority in [keyStore] as one PEM bundle, in KeyStore alias order.
     * Empty when the owner installed none. A single unreadable entry is skipped rather than
     * failing the whole store: one bad certificate must not cost the others their trust.
     */
    fun userAuthoritiesPem(keyStore: KeyStore): String {
      val pem = StringBuilder()
      for (alias in keyStore.aliases()) {
        if (!alias.startsWith(USER_ALIAS_PREFIX)) continue
        val certificate = try {
          keyStore.getCertificate(alias) as? X509Certificate
        } catch (e: Exception) {
          Log.w(TAG, "Skipping unreadable user certificate authority", e)
          null
        } ?: continue
        pem.append("-----BEGIN CERTIFICATE-----\n")
        Base64.encodeToString(certificate.encoded, Base64.NO_WRAP).chunked(PEM_LINE_LENGTH).forEach { line ->
          pem.append(line).append('\n')
        }
        pem.append("-----END CERTIFICATE-----\n")
      }
      return pem.toString()
    }
  }

  private val mainThread = Handler(Looper.getMainLooper())

  fun attach(messenger: BinaryMessenger) {
    MethodChannel(messenger, CHANNEL).setMethodCallHandler(::onMethodCall)
  }

  private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "getUserAuthoritiesPem" -> loadUserAuthorities(result)
      else -> result.notImplemented()
    }
  }

  // The KeyStore walks the certificate directories on disk; keep that off the platform thread
  // the Flutter engine is starting on.
  private fun loadUserAuthorities(result: MethodChannel.Result) {
    val worker = Thread({
      val pem = try {
        val keyStore = KeyStore.getInstance("AndroidCAStore")
        keyStore.load(null)
        userAuthoritiesPem(keyStore)
      } catch (e: Exception) {
        Log.w(TAG, "User certificate authorities unavailable", e)
        null
      }
      mainThread.post {
        if (pem == null) {
          result.error("unavailable", "The Android certificate store could not be read", null)
        } else {
          result.success(pem)
        }
      }
    }, "plezy-user-certificates")
    worker.isDaemon = true
    worker.start()
  }
}
