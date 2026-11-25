package com.edde746.plezy.desktop.windows

/**
 * The crash-recovery record of a display switch: before the app changes a display's mode or HDR state it persists what
 * to put back ([prepare]) under `HKCU\Software\Plezy\DisplayModeOverride`, and a later start (or a display change) puts
 * back whatever a process that died mid-playback left switched ([recover]).
 *
 * Mode and HDR are two independent operations ([Kind]), each with an operation marker (`ModeChanged`, `HDRChanged`)
 * written after the originals it guards, so a marker is never there without a complete original. A non-live
 * operation whose recovery failed (its display is gone, Windows refused) keeps its marker for a retry at the next
 * display change, and becomes *takeover eligible*: a later conflicting request of the same kind may replace it. The
 * replacement is staged in the inactive of two value slots under a pending handoff, so a crash between the selector
 * switch and the OS call still recovers both originals (the replacement first, the prior one last); an OS refusal rolls
 * the selector back. Records written before the `Version` value (one shared `DeviceName`) are still recovered.
 *
 * Pure logic over a [Backend] (the registry and the display calls), so the ordering is testable without either.
 */
internal object DisplayRecovery {
    /** Where the record lives and what puts a display back; [RegistryRecoveryBackend] in the app. */
    interface Backend {
        fun recordExists(): Boolean
        fun readDword(name: String): Long?
        fun readString(name: String): String?
        fun writeDword(name: String, value: Long): Boolean
        fun writeString(name: String, value: String): Boolean
        fun isDevicePresent(device: String): Boolean
        fun restoreMode(device: String, width: Long, height: Long, refreshRate: Long): Boolean
        fun restoreHdr(device: String, enabled: Boolean): Boolean
        fun clearMarker(name: String): Boolean
        fun deleteRecord(): Boolean
    }

    /** The registry key under HKEY_CURRENT_USER. */
    const val KEY = "Software\\Plezy\\DisplayModeOverride"

    const val VERSION = "Version"
    const val LEGACY_DEVICE_NAME = "DeviceName"
    const val ORIGINAL_WIDTH = "OriginalWidth"
    const val ORIGINAL_HEIGHT = "OriginalHeight"
    const val ORIGINAL_REFRESH_RATE = "OriginalRefreshRate"
    const val ORIGINAL_HDR = "OriginalHDREnabled"
    const val ORIGINAL_WIDTH_ALTERNATE = "OriginalWidthAlternate"
    const val ORIGINAL_HEIGHT_ALTERNATE = "OriginalHeightAlternate"
    const val ORIGINAL_REFRESH_RATE_ALTERNATE = "OriginalRefreshRateAlternate"
    const val ORIGINAL_HDR_ALTERNATE = "OriginalHDREnabledAlternate"
    private const val RECOVERY_VERSION = 1L

    /** The values of one operation. */
    enum class Kind(
        val marker: String,
        val takeover: String,
        val slot: String,
        val previousSlot: String,
        val handoff: String,
        val deviceName: String,
        val deviceNameAlternate: String,
    ) {
        MODE("ModeChanged", "ModeTakeoverEligible", "ModeRecoverySlot", "ModePreviousRecoverySlot", "ModeHandoffPending", "ModeDeviceName", "ModeDeviceNameAlternate"),
        HDR("HDRChanged", "HDRTakeoverEligible", "HDRRecoverySlot", "HDRPreviousRecoverySlot", "HDRHandoffPending", "HDRDeviceName", "HDRDeviceNameAlternate"),
        ;

        val sibling: Kind get() = if (this == MODE) HDR else MODE
    }

    /** Every value the record may hold, for its presence check and its deletion. */
    val VALUES: List<String> = listOf(VERSION, LEGACY_DEVICE_NAME) +
        Kind.entries.flatMap { listOf(it.deviceName, it.marker, it.takeover, it.slot, it.deviceNameAlternate, it.handoff, it.previousSlot) } +
        listOf(ORIGINAL_REFRESH_RATE, ORIGINAL_WIDTH, ORIGINAL_HEIGHT, ORIGINAL_HDR) +
        listOf(ORIGINAL_REFRESH_RATE_ALTERNATE, ORIGINAL_WIDTH_ALTERNATE, ORIGINAL_HEIGHT_ALTERNATE, ORIGINAL_HDR_ALTERNATE)

    /** One operation's original: a mode (width, height, GDI frequency) or an HDR state ([hdr], 0 or 1). */
    private data class Original(val device: String, val width: Long = 0, val height: Long = 0, val refreshRate: Long = 0, val hdr: Long = 0)

    // --- Preparation (before the OS call) and its outcome ---

    /** Persists the original mode of [device] and its marker; false (and no OS call may follow) when it can't. */
    fun prepareMode(backend: Backend, device: String, width: Long, height: Long, refreshRate: Long): Boolean {
        if (device.isEmpty() || width == 0L || height == 0L || refreshRate == 0L) return false
        return prepare(backend, Kind.MODE, Original(device, width, height, refreshRate))
    }

    /** Persists the original HDR state of [device] and its marker; false (and no OS call may follow) when it can't. */
    fun prepareHdr(backend: Backend, device: String, enabled: Boolean): Boolean {
        if (device.isEmpty()) return false
        return prepare(backend, Kind.HDR, Original(device, hdr = if (enabled) 1 else 0))
    }

    /** After the OS call of a prepared operation: confirms a handoff, or rolls it back / retires the marker on failure. */
    fun finalize(backend: Backend, kind: Kind, osApplySucceeded: Boolean): Boolean {
        if (osApplySucceeded) {
            val pending = handoffPending(backend, kind) ?: return false
            return !pending || backend.writeDword(kind.handoff, 0)
        }
        val pending = handoffPending(backend, kind) ?: return false
        return if (pending) rollbackHandoff(backend, kind) else complete(backend, kind)
    }

    /** The operation was undone: clears its handoff, disposition and marker, then the record if nothing is marked. */
    fun complete(backend: Backend, kind: Kind): Boolean {
        // Handoff metadata must be inactive before its shared marker disappears.
        if (!backend.writeDword(kind.handoff, 0) || !backend.writeDword(kind.takeover, 0) || !backend.clearMarker(kind.marker)) return false
        deleteRecordIfNoMarkedOperations(backend)
        return true
    }

    /** The owner gave up on undoing the operation: a later conflicting request of its kind may replace it. */
    fun markTakeoverEligible(backend: Backend, kind: Kind): Boolean = backend.writeDword(kind.takeover, 1)

    private fun prepare(backend: Backend, kind: Kind, original: Original): Boolean {
        if (!preserveValidSiblingOrClear(backend, kind.sibling)) return false
        val existing = readMarked(backend, kind)
        if (existing != null) {
            val (existingOriginal, existingAlternate) = existing
            val pending = handoffPending(backend, kind)
            if (pending == null || pending) return false
            // Reusing the restoration point makes it live again: stale takeover permission is revoked first.
            if (existingOriginal == original) return backend.writeDword(kind.takeover, 0)
            if (backend.readDword(kind.takeover) != 1L) return false
            // Stage the replacement in the inactive slot; the handoff keeps both originals recoverable from the
            // selector switch until the OS call is confirmed.
            val alternate = !existingAlternate
            if (!backend.writeDword(VERSION, RECOVERY_VERSION) || !writeOriginal(backend, kind, alternate, original) ||
                !backend.writeDword(kind.previousSlot, if (existingAlternate) 1 else 0) || !backend.writeDword(kind.takeover, 0)
            ) {
                return false
            }
            if (!backend.writeDword(kind.handoff, 1)) {
                markTakeoverEligible(backend, kind)
                return false
            }
            if (!backend.writeDword(kind.slot, if (alternate) 1 else 0)) {
                rollbackHandoff(backend, kind)
                return false
            }
            return true
        }
        // An incomplete operation has no original to keep: the primary slot, its marker last.
        if (!backend.clearMarker(kind.marker)) return false
        return backend.writeDword(VERSION, RECOVERY_VERSION) && writeOriginal(backend, kind, false, original) &&
            backend.writeDword(kind.handoff, 0) && backend.writeDword(kind.takeover, 0) && backend.writeDword(kind.slot, 0) &&
            backend.writeDword(kind.marker, 1)
    }

    private fun writeOriginal(backend: Backend, kind: Kind, alternate: Boolean, original: Original): Boolean {
        if (!backend.writeString(if (alternate) kind.deviceNameAlternate else kind.deviceName, original.device)) return false
        return when (kind) {
            Kind.MODE -> backend.writeDword(if (alternate) ORIGINAL_WIDTH_ALTERNATE else ORIGINAL_WIDTH, original.width) &&
                backend.writeDword(if (alternate) ORIGINAL_HEIGHT_ALTERNATE else ORIGINAL_HEIGHT, original.height) &&
                backend.writeDword(if (alternate) ORIGINAL_REFRESH_RATE_ALTERNATE else ORIGINAL_REFRESH_RATE, original.refreshRate)
            Kind.HDR -> backend.writeDword(if (alternate) ORIGINAL_HDR_ALTERNATE else ORIGINAL_HDR, original.hdr)
        }
    }

    // --- Recovery ---

    /**
     * Puts back what a dead process left switched; [modeLive]/[hdrLive] skip an operation this process holds (a display
     * change during its own switch). True when every recovered operation completed; false when there was nothing to
     * recover or one failed (it stays for the next display change).
     */
    fun recover(backend: Backend, modeLive: Boolean = false, hdrLive: Boolean = false): Boolean {
        if (!backend.recordExists()) return false
        val version = backend.readDword(VERSION)
        val versioned = version != null
        if (versioned) {
            if (version != RECOVERY_VERSION) {
                backend.deleteRecord()
                return false
            }
        } else if (backend.readString(LEGACY_DEVICE_NAME) == null) {
            // The released layout had no Version and shared one DeviceName between mode and HDR; without it nothing
            // versionless is recovery evidence.
            backend.deleteRecord()
            return false
        }
        val mode = requested(backend, Kind.MODE, versioned, modeLive)
        val hdr = requested(backend, Kind.HDR, versioned, hdrLive)
        val recoverMode = mode != null && !modeLive
        val recoverHdr = hdr != null && !hdrLive
        if (!recoverMode && !recoverHdr) {
            deleteRecordIfNoMarkedOperations(backend)
            return false
        }
        var completed = true
        if (recoverMode && !recoverOperation(backend, Kind.MODE, mode)) completed = false
        if (recoverHdr && !recoverOperation(backend, Kind.HDR, hdr)) completed = false
        return completed
    }

    /** An operation's recovery request: its original, and the pre-handoff original when a handoff was pending. */
    private class Request(val original: Original, val previous: Original?)

    private fun requested(backend: Backend, kind: Kind, versioned: Boolean, live: Boolean): Request? {
        val marker = backend.readDword(kind.marker)
        var request: Request? = null
        if (marker == 1L) {
            request = if (versioned) {
                when (handoffPending(backend, kind)) {
                    null -> null
                    true -> storedSlot(backend, kind.previousSlot)?.let { previousAlternate ->
                        val replacement = readSlot(backend, kind, !previousAlternate)
                        val previous = readSlot(backend, kind, previousAlternate)
                        if (replacement != null && previous != null) Request(replacement, previous) else null
                    }
                    false -> readMarked(backend, kind)?.let { Request(it.first, null) }
                }
            } else {
                readValues(backend, kind, LEGACY_DEVICE_NAME, alternate = false)?.let { Request(it, null) }
            }
        }
        // Malformation in one operation does not erase a valid or live sibling.
        if (!live && (marker == null || marker > 1 || (marker == 1L && request == null))) backend.clearMarker(kind.marker)
        return request
    }

    private fun recoverOperation(backend: Backend, kind: Kind, request: Request): Boolean {
        val restored = restore(backend, kind, request.original)
        val previous = request.previous
        if (previous != null) {
            // The replacement first, the pre-handoff original last. On any failure authority collapses back to the
            // prior slot, so display-change retries don't keep forcing the surviving replacement.
            val previousRestored = restore(backend, kind, previous)
            if (!restored || !previousRestored || !complete(backend, kind)) {
                rollbackHandoff(backend, kind)
                return false
            }
            return true
        }
        if (!restored || !complete(backend, kind)) {
            // Kept for display-change retries; one real failed attempt lets a conflicting request replace it.
            markTakeoverEligible(backend, kind)
            return false
        }
        return true
    }

    private fun restore(backend: Backend, kind: Kind, original: Original): Boolean {
        if (!backend.isDevicePresent(original.device)) return false
        return when (kind) {
            Kind.MODE -> backend.restoreMode(original.device, original.width, original.height, original.refreshRate)
            Kind.HDR -> backend.restoreHdr(original.device, original.hdr != 0L)
        }
    }

    // --- Record reading ---

    private fun readValues(backend: Backend, kind: Kind, deviceValue: String, alternate: Boolean): Original? {
        val device = backend.readString(deviceValue) ?: return null
        return when (kind) {
            Kind.MODE -> {
                val width = backend.readDword(if (alternate) ORIGINAL_WIDTH_ALTERNATE else ORIGINAL_WIDTH)?.takeIf { it > 0 } ?: return null
                val height = backend.readDword(if (alternate) ORIGINAL_HEIGHT_ALTERNATE else ORIGINAL_HEIGHT)?.takeIf { it > 0 } ?: return null
                val rate = backend.readDword(if (alternate) ORIGINAL_REFRESH_RATE_ALTERNATE else ORIGINAL_REFRESH_RATE)?.takeIf { it > 0 } ?: return null
                Original(device, width, height, rate)
            }
            Kind.HDR -> {
                val hdr = backend.readDword(if (alternate) ORIGINAL_HDR_ALTERNATE else ORIGINAL_HDR)?.takeIf { it <= 1 } ?: return null
                Original(device, hdr = hdr)
            }
        }
    }

    private fun readSlot(backend: Backend, kind: Kind, alternate: Boolean): Original? =
        readValues(backend, kind, if (alternate) kind.deviceNameAlternate else kind.deviceName, alternate)

    /** The marked operation's original and whether it is in the alternate slot; null when unmarked or malformed. */
    private fun readMarked(backend: Backend, kind: Kind): Pair<Original, Boolean>? {
        if (backend.readDword(VERSION) != RECOVERY_VERSION || backend.readDword(kind.marker) != 1L) return null
        // Version-1 records from before the alternate slots use the original value set.
        val slot = backend.readDword(kind.slot) ?: 0L
        if (slot > 1) return null
        val alternate = slot == 1L
        return readSlot(backend, kind, alternate)?.let { it to alternate }
    }

    /** Whether a handoff is pending (absent is not); null when the value is malformed. */
    private fun handoffPending(backend: Backend, kind: Kind): Boolean? {
        val value = backend.readDword(kind.handoff) ?: return false
        return if (value > 1) null else value == 1L
    }

    private fun storedSlot(backend: Backend, name: String): Boolean? = backend.readDword(name)?.takeIf { it <= 1 }?.let { it == 1L }

    private fun rollbackHandoff(backend: Backend, kind: Kind): Boolean {
        val previousAlternate = storedSlot(backend, kind.previousSlot) ?: return false
        return backend.writeDword(kind.slot, if (previousAlternate) 1 else 0) && markTakeoverEligible(backend, kind) &&
            backend.writeDword(kind.handoff, 0)
    }

    /** Keeps the sibling's marker when it guards a valid original; clears a malformed one. */
    private fun preserveValidSiblingOrClear(backend: Backend, sibling: Kind): Boolean {
        val marker = backend.readDword(sibling.marker) ?: return backend.writeDword(sibling.marker, 0)
        if (marker == 0L) return true
        if (marker == 1L && readMarked(backend, sibling) != null) return true
        return backend.clearMarker(sibling.marker)
    }

    private fun deleteRecordIfNoMarkedOperations(backend: Backend): Boolean {
        // Missing, malformed or active evidence is kept.
        if (backend.readDword(Kind.MODE.marker) != 0L || backend.readDword(Kind.HDR.marker) != 0L) return false
        // Deletion is best effort once both markers are durably clear.
        backend.deleteRecord()
        return true
    }
}
