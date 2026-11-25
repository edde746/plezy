package com.edde746.plezy.presentation.supporter

import com.edde746.plezy.presentation.settings.trailingValueOf
import com.edde746.plezy.presentation.settings.valueSubtitleOf
import com.edde746.plezy.strings.T
import com.edde746.plezy.supporter.AppIconCatalog
import com.edde746.plezy.supporter.AppIcons
import com.edde746.plezy.supporter.Supporter
import com.edde746.plezy.supporter.SupporterAvailability
import com.edde746.plezy.supporter.SupporterError
import com.edde746.plezy.supporter.SupporterPurchaseStatus
import com.edde746.plezy.supporter.SupporterStoreState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

/** One perk the Supporter sheet lists. */
enum class SupporterPerk {
    PRESET_THEMES,
    CUSTOM_THEME,
    APP_ICONS,
    ;

    val title: String get() = when (this) {
        PRESET_THEMES -> T.supporter.presetThemes
        CUSTOM_THEME -> T.supporter.customTheme
        APP_ICONS -> T.supporter.appIcons
    }

    val description: String get() = when (this) {
        PRESET_THEMES -> T.supporter.presetThemesDescription
        CUSTOM_THEME -> T.supporter.customThemeDescription
        APP_ICONS -> T.supporter.appIconsDescription
    }
}

/** The one status line above the sheet's buttons; [failure] paints it in the error colour ("nothing to restore" isn't). */
data class SupporterNotice(val message: String, val failure: Boolean, val pending: Boolean = false)

/**
 * The Supporter sheet as both UIs draw it. Unlocked: the thank-you and Close. Otherwise the intro, [perks], at most
 * one [notice], the primary button (Buy with the price, or Retry when the price failed: [retry]) and Restore Purchases.
 */
data class SupporterSheetUiState(
    val unlocked: Boolean,
    val perks: List<SupporterPerk>,
    val notice: SupporterNotice?,
    /** The price failed to load: the primary button is Retry. */
    val retry: Boolean,
    /** "Buy for 3,99 €", or "Loading price…" before the price is there. */
    val buyLabel: String,
    val buyEnabled: Boolean,
    /** The price is loading or the store's purchase flow is open. */
    val buySpinner: Boolean,
    val restoreEnabled: Boolean,
    val restoreSpinner: Boolean,
) {
    companion object {
        fun of(state: SupporterStoreState, unlocked: Boolean, offersAppIcons: Boolean): SupporterSheetUiState {
            val price = state.price
            val productError = if (price == null && !state.loadingProduct) state.productError else null
            // One notice at a time: the latest action's error, else why the price is missing, else the pending purchase.
            val error = state.error ?: productError
            val notice = when {
                error != null -> SupporterNotice(error.message, failure = error != SupporterError.NOTHING_TO_RESTORE)
                state.status == SupporterPurchaseStatus.PENDING -> SupporterNotice(T.supporter.pending, failure = false, pending = true)
                else -> null
            }
            return SupporterSheetUiState(
                unlocked = unlocked,
                perks = SupporterPerk.entries.filter { it != SupporterPerk.APP_ICONS || offersAppIcons },
                notice = notice,
                retry = productError != null,
                buyLabel = if (price != null) T.supporter.buy(price = price) else T.supporter.loadingPrice,
                buyEnabled = price != null && !state.busy && state.status != SupporterPurchaseStatus.PENDING,
                buySpinner = state.loadingProduct || state.status == SupporterPurchaseStatus.PURCHASING,
                restoreEnabled = !state.busy,
                restoreSpinner = state.status == SupporterPurchaseStatus.RESTORING,
            )
        }
    }
}

private val SupporterError.message: String get() = when (this) {
    SupporterError.STORE_UNAVAILABLE -> T.supporter.errors.storeUnavailable
    SupporterError.PRODUCT_NOT_FOUND -> T.supporter.errors.productNotFound
    SupporterError.PRODUCT_QUERY_FAILED -> T.supporter.errors.productQueryFailed
    SupporterError.PURCHASE_FAILED -> T.supporter.errors.purchaseFailed
    SupporterError.RESTORE_FAILED -> T.supporter.errors.restoreFailed
    SupporterError.NOTHING_TO_RESTORE -> T.supporter.errors.nothingToRestore
}

/**
 * Settings' top tile in purchasable builds: the Theme & Icon Pack, with what it unlocks while locked and thanks once
 * unlocked. Either opens its sheet.
 */
data class SupporterTileUi(val title: String, val subtitle: String)

/**
 * The Supporter sheet's store, for the app's lifetime. [open] it as the sheet shows (only where [canOpen]); the UIs
 * draw [state] and call [buy], [retry] and [restore].
 */
class SupporterSheetStore(private val supporter: Supporter, private val offersAppIcons: Boolean, private val scope: CoroutineScope) {
    /** The sheet opens only in builds that sell the purchase. */
    val canOpen: Boolean get() = supporter.availability == SupporterAvailability.PURCHASABLE

    val state: StateFlow<SupporterSheetUiState> = combine(supporter.storeState, supporter.unlocked) { store, unlocked ->
        SupporterSheetUiState.of(store, unlocked, offersAppIcons)
    }.stateIn(scope, SharingStarted.Eagerly, SupporterSheetUiState.of(supporter.storeState.value, supporter.unlocked.value, offersAppIcons))

    /** Settings' top tile, shown where [canOpen]. */
    val tile: StateFlow<SupporterTileUi> = supporter.unlocked.map(::tileOf).stateIn(scope, SharingStarted.Eagerly, tileOf(supporter.unlocked.value))

    /** The sheet shows: it starts from the offer, not an old failure, and the price loads. */
    fun open() {
        if (!canOpen) return
        supporter.clearError()
        scope.launch { supporter.loadProduct() }
    }

    fun buy() {
        scope.launch { supporter.purchase() }
    }

    fun retry() {
        scope.launch { supporter.loadProduct() }
    }

    fun restore() {
        scope.launch { supporter.restore() }
    }

    private fun tileOf(unlocked: Boolean): SupporterTileUi = SupporterTileUi(
        T.supporter.title,
        when {
            unlocked -> T.supporter.tileUnlocked
            offersAppIcons -> T.supporter.tileSubtitle
            else -> T.supporter.tileSubtitleThemesOnly
        },
    )
}

/** One tile of the app icon picker: [current] has the accent border and check, [locked] the lock. */
data class AppIconTileUi(val id: String, val label: String, val current: Boolean, val locked: Boolean) {
    val isDefault: Boolean get() = id == AppIconCatalog.DEFAULT_ID

    /** What a screen reader says after the name. */
    val stateLabel: String? get() = when {
        current -> T.appIcon.current
        locked -> T.appIcon.locked
        else -> null
    }
}

/**
 * Settings › Appearance's App icon row and its picker. [shown] while the build offers the perks and the device can
 * switch its icon; [tiles] in the catalog's order; [lockedHint] above them while the alternates are locked. The row
 * shows [currentLabel] beside its title while short ([rowTrailingValue]), else under it ([rowSubtitle]).
 */
data class AppIconPickerUiState(
    val shown: Boolean,
    val currentLabel: String,
    val tiles: List<AppIconTileUi>,
    val lockedHint: String?,
) {
    val rowTrailingValue: String? get() = trailingValueOf(currentLabel)
    val rowSubtitle: String? get() = valueSubtitleOf(currentLabel, null)
}

/** What the picker asks of its UI once ([AppIconPickerStore.events]). */
sealed interface AppIconPickerEvent {
    /** Open the Supporter sheet for a locked icon; tell the store when it closes ([AppIconPickerStore.supporterSheetClosed]). */
    data object OpenSupporter : AppIconPickerEvent
}

/**
 * The app icon picker's store, for the app's lifetime. Choosing a locked alternate opens the Supporter sheet, and the
 * icon applies only if the purchase unlocked it; the default is always selectable; one choice at a time.
 */
class AppIconPickerStore(
    private val appIcons: AppIcons,
    private val supporter: Supporter,
    private val scope: CoroutineScope,
    /** Shows a message over the app ([com.edde746.plezy.app.AppSession.notify]): a switch the system refused. */
    private val notify: (String) -> Unit,
) {
    private val mutableEvents = Channel<AppIconPickerEvent>(Channel.BUFFERED)
    private var applying = false
    private var waitingForSupporter: String? = null

    val events: Flow<AppIconPickerEvent> = mutableEvents.receiveAsFlow()

    val state: StateFlow<AppIconPickerUiState> = combine(appIcons.state, supporter.unlocked) { icons, unlocked ->
        stateOf(icons.supported, icons.currentId, unlocked)
    }.stateIn(scope, SharingStarted.Eagerly, stateOf(appIcons.state.value.supported, appIcons.state.value.currentId, supporter.unlocked.value))

    /** The picker shows: the icon the home screen has now. */
    fun refresh() {
        scope.launch { appIcons.refresh() }
    }

    fun choose(id: String) {
        if (applying || id == appIcons.state.value.currentId) return
        applying = true
        if (id != AppIconCatalog.DEFAULT_ID && !supporter.unlocked.value) {
            waitingForSupporter = id
            mutableEvents.trySend(AppIconPickerEvent.OpenSupporter)
            return
        }
        apply(id)
    }

    /** The Supporter sheet a locked choice opened has closed: the purchase decides whether the icon applies. */
    fun supporterSheetClosed() {
        val id = waitingForSupporter ?: return
        waitingForSupporter = null
        if (supporter.unlocked.value) apply(id) else applying = false
    }

    private fun apply(id: String) {
        scope.launch {
            try {
                appIcons.setIcon(id)?.let { notify(T.appIcon.changeFailed) }
            } finally {
                applying = false
            }
        }
    }

    private fun stateOf(supported: Boolean, currentId: String, unlocked: Boolean) = AppIconPickerUiState(
        shown = supported && supporter.available,
        currentLabel = AppIconCatalog.byId(currentId)?.label ?: T.appIcon.defaultIcon,
        tiles = AppIconCatalog.options.map { AppIconTileUi(it.id, it.label, it.id == currentId, !it.isDefault && !unlocked) },
        lockedHint = if (unlocked) null else T.appIcon.lockedHint,
    )
}
