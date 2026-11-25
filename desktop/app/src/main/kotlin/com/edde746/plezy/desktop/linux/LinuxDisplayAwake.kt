package com.edde746.plezy.desktop.linux

import com.edde746.plezy.desktop.DesktopDisplayAwake
import com.edde746.plezy.log.Log
import org.freedesktop.dbus.annotations.DBusInterfaceName
import org.freedesktop.dbus.connections.impl.DBusConnection
import org.freedesktop.dbus.connections.impl.DBusConnectionBuilder
import org.freedesktop.dbus.exceptions.DBusException
import org.freedesktop.dbus.exceptions.DBusExecutionException
import org.freedesktop.dbus.interfaces.DBusInterface
import org.freedesktop.dbus.types.UInt32
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Keeps the display awake on Linux through the desktop's screen saver service on the D-Bus session bus
 * (`org.freedesktop.ScreenSaver`, which KDE, GNOME and most desktops provide; the Flatpak may talk to it): Inhibit while
 * awake, UnInhibit with its cookie after. The service drops an inhibition when the connection that made it closes, so
 * the process's end, however it ends, lets the display sleep. Bus calls run on their own thread, off the event thread.
 * Without a session bus or the service the display isn't held, logged once.
 */
internal class LinuxDisplayAwake : DesktopDisplayAwake {
    private val thread: ExecutorService = Executors.newSingleThreadExecutor { Thread(it, "screensaver").apply { isDaemon = true } }

    // The screensaver thread's state.
    private var connection: DBusConnection? = null
    private var screenSaver: ScreenSaver? = null
    private var cookie: UInt32? = null
    private var failed = false

    override fun keepAwake(awake: Boolean) {
        if (thread.isShutdown) return
        thread.execute {
            if (failed || awake == (cookie != null)) return@execute
            try {
                val service = screenSaver ?: connect()
                val held = cookie
                if (held == null) {
                    cookie = service.Inhibit(APPLICATION, REASON)
                } else {
                    service.UnInhibit(held)
                    cookie = null
                }
            } catch (e: DBusException) {
                stayOff(e)
            } catch (e: DBusExecutionException) {
                stayOff(e)
            }
        }
    }

    override fun close() {
        if (thread.isShutdown) return
        thread.execute {
            runCatching { connection?.close() }.onFailure { Log.w(TAG, it) { "screen saver connection close failed" } }
            connection = null
        }
        thread.shutdown()
        thread.awaitTermination(3, TimeUnit.SECONDS)
    }

    private fun connect(): ScreenSaver {
        val bus = DBusConnectionBuilder.forSessionBus().withShared(false).build().also { connection = it }
        return bus.getRemoteObject(SERVICE, OBJECT_PATH, ScreenSaver::class.java).also { screenSaver = it }
    }

    /** No session bus, or no screen saver service on it: the display may sleep during playback. */
    private fun stayOff(e: Exception) {
        failed = true
        Log.w(TAG, e) { "no $SERVICE on the D-Bus session bus: the display may sleep during playback" }
    }

    private companion object {
        const val TAG = "ScreenSaver"
        const val SERVICE = "org.freedesktop.ScreenSaver"
        const val OBJECT_PATH = "/org/freedesktop/ScreenSaver"
        const val APPLICATION = "Plezy"
        const val REASON = "Playing a video"
    }
}

/** The freedesktop.org idle inhibition interface. */
@Suppress("FunctionName")
@DBusInterfaceName("org.freedesktop.ScreenSaver")
internal interface ScreenSaver : DBusInterface {
    fun Inhibit(applicationName: String, reason: String): UInt32
    fun UnInhibit(cookie: UInt32)
}
