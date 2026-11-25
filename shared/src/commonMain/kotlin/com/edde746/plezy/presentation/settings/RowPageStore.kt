package com.edde746.plezy.presentation.settings

import com.edde746.plezy.data.settings.DeviceSetting
import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.log.Log
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch

/**
 * A settings page of rows ([SettingsPageStore]) bound to device settings: it observes each setting it shows, so every
 * row follows a change made anywhere (the player, an import, a reset), and rebuilds its groups ([build]) on each. The
 * rows are made with the [Rows] helpers, which register what each row's intent does; an intent for an id the page
 * doesn't show is a programming error.
 *
 * A subclass calls [start] last in its constructor, with the settings it reads, and [follow]s any other input.
 */
internal abstract class RowPageStore(
    protected val settings: DeviceSettingsRepository,
    parentScope: CoroutineScope,
    private val heading: () -> String,
) : SettingsPageStore {
    protected val scope = parentScope.childScope()
    private val mutableEvents = Channel<SettingsEvent>(Channel.BUFFERED)
    override val events: Flow<SettingsEvent> = mutableEvents.receiveAsFlow()

    private val mutableState = MutableStateFlow(SettingsPageUiState(heading(), emptyList(), loading = true))
    override val state: StateFlow<SettingsPageUiState> = mutableState.asStateFlow()

    /** The stored values by key; null until read. */
    private var values: Map<String, Any?>? = null
    private var handlers = Handlers()

    /** What a [SettingsEvent.Confirm] does once confirmed, by its id. */
    private val confirms = HashMap<String, () -> Unit>()

    /** The page's groups from the stored values ([value]); called on every change once they were read. */
    protected abstract fun build(rows: Rows): List<SettingsGroup>

    /** Text above the groups, or an empty state in their place. */
    protected open fun header(): String? = null
    protected open fun empty(): SettingsEmptyState? = null

    /** Whether the page waits on something besides the settings ([start]). */
    protected open val loading: Boolean get() = false

    protected fun start(read: List<DeviceSetting<*>>) {
        if (read.isEmpty()) {
            values = emptyMap()
            publish()
            return
        }
        scope.launch {
            combine(read.map { settings.observe(it) }) { it.toList() }.collect { current ->
                values = read.map { it.key }.zip(current).toMap()
                publish()
            }
        }
    }

    /** Runs [onEach] with every value of [flow] and rebuilds the page after it. */
    protected fun <T> follow(flow: Flow<T>, onEach: (T) -> Unit) {
        scope.launch {
            flow.collect {
                onEach(it)
                publish()
            }
        }
    }

    /** [setting]'s stored value, its default while unset. */
    @Suppress("UNCHECKED_CAST")
    protected fun <T> value(setting: DeviceSetting<T>): T {
        val read = checkNotNull(values) { "Read before the settings were" }
        require(setting.key in read || read.isEmpty()) { "${setting.key} isn't among the settings this page reads" }
        return if (setting.key in read) read[setting.key] as T else setting.default
    }

    protected fun publish() {
        if (values == null) return
        val next = Handlers()
        val groups = build(Rows(next)).filter { it.rows.isNotEmpty() }
        handlers = next
        mutableState.value = SettingsPageUiState(title(), groups, loading = loading, header = header(), empty = empty())
    }

    /** The page's title now, in the interface's language now. */
    protected open fun title(): String = heading()

    protected fun emit(event: SettingsEvent) {
        mutableEvents.trySend(event)
    }

    protected fun message(text: String, error: Boolean = false) = emit(SettingsEvent.Message(text, error))

    /** Asks for confirmation; [onConfirm] runs once [confirm]ed. */
    protected fun confirmFirst(id: String, title: String, message: String, confirmLabel: String, destructive: Boolean, onConfirm: () -> Unit) {
        confirms[id] = onConfirm
        emit(SettingsEvent.Confirm(id, title, message, confirmLabel, destructive))
    }

    /** Stores [value] as [setting], checked as the settings screens check it; a failure shows "Could not save changes". */
    protected fun <T> write(setting: DeviceSetting<T>, value: T) {
        AppSettings.validate(setting, value)
        scope.launch { guarded("storing ${setting.key}") { settings.set(setting, value) } }
    }

    /** Runs [block], showing "Could not save changes. Try again." when it fails; false then. */
    protected suspend fun guarded(what: String, block: suspend () -> Unit): Boolean = try {
        block()
        true
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.e(TAG, e) { "$what failed" }
        message(T.settings.saveFailed, error = true)
        false
    }

    override fun toggle(id: String, checked: Boolean) = handler(handlers.toggles, id)(checked)

    override fun choose(id: String, optionId: String) = handler(handlers.choices, id)(optionId)

    override fun setNumber(id: String, text: String): String? = handler(handlers.numbers, id)(text)

    override fun checkNumber(id: String, text: String): String? = handler(handlers.numberChecks, id)(text)

    override fun setSlider(id: String, value: Double) = handler(handlers.sliders, id)(value)

    override fun setChecked(id: String, checkedIds: List<String>) = handler(handlers.checklists, id)(checkedIds)

    override fun submitText(id: String, text: String): String? = handler(handlers.texts, id)(text)

    override fun checkText(id: String, text: String): String? = handler(handlers.textChecks, id)(text)

    override fun resetText(id: String): String? = handler(handlers.textResets, id)()

    override fun setColor(id: String, hex: String) = handler(handlers.colors, id)(hex)

    override fun activate(id: String) = handler(handlers.links, id)()

    override fun confirm(id: String) {
        val action = confirms.remove(id) ?: throw IllegalArgumentException("Nothing awaits confirming $id")
        action()
    }

    override fun exported(saved: Boolean, error: String?): Unit = throw IllegalStateException("${this::class.simpleName} saves no file")

    override fun imported(bytes: ByteArray?): Unit = throw IllegalStateException("${this::class.simpleName} opens no file")

    override fun release() {
        scope.cancel()
        mutableEvents.close()
    }

    private fun <H> handler(map: Map<String, H>, id: String): H =
        map[id] ?: throw IllegalArgumentException("${this::class.simpleName} has no such row: $id")

    protected class Handlers {
        val toggles = HashMap<String, (Boolean) -> Unit>()
        val choices = HashMap<String, (String) -> Unit>()
        val numbers = HashMap<String, (String) -> String?>()
        val numberChecks = HashMap<String, (String) -> String?>()
        val sliders = HashMap<String, (Double) -> Unit>()
        val checklists = HashMap<String, (List<String>) -> Unit>()
        val texts = HashMap<String, (String) -> String?>()
        val textChecks = HashMap<String, (String) -> String?>()
        val textResets = HashMap<String, () -> String?>()
        val colors = HashMap<String, (String) -> Unit>()
        val links = HashMap<String, () -> Unit>()
    }

    /** The row helpers of one [build]: each makes a row and registers its intent. */
    protected inner class Rows(private val handlers: Handlers) {
        /** A switch for [setting]. */
        fun toggle(id: String, setting: DeviceSetting<Boolean>, title: String, subtitle: String?, icon: SettingIcon?, enabled: Boolean = true) =
            toggle(id, value(setting), title, subtitle, icon, enabled) { write(setting, it) }

        /** A switch showing [checked], [onChange] storing a change. */
        fun toggle(id: String, checked: Boolean, title: String, subtitle: String?, icon: SettingIcon?, enabled: Boolean = true, onChange: (Boolean) -> Unit): SettingToggleRow {
            handlers.toggles[id] = { if (enabled) onChange(it) }
            return SettingToggleRow(id, title, subtitle, checked, enabled, icon)
        }

        /** A choice among [options] (value to label, and optional dialog subtitle) for [setting]; [caption] says what it does. */
        fun <V> choice(
            id: String,
            setting: DeviceSetting<V>,
            title: String,
            options: List<Choice<V>>,
            icon: SettingIcon?,
            caption: String? = null,
            shown: V = value(setting),
        ): SettingChoiceRow = choice(id, title, options, shown, icon, caption) { write(setting, it) }

        /** A choice among [options] showing [selected], [onChoose] storing a pick. */
        fun <V> choice(
            id: String,
            title: String,
            options: List<Choice<V>>,
            selected: V,
            icon: SettingIcon?,
            caption: String? = null,
            unselectedLabel: String = "",
            onChoose: (V) -> Unit,
        ): SettingChoiceRow {
            handlers.choices[id] = { optionId ->
                val picked = options.firstOrNull { it.id == optionId } ?: throw IllegalArgumentException("$id has no option $optionId")
                onChoose(picked.value)
            }
            return SettingChoiceRow(
                id,
                title,
                caption,
                options.map { SettingChoiceOption(it.id, it.label, it.value == selected, it.subtitle) },
                unselectedLabel,
                icon = icon,
            )
        }

        /**
         * A number typed into a dialog for [setting], in the bounds the screens offer for it
         * ([AppSettings.numericBounds]), shown as [valueLabel] gives it; [label] names the value in the field and, lower
         * case, the unit of the range error.
         */
        fun number(id: String, setting: DeviceSetting<Int>, title: String, valueLabel: (Int) -> String, label: String, suffix: String, icon: SettingIcon?): SettingNumberRow {
            val bounds = checkNotNull(AppSettings.numericBounds(setting)) { "${setting.key} has no bounds" }
            val min = bounds.start.toInt()
            val max = bounds.endInclusive.toInt()
            val current = value(setting)
            val check = { text: String ->
                when (text.trim().toIntOrNull()) {
                    null -> T.settings.validationErrorEnterNumber
                    !in min..max -> T.settings.validationErrorDuration(min.toString(), max.toString(), label.lowercase())
                    else -> null
                }
            }
            handlers.numberChecks[id] = check
            handlers.numbers[id] = { text ->
                check(text) ?: run {
                    val typed = text.trim().toInt()
                    if (typed != current) write(setting, typed)
                    null
                }
            }
            return SettingNumberRow(id, title, valueLabel(current), current, min, max, suffix, T.settings.durationHint(min.toString(), max.toString()), icon)
        }

        /** A link row saying what it does in [caption] and, where it opens a setting, its current [valueLabel]; [onActivate] runs when it is activated. */
        fun link(
            id: String,
            title: String,
            caption: String?,
            icon: SettingIcon?,
            trailing: LinkTrailing = LinkTrailing.CHEVRON,
            busy: Boolean = false,
            destructive: Boolean = false,
            accent: Boolean = false,
            subtitleLines: Int = 1,
            valueLabel: String? = null,
            onActivate: () -> Unit,
        ): SettingLinkRow {
            handlers.links[id] = { if (!busy) onActivate() }
            return SettingLinkRow(id, title, caption, icon, trailing, busy = busy, destructive = destructive, accent = accent, subtitleLines = subtitleLines, valueLabel = valueLabel)
        }

        /** A link to the settings page [page]. */
        fun page(id: String, title: String, caption: String?, icon: SettingIcon?, page: SettingsPageId, arg: String? = null, valueLabel: String? = null) =
            link(id, title, caption, icon, valueLabel = valueLabel) { emit(SettingsEvent.Open(page, arg)) }

        fun slider(id: String, title: String, value: Double, min: Double, max: Double, steps: Int, valueLabel: String?, startLabel: String?, endLabel: String?, icon: SettingIcon?, onChange: (Double) -> Unit): SettingSliderRow {
            handlers.sliders[id] = { onChange(it.coerceIn(min, max)) }
            return SettingSliderRow(id, title, value, min, max, steps, valueLabel, startLabel, endLabel, icon)
        }

        /** Several options checked at once, [valueLabel] naming the checked ones; [onSave] gets the checked ids in option order. */
        fun checklist(id: String, title: String, valueLabel: String, caption: String?, options: List<SettingCheckOption>, icon: SettingIcon?, onSave: (List<String>) -> Unit): SettingChecklistRow {
            handlers.checklists[id] = { checked -> onSave(options.map { it.id }.filter { it in checked }) }
            return SettingChecklistRow(id, title, valueLabel, caption, options, icon)
        }

        /**
         * A text edited in a dialog; [check] returns the error shown while typing (stores nothing), [submit] the inline
         * error or null once stored, after [check] passed; [reset] the text the reset action fills in, or null once it
         * stored the reset itself (the dialog closes).
         */
        fun text(
            id: String,
            title: String,
            caption: String?,
            value: String,
            fieldLabel: String,
            hint: String,
            resetLabel: String?,
            icon: SettingIcon?,
            monospace: Boolean = false,
            reset: () -> String? = { throw IllegalStateException("$id has no reset") },
            check: (String) -> String? = { null },
            submit: (String) -> String?,
        ): SettingTextRow {
            handlers.textChecks[id] = check
            handlers.texts[id] = { text -> check(text) ?: submit(text) }
            handlers.textResets[id] = reset
            return SettingTextRow(id, title, caption, value, fieldLabel, hint, resetLabel, monospace, icon)
        }

        /**
         * A chapter-title pattern: blank or invalid patterns are refused ("Invalid regular expression"), a
         * valid one stored as typed; Reset to Default fills in [setting]'s default.
         */
        fun regex(id: String, setting: DeviceSetting<String>, title: String, caption: String, icon: SettingIcon?): SettingTextRow =
            text(
                id, title, caption, value(setting), T.settings.regex, setting.default, T.settings.resetToDefault, icon,
                monospace = true,
                reset = { setting.default },
                check = { typed -> if (AppSettings.isValidSkipPattern(typed)) null else T.settings.invalidRegex },
            ) { typed ->
                write(setting, typed)
                null
            }

        /** A colour for [setting], stored `#RRGGBB` upper case; the same colour writes nothing. */
        fun color(id: String, setting: DeviceSetting<String>, title: String, icon: SettingIcon?): SettingColorRow {
            val current = value(setting)
            handlers.colors[id] = { hex ->
                val rgb = rgbHex(hex) ?: throw IllegalArgumentException("Not a colour: $hex")
                if (!rgb.equals(current, ignoreCase = true)) write(setting, rgb)
            }
            return SettingColorRow(id, title, rgbHex(current) ?: "#000000", icon)
        }

        fun slot(id: String, slot: SettingSlot) = SettingSlotRow(id, slot)
    }

    /** One option of a choice: its [value], the option [id] the UI sends back, its [label] and dialog [subtitle]. */
    protected data class Choice<V>(val value: V, val id: String, val label: String, val subtitle: String? = null)

    protected fun <E : Enum<E>> choices(entries: List<E>, label: (E) -> String, subtitle: (E) -> String? = { null }): List<Choice<E>> =
        entries.map { Choice(it, it.name, label(it), subtitle(it)) }

    protected companion object {
        const val TAG = "settings"

        /** `#RRGGBB` upper case from `#RRGGBB` or `#AARRGGBB` (alpha dropped), the `#` optional; null for anything else. */
        fun rgbHex(text: String): String? {
            val digits = text.trim().removePrefix("#")
            if ((digits.length != 6 && digits.length != 8) || !digits.all { it.isDigit() || it.lowercaseChar() in 'a'..'f' }) return null
            return "#" + digits.takeLast(6).uppercase()
        }
    }
}
