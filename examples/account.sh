#!/usr/bin/env bash
#
# Your account: organizations, projects, pricing, and switching between contexts.
#
# Prerequisite: neev-cli auth login

set -euo pipefail

echo "Organizations:"
neev-cli org get

echo
echo "Projects in the current organization:"
neev-cli project get

echo
echo "Products and prices:"
neev-cli billing products get

echo
neev-cli context get

cat <<'TIP'

Work in several projects by saving a context for each and switching:
  neev-cli context set staging --org <org> --project <project>
  neev-cli context use examples
TIP
