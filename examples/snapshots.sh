#!/usr/bin/env bash
#
# Snapshots: capture a sandbox, roll it back after a change, fork its current state
# into a new sandbox, and restore the snapshot into another new sandbox.
#
# Prerequisite: ./examples/quickstart.sh <org> <project>
# Requires: jq

set -euo pipefail

NAME="example-snap-$RANDOM"

neev-cli sandbox create --name "$NAME" --wait
cleanup() { neev-cli sandbox delete "$NAME" "$NAME-fork" "$NAME-restored" --yes >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "v1" | neev-cli sandbox fs write "$NAME" version.txt --in -

echo "Capturing a snapshot…"
SNAPSHOT=$(neev-cli sandbox snapshot create "$NAME" --name v1 -o json | jq -r '.id')
until [ "$(neev-cli sandbox snapshot show "$SNAPSHOT" -o json | jq -r '.status')" = "Ready" ]; do sleep 2; done
neev-cli sandbox snapshot get "$NAME"

echo "Changing the sandbox, then rolling it back…"
echo "v2" | neev-cli sandbox fs write "$NAME" version.txt --in -
neev-cli sandbox rollback "$NAME" --snapshot "$SNAPSHOT" --yes --wait
neev-cli sandbox fs read "$NAME" version.txt   # v1

echo "Forking the current state into a new sandbox…"
neev-cli sandbox fork "$NAME" --as "$NAME-fork" --wait
neev-cli sandbox fs read "$NAME-fork" version.txt

echo "Restoring the snapshot into another new sandbox…"
neev-cli sandbox create --name "$NAME-restored" --restore "$SNAPSHOT" --wait
neev-cli sandbox fs read "$NAME-restored" version.txt

echo "Done. All three sandboxes, and the snapshot, are deleted on exit."
