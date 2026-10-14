#!/usr/bin/env bash
# Deploy to Fasthosts (CentOS 7) by pulling from GitHub on the server.
# Push your commits first; this only tells the server to fetch them.
#
# Usage:
#   SSH_HOST=ssh.yourdomain.co.uk ./build/deploy.sh
#
# Optional env:
#   SSH_USER    (default csh3483715)
#   SSH_PORT    (default 22)
#   REMOTE_DIR  (default htdocs, relative to your home directory; the Fasthosts web root)
#   BRANCH      (default main)
set -euo pipefail

REPO="https://github.com/atikhashmee/buypropertyinuk.git"
SSH_USER="${SSH_USER:-csh3483715}"
SSH_PORT="${SSH_PORT:-22}"
REMOTE_DIR="${REMOTE_DIR:-htdocs}"
BRANCH="${BRANCH:-main}"
: "${SSH_HOST:?Set SSH_HOST to the SSH server shown in your Fasthosts control panel}"

# Warn if what's about to deploy isn't what's on this machine.
cd "$(dirname "$0")/.."
if [ -n "$(git status --porcelain)" ]; then
  echo "Warning: uncommitted local changes will not be deployed." >&2
fi
git fetch -q origin "$BRANCH"
if [ "$(git rev-parse HEAD)" != "$(git rev-parse "origin/$BRANCH")" ]; then
  echo "Warning: local HEAD differs from origin/$BRANCH. Push first if you want it live." >&2
fi

# Runs on the server. Written for git 1.8 (CentOS 7): no `git -C`, no `init -b`.
ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" bash -s -- "$REPO" "$BRANCH" "$REMOTE_DIR" <<'REMOTE'
set -euo pipefail
REPO="$1"; BRANCH="$2"; DIR="$3"
mkdir -p "$DIR" && cd "$DIR"

if [ ! -d .git ]; then
  # First deploy: htdocs may already hold Fasthosts' placeholder page, so init in place instead of cloning.
  echo "First deploy: initialising $DIR from $REPO"
  git init -q
  git remote add origin "$REPO"
  git fetch -q origin "$BRANCH"
  git checkout -q -f -B "$BRANCH" "origin/$BRANCH"
else
  # --ff-only refuses to deploy if someone edited files on the server, instead of overwriting them.
  git pull -q --ff-only origin "$BRANCH"
fi

echo "Live: $(git log -1 --format='%h %s (%cr)')"
REMOTE
