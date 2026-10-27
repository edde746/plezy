# Universal media localization QA

This addendum covers 185 `universalMedia` messages: the original 112 Open media
messages plus 73 VLC feature-parity additions for capture, stream sharing,
search extensions, CLI guidance, privacy and accessibility. English is the
source. The 32 non-English base locales use drafts from
`facebook/m2m100_418M` revision `7c1b2620a4e58dacecbd8bf89cfd6da7eb9eb7b0`;
Traditional Chinese is converted from the Simplified Chinese draft with OpenCC
`s2twp`. Regional catalogs inherit from their configured language parent.

The drafts retain interpolation placeholders and locale-specific plural forms.
Two plural messages remain whole-message English fallbacks:

- French: `universalMedia.skippedEntries`
- Kazakh: `universalMedia.skippedEntries`

The model failed to preserve the required count placeholder in those messages.
The fallback is recorded per message in `docs/localization/provenance/` and in
`translation-provenance.json`. Other new strings are recorded as M2M100 drafts.

No native-speaker review or independent semantic QA has been completed for this
feature. The machine-generated UI text is a draft and needs review, especially
for privacy, capture, streaming, extensions, playback, and accessibility wording.
Structural coverage checks keys, interpolation placeholders, and plural structure; it does not
measure fluency or certify safety language.

The current machine-readable coverage report records no missing, unknown, or
placeholder errors for `universalMedia`. The whole-project localization check
reports 716 issues: existing catalog errors plus 93 English messages whose
source-hash checkpoint is stale (including the new media strings). The checker
does not update that checkpoint while the catalog errors remain, so the global
localization gate does not pass on this branch. The new media strings are
present in each base locale with per-message draft/fallback provenance recorded.
