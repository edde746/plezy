# Localization integration language QA

All identified findings in this bounded integration have been addressed. The pass adds **4,656 directly reviewed non-English locale/message pairs and 568 inherited evaluations**. It preserves the historical review and its 1,218 correction records, records 82 additional catalog corrections separately, and identifies 47 refinements made to unpublished source-setup drafts. This is AI language review, including clearly labeled author self-review; it is not human or native-speaker certification.

The fixed integration baseline is main `027059a836f62dc6aab7212eef9d1935273188e8`. All 1,218 historical corrected values remain present. The original [report](LANGUAGE_QA.md), [manifest](language_qa_manifest.json) and [correction ledger](language_qa_fixes.json) remain byte-for-byte unchanged. The separate [integration manifest](language_qa_integration.json) records complete current hashes, exact reviewed English/translated values, per-locale key sets, review provenance, candidate dispositions and explicitly unreviewed additions.

## Exact semantic scope

| Bounded group | Source keys | Direct locale/message reads | Review type | Inherited evaluations |
| --- | ---: | ---: | --- | ---: |
| `discover.findNext` in all 32 base locales | 42 | 1,344 | Authoring followed by semantic self-review | 168 |
| Six SMB setup messages in all 32 base locales | 6 | 192 | Independent review of parent-authored drafts | 24 |
| `sourceSetup` in 23 base locales | 94 | 2,162 | Authoring followed by semantic self-review | Included below |
| `sourceSetup` in nine other base locales | 94 | 846 | Independent review of parent-authored drafts | 376 across all four regional choices |
| Entire Italian lending/audiobook blocks and audiobook source label | 102 | 102 | Independent review of existing text | 0 |
| Concrete additional audiobook scan candidates | 10 locale/key pairs | 10 | Independent review and correction | 0 |

The nine independently reviewed source-setup locales are `ar`, `bn`, `fa`, `he`, `hi`, `ja`, `ko`, `zh` and `zh-Hant`. The other 23 were authored and self-reviewed by the reviewing subagent. Every base locale received all 142 shared discovery/SMB/source-setup messages. The regional choices `es-419`, `fr-CA`, `pt-BR` and `pt-PT` inherit their existing parents; they are not counted as fresh direct language reads.

| Locale(s) | Direct integration messages per locale | Inherited integration messages per locale |
| --- | ---: | ---: |
| ar, az, bg, bn, cs, da, de, es, fa, fr, he, hi, hu, id | 142 | 0 |
| it | 244 | 0 |
| ja, kk | 143 | 0 |
| ko, ms, nb, nl, pl, pt, ru, sv, th, tr, uk, vi | 142 | 0 |
| uz | 144 | 0 |
| zh, zh-Hant | 145 | 0 |
| es-419, fr-CA, pt-BR, pt-PT | 0 | 142 |

Nine integration reads overlap the historical semantic sample. Exact set unions therefore yield **8,113 direct non-English locale/message pairs plus 858 inherited evaluations, or 8,971 effective pairs**, across the historical and integration reviews. These totals include self-review where specified; they do not imply that every catalog message was semantically reviewed. The manifest enumerates every path used to calculate them.

## Corrections and context review

The [82-entry additional ledger](language_qa_integration_fixes.json) contains English, original and final text, severity and an English explanation for every correction. It includes 71 Italian corrections, ten additional audiobook candidate corrections, and one Thai SMB draft correction. The Thai record's before-image is the parent-authored integration draft; it is not a claim that this wording existed in the historical published snapshot. These 82 records are disjoint from the original 1,218 and bring the catalog correction ledgers to 1,300 records.

| Locale/key | English | Before | After | Meaning repaired |
| --- | --- | --- | --- | --- |
| `it.lending.returnBook` | Return early | Il ritorno presto | Restituisci in anticipo | Restore the action of returning a borrowed book early. |
| `it.lending.signIn` | Sign in with your library | Iscriviti con la tua biblioteca | Accedi tramite la tua biblioteca | Sign in rather than register. |
| `it.audiobook.undoSeek` | Undo last seek | L’ultima ricerca | Annulla l’ultimo salto di riproduzione | Undo a playback seek rather than name a search. |
| `it.audiobook.sleepMinutes` | Minutes (1–1440) | Il tempo (1-440 minuti) | Minuti (1–1440) | Restore the exact allowed range and unit. |

Italian lending was checked for borrowing, signing in, returning, holds, queues, service handoff and warnings. Audiobook text was checked for playback seek, bookmarks, chapter/book duration, sleep ranges, conflict choice, sync credentials and privacy. The Kazakh and Uzbek repeated-word privacy descriptions were replaced with complete translations. Japanese and Chinese warnings now retain provider-side encrypted-file retention; Chinese privacy and conflict messages distinguish tokens from icons, bookmarks from icons, and timestamps from schedules. The Thai SMB text now means the whole single share, not every shared folder.

The [source-setup draft review ledger](language_qa_source_setup_review_fixes.json) separately records 47 before/after refinements: 32 from independent review and 15 from author self-review. These are not appended to the historical or 82-entry catalog correction ledgers. Examples include Korean `암호문` (ciphertext) becoming `암호 구문` (passphrase), Japanese client identity becoming `クライアント認証情報` rather than an ambiguous numeric ID, repairing the truncated Hungarian client-certificate label, and preserving the single saved German client identity. All corresponding final values are checked against the catalogs.

The discovery review used cross-media recommendation context: saved picks are suggestions, not downloads or purchases; finishing the suggestion stack does not mean finishing all media; refresh requests another selection, not an audio remix. Unknown formatted durations and proper names use interpolation-safe constructions. All 224 discovery placeholder occurrences were checked.

The 94 source-setup messages were reviewed in every base locale for clear form labels and errors, saved-value preservation, certificate and passphrase terminology, privacy exclusions and security negation. Specific promises retained include:

- Required encrypted NFS fails closed and is not retried without encryption. Both NFS and mount services require TLS 1.3 and RPC-with-TLS support.
- Certificate names must match the host. Trust certificates must not contain private keys. PKCS#12 client credentials and their passphrase remain distinct from numeric IDs and ciphertext.
- AUTH_SYS UID/GID and client-port policy still apply inside the encrypted connection. NFS is read-only NFSv3 over TCP; NFSv4 and UDP remain unsupported.
- FTP remains passive. Plain `ftp://` is unencrypted; `ftpes://` requests explicit TLS; `ftps://` uses implicit TLS on port 990 and explicit TLS on other ports.
- Metadata title searches exclude media and source credentials. Subtitle searches exclude video files and store API/account credentials encrypted. Both retain the stated title/ID data scope; NFO fields retain priority.

The FTP wording was checked against [RFC 4217](https://www.rfc-editor.org/rfc/rfc4217.html) and the [official Microsoft explicit-TLS description](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-ftps/2f3d3502-a689-4015-adc2-055720b107d2). Several translations explain the separate TLS command and immediate TLS startup instead of relying on ambiguous literal translations of “explicit” and “implicit.” This is terminology verification, not a protocol implementation audit. No external translated sentences were copied.

Source-setup validation checks all 32 × 94 values, exact key sets, nonempty text, 256 placeholder occurrences and preserved technical tokens/examples. Placeholder order is allowed to follow local grammar; names and multiplicities must match. The English source-map SHA-256 is `2bf5dfcd1f5e14a684754b69aa50dd02eaeba185d42bbd4a500c8d944efba605`. The discovery source-map SHA-256 is `0034b569d82344709f535601a29a25b3d0a4e1ad0a52f53fe95d7afe1745d362`. Full input and catalog hashes are in the integration manifest.

## Automated coverage and limits

The complete current catalogs contain **3,060 English messages, 110,160 resolved non-English locale/message pairs and 109,368 scalar comparisons**. The current scan reports zero corrupt-symbol candidates, zero repeated-word candidates and zero identical opposite-action pairs. All ten concrete newly merged audiobook candidates were corrected. The 23 remaining short-translation candidates have explicit adequate-text dispositions: 19 historical cases and four new Chinese cases at `sourceSetup.metadataFailed` and `sourceSetup.subtitleApplyFailed`. The latter preserve the failure, continued playback/local details, or connection/retry instruction in fewer characters.

The scan also inventories 3,959 English-equality matches. Equality is not automatically a defect or an approval. Reviewed discovery matches are minute abbreviations and German/Dutch “Details”; source-setup matches are the OpenSubtitles brand and the accepted Indonesian technical label “Default.” Other equality matches remain an automated inventory rather than an exhaustive semantic judgment.

There are 193 new English paths outside the historical review: 42 discovery, six SMB, 94 source-setup and 51 audiobook/source paths. The manifest explicitly enumerates the paths excluded from historical reconstruction. Of the latter 51, all were reviewed in Italian and ten concrete locale/key candidates were reviewed elsewhere. The remaining **1,571 physical new locale/message pairs, plus 204 inherited evaluations**, are explicitly outside this semantic sample. They were still included in the complete current scan. Unreviewed scope is not an unresolved identified defect, and no blanket fluency approval is given.

AI correction completion is separate from native-language certification. Real-device speech output, typography, truncation, bidi shaping, gesture behavior and regional register were not certified by this text review. Functional, structural, generated-resource and widget-test evidence belongs in [VALIDATION.md](VALIDATION.md).

## Reproduction without rewriting history

```sh
python3 docs/localization/language_qa_scan.py --check-reviewed-hashes --check-findings-resolved
python3 docs/localization/language_qa_scan.py --baseline
```

Both commands passed against the frozen integration catalogs. The first verifies all 37 current complete-catalog hashes, the exact reviewed source/translation values, the 82 additional corrections and the 47 source-setup draft corrections. It checks every declared new path and the current full-catalog candidate scan. The historical artifacts are hash-locked.

For historical verification, the checker reverses only the separate 82 corrections, then projects the exact original reviewed key/order shape from [language_qa_historical_shape.json](language_qa_historical_shape.json). The shape was derived from the hash-verified published snapshot and the original 1,218 final corrections; it contains no replacement translations. All 37 historical reviewed hashes are reproduced. Excluding explicitly enumerated new paths makes no claim that those paths were reviewed.

The baseline command then reverses the original 1,218 corrections, reproducing every original published-input hash at head `776377c17296df39e1fc17471ee9104659784104` and the original counts: 52 corrupt-symbol, 47 repeated-word, 47 short-translation and 3,873 English-equality candidates. This preserves the original audit while verifying the complete later snapshot independently.
