# Private Snap packaging and publication

Snap jobs run in disposable private Linux VMs. Both commands use the Canonical
Snapcraft image pinned in `linux/packaging/snap/toolchain.lock.json`; they do not
start a host snapd or LXD daemon. Podman downloads and container commands receive
the job's explicit restricted HTTP proxy.

Packaging uses `scripts/build_private_snap.sh amd64` or `arm64` on the matching
native architecture, after the workflow stages the real application bundle.

Publication uses the private Linux x64 job for either package architecture:

```bash
bash scripts/publish_private_snap.sh \
  "$RUNNER_TEMP/plezyng-snap/plezyng-linux-arm64.snap" stable
```

Download the package and the release's `SHA256SUMS.txt` into that exact directory
first. The helper requires one matching checksum entry for the exact regular
package file. It accepts `edge`, `beta`, `candidate`, or `stable`, and rejects
symlinks, files outside the job directory, and reused container receipts before
provisioning tools. The workflow must still validate the published release and
its relationship to main before invoking this helper.

Set `SNAPCRAFT_STORE_CREDENTIALS` from the existing Actions secret. The helper
passes the variable name through sudo and Podman; it does not construct a
credential-bearing argument, env file, or log. Podman keeps the environment in
the disposable container's metadata until removal. Snapcraft retains its normal store authentication,
upload, and release processing. The container mounts only the verified package,
read-only, and is removed on success or failure. The receipt file is retained for
job evidence; do not reuse it for another upload attempt.

Validation:

```bash
python3 scripts/checks/test_publish_private_snap.py
shellcheck scripts/publish_private_snap.sh
```

The 2026-10-28 private x64 VM smoke used source
`63b97eb66b2bb2d88bc1d8a2527cc66e1d434a88`, Ubuntu 24.04, rootful Podman 4.9.3,
and image digest
`sha256:0443273552768a3230c2ede3aa47e567da0242bfbb0a7bb1283093208c404a0c`.
The real core24 package configuration and dependencies produced a valid Snap
containing a clearly marked stub executable. `upload --help` succeeded, and an
invalid invocation returned a nonzero container status. This proves the
container and packaging route; it is not an application build or store upload.
No store credentials were used. The disposable VM and its overlay were removed
after retaining the package, logs, hashes, and cleanup receipt.
