#!/usr/bin/env bash
# Deploy the static site to Fasthosts (CentOS 7 shared hosting) over SSH.
# Static HTML/CSS/JS only, so nothing (Node, npm) is needed on the server.
#
# Usage:
#   SSH_HOST=ssh.yourdomain.co.uk ./build/deploy.sh            # upload changed files
#   SSH_HOST=ssh.yourdomain.co.uk ./build/deploy.sh --dry-run  # list what would change
#   SSH_HOST=ssh.yourdomain.co.uk ./build/deploy.sh --delete   # also remove remote files not in the site
#
# Optional env:
#   SSH_USER    (default csh3483715)
#   SSH_PORT    (default 22)
#   REMOTE_DIR  (default htdocs, relative to your home directory; the Fasthosts web root)
#
# The SSH password is asked for once per run and never stored.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/build/dist"
SSH_USER="${SSH_USER:-csh3483715}"
SSH_PORT="${SSH_PORT:-22}"
REMOTE_DIR="${REMOTE_DIR:-htdocs}"
: "${SSH_HOST:?Set SSH_HOST to the SSH server shown in your Fasthosts control panel}"

RSYNC_FLAGS=(-rlvz --checksum --chmod=D755,F644 --exclude .DS_Store)
for arg in "$@"; do
  case "$arg" in
    --dry-run) RSYNC_FLAGS+=(--dry-run) ;;
    --delete)  RSYNC_FLAGS+=(--delete) ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

# Stage only the files the site needs.
rm -rf "${DIST:?}"
mkdir -p "$DIST"
cp "$ROOT/index.html" "$ROOT/styles.css" "$ROOT/main.js" "$DIST/"
cp -R "$ROOT/assets" "$DIST/"
echo "Staged $(find "$DIST" -type f ! -name .DS_Store | wc -l | tr -d ' ') files in build/dist"

# One shared SSH connection, so the password is typed once.
SOCKET="$(mktemp -u /tmp/deploy-ssh.XXXXXX)"
SSH=(ssh -p "$SSH_PORT" -o ControlPath="$SOCKET")
"${SSH[@]}" -o ControlMaster=yes -o ControlPersist=120 -fN "$SSH_USER@$SSH_HOST"
trap '"${SSH[@]}" -O exit "$SSH_USER@$SSH_HOST" 2>/dev/null || true' EXIT

"${SSH[@]}" "$SSH_USER@$SSH_HOST" "mkdir -p '$REMOTE_DIR'"

if "${SSH[@]}" "$SSH_USER@$SSH_HOST" "command -v rsync >/dev/null"; then
  rsync "${RSYNC_FLAGS[@]}" -e "${SSH[*]}" "$DIST/" "$SSH_USER@$SSH_HOST:$REMOTE_DIR/"
else
  # ponytail: scp fallback re-uploads everything and ignores --dry-run/--delete; fine for a small static site.
  echo "rsync not found on server, falling back to scp (full upload)"
  scp -P "$SSH_PORT" -o ControlPath="$SOCKET" -r "$DIST"/. "$SSH_USER@$SSH_HOST:$REMOTE_DIR/"
fi

echo "Deployed to $SSH_USER@$SSH_HOST:~/$REMOTE_DIR"
