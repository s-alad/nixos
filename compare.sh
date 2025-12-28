#!/usr/bin/env bash
set -e

# usage info
show_help() {
  cat << EOF
usage: ${0##*/} [COMMIT1] [COMMIT2]

compare nixos configurations between two git commits.

arguments:
  COMMIT1    first commit to compare (default: HEAD~1)
  COMMIT2    second commit to compare (default: HEAD)

examples:
  ${0##*/}                    # compare HEAD~1 vs HEAD
  ${0##*/} HEAD~2 HEAD~1      # compare two specific commits
  ${0##*/} abc123 def456      # compare by commit hash
  ${0##*/} main develop       # compare branches

this script will:
  1. build both configurations
  2. compare their store paths
  3. run nix-diff if they differ
  4. return you to your original git state (branch or commit)
EOF
}

# check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  show_help
  exit 0
fi

cd /etc/nixos

# check for uncommitted changes
if ! git diff-index --quiet HEAD 2>/dev/null; then
  echo "warning: you have uncommitted changes in your working tree."
  echo "please commit or stash them before running this script."
  exit 1
fi

# get commits to compare
COMMIT1="${1:-HEAD~1}"
COMMIT2="${2:-HEAD}"

echo "comparing nixos configurations..."
echo ""

# save current state (branch name if on a branch, otherwise commit hash)
ORIGINAL_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")
if [ -n "$ORIGINAL_BRANCH" ]; then
  ORIGINAL_STATE="$ORIGINAL_BRANCH"
  ORIGINAL_TYPE="branch"
else
  ORIGINAL_STATE=$(git rev-parse HEAD)
  ORIGINAL_TYPE="commit"
fi

# resolve commit references
if ! RESOLVED1=$(git rev-parse "$COMMIT1" 2>/dev/null); then
  echo "error: invalid commit reference '$COMMIT1'"
  exit 1
fi

if ! RESOLVED2=$(git rev-parse "$COMMIT2" 2>/dev/null); then
  echo "error: invalid commit reference '$COMMIT2'"
  exit 1
fi

echo "commit 1: $(git log -1 --oneline $RESOLVED1)"
echo "commit 2: $(git log -1 --oneline $RESOLVED2)"
echo ""

# build first commit
echo "building first commit..."
git checkout -q "$RESOLVED1"
BUILD1_OUTPUT=$(sudo nixos-rebuild build --no-link 2>&1)
BUILD1=$(echo "$BUILD1_OUTPUT" | grep -oP '/nix/store/[^ ]+' | head -1)

if [ -z "$BUILD1" ]; then
  echo "error: failed to build first commit"
  git checkout -q "$ORIGINAL_STATE"
  exit 1
fi

# build second commit
echo "building second commit..."
git checkout -q "$RESOLVED2"
BUILD2_OUTPUT=$(sudo nixos-rebuild build --no-link 2>&1)
BUILD2=$(echo "$BUILD2_OUTPUT" | grep -oP '/nix/store/[^ ]+' | head -1)

if [ -z "$BUILD2" ]; then
  echo "error: failed to build second commit"
  git checkout -q "$ORIGINAL_STATE"
  exit 1
fi

# compare
echo ""
echo "=========================================="
echo "build 1: $BUILD1"
echo "build 2: $BUILD2"
echo ""

if [ "$BUILD1" = "$BUILD2" ]; then
  echo "identical - no functional changes"
  echo ""
  echo "the configurations produce the exact same system build."
else
  echo "store paths differ - analyzing changes..."
  echo ""
  nix-shell -p nix-diff --run "nix-diff '$BUILD1' '$BUILD2'"
fi
echo "=========================================="

# return to original state
git checkout -q "$ORIGINAL_STATE"
echo ""
if [ "$ORIGINAL_TYPE" = "branch" ]; then
  echo "returned to branch: $ORIGINAL_STATE"
else
  echo "returned to commit: $(git log -1 --oneline)"
fi
