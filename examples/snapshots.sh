#!/usr/bin/env bash
#
# Snapshot, restore, and fork a sandbox. A snapshot captures a sandbox's state;
# restore rolls the same sandbox back to it; fork branches the live state into a
# brand-new sandbox while the source keeps running.
#
# Prerequisites:
#   ./examples/quickstart.sh <org-id> <project-id>
#   export NEEV_API_KEY="your-sandbox-api-key"   # to write the marker file
#
# Requires: jq

set -euo pipefail

: "${NEEV_API_KEY:?export NEEV_API_KEY (a sandbox API key) for the fs step}"

echo "Creating a source sandbox…"
SANDBOX_ID=$(neev-cli sandbox create --name snapshot-demo -o json | jq -r '.id')
FORK_ID=""

# Clean up the source and, if we got that far, the fork.
cleanup() {
  neev-cli sandbox delete "$SANDBOX_ID" --yes >/dev/null 2>&1 || true
  [ -n "$FORK_ID" ] && neev-cli sandbox delete "$FORK_ID" --yes >/dev/null 2>&1 || true
}
trap cleanup EXIT

until [ "$(neev-cli sandbox get "$SANDBOX_ID" -o json | jq -r '.phase')" = "Ready" ]; do sleep 2; done

echo "Writing a marker file so the snapshot is distinguishable…"
printf 'captured-at-snapshot\n' | neev-cli sandbox fs write --sandbox-id "$SANDBOX_ID" --path marker.txt --in -

echo "Creating a snapshot, then waiting until it is Ready…"
# snapshot create takes the sandbox id positionally; snapshot get takes the snapshot id.
SNAPSHOT_ID=$(neev-cli sandbox snapshot create "$SANDBOX_ID" --name checkpoint -o json | jq -r '.id')
until [ "$(neev-cli sandbox snapshot get "$SNAPSHOT_ID" -o json | jq -r '.status')" = "Ready" ]; do sleep 2; done
echo "snapshot $SNAPSHOT_ID ready"

echo "Snapshots for this sandbox:"
neev-cli sandbox snapshot list "$SANDBOX_ID"

echo "Restoring the source sandbox in place…"
neev-cli sandbox restore "$SANDBOX_ID" --snapshot-id "$SNAPSHOT_ID"

echo "Forking the live state into a new sandbox…"
FORK_ID=$(neev-cli sandbox fork "$SANDBOX_ID" --name snapshot-demo-fork -o json | jq -r '.id')
echo "forked $FORK_ID"

echo "Done — both sandboxes are deleted on exit."
