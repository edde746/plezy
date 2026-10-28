# Audiobook/cloud sync recovery artifacts

The base encrypted progress-sync implementation is present in PlezyNG under `lib/sources/sync/` and `lib/screens/sources/source_sync_screen.dart`; see [the current implementation plan](../../AUDIOBOOK_SYNC_PLAN.md).

The [2026-10-26 recovery checkpoint](../../plezyng/audiobooks/CLOUD_SYNC_RECOVERY_CHECKPOINT_2026-10-26.md) preserves a later set of reconstructed audiobook/player refinements. Those edits were not reconciled against current `main` and do not represent delivered app behavior. The bundle may overlap committed files and needs line-by-line review before any use.

`changes.json` is preserved for audit/recovery. `apply.py` preflights text and intentionally refuses `--apply` when it detects the existing sync implementation. Do not remove that guard or apply this bundle to the current checkout. No application edits were made from this bundle during branch consolidation.
