package com.edde746.plezy.watchnext

import android.content.Intent
import android.net.Uri
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class WatchNextPluginTest {
  private fun payloadFor(uri: String) = WatchNextPlugin.handleIntent(Intent(Intent.ACTION_VIEW, Uri.parse(uri)))

  @Test
  fun playLinkWithoutProfileForwardsOnlyTheContentId() {
    assertEquals("plezy_abc_1", payloadFor("plezy://play?content_id=plezy_abc_1"))
    assertEquals("plezy_abc_1", payloadFor("plezy://play?content_id=plezy_abc_1&profile="))
  }

  @Test
  fun playLinkWithProfileForwardsTheWholeUri() {
    val link = "plezy://play?content_id=plezy_abc_1&profile=0123456789abcdef"
    assertEquals(link, payloadFor(link))
  }

  @Test
  fun liveLinkForwardsTheWholeUri() {
    val link = "plezy://live?channel=4.1&profile=0123456789abcdef"
    assertEquals(link, payloadFor(link))
  }

  @Test
  fun ignoresOtherLinks() {
    assertNull(payloadFor("https://play?content_id=plezy_abc_1"))
    assertNull(payloadFor("plezy://other?content_id=plezy_abc_1"))
    assertNull(WatchNextPlugin.handleIntent(Intent(Intent.ACTION_VIEW)))
    assertNull(WatchNextPlugin.handleIntent(null))
  }
}
