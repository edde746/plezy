package com.edde746.plezy.importer

import android.content.Context

/**
 * The earlier releases' Android locations in this app's data directory (the same application id): the base directory
 * `app_flutter` (their documents directory), `files/` for support files, the DataStore preferences in
 * `files/datastore/` and the older SharedPreferences file in `shared_prefs/`. Nothing is created.
 */
fun EarlierReleaseLocations.Companion.android(context: Context): EarlierReleaseLocations {
    val dataDirectory = context.applicationInfo.dataDir
    val files = context.filesDir.path
    return EarlierReleaseLocations(
        baseDirectory = "$dataDirectory/app_flutter",
        supportDirectory = files,
        legacyDatabase = null,
        orphanedSupportDirectory = null,
        preferences = EarlierReleasePreferencesLocation.AndroidStores(
            dataStore = "$files/datastore/FlutterSharedPreferences.preferences_pb",
            legacyXml = "$dataDirectory/shared_prefs/FlutterSharedPreferences.xml",
        ),
        temporaryDirectory = context.cacheDir.path,
    )
}
