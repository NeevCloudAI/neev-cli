# neev-cli — Getting Started

Install the CLI, sign in, set a default org/project, and create your first
sandbox. For a shorter overview see the [README](../README.md); for the full
command surface see the [command reference](command-reference.md).

## Prerequisites

- **macOS**, **Linux**, or **Windows**.
- A NeevCloud account, and a **Personal Access Token** minted in the web UI.
- [`jq`](https://jqlang.github.io/jq/) if you want to run the bundled
  [`examples/`](../examples/) scripts (they parse JSON output).

## Install

### macOS / Linux (any arch)

```sh
curl -fsSL https://raw.githubusercontent.com/NeevCloudAI/neev-cli/main/install.sh | sh
```

The script detects your OS and architecture, verifies the release checksum, and
installs `neev-cli` to `/usr/local/bin` (or `~/.local/bin` if that isn't
writable). Pin a version or change the location with `NEEV_CLI_VERSION` /
`NEEV_CLI_INSTALL_DIR`.

### Windows

Download `neev-cli_windows_amd64.zip` (or `arm64`) from the
[latest release](https://github.com/NeevCloudAI/neev-cli/releases/latest),
extract it, and add the folder to your `PATH`.

Confirm the install:

```sh
neev-cli version
```

## Sign in

Authenticate once with your Personal Access Token. The token is stored locally
and sent on every request.

```sh
neev-cli auth login     # paste the pat-nc-… token (hidden on a TTY)
neev-cli auth status    # confirm the session (exits non-zero when not signed in)
```

For scripts and CI, avoid the prompt — pipe the token, or set it in the
environment for a single command:

```sh
echo "$NEEV_API_TOKEN" | neev-cli auth login --token-stdin
# …or, without logging in:
export NEEV_API_TOKEN="pat-nc-…"
```

A token on a plain flag would leak into shell history and the process list, so
there is no `--token` flag by design — use the prompt, `--token-stdin`, or the
environment.

### Credentials at a glance

| Variable | Used for |
| -------- | -------- |
| `NEEV_API_TOKEN` | Your Personal Access Token, for platform commands (org, project, sandbox lifecycle, billing) |
| `NEEV_API_KEY` | A sandbox API key, for **runtime** commands (`sandbox fs`, `sandbox exec`, `sandbox process`) |

## Set a default context

Most commands take `--org-id` / `--project-id`. Save them once as a **context**
and they fall back to it, kubectl-style. An explicit flag always wins.

```sh
neev-cli context list                              # orgs/projects you can see
neev-cli context set default <org-id> <project-id> # save and make current
neev-cli sandbox list                              # now uses the default context
```

## Create your first sandbox

Only `--name` is required — the platform picks a default template and region when
you omit them. Pass `--template-id` to pin one.

```sh
neev-cli sandbox create --name my-first-sandbox \
  --template-id sb-ubuntu-26-04-minimal \
  --cpu 1 --memory-gb 2 --disk-gb 10
```

The response includes the sandbox `id` and its `phase`. A sandbox starts
`Pending`; poll `sandbox get` until it reports `Ready` before running anything
inside it:

```sh
SANDBOX_ID="<id from create>"
until [ "$(neev-cli sandbox get --sandbox-id "$SANDBOX_ID" | jq -r '.phase')" = "Ready" ]; do
  sleep 2
done
```

## Work inside it

Runtime commands authenticate with a sandbox API key:

```sh
export NEEV_API_KEY="your-sandbox-api-key"

# Run a command (no shell is invoked; the program follows --).
neev-cli sandbox exec --sandbox-id "$SANDBOX_ID" -- sh -c 'echo hello'

# Write and read a workspace-relative file.
printf 'hi\n' | neev-cli sandbox fs write --sandbox-id "$SANDBOX_ID" --path notes.txt --in -
neev-cli sandbox fs read  --sandbox-id "$SANDBOX_ID" --path notes.txt
```

For long-running work that should outlive a single call, use `sandbox process`
(see the [command reference](command-reference.md#sandbox-process)).

## Clean up

```sh
neev-cli sandbox pause  --sandbox-id "$SANDBOX_ID"   # stop billable runtime, keep disks
neev-cli sandbox delete --sandbox-id "$SANDBOX_ID" --yes
```

The full flow is scripted in
[`examples/first-sandbox.sh`](../examples/first-sandbox.sh).

## Troubleshooting

- **`auth status` exits non-zero / commands return 401** — sign in again with
  `neev-cli auth login`, or check `NEEV_API_TOKEN`.
- **Runtime commands (`fs`/`exec`/`process`) fail to authenticate** — set
  `NEEV_API_KEY` (or pass `--api-key`) to a sandbox API key.
- **A runtime command can't reach the sandbox** — make sure the sandbox is
  `Ready` (`sandbox get`), then retry; add `--refresh` to bypass the cached
  connection.
- **`--org-id and --project-id are required`** — set a default context, or pass
  the flags explicitly.

## Where to next

| Document | What you'll find |
| -------- | ---------------- |
| [Command reference](command-reference.md) | Every command group with flags and snippets |
| [`../README.md`](../README.md) | Short overview and usage snippets |
| [`../examples/`](../examples/) | Runnable end-to-end scripts |
