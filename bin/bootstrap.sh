#!/bin/bash
# Prepare a FreeCAD weekly build for headless reproduction. Safe to run again.
#
#   FC_TAG   release tag of the weekly build (default below)
#   FC_HOME  where the extracted build lives (default: $HOME/fc-weekly)
set -euo pipefail

FC_TAG="${FC_TAG:-weekly-2026.10.01}"
FC_HOME="${FC_HOME:-$HOME/fc-weekly}"
ASSET="FreeCAD_${FC_TAG}-Linux-x86_64.AppImage"
HERE="$(cd "$(dirname "$0")" && pwd)"

# Upstream release files are reachable from a cloud session (checked 2026-10-04).
URLS=(
    "https://github.com/FreeCAD/FreeCAD/releases/download/${FC_TAG}/${ASSET}"
)

if [ -x "$FC_HOME/AppRun" ]; then
    echo "bootstrap: weekly build already present in $FC_HOME"
else
    tmp="$(mktemp -d)"
    got=""
    for url in "${URLS[@]}"; do
        echo "bootstrap: downloading $url"
        if curl -fL --retry 3 -sS -o "$tmp/$ASSET" "$url"; then
            got=1
            break
        fi
    done
    if [ -z "$got" ]; then
        echo "bootstrap: ERROR, could not download the weekly build from any source" >&2
        exit 1
    fi
    chmod +x "$tmp/$ASSET"
    # AppImages need FUSE to mount; extracting works everywhere.
    (cd "$tmp" && "./$ASSET" --appimage-extract >/dev/null)
    mkdir -p "$(dirname "$FC_HOME")"
    mv "$tmp/squashfs-root" "$FC_HOME"
    rm -rf "$tmp"
    echo "bootstrap: extracted to $FC_HOME"
fi

# A virtual display for scripts that need the GUI. Not fatal if it cannot be
# installed: bin/fc-gui falls back to Qt's offscreen platform.
if ! command -v xvfb-run >/dev/null 2>&1; then
    sudo=""
    if [ "$(id -u)" != "0" ]; then sudo="sudo -n"; fi
    if $sudo apt-get update -qq && $sudo apt-get install -y -qq xvfb >/dev/null; then
        echo "bootstrap: installed xvfb"
    else
        echo "bootstrap: WARNING, xvfb not installed; fc-gui will use the offscreen platform"
    fi
fi

"$HERE/fc-cmd" --version
