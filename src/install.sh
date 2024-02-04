#!/usr/bin/env bash
set -Eeuo pipefail

# Check if running with interactive TTY or redirected to docker log
if [ -t 1 ]; then
  PROGRESS="--progress=bar:noscroll"
else
  PROGRESS="--progress=dot:giga"
fi

BASE="boot.img"
[ ! -f "$STORAGE/$BASE" ] && BASE="boot.iso"
[ ! -f "$STORAGE/$BASE" ] && BASE="Boot.img"
[ ! -f "$STORAGE/$BASE" ] && BASE="Boot.iso"
[ ! -f "$STORAGE/$BASE" ] && BASE="boot.IMG"
[ ! -f "$STORAGE/$BASE" ] && BASE="boot.ISO"
[ ! -f "$STORAGE/$BASE" ] && BASE="BOOT.IMG"
[ ! -f "$STORAGE/$BASE" ] && BASE="BOOT.ISO"

[ -f "$STORAGE/$BASE" ] && return 0

if [ -z "$BOOT" ]; then
  error "No boot disk specified, set BOOT= to the URL of an ISO file." && exit 64
fi

BASE=$(basename "$BOOT")
[ -f "$STORAGE/$BASE" ] && return 0

BASE=$(basename "${BOOT%%\?*}")
: "${BASE//+/ }"; printf -v BASE '%b' "${_//%/\\x}"
BASE=$(echo "$BASE" | sed -e 's/[^A-Za-z0-9._-]/_/g')
[ -f "$STORAGE/$BASE" ] && return 0

TMP="$STORAGE/${BASE%.*}.tmp"
rm -f "$TMP"

MSG="Downloading $BASE..."
info "$MSG" && html "$MSG"

/run/progress.sh "$TMP" "Downloading $BASE ([P])..." &
{ wget "$BOOT" -O "$TMP" -q --no-check-certificate --show-progress "$PROGRESS"; rc=$?; } || :

fKill "progress.sh"

(( rc != 0 )) && error "Failed to download $BOOT , reason: $rc" && exit 60
[ ! -f "$TMP" ] && error "Failed to download $BOOT" && exit 61

html "Download finished successfully..."

SIZE=$(stat -c%s "$TMP")

if ((SIZE<100000)); then
  error "Invalid ISO file: Size is smaller than 100 KB" && exit 62
fi

mv -f "$TMP" "$STORAGE/$BASE"

return 0
