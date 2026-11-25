package com.edde746.plezy.ui.metadata

import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.components.ArtworkPlaceholder
import com.edde746.plezy.presentation.browse.PlaceholderKind
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.input.TextFieldLineLimits
import androidx.compose.foundation.text.input.TextFieldState
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.Icon
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.presentation.metadata.ArtworkPickerStore
import com.edde746.plezy.presentation.metadata.EditFieldUi
import com.edde746.plezy.presentation.metadata.EditorDialog
import com.edde746.plezy.presentation.metadata.EditorLoad
import com.edde746.plezy.presentation.metadata.MetadataEditStore
import com.edde746.plezy.presentation.metadata.PlexMatchStore
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.app.LocalPlezyPlatform
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.Chevron
import com.edde746.plezy.ui.components.GroupRow
import com.edde746.plezy.ui.components.LoadingState
import com.edde746.plezy.ui.components.ModalOverlay
import com.edde746.plezy.ui.components.OverlayActions
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.RowGroup
import com.edde746.plezy.ui.components.ScreenHeader
import com.edde746.plezy.ui.components.SystemBackHandler
import com.edde746.plezy.ui.components.TextFieldDialog
import com.edde746.plezy.ui.components.contentColumn
import com.edde746.plezy.ui.components.groupShape
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.focus.rememberKeyboardOnSelect
import com.edde746.plezy.ui.focus.remoteLeavesField
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.image.RemoteImage
import com.edde746.plezy.ui.probe.layoutProbe

/**
 * The metadata editor ([MetadataEditStore]): Save in the header (a spinner while a commit runs), the sections as
 * groups of tiles, each opening its dialog. Back waits while a commit runs. Harness names `metadata.edit.<save|section.ID>`,
 * `metadata.field.<id>`.
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
internal fun MetadataEditScreen(app: AppSession, route: Route.MetadataEdit) {
    val store = remember(route) { app.metadata.editor(route) } ?: return
    val state by store.state.collectAsState()
    val memory = rememberFocusMemory()
    RestoreFocus(memory, ready = state.load == EditorLoad.READY, fallback = state.sections.firstOrNull()?.fields?.firstOrNull()?.id)
    SystemBackHandler(enabled = state.committing) {}
    Column(Modifier.fillMaxSize()) {
        val list = rememberLazyListState()
        ScreenHeader(
            state.title,
            Modifier.contentColumn().layoutProbe("metadata.edit.header", reportsFocus = false),
            onBack = { if (!state.committing) app.navigator.back() },
            actions = {
                if (state.committing) {
                    LoadingIndicator(Modifier.size(24.dp).layoutProbe("metadata.edit.saving", reportsFocus = false))
                } else {
                    PlezyIconButton(PlezyIcons.Check, state.saveLabel, store::save, Modifier.layoutProbe("metadata.edit.save"), enabled = state.canSave)
                }
            },
            scrolled = { list.canScrollBackward },
        )
        when (state.load) {
            EditorLoad.LOADING -> LoadingState(Modifier.fillMaxSize())
            EditorLoad.FAILED -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text(state.failedText, Modifier.layoutProbe("metadata.edit.failed", reportsFocus = false), textAlign = TextAlign.Center)
            }
            EditorLoad.READY -> LazyColumn(
                Modifier.fillMaxSize().contentColumn(),
                state = list,
                contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                itemsIndexed(state.sections, key = { _, section -> section.id }) { _, section ->
                    Column(Modifier.layoutProbe("metadata.edit.section.${section.id}", reportsFocus = false)) {
                        Text(
                            section.title,
                            Modifier.padding(16.dp),
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                        )
                        RowGroup {
                            section.fields.forEachIndexed { index, field ->
                                FieldTile(field, index, section.fields.size, !state.committing, Modifier.rememberFocus(memory, field.id)) { store.edit(field.id) }
                            }
                        }
                    }
                }
            }
        }
    }
    state.dialog?.let { EditorDialogHost(app, store, it) }
}

@Composable
private fun FieldTile(field: EditFieldUi, index: Int, count: Int, enabled: Boolean, focus: Modifier, onClick: () -> Unit) {
    val modifier = focus.layoutProbe("metadata.field.${field.id}")
    val artwork = field.artwork
    if (artwork == null) {
        GroupRow(
            title = field.label,
            onClick = onClick,
            modifier = modifier,
            shape = groupShape(index, count),
            subtitle = field.value ?: field.notSetLabel,
            enabled = enabled,
            trailing = { Chevron() },
        )
        return
    }
    PlezySurface(onClick, modifier.fillMaxWidth(), shape = groupShape(index, count), enabled = enabled, grows = false) {
        Row(
            Modifier.heightIn(min = 56.dp).padding(horizontal = 16.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            RemoteImage(
                artwork.imageUrl,
                contentDescription = null,
                modifier = Modifier.size(artwork.width.dp, artwork.height.dp).clip(RoundedCornerShape(4.dp)),
                contentScale = if (artwork.contain) ContentScale.Fit else ContentScale.Crop,
            )
            Text(field.label, Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.Medium))
            Chevron()
        }
    }
}

@Composable
private fun EditorDialogHost(app: AppSession, store: MetadataEditStore, dialog: EditorDialog) {
    when (dialog) {
        is EditorDialog.Text -> TextFieldDialog(
            dialog.title,
            remember(dialog) { TextFieldState(dialog.value) },
            onSubmit = store::submitText,
            onCancel = store::dismissDialog,
            probe = "metadata.text",
            label = dialog.title,
            multiline = dialog.multiline,
            submitLabel = dialog.saveLabel,
            cancelLabel = dialog.cancelLabel,
        )
        is EditorDialog.Date -> DateDialog(dialog, store::submitDate, store::dismissDialog)
        is EditorDialog.Tags -> TagEditDialog(dialog.store, store::submitTags, store::dismissDialog)
        is EditorDialog.Choice -> ChoiceDialog(dialog, store::choose, store::dismissDialog)
        is EditorDialog.Artwork -> ArtworkPickerDialog(app, dialog.store, store::dismissDialog)
    }
}

/**
 * An artwork field's picker ([ArtworkPickerStore]): the candidates in a 400 dp high grid, each tile marked when it is
 * the current one; From URL, Upload File (where the platform has file dialogs) and Cancel, which has focus first.
 * While one applies a spinner shows and nothing else takes a press. Harness names `metadata.artwork.<tile.N|url|upload|cancel>`.
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun ArtworkPickerDialog(app: AppSession, store: ArtworkPickerStore, onDismiss: () -> Unit) {
    val state by store.state.collectAsState()
    val platform = LocalPlezyPlatform.current
    val cancel = remember { FocusRequester() }
    var fromUrl by remember { mutableStateOf(false) }
    ModalOverlay(title = state.title, onDismiss = onDismiss, initialFocus = cancel) {
        Box(Modifier.fillMaxWidth().height(400.dp), contentAlignment = Alignment.Center) {
            when {
                state.loading -> LoadingIndicator(Modifier.size(40.dp))
                state.tiles.isEmpty() -> Text(state.emptyText, Modifier.layoutProbe("metadata.artwork.empty", reportsFocus = false))
                else -> LazyVerticalGrid(
                    GridCells.Fixed(state.columns),
                    Modifier.fillMaxSize(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    itemsIndexed(state.tiles) { index, tile ->
                        PlezySurface(
                            { store.select(index) },
                            Modifier.aspectRatio(state.aspectRatio.toFloat()).semantics { contentDescription = tile.label }.layoutProbe("metadata.artwork.tile.$index"),
                            shape = RoundedCornerShape(8.dp),
                            enabled = !state.applying,
                            grows = false,
                        ) {
                            RemoteImage(
                                tile.imageUrl,
                                contentDescription = null,
                                modifier = Modifier.fillMaxSize().clip(RoundedCornerShape(8.dp)),
                                contentScale = if (state.contain) ContentScale.Fit else ContentScale.Crop,
                            )
                            if (tile.selected) {
                                Box(
                                    Modifier.align(Alignment.BottomEnd).padding(6.dp).background(MaterialTheme.colorScheme.primary, CircleShape).padding(4.dp),
                                ) {
                                    Icon(PlezyIcons.Check, contentDescription = null, Modifier.size(16.dp), tint = MaterialTheme.colorScheme.onPrimary)
                                }
                            }
                        }
                    }
                }
            }
        }
        OverlayActions {
            if (state.applying) LoadingIndicator(Modifier.size(24.dp).layoutProbe("metadata.artwork.applying", reportsFocus = false))
            PlezyButton(state.fromUrlLabel, { fromUrl = true }, Modifier.layoutProbe("metadata.artwork.url"), style = ButtonStyle.TEXT, enabled = !state.applying)
            if (platform.hasFileDialogs) {
                PlezyButton(
                    state.uploadLabel,
                    { platform.openImage({ name, bytes -> store.upload(bytes, name) }, { app.notify(T.metadataEdit.artworkUpdateFailed) }) },
                    Modifier.layoutProbe("metadata.artwork.upload"),
                    style = ButtonStyle.TEXT,
                    enabled = !state.applying,
                )
            }
            PlezyButton(state.cancelLabel, onDismiss, Modifier.focusRequester(cancel).layoutProbe("metadata.artwork.cancel"), style = ButtonStyle.TEXT, enabled = !state.applying)
        }
    }
    if (fromUrl) {
        TextFieldDialog(
            state.fromUrlLabel,
            remember { TextFieldState() },
            onSubmit = {
                fromUrl = false
                store.applyUrl(it)
            },
            onCancel = { fromUrl = false },
            probe = "metadata.text",
            label = state.fromUrlLabel,
            hint = state.imageUrlHint,
            cancelLabel = state.cancelLabel,
        )
    }
}

/**
 * Plex's match search ([PlexMatchStore]): the name and year fields (Enter in the name moves to the year, Enter in the
 * year searches), Search, then the candidates or "No matches found". Harness names
 * `metadata.match.<name|year|search|result.N>`.
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
internal fun PlexMatchScreen(app: AppSession, route: Route.PlexMatch) {
    val store = remember(route) { app.metadata.match(route) } ?: return
    val state by store.state.collectAsState()
    val memory = rememberFocusMemory()
    // The name field takes focus first where keys move it (a TV, a keyboard); a touch screen starts with none.
    RestoreFocus(memory, ready = true, fallback = "name")
    val keyboard = rememberKeyboardOnSelect()
    val nameFocus = remember { FocusRequester() }
    val yearFocus = remember { FocusRequester() }
    val name = remember { TextFieldState(state.name) }
    val year = remember { TextFieldState(state.year) }
    LaunchedEffect(name) { snapshotFlow { name.text.toString() }.collect(store::setName) }
    LaunchedEffect(year) { snapshotFlow { year.text.toString() }.collect(store::setYear) }
    Column(Modifier.fillMaxSize()) {
        val list = rememberLazyListState()
        ScreenHeader(state.title, Modifier.contentColumn().layoutProbe("metadata.match.header", reportsFocus = false), onBack = { app.navigator.back() }, scrolled = { list.canScrollBackward })
        Column(Modifier.contentColumn().padding(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 8.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
                OutlinedTextField(
                    state = name,
                    placeholder = { Text(state.titleHint) },
                    leadingIcon = { Icon(PlezyIcons.Search, contentDescription = null) },
                    lineLimits = TextFieldLineLimits.SingleLine,
                    readOnly = keyboard.readOnly,
                    shape = CircleShape,
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next),
                    onKeyboardAction = { yearFocus.requestFocus() },
                    modifier = Modifier.weight(1f).rememberFocus(memory, "name").focusRequester(nameFocus).then(keyboard.modifier)
                        .onPreviewKeyEvent { event ->
                            if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
                            when (event.key) {
                                Key.Enter, Key.NumPadEnter -> yearFocus.requestFocus().let { true }
                                else -> false
                            }
                        }
                        .remoteLeavesField(name).layoutProbe("metadata.match.name"),
                )
                OutlinedTextField(
                    state = year,
                    placeholder = { Text(state.yearHint) },
                    lineLimits = TextFieldLineLimits.SingleLine,
                    readOnly = keyboard.readOnly,
                    shape = CircleShape,
                    inputTransformation = { if (!asCharSequence().all(Char::isDigit) || length > 4) revertAllChanges() },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number, imeAction = ImeAction.Search),
                    onKeyboardAction = { store.search() },
                    modifier = Modifier.width(140.dp).focusRequester(yearFocus).then(keyboard.modifier)
                        .onPreviewKeyEvent { event ->
                            if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
                            when (event.key) {
                                Key.Enter, Key.NumPadEnter -> store.search().let { true }
                                else -> false
                            }
                        }
                        .remoteLeavesField(year).layoutProbe("metadata.match.year"),
                )
            }
            PlezyButton(
                state.searchLabel,
                store::search,
                Modifier.layoutProbe("metadata.match.search"),
                style = ButtonStyle.PRIMARY,
                icon = PlezyIcons.Search,
                enabled = !state.searching,
                fill = true,
            )
        }
        val results = state.results
        when {
            state.searching || results == null -> LoadingState(Modifier.fillMaxSize())
            results.isEmpty() -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text(state.noMatchesText, Modifier.layoutProbe("metadata.match.empty", reportsFocus = false), style = MaterialTheme.typography.bodyLarge, textAlign = TextAlign.Center)
            }
            else -> LazyColumn(
                Modifier.fillMaxSize().contentColumn(),
                state = list,
                contentPadding = androidx.compose.foundation.layout.PaddingValues(start = 8.dp, end = 8.dp, bottom = 24.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                itemsIndexed(results) { index, result ->
                    PlezySurface(
                        { store.apply(index) },
                        Modifier.fillMaxWidth().padding(horizontal = 4.dp).rememberFocus(memory, "result.$index").layoutProbe("metadata.match.result.$index"),
                        enabled = state.applyingGuid == null,
                        grows = false,
                    ) {
                        Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                            RemoteImage(
                                result.thumbUrl,
                                contentDescription = null,
                                modifier = Modifier.size(48.dp, 72.dp).clip(RoundedCornerShape(4.dp)),
                                blank = PlezyColors.SurfaceHigh,
                                error = { ArtworkPlaceholder(PlaceholderKind.MOVIE) },
                            )
                            Column(Modifier.weight(1f)) {
                                Text(result.title, style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.SemiBold))
                                result.summary?.let {
                                    Text(it, style = MaterialTheme.typography.bodySmall, maxLines = 2, overflow = TextOverflow.Ellipsis, color = PlezyColors.MutedContent)
                                }
                            }
                            when {
                                result.applying -> LoadingIndicator(Modifier.size(24.dp))
                                result.score != null -> Text(
                                    result.score!!,
                                    Modifier.background(MaterialTheme.colorScheme.secondaryContainer, CircleShape).padding(horizontal = 10.dp, vertical = 4.dp),
                                    color = MaterialTheme.colorScheme.onSecondaryContainer,
                                    fontWeight = FontWeight.SemiBold,
                                )
                                else -> Spacer(Modifier)
                            }
                        }
                    }
                }
            }
        }
    }
}
