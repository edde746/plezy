# VLC feature parity localization QA

This addendum covers 36 messages for playback bookmarks, A/B segment loops,
audio effects, FTP access guidance, and local conversion profiles. English is
the source. The 32 non-English base locales use drafts from
`facebook/m2m100_418M` revision
`7c1b2620a4e58dacecbd8bf89cfd6da7eb9eb7b0`; Traditional Chinese is converted
from the Simplified Chinese draft with OpenCC `s2twp`. Regional catalogs inherit
from their configured language parent.

Early QA flagged unreliable output for Azerbaijani, Kazakh, and Uzbek, and the
initial plan used English fallbacks for these 36 messages. Follow-up catalog
updates now contain translated M2M100 drafts for those locales. The previous
fallback plan has been superseded: the per-message records classify the current
text as drafts, not English fallbacks or verified translations. Some A/B loop
terminology remains especially vulnerable to mistranslation because the model
can confuse the playback meaning of “loop” with other senses of the word.

No native-speaker review has been completed for these messages. The structural
localization check verifies keys, placeholders, and plural structure; it does
not measure fluency or certify accessibility announcements. Review playback
terminology, saved-marker labels, network-access guidance, and screen-reader
announcements with fluent speakers before claiming language quality. Until then,
treat these catalogs as drafts.

The follow-up VLC audit adds 10 English source messages for local playlist
export and alternate video-track selection. Non-English catalogs contain
M2M100 draft translations for these messages; they are not English fallbacks
and have not received native-speaker review. Per-message provenance records
the drafts. The source strings and translations remain subject to focused
localization review.

A direct structural audit found no missing or empty entries and no placeholder
mismatches for this 36-message batch across all 37 catalogs, including regional
inheritance. The current repository report checks 37 locales and 3,641 English
messages with no catalog key, placeholder, or plural-structure errors. The
source checkpoint reflects the current catalog structure; source and
translation review remains pending because these drafts have not received
native-speaker review.

A later visualizer follow-up adds the separate short status
`music.visualizerLiveAudio` to the 32 non-English base catalogs; four regional
catalogs inherit it. Its assistant-generated drafts are recorded in the
per-message provenance. No native-speaker review is claimed for this label.
