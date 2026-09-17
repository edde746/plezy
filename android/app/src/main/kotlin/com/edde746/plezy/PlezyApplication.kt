package com.edde746.plezy

import android.app.Application
import android.content.Context
import androidx.work.Configuration
import androidx.work.ListenableWorker
import androidx.work.WorkManager
import androidx.work.WorkerFactory
import androidx.work.WorkerParameters
import com.bbflight.background_downloader.DownloadTaskRunner
import com.bbflight.background_downloader.TaskRunner
import com.bbflight.background_downloader.TaskWorker
import java.net.URI

/** Keeps non-resumable Plex progressive downloads outside WorkManager's nine-minute timeout. */
internal object PlexDownloadForegroundPolicy {
  private const val progressiveDownloadPath = "/video/:/transcode/universal/start.mkv"

  fun shouldForceForeground(url: String): Boolean = runCatching { URI(url).path == progressiveDownloadPath }.getOrDefault(false)
}

/**
 * Mirrors background_downloader's DownloadTaskWorker while preserving foreground state for the
 * one task type that cannot survive its normal timeout: a Plex progressive video transcode.
 */
internal class PlezyDownloadTaskWorker(context: Context, params: WorkerParameters) : TaskWorker(context, params) {
  private var downloaderForeground = false

  override var runInForeground: Boolean
    get() = downloaderForeground || currentTaskRequiresForeground()
    set(value) {
      downloaderForeground = value
    }

  private fun currentTaskRequiresForeground(): Boolean {
    val currentTask = try {
      task
    } catch (_: UninitializedPropertyAccessException) {
      return false
    }
    return PlexDownloadForegroundPolicy.shouldForceForeground(currentTask.url)
  }

  override fun createRunner(): TaskRunner = DownloadTaskRunner(this)
}

internal class PlezyWorkerFactory : WorkerFactory() {
  override fun createWorker(
    appContext: Context,
    workerClassName: String,
    workerParameters: WorkerParameters
  ): ListenableWorker? = if (workerClassName == "com.bbflight.background_downloader.DownloadTaskWorker") {
    PlezyDownloadTaskWorker(appContext, workerParameters)
  } else {
    null
  }
}

class PlezyApplication :
  Application(),
  Configuration.Provider {
  override val workManagerConfiguration: Configuration
    get() = Configuration.Builder().setWorkerFactory(PlezyWorkerFactory()).build()

  override fun onCreate() {
    super.onCreate()
    WorkManager.initialize(this, workManagerConfiguration)
  }
}
