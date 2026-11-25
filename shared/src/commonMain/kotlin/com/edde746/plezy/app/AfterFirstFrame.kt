package com.edde746.plezy.app

import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.settings.AppSettings
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.io.IOException
import kotlinx.io.files.FileSystem
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem

/**
 * The start's best-effort work that waits for the running app's first frame: each UI calls it on the main thread once
 * its app has drawn one; it runs once per process (a later call, a screen built again, does nothing), in [graph]'s
 * scope. A step that fails is logged, and the next runs.
 *
 * - A desktop (Windows, Linux, the Mac) with Start in fullscreen on enters fullscreen ([AppPlatform.setFullscreen]).
 * - The image cache Plezy's earlier releases kept goes, once per install ([cleanLegacyImageCache]).
 * - Cached server responses not written for a while go, unless they back a download
 *   ([com.edde746.plezy.data.cache.ApiCacheRepository.deleteStaleUnpinned]).
 */
fun afterFirstFrame(graph: AppGraph, platform: AppPlatform) {
    if (graph.firstFrameWorkDone) return
    graph.firstFrameWorkDone = true
    graph.scope.launch {
        bestEffort("start in fullscreen") {
            if (platform.formFactor == FormFactor.DESKTOP && graph.data.deviceSettings.value(AppSettings.startInFullscreen)) {
                platform.setFullscreen(true)
            }
        }
        bestEffort("legacy image cache cleanup") {
            cleanLegacyImageCache(graph.data.deviceSettings, graph.earlierRelease?.temporaryDirectory)
        }
        bestEffort("stale api cache cleanup") { graph.data.apiCache.deleteStaleUnpinned() }
    }
}

private inline fun bestEffort(what: String, step: () -> Unit) {
    try {
        step()
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "$what failed" }
    }
}

/**
 * Deletes `plexImageCache` in [temporaryDirectory] (the earlier releases' temporary directory,
 * [com.edde746.plezy.importer.EarlierReleaseLocations.temporaryDirectory]) with everything in it, once per install: then
 * [AppSettings.cleanedOldImageCache] is set, whether or not the folder was there and whether or not the delete
 * succeeded (a failure is logged), so it is never tried again. Nothing without a [temporaryDirectory]: a launch with a
 * device of its own.
 */
internal suspend fun cleanLegacyImageCache(
    settings: DeviceSettingsRepository,
    temporaryDirectory: String?,
    fileSystem: FileSystem = SystemFileSystem,
) {
    if (temporaryDirectory == null || settings.value(AppSettings.cleanedOldImageCache)) return
    try {
        withContext(Dispatchers.IO) {
            val cache = Path(temporaryDirectory, LEGACY_IMAGE_CACHE)
            if (fileSystem.exists(cache)) fileSystem.deleteRecursively(cache)
        }
    } catch (e: IOException) {
        Log.w(TAG, e) { "the earlier releases' image cache couldn't be deleted" }
    } finally {
        settings.set(AppSettings.cleanedOldImageCache, true)
    }
}

private fun FileSystem.deleteRecursively(path: Path) {
    if (metadataOrNull(path)?.isDirectory == true) list(path).forEach { deleteRecursively(it) }
    delete(path)
}

/** The folder of the earlier releases' image cache in their temporary directory. */
internal const val LEGACY_IMAGE_CACHE = "plexImageCache"

private const val TAG = "AfterFirstFrame"
