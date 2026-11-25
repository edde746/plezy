package com.edde746.plezy.ui.supporter

import androidx.compose.foundation.border
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.supporter.AppIconPickerEvent
import com.edde746.plezy.presentation.supporter.AppIconTileUi
import com.edde746.plezy.presentation.supporter.SupporterPerk
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.app.LocalPlezyPlatform
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.GroupRow
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.RowGroup
import com.edde746.plezy.ui.components.groupShape
import com.edde746.plezy.ui.components.PlezySheet
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.icons.materialIcon
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.PlezyColors
import kotlinx.coroutines.launch

/**
 * Settings' top tile in builds that sell the Theme & Icon Pack (`SupporterSheetStore.tile`): the pack, with what it
 * unlocks while locked and thanks once unlocked. Either opens its sheet ([onOpen]). Nothing in other builds.
 */
@Composable
fun SupporterTile(app: AppSession, shape: Shape, onOpen: () -> Unit, modifier: Modifier = Modifier) {
    if (!app.supporterSheet.canOpen) return
    val current by app.supporterSheet.tile.collectAsState()
    GroupRow(
        title = current.title,
        subtitle = current.subtitle,
        onClick = onOpen,
        modifier = modifier,
        shape = shape,
        icon = SupporterIcons.Palette,
    )
}

/** Settings' donation tile (builds that link to donations, outside a Store package): opens Liberapay in the browser. */
@Composable
fun DonationTile(app: AppSession, shape: Shape, modifier: Modifier = Modifier) {
    val url = app.donationUrl ?: return
    GroupRow(
        title = T.settings.supportDeveloper,
        subtitle = T.settings.supportDeveloperDescription,
        onClick = { app.openUrl(url) },
        modifier = modifier,
        shape = shape,
        icon = SupporterIcons.Favorite,
        trailing = { Icon(PlezyIcons.OpenInNew, contentDescription = null, tint = PlezyColors.TextMuted, modifier = Modifier.size(20.dp)) },
    )
}

/**
 * The Supporter sheet: the perks, the price and Buy, Restore Purchases; once unlocked, thanks and Close. With the
 * remote, focus starts on Restore while the price loads and moves to Buy once it can act, and to Close on unlock; Up on
 * the top button scrolls the intro back into view.
 */
@Composable
fun SupporterSheet(app: AppSession, onDismiss: () -> Unit) {
    val store = app.supporterSheet
    LaunchedEffect(Unit) { store.open() }
    val state by store.state.collectAsState()
    val buyFocus = remember { FocusRequester() }
    val restoreFocus = remember { FocusRequester() }
    val closeFocus = remember { FocusRequester() }
    val scroll = rememberScrollState()
    val scope = rememberCoroutineScope()
    // Up from the top button: the intro and perks above it, which take no focus, come back into view.
    val toTop = Modifier.onPreviewKeyEvent { event ->
        if (event.type == KeyEventType.KeyDown && event.key == Key.DirectionUp) scope.launch { scroll.animateScrollTo(0) }
        false
    }
    LaunchedEffect(state.unlocked) { if (state.unlocked) runCatching { closeFocus.requestFocus() } }
    LaunchedEffect(state.buyEnabled) { if (state.buyEnabled) runCatching { buyFocus.requestFocus() } }
    PlezySheet(
        onDismiss = onDismiss,
        title = T.supporter.title,
        initialFocus = if (state.unlocked) closeFocus else if (state.buyEnabled || state.retry) buyFocus else restoreFocus,
        probe = "supporter",
    ) {
        Column(
            Modifier.fillMaxWidth().weight(1f, fill = false).verticalScroll(scroll).padding(vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            if (state.unlocked) {
                Icon(SupporterIcons.Favorite, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(48.dp).align(Alignment.CenterHorizontally))
                Text(T.supporter.thankYouTitle, style = MaterialTheme.typography.titleMedium, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth())
                Text(T.supporter.thankYouBody, color = PlezyColors.TextMuted, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth())
                PlezyButton(T.common.close, onDismiss, Modifier.focusRequester(closeFocus).then(toTop), fill = true)
                return@Column
            }
            Text(T.supporter.intro, color = PlezyColors.TextMuted, style = MaterialTheme.typography.bodyMedium)
            RowGroup {
                state.perks.forEachIndexed { index, perk ->
                    GroupRow(perk.title, onClick = null, shape = groupShape(index, state.perks.size), subtitle = perk.description, icon = perk.icon)
                }
            }
            state.notice?.let { notice ->
                val color = if (notice.failure) PlezyColors.Error else PlezyColors.TextMuted
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Icon(
                        when {
                            notice.pending -> SupporterIcons.Hourglass
                            notice.failure -> PlezyIcons.ErrorOutline
                            else -> PlezyIcons.Info
                        },
                        null,
                        tint = color,
                        modifier = Modifier.size(20.dp),
                    )
                    Text(notice.message, color = color, style = MaterialTheme.typography.bodyMedium)
                }
            }
            if (state.retry) {
                PlezyButton(T.common.retry, store::retry, Modifier.focusRequester(buyFocus).then(toTop), icon = PlezyIcons.Refresh, fill = true)
            } else {
                PlezyButton(
                    state.buyLabel,
                    store::buy,
                    Modifier.focusRequester(buyFocus).then(toTop),
                    style = ButtonStyle.PRIMARY,
                    icon = SupporterIcons.Favorite,
                    enabled = state.buyEnabled,
                    fill = true,
                )
            }
            PlezyButton(
                T.supporter.restore,
                store::restore,
                Modifier.focusRequester(restoreFocus).then(if (state.buyEnabled || state.retry) Modifier else toTop),
                style = ButtonStyle.TEXT,
                icon = SupporterIcons.Restore,
                enabled = state.restoreEnabled,
                fill = true,
            )
        }
    }
}

private val SupporterPerk.icon: ImageVector
    get() = when (this) {
        SupporterPerk.PRESET_THEMES -> SupporterIcons.Palette
        SupporterPerk.CUSTOM_THEME -> SupporterIcons.Colorize
        SupporterPerk.APP_ICONS -> PlezyIcons.Apps
    }

/**
 * Settings › Appearance's App icon row, below Theme: shown while the build offers the perks and the device can switch
 * its icon, with the icon shown now; opens the picker ([onOpen]). It trails as every row that opens a choice does, its
 * value then the drop-down mark, so its value lines up with theirs.
 */
@Composable
fun AppIconRow(app: AppSession, shape: Shape, onOpen: () -> Unit, modifier: Modifier = Modifier) {
    val state by app.appIconPicker.state.collectAsState()
    if (!state.shown) return
    GroupRow(
        T.appIcon.title, onOpen, modifier, shape = shape, subtitle = state.rowSubtitle, value = state.rowTrailingValue, icon = PlezyIcons.Apps,
        trailing = { Icon(PlezyIcons.ArrowDropDown, contentDescription = null, tint = PlezyColors.MutedContent) },
    )
}

private const val MIN_TILE_WIDTH = 76
private const val MAX_COLUMNS = 8

/**
 * The app icon picker: every icon in a grid (tiles at least 76 dp wide, 3 to 8 columns), the current one ringed and
 * checked, locked alternates with a lock. A locked alternate opens the Supporter sheet and applies once a purchase
 * there unlocks it. On Android the launcher shows the new icon once the user leaves the app.
 */
@Composable
fun AppIconPickerSheet(app: AppSession, onDismiss: () -> Unit) {
    val picker = app.appIconPicker
    val state by picker.state.collectAsState()
    var supporterOpen by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { picker.refresh() }
    LaunchedEffect(picker) {
        picker.events.collect { event ->
            when (event) {
                AppIconPickerEvent.OpenSupporter -> supporterOpen = true
            }
        }
    }
    val tv = LocalAppearance.current.formFactor == FormFactor.TV
    val current = remember { FocusRequester() }
    PlezySheet(onDismiss = onDismiss, title = T.appIcon.title, initialFocus = current, probe = "app-icons") {
        Column(Modifier.fillMaxWidth().weight(1f, fill = false).verticalScroll(rememberScrollState()).padding(vertical = 8.dp)) {
            state.lockedHint?.let {
                Text(it, color = PlezyColors.TextMuted, style = MaterialTheme.typography.bodySmall)
                Spacer(Modifier.height(12.dp))
            }
            IconGrid(state.tiles, current) { picker.choose(it) }
            // Compose shows the picker on Android alone (the desktops have no alternate icons): the launcher switches
            // once the user leaves.
            Spacer(Modifier.height(16.dp))
            Text(if (tv) T.appIcon.tvLauncherHint else T.appIcon.launcherHint, color = PlezyColors.TextMuted, style = MaterialTheme.typography.bodySmall)
        }
    }
    if (supporterOpen) {
        SupporterSheet(app) {
            supporterOpen = false
            picker.supporterSheetClosed()
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun IconGrid(tiles: List<AppIconTileUi>, current: FocusRequester, onChoose: (String) -> Unit) {
    BoxWithConstraints(Modifier.fillMaxWidth()) {
        val spacing = 12.dp
        val columns = ((maxWidth + spacing) / (MIN_TILE_WIDTH.dp + spacing)).toInt().coerceIn(3, MAX_COLUMNS)
        val tileWidth = (maxWidth - spacing * (columns - 1)) / columns
        FlowRow(horizontalArrangement = Arrangement.spacedBy(spacing), verticalArrangement = Arrangement.spacedBy(spacing), maxItemsInEachRow = columns) {
            for (tile in tiles) {
                IconTile(tile, Modifier.width(tileWidth).then(if (tile.current) Modifier.focusRequester(current) else Modifier)) { onChoose(tile.id) }
            }
        }
    }
}

@Composable
private fun IconTile(tile: AppIconTileUi, modifier: Modifier, onClick: () -> Unit) {
    val platform = LocalPlezyPlatform.current
    val shape = RoundedCornerShape(16.dp)
    PlezySurface(
        onClick = onClick,
        modifier = modifier.semantics {
            contentDescription = tile.label
            tile.stateLabel?.let { stateDescription = it }
        },
        shape = shape,
        color = Color.Transparent,
        contentColor = PlezyColors.Text,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.padding(4.dp)) {
            Box(Modifier.fillMaxWidth().aspectRatio(1f)) {
                platform.AppIconPreview(tile.id, Modifier.fillMaxWidth().aspectRatio(1f).clip(shape))
                if (tile.current) Box(Modifier.fillMaxWidth().aspectRatio(1f).border(3.dp, MaterialTheme.colorScheme.primary, shape))
                if (tile.current || tile.locked) {
                    val fill = if (tile.current) MaterialTheme.colorScheme.primary else PlezyColors.Surface
                    val tint = if (tile.current) PlezyColors.Background else PlezyColors.Text
                    Box(
                        Modifier.align(Alignment.BottomEnd).padding(4.dp).size(20.dp).clip(CircleShape).background(fill)
                            .border(1.5.dp, PlezyColors.Background, CircleShape),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(if (tile.current) PlezyIcons.Check else PlezyIcons.Lock, null, tint = tint, modifier = Modifier.size(14.dp))
                    }
                }
            }
            Spacer(Modifier.height(6.dp))
            Text(
                tile.label,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                textAlign = TextAlign.Center,
                color = if (tile.current) PlezyColors.Text else PlezyColors.TextMuted,
                style = MaterialTheme.typography.labelMedium,
            )
        }
    }
}

/** The Supporter's Material Icons as path data. */
private object SupporterIcons {
    val Favorite by materialIcon(
        "M12,21.35l-1.45,-1.32C5.4,15.36 2,12.28 2,8.5 2,5.42 4.42,3 7.5,3c1.74,0 3.41,0.81 4.5,2.09C13.09,3.81 14.76,3 " +
            "16.5,3 19.58,3 22,5.42 22,8.5c0,3.78 -3.4,6.86 -8.55,11.54L12,21.35z",
    )

    val Palette by materialIcon(
        "M12,3c-4.97,0 -9,4.03 -9,9s4.03,9 9,9c0.83,0 1.5,-0.67 1.5,-1.5 0,-0.39 -0.15,-0.74 -0.39,-1.01 -0.23,-0.26 " +
            "-0.38,-0.61 -0.38,-0.99 0,-0.83 0.67,-1.5 1.5,-1.5H16c2.76,0 5,-2.24 5,-5 0,-4.42 -4.03,-8 -9,-8zM6.5,12c" +
            "-0.83,0 -1.5,-0.67 -1.5,-1.5S5.67,9 6.5,9 8,9.67 8,10.5 7.33,12 6.5,12zM9.5,8C8.67,8 8,7.33 8,6.5S8.67,5 9.5," +
            "5s1.5,0.67 1.5,1.5S10.33,8 9.5,8zM14.5,8c-0.83,0 -1.5,-0.67 -1.5,-1.5S13.67,5 14.5,5s1.5,0.67 1.5,1.5S15.33,8 " +
            "14.5,8zM17.5,12c-0.83,0 -1.5,-0.67 -1.5,-1.5S16.67,9 17.5,9s1.5,0.67 1.5,1.5 -0.67,1.5 -1.5,1.5z",
    )

    val Colorize by materialIcon(
        "M20.71,5.63l-2.34,-2.34c-0.39,-0.39 -1.02,-0.39 -1.41,0l-3.12,3.12 -1.93,-1.91 -1.41,1.41 1.42,1.42L3,16.25V21h4.75" +
            "l8.92,-8.92 1.42,1.42 1.41,-1.41 -1.92,-1.92 3.12,-3.12c0.4,-0.4 0.4,-1.03 0.01,-1.42zM6.92,19L5,17.08l8.06," +
            "-8.06 1.92,1.92L6.92,19z",
    )

    val Hourglass by materialIcon(
        "M6,2v6h0.01L6,8.01 10,12l-4,4 0.01,0.01H6V22h12v-5.99h-0.01L18,16l-4,-4 4,-3.99 -0.01,-0.01H18V2H6zM16,16.5V20H8" +
            "v-3.5l4,-4 4,4zM12,11.5l-4,-4V4h8v3.5l-4,4z",
    )

    val Restore by materialIcon(
        "M13,3c-4.97,0 -9,4.03 -9,9H1l3.89,3.89 0.07,0.14L9,12H6c0,-3.87 3.13,-7 7,-7s7,3.13 7,7 -3.13,7 -7,7c-1.93,0 " +
            "-3.68,-0.79 -4.94,-2.06l-1.42,1.42C8.27,19.99 10.51,21 13,21c4.97,0 9,-4.03 9,-9s-4.03,-9 -9,-9zM12,8v5l4.28," +
            "2.54 0.72,-1.21 -3.5,-2.08V8H12z",
    )
}
