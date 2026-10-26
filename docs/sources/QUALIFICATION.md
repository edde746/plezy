# File source and reader qualification

This page records what the remediation implements and what still requires a real target environment. A feature being present in code does not count as a device or server qualification result.

## Download queue and storage cap

The download table stores the source ID, validated file descriptor, fingerprint, display label, queue state, last update time, bytes written, and reserved bytes. A process restart requeues rows left in `queued` or `running`. Explicitly paused and failed jobs remain visible in Files & books and require a retry. Removing a source cancels and waits for its active transfers before closing its adapter so a late transfer cannot recreate its queue row. Rows written by older builds have no descriptor; the app preserves their partial files for a later explicit download request instead of presenting them as restorable jobs.

The per-profile cap defaults to 10 GiB and can be changed from the Files & books options menu. Known sizes are reserved before transfer. Unknown sizes are reserved as content size becomes available and then checked as bytes arrive. Completed and partial copies count against the cap. The cap applies to PlezyNG's tracked offline copies; it does not promise a minimum amount of free space for the operating system. Existing files are kept if the user lowers the cap.

## Shared library identity

A source can be assigned a public shared-library ID. Devices using the same ID derive the sync identity from that ID and the source entry ID. Editing the ID re-keys cached progress and annotation versions while retaining the old cloud records so offline devices can still merge their writes.

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
