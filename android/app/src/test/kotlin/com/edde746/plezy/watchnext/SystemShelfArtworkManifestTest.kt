package com.edde746.plezy.watchnext

import java.io.File
import javax.xml.parsers.DocumentBuilderFactory
import org.junit.Assert.assertEquals
import org.junit.Test
import org.w3c.dom.Element

/**
 * [SystemShelfArtworkProvider] performs no caller-identity check of its own, because the launcher
 * rendering the Watch Next row is not necessarily the resolved default HOME activity (issue #1706).
 * The manifest declaration is therefore the only thing standing between a launcher-scoped read
 * grant and every app on the device.
 */
class SystemShelfArtworkManifestTest {
  private companion object {
    const val ANDROID_NAMESPACE = "http://schemas.android.com/apk/res/android"
    const val AUTHORITY = "com.edde746.plezy.systemshelf.artwork"
    val MANIFEST_CANDIDATES = listOf(
      "src/main/AndroidManifest.xml",
      "app/src/main/AndroidManifest.xml",
      "android/app/src/main/AndroidManifest.xml"
    )
  }

  @Test
  fun artworkProviderIsReachableOnlyThroughUriGrants() {
    val provider = artworkProvider()

    assertEquals("false", provider.getAttributeNS(ANDROID_NAMESPACE, "exported"))
    assertEquals("true", provider.getAttributeNS(ANDROID_NAMESPACE, "grantUriPermissions"))
  }

  private fun artworkProvider(): Element {
    val manifest = DocumentBuilderFactory.newInstance()
      .apply { isNamespaceAware = true }
      .newDocumentBuilder()
      .parse(manifestFile())
    val providers = manifest.getElementsByTagName("provider")
    for (index in 0 until providers.length) {
      val provider = providers.item(index) as Element
      if (provider.getAttributeNS(ANDROID_NAMESPACE, "authorities") == AUTHORITY) return provider
    }
    throw AssertionError("No <provider> declares android:authorities=\"$AUTHORITY\"")
  }

  private fun manifestFile(): File {
    var directory: File? = File(System.getProperty("user.dir")).absoluteFile
    while (directory != null) {
      for (candidate in MANIFEST_CANDIDATES) {
        val manifest = File(directory, candidate)
        if (manifest.isFile) return manifest
      }
      directory = directory.parentFile
    }
    throw AssertionError("AndroidManifest.xml not found from ${System.getProperty("user.dir")}")
  }
}
