# Historical audiobook/cloud sync recovery checkpoint

The implementation represented by this checkpoint has since been integrated into PlezyNG. Current behavior and design notes are in [the audiobook sync plan](../../docs/AUDIOBOOK_SYNC_PLAN.md); application code is under `lib/sources/sync/` and `lib/screens/sources/source_sync_screen.dart`.

This bundle remains as an audit and recovery artifact. It targets a pre-integration source snapshot and should not be applied to the current repository.

The bundle contains reconstructed source transformations and the English localization additions that were used during recovery. It is not a byte-for-byte backup of the original working tree.

The replay script refuses to apply its patch set when it detects the integrated sync implementation. Do not use `--apply` in this checkout. A separate older checkout would still require code review, regenerated Slang output, formatting, analysis and tests after replay.
