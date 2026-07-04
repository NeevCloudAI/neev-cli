#!/usr/bin/env bash
#
# Read live health metrics for a sandbox. The window defaults to the last hour;
# pass --from/--to (RFC3339) to widen it and --step to change the resolution.
#
# Prerequisites:
#   neev-cli auth login
#   neev-cli context set default <org-id> <proj>
#   export SANDBOX_ID="<a sandbox id>"

set -euo pipefail
: "${SANDBOX_ID:?set SANDBOX_ID to a sandbox}"

neev-cli sandbox metrics --sandbox-id "$SANDBOX_ID" --step 60s
