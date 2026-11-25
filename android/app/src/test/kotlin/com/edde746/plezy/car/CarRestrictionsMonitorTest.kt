package com.edde746.plezy.car

import android.car.Car
import android.car.drivingstate.CarUxRestrictions
import android.car.drivingstate.CarUxRestrictionsManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Looper
import android.view.Display
import com.edde746.plezy.music.CarRestrictionState
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowDisplayManager
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNotSame
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * The car service is played by the test doubles in `android.car` (the platform library exists only on Automotive
 * images). Android 11 for the lifecycle listener route: Robolectric's images from Android 12L on carry the real car
 * library, which would take the doubles' place.
 */
@Config(sdk = [30])
@RunWith(RobolectricTestRunner::class)
class CarRestrictionsMonitorTest {
    private companion object {
        val PARKED = CarRestrictionState(supported = true, requiresDistractionOptimization = false, pending = false)
        val DRIVING = CarRestrictionState(supported = true, requiresDistractionOptimization = true, pending = false)
        val CONNECTING = CarRestrictionState(supported = false, requiresDistractionOptimization = false, pending = true)
        val DIED = CarRestrictionState(supported = false, requiresDistractionOptimization = true, pending = true)
    }

    private val context: Context = RuntimeEnvironment.getApplication()
    private val published = mutableListOf<CarRestrictionState>()
    private lateinit var monitor: CarRestrictionsMonitor

    @Before
    fun startMonitor() {
        Car.reset()
        monitor = CarRestrictionsMonitor(context)
        monitor.setListener { published += it }
        idle()
    }

    @After
    fun releaseMonitor() {
        monitor.release()
    }

    private fun automotive() = shadowOf(context.packageManager).setSystemFeature(PackageManager.FEATURE_AUTOMOTIVE, true)

    private fun idle() = shadowOf(Looper.getMainLooper()).idle()

    private fun parked() = CarUxRestrictionsManager(CarUxRestrictions(requiresDistractionOptimization = false))

    private fun driving() = CarUxRestrictionsManager(CarUxRestrictions(requiresDistractionOptimization = true))

    private fun currentState(): CarRestrictionState? {
        var answered = false
        var answer: CarRestrictionState? = null
        monitor.currentState {
            answered = true
            answer = it
        }
        idle()
        assertTrue(answered)
        return answer
    }

    @Test
    fun aPhoneHasNoCarSignalAndNeverConnects() {
        assertNull(currentState())
        assertFalse(monitor.pending)
        assertTrue(Car.created.isEmpty())
        assertTrue(published.isEmpty())
    }

    @Test
    fun withoutTheDriversDisplayTheMonitorFailsClosed() {
        automotive()
        Car.runningService = parked()
        ShadowDisplayManager.removeDisplay(Display.DEFAULT_DISPLAY)

        assertNull(currentState())
        assertFalse(monitor.pending)
        assertTrue(Car.created.isEmpty())
    }

    @Test
    fun aReadyCarServiceAnswersItsCurrentVerdictForTheDriversDisplay() {
        automotive()
        Car.runningService = parked()

        assertEquals(PARKED, currentState())
        assertEquals(listOf(PARKED), published)
        val car = Car.created.single()
        assertNotSame(context, car.context)
        assertEquals(Display.DEFAULT_DISPLAY, car.context.display.displayId)
        assertEquals(Car.CAR_WAIT_TIMEOUT_DO_NOT_WAIT, Car.lastWaitTimeout)
    }

    @Test
    fun aColdCarServiceIsPendingAndRestrictedUntilItIsReady() {
        automotive()

        assertEquals(CONNECTING, currentState())
        assertTrue(monitor.requiresDistractionOptimization)
        assertTrue(published.isEmpty())

        Car.created.single().ready(parked())
        assertEquals(listOf(PARKED), published)
        assertEquals(PARKED, currentState())
    }

    @Test
    fun theListenerIsRegisteredBeforeTheVerdictIsReadAndOncePerManager() {
        automotive()
        val manager = CarUxRestrictionsManager(null)
        Car.runningService = manager

        assertTrue(monitor.start())
        assertEquals(listOf("register", "read"), manager.calls)

        // Still without a verdict: the retry binds the same, cached manager again.
        assertTrue(monitor.start())
        assertEquals(listOf("register", "read", "read"), manager.calls)
        assertEquals(1, Car.created.size)
    }

    @Test
    fun aCarServiceWithoutRestrictionsYetStaysPendingUntilTheyChange() {
        automotive()
        val manager = CarUxRestrictionsManager(null)
        Car.runningService = manager

        assertEquals(CONNECTING, currentState())
        assertTrue(monitor.pending)
        assertFalse(monitor.supported)
        assertTrue(published.isEmpty())

        manager.change(CarUxRestrictions(requiresDistractionOptimization = false))
        idle()
        assertEquals(listOf(PARKED), published)
        assertEquals(PARKED, currentState())
    }

    @Test
    fun aChangeFromTheCarServicePublishesTheNewVerdict() {
        automotive()
        val manager = parked()
        Car.runningService = manager
        assertEquals(PARKED, currentState())

        manager.change(CarUxRestrictions(requiresDistractionOptimization = true))
        idle()
        assertEquals(listOf(PARKED, DRIVING), published)
        assertEquals(DRIVING, currentState())
    }

    @Test
    fun aDeadCarServicePublishesRestrictedAndUnsupported() {
        automotive()
        Car.runningService = parked()
        assertEquals(PARKED, currentState())
        val car = Car.created.single()

        car.die()
        assertEquals(listOf(PARKED, DIED), published)
        assertFalse(monitor.supported)
        assertTrue(monitor.requiresDistractionOptimization)
        assertTrue(monitor.pending)
        // The client stays: its own binding brings the service back.
        assertEquals(0, car.disconnects)
    }

    @Test
    fun aNewReadyTakesAFreshManagerAndRegistersOnIt() {
        automotive()
        val first = driving()
        Car.runningService = first
        assertEquals(DRIVING, currentState())
        val car = Car.created.single()
        car.die()

        val second = parked()
        car.ready(second)
        assertEquals(listOf("register", "read"), first.calls)
        assertEquals(listOf("register", "read"), second.calls)
        assertEquals(listOf(DRIVING, DIED, PARKED), published)

        second.change(CarUxRestrictions(requiresDistractionOptimization = true))
        idle()
        assertEquals(DRIVING, published.last())
    }

    @Test
    fun releaseUnregistersDisconnectsAndDropsTheVerdict() {
        automotive()
        val manager = parked()
        Car.runningService = manager
        assertEquals(PARKED, currentState())
        val car = Car.created.single()

        monitor.release()
        assertEquals(listOf("register", "read", "unregister"), manager.calls)
        assertEquals(1, car.disconnects)
        assertFalse(monitor.supported)
        assertFalse(monitor.pending)
        assertTrue(monitor.requiresDistractionOptimization)
    }

    @Config(sdk = [29])
    @Test
    fun beforeAndroid11TheServiceConnectionConnectsAndReconnectsAfterADisconnect() {
        automotive()

        assertTrue(monitor.start())
        val car = Car.created.single()
        assertNull(Car.lastWaitTimeout)
        assertEquals(1, car.connects)
        assertTrue(monitor.pending)

        car.ready(parked())
        assertEquals(listOf(PARKED), published)

        car.die()
        assertEquals(listOf(PARKED, DIED), published)
        assertEquals(2, car.connects)

        val second = driving()
        car.ready(second)
        assertEquals(listOf("register", "read"), second.calls)
        assertEquals(listOf(PARKED, DIED, DRIVING), published)
    }

    @Config(sdk = [29])
    @Test
    fun beforeAndroid11WithoutACarServiceLoaderTheSignalIsUnsupportedAndNotPending() {
        automotive()
        Car.loaderAvailable = false

        assertNull(currentState())
        assertFalse(monitor.pending)
        assertFalse(monitor.supported)

        // Nothing is left half-connected: a later try starts over.
        Car.loaderAvailable = true
        assertTrue(monitor.start())
        assertNotNull(Car.created.singleOrNull())
        assertTrue(monitor.pending)
    }
}
