#!/bin/bash
# Test changed Python files against the weekly build without building FreeCAD.
#
#   bin/overlay.sh apply <checkout> [base]   copy the Python files that differ from
#                                            [base] (default origin/main), committed
#                                            or not, from <checkout>/src/Mod/... into
#                                            $FC_HOME/usr/Mod/...
#   bin/overlay.sh restore                   put the original files back
#   bin/overlay.sh status                    list the files currently overlaid
#
# Only added and modified .py files are handled. Deleted files and non-Python
# files (ui, icons, C++) are reported and skipped.
set -euo pipefail

FC_HOME="${FC_HOME:-$HOME/fc-weekly}"
BK="$FC_HOME/.lab-overlay"
cmd="${1:-status}"

case "$cmd" in
apply)
    co="${2:?usage: overlay.sh apply <checkout> [base]}"
    base="${3:-origin/main}"
    if [ -d "$BK" ]; then
        echo "overlay: already applied, run 'overlay.sh restore' first" >&2
        exit 1
    fi
    if [ ! -d "$FC_HOME/usr/Mod" ]; then
        echo "overlay: no weekly build in $FC_HOME, run bootstrap.sh first" >&2
        exit 1
    fi
    mkdir -p "$BK/orig"
    : >"$BK/new.list"
    : >"$BK/files.list"
    {
        git -C "$co" diff --name-only --diff-filter=AM "$base" -- src/Mod
        git -C "$co" ls-files --others --exclude-standard -- src/Mod
    } | sort -u >"$BK/changed.list"
    git -C "$co" diff --name-only --diff-filter=D "$base" -- src/Mod |
        sed 's/^/overlay: NOT handled, deleted file /'
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        case "$f" in
        *.py) ;;
        *)
            echo "overlay: skipped, not a Python file: $f"
            continue
            ;;
        esac
        rel="${f#src/Mod/}"
        dst="$FC_HOME/usr/Mod/$rel"
        if [ -f "$dst" ]; then
            mkdir -p "$BK/orig/$(dirname "$rel")"
            cp -p "$dst" "$BK/orig/$rel"
        else
            echo "$rel" >>"$BK/new.list"
        fi
        mkdir -p "$(dirname "$dst")"
        cp "$co/$f" "$dst"
        echo "$rel" >>"$BK/files.list"
        echo "overlay: applied $rel"
    done <"$BK/changed.list"
    if [ ! -s "$BK/files.list" ]; then
        echo "overlay: no changed Python files under src/Mod"
        rm -rf "$BK"
    fi
    ;;
restore)
    if [ ! -d "$BK" ]; then
        echo "overlay: nothing to restore"
        exit 0
    fi
    while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        if [ -f "$BK/orig/$rel" ]; then
            cp -p "$BK/orig/$rel" "$FC_HOME/usr/Mod/$rel"
        else
            rm -f "$FC_HOME/usr/Mod/$rel"
        fi
    done <"$BK/files.list"
    rm -rf "$BK"
    echo "overlay: restored the original files"
    ;;
status)
    if [ -d "$BK" ]; then
        echo "overlay: applied files:"
        cat "$BK/files.list"
    else
        echo "overlay: not applied"
    fi
    ;;
*)
    echo "usage: overlay.sh apply <checkout> [base] | restore | status" >&2
    exit 2
    ;;
esac
