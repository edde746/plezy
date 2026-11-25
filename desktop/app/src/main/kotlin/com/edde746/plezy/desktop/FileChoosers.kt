package com.edde746.plezy.desktop

import com.edde746.plezy.desktop.linux.FileChooserPortal
import com.edde746.plezy.desktop.linux.inFlatpak
import com.edde746.plezy.log.Log
import com.edde746.plezy.ui.app.SaveResult
import java.awt.EventQueue
import java.awt.Window
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.IOException
import javax.swing.JFileChooser
import javax.swing.UIManager
import javax.swing.filechooser.FileNameExtensionFilter
import kotlin.concurrent.thread

private const val TAG = "Files"

/**
 * The largest file the open dialog reads; a bigger one is refused as unreadable before it fills the heap (a video
 * picked by mistake, read whole).
 */
internal const val MAX_OPENED_BYTES = 32 * 1024 * 1024

/*
 * The desktop's file dialogs: a modal JFileChooser over the window, built in the system's look as the JDK names it:
 * Windows' file dialog style on Windows, GTK's on GNOME, and Swing's own Metal look on any other Linux desktop, KDE
 * included; the app's look and feel is left as it was. Inside the Flatpak the desktop portal's dialogs instead
 * (FileChooserPortal): a JFileChooser there sees only the sandbox, whose home folder is in memory and gone when the app
 * exits. Call each on the AWT event thread (Compose's main thread). None logs a path or a file's text.
 */

/**
 * The folder picker of Settings → Downloads location over [parent], titled [title], opened at [initial] where that
 * folder exists: [chosen] gets the picked folder's absolute path, null when the user cancels or the portal fails
 * (logged).
 */
internal fun chooseDirectory(parent: Window, title: String, initial: String?, chosen: (String?) -> Unit) {
    if (inFlatpak) {
        val window = FileChooserPortal.parentWindow(parent)
        return throughPortal({ FileChooserPortal.open(window, title, directory = true, folder = initial) }, failed = { chosen(null) }) { folder ->
            chosen(folder?.absolutePath)
        }
    }
    val chooser = inSystemLook { JFileChooser() }
    chooser.dialogTitle = title
    chooser.fileSelectionMode = JFileChooser.DIRECTORIES_ONLY
    chooser.isAcceptAllFileFilterUsed = false
    initial?.let(::File)?.takeIf { it.isDirectory }?.let { folder ->
        chooser.currentDirectory = folder.parentFile ?: folder
        chooser.selectedFile = folder
    }
    chosen(if (chooser.showOpenDialog(parent) == JFileChooser.APPROVE_OPTION) chooser.selectedFile?.absolutePath else null)
}

/**
 * The save dialog of Settings → Export and import and of Settings → Home's Export collections
 * (`PlezyPlatform.saveFile`) over [parent], [fileName] proposed: the chooser lists JSON files in its default folder
 * (Documents on Windows, the home folder on Linux), and a name typed there without an extension gets `.json`; the
 * portal's dialog starts where the desktop chooses, and its file is written under the name the user gave it (the only
 * one the document portal shares). [text] is written as UTF-8 on a thread of its own, then [done] runs on the AWT event
 * thread; FAILED also when the portal fails.
 */
internal fun saveTextFile(parent: Window, fileName: String, text: String, done: (SaveResult) -> Unit) {
    if (inFlatpak) {
        val window = FileChooserPortal.parentWindow(parent)
        val title = UIManager.getString("FileChooser.saveDialogTitleText").orEmpty()
        return throughPortal({ FileChooserPortal.save(window, title, fileName) }, failed = { done(SaveResult.FAILED) }) { file ->
            if (file == null) done(SaveResult.CANCELLED) else write(file, text, done)
        }
    }
    val chooser = inSystemLook { JFileChooser() }
    chooser.fileFilter = FileNameExtensionFilter("JSON", "json")
    chooser.selectedFile = File(chooser.currentDirectory, fileName)
    if (chooser.showSaveDialog(parent) != JFileChooser.APPROVE_OPTION) return done(SaveResult.CANCELLED)
    val chosen = chooser.selectedFile
    write(if (chosen.extension.isEmpty()) File(chosen.path + ".json") else chosen, text, done)
}

/**
 * The open dialog (`PlezyPlatform.openFile`: Settings → Export and import, Settings → Home's Import collections, the
 * player's shader import) over [parent], every file listed (one saved under another type is still offered). The chosen
 * file is read on a thread of its own and decoded strictly as UTF-8, then its name and text go to [opened], or [failed]
 * runs when it can't be read, is over [MAX_OPENED_BYTES], isn't UTF-8 or the portal failed, on the AWT event thread;
 * nothing when the user cancels.
 */
internal fun openTextFile(parent: Window, opened: (name: String, text: String) -> Unit, failed: () -> Unit) {
    if (inFlatpak) {
        val window = FileChooserPortal.parentWindow(parent)
        val title = UIManager.getString("FileChooser.openDialogTitleText").orEmpty()
        return throughPortal({ FileChooserPortal.open(window, title, directory = false, folder = null) }, failed) { file ->
            file?.let { read(it, opened, failed) }
        }
    }
    val chooser = inSystemLook { JFileChooser() }
    if (chooser.showOpenDialog(parent) != JFileChooser.APPROVE_OPTION) return
    read(chooser.selectedFile, opened, failed)
}

/** Writes [text] into [file] as UTF-8 on a thread of its own, then [done] on the AWT event thread. */
private fun write(file: File, text: String, done: (SaveResult) -> Unit) {
    thread(name = "Files.save", isDaemon = true) {
        val saved = try {
            file.writeText(text)
            Log.i(TAG) { "Saved a file of ${text.length} characters" }
            true
        } catch (e: IOException) {
            Log.w(TAG) { "The file couldn't be written: ${e.javaClass.simpleName}" }
            false
        }
        EventQueue.invokeLater { done(if (saved) SaveResult.SAVED else SaveResult.FAILED) }
    }
}

/** Reads [file] on a thread of its own ([readText]): its name and text to [opened], else [failed], on the AWT event thread. */
private fun read(file: File, opened: (name: String, text: String) -> Unit, failed: () -> Unit) {
    thread(name = "Files.open", isDaemon = true) {
        val text = readText(file)
        EventQueue.invokeLater { if (text != null) opened(file.name, text) else failed() }
    }
}

/**
 * Shows the open dialog for an image (the metadata editor's artwork upload), then reads the chosen file on a thread of
 * its own: its name and bytes to [opened], else [failed], on the AWT event thread; nothing when cancelled.
 */
internal fun openImageFile(parent: Window, opened: (name: String, bytes: ByteArray) -> Unit, failed: () -> Unit) {
    val readChosen = { file: File ->
        thread(name = "Files.openImage", isDaemon = true) {
            val bytes = readBytes(file)
            EventQueue.invokeLater { if (bytes != null) opened(file.name, bytes) else failed() }
        }
    }
    if (inFlatpak) {
        val window = FileChooserPortal.parentWindow(parent)
        val title = UIManager.getString("FileChooser.openDialogTitleText").orEmpty()
        return throughPortal({ FileChooserPortal.open(window, title, directory = false, folder = null) }, failed) { file ->
            file?.let { readChosen(it) }
        }
    }
    val chooser = inSystemLook { JFileChooser() }
    if (chooser.showOpenDialog(parent) != JFileChooser.APPROVE_OPTION) return
    readChosen(chooser.selectedFile)
}

/**
 * [file]'s text, strictly UTF-8, or null when it can't be read ([readBytes]) or isn't UTF-8 (a
 * CharacterCodingException is an IOException).
 */
internal fun readText(file: File): String? = readBytes(file)?.let { bytes ->
    try {
        bytes.decodeToString(throwOnInvalidSequence = true)
    } catch (e: CharacterCodingException) {
        Log.w(TAG) { "The file couldn't be read: ${e.javaClass.simpleName}" }
        null
    }
}

/**
 * [file]'s bytes, or null when it can't be read or is over [MAX_OPENED_BYTES]. Running out of memory is a file that
 * couldn't be read too, not the reader's end with no answer.
 */
private fun readBytes(file: File): ByteArray? = try {
    val bytes = ByteArrayOutputStream()
    file.inputStream().use {
        val buffer = ByteArray(64 * 1024)
        while (true) {
            val n = it.read(buffer)
            if (n < 0) break
            if (bytes.size() + n > MAX_OPENED_BYTES) throw IOException("over $MAX_OPENED_BYTES bytes")
            bytes.write(buffer, 0, n)
        }
    }
    bytes.toByteArray()
} catch (e: IOException) {
    Log.w(TAG) { "The file couldn't be read: ${e.javaClass.simpleName}" }
    null
} catch (e: OutOfMemoryError) {
    Log.w(TAG) { "The file couldn't be read: ${e.javaClass.simpleName}" }
    null
}

/**
 * Runs the portal's dialog [show] on a thread of its own (it blocks until the user answers): what the user chose (null
 * when cancelled) goes to [answered], or [failed] runs when the portal couldn't show it (logged), on the AWT event
 * thread.
 */
private fun throughPortal(show: () -> File?, failed: () -> Unit = {}, answered: (File?) -> Unit) {
    thread(name = "Files.portal", isDaemon = true) {
        val result = try {
            Result.success(show())
        } catch (e: IOException) {
            Log.w(TAG) { "The file dialog couldn't be shown: ${e.message}" }
            Result.failure(e)
        }
        EventQueue.invokeLater { result.fold(answered) { failed() } }
    }
}

/** [create]'s components get the system's look and feel; the one in effect before is restored afterwards. */
private fun <T> inSystemLook(create: () -> T): T {
    val previous = UIManager.getLookAndFeel()
    val switched = runCatching { UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName()) }.isSuccess
    try {
        return create()
    } finally {
        if (switched && previous != null) runCatching { UIManager.setLookAndFeel(previous) }
    }
}
