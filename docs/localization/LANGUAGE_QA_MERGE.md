# Language QA for the main9a17 merge

The merge against fixed main `9a17bbd0bff73071079c8b1bc4d85b77557b42fe` preserves all 1,218 original corrections and all 82 additional integration corrections. The only changed previously reviewed message is `discover.findNext.swipeHint`: English now says “Swipe the cover toward an arrow, or use the buttons below.” Its 32 base translations were independently reviewed against that cover/arrow context, preserving the alternative of using buttons. Four new regional physical overrides were also read and verified identical to their reviewed parent wording.

One incoming Malay phrase was clarified: `Leret kulit ke arah anak panah atau gunakan butang di bawah.` became `Leret imej muka depan ke arah anak panah atau gunakan butang di bawah.` The added image wording avoids interpreting standalone `kulit` as skin. Its before-image comes from the fetched main blob, and its final text is checked against the merged catalog. The separate [merge overlay](language_qa_merge_overlay.json) records this correction, the 36 reviewed physical hint values, the new English source, exact per-catalog additions and all current hashes.

The 19 other newly merged English paths—seven settings messages and twelve discovery messages—are explicitly outside this bounded semantic review. They account for 656 new physical non-English messages and 28 inherited evaluations, or 684 effective messages. They were included in the full automated scan; none created a new corrupt-symbol, repeated-word or short-translation candidate. No new broad translation authoring was performed for these features.

A later main update added five Steam audio setting messages. They remain outside semantic translation review and use explicit English fallbacks in non-English catalogs until translations are reviewed.

At the merge review, catalogs contained **3,079 English messages, 110,844 resolved non-English locale/message pairs and 110,052 scalar comparisons**. The scan retains 3,959 English-equality matches and the same 23 explicitly adjudicated adequate short cases. There are zero corrupt-symbol, repeated-word or identical opposite-action candidates. English equality remains a heuristic inventory, not an exhaustive fluency approval.

The regional hint overrides change the physical/inherited classification of four already covered locale/key pairs. Combined unique semantic coverage is now **8,117 physical reviews plus 854 inherited evaluations, or 8,971 effective pairs**. The 36 hint reads concern new wording of already covered messages, so they are not added again to the unique-pair total. Independent AI review does not certify native fluency, regional style or real-device layout.

The [historical report](LANGUAGE_QA.md), its manifest and 1,218-entry ledger remain unchanged. The [prior integration report](LANGUAGE_QA_INTEGRATION.md), integration manifest, 82-entry ledger and 47-entry source-setup draft ledger also remain unchanged. Their previous snapshot is local commit `734726aec69346b7e3e2bebf23b99c61639361e6`; the overlay pins its integration manifest/report hashes.

```sh
python3 docs/localization/language_qa_scan.py --check-reviewed-hashes --check-findings-resolved
python3 docs/localization/language_qa_scan.py --baseline
```

The checker verifies the complete merged hashes and current hint values, removes only explicitly enumerated new paths, restores the earlier hint text and any recorded key order, and reproduces all 37 pre-merge integration hashes. It then runs the existing exact historical projection and baseline reconstruction. Thus current merge verification and the original published audit remain separate and reproducible. All identified findings within this merge review are addressed; the 19 untouched additions are not claimed as semantically reviewed.
