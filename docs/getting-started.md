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

Only `--name` is required — the platform picks a default template (currently
`sb-debian-12-minimal`) and region when you omit them. Pass `--template-id` to pin
a different one.

```sh
SANDBOX_ID=$(neev-cli sandbox create --name my-first-sandbox \
  --cpu 1 --memory-gb 2 --disk-gb 10 -o json | jq -r '.id')
```

A sandbox starts `Pending`; poll `sandbox get` until it reports `Ready` before
running anything inside it. The default output is a table, so add `-o json` to
pull out a single field:

```sh
until [ "$(neev-cli sandbox get "$SANDBOX_ID" -o json | jq -r '.phase')" = "Ready" ]; do
  sleep 2
done
```

## Work inside it

Runtime commands authenticate with a sandbox API key:

```sh
export NEEV_API_KEY="your-sandbox-api-key"

# Run a command (no shell is invoked; the program follows --).
neev-cli sandbox exec "$SANDBOX_ID" -- sh -c 'echo hello'

# Write and read a workspace-relative file (fs takes --sandbox-id, not a positional id).
printf 'hi\n' | neev-cli sandbox fs write --sandbox-id "$SANDBOX_ID" --path notes.txt --in -
neev-cli sandbox fs read  --sandbox-id "$SANDBOX_ID" --path notes.txt
```

For long-running work that should outlive a single call, use `sandbox process`
(see the [command reference](command-reference.md#sandbox-process)).

## Try an AI agent

Beyond raw sandboxes, `neev-cli agent` manages first-class AI agents (e.g.
`claude-code`) backed by a sandbox:

```sh
AGENT_ID=$(neev-cli agent create --name code-helper --agent-template claude-code \
  --cpu 1 --memory-gb 2 -o json | jq -r '.id')
neev-cli agent list
neev-cli agent delete "$AGENT_ID" --yes
```

The full lifecycle — create, resolve the agent's backing sandbox, run a command
in it, resize, pause/resume, delete — is scripted in
[`examples/agent.sh`](../examples/agent.sh); see also
[`examples/sandbox.sh`](../examples/sandbox.sh) for the plain sandbox flow.

## Clean up

```sh
neev-cli sandbox pause  "$SANDBOX_ID"   # stop billable runtime, keep disks
neev-cli sandbox delete "$SANDBOX_ID" --yes
```

The full flow is scripted in
[`examples/sandbox.sh`](../examples/sandbox.sh).

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
| [Connect from Claude Desktop](claude-desktop-ssh.md) | Run Claude Code inside a sandbox over SSH |
| [`../README.md`](../README.md) | Short overview and usage snippets |
| [`../examples/`](../examples/) | Runnable end-to-end scripts |
