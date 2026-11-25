package com.edde746.plezy.downloads

import android.content.Context
import com.edde746.plezy.importer.EarlierReleaseLocations
import com.edde746.plezy.importer.android

/**
 * Downloads on Android: under `app_flutter` in the app's data directory (read on every use: the data directory moves
 * with adoptable storage), or in a storage-access-framework folder the user picked.
 */
fun DownloadStoragePlatform.Companion.android(context: Context): DownloadStoragePlatform =
    DownloadStoragePlatform(BaseDirectory.APPLICATION_DOCUMENTS, { EarlierReleaseLocations.android(context).baseDirectory }, supportsSaf = true)
