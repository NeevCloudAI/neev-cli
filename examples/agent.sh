#!/usr/bin/env bash
#
# An agent end to end: pick an agent template, create a Claude Code agent, work inside
# it, check its network access, resize it, pause and resume it, then delete it.
#
# Prerequisite: ./examples/quickstart.sh <org> <project>
#
# Set AGENT_TEMPLATE to try another agent (see 'neev-cli agent template get').

set -euo pipefail

TEMPLATE="${AGENT_TEMPLATE:-claude-code}"
NAME="example-agent-$RANDOM"

echo "Agent templates:"
neev-cli agent template get

echo "Creating $NAME from ${TEMPLATE}…"
neev-cli agent create --name "$NAME" --agent-template "$TEMPLATE" --wait
trap 'neev-cli agent delete "$NAME" --yes >/dev/null 2>&1 || true' EXIT

echo "Working inside the agent…"
neev-cli agent exec "$NAME" -- sh -c 'uname -sr; ls /workspace'
echo 'Build a small CLI that prints the weather.' | neev-cli agent fs write "$NAME" TASK.md --in -

echo "Hosts the template allows:"
neev-cli agent egress get "$NAME"

echo "Resizing in place…"
neev-cli agent update "$NAME" --cpu 2 --memory-gb 4

echo "Pausing and resuming…"
neev-cli agent pause "$NAME" --wait
neev-cli agent resume "$NAME" --wait

echo "For an interactive session, run: neev-cli agent exec $NAME -it -- claude"
echo "Done. $NAME is deleted on exit."
