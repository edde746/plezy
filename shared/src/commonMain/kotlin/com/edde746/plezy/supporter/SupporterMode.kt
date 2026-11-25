package com.edde746.plezy.supporter

import com.edde746.plezy.app.BuildFlavor
import com.edde746.plezy.app.DevicePlatform

/**
 * How a build offers the Supporter perks: the preset and custom themes and the alternate app icons. It follows from
 * where the build is distributed and the platform it runs on ([of]).
 */
enum class SupporterMode {
    /** Perks left out: the GitHub release's Android APKs and IPA. */
    OFF,

    /** Perks unlock through the one-time Supporter purchase: App Store and Google Play. */
    IAP,

    /** Perks are free: Amazon Appstore, macOS and Linux. */
    UNLOCKED,

    /**
     * Free inside a Microsoft Store (MSIX) install, hidden everywhere else: the GitHub Windows build is the same compile
     * as the Store package, so only the install tells them apart.
     */
    MSSTORE,
    ;

    companion object {
        /**
         * The mode of a [flavor] build on [platform] (a [DevicePlatform] name): the stores that sell apps sell the
         * purchase (Google Play, the App Store), Amazon's and the desktops' builds give the perks, Windows only inside
         * its Store package, and the sideloaded phone and TV builds leave them out. Apple TV sells the purchase in
         * every build.
         */
        fun of(flavor: BuildFlavor, platform: String): SupporterMode = when {
            platform == DevicePlatform.WINDOWS -> MSSTORE
            platform == DevicePlatform.MACOS || platform == DevicePlatform.LINUX -> UNLOCKED
            platform == DevicePlatform.TVOS -> IAP
            flavor == BuildFlavor.AMAZON -> UNLOCKED
            flavor == BuildFlavor.STORE -> IAP
            else -> OFF
        }
    }
}

/** Whether this install shows the perks and how they unlock. */
enum class SupporterAvailability {
    /** No perk UI anywhere; a stored perk choice paints its default instead. */
    HIDDEN,

    /** Perks are usable without a purchase. */
    FREE,

    /** Perks unlock through the Supporter purchase. */
    PURCHASABLE,
    ;

    companion object {
        /** [mode]'s availability on an install that is ([packagedInstall]) or isn't a Microsoft Store package. */
        fun of(mode: SupporterMode, packagedInstall: Boolean): SupporterAvailability = when (mode) {
            SupporterMode.OFF -> HIDDEN
            SupporterMode.IAP -> PURCHASABLE
            SupporterMode.UNLOCKED -> FREE
            SupporterMode.MSSTORE -> if (packagedInstall) FREE else HIDDEN
        }
    }
}

/**
 * What the platform brings to the Supporter perks ([com.edde746.plezy.app.AppPlatform.supporter]): this build's
 * [mode], whether it runs as a Microsoft Store package ([packagedInstall]), the device's store ([billing]: Google Play,
 * the App Store; used only in [SupporterMode.IAP] builds), the home-screen icon switcher ([appIcons]: Android's
 * launcher aliases, the iPhone's, iPad's and Apple TV's alternate icons) and whether the build links to donations
 * ([donations]: the Liberapay tile, never inside a Store package). Platforms make it with [of].
 */
class SupporterPlatform(
    val mode: SupporterMode,
    val packagedInstall: Boolean = false,
    val billing: StoreBilling? = null,
    val appIcons: AppIconSwitch? = null,
    val donations: Boolean = false,
) {
    /** This install's availability ([SupporterAvailability.of]). */
    val availability: SupporterAvailability get() = SupporterAvailability.of(mode, packagedInstall)

    /**
     * Where Settings' donation tile links: in builds that link to donations, outside a Store package, and never beside
     * the Supporter tile (a [SupporterMode.IAP] build's hub tile); null otherwise.
     */
    val donationUrl: String? get() = DONATION_URL.takeIf { donations && !packagedInstall && mode != SupporterMode.IAP }

    /** The same platform in a build of [mode]: a development session's choice. */
    fun withMode(mode: SupporterMode): SupporterPlatform = SupporterPlatform(mode, packagedInstall, billing, appIcons, donations)

    companion object {
        /** No perks, no store, no icons: tests and tools. */
        val OFF = SupporterPlatform(SupporterMode.OFF)

        /**
         * A [flavor] build's on [platform] ([SupporterMode.of]); the sideloaded builds, the GitHub release's, link to
         * donations, except on Apple TV, which has no browser to open the link.
         */
        fun of(
            flavor: BuildFlavor,
            platform: String,
            packagedInstall: Boolean = false,
            billing: StoreBilling? = null,
            appIcons: AppIconSwitch? = null,
        ): SupporterPlatform = SupporterPlatform(
            SupporterMode.of(flavor, platform), packagedInstall, billing, appIcons,
            donations = flavor == BuildFlavor.SIDELOADED && platform != DevicePlatform.TVOS,
        )

        /** Where donations go (the Settings tile). */
        const val DONATION_URL = "https://liberapay.com/edde746"
    }
}
