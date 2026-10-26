# Interaction and visual specification

All behavior below is proposed. App-owned floating PiP and split view are the primary cross-platform experience. Keep existing single-session playback as the default until the user opens a companion. Introduce the feature through content actions and the existing transport area, not a new navigation destination.

## Vocabulary and entry points

| Label | Meaning | Entry point |
|---|---|---|
| Open alongside | Add this item without replacing the active one | Existing media context menu, detail overflow, reader/file menu, supported game menu |
| Add another | Browse for content while keeping current sessions | Layout menu and workspace tray |
| Layout | Choose Single, Side by side, Above and below, or Float | Existing player/reader header or overflow; visible labeled control when Multiview is active |
| Float in Plezy | Keep a pane above the current Plezy content | Layout menu |
| Picture in picture | Continue eligible video outside Plezy | Retain existing video PiP action; short secondary explanation differentiates it from Float |
| Pop out | Move a pane into its own application window | Qualified desktop layout menu |
| Swap | Exchange the main and selected companion placements | Companion header, layout menu, shortcut |
| Make main | Promote a selected session when more than two are open | Session menu/tray |
| Listen to this | Make this the audible session | Speaker control and session menu |
| Mix audio | Opt in to two audible decoded streams | Audio panel when supported |
| Keep open for quick switching | Pause/release expensive resources while retaining place | Session menu; constrained-device alternative |
| Return to main window | Dock a detached pane | Detached window header/system menu |
| Close | Stop/flush/remove this session | Pane header and session menu; games use Disconnect wording |

Existing Play and Read preserve replacement semantics. Never change a familiar single tap into an implicit multi-session launch. When two sessions are already visible, Open alongside first offers a free slot or a clear replacement/park choice. A failed add leaves the current layout and playback intact.

Use existing `AppIcon` and Material Symbols conventions. Suggested semantic icons: split view, picture-in-picture, open-in-new, swap, speaker/mute, close. Verify the installed icon package names during implementation. Do not invent icon-only meanings or use the same undifferentiated PiP glyph for in-app and system modes without labels/tooltips.

## Main journeys

### Continue a film while reading

1. In the film controls, choose **Layout → Add another**. The film becomes an in-app companion while the existing browser opens, with a compact instruction: “Choose something to open alongside.” A visible Cancel restores the previous layout.
2. Browse Books, Files, or Comics normally. Selection uses the existing resolver, download, source authentication and resume behavior. Do not force all libraries into a new combined picker.
3. The publication opens beside the film when both satisfy their minimum readable dimensions. On a narrow screen it becomes main, with the film floating above it. The film remains the audio owner.
4. The new companion exposes **Swap**, **Listen to this** if relevant, and its menu. No hidden gesture is required.
5. Closing the reader flushes the locator and returns the film to its prior presentation. Closing the film leaves the reader where it is.

Direct **Open alongside** from an item menu skips the Add another browsing step. With no current session, it opens normally and briefly explains how to add another; it does not create an empty split.

### Read while listening

Reuse the current `MusicPlaybackService`, queue, artwork, lyrics, mini-player, sleep timer and `MusicVisualizer`. The companion can show **Artwork / Lyrics / Visualizer** using the existing now-playing choices. Choosing visualization is a presentation change, not a second audio player. When no loudness analysis exists, retain the current non-analyzed behavior; do not label a decorative animation a live spectrum.

TTS/read-along explicitly requests narration audio ownership. Default: pause other narrative audio, duck or pause music according to the chosen setting, and offer a visible way to restore it. A page turn does not stop background music. Audiobook plus publication is independent unless the existing edition has actual alignment data; then expose its existing read-along control.

### Play a game with a companion

Only show a live game pane for an engine that supports embedding, resize and input release. Opening media beside an activity-only game offers preserved switching until that engine is upgraded.

A qualified game starts main; the media companion starts muted if another session owns audio. The user selects the audible source explicitly. Physical controller input stays assigned to the game until they invoke workspace controls. Once workspace controls open, send a complete neutral input state before accepting navigation keys. The selected pane's focus border is distinct from the game-input badge and audible badge.

**Swap** changes prominence, not host process state. If the game engine supports only foreground input, making it a companion releases input. Show “Controls released — game still running” where applicable. Never claim the remote game paused without a supported, acknowledged pause operation. Disconnect and Quit host game remain separate actions; closing the game pane defaults to disconnect, with host behavior described.

Touch controls are clipped and scaled to the game viewport and its safe areas. Drag handles and workspace actions never overlap active sticks/triggers. Reader pinches and panel resize gestures do not enter the game. Rejoining game input requires an explicit activation action; merely hovering a pane is insufficient.

### Swap and resume

For two panes, Swap exchanges placements atomically and retains both content states. It does **not** swap audio by default. A setting **Follow the main view with audio** may opt into that behavior; display the changed speaker badge immediately. For three/four panes, Make main promotes the selected pane and puts the previous main in that pane's slot; it never permutes unrelated panes.

The session tray remembers parked items with title, artwork or content-type fallback and saved position. Parked labels distinguish Paused, Ready to reopen, and Game disconnected. No animated “live” image is used for a suspended session. Opening a parked item can require source reconnection; show this locally in the pane.

## Layout rules

The following are proposed initial layout defaults, not measured device limits. Use viewport constraints, text scaling and adapter minima rather than device-name checks.

| Available space | Default | Expansion |
|---|---|---|
| Narrow phone/portrait window | One main + one floating companion, or Above and below if each pane remains usable | Two visible panes maximum initially; additional items parked |
| Tablet/foldable/medium desktop | Side by side, initially equal widths; remember user ratio | Two visible panes by default |
| Large desktop/tablet window | Two panes; optional main + two companions or four equal regions | Up to four visible panes after resource admission; no automatic fourth decoder |
| TV | Main + fixed-corner companion or 70/30 side by side | Two visible panes initially; remote-selectable size/position presets |
| Detached window | One interactive session | One window per session, maximum included in global workspace budget |

Initial minimum usable content width: reader 320 logical pixels; general video 240; game 360 or the engine/controls' larger minimum. Initial interactive video height: 135; reader height: 240. These are layout candidates to validate at text scale 1.0–2.0, not reasons to clip controls. Large text, captions, keyboard, touch overlay or minimum native plane sizes can require larger bounds. If minima do not fit, switch to a visible, explained single/parked arrangement. Never shrink body text to make a layout fit.

On dual-screen/foldable devices, avoid hinge and cutout bounds; use one pane per safe region when possible. A resize preserves the reading anchor and zoom intent: reflow EPUB around its logical locator; preserve PDF/comic page and normalized focal point. UI RTL mirrors layout placement and start/end controls, while manga reading direction and media timeline direction retain their own established rules.

Floating panels snap to safe corner/edge locations; remember normalized position within the usable viewport. The drag handle moves the panel, its resize handle changes the panel, and gestures on content retain content meaning. Offer explicit Move and Size menus for every gesture operation. Page controls, subtitle safe regions, keyboard/IME, navigation, game controls and accessibility overlays are keep-clear inputs. Move only when a new obstruction requires it; do not make a panel chase the pointer or focused text continuously.

Use a clearly reachable collapsed tab only after an explicit tuck action. Do not require an offscreen swipe to recover a panel. On viewport shrink or display removal, bring every title/restore control into a reachable area.

## Chrome and theme

Reuse `tokens(context)` and existing theme extensions for every surface. Audited defaults: radius 8/12/20 with 5 for grouped inner corners, spacing 12, group gap 2, durations 120/200/300/350 ms. Dark palette is background `#0E0F12`, surface `#15171C`, text `#EDEDED`; these values inform the wireframe only. Production reads tokens and supports Light, OLED, presets and custom themes.

Use a slim pane header with title, input/focus status where needed, speaker state, Swap/Make main, and overflow. The title truncates visually with full accessible text and a tooltip on pointer devices. Controls remain visible when focused, on first use, when paused, or during a recoverable error. Otherwise use the existing player chrome visibility policy. Reader controls follow reader behavior, not timed video hiding.

Use `MonoMotion` and current focus chrome; reduced motion/performance tiers use immediate placement and a stable focus outline. Avoid bouncing panels, decorative gradients, independent panel themes, tiny toolbars, and new floating menus with different shapes. Native OS PiP chrome is owned by the OS and need not imitate Flutter.

The existing mini-player remains unchanged in the ordinary one-music-session case. With Multiview active, extend its inset/transport area into a compact **Open media** tray: ordered session chips with artwork, title and state; selecting a chip promotes/restores that session. Do not render a second mini-player for the same music session. Browsing controls and drawer focus retain their existing positions.

## Audio and control semantics

| Operation | Audio result | Input result |
|---|---|---|
| Focus/click a pane | Unchanged | Local pointer/keyboard focus changes; game capture requires explicit activation |
| Swap / Make main | Unchanged by default | Focus moves to promoted pane header, never sends a held key to content |
| Listen to this | Prior audio owner muted/paused by documented content policy | No change to game capture or visual layout |
| Mix audio | Two explicitly selected sessions, separate gain controls, supported decoded output only | No change |
| Minimize/hide an ordinary pane | Visible state becomes parked; video pauses unless user chose background audio | Release pane capture |
| Background the app | Selected native PiP or allowed background audio continues; others checkpoint/pause | All game and pointer capture released |
| Close audible pane | Flush/stop it; select next owner only if it was already playing and policy permits | Restore focus to nearest surviving header/tray |

New accompanying video starts muted with a persistent visible mute indicator; an audiobook starts paused until the user chooses to listen, to avoid advancing unheard narration. Mixing uses no automatic surprise volume changes. Surface the decoded-audio requirement before leaving passthrough/exclusive output; keep exclusive playback if the user cancels. Remember mix choices per workspace/device only, not globally across unrelated profiles.

Hardware media keys and OS now-playing controls address the declared transport owner, normally the audible session. If all media is muted, retain the last valid transport owner until explicitly changed. In tvOS native dual-PiP paths, adapt to the platform's multiple Now Playing sessions while preserving these app-level semantics. The audio panel labels “Media buttons control …” when it differs from the focused pane.

## Keyboard, touch, remote and accessibility

Register commands in the existing shortcut system, checking collisions in MV01. Initial candidate bindings: next/previous pane Ctrl+Tab / Ctrl+Shift+Tab (Cmd equivalents only where appropriate); Swap Ctrl+Shift+S; layout menu Ctrl+Shift+M. Treat these as candidates until collision review; make them discoverable and rebindable. Do not intercept reader/editor selection shortcuts, IME composition, browser text entry, or captured game input. Escape uses the existing back handler: close menu, leave move/resize mode, release capture, exit pane-fullscreen, then navigate. Never close all sessions on the first Back.

On TV, Layout is reachable in the existing action bar. A focused pane header opens pane actions with Select; **Change pane** explicitly moves between pane headers. Direction keys inside reader/game/video content stay with that content. Move mode offers corner presets or controlled D-pad movement, with Select to apply and Back to cancel. Reuse `FocusableActionBar`, focus memory and covered-route boundaries. System Home/Guide buttons retain system ownership.

On touch, tap reveals video chrome, header drag moves floating panels, content pinch zooms readers, and resize handles resize panels. Long press is optional context-menu access, never the only access. Primary touch hit targets meet at least 48 logical pixels where the platform contract permits; native system controls follow system metrics.

Each pane is an accessible region named with content title/type and status. Distinguish “Main view”, “Audio on”, “Controls here”, and “Paused for quick switching” in text/semantics, not color alone. Provide named actions for move, size, promote, swap, audio, park and close. Announce completed layout changes once; do not announce every video frame, progress tick, or pointer move. Focused reading content retains its semantic reading position when its pane moves.

Test screen readers, Switch Control, keyboard-only operation, D-pad and controller. Respect reduced motion, text scaling, high contrast, platform focus preferences, captions and audio description. New strings use `slang` keys with placeholders/plurals and translator context; test pseudo-localization, CJK, Arabic/Hebrew RTL and mixed-script titles. Do not concatenate English ordinal labels or infer reading direction from UI locale.

## Hints, help and failure copy

The first eligible use displays a short anchored hint at Layout: “Keep two things open. Choose Open alongside.” Dismissal persists per profile; Settings → Playback → Multiview contains **Show tips again** and a concise illustrated help sheet. The help sheet distinguishes the four window modes and exposes the same actions, not a tutorial-only gesture.

| Situation | User-facing copy/action intent |
|---|---|
| Decoder budget exhausted | “This device can play one video at a time. Keep this open for quick switching?” with Keep open / Replace current / Cancel |
| Native PiP unavailable for a book | Offer Float in Plezy or Pop out where supported; explain “Interactive reading stays inside Plezy on this device.” |
| Android TV system PiP requested | Explain “Use a floating view inside Plezy on this TV.” Offer it directly |
| Reader lacks a TV renderer | “This reader is not available on this device yet.” Keep video running; offer another item |
| Game engine is activity-only | “This game currently opens full screen. Keep your other media ready to return to?” |
| Mixing conflicts with passthrough | “Mixing needs decoded audio.” Show current output, proposed compatible output, Continue / Keep current |
| Pair cannot overlap native planes | “Use side by side for these views.” Preserve sessions and offer the valid arrangement |
| Pop-out/window transfer fails | Restore original pane, keep playback, and show a local Retry action |
| Source removed/loan expired | Preserve bookmark; stop unavailable playback and offer reconnect/renew in the existing source flow |
| Lost game connection | Show Reconnect / Disconnect; release all input; do not freeze the rest of the workspace |

Copy above is a functional English source draft. Localize and fit it using existing app tone and QA. Avoid technical backend names in normal controls; diagnostic detail belongs in the existing troubleshooting surface.

## Settings

Use the existing Playback settings group for Multiview: default layout (Automatic initially), keep playing while browsing, background-audio choice, follow-main audio (off), allow audio mixing (off), caption keep-clear (on), remember layout (on), restore previous workspace (Ask initially), device resource mode (Automatic), and show tips/help. Advanced settings may expose a lower visible-pane limit, animation/visualizer quality and diagnostic capability details. They must never force unsupported decoder counts or unlock unimplemented backends.

Restoring a workspace never auto-launches a host game, renews a loan, starts downloads, pairs a host, or resumes several audible streams. Offer **Restore layout** with sessions paused; resuming a particular item remains explicit.
