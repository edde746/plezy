package com.edde746.plezy.importer

actual fun readEarlierReleasePrefs(location: EarlierReleasePreferencesLocation): EarlierReleasePrefs? = when (location) {
    is EarlierReleasePreferencesLocation.AndroidStores -> readAndroidEarlierReleasePrefs(location.dataStore, location.legacyXml)
    is EarlierReleasePreferencesLocation.JsonFile -> readDesktopEarlierReleasePrefs(location.path)
    is EarlierReleasePreferencesLocation.UserDefaults -> error("Apple user defaults are read on Apple platforms")
}
