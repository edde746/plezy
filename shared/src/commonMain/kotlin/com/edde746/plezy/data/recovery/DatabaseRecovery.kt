package com.edde746.plezy.data.recovery

/**
 * What opening the database found on a device whose system may delete it (Apple TV keeps only purgeable storage), and
 * did about it ([com.edde746.plezy.data.LocalData.recovery]). Elsewhere it is always [NOT_APPLICABLE].
 */
enum class DatabaseRecovery {
    /** The database isn't in purgeable storage: nothing to recover, no recovery image kept. */
    NOT_APPLICABLE,

    /** No database and no sign the app was used here before: a first start. */
    FRESH,

    /** The database was there; it is authoritative and the recovery image was renewed from it. */
    ADOPTED_EXISTING,

    /** The system had deleted the database: accounts, profiles and unsent watch actions came back from the image. */
    RESTORED,

    /**
     * The system had deleted the database and the image can't bring it back (missing, damaged, or interrupted), though
     * the app was used here: the user signs in again. Until then ([com.edde746.plezy.data.LocalData.acknowledgeRecoveryRequired],
     * which a new sign-in calls first) accounts, profiles and watch actions can't be changed.
     */
    RECOVERY_REQUIRED,
}

/**
 * A change to accounts, profiles or unsent watch actions was refused because its recovery image couldn't be kept in
 * step with it: the image couldn't be invalidated first, or recovery is required and not yet acknowledged
 * ([DatabaseRecovery.RECOVERY_REQUIRED]). Nothing of the change was written. It names no row data.
 */
class DatabaseDurabilityException : IllegalStateException("Critical local data could not be kept durably")
