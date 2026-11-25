package com.edde746.plezy.desktop

import com.edde746.plezy.app.DeviceIdentity
import com.edde746.plezy.desktop.windows.WindowsRegistry
import com.edde746.plezy.log.Log
import java.io.IOException
import java.nio.file.Files
import java.nio.file.Path

private const val TAG = "DesktopDevice"

/** What the identity reads of this computer: the JVM's OS properties, the environment, files and Windows's registry. */
internal class DesktopSystem(
    val osName: String = System.getProperty("os.name"),
    val osVersion: String = System.getProperty("os.version"),
    val env: (String) -> String? = System::getenv,
    val readFile: (String) -> String = { Files.readString(Path.of(it)) },
    /** A string value of `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion`; null when it isn't there. */
    val currentVersion: (String) -> String? = {
        WindowsRegistry.string(WindowsRegistry.Root.LOCAL_MACHINE, """SOFTWARE\Microsoft\Windows NT\CurrentVersion""", it)
    },
)

/**
 * This computer as media servers see it: Windows by its computer name, Linux by its host name, else its OS's name. The
 * version is the OS's own description, as Plezy's earlier releases sent it. Never throws: where the registry or the
 * kernel's files can't be read, the platform is the JVM's OS name and version, with no model or name.
 */
internal fun desktopDeviceIdentity(system: DesktopSystem = DesktopSystem()): DeviceIdentity = try {
    val windows = system.osName.startsWith("Windows")
    val platform = if (windows) "Windows" else "Linux"
    DeviceIdentity(
        platform = platform,
        platformVersion = if (windows) system.windowsVersion() else system.linuxVersion(),
        deviceModel = platform,
        deviceName = if (windows) system.env("COMPUTERNAME")?.takeIf { it.isNotBlank() } else system.linuxDeviceName(),
        isTv = false,
    )
} catch (e: IOException) {
    system.osIdentity(e)
} catch (e: IllegalStateException) {
    system.osIdentity(e)
}

private fun DesktopSystem.osIdentity(failure: Exception): DeviceIdentity {
    Log.w(TAG, failure) { "This computer's identity can't be read; it goes by $osName" }
    return DeviceIdentity(platform = osName, platformVersion = osVersion, deviceModel = null, deviceName = null, isTv = false)
}

/** `"Windows 11 Pro" 10.0 (Build 22631)`, from the registry's description of the installed Windows. */
private fun DesktopSystem.windowsVersion(): String {
    val product = checkNotNull(currentVersion("ProductName")) { "Windows has no product name" }
    val build = checkNotNull(currentVersion("CurrentBuild")) { "Windows has no build number" }
    // The JVM's version is the kernel's major.minor (10.0).
    return windowsOsVersion(product, osVersion, build)
}

/**
 * Windows as `"<edition>" <version> (Build <build>)`. The edition is the OS's caption without `Microsoft`
 * (`Windows 11 Pro`); the registry's [productName] still says Windows 10 on Windows 11 (build 22000 on), which the
 * caption doesn't.
 */
internal fun windowsOsVersion(productName: String, version: String, build: String): String {
    val windows11 = (build.toIntOrNull() ?: 0) >= 22_000 && productName.startsWith("Windows 10")
    val edition = if (windows11) "Windows 11" + productName.removePrefix("Windows 10") else productName
    return "\"$edition\" $version (Build $build)"
}

/** `Linux <release> <version>` as `uname` gives them: `Linux 6.8.0-45-generic #45-Ubuntu SMP PREEMPT_DYNAMIC …`. */
private fun DesktopSystem.linuxVersion(): String =
    linuxOsVersion(readTrimmed("/proc/sys/kernel/osrelease"), readTrimmed("/proc/sys/kernel/version"))

internal fun linuxOsVersion(release: String, version: String): String = "Linux $release $version"

private fun DesktopSystem.readTrimmed(path: String): String = readFile(path).trim()

/** The kernel's host name, else (unset, `localhost` or unreadable) the OS's name in `os-release`. */
private fun DesktopSystem.linuxDeviceName(): String {
    val host = try {
        readTrimmed("/proc/sys/kernel/hostname")
    } catch (_: IOException) {
        ""
    }
    if (host.isNotEmpty() && host != "localhost") return host
    val release = listOf("/etc/os-release", "/usr/lib/os-release").firstNotNullOfOrNull { path ->
        try {
            readFile(path).lines()
        } catch (_: IOException) {
            null
        }
    }
    return osReleaseName(release.orEmpty())
}

/**
 * `NAME` of the `os-release` [lines] (`Ubuntu`), else `Linux`. A line is `KEY=value`, the value's surrounding double
 * quotes dropped; a line with another `=` in it counts as no value, and the last line of a key wins.
 */
internal fun osReleaseName(lines: List<String>): String {
    var name: String? = null
    for (line in lines) {
        val parts = line.split('=')
        if (parts.first() != "NAME") continue
        name = if (parts.size == 2) parts[1].removePrefix("\"").removeSuffix("\"") else null
    }
    return name ?: "Linux"
}
