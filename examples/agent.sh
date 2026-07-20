#!/usr/bin/env bash
#
# The agent resource, end to end. An agent is a managed AI agent (for example a
# claude-code agent) backed by a sandbox. This browses templates, creates one,
# lists it, resolves its backing sandbox, runs a command inside it, resizes it,
# then pauses, resumes, and deletes it.
#
# Agents are addressed by the id from 'agent list', not by name. SSH and exec
# reuse the sandbox commands with the backing sandbox id.
#
# Prerequisites:
#   ./examples/quickstart.sh <org-id> <project-id>   # sign in + set a context
#   export NEEV_API_KEY="your-sandbox-api-key"        # for exec into the backing sandbox
#
# Requires: jq

set -euo pipefail

: "${NEEV_API_KEY:?export NEEV_API_KEY (a sandbox API key) for the exec step}"

TEMPLATE="${AGENT_TEMPLATE:-claude-code}"

echo "Agent templates you can create from:"
neev-cli agent template list

echo "Creating an agent (template=$TEMPLATE)…"
# Egress is the same as sandboxes: --allow-internet or --allow <host> at create time;
# omit both to keep the template's default policy.
AGENT_ID=$(neev-cli agent create --name lifecycle-demo --agent-template "$TEMPLATE" \
  --cpu 1 --memory-gb 2 -o json | jq -r '.id')
echo "created agent $AGENT_ID"

# Always clean up, even if a later step fails.
cleanup() { neev-cli agent delete "$AGENT_ID" --yes >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "Listing agents (ID, SANDBOX_ID, NAME, STATUS)…"
neev-cli agent list

echo "Waiting until Ready, then resolving the backing sandbox…"
until [ "$(neev-cli agent get "$AGENT_ID" -o json | jq -r '.status')" = "Ready" ]; do sleep 2; done
SANDBOX_ID=$(neev-cli agent get "$AGENT_ID" -o json | jq -r '.sandbox_id')
echo "backing sandbox: $SANDBOX_ID"

echo "Running a command inside the agent (via its backing sandbox)…"
neev-cli sandbox exec "$SANDBOX_ID" -- sh -c 'echo hello from the agent'

# SSH into the agent reuses the sandbox ssh-config with the backing sandbox id:
#   neev-cli sandbox ssh-config "$SANDBOX_ID" --write   # then: ssh <printed-host-alias>

echo "Resizing the agent in place…"
neev-cli agent update "$AGENT_ID" --cpu 2 --memory-gb 4

echo "Pause and resume…"
neev-cli agent pause  "$AGENT_ID"
neev-cli agent resume "$AGENT_ID"

echo "Done — the agent is deleted on exit."
