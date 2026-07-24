#!/usr/bin/env bash
#
# Browse account resources: organizations, projects, and billing products.
# With a context set, the org/project commands need no flags.
#
# Prerequisites:
#   ./examples/quickstart.sh <org-id> <project-id>

set -euo pipefail

echo "Organizations you can see:"
neev-cli org list

echo
echo "Projects in the current context's org:"
# 'project list' reads --org-id from the context.
neev-cli project list

echo
echo "Billing products:"
neev-cli billing products list

echo
echo "Switch org/project sets with named contexts:"
echo "  neev-cli context set staging <org-id> <project-id>   # save + activate"
echo "  neev-cli context use demo                            # switch back"
echo "  neev-cli context list                                # see them all"
