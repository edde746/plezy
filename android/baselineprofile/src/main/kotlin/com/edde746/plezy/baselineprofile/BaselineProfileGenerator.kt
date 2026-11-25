package com.edde746.plezy.baselineprofile

import android.content.pm.PackageManager
import android.graphics.Rect
import android.os.SystemClock
import android.view.KeyEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.EditText
import androidx.benchmark.macro.MacrobenchmarkScope
import androidx.benchmark.macro.junit4.BaselineProfileRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.By
import androidx.test.uiautomator.Configurator
import androidx.test.uiautomator.Direction
import androidx.test.uiautomator.StaleObjectException
import androidx.test.uiautomator.UiObject2
import androidx.test.uiautomator.Until
import java.util.regex.Pattern
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * The journeys most sessions take, whose code the Baseline Profile has ART compile ahead of time, on an Android TV by
 * D-pad and on a phone by touch (the same profile ships on both; `:app-android:generateBaselineProfile` runs them on
 * every connected device and merges what each collects): the product's cold start of a signed-in session to Home,
 * Home's rows, the first library's grid scrolled, an item's detail, and the item played from there to its video and
 * back. On a TV also Home's navigation column. Each iteration starts cold.
 *
 * The content: the media server given as the `server` instrumentation argument, in `--dev-server`'s form
 * (`<kind>=<user>:<password>@<url>`, a Jellyfin or Emby server, e.g.
 * `-Pandroid.testInstrumentationRunnerArguments.server=jellyfin=…`), whose first library holds a few rows of items.
 * The startup journey signs the product into it once, through its own screens ([signIn]); the others use a
 * development session (the harness build's `dev` launch extras, android/app/src/debug TestLaunches.kt) signed into it.
 *
 * TV screens are told apart by focus, not by text the app translates: a card is tall (a poster), a button short; the
 * navigation column's items sit at the screen's start edge. Phone screens by what they hold: a scrollable grid or list
 * of cards, each a clickable element holding its artwork's description (its title).
 */
@RunWith(AndroidJUnit4::class)
class BaselineProfileGenerator {
    @get:Rule
    val rule = BaselineProfileRule()

    /** The product's cold start, signed in (before the journey, outside the profile), to Home with its rows; the startup profile. */
    @Test
    fun startup() {
        MacrobenchmarkScope(PACKAGE, launchWithClearTask = true).signIn()
        rule.collect(PACKAGE, maxIterations = ITERATIONS, stableIterations = STABLE, includeInStartupProfile = true) {
            coldStart(dev = false)
            awaitHome()
        }
    }

    /** Home's rows, down and along. On a TV then Left into the navigation column (it opens) and Right back. */
    @Test
    fun home() = rule.collect(PACKAGE, maxIterations = ITERATIONS, stableIterations = STABLE) {
        coldStart()
        awaitHome()
        if (TV) {
            repeat(4) { press(KeyEvent.KEYCODE_DPAD_DOWN) }
            repeat(4) { press(KeyEvent.KEYCODE_DPAD_RIGHT) }
            pressUntil("the navigation column", KeyEvent.KEYCODE_DPAD_LEFT) { it.left < device.displayWidth / 6 }
            press(KeyEvent.KEYCODE_DPAD_RIGHT)
        } else {
            repeat(3) { scrollable().fling(Direction.DOWN) }
            scrollable().fling(Direction.UP)
        }
    }

    /** The first library's grid, scrolled down (posters loading as rows come in) and back up. */
    @Test
    fun library() = rule.collect(PACKAGE, maxIterations = ITERATIONS, stableIterations = STABLE) {
        openLibrary()
        if (TV) {
            repeat(8) { press(KeyEvent.KEYCODE_DPAD_DOWN) }
            repeat(3) { press(KeyEvent.KEYCODE_DPAD_RIGHT) }
            repeat(4) { press(KeyEvent.KEYCODE_DPAD_UP) }
        } else {
            repeat(4) { scrollable().fling(Direction.DOWN) }
            scrollable().fling(Direction.UP)
        }
    }

    /** The library grid's first item opened: its detail page, scrolled down. */
    @Test
    fun detail() = rule.collect(PACKAGE, maxIterations = ITERATIONS, stableIterations = STABLE) {
        openLibrary()
        if (TV) {
            device.pressKeyCode(KeyEvent.KEYCODE_DPAD_CENTER)
            awaitFocus("the detail page's buttons") { !isCard(it) }
            repeat(4) { press(KeyEvent.KEYCODE_DPAD_DOWN) }
        } else {
            val card = card()
            val artwork = card.children.first { !it.contentDescription.isNullOrEmpty() }
            val title = artwork.contentDescription
            val bounds = artwork.visibleBounds
            card.click()
            // The title shown (the detail page's name or logo) and the card's artwork gone: the detail page is up; then
            // its content's time to load.
            waitFor("the detail page") {
                try {
                    val shown = device.findObjects(By.pkg(PACKAGE).desc(title)) + device.findObjects(By.pkg(PACKAGE).text(title))
                    shown.isNotEmpty() && shown.none { it.visibleBounds == bounds }
                } catch (e: StaleObjectException) {
                    false
                }
            }
            SystemClock.sleep(SETTLE_MS)
            repeat(2) { scrollable().fling(Direction.DOWN) }
        }
    }

    /**
     * The library grid's first item played from its detail page: Play, the player up until its video shows, then Back
     * to the detail page.
     */
    @Test
    fun play() = rule.collect(PACKAGE, maxIterations = ITERATIONS, stableIterations = STABLE) {
        openLibrary()
        if (TV) {
            device.pressKeyCode(KeyEvent.KEYCODE_DPAD_CENTER)
            // The detail page opens on its Play button.
            awaitFocus("the detail page's buttons") { !isCard(it) }
            SystemClock.sleep(SETTLE_MS)
            device.pressKeyCode(KeyEvent.KEYCODE_DPAD_CENTER)
        } else {
            card().click()
            playButton().click()
        }
        awaitVideo()
        leavePlayer()
    }
}

/**
 * The detail page's Play button, pressable (its item loaded): the widest short clickable element with a label (the
 * primary pill), as a phone lays the detail page out.
 */
private fun MacrobenchmarkScope.playButton(): UiObject2 {
    SystemClock.sleep(SETTLE_MS)
    val selector = By.pkg(PACKAGE).clickable(true).enabled(true).hasChild(By.text(Pattern.compile(".+")))
    val buttons = device.wait(Until.findObjects(selector), TIMEOUT_MS).orEmpty().filter { !isCard(it.visibleBounds) }
    return checkNotNull(buttons.maxByOrNull { it.visibleBounds.width() }) { "no Play button on the detail page" }
}

/**
 * The player's video surface on screen: a SurfaceView layer of the app's in SurfaceFlinger's list (mpv's; no other
 * screen of the journeys has one). The accessibility tree doesn't show it on every device.
 */
private fun MacrobenchmarkScope.videoShown(): Boolean =
    device.executeShellCommand("dumpsys SurfaceFlinger --list").lineSequence().any { "SurfaceView" in it && PACKAGE in it }

/** The player up with its video surface, then [VIDEO_MS] for the first frames to show and the playback to run. */
private fun MacrobenchmarkScope.awaitVideo() {
    waitFor("player's video") { videoShown() }
    SystemClock.sleep(VIDEO_MS)
}

/** Back until the player is gone (a first Back can hide its controls instead), then the detail page's time to settle. */
private fun MacrobenchmarkScope.leavePlayer() {
    var presses = 0
    while (videoShown()) {
        check(presses++ < MAX_PRESSES) { "Back never left the player" }
        device.pressBack()
        SystemClock.sleep(MOVE_MS)
    }
    SystemClock.sleep(SETTLE_MS)
}

/**
 * The app under test: the harness build's application ID (com.edde746.plezy.dev, a test build's), which the
 * androidx.baselineprofile plugin passes as this instrumentation argument.
 */
internal val PACKAGE: String =
    checkNotNull(InstrumentationRegistry.getArguments().getString("androidx.benchmark.targetPackageName")) {
        "no androidx.benchmark.targetPackageName argument: run the journeys through :app-android:generateBaselineProfile"
    }

/** The media server the sessions sign into, as `--dev-server` takes it. */
private val SERVER: String by lazy {
    checkNotNull(InstrumentationRegistry.getArguments().getString("server")) {
        "no server instrumentation argument (<kind>=<user>:<password>@<url>): the journeys need a media server's content"
    }
}

/** An Android TV (D-pad journeys) rather than a phone (touch). */
internal val TV: Boolean = InstrumentationRegistry.getInstrumentation().targetContext.packageManager
    .hasSystemFeature(PackageManager.FEATURE_LEANBACK)

private const val ITERATIONS = 5
private const val STABLE = 2
private const val TIMEOUT_MS = 30_000L
private const val MOVE_MS = 2_000L
private const val SETTLE_MS = 2_000L
private const val MAX_PRESSES = 10
private const val VIDEO_MS = 5_000L

/**
 * Home, the app killed, then the launch: a session signed into [SERVER] (opening [open]) unless [dev] is false (the
 * product's).
 */
private fun MacrobenchmarkScope.coldStart(dev: Boolean = true, open: String? = null) {
    pressHome()
    killProcess()
    // On a TV a key press first: until one, Android is in touch mode, where nothing is focused.
    if (TV) device.pressDPadDown()
    if (!dev) {
        startActivityAndWait()
        return
    }
    // The development options, as every platform takes them (DevLaunch), in the `dev` string array extra: through `am
    // start`, as startActivityAndWait passes its intent as a URI, which has no string arrays.
    val options = listOf("--dev", "--dev-server", SERVER) + (open?.let { listOf("--dev-open", it) } ?: emptyList())
    val result = device.executeShellCommand(
        "am start -W -n $PACKAGE/com.edde746.plezy.MainActivity --esa dev ${options.joinToString(",")} --esa mpv ao=null",
    )
    check("Status: ok" in result) { "the launch failed: $result" }
}

/** Home with its rows loaded: on a TV a card focused, on a phone a card shown. */
internal fun MacrobenchmarkScope.awaitHome() {
    if (TV) {
        awaitFocus("Home") { true }
        // The rows come once the session has signed in.
        SystemClock.sleep(SETTLE_MS)
        pressUntil("Home's first card", KeyEvent.KEYCODE_DPAD_DOWN) { isCard(it) }
    } else {
        card()
    }
}

/**
 * The product signed into [SERVER] through its own screens on fresh data (the app's data cleared first), and on Home:
 * Connect to Jellyfin (or Emby), the server's address (Go finds the server), the username, the password (Done signs
 * in).
 */
internal fun MacrobenchmarkScope.signIn() {
    val (kind, account) = SERVER.split("=", limit = 2)
    val at = account.lastIndexOf("@http")
    val product = kind.replaceFirstChar { it.uppercase() }
    check(at > 0 && product in listOf("Jellyfin", "Emby")) { "$SERVER: the product signs into a Jellyfin or Emby server here" }
    val (user, password) = account.substring(0, at).split(":", limit = 2)
    device.executeShellCommand("pm clear $PACKAGE")
    coldStart(dev = false)
    val connect = checkNotNull(device.wait(Until.findObject(By.pkg(PACKAGE).textContains(product)), TIMEOUT_MS)) { "no Connect to $product" }
    if (TV) {
        // Down until the button is focused: nothing is while the Plex buttons wait for their sign-in service.
        var presses = 0
        while (product !in focusedText()) {
            check(presses++ < MAX_PRESSES) { "focus never reached Connect to $product (at '${focusedText()}')" }
            press(KeyEvent.KEYCODE_DPAD_DOWN)
        }
        device.pressDPadCenter()
    } else {
        connect.click()
    }
    fill(fields(1)[0], account.substring(at + 1))
    // The server found: its form, or on a TV its Quick Connect code (no fields), started by itself with Cancel focused,
    // which goes back to the form.
    waitFor("the server found") { textFields().size != 1 }
    if (textFields().isEmpty()) {
        awaitFocus("Quick Connect's Cancel") { true }
        device.pressDPadCenter()
    }
    fill(fields(3)[1], user)
    fill(fields(3)[2], password)
    awaitHome()
}

private fun MacrobenchmarkScope.textFields(): List<UiObject2> = device.findObjects(By.pkg(PACKAGE).clazz(EditText::class.java))

/** The screen's first [count] text fields, from the top, once it has that many. */
private fun MacrobenchmarkScope.fields(count: Int): List<UiObject2> {
    var found = emptyList<UiObject2>()
    waitFor("$count text fields") {
        found = textFields()
        found.size >= count
    }
    return found.sortedBy { it.visibleBounds.top }.take(count)
}

/**
 * [text] typed into [field], then its keyboard action (Go, Next or Done: the field's submit, or on to the next field).
 * On a TV the field takes focus by itself; Select opens its keyboard, Back closes it (an Enter there would open it
 * again). On a phone a tap opens it.
 */
private fun MacrobenchmarkScope.fill(field: UiObject2, text: String) {
    if (TV) {
        val bounds = field.visibleBounds
        awaitFocus("the text field") { bounds.contains(it.centerX(), it.centerY()) }
        device.pressDPadCenter()
    } else {
        field.click()
    }
    SystemClock.sleep(MOVE_MS)
    // Not through a shell: the command is split at spaces, and quotes would be typed.
    device.executeShellCommand("input text $text")
    if (TV) {
        device.pressBack()
        SystemClock.sleep(MOVE_MS)
    }
    val automation = InstrumentationRegistry.getInstrumentation().getUiAutomation(Configurator.getInstance().uiAutomationFlags)
    automation.clearCache()
    val focused = automation.rootInActiveWindow?.findFocus(AccessibilityNodeInfo.FOCUS_INPUT)
    val input = checkNotNull(focused?.takeIf { it.className == EditText::class.java.name }) { "no text field focused (at $focused)" }
    check(input.performAction(AccessibilityNodeInfo.AccessibilityAction.ACTION_IME_ENTER.id)) { "the text field took no keyboard action" }
}

/** The libraries page on its first library, its grid loaded: on a TV its first card focused. */
private fun MacrobenchmarkScope.openLibrary() {
    coldStart(open = "libraries")
    // On a TV the grid's first card takes focus once the session has signed in and the grid loaded.
    if (TV) awaitFocus("the grid's first card") { isCard(it) } else card()
}

/** A card shown: a clickable element in a scrollable grid or list, holding its artwork's description (the title). */
private fun MacrobenchmarkScope.card(): UiObject2 {
    val selector = By.pkg(PACKAGE).clickable(true).hasChild(By.desc(Pattern.compile(".+"))).hasAncestor(By.scrollable(true))
    return checkNotNull(device.wait(Until.findObject(selector), TIMEOUT_MS)) { "no card within ${TIMEOUT_MS / 1000} s" }
}

/** The screen's scrollable grid or list (the largest, when there are several). */
private fun MacrobenchmarkScope.scrollable(): UiObject2 {
    val all = device.wait(Until.findObjects(By.pkg(PACKAGE).scrollable(true)), TIMEOUT_MS)
    return checkNotNull(all?.maxByOrNull { it.visibleBounds.height() * it.visibleBounds.width() }) { "nothing scrollable" }
        .also { it.setGestureMargin(device.displayHeight / 8) }
}

/** Presses [keyCode], then waits (up to [MOVE_MS]) for focus to move: a scrolled list or a loading screen moves it late. */
private fun MacrobenchmarkScope.press(keyCode: Int) {
    val before = focusedBounds() to focusedText()
    device.pressKeyCode(keyCode)
    val deadline = SystemClock.uptimeMillis() + MOVE_MS
    while ((focusedBounds() to focusedText()) == before && SystemClock.uptimeMillis() < deadline) SystemClock.sleep(100)
}

/** A card: taller than an eighth of the screen (a poster), where buttons and chips are short. */
private fun MacrobenchmarkScope.isCard(bounds: Rect) = bounds.height() > device.displayHeight / 8

private fun MacrobenchmarkScope.awaitFocus(what: String, focus: MacrobenchmarkScope.(Rect) -> Boolean) {
    waitFor(what) { focusedBounds()?.let { focus(it) } == true }
}

/** Presses [keyCode] until the focused element's bounds pass [focus]. */
private fun MacrobenchmarkScope.pressUntil(what: String, keyCode: Int, focus: MacrobenchmarkScope.(Rect) -> Boolean) {
    waitFor("focus") { focusedBounds() != null }
    var presses = 0
    while (focusedBounds()?.let { focus(it) } != true) {
        check(presses++ < MAX_PRESSES) { "focus never reached $what (at ${focusedBounds()}: '${focusedText()}')" }
        press(keyCode)
    }
}

private fun waitFor(what: String, condition: () -> Boolean) {
    val deadline = SystemClock.uptimeMillis() + TIMEOUT_MS
    while (!condition()) {
        check(SystemClock.uptimeMillis() < deadline) { "no $what within ${TIMEOUT_MS / 1000} s" }
        SystemClock.sleep(100)
    }
}

/**
 * The focused element, read fresh: Compose's focus moves don't reach this process's accessibility cache, which would
 * keep answering with the element focused when it was first read (UiAutomation.clearCache, API 34).
 */
private fun MacrobenchmarkScope.focused(): UiObject2? {
    InstrumentationRegistry.getInstrumentation().getUiAutomation(Configurator.getInstance().uiAutomationFlags).clearCache()
    return device.findObject(By.pkg(PACKAGE).focused(true))
}

/** The focused element's bounds, or null when nothing is focused or it changed while read. */
private fun MacrobenchmarkScope.focusedBounds(): Rect? = try {
    focused()?.visibleBounds
} catch (e: StaleObjectException) {
    null
}

/** The focused element's text and its descendants', or "" when nothing is focused or it changed while read. */
private fun MacrobenchmarkScope.focusedText(): String = try {
    focused()?.let { node -> buildList<String> { collectText(node, this) }.joinToString(" ") }.orEmpty()
} catch (e: StaleObjectException) {
    ""
}

private fun collectText(node: UiObject2, into: MutableList<String>) {
    node.text?.let(into::add)
    node.contentDescription?.let(into::add)
    node.children.forEach { collectText(it, into) }
}
