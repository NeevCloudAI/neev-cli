#!/usr/bin/env bash
#
# Networking: serve an app from a sandbox at a public preview URL, then control which
# hosts the sandbox can reach.
#
# Prerequisite: ./examples/quickstart.sh <org> <project>

set -euo pipefail

NAME="example-net-$RANDOM"

echo "Creating $NAME with egress to pypi.org only…"
neev-cli sandbox create --name "$NAME" --allow pypi.org:443 --wait
trap 'neev-cli sandbox delete "$NAME" --yes >/dev/null 2>&1 || true' EXIT

echo "Starting a web server in the background…"
neev-cli sandbox exec "$NAME" -- sh -c 'echo "<h1>Hello from NeevCloud</h1>" > index.html'
neev-cli sandbox exec "$NAME" -- sh -c 'nohup python3 -m http.server 3000 >/dev/null 2>&1 &'

echo "Exposing port 3000 and waiting until the app answers…"
neev-cli sandbox port create "$NAME" --port 3000 --wait
URL=$(neev-cli sandbox port get "$NAME" -o json | jq -r '.items[0].preview_url')
curl -fsS "$URL"

echo "Egress rules:"
neev-cli sandbox egress get "$NAME"

echo "pypi.org is allowed, github.com is not…"
for host in pypi.org github.com; do
  if neev-cli sandbox exec "$NAME" -- curl -fsS -m 5 -o /dev/null "https://$host/" >/dev/null 2>&1; then
    echo "$host: reachable"
  else
    echo "$host: blocked"
  fi
done

echo "Adding github.com to the allow-list, keeping pypi.org…"
neev-cli sandbox update "$NAME" --allow-add github.com
neev-cli sandbox egress get "$NAME"

echo "Closing the preview URL…"
neev-cli sandbox port delete "$NAME" --port 3000 --yes

echo "Done. $NAME is deleted on exit."
