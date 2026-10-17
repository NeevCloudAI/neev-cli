#!/usr/bin/env bash
#
# An AI runtime: browse runtime templates and plans, create a runtime from a request
# file, inspect it, read its metrics, then delete it.
#
# This creates a billed GPU runtime. Fill in the region, GPU configuration and plan
# below before you run it.
#
# Prerequisite: ./examples/quickstart.sh <org> <project>
# Requires: jq

set -euo pipefail

echo "Runtime templates:"
neev-cli airuntime template get

echo "Plans and prices:"
neev-cli billing products get

REQUEST=$(mktemp)
cat > "$REQUEST" <<'JSON'
{
  "name": "example-notebook",
  "region": "REPLACE_WITH_REGION",
  "templateID": "tpl-jupyterlab-pytorch",
  "gpuConfigID": "REPLACE_WITH_GPU_CONFIG_ID",
  "gpuCount": 1,
  "planId": "REPLACE_WITH_PLAN_ID"
}
JSON

echo "Creating the runtime…"
ID=$(neev-cli airuntime create --filename "$REQUEST" -o json | jq -r '.id')
cleanup() { neev-cli airuntime delete "$ID" --yes >/dev/null 2>&1 || true; rm -f "$REQUEST"; }
trap cleanup EXIT

neev-cli airuntime get "$ID"
neev-cli airuntime metrics "$ID"

echo "Done. The runtime is deleted on exit."
