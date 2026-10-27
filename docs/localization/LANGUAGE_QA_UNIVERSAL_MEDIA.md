# Universal media localization QA

This addendum covers the 112 new `universalMedia` messages in the Open media
feature. English is the source. The 32 non-English base locales use drafts from
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
for privacy, transfer, playback, and accessibility wording. Structural coverage
checks keys, interpolation placeholders, and plural structure; it does not
measure fluency or certify safety language.

The current machine-readable coverage report records zero structural errors for
`universalMedia`. The whole-project localization check still reports 716 legacy
catalog and source-snapshot issues outside this feature, so the global gate does
not pass on this branch.
