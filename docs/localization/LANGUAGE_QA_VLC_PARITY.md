# VLC feature parity localization QA

This addendum covers 36 messages for playback bookmarks, A/B segment loops,
audio effects, FTP access guidance, and local conversion profiles. English is
the source. The 32 non-English base locales use drafts from
`facebook/m2m100_418M` revision
`7c1b2620a4e58dacecbd8bf89cfd6da7eb9eb7b0`; Traditional Chinese is converted
from the Simplified Chinese draft with OpenCC `s2twp`. Regional catalogs inherit
from their configured language parent.

The pinned model produced unreliable output for Azerbaijani, Kazakh, and Uzbek,
so those catalogs use explicit English fallbacks for these 36 messages. Each
fallback is recorded per message in `docs/localization/provenance/` and
`translation-provenance.json`. Other non-English entries are machine drafts,
not verified translations. Some A/B loop terminology is especially vulnerable
to mistranslation because the model confuses the playback meaning of “loop” with
other senses of the word.

No native-speaker review has been completed for these messages. The structural
localization check verifies keys, placeholders, and plural structure; it does
not measure fluency or certify accessibility announcements. Review playback
terminology, saved-marker labels, network-access guidance, and screen-reader
announcements with fluent speakers before claiming language quality. Until then,
treat these catalogs as drafts.

A direct structural audit found no missing or empty entries and no placeholder
mismatches for this 36-message batch across all 37 catalogs, including regional
inheritance. The current repository report checks 37 locales and 3,626 English
messages with no catalog key, placeholder, or plural-structure errors. Source
review remains pending for 36 changed English messages, including this batch;
the source checkpoint was not refreshed because these translations have not
received native-speaker review.
