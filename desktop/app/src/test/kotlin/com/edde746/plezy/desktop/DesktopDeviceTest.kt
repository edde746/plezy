package com.edde746.plezy.desktop

import com.edde746.plezy.app.DeviceIdentity
import java.nio.file.NoSuchFileException
import kotlin.test.Test
import kotlin.test.assertEquals

class DesktopDeviceTest {
    @Test
    fun windowsDescribesItsEditionVersionAndBuild() {
        assertEquals("\"Windows 10 Home\" 10.0 (Build 19045)", windowsOsVersion("Windows 10 Home", "10.0", "19045"))
        // The registry keeps calling Windows 11 Windows 10.
        assertEquals("\"Windows 11 Pro\" 10.0 (Build 22631)", windowsOsVersion("Windows 10 Pro", "10.0", "22631"))
        assertEquals(
            "\"Windows Server 2022 Datacenter\" 10.0 (Build 20348)",
            windowsOsVersion("Windows Server 2022 Datacenter", "10.0", "20348"),
        )
    }

    @Test
    fun linuxDescribesItsKernelAsUnameDoes() {
        assertEquals(
            "Linux 6.8.0-45-generic #45-Ubuntu SMP PREEMPT_DYNAMIC Fri Aug 30 12:02:04 UTC 2024",
            linuxOsVersion("6.8.0-45-generic", "#45-Ubuntu SMP PREEMPT_DYNAMIC Fri Aug 30 12:02:04 UTC 2024"),
        )
    }

    @Test
    fun aLinuxWithoutAHostNameIsCalledByItsOsName() {
        assertEquals("Ubuntu", osReleaseName(listOf("PRETTY_NAME=\"Ubuntu 24.04.1 LTS\"", "NAME=\"Ubuntu\"", "VERSION_ID=\"24.04\"")))
        assertEquals("Arch Linux", osReleaseName(listOf("NAME=Arch Linux")))
        assertEquals("Linux", osReleaseName(listOf("ID=nixos")))
        assertEquals("Linux", osReleaseName(emptyList()))
        assertEquals("Linux", osReleaseName(listOf("NAME=a=b")))
        assertEquals("Fedora Linux", osReleaseName(listOf("NAME=Old", "NAME=\"Fedora Linux\"")))
    }

    private fun files(vararg entries: Pair<String, String>): (String) -> String = { path -> entries.toMap()[path] ?: throw NoSuchFileException(path) }

    @Test
    fun linuxIsCalledByItsHostNameAndDescribedByItsKernel() {
        val system = DesktopSystem(
            osName = "Linux",
            osVersion = "6.8.0",
            readFile = files(
                "/proc/sys/kernel/osrelease" to "6.8.0\n",
                "/proc/sys/kernel/version" to "#45 SMP\n",
                "/proc/sys/kernel/hostname" to "localhost\n",
                "/usr/lib/os-release" to "NAME=\"Ubuntu\"\n",
            ),
        )

        assertEquals(DeviceIdentity("Linux", "Linux 6.8.0 #45 SMP", "Linux", "Ubuntu", false), desktopDeviceIdentity(system))
    }

    @Test
    fun unreadableKernelFilesFallBackToTheOsName() {
        val system = DesktopSystem(osName = "Linux", osVersion = "6.8.0", readFile = files("/proc/sys/kernel/hostname" to "deck"))

        assertEquals(DeviceIdentity("Linux", "6.8.0", null, null, false), desktopDeviceIdentity(system))
    }

    @Test
    fun windowsIsCalledByItsComputerNameAndAMissingRegistryValueFallsBackToTheOsName() {
        val registry = mutableMapOf("ProductName" to "Windows 10 Pro", "CurrentBuild" to "22631")
        val system = DesktopSystem(osName = "Windows 11", osVersion = "10.0", env = { if (it == "COMPUTERNAME") "DESK" else null }, currentVersion = { registry[it] })

        assertEquals(DeviceIdentity("Windows", "\"Windows 11 Pro\" 10.0 (Build 22631)", "Windows", "DESK", false), desktopDeviceIdentity(system))
        registry.remove("CurrentBuild")
        assertEquals(DeviceIdentity("Windows 11", "10.0", null, null, false), desktopDeviceIdentity(system))
    }
}
