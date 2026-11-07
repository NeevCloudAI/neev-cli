#!/usr/bin/env bash
#
# Set up neev-cli: check the install, sign in, and save a context (your organization,
# project and sandbox API key) so the other examples need no extra flags.
#
# Usage:
#   ./examples/quickstart.sh <org> <project>
#
# <org> and <project> are IDs or display names. To find them, see
# https://docs.ai.neevcloud.com/getting-started/org-and-project#find-your-organization-id-and-project-id

set -euo pipefail

ORG="${1:-}"
PROJECT="${2:-}"
if [ -z "$ORG" ] || [ -z "$PROJECT" ]; then
  echo "usage: $0 <org> <project>" >&2
  echo "Sign in and run 'neev-cli context get' to see the organizations and projects you can use." >&2
  exit 2
fi

echo "1. Check the install"
neev-cli version

echo "2. Sign in with your Personal Access Token"
if ! neev-cli auth status >/dev/null 2>&1; then
  neev-cli auth login
fi

echo "3. Save a context with your sandbox API key (you'll be asked for it)"
neev-cli context set examples --org "$ORG" --project "$PROJECT" --sandbox-api-key

echo "4. Confirm it works"
neev-cli context current
neev-cli sandbox get

echo
echo "Done. Next: ./examples/sandbox.sh"
