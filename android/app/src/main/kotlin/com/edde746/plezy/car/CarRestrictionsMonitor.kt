package com.edde746.plezy.car

import android.car.Car
import android.car.drivingstate.CarUxRestrictions
import android.car.drivingstate.CarUxRestrictionsManager
import android.content.ComponentName
import android.content.Context
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.view.Display
import com.edde746.plezy.music.CarRestrictionState
import com.edde746.plezy.music.CarRestrictionsSource

/**
 * Android Automotive OS's driver-distraction state, straight from the car service ([CarUxRestrictionsManager]): what
 * tells a car that drives (music must stop: car app quality DD-2/DD-3) from a parked car with the app in the
 * background (ordinary background audio).
 *
 * Bound to the driver's display ([Display.DEFAULT_DISPLAY]) through a display context: an application context has no
 * display, and the manager would then read the user's main display, which under multi-user Automotive can be a
 * passenger's screen. Audio isn't per display, so the driver's verdict is the safe one. Without that display the
 * monitor fails closed ([start] false).
 *
 * The connection never blocks and never takes the process down: from Android 11 `Car.createCar` with
 * [Car.CAR_WAIT_TIMEOUT_DO_NOT_WAIT] and a lifecycle listener (without a listener `createCar` polls for up to five
 * seconds, and a client without one is killed with the car service, `finishClient()`); before, a [ServiceConnection].
 * Each `ready` takes a fresh manager and registers the listener again: the old manager holds a dead binder whose calls
 * answer null. A car service that dies publishes restricted with [supported] false ([unbind]).
 *
 * A manager that holds no restrictions for the display yet (a null verdict) stays [pending]: publishing the restricted
 * default as a verdict would refuse playback for a whole parked session, as no change would come to correct it.
 *
 * `android.car` exists only on Automotive images (the build's `useLibrary`, the manifest's optional `uses-library`):
 * elsewhere its classes are absent, hence the [Throwable] catches. Main thread; the listener's callbacks are posted to
 * it.
 */
internal class CarRestrictionsMonitor(private val context: Context) : CarRestrictionsSource {
    private val main = Handler(Looper.getMainLooper())
    private var car: Car? = null
    private var manager: CarUxRestrictionsManager? = null
    private var connecting = false
    private var legacyConnection = false
    private var listener: ((CarRestrictionState) -> Unit)? = null

    /** A live connection answered for the driver's display; until then [requiresDistractionOptimization] means nothing. */
    var supported: Boolean = false
        private set

    /** The latest verdict; restricted until the car says otherwise, so a half-connected car is never "free to play". */
    var requiresDistractionOptimization: Boolean = true
        private set

    /** A connection exists without a verdict yet (the car service is starting, or died and comes back): worth waiting for. */
    val pending: Boolean get() = connecting && !supported

    private val state: CarRestrictionState
        get() = CarRestrictionState(supported, supported && requiresDistractionOptimization, pending)

    /**
     * Connects (again, while the signal is dark: a car service not ready at launch may answer later; on a phone each try
     * fails at once on the feature check) and answers the state now, or null when this device can't have the signal.
     */
    override fun currentState(callback: (CarRestrictionState?) -> Unit) {
        main.post { callback(if (start()) state else null) }
    }

    override fun setListener(listener: ((CarRestrictionState) -> Unit)?) {
        main.post { this.listener = listener }
    }

    /**
     * Begins connecting. True when this device can have the signal at all (not that it is ready: readiness arrives
     * through the listener); false leaves the caller without it.
     */
    fun start(): Boolean {
        if (supported) return true
        val existing = car
        if (existing != null) {
            // A connection that isn't observing the vehicle (the manager lookup or the registration failed): the car
            // service is up and won't announce itself again, so retry here.
            if (existing.isConnected) bind(existing) else reconnectLegacy()
            return true
        }
        if (connecting) return true
        if (!context.packageManager.hasSystemFeature(PackageManager.FEATURE_AUTOMOTIVE)) return false
        return try {
            val driverDisplay = context.getSystemService(DisplayManager::class.java)?.getDisplay(Display.DEFAULT_DISPLAY) ?: return false
            val displayContext = context.createDisplayContext(driverDisplay)
            connecting = true
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) connectWithLifecycleListener(displayContext) else connectWithServiceConnection(displayContext)
        } catch (error: Throwable) {
            Log.w(TAG, "Car UX restrictions unavailable", error)
            release()
            false
        }
    }

    /** Android 11+: readiness and death through one callback. */
    private fun connectWithLifecycleListener(displayContext: Context): Boolean {
        val created = Car.createCar(displayContext, null, Car.CAR_WAIT_TIMEOUT_DO_NOT_WAIT) { connected: Car, ready: Boolean ->
            // The Car handed over: with the service already up this runs inside createCar, before it returns.
            if (ready) bind(connected) else unbind()
        }
        // A cold service: the listener hasn't run, and this is the only reference to the pending connection.
        if (car == null) car = created
        return true
    }

    /** Android 9 and 10 head units, without the lifecycle listener (naming it there throws `NoSuchMethodError`). */
    @Suppress("DEPRECATION")
    private fun connectWithServiceConnection(displayContext: Context): Boolean {
        legacyConnection = true
        val connection = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
                car?.let(::bind)
            }

            override fun onServiceDisconnected(name: ComponentName?) {
                unbind()
                // Android 10 unbinds within its own disconnect handling: the binding that would reconnect is gone.
                reconnectLegacy()
            }
        }
        val created = Car.createCar(displayContext, connection)
        if (created == null) {
            // No car service loader: clear the connection, or it would read pending for the process's life.
            Log.w(TAG, "Car service loader unavailable")
            release()
            return false
        }
        car = created
        created.connect()
        return true
    }

    private fun reconnectLegacy() {
        if (!legacyConnection) return
        val existing = car ?: return
        if (existing.isConnected || existing.isConnecting) return
        try {
            existing.connect()
        } catch (error: IllegalStateException) {
            Log.w(TAG, "Car service reconnect already under way", error)
        }
    }

    /** Takes a ready car service: a fresh manager, the listener registered, then the verdict read. */
    private fun bind(connected: Car) {
        car = connected
        try {
            val ux = connected.getCarManager(Car.CAR_UX_RESTRICTION_SERVICE) as? CarUxRestrictionsManager
            if (ux == null) {
                Log.w(TAG, "Car service is ready without a UX restrictions manager")
                return
            }
            // Register before reading: registration hears only later changes, and a change between a read and the
            // registration would be lost. Once per manager instance (a retry comes with the same, cached one).
            if (manager !== ux) {
                ux.registerListener { restrictions: CarUxRestrictions ->
                    main.post { adopt(restrictions.isRequiresDistractionOptimization) }
                }
                manager = ux
            }
            val current = ux.currentCarUxRestrictions
            if (current == null) {
                Log.w(TAG, "Car service has no UX restrictions for this display yet; pending until it answers")
                return
            }
            adopt(current.isRequiresDistractionOptimization)
        } catch (error: Throwable) {
            Log.w(TAG, "Couldn't observe car UX restrictions", error)
            manager = null
            supported = false
        }
    }

    /** A real verdict: only now is [requiresDistractionOptimization] to be trusted. */
    private fun adopt(restricted: Boolean) {
        supported = true
        requiresDistractionOptimization = restricted
        listener?.invoke(state)
    }

    /** The car service died: restricted, unsupported, the [Car] kept (its auto-create binding is what reconnects). */
    private fun unbind() {
        Log.w(TAG, "Car service went away")
        manager = null
        supported = false
        requiresDistractionOptimization = true
        listener?.invoke(CarRestrictionState(supported = false, requiresDistractionOptimization = true, pending = pending))
    }

    /** Unregisters and disconnects. Safe when never started. */
    fun release() {
        try {
            manager?.unregisterListener()
        } catch (error: Throwable) {
            Log.w(TAG, "Couldn't unregister the car UX restrictions listener", error)
        }
        try {
            car?.disconnect()
        } catch (error: Throwable) {
            Log.w(TAG, "Couldn't disconnect from the car service", error)
        }
        manager = null
        car = null
        connecting = false
        legacyConnection = false
        supported = false
        requiresDistractionOptimization = true
    }

    private companion object {
        const val TAG = "CarRestrictions"
    }
}
