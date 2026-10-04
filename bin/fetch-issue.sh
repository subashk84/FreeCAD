#!/bin/bash
# Save an upstream FreeCAD issue into issues/<number>/ so a cloud session can read it.
# Run this on the contributor's machine (it needs a logged-in gh); cloud sessions
# cannot reach the upstream issue API or attachment URLs.
#
#   bin/fetch-issue.sh 16725
set -euo pipefail

n="${1:?usage: fetch-issue.sh <issue number>}"
repo="${FC_UPSTREAM:-FreeCAD/FreeCAD}"
root="$(cd "$(dirname "$0")/.." && pwd)"
dir="$root/issues/$n"
mkdir -p "$dir"

gh api "repos/$repo/issues/$n" -q '"TITLE: \(.title)\nSTATE: \(.state)\nAUTHOR: \(.user.login)\nCREATED: \(.created_at)\nUPDATED: \(.updated_at)\nASSIGNEES: \([.assignees[].login]|join(", "))\nLABELS: \([.labels[].name]|join(", "))\n\n\(.body)"' |
    tr -d '\r' >"$dir/issue.txt"
gh api "repos/$repo/issues/$n/comments" --paginate \
    -q '.[] | "\n----- \(.created_at[0:10]) \(.user.login) -----\n\(.body)"' |
    tr -d '\r' >"$dir/comments.txt"

# Attached files (not images or videos, which a session cannot use anyway).
{ grep -ohE 'https://github\.com/(user-attachments/files|[^/ ]+/[^/ ]+/files)/[0-9]+/[^) >"]+' \
    "$dir/issue.txt" "$dir/comments.txt" || true; } | sort -u | while IFS= read -r url; do
    name="$(basename "$url")"
    if curl -fsSL -o "$dir/$name" "$url"; then
        echo "attachment: $name"
        case "$name" in
        *.zip) (cd "$dir" && unzip -o -q "$name" && rm -f "$name") ;;
        esac
    else
        echo "attachment FAILED: $url" >&2
    fi
done

# Open pull requests that mention the issue: a reason not to start work on it.
gh api "repos/$repo/issues/$n/timeline" --paginate \
    -q '.[] | select(.event=="cross-referenced") | .source.issue | select(.pull_request != null) | "PR \(.number) [\(.state)] \(.title)"' \
    >"$dir/linked_prs.txt" 2>/dev/null || true

echo "saved issue $n to $dir:"
ls "$dir"
if grep -q '\[open\]' "$dir/linked_prs.txt" 2>/dev/null; then
    echo "WARNING: an open pull request already references this issue:"
    grep '\[open\]' "$dir/linked_prs.txt"
fi
