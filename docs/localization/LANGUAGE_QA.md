# Independent localization language QA

**All identified findings in this bounded pass are resolved. This is an independent AI language review and correction pass, not a human review, native-speaker certification, or approval of every translation.**

The review corrected **1,218 distinct source messages in 33 catalogs: 1,217 translations and one English source message**. The first pass corrected 790 messages; the follow-up corrected all 291 specifically recorded residual findings and the remaining identified gibberish, omissions, terminology errors and destructive-warning grammar. No known finding from this pass was left merely as a request for native review. Broader unsampled language and device behavior remain outside this result.

## Snapshot and independence

- PR: <https://github.com/snapetech-org/PlezyNG/pull/20>
- Published input head: `776377c17296df39e1fc17471ee9104659784104`.
- Published input tree: `3db4a8a763e21bbc868b0ac06cfcdf811be447ee`.
- Review date: 2026-10-26.
- The local checkout had older HEAD `eacf364b0b8eb9332e3eef241a97cf45972707be` and pre-existing changes. All 37 original catalog hashes were independently matched against the parent-provided, published-tree-verified snapshot. The manifest records original, first-pass and final hashes. No current-main fetch, rebase or other checkout was used.
- `original` and `english` in the correction ledger always mean the published 776377c text. `corrected` is the final text; `englishAfter` records the revised source where applicable. English before/after hashes are separate in the manifest. The 790-correction output is the second pass's baseline, not a replacement for the published before-images.
- The reviewer read the localization README, source and translation provenance for origin context, but made independent source-to-target judgments. Prior author review and upstream provenance were not treated as language approval.

## What was actually reviewed

**3,466 distinct physical non-English locale/message pairs** received direct semantic inspection, spanning all 32 non-English base catalogs and all four regional override catalogs. Another **290 inherited evaluations** give **3,756 effective locale/message pairs** across all 36 non-English choices. Inherited strings were evaluated through the reviewed parent, not counted as new direct reads. English was compared alongside each target; its singular episode-deletion warning also received one separately recorded source correction.

The first pass inspected 40 shared high-risk keys, 18 permission/recovery keys, 20 representative controls, four plural families and reader keyboard help in each full catalog. The 15 priority locales (`ar`, `bn`, `cs`, `fa`, `he`, `hi`, `id`, `ms`, `th`, `uk`, `vi`, `zh`, `zh-Hant`, `ja`, `ko`) also received the 39-key reader/source/lending/accessibility sample. Keyboard help overlaps that sample and is counted once. Regional catalogs contributed 122 explicit override reads. All four platform permission prompts were inspected for every effective locale.

The follow-up re-read and corrected all 291 residual findings, including all Azerbaijani, Kazakh and Uzbek items, and directly adjudicated every original corrupt-symbol, repeated-word and short-translation candidate. Nineteen adjacent labels were repaired to keep the corrected controls intelligible and consistent. The exact per-locale key paths and candidate dispositions are in the manifest; repeated reads and corrected forms are not inflated into additional unique-message counts.

The four plural families were read in all 32 base catalogs, covering **273 original plural-form strings**. They are `mediaMenu.deleteEpisodeCountWarning`, `mediaMenu.deleteMultiPartWarning`, `mediaMenu.deleteSharedFileHeading` and `playlists.itemCount`. The follow-up repaired the English singular warning, corresponding singular translation failures, older CJK `one` branches and directly observed Persian/Hebrew/Hindi warning grammar. It preserved count interpolation and plural structure. CLDR-generated unit messages were not edited.

Semantic checks considered the actor and object, negation, what is removed or retained, conditional warnings, reading direction, borrowing versus lending, action versus status labels, placeholders, number agreement and script. Context inspection included deletion dialogs, source-copy/conflict controls, narration/reader help, Home-layout navigation and playback settings. No live screen-reader or real-device permission session was performed.

| Locale | Physical messages | Direct semantic reads | Inherited evaluations | Original plural forms read | Corrections |
|---|---:|---:|---:|---:|---:|
| ar | 2867 | 123 | 0 | 24 | 24 |
| az | 2867 | 89 | 0 | 8 | 34 |
| bg | 2867 | 83 | 0 | 8 | 22 |
| bn | 2867 | 121 | 0 | 8 | 61 |
| cs | 2867 | 122 | 0 | 10 | 49 |
| da | 2867 | 83 | 0 | 8 | 22 |
| de | 2867 | 83 | 0 | 8 | 20 |
| es | 2867 | 83 | 0 | 8 | 20 |
| es-419 | 372 | 30 | 73 | 0 | 0 |
| fa | 2867 | 122 | 0 | 8 | 58 |
| fr | 2867 | 83 | 0 | 8 | 21 |
| fr-CA | 353 | 30 | 73 | 0 | 0 |
| he | 2867 | 121 | 0 | 9 | 67 |
| hi | 2867 | 121 | 0 | 8 | 43 |
| hu | 2867 | 83 | 0 | 8 | 19 |
| id | 2867 | 121 | 0 | 4 | 45 |
| it | 2867 | 83 | 0 | 8 | 20 |
| ja | 2867 | 122 | 0 | 7 | 46 |
| kk | 2867 | 84 | 0 | 8 | 32 |
| ko | 2867 | 132 | 0 | 7 | 53 |
| ms | 2867 | 127 | 0 | 4 | 51 |
| nb | 2867 | 83 | 0 | 8 | 20 |
| nl | 2867 | 83 | 0 | 8 | 19 |
| pl | 2867 | 83 | 0 | 16 | 20 |
| pt | 2867 | 83 | 0 | 8 | 20 |
| pt-BR | 381 | 31 | 72 | 0 | 0 |
| pt-PT | 384 | 31 | 72 | 0 | 0 |
| ru | 2867 | 83 | 0 | 16 | 18 |
| sv | 2867 | 83 | 0 | 8 | 18 |
| th | 2867 | 121 | 0 | 4 | 57 |
| tr | 2867 | 83 | 0 | 8 | 20 |
| uk | 2867 | 122 | 0 | 10 | 55 |
| uz | 2867 | 115 | 0 | 8 | 64 |
| vi | 2867 | 123 | 0 | 4 | 53 |
| zh | 2867 | 150 | 0 | 7 | 73 |
| zh-Hant | 2867 | 146 | 0 | 7 | 73 |

The English source contains 2,867 messages. Structural checks cover all 37 choices; the resolved non-English comparison has 103,212 locale/message pairs and the physical non-English catalogs contain 93,234 messages. These are automated totals, not semantic-review totals. Most catalog text remains outside the direct sample.

## Shared high-risk and recovery key sets

These exact sets apply to every non-English locale choice, resolving regional inheritance where needed. Complete representative, priority, plural and regional key lists are in [`language_qa_manifest.json`](language_qa_manifest.json).

### High risk: 40 keys

```text
settings.importSettingsConfirm
themeEditor.discardMessage
mediaMenu.confirmDeleteTarget
mediaMenu.deleteMultipleWarning
mediaMenu.deleteScopeUnverifiedProbeFailed
mediaMenu.deleteScopeUnverifiedNoFileInfo
messages.playbackNotAllowedBody
profiles.deleteThisProfileMessage
profiles.signOutPlexDeleteDownloadsDescription
profiles.removeConnectionMessage
profiles.deleteProfileMessage
libraries.selection.confirmUnwatched
startup.backupWarning
liveTv.deleteRuleMessage
collections.deleteConfirm
downloads.deleteConfirm
downloads.deleteCollectionDownloadsConfirm
downloads.removeSyncRuleConfirm
downloads.deleteSyncRuleDownloadsDescription
addServer.insecureDescription
addServer.allowHttp
fileSources.allowHttp
fileSources.disconnectMessage
fileSources.confirmDelete
fileSources.errorPermission
fileSources.errorInvalidData
fileSources.externalBlocked
fileSources.browserReaderHelp
fileSources.leftToRight
fileSources.rightToLeft
lending.disconnectMessage
lending.confirmReturn
lending.confirmCancelHold
lending.suspendMessage
lending.resumeMessage
accessibility.mediaCardUnwatched
accessibility.mediaCardPartiallyWatched
accessibility.rowColumnPosition
accessibility.navigationHint
accessibility.reduceMotionHint
```

### Permissions and recovery: 18 keys

```text
auth.localDataRecoveryRequired
settings.cloudBackupDescription
startup.failedBodyRepairable
startup.repairBodyCommon
startup.repairBodyOneCredential
startup.repairBodySignInsKept
startup.repairBodySignInsLost
startup.repairBodySessionsUncertain
startup.restartRequiredBody
startup.repairKeptSignIns
startup.repairLostSignIns
startup.repairLostSessions
seerr.noStoredCredentials
watchTogether.notices.downloadNotShared
platform.localNetworkPermission
platform.locationPermission
platform.photoLibraryPermission
platform.cameraPermission
```

## High-confidence findings and fixes

Severity **high** means wording can materially mislead a user about an action, loss, retained data, permission, borrowing, or recovery. **Medium** covers unusable navigation/accessibility wording and terminology that misidentifies a control. These are copy defects, not evidence that the implementation performed the mistranslated action.

The complete 1,218-entry [`language_qa_fixes.json`](language_qa_fixes.json) records locale, exact key, English, original, corrected text, severity, and an English explanation. Examples:

### he · `themeEditor.discardMessage` · high

- English: Your unsaved color changes will be lost.
- Original: השינויים הצבעוניים שלך לא ייעלמו.
- Corrected: שינויי הצבע שלא נשמרו יאבדו.
- Reason: Original reverses warning by saying changes will not disappear.

### he · `fileSources.externalBlocked` · high

- English: External book links are disabled in the reader.
- Original: קישורים חיצוניים לספרים מופעלים בקורא.
- Corrected: קישורים חיצוניים בספרים מושבתים בקורא.
- Reason: Original reverses disabled to enabled.

### th · `startup.repairBodyOneCredential` · high

- English: One saved sign-in is damaged and cannot be read. Repairing removes just that one; your other settings are left alone.
- Original: หนึ่งบันทึกจะเสียหายและไม่สามารถอ่านได้ การซ่อมแซมจะลบเพียงหนึ่งการตั้งค่าอื่น ๆ ของคุณจะหายไป
- Corrected: ข้อมูลเข้าสู่ระบบที่บันทึกไว้หนึ่งรายการเสียหายและอ่านไม่ได้ การซ่อมแซมจะลบเฉพาะรายการนั้น การตั้งค่าอื่นจะไม่เปลี่ยนแปลง
- Reason: Original reverses retention and says other settings will disappear.

### th · `startup.restartRequiredBody` · high

- English: Your data was repaired, but PlezyNG has to start fresh before it can use it. Close PlezyNG and open it again.
- Original: ข้อมูลของคุณได้รับการแก้ไข แต่ PlezyNG จะต้องเริ่มต้นใหม่ก่อนที่จะสามารถใช้ได้ ลบ PlezyNG และเปิดอีกครั้ง
- Corrected: ข้อมูลของคุณได้รับการซ่อมแซมแล้ว แต่ต้องเริ่ม PlezyNG ใหม่ก่อนใช้งาน ปิด PlezyNG แล้วเปิดอีกครั้ง
- Reason: Close app rather than delete PlezyNG.

### th · `mediaMenu.deleteScopeUnverifiedProbeFailed` · high

- English: PlezyNG could not check which files this will remove, so it may delete more than the item named above. Cancel and try again, or delete anyway.
- Original: PlezyNG ไม่สามารถตรวจสอบไฟล์ใดนี้จะลบดังนั้นจึงสามารถลบมากกว่ารายการที่ระบุไว้ข้างต้น ลบและลองอีกครั้งหรือลบในทางใด ๆ
- Corrected: PlezyNG ตรวจสอบไม่ได้ว่าจะลบไฟล์ใดบ้าง จึงอาจลบมากกว่ารายการที่ระบุข้างต้น ยกเลิกแล้วลองอีกครั้ง หรือเลือกที่จะลบต่อไป
- Reason: Cancel-and-retry was dangerously mistranslated as delete-and-retry.

### fa · `lending.due` · medium

- English: Due $date
- Original: درگذشت $date
- Corrected: موعد بازگشت: $date
- Reason: Due date was mistranslated as deceased.

### hi · `fileSources.stopReading` · medium

- English: Stop narration
- Original: नारियल को रोकें
- Corrected: पढ़कर सुनाना बंद करें
- Reason: Stop narration was mistranslated as stop coconut.

### bn · `messages.playbackNotAllowedBody` · high

- English: The server refused to stream this item (HTTP 403). Your account may not have permission to play it, or the server may only allow playback on its local network.
- Original: সার্ভার এই পণ্যটি প্রদর্শন করতে বাধ্য হয়েছিল (HTTP 403). আপনার অ্যাকাউন্টটি এটি খেলতে অনুমতি দেয়া হয় না, অথবা সার্ভার শুধুমাত্র স্থানীয় নেটওয়ার্কটিতে প্রদর্শন অনুমতি দেয়।
- Corrected: সার্ভার এই আইটেমটি স্ট্রিম করতে অস্বীকার করেছে (HTTP 403)। আপনার অ্যাকাউন্টে এটি চালানোর অনুমতি নাও থাকতে পারে, অথবা সার্ভার শুধু তার স্থানীয় নেটওয়ার্কে চালানোর অনুমতি দিতে পারে।
- Reason: Original says server was forced to show item rather than refused streaming.

### zh · `libraries.selection.confirmUnwatched` · high

- English: This also clears playback progress for the selected items.
- Original: 这也清晰了对所选择的项目的播放进展。
- Corrected: 这也会清除所选项目的播放进度。
- Reason: Clear progress rather than clarify progress.

### ar · `accessibility.rowColumnPosition` · medium

- English: Row ${row} of ${rowCount}, column ${column} of ${columnCount}
- Original: صف ${row} من ${rowCount}، صف ${column} من ${columnCount}
- Corrected: الصف ${row} من ${rowCount}، العمود ${column} من ${columnCount}
- Reason: Column was incorrectly announced as a second row.

### de · `fileSources.rightToLeft` · high

- English: Right to left
- Original: Recht auf Verlassen
- Corrected: Von rechts nach links
- Reason: Correct right-to-left reading direction.

### vi · `lending.suspendHold` · high

- English: Suspend hold
- Original: Hủy hoại
- Corrected: Tạm dừng đặt trước
- Reason: Suspend hold was mistranslated as destroy.

### Follow-up corrections

The additional 428 corrections are disjoint from the original 790: 291 residual findings, 59 remaining corruption/repetition candidates, 32 CJK short-candidate defects, 19 adjacent terminology labels and 27 destructive-warning plural families (including English). Each is a real before/after change, not an administrative change of status.

### az · `addServer.plexTokenRequired` · high

- Published English: Authentication required. Please enter your Plex token (X-Plex-Token).
- Original: X-Plex-Token (X-Plex-Token) xətnamə xətnamə xətnamə xətnamə xətnamə xətnamə xətnamə xətnamə xətnamə xətnamə xətnamə xətnamə xətnamə
- Corrected: Kimliyin təsdiqlənməsi tələb olunur. Plex tokeninizi (X-Plex-Token) daxil edin.
- Reason: Restore required authentication and the exact Plex token field name.

### uz · `homeLayout.removeRowBody` · high

- Published English: ${title} will be deleted. This can't be undone.
- Original: ${title} bilan bilan bilan bilan qaytadi.
- Corrected: ${title} o‘chiriladi. Bu amalni ortga qaytarib bo‘lmaydi.
- Reason: Restore deletion and its irreversible consequence with the title intact.

### zh · `appAccess.trialEndedDescription` · high

- Published English: Unlock every feature in PlezyNG for life with one purchase at your store's price. There is no subscription.
- Original: 解锁每件功能在 PlezyNG 终身,在您的商店价格购买一件。
- Corrected: 按商店显示的价格一次性购买，即可终身解锁 PlezyNG 的全部功能，无需订阅。
- Reason: Restore the omitted no-subscription promise and natural lifetime one-purchase wording.

### en · `mediaMenu.deleteEpisodeCountWarning` · medium

- Published English: This deletes all ${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} episode in it, and its file.
- Original: This deletes all ${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} episode in it, and its file.
- Corrected: This deletes the ${n: NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName)} episode it contains and its file.
- Reason: Remove the ungrammatical all-plus-singular construction while preserving deletion of both the contained episode and its file.

## Automated candidate scans and their dispositions

The scalar heuristics compare **102,420 resolved non-English messages** for English equality, short translations (English longer than 80 characters and target shorter than 30% of English), runs of four repeated words, corrupt/replacement characters (`U+2047`, `U+FFFD`), and selected opposite-action label collisions. The 22 plural families are excluded from scalar heuristics but receive structural checks. These heuristics identify candidates; they do not judge fluency.

| Candidate type | Published input | First-pass output | Final output |
|---|---:|---:|---:|
| `same_as_english` | 3873 | 3877 | 3878 |
| `repeated_word` | 47 | 47 | 0 |
| `corrupt_symbol` | 52 | 17 | 0 |
| `short_translation` | 47 | 45 | 19 |
| Identical selected opposite-action labels | 0 | 0 | 0 |

Every original corrupt-symbol, repeated-word and short-translation candidate has a concrete disposition in the manifest. All corrupt-symbol and repeated-word defects are corrected. Of the 43 short candidates remaining after the 291-key remediation, 32 had omissions or wrong meanings and were corrected; 11 were verified as adequate without further change. The final 19 length-ratio matches consist of those 11 plus eight corrected texts that still use fewer characters than English. Their source claims and qualifications were checked; the remaining ratio matches are CJK compression, not unaddressed defects.

English-equality candidates were not individually adjudicated. Product names, protocol labels and intentional font names can legitimately remain identical; the increase includes corrected technical labels. No claim of full untranslated-prose detection is made.

## Terminology references used during remediation

Primary references were used for domain vocabulary where useful; the final sentences are original AI corrections, not copied official translations or proof of native approval:

- Azerbaijani library reservation usage: [Khazar University library services](https://khazar.jis.az/library/services/) and [Institute of Zoology library instructions](https://zoologiya.az/az/content/1290).
- Kazakh library reservation usage: [Nazarbayev University library history](https://library.nu.edu.kz/kz/history).
- Uzbek library reservation action: [National University Jizzakh branch library guidance](https://lib.jbnuu.uz/info).
- Location and permission terminology: official Yandex [Kazakh geolocation guidance](https://yandex.kz/support/common/kk/browsers-settings/geolocation) and [Uzbek location-information guidance](https://yandex.uz/support/browser/uz/personal-data-protection/location-information).
- Azerbaijani account/sign-in terminology: [Google Account privacy page](https://myaccount.google.com/privacy?hl=az).

## Scope limits after remediation

There are **zero known unaddressed findings from this pass**. Native-speaker certification was not obtained, and this report does not imply it. Whole-workflow fluency, unsampled plural families and terminology, regional tone, speech output, bidi/font shaping, 200% text layout and real-device permissions still need their own coverage. Regional override samples had no specific semantic defect requiring a patch; broader `pt-PT`, `es-419` and `fr-CA` style evaluation was not a certification of every inherited string.

The former `needsNativeReviewKeys` lists are preserved as historical `firstPassNeedsNativeReviewKeys`; every one of their 291 entries links to an actual correction. Current unresolved lists are empty. Future native review is a quality-validation limitation, not a substitute for fixing an identified defect.

## Verification and reproduction

The final source catalogs pass all 37-locale/2,867-message structure and placeholder checks, strict cleanup, CLDR-unit freshness and all six catalog-check unit tests. The ledger was compared against the original published catalog contents and final files: 1,218 unique keys, no duplicate entries, all 291 residual keys changed against the first-pass baseline, and all 59 remaining corruption/repetition keys changed.

```sh
python3 scripts/checks/check_localizations.py
python3 scripts/checks/clean_translations.py --check --strict
python3 scripts/codegen/generate_localized_quantities.py --check
python3 scripts/checks/test_check_localizations.py
python3 docs/localization/language_qa_scan.py --check-reviewed-hashes
python3 docs/localization/language_qa_scan.py --check-findings-resolved
python3 docs/localization/language_qa_scan.py --baseline
```

Strict cleanup reports zero unused keys; its 73 ambiguous parent/dynamic references are not unused-key failures. The quantity generator reports zero changed catalogs. The independent reviewer edited catalog sources and QA artifacts only. The parent owns generated Dart/native resources, source snapshots, provenance and broader Flutter/browser validation; see [VALIDATION.md](VALIDATION.md) for the final integration evidence.

Artifacts: [`language_qa_manifest.json`](language_qa_manifest.json) records snapshots, exact reviewed paths, deduplicated coverage and resolved candidate dispositions; [`language_qa_fixes.json`](language_qa_fixes.json) is the complete original/English/final/rationale ledger; [`language_qa_scan.py`](language_qa_scan.py) reproduces automated evidence. Re-running checks reproduces hashes, structures and candidate counts, not the independent semantic judgments.
