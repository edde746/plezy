package android.car

import android.car.drivingstate.CarUxRestrictionsManager
import android.content.ComponentName
import android.content.Context
import android.content.ServiceConnection
import android.os.Binder
import android.os.Handler

/**
 * The car service client as the unit tests drive it. The platform's `android.car` library exists only on Automotive
 * images (the build compiles against its stub), so the JVM tests supply this class under its name: the surface
 * `CarRestrictionsMonitor` uses, with the platform's signatures, plus [ready] and [die] to play the car service.
 */
class Car private constructor(
    val context: Context,
    private val connection: ServiceConnection?,
    private val lifecycle: CarServiceLifecycleListener?,
) {
    private var connected = false
    private var connecting = lifecycle != null
    private var uxManager: CarUxRestrictionsManager? = null

    var connects = 0
        private set
    var disconnects = 0
        private set

    fun connect() {
        // The platform throws here too: a client may connect only while neither connected nor connecting.
        check(!connected && !connecting) { "already connected or connecting" }
        connects++
        connecting = true
    }

    fun disconnect() {
        disconnects++
        connected = false
        connecting = false
    }

    fun isConnected(): Boolean = connected

    fun isConnecting(): Boolean = connecting

    fun getCarManager(serviceName: String): Any? = if (serviceName == CAR_UX_RESTRICTION_SERVICE) uxManager else null

    /** The car service comes up, serving [manager]: told to the lifecycle listener, or else to the service connection. */
    fun ready(manager: CarUxRestrictionsManager) {
        connected = true
        connecting = false
        uxManager = manager
        if (lifecycle != null) lifecycle.onLifecycleChanged(this, true) else connection?.onServiceConnected(SERVICE, Binder())
    }

    /** The car service dies: its managers go with it. */
    fun die() {
        connected = false
        connecting = false
        uxManager = null
        if (lifecycle != null) lifecycle.onLifecycleChanged(this, false) else connection?.onServiceDisconnected(SERVICE)
    }

    fun interface CarServiceLifecycleListener {
        fun onLifecycleChanged(car: Car, ready: Boolean)
    }

    companion object {
        const val CAR_UX_RESTRICTION_SERVICE = "uxrestriction"
        const val CAR_WAIT_TIMEOUT_DO_NOT_WAIT = 0L

        private val SERVICE = ComponentName("com.android.car", "com.android.car.CarService")

        /** A car service already up: `createCar` with a lifecycle listener hands it over before returning, as on the main thread. */
        var runningService: CarUxRestrictionsManager? = null

        /** False: the device has no car service loader, and the service connection `createCar` answers null. */
        var loaderAvailable = true

        /** Every client created, oldest first. */
        val created = mutableListOf<Car>()

        /** The wait the lifecycle listener `createCar` was last asked for. */
        var lastWaitTimeout: Long? = null

        fun reset() {
            runningService = null
            loaderAvailable = true
            created.clear()
            lastWaitTimeout = null
        }

        @JvmStatic
        fun createCar(context: Context, serviceConnectionListener: ServiceConnection?): Car? {
            if (!loaderAvailable) return null
            return Car(context, serviceConnectionListener, null).also { created += it }
        }

        @JvmStatic
        fun createCar(context: Context, handler: Handler?, waitTimeoutMs: Long, statusChangeListener: CarServiceLifecycleListener): Car {
            lastWaitTimeout = waitTimeoutMs
            val car = Car(context, null, statusChangeListener).also { created += it }
            runningService?.let(car::ready)
            return car
        }
    }
}
