#!/usr/bin/env bash
#
# The sandbox resource, end to end: create one, wait until it is Ready, run a
# command, write and read a workspace file, start a short background process,
# read metrics, then pause, resume, and delete it.
#
# Lifecycle commands (create/get/pause/resume/delete/metrics) use your Personal
# Access Token and read org/project from the current context. Runtime commands
# (exec/fs/process) use a sandbox API key.
#
# Prerequisites:
#   ./examples/quickstart.sh <org-id> <project-id>   # sign in + set a context
#   export NEEV_API_KEY="your-sandbox-api-key"        # for exec / fs / process
#
# Requires: jq

set -euo pipefail

: "${NEEV_API_KEY:?export NEEV_API_KEY (a sandbox API key) for the exec/fs/process steps}"

echo "Creating a sandbox (omit --template-id to use the platform default)…"
# Every resource id is addressed positionally; ids come from '-o json' since the
# default output is a human-readable table.
#
# Egress is deny-all by default. To open it (create-time only):
#   neev-cli sandbox create --name web --allow-internet
#   neev-cli sandbox create --name ci  --allow github.com --allow registry.npmjs.org
SANDBOX_ID=$(neev-cli sandbox create --name quickstart-demo -o json | jq -r '.id')
echo "created $SANDBOX_ID"

# Always clean up, even if a later step fails.
cleanup() { neev-cli sandbox delete "$SANDBOX_ID" --yes >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "Waiting until Ready…"
until [ "$(neev-cli sandbox get "$SANDBOX_ID" -o json | jq -r '.phase')" = "Ready" ]; do sleep 2; done
echo "ready"

echo "Running a command (the program follows --)…"
neev-cli sandbox exec "$SANDBOX_ID" -- sh -c 'echo hello from the sandbox; uname -a'

echo "Writing and reading a workspace file (paths are workspace-relative)…"
printf 'written by neev-cli\n' | neev-cli sandbox fs write --sandbox-id "$SANDBOX_ID" --path notes.txt --in -
neev-cli sandbox fs read --sandbox-id "$SANDBOX_ID" --path notes.txt

echo "Starting a short background process, then following its logs…"
# 'process start' puts everything after -- into the program, so -o json goes before it.
# shellcheck disable=SC2016  # $i is meant to expand in the sandbox's shell, not here
PROCESS_ID=$(neev-cli sandbox process start --sandbox-id "$SANDBOX_ID" -o json \
  -- sh -c 'for i in 1 2 3; do echo tick $i; sleep 1; done' | jq -r '.process_id')
echo "started $PROCESS_ID"
neev-cli sandbox process logs --sandbox-id "$SANDBOX_ID" --process-id "$PROCESS_ID" --follow

echo "Reading metrics (default window is the last hour)…"
neev-cli sandbox metrics "$SANDBOX_ID" --step 60s

echo "Pause and resume…"
neev-cli sandbox pause  "$SANDBOX_ID"
neev-cli sandbox resume "$SANDBOX_ID"

echo "Done — the sandbox is deleted on exit."
