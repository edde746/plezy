## Runner policy — owner directive, 2026-10-26

All repositories and all GitHub Actions build, test, scan, packaging and release
jobs must use compatible private ephemeral JIT runners. GitHub-hosted runners
and automatic hosted fallback are not authorized. This directive supersedes
older hosted-first, pilot-only, selected-jobs-only and permission-pending notes.
Do not restore `NG_HOSTED_FIRST`, a hosted literal, or a hosted matrix fallback.
Missing capacity is a provisioning blocker, never permission to spend hosted
minutes. Preserve OS and architecture requirements. Keep untrusted pull-request
code on an isolated disposable runner with no secrets; do not widen trusted
runner-group access to make it run. Preserve active builds and other agents'
work. Do not restart the broker while it owns running guests. Validate a new
workflow revision on private JIT; rerunning an old run uses its old revision.

The shared policy and exact workflow inventory live in
`snapetech-org/packer/scripts/shared-jit-runner-pool/`. Source routing, deployed
broker policy, runner-group access and live platform capacity must all agree.
Do not report the rollout complete from YAML changes alone.

