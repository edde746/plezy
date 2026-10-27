# Motion & clarity

Motion & clarity gives PlezyNG playback its own controls for cadence, motion smoothing, and motion-compensated frame generation. Choose a preset for the kind of content you are watching, compare it live, and use Custom when you want direct control over the processing method and output rate.

## Open the controls

- **While watching:** open the player’s Video settings and select **Motion & clarity**. This keeps the movie running while you switch presets and use **Compare without motion processing**.
- **For saved defaults:** open **Settings → Playback → Video and display** and choose a preset. The same entry shows the selected preset and its short description.
- **Choose a preference scope:** set motion preferences for all playback, a library, or a title from the Motion & clarity scope selector.

The in-player comparison is a quick A/B: it temporarily bypasses the active motion filter while keeping display synchronization, scaling, and audio settings in place. Choose **Return to motion processing** to restore the selected processing. The comparison does not change the saved preference.

## Choose a preset

| Preset | What it does |
| --- | --- |
| **Original** | Preserves source cadence and restores the player options captured before motion processing. Use it to turn processing off. |
| **Cinema** | Uses the sharpest, lightest temporal blend for restrained smoothing. |
| **Balanced** | Applies moderate temporal blending for smoother motion with controlled softness. |
| **Smooth** | Uses stronger temporal blending for a smoother presentation. |
| **Animation** | Uses a sharper temporal filter for drawn edges and graphic motion. |
| **Sports** | Uses a smoother temporal filter for fast movement; sources whose high frame rate already matches playback keep their native cadence. |
| **OLED** | Generates motion-compensated frames toward the renderer-reported display cadence to reduce sample-and-hold blur. |
| **Custom** | Opens manual method, temporal-filter, threshold, search-effort, and generated-rate controls. |

Cinema, Balanced, Smooth, Animation, and Sports use mpv temporal blending. OLED selects motion compensation at the current renderer-reported display cadence. Custom lets you choose between temporal blending and motion-compensated frames, then tune the relevant controls.

## Tune Custom

### Temporal blending

Temporal blending combines adjacent frames around the display clock to smooth cadence differences. Choose a temporal filter to favor edge sharpness or softer blending:

- **Oversample:** sharpest, least blending.
- **Linear:** light blending.
- **Catmull–Rom:** sharper blend with possible ringing.
- **Mitchell:** balanced softness.
- **Gaussian:** smoother blend with softer edges.
- **Bicubic:** smoothest and softest blend.

The **Interpolation threshold** controls how much refresh-rate difference is ignored before interpolation is used. Values range from 0% to 10%; zero means always interpolate. Cinema and the other named temporal presets select their own filters automatically.

### Motion-compensated frames

Motion compensation uses FFmpeg motion search to create in-between frames. Choose:

- **Generated frame-rate target:** Match current display, or select 48, 50, 60, 72, 90, 100, 120, or 144 fps. This is the primary smoothness control. Lower targets retain more of the source cadence; higher targets create smoother, more video-like motion.
- **Motion search effort:** Fast, Balanced, or High. Higher effort spends more processing on block matching and edge refinement; it changes search cost and matching detail, not the generated-rate target.

When the player repeatedly reports late frames or dropped frames, it can lower the active search effort from High to Balanced to Fast. If timing reports continue at Fast, playback returns to temporal blending. The saved quality selection remains unchanged; select the preset again to restore it and retry.

On Android mpv, PlezyNG can request the selected generated rate when opening playback. The Android display system chooses whether to apply the requested mode. The in-player status shows the renderer-reported display rate and generated target when available.

## Picture and sound

Motion & clarity works alongside existing picture controls. Spatial upscaling remains in **Shader presets**; the motion filter does not replace or overwrite the selected scaler. The A/B comparison keeps scaling in place, so you can compare motion processing without changing spatial picture settings.

With audio passthrough, the player uses a different synchronization mode to preserve encoded audio. If motion cadence looks uneven, try decoded audio and compare again. The in-player status explains when passthrough is active.

The status panel can show the renderer-reported display rate, the container-reported nominal source rate, generated-rate target, active engine, selected search effort, and any restart or fallback state. A container-reported rate is nominal metadata; variable-frame-rate timing can differ.

## Finding your preferred look

- If motion looks too smooth, choose a lower generated-rate target or switch to Cinema or Original.
- If moving edges look softer than you prefer, try a sharper temporal filter or a lower temporal blend preset.
- If motion-compensated frames are not keeping up, use a lower search-effort tier or a lower generated-rate target.
- If a change requests a playback restart to reserve decoder frames, use the status message and restart when convenient.
- For a clean TV comparison, turn off the TV’s motion interpolation while comparing the PlezyNG presets.

## Playback support

Motion & clarity uses mpv’s GPU renderer and labelled video-filter path. Android ExoPlayer and native TV media routes do not expose the same processing controls. The feature entry remains visible in Playback Settings where useful, and playback status identifies when the current route cannot apply a selected method.
