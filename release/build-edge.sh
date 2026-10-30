#!/usr/bin/env bash
set -euo pipefail
umask 077

CDB_SOURCE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$CDB_SOURCE_DIR"
CDB_BUILD_DIR="${CDB_BUILD_DIR:?Set an absolute output/cache directory outside the source checkout}"
CDB_JOBS=$(nproc)
CDB_UPSTREAM_LDFLAGS=$(cat release/LDFLAGS)
install -d -m 0700 "$CDB_BUILD_DIR" "$CDB_BUILD_DIR/out" \
  "$CDB_BUILD_DIR/gopath" "$CDB_BUILD_DIR/modules" \
  "$CDB_BUILD_DIR/cache" "$CDB_BUILD_DIR/tmp" "$CDB_BUILD_DIR/config"

env -i PATH=/usr/bin:/bin HOME="$HOME" \
  XDG_CONFIG_HOME="$CDB_BUILD_DIR/config" GOENV=off GOTOOLCHAIN=local \
  /usr/bin/go telemetry off

env -i PATH=/usr/bin:/bin HOME="$HOME" \
  XDG_CONFIG_HOME="$CDB_BUILD_DIR/config" \
  GOENV=off GOWORK=off GOTOOLCHAIN=go1.26.10 \
  GOPROXY=https://proxy.golang.org GOSUMDB=sum.golang.org \
  GOPATH="$CDB_BUILD_DIR/gopath" GOMODCACHE="$CDB_BUILD_DIR/modules" \
  GOCACHE="$CDB_BUILD_DIR/cache" GOTMPDIR="$CDB_BUILD_DIR/tmp" \
  GOOS=linux GOARCH=amd64 GOAMD64=v1 CGO_ENABLED=0 \
  GOMAXPROCS="$CDB_JOBS" \
  /usr/bin/go build -compiler=gc -mod=readonly -buildvcs=false -trimpath \
  -p "$CDB_JOBS" -tags netgo,osusergo \
  -ldflags "$CDB_UPSTREAM_LDFLAGS -s -w -buildid= -X github.com/sagernet/sing-box/constant.Version=1.14.4-edge1" \
  -o "$CDB_BUILD_DIR/out/edge-entry" ./cmd/sing-box
