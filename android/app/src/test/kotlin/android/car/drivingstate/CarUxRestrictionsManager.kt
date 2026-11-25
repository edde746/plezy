package android.car.drivingstate

/**
 * The car service's UX restrictions manager as the unit tests drive it (see `android.car.Car` here): the platform's
 * signatures, a record of the calls in order, and [change] to push a new verdict to the registered listener.
 */
class CarUxRestrictionsManager(var current: CarUxRestrictions?) {
    val calls = mutableListOf<String>()

    var listener: OnUxRestrictionsChangedListener? = null
        private set

    fun registerListener(listener: OnUxRestrictionsChangedListener) {
        calls += "register"
        this.listener = listener
    }

    fun unregisterListener() {
        calls += "unregister"
        listener = null
    }

    fun getCurrentCarUxRestrictions(): CarUxRestrictions? {
        calls += "read"
        return current
    }

    fun change(restrictions: CarUxRestrictions) {
        current = restrictions
        listener?.onUxRestrictionsChanged(restrictions)
    }

    fun interface OnUxRestrictionsChangedListener {
        fun onUxRestrictionsChanged(restrictionInfo: CarUxRestrictions)
    }
}

class CarUxRestrictions(private val requiresDistractionOptimization: Boolean) {
    fun isRequiresDistractionOptimization(): Boolean = requiresDistractionOptimization
}
