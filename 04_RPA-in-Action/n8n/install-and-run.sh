#!/usr/bin/env bash
# Installs n8n locally (no global install, no Docker, no account) and starts it.
# All state (n8n itself, its database, credentials) lives under ./.n8n-runtime next to
# this script, so nothing touches your global npm packages or your home directory,
# and you can wipe it completely by deleting that one folder (or running with "reset").
#
# Usage:
#   ./install-and-run.sh          # install (first run) and start n8n
#   ./install-and-run.sh reset    # wipe local n8n data (workflows/credentials) and start fresh
#
# Override the pinned version if needed:
#   N8N_VERSION=2.33.2 ./install-and-run.sh

set -euo pipefail

# Pinned to the exact version the workflows in this repo were verified against, so the
# steps in the READMEs (menus, node behavior) match what you see on screen.
N8N_VERSION="${N8N_VERSION:-2.32.6}"
MIN_NODE_MAJOR=22
MIN_NODE_MINOR_IF_SAME_MAJOR=22

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_DIR="$SCRIPT_DIR/.n8n-runtime"
DATA_DIR="$RUNTIME_DIR/data"

if [[ "${1:-}" == "reset" ]]; then
  echo "Removing local n8n data (workflows, credentials, execution history) at:"
  echo "  $DATA_DIR"
  rm -rf "$DATA_DIR"
  echo "Done. n8n itself (in .n8n-runtime/node_modules) was left in place."
fi

echo "== Checking prerequisites =="

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  cat <<'EOF'
Node.js (which includes npm) was not found on your PATH.

Install it from https://nodejs.org (the "LTS" build), or with a version manager such as
nvm (https://github.com/nvm-sh/nvm), then re-run this script.
EOF
  exit 1
fi

NODE_VERSION="$(node -v)"                     # e.g. v25.6.1
NODE_MAJOR="$(echo "$NODE_VERSION" | sed 's/^v//' | cut -d. -f1)"
NODE_MINOR="$(echo "$NODE_VERSION" | sed 's/^v//' | cut -d. -f2)"

if (( NODE_MAJOR < MIN_NODE_MAJOR )) || \
   { (( NODE_MAJOR == MIN_NODE_MAJOR )) && (( NODE_MINOR < MIN_NODE_MINOR_IF_SAME_MAJOR )); }; then
  cat <<EOF
n8n $N8N_VERSION requires Node.js >= ${MIN_NODE_MAJOR}.${MIN_NODE_MINOR_IF_SAME_MAJOR}, but this
machine has $NODE_VERSION.

Install a newer Node.js from https://nodejs.org (the "LTS" build) or via nvm:
  nvm install --lts
  nvm use --lts
then re-run this script.
EOF
  exit 1
fi

echo "Node.js $NODE_VERSION OK, npm $(npm -v) OK."

mkdir -p "$RUNTIME_DIR" "$DATA_DIR"
cd "$RUNTIME_DIR"

if [[ ! -f package.json ]]; then
  # Not `npm init -y`: it derives the package name from the directory name, and
  # ".n8n-runtime" (leading dot) is rejected by npm as an invalid package name.
  printf '{"name":"n8n-course-runtime","private":true}\n' > package.json
fi

INSTALLED_VERSION="$(node -e "try{console.log(require('./node_modules/n8n/package.json').version)}catch(e){}" 2>/dev/null || true)"

if [[ "$INSTALLED_VERSION" != "$N8N_VERSION" ]]; then
  echo "== Installing n8n $N8N_VERSION locally =="
  echo "First install can take 10-15 minutes: a couple of dependencies (isolated-vm, ssh2)"
  echo "compile native code from source and are slow even when everything works correctly."
  if ! npm install --no-fund --no-audit "n8n@${N8N_VERSION}"; then
    cat <<'EOF'

npm install failed. The most common cause is a native module (e.g. isolated-vm or ssh2)
that needs to compile from source on your machine:

  macOS:   xcode-select --install        (installs the Command Line Tools, then re-run)
  Linux:   sudo apt-get install -y build-essential python3   (Debian/Ubuntu; use your
           distro's equivalent otherwise)
  Windows: run this script from WSL instead of Git Bash (see README-setup.md)

Once the missing tool is installed, just re-run ./install-and-run.sh — npm resumes from
where it left off.
EOF
    exit 1
  fi
else
  echo "n8n $N8N_VERSION already installed, skipping."
fi

echo
echo "== Starting n8n $N8N_VERSION =="
echo "Data folder: $DATA_DIR"
echo "Once you see 'Editor is now accessible via:', open:  http://localhost:5678"
echo "Press Ctrl+C to stop."
echo

export N8N_USER_FOLDER="$DATA_DIR"
export N8N_DIAGNOSTICS_ENABLED=false
export N8N_VERSION_NOTIFICATIONS_ENABLED=false
export N8N_TEMPLATES_ENABLED=false

exec npx --no-install n8n start
