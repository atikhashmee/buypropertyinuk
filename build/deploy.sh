#!/usr/bin/env bash
# Deploy to Fasthosts by pushing with git over SSH.
#
# Fasthosts shared hosting has no outbound internet (it can't reach github.com), so the server
# can't pull. Instead this pushes your local branch to a bare repo on the server, and a
# post-receive hook checks it out into the web root.
#
# Usage:
#   ./build/deploy.sh   (asks for the SSH password once)
#
# Optional env:
#   SSH_HOST    (default ssh.buypropertyinuk.co.uk)
#   SSH_USER    (default csh3483715)
#   SSH_PORT    (default 1022)
#   REMOTE_DIR  (default htdocs, relative to your home directory; the Fasthosts web root)
#   BRANCH      (default main)
set -euo pipefail

SSH_HOST="${SSH_HOST:-ssh.buypropertyinuk.co.uk}"
SSH_USER="${SSH_USER:-csh3483715}"
SSH_PORT="${SSH_PORT:-1022}"  # Fasthosts: 22 is interactive-only, scripted commands must use 1022
REMOTE_DIR="${REMOTE_DIR:-htdocs}"
BRANCH="${BRANCH:-main}"
BARE_REPO="buypropertyinuk.git"  # lives in the home directory, outside the web root

cd "$(dirname "$0")/.."
if [ -n "$(git status --porcelain)" ]; then
  echo "Warning: uncommitted local changes will not be deployed." >&2
fi

# One shared SSH connection for setup and push, so the password is typed once.
SOCKET="$(mktemp -u /tmp/deploy-ssh.XXXXXX)"
SSH_CMD="ssh -p $SSH_PORT -o ControlPath=$SOCKET"
$SSH_CMD -o ControlMaster=yes -o ControlPersist=120 -fN "$SSH_USER@$SSH_HOST"
trap '$SSH_CMD -O exit "$SSH_USER@$SSH_HOST" 2>/dev/null || true' EXIT

# Server setup, safe to repeat. Written for git 1.8 (CentOS 7).
$SSH_CMD "$SSH_USER@$SSH_HOST" bash -s -- "$BARE_REPO" "$REMOTE_DIR" "$BRANCH" <<'REMOTE'
set -euo pipefail
REPO="$HOME/$1"; WEB="$HOME/$2"; BRANCH="$3"

[ -d "$REPO" ] || git init -q --bare "$REPO"
mkdir -p "$WEB"

# Remove the empty repo left in the web root by the earlier pull-based attempt (only if it has no commits).
if [ -d "$WEB/.git" ] && ! git --git-dir="$WEB/.git" rev-parse -q --verify HEAD >/dev/null; then
  rm -rf "$WEB/.git"
fi

cat > "$REPO/hooks/post-receive" <<HOOK
#!/bin/bash
while read old new ref; do
  [ "\$ref" = "refs/heads/$BRANCH" ] || continue
  git --git-dir="$REPO" --work-tree="$WEB" checkout -q -f "$BRANCH"
  echo "Live: \$(git --git-dir="$REPO" log -1 --format='%h %s (%cr)' "$BRANCH")"
done
HOOK
chmod +x "$REPO/hooks/post-receive"
REMOTE

GIT_SSH_COMMAND="$SSH_CMD" git push "ssh://$SSH_USER@$SSH_HOST:$SSH_PORT/~/$BARE_REPO" "$BRANCH:$BRANCH"
