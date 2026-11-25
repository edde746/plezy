package com.edde746.plezy.desktop.windows

import com.edde746.plezy.desktop.bind
import com.edde746.plezy.desktop.int
import java.lang.foreign.Arena
import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.MemorySegment
import java.lang.foreign.SymbolLookup
import java.lang.foreign.ValueLayout.ADDRESS
import java.lang.foreign.ValueLayout.JAVA_INT
import java.lang.foreign.ValueLayout.JAVA_SHORT
import java.lang.invoke.MethodHandle
import java.nio.charset.StandardCharsets.UTF_16LE

/**
 * A Windows display (a GDI device such as `\\.\DISPLAY1`): its modes at the current resolution, its HDR state, and
 * switching both for playback.
 *
 * - Modes come from `EnumDisplaySettingsExW`, whose rates are whole hertz rounded down (23 is 23.976 Hz); [refreshOf]
 *   reads them the way mpv does. The current mode's exact rate comes from the DisplayConfig API (239.991 Hz).
 * - [setMode] switches with `ChangeDisplaySettingsExW(CDS_FULLSCREEN)`: a temporary mode that Windows drops when the
 *   process ends, however it ends; [restoreMode] goes back to the mode in the registry.
 * - HDR ("Use HDR") through `DisplayConfigGetDeviceInfo`/`DisplayConfigSetDeviceInfo`: the HDR info and state of
 *   Windows 11 24H2 and later, else the advanced colour info and state of earlier builds; and the SDR white level
 *   (Settings' "SDR content brightness"), where DWM shows SDR content while HDR is on.
 *
 * DisplayConfig needs the interactive session (SSH's session 0 is denied). Calls block (a mode switch takes a moment);
 * make them off the UI thread.
 */
internal class WindowsDisplay(val device: String) {
    /** A mode at the display's current resolution: [frequency] as GDI lists it, [refreshHz] what it means. */
    data class Mode(val width: Int, val height: Int, val frequency: Int, val refreshHz: Double)

    data class Hdr(val supported: Boolean, val enabled: Boolean)

    /** The current mode, with the exact rate when DisplayConfig knows the display. */
    fun currentMode(): Mode? = Arena.ofConfined().use { a ->
        val mode = a.devMode()
        if (Api.enumDisplaySettingsExW.int(a.wide(device), ENUM_CURRENT_SETTINGS, mode, 0) == 0) return null
        val frequency = mode.get(JAVA_INT, DM_FREQUENCY)
        Mode(mode.get(JAVA_INT, DM_WIDTH), mode.get(JAVA_INT, DM_HEIGHT), frequency, target()?.refreshHz ?: refreshOf(frequency))
    }

    /** The progressive modes at the current resolution, one per rate, slowest first. */
    fun modes(): List<Mode> = Arena.ofConfined().use { a ->
        val current = currentMode() ?: return emptyList()
        val name = a.wide(device)
        val mode = a.devMode()
        val frequencies = sortedSetOf<Int>()
        var i = 0
        while (Api.enumDisplaySettingsExW.int(name, i++, mode, 0) != 0) {
            val progressive = mode.get(JAVA_INT, DM_DISPLAY_FLAGS) and DM_INTERLACED == 0
            if (progressive && mode.get(JAVA_INT, DM_WIDTH) == current.width && mode.get(JAVA_INT, DM_HEIGHT) == current.height) {
                frequencies += mode.get(JAVA_INT, DM_FREQUENCY)
            }
            mode.fill(0)
            mode.set(JAVA_SHORT, DM_SIZE, DEVMODE_BYTES.toShort())
        }
        frequencies.filter { it > 1 }.map { f -> if (f == current.frequency) current else Mode(current.width, current.height, f, refreshOf(f)) }
    }

    /**
     * Switches to [mode] until [restoreMode] or the process ends; false when Windows refuses it. Exactly 24, 48 and
     * 60 Hz go through the registry (written without a reset, applied, then put back), where a direct switch on
     * Windows 8 and later can land on the NTSC rate next to them.
     */
    fun setMode(mode: Mode): Boolean = Arena.ofConfined().use { a ->
        val name = a.wide(device)
        val devMode = a.devMode()
        devMode.set(JAVA_INT, DM_FIELDS, DM_PELSWIDTH or DM_PELSHEIGHT or DM_DISPLAYFREQUENCY)
        devMode.set(JAVA_INT, DM_WIDTH, mode.width)
        devMode.set(JAVA_INT, DM_HEIGHT, mode.height)
        devMode.set(JAVA_INT, DM_FREQUENCY, mode.frequency)
        if (mode.frequency in REGISTRY_RATES) {
            val registry = a.devMode()
            if (Api.enumDisplaySettingsExW.int(name, ENUM_REGISTRY_SETTINGS, registry, 0) != 0 &&
                Api.changeDisplaySettingsExW.int(name, devMode, MemorySegment.NULL, CDS_UPDATEREGISTRY or CDS_NORESET, MemorySegment.NULL) == DISP_CHANGE_SUCCESSFUL
            ) {
                val changed = Api.changeDisplaySettingsExW.int(name, MemorySegment.NULL, MemorySegment.NULL, CDS_FULLSCREEN, MemorySegment.NULL) == DISP_CHANGE_SUCCESSFUL
                registry.set(JAVA_INT, DM_FIELDS, DM_PELSWIDTH or DM_PELSHEIGHT or DM_DISPLAYFREQUENCY or DM_DISPLAYFLAGS)
                Api.changeDisplaySettingsExW.int(name, registry, MemorySegment.NULL, CDS_UPDATEREGISTRY or CDS_NORESET, MemorySegment.NULL)
                if (changed) return@use true
            }
        }
        Api.changeDisplaySettingsExW.int(name, devMode, MemorySegment.NULL, CDS_FULLSCREEN, MemorySegment.NULL) == DISP_CHANGE_SUCCESSFUL
    }

    /**
     * Back to the user's saved display configuration, dropping a [setMode] mode: the display database first (it keeps a
     * Dynamic Refresh Rate selection a mode can't express), else the mode in the registry.
     */
    fun restoreMode(): Boolean = Api.setDisplayConfig.int(0, MemorySegment.NULL, 0, MemorySegment.NULL, SDC_APPLY or SDC_USE_DATABASE_CURRENT) == 0 ||
        Arena.ofConfined().use { a ->
            Api.changeDisplaySettingsExW.int(a.wide(device), MemorySegment.NULL, MemorySegment.NULL, 0, MemorySegment.NULL) == DISP_CHANGE_SUCCESSFUL
        }

    /**
     * Back to [width]×[height] at GDI [frequency] (a crash's recorded original): the saved configuration when it gives
     * that mode, else that mode itself.
     */
    fun restoreMode(width: Int, height: Int, frequency: Int): Boolean {
        if (restoreMode()) {
            val current = currentMode()
            if (current != null && current.width == width && current.height == height && current.frequency == frequency) return true
        }
        return setMode(Mode(width, height, frequency, refreshOf(frequency)))
    }

    /** Whether Windows still has this display. */
    fun isPresent(): Boolean = Arena.ofConfined().use { a ->
        Api.enumDisplaySettingsExW.int(a.wide(device), ENUM_CURRENT_SETTINGS, a.devMode(), 0) != 0
    }

    /**
     * Whether the display can show HDR (not just wide colour) and has it on; null when DisplayConfig doesn't know it.
     * Windows 11 24H2 and later say so directly (HDR supported; the active colour mode is HDR); before it, advanced
     * colour that isn't enforced wide colour (an SDR screen with automatic colour management) is HDR.
     */
    fun hdr(): Hdr? {
        val target = target() ?: return null
        return Arena.ofConfined().use { a ->
            val info = a.header(GET_ADVANCED_COLOR_INFO_2, 36, target)
            if (Api.displayConfigGetDeviceInfo.int(info) == 0) {
                val supported = info.get(JAVA_INT, 20) and 0x10 != 0 // highDynamicRangeSupported
                return@use Hdr(supported = supported, enabled = info.get(JAVA_INT, 32) == ADVANCED_COLOR_MODE_HDR)
            }
            val legacy = a.header(GET_ADVANCED_COLOR_INFO, 32, target)
            if (Api.displayConfigGetDeviceInfo.int(legacy) != 0) return@use null
            val value = legacy.get(JAVA_INT, 20)
            // advancedColorSupported && !wideColorEnforced; enabled is advancedColorEnabled on such a display.
            val supported = value and 0x1 != 0 && value and 0x4 == 0
            Hdr(supported = supported, enabled = supported && value and 0x2 != 0)
        }
    }

    /** Turns HDR on or off and waits (up to 5 s) until the display reports it; false when it didn't take. */
    fun setHdr(enabled: Boolean): Boolean {
        val target = target() ?: return false
        val set = Arena.ofConfined().use { a ->
            val state = a.header(SET_HDR_STATE, 24, target)
            state.set(JAVA_INT, 20, if (enabled) 1 else 0)
            Api.displayConfigSetDeviceInfo.int(state) == 0 || run {
                val legacy = a.header(SET_ADVANCED_COLOR_STATE, 24, target)
                legacy.set(JAVA_INT, 20, if (enabled) 1 else 0)
                Api.displayConfigSetDeviceInfo.int(legacy) == 0
            }
        }
        if (!set) return false
        val deadline = System.nanoTime() + 5_000_000_000L
        while (System.nanoTime() < deadline) {
            if (hdr()?.enabled == enabled) return true
            Thread.sleep(100)
        }
        return false
    }

    /** Where SDR white shows while HDR is on, in cd/m² (80 to 480); null when DisplayConfig doesn't know it. */
    fun sdrWhiteNits(): Double? {
        val target = target() ?: return null
        return Arena.ofConfined().use { a ->
            // DISPLAYCONFIG_SDR_WHITE_LEVEL: thousandths of 80 cd/m².
            val level = a.header(GET_SDR_WHITE_LEVEL, 24, target)
            if (Api.displayConfigGetDeviceInfo.int(level) != 0) return@use null
            level.get(JAVA_INT, 20).toUInt().toDouble() * 80.0 / 1000.0
        }
    }

    /** The DisplayConfig target (monitor) of this GDI device, with the exact rate of its current mode. */
    private class Target(val adapterLow: Int, val adapterHigh: Int, val id: Int, val refreshHz: Double?)

    private fun target(): Target? = Arena.ofConfined().use { a ->
        val counts = a.allocate(JAVA_INT, 2)
        if (Api.getDisplayConfigBufferSizes.int(QDC_ONLY_ACTIVE_PATHS, counts, counts.asSlice(4)) != 0) return null
        val paths = a.allocate(PATH_BYTES * counts.getAtIndex(JAVA_INT, 0).toLong())
        val modes = a.allocate(MODE_BYTES * counts.getAtIndex(JAVA_INT, 1).toLong())
        if (Api.queryDisplayConfig.int(QDC_ONLY_ACTIVE_PATHS, counts, paths, counts.asSlice(4), modes, MemorySegment.NULL) != 0) return null
        for (i in 0 until counts.getAtIndex(JAVA_INT, 0)) {
            val path = paths.asSlice(i * PATH_BYTES, PATH_BYTES)
            // DISPLAYCONFIG_SOURCE_DEVICE_NAME: the GDI name of the path's source.
            val source = a.allocate(84)
            source.set(JAVA_INT, 0, GET_SOURCE_NAME)
            source.set(JAVA_INT, 4, 84)
            source.set(JAVA_INT, 8, path.get(JAVA_INT, 0))
            source.set(JAVA_INT, 12, path.get(JAVA_INT, 4))
            source.set(JAVA_INT, 16, path.get(JAVA_INT, 8))
            if (Api.displayConfigGetDeviceInfo.int(source) != 0 || !source.getString(20, UTF_16LE).equals(device, ignoreCase = true)) continue
            val numerator = path.get(JAVA_INT, 48).toUInt().toDouble()
            val denominator = path.get(JAVA_INT, 52).toUInt().toDouble()
            return@use Target(path.get(JAVA_INT, 20), path.get(JAVA_INT, 24), path.get(JAVA_INT, 28), if (denominator > 0) numerator / denominator else null)
        }
        null
    }

    private fun Arena.header(type: Int, size: Int, target: Target): MemorySegment = allocate(size.toLong()).also {
        it.set(JAVA_INT, 0, type)
        it.set(JAVA_INT, 4, size)
        it.set(JAVA_INT, 8, target.adapterLow)
        it.set(JAVA_INT, 12, target.adapterHigh)
        it.set(JAVA_INT, 16, target.id)
    }

    private fun Arena.devMode(): MemorySegment = allocate(DEVMODE_BYTES.toLong()).also { it.set(JAVA_SHORT, DM_SIZE, DEVMODE_BYTES.toShort()) }

    private fun Arena.wide(text: String): MemorySegment = allocateFrom(text, UTF_16LE)

    companion object {
        /** DEVMODEW (220 bytes) and the offsets of its display fields. */
        private const val DEVMODE_BYTES = 220
        private const val DM_SIZE = 68L
        private const val DM_FIELDS = 72L
        private const val DM_WIDTH = 172L
        private const val DM_HEIGHT = 176L
        private const val DM_DISPLAY_FLAGS = 180L
        private const val DM_FREQUENCY = 184L
        private const val DM_PELSWIDTH = 0x80000
        private const val DM_PELSHEIGHT = 0x100000
        private const val DM_DISPLAYFREQUENCY = 0x400000
        private const val ENUM_REGISTRY_SETTINGS = -2
        private const val CDS_UPDATEREGISTRY = 0x1
        private const val CDS_NORESET = 0x10000000
        private const val DM_DISPLAYFLAGS = 0x200000
        private val REGISTRY_RATES = setOf(24, 48, 60)
        private const val SDC_APPLY = 0x80
        private const val SDC_USE_DATABASE_CURRENT = 0xF
        private const val ADVANCED_COLOR_MODE_HDR = 2
        private const val DM_INTERLACED = 0x2
        private const val ENUM_CURRENT_SETTINGS = -1
        private const val CDS_FULLSCREEN = 0x4
        private const val DISP_CHANGE_SUCCESSFUL = 0

        /** DISPLAYCONFIG_PATH_INFO and DISPLAYCONFIG_MODE_INFO sizes; the device info types used. */
        private const val PATH_BYTES = 72L
        private const val MODE_BYTES = 64L
        private const val QDC_ONLY_ACTIVE_PATHS = 2
        private const val GET_SOURCE_NAME = 1
        private const val GET_ADVANCED_COLOR_INFO = 9
        private const val SET_ADVANCED_COLOR_STATE = 10
        private const val GET_SDR_WHITE_LEVEL = 11
        private const val GET_ADVANCED_COLOR_INFO_2 = 15
        private const val SET_HDR_STATE = 16

        private const val MONITOR_DEFAULTTONEAREST = 2

        /**
         * The rate a GDI frequency stands for: GDI rounds down, so 23, 29, 59, 119… are the NTSC rates (24/1.001 Hz and
         * multiples), as mpv reads them (`get_refresh_rate_from_gdi`).
         */
        fun refreshOf(frequency: Int): Double =
            if (frequency in NTSC_FLOORS) (frequency + 1) / 1.001 else frequency.toDouble()

        private val NTSC_FLOORS = setOf(23, 29, 47, 59, 71, 89, 95, 119, 143, 164, 239, 359, 479)

        /** The display the window [hwnd] is on (the one nearest to it). */
        fun forWindow(hwnd: Long): WindowsDisplay = Arena.ofConfined().use { a ->
            val monitor = Api.monitorFromWindow.invokeWithArguments(MemorySegment.ofAddress(hwnd), MONITOR_DEFAULTTONEAREST) as MemorySegment
            val info = a.allocate(104) // MONITORINFOEXW
            info.set(JAVA_INT, 0, 104)
            check(Api.getMonitorInfoW.int(monitor, info) != 0) { "GetMonitorInfoW failed" }
            WindowsDisplay(info.getString(40, UTF_16LE))
        }
    }

    /** user32's display functions, bound on first use. */
    private object Api {
        private val user32 = SymbolLookup.libraryLookup("user32", Arena.global())

        val monitorFromWindow: MethodHandle = user32.bind("MonitorFromWindow", FunctionDescriptor.of(ADDRESS, ADDRESS, JAVA_INT))
        val getMonitorInfoW: MethodHandle = user32.bind("GetMonitorInfoW", FunctionDescriptor.of(JAVA_INT, ADDRESS, ADDRESS))
        val enumDisplaySettingsExW: MethodHandle = user32.bind("EnumDisplaySettingsExW", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_INT, ADDRESS, JAVA_INT))
        val changeDisplaySettingsExW: MethodHandle = user32.bind(
            "ChangeDisplaySettingsExW",
            FunctionDescriptor.of(JAVA_INT, ADDRESS, ADDRESS, ADDRESS, JAVA_INT, ADDRESS),
        )
        val getDisplayConfigBufferSizes: MethodHandle = user32.bind("GetDisplayConfigBufferSizes", FunctionDescriptor.of(JAVA_INT, JAVA_INT, ADDRESS, ADDRESS))
        val queryDisplayConfig: MethodHandle = user32.bind(
            "QueryDisplayConfig",
            FunctionDescriptor.of(JAVA_INT, JAVA_INT, ADDRESS, ADDRESS, ADDRESS, ADDRESS, ADDRESS),
        )
        val displayConfigGetDeviceInfo: MethodHandle = user32.bind("DisplayConfigGetDeviceInfo", FunctionDescriptor.of(JAVA_INT, ADDRESS))
        val displayConfigSetDeviceInfo: MethodHandle = user32.bind("DisplayConfigSetDeviceInfo", FunctionDescriptor.of(JAVA_INT, ADDRESS))
        val setDisplayConfig: MethodHandle = user32.bind(
            "SetDisplayConfig",
            FunctionDescriptor.of(JAVA_INT, JAVA_INT, ADDRESS, JAVA_INT, ADDRESS, JAVA_INT),
        )
    }
}
