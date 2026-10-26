# File source and reader qualification

This page records what the remediation implements and what still requires a real target environment. A feature being present in code does not count as a device or server qualification result.

## Download queue and storage cap

The download table stores the source ID, validated file descriptor, fingerprint, display label, queue state, last update time, bytes written, and reserved bytes. Picker imports use the same ledger and reserve their known size before copying or grow the reservation as bytes arrive. At startup, older picker copies in the app-owned imports directory are adopted into the ledger so they count against the quota after upgrading. A process restart requeues rows left in `queued` or `running`; interrupted picker imports cannot resume their picker grant and are marked for removal. If promotion finished just before a crash, startup reconstructs and commits the imported file from its metadata. Explicitly paused and failed provider jobs remain visible in Files & books and require a retry. Removing a source cancels and waits for its active transfers before closing its adapter so a late transfer cannot recreate its queue row. Failed and paused jobs can be removed from the queue to release their partial files and quota reservations; source removal also clears that source's incomplete jobs while retaining completed offline copies. Rows written by older builds have no descriptor; the app preserves their partial files for a later explicit download request instead of presenting them as restorable jobs.

The per-profile cap defaults to 10 GiB and can be changed from the Files & books options menu. Known sizes are reserved before transfer. Unknown sizes are reserved as content size becomes available and then checked as bytes arrive. Completed and partial copies count against the cap. Lowering the cap below currently tracked usage or reservations is rejected; the user can remove copies or jobs first. The cap includes picker-imported offline files as well as provider downloads. Android, iOS, macOS, Windows, and Linux writes also preserve a 512 MiB volume-free-space reserve after accounting for remaining active transfer reservations, checking each chunk before it is written. If the native free-space query fails, the write stops closed. tvOS and webOS builds retain the app quota but do not use this probe. Native background-transfer guarantees remain platform work.

## Combined sync destinations

Encrypted cloud sync and compatible provider-native progress/bookmark sync can run in the same cycle. The cloud document tracks its own observed values and published generation; provider events remain pending until the corresponding provider accepts them. Cloud-imported progress and annotations are also queued for compatible provider targets. A cloud error does not prevent the provider queue from running, and each target keeps its own conflict and retry state. Sync reports the first target error after attempting both. Native background-transfer guarantees are not provided by the foreground queue.

## Large local directory paging

Local source browsing keeps up to 20,000 entries in memory. Larger sorted directory snapshots are spooled to temporary JSON pages for reuse across cursor requests, up to 100,000 recognized entries and 128 MiB total across at most 32 directories. Snapshots expire after one minute and are removed when the adapter closes. If a spool exceeds its byte budget, browsing remains functional but later pages may re-enumerate the directory. Initial enumeration, sort, and 10,000/100,000-entry latency, memory, and I/O budgets still require measurement on target devices and filesystems.

## Shared library identity

A source can be assigned a public shared-library ID. Devices using the same ID derive the sync identity from that ID and the source entry ID. Editing the ID re-keys cached progress and annotation versions while retaining old cloud records as history. Every participating device must set the matching IDs before it can join the paired identity.

When providers assign different entry IDs to the same publication, the item detail screen accepts an explicit shared item ID. Setting or changing that mapping migrates cached progress and annotation records, including their edition keys, in the same transaction as the mapping preference. Edition progress is paired only when the edition's file types, MIME types, sizes, and positions in the entry file list match uniquely on both sources. Ambiguous or different file sets remain unapplied locally; they are never joined by title or file contents. Recovery files do not contain the mapping preference, so set the same shared-library and item IDs on each device before importing.

## Sync compaction and recovery

Compaction merges concurrent versions only when their values are identical. Deleted annotation records keep their causal tombstone and identity while the deleted note and quote text is removed. The first transformation advances the tombstone's causal clock; subsequent runs leave the already-compressed tombstone unchanged. This retains the evidence needed to reject stale writes from offline devices without changing the document on every sync.

Recovery export contains the encrypted sync document and its authenticated filename. The sync code remains separate. Import verifies the code and filename, merges state through the causal rules, and retains current history. Export after a successful sync to include the newest provider snapshot.

## NFS read performance

NFSv3 reads use a bounded read-ahead window, configurable from one to four requests. Four is the hard limit for concurrent NFS READ RPCs per adapter. A source detail action reads at most 64 MiB from the largest file and reports the bytes read, elapsed throughput, request count, and configured window. A short or interrupted sample fails qualification instead of reporting throughput for an incomplete read.

For a target NAS qualification, run the measurement with the same file and network path at read-ahead values 1, 2, 3, and 4. Repeat each measurement three times. Record the app build, NAS model and firmware, NFS export options, RPC-with-TLS setting, network link, file size, seek behavior, cancellation behavior, and the median throughput. This workspace has no NAS endpoint, so it has no live throughput result.

## Native reader qualification

The reader has separate native paths: EPUB and CBZ use the in-app WebView and the local publication server; PDF uses the native PDF viewer. Linux launches the reader in the external browser. The browser integration suite does not qualify the native WebView or PDF viewer.

| Platform | Reader engine | Qualification target |
| --- | --- | --- |
| Android phone/tablet | Android WebView and native PDF viewer | Open online and offline EPUB, CBZ, and PDF; save and restore position; search, notes, text selection, links, background/resume, process restart, rotation, TalkBack |
| iOS/iPadOS | WKWebView and native PDF viewer | Same flows; include app suspension, memory pressure, VoiceOver, and file URL/loopback behavior |
| macOS | WKWebView and native PDF viewer | Same flows; include keyboard navigation, window resizing, sleep/wake, VoiceOver, and large documents |
| Windows | WebView2 and native PDF viewer | Same flows; include keyboard navigation, window resize, WebView process restart, screen reader, and large documents |
| Linux | External browser and PDF path | Confirm the browser bridge, note/progress saving, external-link policy, and PDF rendering on each supported distribution |

For every platform, test a small and a large fixture, a remote source and an offline copy, interrupted reading, annotation deletion, sync conflict handling, and a profile switch while the reader is open. Record OS version, device model, app build, WebView/PDF engine version, source type, fixture fingerprint, and pass/fail for each flow.

No native device run is represented by this change. Native reader qualification remains pending until this matrix is completed on supported devices.
