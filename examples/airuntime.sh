#!/usr/bin/env bash
#
# The AI-runtime resource, end to end: browse the template catalogue, create a
# runtime from a request file, inspect it, read metrics, then delete it.
#
# Uses your Personal Access Token and reads org/project from the current context.
#
# Prerequisites:
#   ./examples/quickstart.sh <org-id> <project-id>
#
# Requires: jq

set -euo pipefail

echo "Runtime templates on the platform catalogue:"
# For 'airuntime template', --org-id is a mode switch (omit = platform catalogue,
# set = an org's catalogue), so it is NOT auto-filled from the context.
neev-cli airuntime template list

# Fill in real values before running:
#   templateID   from 'airuntime template list'
#   gpuConfigID  a UUID from the inventory API / console
#   planId       a plan you can access (e.g. gpu-h200-on-demand-1h)
# Optional: add "sshKeys": ["ssh-ed25519 AAAA... you@host"] for SSH access.
# storage is optional — omit it to use the free 100 GB network volume.
REQ=$(mktemp)
cat > "$REQ" <<'JSON'
{
  "name": "quickstart-jupyter",
  "region": "as-south-1",
  "templateID": "tpl-jupyterlab-pytorch",
  "gpuConfigID": "REPLACE_WITH_GPU_CONFIG_ID",
  "gpuCount": 1,
  "planId": "gpu-h200-on-demand-1h"
}
JSON

echo "Creating a runtime from the request file…"
AIRUNTIME_ID=$(neev-cli airuntime create --from-file "$REQ" -o json | jq -r '.id')
echo "created runtime $AIRUNTIME_ID"

# Always clean up the runtime and the temp file.
cleanup() {
  neev-cli airuntime delete "$AIRUNTIME_ID" --yes >/dev/null 2>&1 || true
  rm -f "$REQ"
}
trap cleanup EXIT

echo "Inspecting the runtime and reading its metrics…"
neev-cli airuntime get     "$AIRUNTIME_ID"
neev-cli airuntime metrics "$AIRUNTIME_ID"

echo "Done — the runtime is deleted on exit."
