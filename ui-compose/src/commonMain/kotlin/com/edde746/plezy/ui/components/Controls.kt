package com.edde746.plezy.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.selection.toggleable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.foundation.text.modifiers.TextAutoSizeLayoutScope
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.PlainTooltip
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TooltipBox
import androidx.compose.material3.TooltipDefaults
import androidx.compose.material3.rememberTooltipState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.State
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.compositeOver
import androidx.compose.ui.graphics.drawOutline
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.graphics.painter.Painter
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.layout.layout
import androidx.compose.ui.layout.layoutId
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.edde746.plezy.ui.focus.focusGrowth
import com.edde746.plezy.ui.focus.focusInset
import com.edde746.plezy.ui.focus.isFocusVisible
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.LocalPlezyColors
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.image.effectMillis
import com.edde746.plezy.ui.theme.contentDirection

/**
 * The colours a [PlezySurface] draws with in its current state. [fill] is read while drawing ([surfaceFill]), so its
 * animation only redraws; [content] switches at once, as the content reads it while composing.
 */
private class SurfaceState(val fill: State<Color>, val content: Color)

/**
 * The fill and content colours of a control resting in [color] / [contentColor]: focused (keyboard, D-pad, remote;
 * while focus shows, [isFocusVisible]) or [drawnFocused] it turns the primary fill with its content colour (on TV the
 * text colour, never the accent: [focusFill][com.edde746.plezy.ui.theme.PlezyColorSet.focusFill]); hovered or pressed
 * a step lighter; disabled faint. A control resting in the primary fill keeps it (its focus shows as a ring,
 * [focusGrowth]); on TV it rests in a solid tint of the accent instead
 * ([primaryRest][com.edde746.plezy.ui.theme.PlezyColorSet.primaryRest], in the text colour) and turns the focus fill as
 * every control does, so only the focused control is ever filled. One resting transparent or translucent (an icon
 * button over a picture or the video) stays see-through hovered or pressed: [PlezyColors.HoverTint] over its rest,
 * never a solid surface.
 */
@Composable
private fun surfaceState(interactions: MutableInteractionSource, color: Color, contentColor: Color, enabled: Boolean, drawnFocused: Boolean): SurfaceState {
    val focusedRaw by interactions.collectIsFocusedAsState()
    val hovered by interactions.collectIsHoveredAsState()
    val pressed by interactions.collectIsPressedAsState()
    val focusVisible = isFocusVisible()
    val focused = focusedRaw && focusVisible || drawnFocused
    val primary = MaterialTheme.colorScheme.primary
    val colors = LocalPlezyColors.current
    val tv = LocalPlezyDimens.current.focusGrows
    val tvPrimary = tv && color == primary
    val restsPrimary = color == primary && !tv
    val rest = if (tvPrimary) colors.primaryRest else color
    val target = when {
        !enabled -> if (color.alpha == 0f) color else colors.surfaceHigh.copy(alpha = 0.6f)
        focused && !restsPrimary -> colors.focusFill(tv)
        pressed || hovered -> when {
            restsPrimary -> lerp(primary, colors.onAccent, 0.12f)
            rest.alpha < 1f -> colors.hoverTint.compositeOver(rest)
            else -> colors.surfaceHighest
        }
        else -> rest
    }
    val content = when {
        !enabled -> colors.textFaint
        focused && !restsPrimary -> colors.onFocusFill(tv)
        tvPrimary -> colors.text
        else -> contentColor
    }
    return SurfaceState(animateColorAsState(target, tween(durationMillis = effectMillis(120)), label = "fill"), content)
}

/** [fill] in [shape] behind the content, read while drawing. */
private fun Modifier.surfaceFill(fill: State<Color>, shape: Shape): Modifier = drawWithCache {
    val outline = shape.createOutline(size, layoutDirection, this)
    onDrawBehind {
        val color = fill.value
        if (color.alpha > 0f) drawOutline(outline, color)
    }
}

/**
 * The one focusable, clickable surface every control is made of (buttons, chips, rows, icon buttons): a [color] fill in
 * [shape], never an outline; transparent over a picture or the video. Focus (keyboard, D-pad, remote) turns it the
 * primary fill with black content and, on TV, grows it unless it is a row of a list ([grows] = false: a stream, a
 * setting, a menu option, an addon, where the fill alone shows focus); with [focusInset] (a chip in a row of chips) it
 * keeps its size everywhere and marks focus with a ring inside its edge as well. [drawnFocused]: drawn focused by its
 * owner, which moves a focus of its own over elements that never take the platform's (the Live TV guide). On TV a
 * [color] of the primary fill rests as its solid tint ([surfaceState]). Hover and press lighten it, a
 * see-through one with a tint ([surfaceState]). Content reads [LocalContentColor], so text and icons follow the state
 * (secondary text: [PlezyColors.MutedContent]). An overlay opened from it gives focus back to it
 * ([overlayOpener]). [onLongClick] is a long press (touch) or a held Select (a remote), which screen readers offer as an
 * action named [onLongClickLabel]. With [hitTarget] (a control drawn smaller than a finger's least target: an icon
 * button, a one-line button) it takes taps on a touch screen in a square of at least 48 dp centred on it ([HitTarget]),
 * keeping its drawn size and place.
 */
@Composable
fun PlezySurface(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    shape: Shape = MaterialTheme.shapes.medium,
    color: Color = PlezyColors.SurfaceHigh,
    contentColor: Color = MaterialTheme.colorScheme.onSurface,
    enabled: Boolean = true,
    role: Role = Role.Button,
    selected: Boolean? = null,
    onLongClick: (() -> Unit)? = null,
    onLongClickLabel: String? = null,
    contentAlignment: Alignment = Alignment.TopStart,
    grows: Boolean = true,
    focusInset: Boolean = false,
    hitTarget: Boolean = false,
    drawnFocused: Boolean = false,
    content: @Composable BoxScope.() -> Unit,
) {
    val interactions = remember { MutableInteractionSource() }
    val state = surfaceState(interactions, color, contentColor, enabled, drawnFocused)
    val target = if (hitTarget) rememberHitTarget() else null
    // Off TV a control resting in the primary fill keeps it focused and takes a ring; on TV it rests tinted.
    val restsPrimary = color == MaterialTheme.colorScheme.primary && !LocalPlezyDimens.current.focusGrows
    Box(
        modifier
            .then(
                when {
                    focusInset -> Modifier.focusInset(shape)
                    grows || restsPrimary -> Modifier.focusGrowth(shape, ring = restsPrimary, grows = grows)
                    else -> Modifier
                },
            )
            .then(if (selected != null) Modifier.semantics { this.selected = selected } else Modifier)
            .overlayOpener()
            .then(target?.bounds ?: Modifier)
            .combinedClickable(
                interactionSource = interactions,
                indication = null,
                enabled = enabled,
                role = role,
                onLongClickLabel = onLongClickLabel,
                onLongClick = onLongClick,
                onClick = onClick,
            )
            .then(target?.square ?: Modifier)
            .clip(shape)
            .surfaceFill(state.fill, shape),
        contentAlignment = contentAlignment,
    ) {
        CompositionLocalProvider(LocalContentColor provides state.content) { content() }
    }
}

/**
 * A [PlezySurface] that toggles [checked] (a switch row, a tick box row): the whole surface is the control, and as a
 * row of a list its fill alone shows focus (no growth on TV). [contentColor] is its content's colour at rest (a control
 * inside a row passes the row's, black on a focused row). An overlay opened from it gives focus back to it
 * ([overlayOpener]).
 */
@Composable
fun PlezyToggleSurface(
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
    shape: Shape = MaterialTheme.shapes.medium,
    color: Color = PlezyColors.SurfaceHigh,
    contentColor: Color = MaterialTheme.colorScheme.onSurface,
    enabled: Boolean = true,
    role: Role = Role.Switch,
    content: @Composable BoxScope.() -> Unit,
) {
    val interactions = remember { MutableInteractionSource() }
    val state = surfaceState(interactions, color, contentColor, enabled, drawnFocused = false)
    Box(
        modifier
            .clip(shape)
            .surfaceFill(state.fill, shape)
            .overlayOpener()
            .toggleable(checked, interactions, indication = null, enabled = enabled, role = role, onValueChange = onCheckedChange),
    ) {
        CompositionLocalProvider(LocalContentColor provides state.content) { content() }
    }
}

/**
 * Whether the content colour is a focus fill's ([com.edde746.plezy.ui.theme.PlezyColorSet.onFocusFill]): on the
 * other side of light and dark from the theme's text, whichever theme it is.
 */
@Composable
private fun onFocusFill(): Boolean = (LocalContentColor.current.luminance() < 0.5f) != (PlezyColors.Text.luminance() < 0.5f)

/**
 * The switch at the end of a toggle row ([PlezyToggleSurface]): it shows the state, the row is the control. At rest
 * the theme's standard colours; on a focus fill (the focused row: its content colour turns to the fill's) its colours
 * invert, so its track never vanishes into the fill.
 */
@Composable
fun RowSwitch(checked: Boolean, enabled: Boolean = true) {
    val colors = if (onFocusFill()) {
        SwitchDefaults.colors(
            checkedThumbColor = MaterialTheme.colorScheme.primary,
            checkedTrackColor = PlezyColors.OnPrimary,
            uncheckedThumbColor = PlezyColors.OnPrimary,
            uncheckedTrackColor = Color.Transparent,
            uncheckedBorderColor = PlezyColors.OnPrimary,
        )
    } else {
        SwitchDefaults.colors()
    }
    Switch(checked = checked, onCheckedChange = null, enabled = enabled, colors = colors)
}

/**
 * The tick box at the end of a tick box row ([PlezyToggleSurface] with [Role.Checkbox]): it shows the state, the row
 * is the control. On a focus fill (the focused row) its colours invert, as [RowSwitch]'s do.
 */
@Composable
fun RowCheckbox(checked: Boolean) {
    val colors = if (onFocusFill()) {
        CheckboxDefaults.colors(
            checkedColor = PlezyColors.OnPrimary,
            uncheckedColor = PlezyColors.OnPrimary,
            checkmarkColor = MaterialTheme.colorScheme.primary,
        )
    } else {
        CheckboxDefaults.colors()
    }
    Checkbox(checked = checked, onCheckedChange = null, colors = colors)
}

/** How prominent a [PlezyButton] is. */
enum class ButtonStyle {
    /** The primary fill with black content: the screen's main action (on TV a solid accent tint until focused). */
    PRIMARY,

    /** A solid surfaceHigh fill: every other action. */
    SECONDARY,

    /**
     * No fill until hovered or focused: a quiet action ("See all", Cancel). On TV, where a control without a fill
     * reads as plain text, a tonal pill ([PlezyColors.TonalRest]).
     */
    TEXT,

    /** A secondary button in the error colour: an action that deletes or signs out. */
    DESTRUCTIVE,
}

/**
 * A pill button: [text] with an optional leading [icon] (or [logo], a mark drawn in its own colours: a sign-in
 * provider's), [LocalPlezyDimens]' `controlHeight` tall, in [style]'s fill ([fill] = true: as wide as its
 * parent). [progress] (0–1) shows as a fill inside the button (the watched part of a Resume), in a tone a step from the
 * button's own; [iconProgress] (0–1) as a ring round [icon] ([DownloadMark]: Home's Downloads). A label the button's
 * width can't hold at full size (a Resume beside the round buttons on a narrow phone) shrinks a little before it is
 * cut short; the icons keep their room. A [lead] goes before [text] and is never cut short (an episode's code before
 * its name): [text] is cut short after it, at full size. [grows] = false keeps it its size under focus on TV (a button
 * of a pair that must stay one size), as [PlezySurface]'s. On a touch screen it takes taps in at least 48 dp of
 * height ([PlezySurface]'s `hitTarget`). [contentText]: whether [text] is content text (an addon's or a person's),
 * which takes its direction from its first letter ([contentDirection]). [busy]: its work is under way: a spinner in
 * the icon's place, the label kept.
 */
@Composable
fun PlezyButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    style: ButtonStyle = ButtonStyle.SECONDARY,
    icon: ImageVector? = null,
    logo: Painter? = null,
    enabled: Boolean = true,
    fill: Boolean = false,
    progress: Float? = null,
    trailingIcon: ImageVector? = null,
    grows: Boolean = true,
    lead: String? = null,
    iconProgress: Float? = null,
    contentText: Boolean = false,
    busy: Boolean = false,
) {
    val dimens = LocalPlezyDimens.current
    val (color, content) = when (style) {
        ButtonStyle.PRIMARY -> MaterialTheme.colorScheme.primary to PlezyColors.OnPrimary
        ButtonStyle.SECONDARY -> PlezyColors.SurfaceHigh to MaterialTheme.colorScheme.onSurface
        ButtonStyle.TEXT -> (if (dimens.focusGrows) PlezyColors.TonalRest else Color.Transparent) to MaterialTheme.colorScheme.onSurface
        ButtonStyle.DESTRUCTIVE -> PlezyColors.SurfaceHigh to PlezyColors.Error
    }
    PlezySurface(
        onClick = onClick,
        modifier = modifier.then(if (fill) Modifier.fillMaxWidth() else Modifier).heightIn(min = dimens.controlHeight),
        shape = CircleShape,
        color = color,
        contentColor = content,
        enabled = enabled,
        contentAlignment = Alignment.Center,
        grows = grows,
        hitTarget = true,
    ) {
        if (progress != null && progress > 0f) {
            // The watched part, from the button's leading edge (right to left in Arabic): the button's content colour
            // over its fill, faintly.
            val tone = LocalContentColor.current.copy(alpha = 0.16f)
            val watched = progress.coerceIn(0f, 1f)
            Box(
                Modifier.matchParentSize().drawBehind {
                    val width = size.width * watched
                    val left = if (layoutDirection == LayoutDirection.Rtl) size.width - width else 0f
                    drawRect(tone, topLeft = Offset(left, 0f), size = Size(width, size.height))
                },
            )
        }
        Row(
            Modifier.padding(
                start = if (icon != null || logo != null || busy) 16.dp else ButtonLabelInset,
                end = if (trailingIcon != null) 14.dp else ButtonLabelInset,
                top = ButtonLabelPadding,
                bottom = ButtonLabelPadding,
            ),
            horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (busy) {
                CircularProgressIndicator(Modifier.size(20.dp), color = LocalContentColor.current, strokeWidth = 2.dp)
            } else if (logo != null) {
                Icon(logo, contentDescription = null, Modifier.size(20.dp), tint = Color.Unspecified)
            } else if (icon != null) {
                if (iconProgress != null) DownloadMark(icon, iconProgress, size = 20.dp) else Icon(icon, contentDescription = null, Modifier.size(20.dp))
            }
            // On TV a primary's label is semibold, so it reads as the main action at rest as well.
            val label = MaterialTheme.typography.labelLarge.let { if (style == ButtonStyle.PRIMARY && dimens.focusGrows) it.copy(fontWeight = FontWeight.SemiBold) else it }
            val textStyle = if (contentText) label.contentDirection() else label
            if (lead == null) {
                Text(
                    text,
                    Modifier.weight(1f, fill = false),
                    autoSize = LabelAutoSize(label.fontSize),
                    style = textStyle,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            } else {
                Row(Modifier.weight(1f, fill = false)) {
                    Text(lead, style = label, maxLines = 1, softWrap = false)
                    Text(text, Modifier.weight(1f, fill = false), style = textStyle, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
            }
            if (trailingIcon != null) Icon(trailingIcon, contentDescription = null, Modifier.size(20.dp))
        }
    }
}

/** The smallest a [PlezyButton]'s label shrinks to before it is cut short. */
internal val MIN_LABEL_SIZE = 11.sp

/**
 * A label's size that keeps it whole where it can: the largest from [max] down to [MIN_LABEL_SIZE], in half points, at
 * which the whole label fits the width it has, else [MIN_LABEL_SIZE], where it ends in "…" (a [PlezyButton]'s one
 * line). [byWord]: the label wraps (a person's name over two lines), so it is each of its words that fits a line whole:
 * its lines break only between words. Compose's step-based sizing never steps a label down: it takes the line cut short
 * with "…" for one that fits.
 */
internal data class LabelAutoSize(val max: TextUnit, val byWord: Boolean = false) : TextAutoSize {
    override fun TextAutoSizeLayoutScope.getFontSize(constraints: Constraints, text: AnnotatedString): TextUnit {
        if (!constraints.hasBoundedWidth) return max
        var size = max.value
        while (size > MIN_LABEL_SIZE.value) {
            if (fits(constraints, text, size.sp)) return size.sp
            size -= 0.5f
        }
        return MIN_LABEL_SIZE
    }

    // performLayout lays out the Text's own text, whatever text it is handed.
    private fun TextAutoSizeLayoutScope.fits(constraints: Constraints, text: AnnotatedString, size: TextUnit): Boolean {
        // Laid out on an unbounded width, the label is its whole line, never cut short.
        if (!byWord) return performLayout(Constraints(), text, size).size.width <= constraints.maxWidth
        val layout = performLayout(Constraints(maxWidth = constraints.maxWidth), text, size)
        return (0 until layout.lineCount - 1).all { line ->
            val end = layout.getLineEnd(line)
            text.text.getOrNull(end - 1)?.isWhitespace() == true || text.text.getOrNull(end)?.isWhitespace() == true
        }
    }
}

/**
 * How far inside a [PlezyButton] without icons its label starts (and ends): a text button lines its label up with
 * the text around it by standing this far out.
 */
internal val ButtonLabelInset = 20.dp

/** The room above and below a [PlezyButton]'s label: a pill is at least its label's line and this twice tall. */
internal val ButtonLabelPadding = 8.dp

/** How a [PlezyIconButton] rests. */
enum class IconButtonStyle {
    /** A round surfaceHigh fill. */
    FILLED,

    /** The primary fill with black content (the one emphasised action; on TV a solid accent tint until focused). */
    PRIMARY,

    /** No fill until hovered or focused (inside a row or a field). */
    PLAIN,

    /** A toggle that is on: the accent as a tint over the background ([PlezyColors.AccentRest]) with the text colour. */
    SELECTED,

    /**
     * A dark circle ([PlezyColors.PictureButton]) with white content, whatever the theme, and no outline: over a
     * picture, where the white icon on the dark fill reads over light, mid-tone and dark pictures alike.
     */
    OVER_PICTURE,
}

/**
 * A round icon button, [LocalPlezyDimens]' `iconButtonSize` wide ([size] to override), its icon half that ([iconSize]
 * to override), with [contentDescription] for screen readers. Focus turns it the primary fill (and on TV grows it), as
 * every control; with [focusInset] (a round button in a row of chips, as tall as they are) it keeps its size and marks
 * focus with a ring inside its edge, as the chips do. On a touch screen it takes taps in a square of at least 48 dp
 * ([PlezySurface]'s `hitTarget`).
 */
@Composable
fun PlezyIconButton(
    icon: ImageVector,
    contentDescription: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    style: IconButtonStyle = IconButtonStyle.FILLED,
    enabled: Boolean = true,
    size: Dp = LocalPlezyDimens.current.iconButtonSize,
    selected: Boolean? = null,
    focusInset: Boolean = false,
    drawnFocused: Boolean = false,
    iconSize: Dp = size * 0.5f,
) {
    val (color, content) = when (style) {
        IconButtonStyle.FILLED -> PlezyColors.SurfaceHigh to MaterialTheme.colorScheme.onSurface
        IconButtonStyle.PRIMARY -> MaterialTheme.colorScheme.primary to PlezyColors.OnPrimary
        // Inside a row or field: the row's content colour (black on a focused row).
        IconButtonStyle.PLAIN -> Color.Transparent to LocalContentColor.current
        IconButtonStyle.SELECTED -> PlezyColors.AccentRest to PlezyColors.Text
        IconButtonStyle.OVER_PICTURE -> PlezyColors.PictureButton to Color.White
    }
    PlezySurface(
        onClick = onClick,
        modifier = modifier.size(size),
        shape = CircleShape,
        color = color,
        contentColor = content,
        enabled = enabled,
        selected = selected,
        focusInset = focusInset,
        drawnFocused = drawnFocused,
        contentAlignment = Alignment.Center,
        hitTarget = true,
    ) {
        Icon(icon, contentDescription = contentDescription, Modifier.size(iconSize))
    }
}

/**
 * A solid pill chip ([LocalPlezyDimens]' `chipHeight`): unselected on surfaceHigh, [selected] in the primary fill
 * with black text; no outline. With [checkmark] (the Streams list's row of addons) a selected chip keeps the
 * unselected fill and shows a leading check mark and a semibold label instead, and the chip is as wide either way, the
 * narrower look centred ([widestLook]), so a pick moves no chip of its row. Focused it keeps its size and draws
 * nothing past its edge, so a row of chips keeps one height: the primary fill and a ring inside the edge, which marks a
 * selected chip's focus too ([PlezySurface]'s `focusInset`). A [dropdown] chip opens a menu: its label ends in the
 * dropdown arrow, and a screen reader hears a dropdown list ("selected" while it narrows what is shown). A [tab] chip is
 * one of a row of tabs or exclusive choices: a screen reader hears a tab, selected or not. Any other chip is a command,
 * heard as a button whatever its fill. An empty [label] makes a round chip of the leading icon alone, as wide as it is
 * tall, with no arrow (a menu chip where the row has no room for its text; name it for screen readers through
 * [modifier]). A chip given less than
 * its width (a row that fits its chips to the window) drops its leading icon before it cuts its label short, and a
 * dropdown chip keeps its arrow: its text is what names it, the arrow what says it opens a menu. [onLongClick] is a
 * long press (touch) or a held Select (a remote), for
 * the chip's menu. On a touch screen it takes taps in at least 48 dp of height ([PlezySurface]'s `hitTarget`).
 * [contentLabel]: whether [label] is content text (an addon's or a person's), which takes its direction from its first
 * letter ([contentDirection]). [iconProbe]: the leading icon's harness name ([layoutProbe]), its bounds alone.
 * [tooltip]: a round chip's name with what it shows now (a sort's field and direction), shown as the pointer rests on
 * it (not on TV, which has no pointer).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlezyChip(
    label: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    dropdown: Boolean = false,
    leadingIcon: ImageVector? = null,
    onLongClick: (() -> Unit)? = null,
    checkmark: Boolean = false,
    contentLabel: Boolean = false,
    iconProbe: String? = null,
    drawnFocused: Boolean = false,
    tooltip: String? = null,
    tab: Boolean = false,
) {
    val dimens = LocalPlezyDimens.current
    if (tooltip != null && !dimens.focusGrows) {
        TooltipBox(TooltipDefaults.rememberPlainTooltipPositionProvider(), { PlainTooltip { Text(tooltip) } }, rememberTooltipState(), focusable = false) {
            PlezyChip(label, selected, onClick, modifier, enabled, dropdown, leadingIcon, onLongClick, checkmark, contentLabel, iconProbe, drawnFocused, tab = tab)
        }
        return
    }
    val filled = selected && !checkmark
    val checked = selected && checkmark
    val icon = if (checked) PlezyIcons.Check else leadingIcon
    val iconOnly = label.isEmpty() && icon != null
    PlezySurface(
        onClick = onClick,
        modifier = modifier.heightIn(min = dimens.chipHeight).then(if (iconOnly) Modifier.widthIn(min = dimens.chipHeight) else Modifier),
        shape = CircleShape,
        // On TV a selected chip rests in the accent's lighter tint, apart from a primary button's.
        color = when {
            !filled -> PlezyColors.SurfaceHigh
            dimens.focusGrows -> PlezyColors.AccentRest
            else -> MaterialTheme.colorScheme.primary
        },
        contentColor = when {
            !filled -> MaterialTheme.colorScheme.onSurface
            dimens.focusGrows -> PlezyColors.Text
            else -> PlezyColors.OnPrimary
        },
        enabled = enabled,
        selected = when {
            dropdown -> selected.takeIf { it }
            tab -> selected
            else -> null
        },
        role = when {
            dropdown -> Role.DropdownList
            tab -> Role.Tab
            else -> Role.Button
        },
        onLongClick = onLongClick,
        contentAlignment = Alignment.Center,
        focusInset = true,
        drawnFocused = drawnFocused,
        hitTarget = true,
    ) {
        val tv = dimens.focusGrows
        val style = if (tv) MaterialTheme.typography.titleSmall else MaterialTheme.typography.labelLarge
        val checkedStyle = style.copy(fontWeight = FontWeight.SemiBold)
        val textEdge = if (tv) 18.dp else 14.dp
        val measurer = if (checkmark && label.isNotEmpty()) rememberTextMeasurer() else null
        val density = LocalDensity.current
        Layout(
            content = {
                if (icon != null) Icon(icon, contentDescription = null, Modifier.layoutId(ChipPart.ICON).size(CHIP_ICON).then(iconProbe?.let { Modifier.layoutProbe(it, reportsFocus = false) } ?: Modifier))
                if (label.isNotEmpty()) {
                    val labelStyle = if (checked) checkedStyle else style
                    Text(
                        label,
                        Modifier.layoutId(ChipPart.LABEL),
                        style = if (contentLabel) labelStyle.contentDirection() else labelStyle,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                    if (dropdown) Icon(PlezyIcons.ArrowDropDown, contentDescription = null, Modifier.layoutId(ChipPart.ARROW).size(CHIP_TRAILING_ICON))
                }
            },
            modifier = if (measurer == null) {
                Modifier
            } else {
                with(density) {
                    // Beside the label checked: its start, the check and the gap; unchecked: its start (and a leading
                    // icon and the gap); then its end. Each rounded as the chip's layout rounds it.
                    val checkedStart = CHIP_ICON_START.roundToPx() + CHIP_ICON.roundToPx() + CHIP_ICON_GAP.roundToPx()
                    val plainStart = if (leadingIcon != null) checkedStart else textEdge.roundToPx()
                    val end = (if (dropdown) CHIP_ARROW_END else textEdge).roundToPx()
                    Modifier.widestLook(measurer, label, style, plainStart + end, checkedStyle, checkedStart + end)
                }
            },
        ) { measurables, constraints ->
            val part = { id: ChipPart -> measurables.firstOrNull { it.layoutId == id } }
            val iconPart = part(ChipPart.ICON)
            val labelPart = part(ChipPart.LABEL)
            val arrowPart = part(ChipPart.ARROW)
            val gap = CHIP_ICON_GAP.roundToPx()
            val vertical = 4.dp.roundToPx() * 2
            val labelWanted = labelPart?.maxIntrinsicWidth(constraints.maxHeight) ?: 0
            fun width(withIcon: Boolean, withArrow: Boolean): Int {
                if (labelPart == null) return if (withIcon) CHIP_ICON.roundToPx() else 0
                val start = if (withIcon) CHIP_ICON_START.roundToPx() + CHIP_ICON.roundToPx() + gap else textEdge.roundToPx()
                val end = if (withArrow) gap + CHIP_TRAILING_ICON.roundToPx() + CHIP_ARROW_END.roundToPx() else textEdge.roundToPx()
                return start + labelWanted + end
            }
            val room = if (constraints.hasBoundedWidth) constraints.maxWidth else Int.MAX_VALUE
            // The check of a checked chip stays: the chip is as wide as its checked look ([widestLook]).
            val keepIcon = iconPart != null && (labelPart == null || checkmark || width(true, arrowPart != null) <= room)
            val keepArrow = arrowPart != null
            val start = if (labelPart == null) 0 else if (keepIcon) CHIP_ICON_START.roundToPx() else textEdge.roundToPx()
            val end = if (labelPart == null) 0 else if (keepArrow) CHIP_ARROW_END.roundToPx() else textEdge.roundToPx()
            val loose = Constraints()
            val iconPlaced = if (keepIcon) iconPart?.measure(loose) else null
            val arrowPlaced = if (keepArrow) arrowPart?.measure(loose) else null
            val beside = start + end + (iconPlaced?.let { it.width + gap } ?: 0) + (arrowPlaced?.let { it.width + gap } ?: 0)
            val labelPlaced = labelPart?.measure(Constraints(maxWidth = (room - beside).coerceIn(0, labelWanted)))
            val inner = listOfNotNull(iconPlaced, labelPlaced, arrowPlaced)
            // A gap between each two parts only: an icon alone is centred.
            val used = start + end + inner.sumOf { it.width } + gap * (inner.size - 1).coerceAtLeast(0)
            val contentHeight = inner.maxOfOrNull { it.height } ?: 0
            val width = maxOf(constraints.minWidth, minOf(used, room))
            val height = maxOf(constraints.minHeight, contentHeight + vertical)
            layout(width, height) {
                var x = ((width - used) / 2).coerceAtLeast(0) + start
                for (placeable in inner) {
                    placeable.placeRelative(x, (height - placeable.height) / 2)
                    x += placeable.width + gap
                }
            }
        }
    }
}

/** A [PlezyChip]'s parts, in the order its layout places them. */
private enum class ChipPart { ICON, LABEL, ARROW }

/**
 * At least as wide as the wider of [label]'s two looks: set in [plain] with [plainBeside] px beside it (padding and
 * icons) and in [selected] with [selectedBeside] px, each on one line, cut short where the room left beside it ends. A
 * control whose label's look follows its selection keeps one width, its content centred while it is narrower.
 */
internal fun Modifier.widestLook(measurer: TextMeasurer, label: String, plain: TextStyle, plainBeside: Int, selected: TextStyle, selectedBeside: Int): Modifier =
    layout { measurable, constraints ->
        fun width(style: TextStyle, beside: Int): Int {
            val room = if (constraints.hasBoundedWidth) (constraints.maxWidth - beside).coerceAtLeast(0) else Constraints.Infinity
            val text = measurer.measure(label, style, TextOverflow.Ellipsis, maxLines = 1, constraints = Constraints(maxWidth = room), layoutDirection = layoutDirection, density = this)
            return beside + text.size.width
        }
        val least = maxOf(width(plain, plainBeside), width(selected, selectedBeside))
        val placeable = measurable.measure(constraints.copy(minWidth = least.coerceIn(constraints.minWidth, constraints.maxWidth)))
        layout(placeable.width, placeable.height) { placeable.place(0, 0) }
    }

/** The room (px) a dropdown [PlezyChip] of each of [labels] needs to show it whole with its arrow, and its leading [icon]. */
@Composable
fun dropdownChipWidths(labels: List<String>, icon: Boolean): List<Int> {
    val measurer = rememberTextMeasurer()
    val tv = LocalPlezyDimens.current.focusGrows
    val style = if (tv) MaterialTheme.typography.titleSmall else MaterialTheme.typography.labelLarge
    val density = LocalDensity.current
    return remember(labels, icon, tv, style, density) {
        with(density) {
            val start = if (icon) CHIP_ICON_START + CHIP_ICON + CHIP_ICON_GAP else if (tv) 18.dp else 14.dp
            val beside = (start + CHIP_ICON_GAP + CHIP_TRAILING_ICON + CHIP_ARROW_END).roundToPx()
            labels.map { measurer.measure(it, style, maxLines = 1).size.width + beside }
        }
    }
}

private val CHIP_ICON_START = 10.dp
/** A chip's leading icon, and the icon of a round button in a row of chips ([HeaderAction]), so the row draws one size. */
internal val CHIP_ICON = 18.dp
private val CHIP_ARROW_END = 8.dp
private val CHIP_TRAILING_ICON = 20.dp
private val CHIP_ICON_GAP = 6.dp
