package com.edde746.plezy.downloads

import com.edde746.plezy.importer.EarlierReleaseLocations
import com.edde746.plezy.importer.apple
import kotlinx.cinterop.BetaInteropApi
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.ObjCObjectVar
import kotlinx.cinterop.alloc
import kotlinx.cinterop.memScoped
import kotlinx.cinterop.ptr
import kotlinx.cinterop.value
import platform.Foundation.NSError
import platform.Foundation.NSURL
import platform.Foundation.NSURLIsExcludedFromBackupKey
import kotlin.experimental.ExperimentalNativeApi

/**
 * Downloads on this Apple device: Documents on iPhone and iPad (excluded from iCloud backup: the media is
 * re-downloadable, and hundreds of gigabytes made backups fail), `Application Support/com.edde746.plezy` on the Mac.
 * Apple TV has no downloads.
 */
@OptIn(ExperimentalNativeApi::class)
fun DownloadStoragePlatform.Companion.apple(): DownloadStoragePlatform {
    val mac = Platform.osFamily == OsFamily.MACOSX
    return DownloadStoragePlatform(
        baseDirectory = if (mac) BaseDirectory.APPLICATION_SUPPORT else BaseDirectory.APPLICATION_DOCUMENTS,
        baseDirectoryPath = { EarlierReleaseLocations.apple().baseDirectory },
        supportsSaf = false,
        excludeFromBackup = if (Platform.osFamily == OsFamily.IOS) ::markExcludedFromBackup else null,
    )
}

/** Sets `isExcludedFromBackup` on [path]; the mark on a directory covers every file written into it later. */
@OptIn(ExperimentalForeignApi::class, BetaInteropApi::class)
internal fun markExcludedFromBackup(path: String) = memScoped {
    val error = alloc<ObjCObjectVar<NSError?>>()
    if (!NSURL.fileURLWithPath(path).setResourceValue(true, NSURLIsExcludedFromBackupKey, error.ptr)) {
        throw IllegalStateException("Excluding $path from backup failed: ${error.value?.localizedDescription}")
    }
}
