package com.edde746.plezy.libass.media

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Test

class AssFontStoreTest {

  @Test
  fun queuedFontsFlushOnceAndResetDropsPendingBuffers() {
    val store = AssFontStore()
    val delivered = mutableListOf<Pair<String, ByteArray>>()
    val deliver: (String, ByteArray) -> Unit = { name, data -> delivered.add(name to data) }
    store.add("first", byteArrayOf(1, 2), nativeReady = false, deliver)
    store.add("second", byteArrayOf(3), nativeReady = false, deliver)

    store.reset(nativeInitialized = false) { error("native clear must stay lazy") }
    store.flush(deliver)
    assertEquals(0, delivered.size)

    store.add("third", byteArrayOf(4, 5), nativeReady = false, deliver)
    store.flush(deliver)
    store.flush(deliver)

    assertEquals(1, delivered.size)
    assertEquals("third", delivered.single().first)
    assertArrayEquals(byteArrayOf(4, 5), delivered.single().second)
  }

  @Test
  fun resetClearsNativeFontsAndNewMediaCanAddAfterward() {
    val store = AssFontStore()
    val delivered = mutableListOf<Pair<String, ByteArray>>()
    val deliver: (String, ByteArray) -> Unit = { name, data -> delivered.add(name to data) }
    var clearCount = 0

    store.add("old", byteArrayOf(1), nativeReady = false, deliver)
    store.flush(deliver)
    store.reset(nativeInitialized = true) { clearCount++ }

    store.add("new", byteArrayOf(2), nativeReady = true, deliver)
    store.reset(nativeInitialized = true) { clearCount++ }

    assertEquals(listOf("old", "new"), delivered.map { it.first })
    assertEquals(2, clearCount)
    assertEquals(0, store.pendingSnapshot().size)
  }
}
