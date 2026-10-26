# Audiobook/cloud sync recovery checkpoint

This is draft source and integration work preserved after the execution environment became unavailable. It is not active application code, has not completed validation, and must not be represented as merged functionality.

Read [the engineering plan](../../docs/AUDIOBOOK_SYNC_PLAN.md) first. The pending `lib/sources` / `lib/screens/sources` foundation must be present. Preserve newer security, branding and localization changes.

The bundle contains eight new Dart files (six implementation files and two test files), 70 ordered integration edits, and the English localization additions. It reconstructs issued edits; it is not a byte-for-byte backup of the inaccessible working tree.

Run `python3 tools/audiobook_sync_recovery/apply.py --root /path/to/isolated/checkout` for preflight. It does not write unless `--apply` is provided, and it stops if a prerequisite or expected source context differs. Reconcile changed context before applying. Then regenerate Slang, format, analyze and run the tests and remaining acceptance work documented in the plan.
