package com.edde746.plezy.presentation.downloads

import com.edde746.plezy.downloads.DeletionProgress
import com.edde746.plezy.downloads.DownloadsController
import com.edde746.plezy.strings.T
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * The non-dismissible dialog of a deletion that takes a while: [progress] null while the deletion hasn't reported one
 * (a spinner and "Deleting…"), else how many of its downloads are gone.
 */
data class DeletionDialog(val globalKey: String, val progress: DeletionProgress?) {
    val label: String
        get() = progress?.let { T.downloads.deletingWithProgress(it.itemTitle, it.currentItem.toString(), it.totalItems.toString()) }
            ?: T.downloads.deleting

    /** 0–1, null while there's no progress to show. */
    val fraction: Float? get() = progress?.progressPercent?.toFloat()

    val percentLabel: String? get() = progress?.let { "${it.progressPercentInt}%" }

    val operation: String? get() = progress?.currentOperation
}

/**
 * Deletes a download, showing [dialog] only when the deletion is still running after [delay] (a quick delete shows
 * nothing), and taking it down when the deletion ends, however it ends.
 */
class SmartDeletion(private val controller: DownloadsController, private val delay: Duration = 500.milliseconds) {
    private val mutableDialog = MutableStateFlow<DeletionDialog?>(null)
    val dialog: StateFlow<DeletionDialog?> = mutableDialog.asStateFlow()

    suspend fun deleteWithProgress(globalKey: String) = coroutineScope {
        val shower = launch {
            delay(delay)
            controller.changes.collect { mutableDialog.value = DeletionDialog(globalKey, controller.getDeletionProgress(globalKey)) }
        }
        try {
            controller.deleteDownload(globalKey)
        } finally {
            shower.cancel()
            if (mutableDialog.value?.globalKey == globalKey) mutableDialog.value = null
        }
    }
}
