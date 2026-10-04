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

# A virtual display and the system libraries Qt's X11 platform needs. Only done
# as root (a cloud session); on a desktop these are normally present already.
# Not fatal: bin/fc-gui can fall back to Qt's offscreen platform.
if [ "$(id -u)" = "0" ] && command -v apt-get >/dev/null 2>&1; then
    if apt-get update -qq >/dev/null 2>&1 &&
        apt-get install -y -qq xvfb libegl1 libgl1 libxkbcommon-x11-0 libxcb-cursor0 >/dev/null 2>&1; then
        echo "bootstrap: display packages installed"
    else
        echo "bootstrap: WARNING, could not install display packages"
    fi
fi

"$HERE/fc-cmd" --version

# Find a GUI mode that works here and say which.
for mode in xvfb offscreen; do
    if [ "$mode" = "xvfb" ] && ! command -v xvfb-run >/dev/null 2>&1; then continue; fi
    if FC_GUI_MODE="$mode" FC_TIMEOUT=180 "$HERE/fc-gui" "$HERE/gui_smoke.py" 2>/dev/null |
        grep -q GUI_SMOKE_OK; then
        echo "bootstrap: GUI scripts work with FC_GUI_MODE=$mode"
        if [ "$mode" = "offscreen" ]; then
            echo "bootstrap: xvfb mode failed, export FC_GUI_MODE=offscreen before using bin/fc-gui"
        fi
        exit 0
    fi
done
echo "bootstrap: WARNING, the GUI smoke test failed in every mode; see bin/fc-gui" >&2
exit 1
