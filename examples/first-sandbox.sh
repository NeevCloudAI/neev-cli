#!/usr/bin/env bash
#
# Create a sandbox, wait until it is Ready, run a command, write and read a
# file, then delete it — the CLI equivalent of a "hello world".
#
# Prerequisites:
#   neev-cli auth login                            # sign in once
#   neev-cli context set default <org-id> <proj>   # default org/project for lifecycle commands
#   export NEEV_API_KEY="your-sandbox-api-key"     # auth for fs/exec (runtime commands)
#
# Requires: jq (https://jqlang.github.io/jq/)

set -euo pipefail

TEMPLATE="${TEMPLATE:-sb-ubuntu-26-04-minimal}"

echo "Creating sandbox…"
SANDBOX_ID=$(neev-cli sandbox create \
  --name quickstart-demo \
  --template-id "$TEMPLATE" \
  --cpu 1 --memory-gb 2 --disk-gb 10 \
  | jq -r '.id')
echo "created $SANDBOX_ID"

# Always clean the sandbox up, even if a later step fails.
cleanup() { neev-cli sandbox delete --sandbox-id "$SANDBOX_ID" --yes >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "Waiting until Ready…"
until [ "$(neev-cli sandbox get --sandbox-id "$SANDBOX_ID" | jq -r '.phase')" = "Ready" ]; do
  sleep 2
done
echo "ready"

echo "Running a command…"
neev-cli sandbox exec --sandbox-id "$SANDBOX_ID" -- sh -c 'echo hello from the sandbox'

echo "Writing and reading a file (paths are workspace-relative)…"
printf 'written by neev-cli\n' | neev-cli sandbox fs write --sandbox-id "$SANDBOX_ID" --path notes.txt --in -
neev-cli sandbox fs read --sandbox-id "$SANDBOX_ID" --path notes.txt

echo "Done — the sandbox is deleted on exit."
