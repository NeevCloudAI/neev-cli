#!/usr/bin/env bash
#
# Set up neev-cli and confirm it works: check the install, sign in, save a
# context, and list a couple of resources. Run this once — the other example
# scripts assume a context is set, so they can omit --org-id / --project-id.
#
# Usage:
#   ./examples/quickstart.sh <org-id> <project-id>
#   # …or set them in the environment:
#   NEEV_ORG_ID=… NEEV_PROJECT_ID=… ./examples/quickstart.sh
#
# Prerequisites: neev-cli installed (see the README) and a Personal Access Token.

set -euo pipefail

ORG_ID="${1:-${NEEV_ORG_ID:-}}"
PROJECT_ID="${2:-${NEEV_PROJECT_ID:-}}"
if [ -z "$ORG_ID" ] || [ -z "$PROJECT_ID" ]; then
  echo "usage: $0 <org-id> <project-id>   (or set NEEV_ORG_ID / NEEV_PROJECT_ID)" >&2
  echo "tip: 'neev-cli org list' and 'neev-cli project list --org-id <org-id>' list the ids." >&2
  exit 2
fi

echo "1. Check the install"
neev-cli version

echo "2. Sign in (paste your Personal Access Token when prompted)"
# Skip the prompt if a valid session already exists.
if ! neev-cli auth status >/dev/null 2>&1; then
  neev-cli auth login
fi
neev-cli auth status

echo "3. Save a context — 'context set' saves it AND makes it current in one step"
neev-cli context set demo "$ORG_ID" "$PROJECT_ID"
neev-cli context current

echo "4. Confirm it works — these read org/project from the context, no flags needed"
neev-cli project list
neev-cli sandbox list

echo
echo "Done. The 'demo' context is active, so the other examples can drop --org-id/--project-id."
echo "Next: ./examples/sandbox.sh"
