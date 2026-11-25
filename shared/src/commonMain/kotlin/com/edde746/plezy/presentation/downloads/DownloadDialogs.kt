package com.edde746.plezy.presentation.downloads

import com.edde746.plezy.downloads.validateEpisodeCountInput
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/** The symbol a dialog row shows; each UI maps it to its own icon. */
enum class DownloadDialogIcon {
    DOWNLOAD,
    UNWATCHED,
    NEXT_5,
    NEXT_10,
    CUSTOM,
    DELETE,
    SYNC,
    SPECIALS,
    VERSION,
    QUALITY,
}

/** A dialog row: [label] with [icon], and [detail] under or beside it (a quality's estimated size). */
data class DownloadDialogOption(val label: String, val icon: DownloadDialogIcon, val detail: String? = null)

/** A switch inside a dialog, with its current [value]. */
data class DownloadDialogSwitch(val label: String, val value: Boolean, val icon: DownloadDialogIcon? = null, val subtitle: String? = null)

/** A download dialog as the UIs draw it; each is answered through [DownloadDialogs]. */
sealed interface DownloadDialog {
    val title: String

    /** Rows to pick one of ([DownloadDialogs.choose]), with an optional [toggle] ([DownloadDialogs.setToggle]). */
    data class Options(override val title: String, val options: List<DownloadDialogOption>, val toggle: DownloadDialogSwitch? = null) : DownloadDialog

    /**
     * A number entry (digits only), submitted with [DownloadDialogs.submitCount]; [error] says why the last entry was
     * refused. [hint] is the current value, if any.
     */
    data class Count(override val title: String, val hint: String, val allowZero: Boolean, val error: String? = null) : DownloadDialog {
        val confirmLabel: String get() = T.common.ok
    }

    /**
     * A confirmation ([DownloadDialogs.confirm]); [destructive] draws [confirmLabel] as such. [switch] (removing a list
     * rule: also delete its downloads) is set with [DownloadDialogs.setToggle].
     */
    data class Confirm(
        override val title: String,
        val message: String,
        val confirmLabel: String,
        val destructive: Boolean = false,
        val switch: DownloadDialogSwitch? = null,
        val cancelLabel: String = T.common.cancel,
    ) : DownloadDialog
}

/** An answered [DownloadDialog.Confirm]: [switch] is the switch's value at confirmation. */
data class ConfirmAnswer(val switch: Boolean)

/**
 * The download dialogs one screen shows, one at a time ([dialog]); each `ask` suspends until the UI answers, and a new
 * question cancels the one open. Call everything on the main thread.
 */
class DownloadDialogs {
    private val mutableDialog = MutableStateFlow<DownloadDialog?>(null)
    val dialog: StateFlow<DownloadDialog?> = mutableDialog.asStateFlow()

    private var pending: CompletableDeferred<Any?>? = null

    private suspend fun ask(dialog: DownloadDialog): Any? {
        cancel()
        val answer = CompletableDeferred<Any?>()
        pending = answer
        mutableDialog.value = dialog
        try {
            return answer.await()
        } finally {
            if (pending === answer) {
                pending = null
                mutableDialog.value = null
            }
        }
    }

    private fun answer(value: Any?) {
        val answer = pending ?: return
        pending = null
        mutableDialog.value = null
        answer.complete(value)
    }

    /** The index of the row picked, and the toggle's value at that moment; null when dismissed. */
    suspend fun pickOption(dialog: DownloadDialog.Options): Pair<Int, Boolean?>? {
        @Suppress("UNCHECKED_CAST")
        return ask(dialog) as Pair<Int, Boolean?>?
    }

    /** The count entered; null when dismissed. */
    suspend fun enterCount(dialog: DownloadDialog.Count): Int? = ask(dialog) as Int?

    /** The answer; null when cancelled. */
    suspend fun confirm(dialog: DownloadDialog.Confirm): ConfirmAnswer? = ask(dialog) as ConfirmAnswer?

    /** Picks row [index] of the open [DownloadDialog.Options]. */
    fun choose(index: Int) {
        val options = mutableDialog.value as? DownloadDialog.Options ?: return
        if (index !in options.options.indices) return
        answer(index to options.toggle?.value)
    }

    /** Sets the open dialog's toggle or switch. */
    fun setToggle(value: Boolean) {
        mutableDialog.value = when (val open = mutableDialog.value) {
            is DownloadDialog.Options -> open.copy(toggle = open.toggle?.copy(value = value))
            is DownloadDialog.Confirm -> open.copy(switch = open.switch?.copy(value = value))
            else -> return
        }
    }

    /** Submits [text] to the open [DownloadDialog.Count]: answers with the count, or shows why it is refused. */
    fun submitCount(text: String) {
        val count = mutableDialog.value as? DownloadDialog.Count ?: return
        val error = validateEpisodeCountInput(text.trim(), count.allowZero)
        if (error != null) {
            mutableDialog.value = count.copy(error = error)
            return
        }
        answer(text.trim().toInt())
    }

    /** Confirms the open [DownloadDialog.Confirm]. */
    fun confirm() {
        val confirm = mutableDialog.value as? DownloadDialog.Confirm ?: return
        answer(ConfirmAnswer(confirm.switch?.value ?: false))
    }

    /** Dismisses the open dialog without an answer. */
    fun cancel() = answer(null)
}
