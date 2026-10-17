#!/usr/bin/env bash
#
# A sandbox end to end: create it, run commands, move files in and out, read its
# metrics, pause and resume it, then delete it.
#
# Prerequisite: ./examples/quickstart.sh <org> <project>

set -euo pipefail

NAME="example-sandbox-$RANDOM"

echo "Creating ${NAME}…"
neev-cli sandbox create --name "$NAME" --template-id sb-ubuntu-26-04-dev --wait
trap 'neev-cli sandbox delete "$NAME" --yes >/dev/null 2>&1 || true' EXIT

echo "Running commands (everything after -- runs in the sandbox)…"
neev-cli sandbox exec "$NAME" -- python3 -c 'print(6 * 7)'
neev-cli sandbox exec "$NAME" -- sh -c 'uname -sr && python3 --version'

echo "Writing and reading a file…"
echo 'hello from NeevCloud' | neev-cli sandbox fs write "$NAME" hello.txt --in -
neev-cli sandbox fs read "$NAME" hello.txt

echo "Copying a directory in, using it, and copying the result out…"
WORK=$(mktemp -d)
mkdir -p "$WORK/app"
printf 'import json\nprint(json.dumps({"sum": sum(range(10))}))\n' > "$WORK/app/main.py"
neev-cli sandbox fs upload "$NAME" "$WORK/app" /workspace/app
neev-cli sandbox exec "$NAME" --cwd app -- sh -c 'python3 main.py > result.json'
neev-cli sandbox fs download "$NAME" /workspace/app/result.json "$WORK/result.json"
cat "$WORK/result.json"
neev-cli sandbox fs get "$NAME" app

echo "Reading metrics for the last hour…"
neev-cli sandbox metrics "$NAME" --step 60s

echo "Pausing and resuming (files are kept)…"
neev-cli sandbox pause "$NAME" --wait
neev-cli sandbox resume "$NAME" --wait
neev-cli sandbox fs read "$NAME" hello.txt

echo "Done. $NAME is deleted on exit."
