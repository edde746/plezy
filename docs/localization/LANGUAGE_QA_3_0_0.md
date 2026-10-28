# PlezyNG 3.0.0 deep-link and playback localization

The 3.0.0 catalog pass completed 19 previously blank or missing messages in
32 base non-English catalogs: 17 `deepLinks` messages and two playback
screen-lock labels. This produced 608 M2M100 draft strings. Traditional Chinese
uses the documented OpenCC `s2twp` conversion from the Simplified Chinese draft.

The pinned source is `jncraton/m2m100_418M-ct2-int8` revision
`7c1b2620a4e58dacecbd8bf89cfd6da7eb9eb7b0`, matching the model provenance in
`sources.json`. Decoding used beam size 4, repetition penalty 1.15, no-repeat
trigram blocking and a maximum decoding length of 160. The source end token is
included. Per-message origins are recorded in `provenance/`.

A targeted AI correction pass changed 107 strings, including both screen-lock
labels in every base locale and the machine drafts that failed spot checks.
The exact before/after values and reasons are in
[the correction ledger](language_qa_3_0_0_corrections.json). Regional locales
continue to inherit from their language parents. The unused `automation.profileNotFound`
message and orphan `videoControls.longPressToUnlock` translations were removed.

`clean_translations.py --check --strict` and `check_localizations.py` pass for
all 37 locales and 3,593 source messages, including interpolation placeholders
and the reviewed English source snapshot. This is structural coverage and
limited targeted AI review; no native-speaker approval or full fluency review
is claimed.
