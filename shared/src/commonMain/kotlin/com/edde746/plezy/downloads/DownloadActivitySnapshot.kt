package com.edde746.plezy.downloads

/** Aggregate download activity across every profile at one instant. */
data class DownloadActivitySnapshot(
    val activeTasks: Int,
    val completedTasks: Int,
    val failedTasks: Int,
    val downloadedBytes: Long,
    val progressUnits: Int,
    val networkAvailable: Boolean?,
    val networkStateGeneration: Int,
)
