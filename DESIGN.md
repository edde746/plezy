---
version: alpha
name: Plezy
description: Artwork-led media browsing with quiet monochrome controls.
colors:
  background: "#0E0F12"
  surface: "#15171C"
  text: "#EDEDED"
  error: "#B00020"
typography:
  sans:
    fontFamily: "system-ui, sans-serif"
rounded:
  card: "14px"
omitted:
  - section: spacing
    reason: Existing Flutter runtime geometry is canonical.
components:
  media-card: {}
  selection-bar: {}
---

# Plezy design context

## Overview

Preserve Plezy's existing visual identity across desktop, mobile, and TV.
Artwork carries expression; selection controls serve the task quietly.

## Colors

`lib/theme/mono_theme.dart` owns palettes; `MonoTokens` adapts the selected
palette for shared widgets. Selection uses existing theme colors and icons.

## Typography

Use the platform typography selected by `monoTheme`. Slang owns UI copy,
with English as its configured fallback for untranslated new keys.

## Layout

Keep library pagination and scroll ownership unchanged. A stable action row
below the library content exposes selection without overlaying media cards.

## Elevation & Depth

Reuse `AppMenuButton` and the shared confirmation dialog surfaces.

## Shapes

Keep existing card and control geometry. Selection indicators use circles.

## Components

`MediaCard` owns selection decoration and checkbox semantics;
`FocusableMediaCard` forwards pointer, keyboard, and D-pad actions.
`LibrarySelectionBar` owns count, cancellation, and the adaptive actions menu.

## Do's and Don'ts

- Use shared menus, icons, theme tokens, dialogs, and snackbars.
- Keep selected items recognizable in both grid and list views.
- Do not restyle the library for selection or obscure focus decoration.

## Reading, sources and accessibility

File sources and public libraries extend the existing grouped rows, quiet actions and artwork-led shelves. Use official unmodified provider marks only at their connection/sign-in/service affordances; provenance and attribution live in `assets/provider_marks`. EPUB/CBZ controls use the active palette and low-emphasis controls; PDF uses the same reader shell. Zoom, fit and layout are ordinary reader actions, not a separate technical panel.

App accessibility preferences live in Appearance and compose with system settings. High contrast retains Mono geometry, font sizing reflows, and reduced motion keeps visible focus while removing decorative movement. Shared controls keep labelled keyboard/screen-reader actions and adequate touch targets. Do not replace a semantic control with an unlabelled custom gesture.
