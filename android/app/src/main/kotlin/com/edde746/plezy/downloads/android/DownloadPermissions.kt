package com.edde746.plezy.downloads.android

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContract
import com.edde746.plezy.downloads.AndroidSafStorage
import com.edde746.plezy.log.Log
import com.edde746.plezy.presentation.downloads.FolderPicker
import com.edde746.plezy.presentation.downloads.PickedFolder
import kotlinx.coroutines.CompletableDeferred

/**
 * The download folder picker's activity-result request, one per process ([FolderPicker]: the document tree, its read
 * and write grant made persistent). The activity on screen registers its launcher before it starts ([attach]).
 */
internal class DownloadPermissions(context: Context, television: Boolean) : FolderPicker {
    private val context: Context = context.applicationContext

    private var activity: ComponentActivity? = null
    private var folderLauncher: ActivityResultLauncher<Uri?>? = null

    private var folderAnswer: CompletableDeferred<Uri?>? = null

    /** Registers [activity]'s launchers, in its `onCreate`. Lint's fragment check concerns FragmentActivity only. */
    @SuppressLint("InvalidFragmentVersionForActivityResult")
    fun attach(activity: ComponentActivity) {
        this.activity = activity
        folderLauncher = activity.registerForActivityResult(OpenTree()) { uri -> answerFolder(uri) }
    }

    /** [activity] is destroyed; finishing, an open picker ends as cancelled. */
    fun detach(activity: ComponentActivity) {
        if (this.activity !== activity) return
        this.activity = null
        folderLauncher = null
        if (activity.isFinishing) answerFolder(null)
    }

    /** Phones and tablets: TV boxes have no usable document tree picker (none, the framework's stub, or no remote input). */
    override val available: Boolean = !television

    override suspend fun pick(title: String): PickedFolder? {
        val launcher = folderLauncher ?: return null.also { Log.w(TAG) { "No activity for the folder picker" } }
        answerFolder(null)
        val answer = CompletableDeferred<Uri?>()
        folderAnswer = answer
        try {
            launcher.launch(null)
        } catch (e: RuntimeException) {
            Log.w(TAG) { "No folder picker: ${e.javaClass.simpleName}" }
            folderAnswer = null
            return null
        }
        val uri = answer.await() ?: return null
        return PickedFolder(AndroidSafStorage(context).persistPickedDirectory(uri), PickedFolder.SAF)
    }

    private fun answerFolder(uri: Uri?) {
        val answer = folderAnswer ?: return
        folderAnswer = null
        answer.complete(uri)
    }

    /** The document tree picker with the persistable read and write grant the downloads keep; the picked tree or null. */
    private class OpenTree : ActivityResultContract<Uri?, Uri?>() {
        override fun createIntent(context: Context, input: Uri?) = AndroidSafStorage.openDirectoryIntent(input)

        override fun parseResult(resultCode: Int, intent: Intent?): Uri? = intent?.takeIf { resultCode == Activity.RESULT_OK }?.data
    }

    private companion object {
        const val TAG = "DownloadPermissions"
    }
}
