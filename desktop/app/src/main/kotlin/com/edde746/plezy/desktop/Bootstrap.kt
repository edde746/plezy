package com.edde746.plezy.desktop

import com.edde746.plezy.app.AppBootstrap
import com.edde746.plezy.app.BuildFlavor
import com.edde746.plezy.app.DevicePlatform
import com.edde746.plezy.app.Startup
import com.edde746.plezy.app.SystemInputs
import com.edde746.plezy.crash.ReleaseChannel
import com.edde746.plezy.data.DatabaseFactory
import com.edde746.plezy.desktop.linux.systemLanguages
import com.edde746.plezy.desktop.secrets.desktopSecretStore
import com.edde746.plezy.desktop.windows.WindowsLocale
import com.edde746.plezy.downloads.BaseDirectory
import com.edde746.plezy.downloads.DownloadStoragePlatform
import com.edde746.plezy.importer.EarlierReleaseLocations
import com.edde746.plezy.importer.desktop
import com.edde746.plezy.secrets.SecretStore
import com.edde746.plezy.supporter.SupporterPlatform
import java.io.File
import java.nio.file.Path
import java.security.MessageDigest
import java.util.Locale
import java.util.jar.JarFile

/**
 * The desktop's shared core ([AppBootstrap]): the product on the device's database and the OS secret store. The
 * harness launcher's dev session (desktop/app/src/harness) builds its own local core. Every process reports the
 * system's settings first ([reportSystemInputs]).
 */
internal object Bootstrap {
    /**
     * Reports the system's settings the shared code follows ([SystemInputs]), before anything reads them: the
     * interface's languages (Windows' preferred languages, or Linux's LANGUAGE list,
     * else the JVM's locale); the region streams' country lists are checked against (Windows' country or region, else
     * the format locale's, LC_CTYPE's or LANG's, not the messages one's); captions and audio descriptions off, which
     * neither system has a setting for.
     */
    fun reportSystemInputs() {
        val windows = System.getProperty("os.name").startsWith("Windows")
        SystemInputs.report(
            languages = if (windows) WindowsLocale.preferredLanguages() else systemLanguages(System.getenv(), Locale.getDefault()),
            region = if (windows) WindowsLocale.region() else Locale.getDefault(Locale.Category.FORMAT).country.takeIf { it.isNotEmpty() },
            captions = false,
            audioDescriptions = false,
        )
    }

    /**
     * @param startup the product's start, which the splash shows.
     * @param dataDir a test launch's device of its own on this OS user (`--data-dir`), with its database
     *   in this directory and its secrets under a name derived from the directory; null for the device itself.
     */
    fun product(version: String, startup: Startup, dataDir: Path? = null): AppBootstrap {
        val device = Device(dataDir)
        return AppBootstrap.product(
            device.database, device.secrets, flavor, version, startup, earlierRelease = earlierRelease(dataDir),
            downloadTempDirectory = device.downloadTemp, buildLabel = build?.let { "$version+$it" } ?: version,
        )
    }

    /**
     * Resets the saved data [product] couldn't use, once the user confirmed ([AppBootstrap.resetData]); a `--data-dir`
     * launch's leaves this device's downloads alone.
     */
    suspend fun resetData(dataDir: Path? = null) {
        val device = Device(dataDir)
        val downloads = if (dataDir == null) DownloadStoragePlatform(BaseDirectory.APPLICATION_SUPPORT, { DesktopDownloads.appSupport() }, supportsSaf = false) else null
        AppBootstrap.resetData(device.database, device.secrets, downloads, device.downloadTemp)
    }

    /** The database and secrets of this device, or of a `--data-dir` launch's device of its own. */
    private class Device(dataDir: Path?) {
        private val directory = dataDir?.toAbsolutePath() ?: DatabaseFactory.defaultDirectory()
        val secrets = dataDir?.let { PrefixedSecretStore(desktopSecretStore(directory), dataDirPrefix(it)) } ?: desktopSecretStore(directory)
        val database = DatabaseFactory(directory.resolve("plezy.db"))

        // A `--data-dir` launch's full disk leaves this device's partial downloads alone.
        val downloadTemp = if (dataDir == null) DesktopDownloads.tempDirectory() else null
    }

    /**
     * Where Plezy's earlier releases kept their data on this Windows or Linux machine, which the first start imports;
     * none for a `--data-dir` launch, which is a device of its own, or on a Mac, where the Apple app imports them.
     */
    private fun earlierRelease(dataDir: Path?): EarlierReleaseLocations? {
        val os = System.getProperty("os.name")
        val looks = dataDir == null && (os.startsWith("Windows") || os.startsWith("Linux"))
        return if (looks) EarlierReleaseLocations.desktop(DesktopDownloads::windowsDocuments) else null
    }

    /**
     * Where this build is distributed: the app jar manifest's Plezy-Flavor (-Pplezy.flavor,
     * desktop/app/build.gradle.kts), or SIDELOADED when the app runs from class directories (the tests).
     */
    val flavor: BuildFlavor by lazy { manifestAttribute("Plezy-Flavor")?.let(BuildFlavor::valueOf) ?: BuildFlavor.SIDELOADED }

    /**
     * This build's number (version.xcconfig's CURRENT_PROJECT_VERSION, which the update feed's releases are compared
     * by): the app jar manifest's Plezy-Build, or null when the app runs from class directories.
     */
    val build: Long? by lazy { manifestAttribute("Plezy-Build")?.toLong() }

    /** [name] in the app jar's manifest; null when the app runs from class directories. */
    private fun manifestAttribute(name: String): String? {
        val location = File(Bootstrap::class.java.protectionDomain.codeSource.location.toURI())
        return if (location.isFile) JarFile(location).use { it.manifest?.mainAttributes?.getValue(name) } else null
    }

    /** This OS as a [DevicePlatform] name. */
    private val platform: String by lazy {
        val os = System.getProperty("os.name")
        when {
            os.startsWith("Windows") -> DevicePlatform.WINDOWS
            os.startsWith("Mac") -> DevicePlatform.MACOS
            else -> DevicePlatform.LINUX
        }
    }

    /**
     * The Supporter perks of this build ([SupporterPlatform.of]): free on macOS and Linux, on Windows only inside a
     * Microsoft Store package, which runs from under WindowsApps; the sideloaded builds link to donations.
     */
    val supporter: SupporterPlatform by lazy {
        val command = ProcessHandle.current().info().command().orElse("")
        val packaged = platform == DevicePlatform.WINDOWS && command.contains("\\WindowsApps\\", ignoreCase = true)
        SupporterPlatform.of(flavor, platform, packagedInstall = packaged)
    }

    /** Where this build is distributed, as its crash reports name it: its flavor's on this OS and architecture. */
    val releaseChannel: ReleaseChannel by lazy { ReleaseChannel.of(flavor, platform, System.getProperty("os.arch")) }

    /** `data-dir-<12 hex>/`: the secrets' name for a `--data-dir` device, the same on every run with that directory. */
    private fun dataDirPrefix(dir: Path): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(dir.toAbsolutePath().normalize().toString().toByteArray())
        return "data-dir-" + digest.take(6).joinToString("") { "%02x".format(it) } + "/"
    }
}

/** [inner] with every key under [prefix]: a `--data-dir` device's secrets, apart from the device's own. */
private class PrefixedSecretStore(private val inner: SecretStore, private val prefix: String) : SecretStore {
    override suspend fun get(key: String): ByteArray? = inner.get(prefix + key)

    override suspend fun put(key: String, value: ByteArray) = inner.put(prefix + key, value)

    override suspend fun delete(key: String) = inner.delete(prefix + key)

    override suspend fun deleteAll(prefix: String) = inner.deleteAll(this.prefix + prefix)
}
