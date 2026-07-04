#!/usr/bin/env bash
#
# Capture a snapshot of a sandbox, wait until it is Ready, restore the sandbox
# in place from it, and separately fork the sandbox's current live state into a
# brand-new sandbox.
#
# Prerequisites:
#   neev-cli auth login
#   neev-cli context set default <org-id> <proj>
#   export SANDBOX_ID="<a running sandbox id>"
#
# Requires: jq

set -euo pipefail
: "${SANDBOX_ID:?set SANDBOX_ID to a running sandbox}"

echo "Capturing a snapshot…"
SNAPSHOT_ID=$(neev-cli sandbox snapshot create --sandbox-id "$SANDBOX_ID" --name checkpoint | jq -r '.id')
echo "snapshot $SNAPSHOT_ID"

# A snapshot starts pending and must reach Ready before it can be restored.
echo "Waiting until the snapshot is Ready…"
until [ "$(neev-cli sandbox snapshot get --snapshot-id "$SNAPSHOT_ID" | jq -r '.status')" = "Ready" ]; do
  sleep 2
done
echo "snapshot ready"

# Restore the original sandbox in place from the snapshot.
echo "Restoring in place…"
neev-cli sandbox restore --sandbox-id "$SANDBOX_ID" --snapshot-id "$SNAPSHOT_ID"

# Fork branches the current live state into a new sandbox; the source keeps
# running and no snapshot is consumed.
echo "Forking current live state…"
FORK_ID=$(neev-cli sandbox fork --sandbox-id "$SANDBOX_ID" --name my-fork | jq -r '.id')
echo "forked into $FORK_ID"

# List and prune snapshots when you no longer need them:
#   neev-cli sandbox snapshot list   --sandbox-id "$SANDBOX_ID"
#   neev-cli sandbox snapshot delete --snapshot-id "$SNAPSHOT_ID"
