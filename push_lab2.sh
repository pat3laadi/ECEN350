#!/bin/bash
# push_lab2.sh
# Run this from inside your ECEN350 repo root (~/ECEN350) after
# copying the downloaded files into Lab2/part3/.
#
# Usage:
#   chmod +x push_lab2.sh
#   ./push_lab2.sh

set -e  # stop immediately if any command fails

# Make sure we're at the repo root (adjust if your clone lives elsewhere)
cd "$(dirname "$0")" 2>/dev/null || true

if [ ! -d ".git" ]; then
    echo "ERROR: This doesn't look like the root of a git repo."
    echo "cd into ~/ECEN350 first, then re-run this script from there."
    exit 1
fi

echo "== Pulling latest from GitHub first, to avoid conflicts =="
git pull origin main

echo "== Files about to be staged =="
git status --short Lab2/part3

echo "== Staging Lab2/part3 =="
git add Lab2/part3

# Only commit if there's actually something staged
if git diff --cached --quiet; then
    echo "Nothing changed in Lab2/part3 — nothing to commit."
    exit 0
fi

echo "== Committing =="
git commit -m "Update Lab2 part3 files"

echo "== Pushing to GitHub =="
git push origin main

echo "== Done. Verifying remote state =="
git log origin/main --oneline -3
