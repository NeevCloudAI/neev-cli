#!/usr/bin/env bash
#
# Start a detached, long-running process, follow its output until it exits, then
# inspect and clean up. Unlike `exec`, a process outlives the call that started
# it and is addressed by a stable process id.
#
# Prerequisites:
#   export NEEV_API_KEY="your-sandbox-api-key"
#   export SANDBOX_ID="<a running sandbox id>"
#
# Requires: jq

set -euo pipefail
: "${SANDBOX_ID:?set SANDBOX_ID to a running sandbox}"

echo "Starting a detached process…"
PROCESS_ID=$(neev-cli sandbox process start --sandbox-id "$SANDBOX_ID" \
  -- sh -c 'for i in 1 2 3 4 5; do echo tick $i; sleep 1; done' \
  | jq -r '.process_id')
echo "started $PROCESS_ID"

# Follow combined stdout/stderr live until the process exits.
neev-cli sandbox process logs --sandbox-id "$SANDBOX_ID" --process-id "$PROCESS_ID" -f

# List tracked processes and fetch this one's final status.
neev-cli sandbox process list --sandbox-id "$SANDBOX_ID"
neev-cli sandbox process get  --sandbox-id "$SANDBOX_ID" --process-id "$PROCESS_ID"

# Signal a process (or every process) when you need to stop it early:
#   neev-cli sandbox process kill     --sandbox-id "$SANDBOX_ID" --process-id "$PROCESS_ID"
#   neev-cli sandbox process kill-all --sandbox-id "$SANDBOX_ID"
