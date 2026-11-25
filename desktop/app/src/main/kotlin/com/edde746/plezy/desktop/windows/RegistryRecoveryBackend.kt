package com.edde746.plezy.desktop.windows

import com.edde746.plezy.desktop.windows.WindowsRegistry.Root.CURRENT_USER

/** [DisplayRecovery]'s record in `HKEY_CURRENT_USER`, and the displays it puts back. */
internal object RegistryRecoveryBackend : DisplayRecovery.Backend {
    private const val KEY = DisplayRecovery.KEY

    override fun recordExists(): Boolean = DisplayRecovery.VALUES.any { WindowsRegistry.exists(CURRENT_USER, KEY, it) }

    override fun readDword(name: String): Long? = WindowsRegistry.dword(CURRENT_USER, KEY, name)

    override fun readString(name: String): String? = WindowsRegistry.string(CURRENT_USER, KEY, name)

    override fun writeDword(name: String, value: Long): Boolean = WindowsRegistry.setDword(CURRENT_USER, KEY, name, value)

    override fun writeString(name: String, value: String): Boolean = WindowsRegistry.setString(CURRENT_USER, KEY, name, value)

    override fun isDevicePresent(device: String): Boolean = WindowsDisplay(device).isPresent()

    override fun restoreMode(device: String, width: Long, height: Long, refreshRate: Long): Boolean =
        WindowsDisplay(device).restoreMode(width.toInt(), height.toInt(), refreshRate.toInt())

    override fun restoreHdr(device: String, enabled: Boolean): Boolean = WindowsDisplay(device).setHdr(enabled)

    override fun clearMarker(name: String): Boolean = writeDword(name, 0)

    override fun deleteRecord(): Boolean = DisplayRecovery.VALUES.map { WindowsRegistry.delete(CURRENT_USER, KEY, it) }.all { it }
}
