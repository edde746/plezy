package com.edde746.plezy.desktop.linux

import com.edde746.plezy.mpv.DesktopWindow
import com.edde746.plezy.mpv.WaylandSession
import org.freedesktop.dbus.DBusPath
import org.freedesktop.dbus.annotations.DBusInterfaceName
import org.freedesktop.dbus.connections.impl.DBusConnectionBuilder
import org.freedesktop.dbus.exceptions.DBusException
import org.freedesktop.dbus.exceptions.DBusExecutionException
import org.freedesktop.dbus.interfaces.DBusInterface
import org.freedesktop.dbus.matchrules.DBusMatchRuleBuilder
import org.freedesktop.dbus.types.UInt32
import org.freedesktop.dbus.types.Variant
import java.awt.Window
import java.io.File
import java.io.IOException
import java.net.URI
import java.net.URISyntaxException
import java.util.concurrent.CompletableFuture
import java.util.concurrent.ExecutionException
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException
import java.util.concurrent.atomic.AtomicInteger

/**
 * The file dialogs inside the Flatpak ([inFlatpak]): the desktop portal's file chooser (xdg-desktop-portal's
 * `org.freedesktop.portal.FileChooser` on the D-Bus session bus, which every Flatpak may talk to). The dialog is the
 * desktop's own, outside the sandbox, so it shows the user's real folders; what the user picks is shared with the
 * sandbox, through the document portal (`/run/user/<uid>/doc/…`, kept across restarts) unless the sandbox sees it
 * already. Each dialog is a request: its answer comes as the `Response` signal on the request's own object path,
 * listened for before asking. One connection per dialog. The calls block until the user answers, for an hour at most
 * (a portal that never answers, its backend gone, then closes the dialog and fails): call them off the AWT event
 * thread. An answer that isn't what the portal's API describes fails as an [IOException] like any other portal failure.
 */
internal object FileChooserPortal {
    private const val SERVICE = "org.freedesktop.portal.Desktop"
    private const val OBJECT_PATH = "/org/freedesktop/portal/desktop"
    private const val REQUEST = "org.freedesktop.portal.Request"
    private const val ANSWER_TIMEOUT_MINUTES = 60L
    private val tokens = AtomicInteger()

    /**
     * [window] as a portal dialog's parent: `x11:<its X window in hex>` under X11; none (empty) under Wayland, where a
     * parent takes an exported surface handle (xdg-foreign) the toolkit doesn't make.
     */
    fun parentWindow(window: Window): String = if (WaylandSession.active) "" else "x11:" + DesktopWindow.xWindow(window).toString(16)

    /**
     * The open dialog over [parentWindow], titled [title]: any file, or a folder when [directory], starting in [folder]
     * where given. The chosen file or folder, or null when the user cancelled.
     * @throws IOException when there's no session bus, no portal on it, or the portal failed or never answered.
     */
    fun open(parentWindow: String, title: String, directory: Boolean, folder: String?): File? {
        val options = buildMap<String, Variant<*>> {
            put("directory", Variant(directory))
            folder?.let { put("current_folder", Variant((it + "\u0000").toByteArray(), "ay")) }
        }
        return request(parentWindow, title, options) { chooser, window, text, all -> chooser.OpenFile(window, text, all) }
    }

    /**
     * The save dialog over [parentWindow], titled [title], [fileName] proposed. The file to write, exactly as the user
     * named it (the document portal shares that name only), or null when the user cancelled.
     * @throws IOException when there's no session bus, no portal on it, or the portal failed or never answered.
     */
    fun save(parentWindow: String, title: String, fileName: String): File? =
        request(parentWindow, title, mapOf("current_name" to Variant(fileName))) { chooser, window, text, all -> chooser.SaveFile(window, text, all) }

    private fun request(
        parentWindow: String,
        title: String,
        options: Map<String, Variant<*>>,
        ask: (FileChooser, String, String, Map<String, Variant<*>>) -> DBusPath,
    ): File? = try {
        DBusConnectionBuilder.forSessionBus().withShared(false).build().use { bus ->
            val token = "plezy${tokens.incrementAndGet()}"
            val handle = "$OBJECT_PATH/request/${bus.uniqueName.removePrefix(":").replace('.', '_')}/$token"
            val answer = CompletableFuture<Array<Any?>>()
            val rule = DBusMatchRuleBuilder.create().withType("signal").withPath(handle).withInterface(REQUEST).withMember("Response").build()
            bus.addGenericSigHandler(rule) { signal ->
                try {
                    answer.complete(signal.parameters)
                } catch (e: DBusException) {
                    answer.completeExceptionally(e)
                }
            }.use {
                val chooser = bus.getRemoteObject(SERVICE, OBJECT_PATH, FileChooser::class.java)
                val asked = ask(chooser, parentWindow, title, options + ("handle_token" to Variant(token)))
                if (asked.path != handle) throw IOException("the portal answers on ${asked.path}, not on $handle")
                val response = try {
                    answer.get(ANSWER_TIMEOUT_MINUTES, TimeUnit.MINUTES)
                } catch (e: TimeoutException) {
                    bus.getRemoteObject(SERVICE, handle, PortalRequest::class.java).Close()
                    throw IOException("the file chooser portal didn't answer within $ANSWER_TIMEOUT_MINUTES minutes", e)
                }
                chosen(response)
            }
        }
    } catch (e: DBusException) {
        throw IOException("the file chooser portal failed: ${e.message}", e)
    } catch (e: DBusExecutionException) {
        throw IOException("the file chooser portal failed: ${e.message}", e)
    } catch (e: ExecutionException) {
        throw IOException("the file chooser portal's answer couldn't be read: ${e.cause?.message}", e)
    }

    /**
     * The `Response` signal's arguments (`ua{sv}`): the one file chosen, null when the user cancelled.
     * @throws IOException when the portal ended the dialog otherwise, or answered anything else than its API describes.
     */
    internal fun chosen(response: Array<Any?>): File? {
        val code = response.getOrNull(0) as? UInt32 ?: throw IOException("the file chooser portal answered no response code")
        when (code.toInt()) {
            0 -> {}
            1 -> return null
            else -> throw IOException("the file chooser portal ended the dialog (${code.toInt()})")
        }
        val results = response.getOrNull(1) as? Map<*, *> ?: throw IOException("the file chooser portal answered no results")
        val uri = when (val uris = (results["uris"] as? Variant<*>)?.value) {
            is List<*> -> uris.firstOrNull()
            is Array<*> -> uris.firstOrNull()
            else -> null
        } as? String ?: throw IOException("the file chooser portal answered no file")
        return try {
            File(URI(uri))
        } catch (e: URISyntaxException) {
            throw IOException("the file chooser portal answered a URI that doesn't parse", e)
        } catch (e: IllegalArgumentException) {
            throw IOException("the file chooser portal answered a URI that is no file", e)
        }
    }
}

/** xdg-desktop-portal's file chooser: each method starts a request and returns its object path. */
@Suppress("FunctionName")
@DBusInterfaceName("org.freedesktop.portal.FileChooser")
internal interface FileChooser : DBusInterface {
    fun OpenFile(parentWindow: String, title: String, options: Map<String, @JvmSuppressWildcards Variant<*>>): DBusPath

    fun SaveFile(parentWindow: String, title: String, options: Map<String, @JvmSuppressWildcards Variant<*>>): DBusPath
}

/** A portal request: [Close] ends its dialog with no answer. */
@Suppress("FunctionName")
@DBusInterfaceName("org.freedesktop.portal.Request")
internal interface PortalRequest : DBusInterface {
    fun Close()
}
