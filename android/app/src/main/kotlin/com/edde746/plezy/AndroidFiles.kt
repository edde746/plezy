package com.edde746.plezy

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import com.edde746.plezy.log.Log
import com.edde746.plezy.ui.app.SaveResult
import java.io.ByteArrayOutputStream
import java.io.IOException
import kotlin.concurrent.thread

/**
 * The system's document picker (the Storage Access Framework) for Settings → Export and import and the player's shader
 * import on phones and tablets, one per process (AndroidPlatform): `ACTION_CREATE_DOCUMENT` saves a JSON file under a
 * proposed name,
 * `ACTION_OPEN_DOCUMENT` opens any file, and the bytes go through the content resolver on a thread of their own. The
 * activity on screen registers the result launcher before it starts ([attach]); one dialog at a time, a new one ending
 * the previous one as cancelled.
 *
 * Never logs the file's contents or its URI.
 */
internal class AndroidFiles(context: Context) {
    private val context: Context = context.applicationContext

    /** The activity showing the app and its result launcher, while one does. Main thread. */
    private var activity: ComponentActivity? = null
    private var launcher: ActivityResultLauncher<Intent>? = null

    /** What the dialog's answer goes to: the chosen document, or null when it was cancelled. Main thread. */
    private var pending: ((Uri?) -> Unit)? = null

    /**
     * Registers [activity]'s result launcher, in its `onCreate` (before it starts). Lint's fragment check is about a
     * FragmentActivity's request codes: the activity is a plain ComponentActivity (as AndroidPlayerApps.attach).
     */
    @SuppressLint("InvalidFragmentVersionForActivityResult")
    fun attach(activity: ComponentActivity) {
        this.activity = activity
        launcher = activity.registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
            answer(if (result.resultCode == Activity.RESULT_OK) result.data?.data else null)
        }
    }

    /** [activity] is destroyed; finishing, the dialog it showed ends as cancelled (no answer comes). */
    fun detach(activity: ComponentActivity) {
        if (this.activity !== activity) return
        this.activity = null
        launcher = null
        if (activity.isFinishing) answer(null)
    }

    /** The save dialog for [fileName]; [text] is written to the chosen document as UTF-8, then [done] on the main thread. */
    fun save(fileName: String, text: String, done: (SaveResult) -> Unit) {
        val shown = show(createIntent(fileName)) { uri ->
            if (uri == null) {
                done(SaveResult.CANCELLED)
                return@show
            }
            work("Files.save", { write(uri, text) }) { saved -> done(if (saved) SaveResult.SAVED else SaveResult.FAILED) }
        }
        if (!shown) done(SaveResult.FAILED)
    }

    /**
     * The open dialog; the chosen document's display name and text (strict UTF-8) go to [opened], or [failed]; nothing
     * when cancelled.
     */
    fun open(opened: (name: String, text: String) -> Unit, failed: () -> Unit) {
        val shown = show(openIntent()) { uri ->
            if (uri != null) {
                work("Files.open", { read(uri)?.let { text -> displayName(uri) to text } }) { file ->
                    if (file != null) opened(file.first, file.second) else failed()
                }
            }
        }
        if (!shown) failed()
    }

    /** The open dialog for an image; the chosen one's display name and bytes go to [opened], or [failed]; nothing when cancelled. */
    fun openImage(opened: (name: String, bytes: ByteArray) -> Unit, failed: () -> Unit) {
        val shown = show(openIntent().setType("image/*")) { uri ->
            if (uri != null) {
                work("Files.openImage", { readBytes(uri)?.let { bytes -> displayName(uri) to bytes } }) { file ->
                    if (file != null) opened(file.first, file.second) else failed()
                }
            }
        }
        if (!shown) failed()
    }

    private fun show(intent: Intent, onAnswer: (Uri?) -> Unit): Boolean {
        val launcher = launcher ?: return false.also { Log.w(TAG) { "No activity for the document picker" } }
        answer(null)
        pending = onAnswer
        return try {
            launcher.launch(intent)
            true
        } catch (e: RuntimeException) {
            Log.w(TAG) { "No document picker: ${e.javaClass.simpleName}" }
            pending = null
            false
        }
    }

    private fun answer(uri: Uri?) {
        val onAnswer = pending ?: return
        pending = null
        onAnswer(uri)
    }

    /** Whether [text] was written; any failure of the document's provider (another app's) is a failed save. */
    private fun write(uri: Uri, text: String): Boolean = try {
        val stream = context.contentResolver.openOutputStream(uri, "wt") ?: throw IOException("no output stream")
        stream.use { it.write(text.encodeToByteArray()) }
        Log.i(TAG) { "Saved a file of ${text.length} characters" }
        true
    } catch (e: Exception) {
        Log.w(TAG) { "The file couldn't be written: ${e.javaClass.simpleName}" }
        false
    }

    /** The name the document's provider shows for it ([OpenableColumns.DISPLAY_NAME]), else its URI's last segment. */
    private fun displayName(uri: Uri): String {
        val shown = try {
            context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
                if (it.moveToFirst()) it.getString(0) else null
            }
        } catch (e: Exception) {
            Log.w(TAG) { "The file's name couldn't be read: ${e.javaClass.simpleName}" }
            null
        }
        return shown ?: uri.lastPathSegment.orEmpty()
    }

    /**
     * The document's text, or null when it can't be read ([readBytes]) or isn't UTF-8 (a CharacterCodingException is
     * an IOException).
     */
    private fun read(uri: Uri): String? = readBytes(uri)?.let { bytes ->
        try {
            bytes.decodeToString(throwOnInvalidSequence = true)
        } catch (e: Exception) {
            Log.w(TAG) { "The file couldn't be read: ${e.javaClass.simpleName}" }
            null
        }
    }

    /**
     * The document's bytes, or null when it can't be read or is over [MAX_IMPORT_BYTES]. Any failure of the document's
     * provider (another app's, which can throw what it likes) or of memory is a file that couldn't be read, not the
     * app's end.
     */
    private fun readBytes(uri: Uri): ByteArray? = try {
        val stream = context.contentResolver.openInputStream(uri) ?: throw IOException("no input stream")
        val bytes = ByteArrayOutputStream()
        stream.use {
            val buffer = ByteArray(64 * 1024)
            while (true) {
                val n = it.read(buffer)
                if (n < 0) break
                if (bytes.size() + n > MAX_IMPORT_BYTES) throw IOException("over $MAX_IMPORT_BYTES bytes")
                bytes.write(buffer, 0, n)
            }
        }
        bytes.toByteArray()
    } catch (e: Exception) {
        Log.w(TAG) { "The file couldn't be read: ${e.javaClass.simpleName}" }
        null
    } catch (e: OutOfMemoryError) {
        Log.w(TAG) { "The file couldn't be read: ${e.javaClass.simpleName}" }
        null
    }

    /** [block] on a thread of its own, its result to [then] on the main thread. */
    private fun <T> work(name: String, block: () -> T, then: (T) -> Unit) {
        val main = ContextCompat.getMainExecutor(context)
        thread(name = name, isDaemon = true) {
            val result = block()
            main.execute { then(result) }
        }
    }

    private companion object {
        const val TAG = "Files"

        /**
         * The largest file Import reads; a bigger one is refused as unreadable before it fills the heap (a video picked
         * by mistake, read whole, ended the app).
         */
        const val MAX_IMPORT_BYTES = 32 * 1024 * 1024

        fun createIntent(fileName: String): Intent = Intent(Intent.ACTION_CREATE_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType("application/json")
            .putExtra(Intent.EXTRA_TITLE, fileName)

        fun openIntent(): Intent = Intent(Intent.ACTION_OPEN_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType("*/*")
    }
}
