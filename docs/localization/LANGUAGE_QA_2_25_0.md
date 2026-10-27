# PlezyNG 2.25.0 catalog update

The English catalog contains 3,391 messages. Since the frozen October 26 QA
snapshot, main added 303 English messages. Seventy-nine already had translations
retained from main; this update fills the remaining 224 entries in each of the
32 base non-English catalogs. Nine newer Steam account-library messages remain
explicit English fallbacks in those catalogs because the local machine drafts
were too garbled to ship. Their `english-fallback` provenance is tracked
separately. Regional catalogs continue to inherit from their existing language
parents.

The new entries use the documented M2M100 418M int8 model and are recorded as
`m2m100-draft` in per-message provenance. Decoding used beam size 4, repetition
penalty 1.15 and no-repeat trigram blocking. Ninety-five targeted AI corrections
across Bengali, Chinese, Czech, German, Hindi, Indonesian, Thai, Uzbek and
Vietnamese are recorded in [the correction ledger](language_qa_2_25_0_corrections.json)
and labeled `targeted-ai-review`.

The separate [2.25.0 overlay](language_qa_2_25_0_overlay.json) locks all 37
current catalogs, the translation source metadata and provenance, and reconstructs
the frozen QA snapshot from commit `c93850d623d9339dd4640e52d78d0650905d06ef`.
It also records 17 concise Chinese strings whose meaning was checked despite the
English-to-CJK length heuristic. No native-speaker approval is claimed. The
prior QA snapshots remain unchanged; source coverage and interpolation checks
are reproducible with `check_localizations.py`.
