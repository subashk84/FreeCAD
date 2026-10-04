#!/bin/bash
# Check a session's fix branch on a local weekly build, independently of the session.
# Run on the contributor's machine (needs a logged-in gh and an extracted weekly build).
#
#   FC_HOME=<extracted weekly> bin/verify-branch.sh <branch> [console tests] [gui tests]
#   e.g. bin/verify-branch.sh fix/16725-layer-mirror-source TestDraft TestDraftGui
#
# It reads the branch from the fork through the GitHub API (no local checkout needed),
# lists what the branch changes, runs the issue's repro_check.py (if there is one) and
# the test modules on the unmodified build, copies the branch's Python files into the
# build, runs everything again, and restores the build.
set -uo pipefail

BR="${1:?usage: verify-branch.sh <branch> [console test module] [gui test module]}"
T_CMD="${2:-}"
T_GUI="${3:-}"
REPO="${FC_FORK:-subashk84/FreeCAD}"
LAB="$(cd "$(dirname "$0")/.." && pwd)"
export FC_HOME="${FC_HOME:-$HOME/fc-weekly}"
W="$(mktemp -d "${TMPDIR:-/tmp}/fc-verify.XXXXXX")"
export FREECAD_USER_HOME="$W/profile"
mkdir -p "$W/files" "$W/orig" "$FREECAD_USER_HOME"

if [ ! -d "$FC_HOME/usr/Mod" ]; then
    echo "verify: no weekly build in $FC_HOME (set FC_HOME)" >&2
    exit 2
fi

# The issue number is the first run of digits in the branch name.
num="$(echo "$BR" | grep -oE '[0-9]+' | head -1)"
repro="$LAB/issues/$num/repro_check.py"
repro_file="$(ls "$LAB/issues/$num"/*.FCStd 2>/dev/null | head -1)"

echo "== branch $BR"
gh api "repos/$REPO/compare/main...$BR" \
    -q '"commits ahead of main: \(.ahead_by), behind: \(.behind_by)", (.commits[] | "commit \(.sha[0:10]) \(.commit.message | split("\n")[0])"), (.files[] | "file \(.status) +\(.additions) -\(.deletions) \(.filename)")'
gh api "repos/$REPO/compare/main...$BR" -q '.commits[].commit.message' >"$W/messages.txt"
if grep -q -E '#[0-9]+|github\.com/.*/(issues|pull)/' "$W/messages.txt"; then
    echo "!! a commit message contains an issue reference or URL (it will show on the upstream issue)"
else
    echo "ok: no issue cross-reference in the commit messages"
fi

gh api "repos/$REPO/compare/main...$BR" -q '.files[] | select(.status != "removed") | .filename' >"$W/files.list"
while IFS= read -r f; do
    case "$f" in
    src/Mod/*.py) ;;
    *)
        echo "note: not applied to the build (not Python under src/Mod): $f"
        continue
        ;;
    esac
    mkdir -p "$W/files/$(dirname "$f")"
    gh api "repos/$REPO/contents/$f?ref=$BR" -H "Accept: application/vnd.github.raw" >"$W/files/$f"
done <"$W/files.list"

run_all() {
    tag="$1"
    if [ -f "$repro" ]; then
        echo "-- [$tag] reproduction check"
        FC_TIMEOUT=240 FC_REPRO_FILE="$repro_file" "$LAB/bin/fc-gui" "$repro" 2>&1 |
            grep -a -E "^(BEFORE|AFTER|RESULT|Traceback|[A-Za-z]+Error)" | head -12
    fi
    if [ -n "$T_CMD" ]; then
        FC_TIMEOUT=600 "$LAB/bin/fc-cmd" -t "$T_CMD" >"$W/$tag.cmd.out" 2>&1
        echo "-- [$tag] $T_CMD: exit=$? $(tr '\r' '\n' <"$W/$tag.cmd.out" | grep -a -E '^Ran |^OK|^FAILED' | tr '\n' ' ')"
        tr '\r' '\n' <"$W/$tag.cmd.out" | grep -a -E '^(ERROR|FAIL): ' | head -5
    fi
    if [ -n "$T_GUI" ]; then
        FC_TIMEOUT=600 "$LAB/bin/fc-gui" -t "$T_GUI" >"$W/$tag.gui.out" 2>&1
        echo "-- [$tag] $T_GUI: exit=$? $(tr '\r' '\n' <"$W/$tag.gui.out" | grep -a -E '^Ran |^OK|^FAILED' | tr '\n' ' ')"
        tr '\r' '\n' <"$W/$tag.gui.out" | grep -a -E '^(ERROR|FAIL): ' | head -5
    fi
}

restore() {
    [ -f "$W/py.list" ] || return 0
    while IFS= read -r f; do
        rel="${f#src/Mod/}"
        if [ -f "$W/orig/$rel" ]; then
            cp -p "$W/orig/$rel" "$FC_HOME/usr/Mod/$rel"
        else
            rm -f "$FC_HOME/usr/Mod/$rel"
        fi
    done <"$W/py.list"
    echo "== weekly build restored"
}
trap restore EXIT

echo "== BEFORE (unmodified build)"
run_all before

echo "== applying the branch's Python files"
(cd "$W/files" && find . -name '*.py' -type f | sed 's|^\./||') >"$W/py.list"
while IFS= read -r f; do
    rel="${f#src/Mod/}"
    dst="$FC_HOME/usr/Mod/$rel"
    if [ -f "$dst" ]; then
        mkdir -p "$W/orig/$(dirname "$rel")"
        cp -p "$dst" "$W/orig/$rel"
    fi
    mkdir -p "$(dirname "$dst")"
    cp "$W/files/$f" "$dst"
    echo "applied $rel"
done <"$W/py.list"

echo "== AFTER (with the branch)"
run_all after
echo "== output kept in $W"
