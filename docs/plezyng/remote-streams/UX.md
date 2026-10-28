# User experience and design contract

This is the proposed product behavior. Confidence: high in the fit with the
inspected components; device usability requires the validation matrix.

## Navigation and ownership

Use **Settings → Connections → Add connection** as the canonical account entry.
Extend the current grouped connection picker with three labeled groups:
**Media servers**, **Cloud streaming**, and **Catalogs & add-ons**. Keep existing
Plex/Jellyfin/Emby choices and profile borrowing behavior. Cloud choices are
Real-Debrid, AllDebrid, Premiumize and TorBox. “Stremio” opens account import;
“Add-on link” installs a configured manifest. Additional qualified providers
join this group without acquiring their own navigation destinations.

**Settings → Services** may link to the same account detail routes under a
Streaming group. **Libraries → Files & books → Add source** may link to Cloud
streaming. These are shortcuts to the same state/flow, not separate stores or
duplicate account records. Respect the target profile passed by the caller.
When starting from a global picker, bind to the active unlocked profile; if
there is no profile yet, use the existing local-profile creation flow.

Cloud-only and add-on-only users must be able to start PlezyNG without signing
into a media server. Update first-run and empty-state routing so a working
source is not redirected back to Plex authentication.

| Existing surface | Added behavior |
| --- | --- |
| Home | Unified Continue Watching/Next Up; recently added cloud media; optional pinned catalog shelves using the current row organizer |
| Libraries | Cloud-account libraries in the existing quick picker; regular poster/grid view plus original Files view; one source badge |
| Explore | Installed catalog hubs and filters; stable add-on instance identity; existing provider selection extended for multiple installations |
| Search | One entry point with server, owned-cloud and enabled catalog results; progressive groups and duplicate-title folding |
| Detail / episode | Play or Resume, compact Sources action, selected-source summary, queue preparation in place |
| Find Next / swipe | Eligible title cards with source availability and existing directional actions; no transfers while swiping |
| Downloads | Shared presentation of “On this device” and “In your cloud”; provider preparation jobs are visibly different from local downloads |
| Player | Existing controls, tracks, captions, queue, picture settings, PiP and multiview; Sources lives in the existing version/quality sheet |
| Connection detail | Account status, library visibility, playback preference, transfer queue, refresh, reconnect and disconnect |

Do not rename all existing product terms to implement this feature. Reuse the
current settings, library and service labels wherever their meaning remains
correct. “Cloud streaming” is a useful group label; “resolver backend” is not
user-facing language.

## Sign in, then see media

### Provider device/QR journey

1. Choose a provider card with its official mark and one-line explanation.
2. Open the existing device-code dialog. On TV the QR and readable code are
   primary; on mobile/desktop the browser button is primary. Both remain
   available and accessible. Display the verified service hostname.
3. Provider approval completes asynchronously. Cancel stops polling and removes
   the pending session. Expiry changes the action to “Get a new code”; it does
   not bounce the user out of setup.
4. Validate the account and persist credentials and connection transactionally.
   A lost response or repeated callback cannot create duplicate accounts.
5. Close the dialog and show **Connected to Real-Debrid** in the current
   snackbar style. The new library is selected only when setup began from an
   empty library; otherwise preserve the user's current location.
6. Load the first inventory page and render cards immediately. Continue paging
   and metadata enrichment in bounded background work. Use the existing
   skeleton cards, not a blocking “scanning entire cloud” modal.

Default visibility: add the cloud library to the library picker and include
recognized titles in Search/Continue Watching. Add at most one recently-added
Home row per new account; do not insert empty rows or reorder existing rows.
Respect Home customization and profile restrictions.

An empty account shows **Your cloud is connected. Add a link or connect a
catalog to find something to watch.** Actions: **Add link**, **Add catalog**.
A successful connection with a failed inventory fetch shows **Connected. Your
files couldn't be loaded.** with **Retry**; it is not “No media found.”
A subscription/account limitation is a distinct account state with the
provider's account-page action. Credentials remain intact.

### Stremio account journey

Offer **Link with QR**, after live qualification, and **Sign in** where the
first-party login supports the account. Offer **Add an add-on link** alongside
these so account linking is never the only entrance.

After authentication, show one concise import sheet: installed add-ons, their
hosts, resource capabilities and current order. Existing identical
installations are labeled **Already added**. Known installed descriptors are
selected by default, but import happens on **Add selected**. Explain only
material details: **These add-ons receive the searches and titles you open.**
Flag a private/LAN endpoint or changed privilege on that specific row.

Import useful catalogs and configured streams even if one endpoint is offline.
The offline row remains available with Retry; invalid manifests are excluded
with a specific reason. The user can enter PlezyNG after the first usable
catalog arrives. Do not wait for every add-on before showing results.

Saved titles/resume import is a separate option after its schema is supported.
“Keep connected” controls retention of Stremio account authorization. Add-on
credentials in configured URLs remain encrypted in their own installations.
The default import leaves Stremio's own configuration and watch state intact.

### Manifest link and configuration journey

Accept paste, OS share/open, and a PlezyNG-owned deep link carrying an import
intent. Recognize a pasted `stremio://` transport URL without seizing the OS's
Stremio protocol association. The UI shows a safe hostname and add-on name,
never the token-bearing full URL. Preview the manifest before installation.

If configuration is required, launch the validated add-on configuration page
in the system browser. On return, accept its configured manifest through share,
paste or a validated callback. Standard add-ons do not promise a PlezyNG
callback; retain a paste path. Show exactly which host receives credentials if
the user elects to configure a remote add-on with a native account credential.
Never silently inject those credentials to make setup look automatic.

For TV input, prefer the provider's own QR flow. For a key or manifest available
on a phone, offer **Enter on my phone** only when an authenticated encrypted
companion transfer is available. Otherwise retain code/manual input and the
existing TV keyboard. A QR containing an API key is not an acceptable shortcut.

## Browsing and title identity

Poster cards, aspect ratios, information density, focus outlines, selection
animation, context menus and backdrop handling reuse the existing widgets.
Owned cloud files without a confident match appear under **Files**, with a
clean filename and a **Match title** action. They remain playable without
metadata. Never force an uncertain match merely to fill a polished grid.

Deduplicate within merged search/results and Continue Watching, not across
independently named catalog shelves. Keep provider provenance on detail and
source selection. A movie existing in Plex and a debrid cloud should have one
logical search result, with both copies in Sources. Editions and different
episode mappings remain separate choices.

Catalog-only metadata may appear in Explore without a Play guarantee. Detail
can say **Find a stream** while resolution is unknown. Do not add every
discoverable catalog title to Libraries: Libraries represents owned cloud
items, server libraries and the user's explicitly saved collection.

Search renders cached/local results first, then independent source groups.
Keep a stable selection while late responses arrive. Do not reorder focused
rows under the remote. A provider error displays a compact retry affordance
in that group, rather than replacing the whole result set.

## Play and choose a source

Primary action: **Resume** when there is compatible progress, otherwise
**Play**. Adjacent secondary action: **Sources**, with a count only after a
bounded query has returned. The selected source appears as a small secondary
line, for example **Living Room Plex · 4K** or **Real-Debrid · 1080p**.

Opening Sources uses the existing adaptive sheet/menu language. Show grouped
choices in this order: **On this device**, **Your servers**, **Cloud & streams**.
Each row has a short service label, resolution, meaningful language/audio/HDR
facts when known, and an availability label. File size and full release name
belong behind **Details**, not in the primary row. Include **Automatic** as
the default and a remember choice scoped to the show/edition. Preserve a
configured aggregator's order unless the user explicitly changes ranking.

| State | Compact copy | Action |
| --- | --- | --- |
| Known playable | Ready to play | Play |
| Availability unknown | Check on play | Play, with resolution progress |
| Provider preparation needed | Prepare in your cloud | Prepare & play |
| Job active | Preparing… / percentage when reliable | Keep browsing, Cancel |
| Auth expired | Reconnect to continue | Reconnect |
| Quota/slot exhausted | Cloud limit reached | Manage account / Retry when eligible |
| Unsupported local transport | Needs a connected streaming service | Connect service |
| Failed candidate | This source isn't available | Try another source |
| External-only stream | Open in browser | Open, with external indicator |

The source list does not perform speculative unlocks, torrent submissions,
heavy byte probes or bandwidth tests. Read-only observations are allowed with
budgets. Do not call “cached” ready unless the account can actually resolve the
intended file. Unknown quality is displayed as unknown, not promoted to 4K.

### Automatic policy

Respect an explicit user choice first, then a valid remembered show/edition
choice. Otherwise prefer a compatible downloaded copy, preferred/available
server copies, ready cloud choices, and unknown choices in deterministic
configured order. Readiness and device compatibility dominate a slightly higher
resolution. Use the existing quality, subtitle and language preferences.

Exclude disabled accounts, profile-hidden sources, unsupported codecs/DRM,
unapproved transport changes and provider limits. A stream's “Dolby Vision”
label routes into existing capability checks; it does not enable an experimental
engine, change picture settings, or promise output compatibility.

For Play resolving to an uncached transfer, the default asks once per account:
**Prepare this in your cloud?** Show target provider, file/episode and known
size. Choices: **Prepare & play**, **Choose another**; optional **Allow future
preparation on this account**. With that preference enabled, a subsequent Play
can prepare directly and show immediate progress. Browsing and Next Up preview
never acquire this permission by implication.

Automatic startup fallback attempts at most two different eligible sources.
Honor explicit source locks; show one concise failure action after the budget.
During playback, renew the same source first. Switching copies preserves
position only for a verified compatible timeline/edition; otherwise ask the
user and do not pretend timestamp parity.

## Queue, episodes and downloads

A preparation job appears in the title's action area and the cloud section of
Downloads. Keeping browsing returns to the prior view; completion shows a
nonmodal **Ready to play** action. Autoplay occurs only while the original
visible playback intent remains active, never when a queued job completes hours
later on another screen/profile.

Cancel stops local waiting immediately. Canceling remote work is offered only
for an app-owned job and never deletes a pre-existing user's cloud item.
Account-level remote deletion is a separate explicit action with the affected
file/container clearly described. Disconnect does not mean remote deletion.

Next episode uses the exact show/season/episode identity and the prior source
preference. Read-only metadata/candidate lookahead may happen near the end.
No speculative provider job or local swarm is started for the next episode by
default. Missing episodes lead to alternatives or a clear missing state;
season packs never select their largest video as a shortcut.

Use **Save offline** for local copies and **Save to cloud** only for services
that implement it. Keep progress, limits and cancellation unified in the UI
while preserving separate backend lifecycles. On tvOS, where Downloads is
currently hidden, show cloud preparation status in connection details and the
title instead of exposing unavailable device-download controls.

## Settings and help

| Location | Setting / default | Short help |
| --- | --- | --- |
| Connection | Show in library: on | Browse this account with your other libraries. |
| Connection | Show on Home: initial row only | Add or remove this account's row in Home layout. |
| Connection | Include in search: on, subject to profile gates | Search this source with your other media. |
| Connection | Preferred source: Automatic | Use a ready source that matches this device and your quality settings. |
| Connection | Allow cloud preparation: ask initially | Let Play prepare missing files in this account. |
| Add-on detail | Resources and host access | Controls what this add-on can provide and where it can connect. |
| Playback advanced | Peer-to-peer streaming: off | Download from peers on this device; uses local data, storage and upload bandwidth. |
| Playback advanced | P2P network/seeding limits | Choose when peer traffic can run and how much it can use. |
| Privacy/profile | Import or sync progress: off | Keep your viewing position across selected services. |
| Diagnostics | Connection details | Show sanitized status and recent errors. |

Use `SettingTile` help/subtitle patterns and `SettingsHelpHint`; keep long
explanations in the associated help sheet. Do not add a new question-mark icon
to every compact player control. Every icon-only button needs a localized
tooltip and semantic name. Mask API keys with a deliberate reveal action.

## Theme, icons, accessibility and interaction

Reuse `MonoTokens`, `groupItemRadii`, `FocusedScrollScaffold`, `SettingsGroup`,
`AppMenu`, `OverlaySheet`, `AppIcon`, `ProviderMark`, media card/grid widgets,
and current focus wrappers. Use bundled official provider marks with provenance;
retain brand colors as `ProviderMark` already does. Use current app typography
for labels; do not add downloaded fonts or restyle whole screens.

New semantic actions use existing rounded Material symbols: cloud for cloud
streaming, extension for add-ons, QR for linking, and the existing video/source
symbols for playback selection. Use labels alongside unfamiliar icons. Badges
must distinguish availability by text and semantics, not color alone.

On TV, all choices are reachable by D-pad with predictable Back behavior.
Closing a sheet restores focus to the invoking control; removing a focused
source moves focus to the next valid row. Keep the primary setup action and
Cancel accessible at large text sizes. QR codes need a quiet zone, sufficient
contrast and an equivalent readable URL/code; screen readers announce the code
once, not at every poll. Pause decorative motion with reduced-motion settings.

Use Slang keys in the established namespaces, plural rules and language-name
helpers. Isolate provider titles/filenames/URLs in bidi contexts; mirror layout
with directional padding, not the QR/code. Exercise Arabic/Hebrew RTL, CJK,
long translated labels and 200% text. Redacted hostnames must still be
understandable to assistive technology.
