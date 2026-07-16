package com.edde746.plezy.shared

import android.os.Handler
import android.os.Looper
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf

@RunWith(RobolectricTestRunner::class)
class MpvContentUriResolverTest {

  @Test
  fun contentDescriptorOpensOffMainAndCompletesOnMain() {
    val mainLooper = Looper.getMainLooper()
    val openedOnMain = AtomicBoolean(true)
    val completedOnMain = AtomicBoolean(false)
    val completed = CountDownLatch(1)

    MpvContentUriResolver.resolve(
      uriString = "content://downloads/video.mkv",
      mainHandler = Handler(mainLooper),
      opener = {
        openedOnMain.set(Looper.myLooper() == mainLooper)
        null
      },
      onResolved = {
        completedOnMain.set(Looper.myLooper() == mainLooper)
        completed.countDown()
      }
    )

    var didComplete = false
    repeat(100) {
      shadowOf(mainLooper).idle()
      if (completed.await(10, TimeUnit.MILLISECONDS)) {
        didComplete = true
        return@repeat
      }
    }

    assertTrue("content URI resolution never completed", didComplete)
    assertFalse("content descriptor opened on the main thread", openedOnMain.get())
    assertTrue("resolved URI callback did not return on the main thread", completedOnMain.get())
  }
}
