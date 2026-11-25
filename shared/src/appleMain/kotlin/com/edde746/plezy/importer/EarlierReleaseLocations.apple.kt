package com.edde746.plezy.importer

import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.toKString
import platform.Foundation.NSApplicationSupportDirectory
import platform.Foundation.NSBundle
import platform.Foundation.NSCachesDirectory
import platform.Foundation.NSDocumentDirectory
import platform.Foundation.NSNumber
import platform.Foundation.NSSearchPathDirectory
import platform.Foundation.NSSearchPathForDirectoriesInDomains
import platform.Foundation.NSUserDefaults
import platform.Foundation.NSUserDomainMask
import kotlin.experimental.ExperimentalNativeApi

/** The earlier releases' locations for this app's bundle ID ([apple]). */
fun EarlierReleaseLocations.Companion.apple(): EarlierReleaseLocations =
    apple(checkNotNull(NSBundle.mainBundle.bundleIdentifier) { "The app has no bundle identifier" })

/**
 * The earlier releases' locations on this Apple device, for the app [appId] (this app's bundle ID; the earlier
 * releases' [EARLIER_RELEASE_APP_ID] in a release). iPhone and iPad: Documents is the base directory, Application Support the
 * support directory. Apple TV: everything under `Library/Caches` (`Documents`, `ApplicationSupport`), the only storage
 * those releases could write. Mac (not sandboxed): `~/Library/Application Support/<appId>` for both, and the older
 * database in `~/Documents`. Preferences: the app's user defaults domain. The temporary directory: `Library/Caches`, on
 * the Mac with the app ID appended. A Mac build under another ID (the Debug build's) therefore neither imports nor
 * writes downloads into the release's data.
 */
@OptIn(ExperimentalNativeApi::class)
internal fun EarlierReleaseLocations.Companion.apple(appId: String): EarlierReleaseLocations {
    fun directory(kind: NSSearchPathDirectory) = NSSearchPathForDirectoriesInDomains(kind, NSUserDomainMask, true).first() as String
    val preferences = EarlierReleasePreferencesLocation.UserDefaults(appId)
    val caches = directory(NSCachesDirectory)
    return when (Platform.osFamily) {
        OsFamily.TVOS -> EarlierReleaseLocations(
            "$caches/Documents", "$caches/ApplicationSupport", null, null, preferences, purgeableDatabase = true, temporaryDirectory = caches,
        )
        OsFamily.MACOSX -> {
            val support = "${directory(NSApplicationSupportDirectory)}/$appId"
            EarlierReleaseLocations(
                support, support, "${directory(NSDocumentDirectory)}/$EARLIER_RELEASE_DATABASE_FILE_NAME", null, preferences,
                temporaryDirectory = "$caches/$appId",
            )
        }
        else -> EarlierReleaseLocations(
            directory(NSDocumentDirectory), directory(NSApplicationSupportDirectory), null, null, preferences, temporaryDirectory = caches,
        )
    }
}

actual fun readEarlierReleasePrefs(location: EarlierReleasePreferencesLocation): EarlierReleasePrefs? = when (location) {
    is EarlierReleasePreferencesLocation.UserDefaults -> readUserDefaultsEarlierReleasePrefs(NSUserDefaults.standardUserDefaults, location.domain)
    is EarlierReleasePreferencesLocation.JsonFile -> readDesktopEarlierReleasePrefs(location.path)
    is EarlierReleasePreferencesLocation.AndroidStores -> error("Android preference stores are read on Android")
}

/**
 * Reads the earlier releases' preferences from the persistent domain [domain] of [defaults] (bare and `flutter.` keys
 * side by side). Numbers become bools, ints or doubles by their stored type; arrays of strings become lists; values of
 * other types (dates, data, mixed arrays, written by the system or another component) are left out.
 *
 * Null when the earlier releases never wrote the domain: it is this app's own too, and the system and the app keep
 * their keys there whatever was installed before. Those releases always left the migration sentinel (their preference
 * store set it as it first opened) or, before it, `flutter.`-prefixed keys.
 */
fun readUserDefaultsEarlierReleasePrefs(defaults: NSUserDefaults, domain: String): EarlierReleasePrefs? {
    val stored = defaults.persistentDomainForName(domain) ?: return null
    val written = stored.keys.any { it == EarlierReleasePrefs.MIGRATION_SENTINEL || (it is String && it.startsWith(EarlierReleasePrefs.LEGACY_PREFIX)) }
    if (!written) return null
    val values = LinkedHashMap<String, EarlierReleasePrefValue>()
    for ((key, value) in stored) {
        if (key !is String) continue
        userDefaultsValue(value)?.let { values[key] = it }
    }
    return EarlierReleasePrefs.resolve(values)
}

@OptIn(ExperimentalForeignApi::class)
private fun userDefaultsValue(value: Any?): EarlierReleasePrefValue? = when (value) {
    is String -> EarlierReleasePrefValue.StringValue(value)
    is NSNumber -> when (value.objCType?.toKString()) {
        // A plist boolean is a CFBoolean, whose type is char.
        "c", "B" -> EarlierReleasePrefValue.BoolValue(value.boolValue)
        "f", "d" -> EarlierReleasePrefValue.DoubleValue(value.doubleValue)
        else -> EarlierReleasePrefValue.LongValue(value.longLongValue)
    }
    is List<*> -> if (value.all { it is String }) EarlierReleasePrefValue.StringListValue(value.map { it as String }) else null
    else -> null
}
