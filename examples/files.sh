#!/usr/bin/env bash
#
# Upload, read, and list files in a running sandbox workspace. Paths are
# workspace-relative — absolute paths are rejected.
#
# Prerequisites:
#   export NEEV_API_KEY="your-sandbox-api-key"
#   export SANDBOX_ID="<a running sandbox id>"

set -euo pipefail
: "${SANDBOX_ID:?set SANDBOX_ID to a running sandbox}"

# Upload a file. --in takes a local path, or - to read stdin.
printf 'print("hi")\n' | neev-cli sandbox fs write --sandbox-id "$SANDBOX_ID" --path main.py --in -

# Read it back to stdout (add --out ./main.py to save it locally instead).
neev-cli sandbox fs read --sandbox-id "$SANDBOX_ID" --path main.py

# List the workspace root, walking the full subtree.
neev-cli sandbox fs list --sandbox-id "$SANDBOX_ID" --path . --recursive
