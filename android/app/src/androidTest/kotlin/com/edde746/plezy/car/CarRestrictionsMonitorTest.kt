package com.edde746.plezy.car

import android.content.pm.PackageManager
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Verifies the platform half of the driver-distraction gate on a real device.
 *
 * Everything here is invisible to the Dart unit tests: `android.car` is a compile-time stub, so a
 * missing `useLibrary`, a wrong `uses-library` declaration, a car service that refuses to connect,
 * or an unresolvable default display all compile fine and merely make [CarRestrictionsMonitor.start]
 * return false — at which point Plezy silently falls back to lifecycle gating and parked background
 * audio never works, with no crash to notice.
 *
 * On a non-automotive device the monitor must stay inert instead of throwing, which is the other
 * half of the contract.
 */
@RunWith(AndroidJUnit4::class)
class CarRestrictionsMonitorTest {

  private val context = InstrumentationRegistry.getInstrumentation().targetContext
  private val isCar = context.packageManager.hasSystemFeature(PackageManager.FEATURE_AUTOMOTIVE)

  @Test
  fun reportsSupportOnlyOnACarAndNeverThrows() {
    val monitor = CarRestrictionsMonitor(context)
    val answered = CountDownLatch(1)
    try {
      val started = monitor.start { answered.countDown() }
      if (isCar) {
        assertTrue("android.car is present but the UX-restriction signal did not connect", started)
        // The connect never blocks, so readiness arrives on the main thread while this test thread
        // waits. A timeout here means the car service never handed over a verdict.
        assertTrue("car service never reported its UX restrictions", answered.await(10, TimeUnit.SECONDS))
        assertTrue("a verdict arrived without marking the monitor supported", monitor.supported)
      } else {
        assertFalse("a non-automotive device must not claim car restrictions", started)
        assertFalse(monitor.supported)
      }
    } finally {
      monitor.release()
    }
    assertFalse("release() must drop support so a stale verdict cannot leak", monitor.supported)
  }

  @Test
  fun aParkedEmulatorReportsNoDistractionOptimization() {
    if (!isCar) return
    val monitor = CarRestrictionsMonitor(context)
    val answered = CountDownLatch(1)
    try {
      assertTrue(monitor.start { answered.countDown() })
      assertTrue("car service never reported its UX restrictions", answered.await(10, TimeUnit.SECONDS))
      // The suite runs on a parked vehicle (no VHAL driving injection), which is the state that
      // must permit background audio. A restricted verdict here means the gate would keep music
      // tied to the foreground exactly as before.
      assertFalse(
        "parked car reported that distraction optimization is required",
        monitor.requiresDistractionOptimization
      )
    } finally {
      monitor.release()
    }
  }

  @Test
  fun theServiceConnectionRouteUsedBelowAndroidElevenAlsoReportsTheVehicle() {
    if (!isCar) return
    // No Android 9 or 10 Automotive image is published, so the only way to exercise the path those
    // head units take is to force it here: the deprecated API is present on every version.
    val monitor = CarRestrictionsMonitor(context, forceLegacyConnect = true)
    val answered = CountDownLatch(1)
    try {
      assertTrue("the ServiceConnection route failed to start", monitor.start { answered.countDown() })
      assertTrue("car service never reported through the legacy route", answered.await(20, TimeUnit.SECONDS))
      assertTrue(monitor.supported)
      assertFalse(
        "parked car reported that distraction optimization is required",
        monitor.requiresDistractionOptimization
      )
    } finally {
      monitor.release()
    }
  }
}
