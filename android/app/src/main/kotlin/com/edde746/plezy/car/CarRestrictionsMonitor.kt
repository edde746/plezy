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
import android.os.IBinder
import android.util.Log
import android.view.Display

/**
 * Reads Android Automotive OS driver-distraction state straight from the platform.
 *
 * Plezy previously derived "may audio play?" from the Flutter activity lifecycle, which conflates
 * two different things: a car that is driving, and a car that is parked with Plezy simply not in
 * the foreground. Only the first must silence playback (car app quality `DD-2`/`DD-3`); the second
 * is ordinary background audio. [CarUxRestrictionsManager] is the signal the platform documents for
 * apps where lifecycle reaction is not sufficient.
 *
 * Bound explicitly to [Display.DEFAULT_DISPLAY] — the driver's screen — by creating a display
 * context for it. An application context would NOT do: it has no associated display, so
 * `CarUxRestrictionsManager` falls back to the current user's assigned main display, which under
 * multi-user Android Automotive OS can be a passenger screen. UX restrictions legitimately differ
 * per display, but audio is not per-display, and `DD-2` requires audio to stop when the user starts
 * driving unless the device declares `com.android.car.background_audio_while_driving`. Reading the
 * driver display therefore keeps a passenger-display session stricter than it may need to be, which
 * is the safe direction; do not rebind this without pairing it with that feature check. If the
 * default display cannot be resolved, [start] fails closed and the caller keeps lifecycle gating.
 *
 * Connection uses the [Car.CarServiceLifecycleListener] overload with
 * [Car.CAR_WAIT_TIMEOUT_DO_NOT_WAIT], which is not a preference:
 *
 *  - `Car.createCar(Context)` blocks the calling thread polling for the car service (AOSP polls
 *    every 50 ms up to 100 times, so up to five seconds) and is reached from the main thread here.
 *  - Worse, a client created without a lifecycle listener is terminated when the car service dies:
 *    the library calls `finishClient()`, which for anything that is not literally an `Activity` or
 *    `Service` — a display context included — runs `Process.killProcess(myPid())`. A routine car
 *    service update would take the whole app down.
 *
 * With the listener, `createCar` never blocks and a service restart arrives as `ready = false`
 * instead. Every `ready = true` re-fetches the manager and re-registers the listener, because the
 * old manager holds a dead binder: its calls then return null and are swallowed, which would look
 * like a permanently parked car rather than a failure.
 *
 * `android.car` is a platform library that only exists on Android Automotive OS images, hence the
 * `useLibrary` compile-time stub, the `uses-library required=false` manifest entry, and the
 * defensive [Throwable] catches: on a phone the classes are simply absent.
 */
class CarRestrictionsMonitor(
  private val context: Context,
  /**
   * Forces the pre-Android-11 [ServiceConnection] route on a device that also has the newer one, so
   * instrumentation can exercise it: no Android 9 or 10 Automotive system image is published.
   */
  private val forceLegacyConnect: Boolean = false
) {

  private var car: Car? = null
  private var manager: CarUxRestrictionsManager? = null
  private var onChanged: ((Boolean) -> Unit)? = null
  private var connecting = false
  private var legacyConnection = false

  /**
   * True while a live car connection can answer; until then callers must not trust
   * [requiresDistractionOptimization]. Goes back to false if the car service dies.
   */
  var supported: Boolean = false
    private set

  /**
   * Latest platform verdict. Defaults to restricted so a half-connected car can never be read as
   * "free to play"; [supported] is what gates whether this value is used at all.
   */
  var requiresDistractionOptimization: Boolean = true
    private set

  /**
   * A connection exists but has not produced a verdict yet — the car service is starting, or died
   * and is expected back. Callers that gate behaviour on the verdict should wait rather than treat
   * this like a phone, where no answer is ever coming.
   */
  val pending: Boolean
    get() = connecting && !supported

  /**
   * Begins connecting to the car service. Returns whether this device can have the signal at all,
   * NOT whether it is ready: readiness arrives through [onChanged], and [supported] reports it.
   * A false return leaves the caller on its previous (lifecycle-derived) behaviour for good.
   */
  fun start(onChanged: (Boolean) -> Unit): Boolean {
    if (supported) return true
    val existing = car
    if (existing != null) {
      // A connection exists but is not observing the vehicle: the manager lookup or the listener
      // registration failed. Retry it here, because the car service is already ready and will not
      // announce itself again — without this the signal would stay dark for the whole process.
      this.onChanged = onChanged
      if (existing.isConnected) bind(existing) else reconnectLegacyIfNeeded()
      return true
    }
    if (connecting) return true
    if (!context.packageManager.hasSystemFeature(PackageManager.FEATURE_AUTOMOTIVE)) return false

    return try {
      // Fail closed when the driver display cannot be resolved: an unbound context would silently
      // report some other display's restrictions (see the class doc).
      val displayManager = context.getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager ?: return false
      val driverDisplay = displayManager.getDisplay(Display.DEFAULT_DISPLAY) ?: return false
      val displayContext = context.createDisplayContext(driverDisplay)
      this.onChanged = onChanged
      connecting = true
      if (!forceLegacyConnect && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
        connectWithLifecycleListener(displayContext)
      } else {
        connectWithServiceConnection(displayContext)
      }
    } catch (error: Throwable) {
      Log.w(TAG, "Car UX restrictions unavailable; falling back to lifecycle gating", error)
      release()
      false
    }
  }

  /** Android 11 and newer: the car service announces readiness and death through one callback. */
  private fun connectWithLifecycleListener(displayContext: Context): Boolean {
    val created = Car.createCar(
      displayContext,
      null,
      Car.CAR_WAIT_TIMEOUT_DO_NOT_WAIT
    ) { connectedCar: Car, ready: Boolean ->
      // Use the Car handed to the listener: on the synchronous path — the car service is already
      // up and this runs on the main thread — it fires inside createCar, before it returns.
      if (ready) bind(connectedCar) else unbind()
    }
    // Cold service: the listener has not run, so this is the only reference to the pending
    // connection and release() would otherwise leave it bound for the process's lifetime.
    if (car == null) car = created
    return true
  }

  /**
   * Android 9 and 10 head units, which have no [Car.CarServiceLifecycleListener].
   *
   * A [ServiceConnection] is the safe alternative, not merely an older one: the process kill in
   * `finishClient()` is reached only by a client that supplies neither callback, and binding here is
   * asynchronous, so nothing blocks. Kept behind a version check because naming the newer overload
   * on such a device raises `NoSuchMethodError`.
   */
  @Suppress("DEPRECATION")
  private fun connectWithServiceConnection(displayContext: Context): Boolean {
    legacyConnection = true
    val connection = object : ServiceConnection {
      override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
        car?.let { bind(it) }
      }

      override fun onServiceDisconnected(name: ComponentName?) {
        unbind()
        // Android 10 unbinds inside its own disconnect handling, so the binding that would have
        // reconnected is gone; newer platforms keep it and race us harmlessly.
        reconnectLegacyIfNeeded()
      }
    }
    val created = Car.createCar(displayContext, connection)
    if (created == null) {
      // The platform returns null when the car service loader is unavailable. Clearing the
      // connection state matters: leaving it set would report a pending verdict for the rest of the
      // process, and every later start would short-circuit instead of trying again.
      Log.w(TAG, "Car service loader unavailable; falling back to lifecycle gating for now")
      release()
      return false
    }
    car = created
    created.connect()
    return true
  }

  private fun reconnectLegacyIfNeeded() {
    if (!legacyConnection) return
    val existing = car ?: return
    if (existing.isConnected || existing.isConnecting) return
    try {
      existing.connect()
    } catch (error: IllegalStateException) {
      // The platform's own reconnect won the race, which is the outcome we wanted anyway.
      Log.w(TAG, "Car service reconnect already in progress", error)
    }
  }

  /** Adopts a ready car service: fresh manager, fresh listener, fresh verdict. */
  private fun bind(connectedCar: Car) {
    car = connectedCar
    try {
      val uxManager = connectedCar.getCarManager(Car.CAR_UX_RESTRICTION_SERVICE) as? CarUxRestrictionsManager
      if (uxManager == null) {
        Log.w(TAG, "Car service is ready but has no UX restrictions manager")
        return
      }
      manager = uxManager
      // Register before reading, per the platform's own guidance: registration subscribes to future
      // changes only, it does not replay the current one. Reading first would drop a transition that
      // lands between the two binder calls, and publishing the stale "parked" afterwards would then
      // override lifecycle gating and permit audio for the whole drive.
      uxManager.registerListener { restrictions: CarUxRestrictions -> publish(restrictions.isRequiresDistractionOptimization) }
      supported = true
      publish(uxManager.currentCarUxRestrictions?.isRequiresDistractionOptimization ?: true)
    } catch (error: Throwable) {
      // Registration is the failure the caller's retry is meant to survive, so keep the connection
      // owned (it is in `car`) and report nothing rather than half-observing the vehicle.
      Log.w(TAG, "Failed to observe car UX restrictions", error)
      manager = null
      supported = false
    }
  }

  /**
   * Drops a dead car service. The [Car] itself is kept: its `BIND_AUTO_CREATE` binding is what
   * reconnects, and disconnecting would end that for good.
   */
  private fun unbind() {
    Log.w(TAG, "Car service went away; falling back to lifecycle gating until it returns")
    manager = null
    supported = false
    requiresDistractionOptimization = true
    onChanged?.invoke(true)
  }

  private fun publish(restricted: Boolean) {
    requiresDistractionOptimization = restricted
    onChanged?.invoke(restricted)
  }

  /** Unregisters and disconnects. Safe to call when never started. */
  fun release() {
    try {
      manager?.unregisterListener()
    } catch (error: Throwable) {
      Log.w(TAG, "Failed to unregister car UX restrictions listener", error)
    }
    try {
      car?.disconnect()
    } catch (error: Throwable) {
      Log.w(TAG, "Failed to disconnect from the car service", error)
    }
    manager = null
    car = null
    onChanged = null
    connecting = false
    legacyConnection = false
    supported = false
    requiresDistractionOptimization = true
  }

  private companion object {
    const val TAG = "CarRestrictions"
  }
}
