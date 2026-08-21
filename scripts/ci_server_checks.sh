#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR/server"

go mod download
go mod verify
git diff --exit-code -- go.mod go.sum
go vet -mod=readonly ./...
go test -mod=readonly -race -count=1 ./...
go install golang.org/x/vuln/cmd/govulncheck@v1.1.4
govulncheck ./...
