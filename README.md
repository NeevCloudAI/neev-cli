# neev-cli

> Official command-line interface for the **NeevCloud AI platform** — manage your cloud from the terminal.

`neev-cli` is the single, growing CLI for the **NeevCloud AI platform**. One
binary, one login, one command tree — reach for new capabilities as they ship.

**What you can do today**

- **`neev-cli sandbox`** — the full agent-sandbox lifecycle: create, list, get,
  pause, resume, delete, and live metrics, plus snapshots, restore, and fork.
  Inside a running sandbox: `fs` (read/write/list files), `exec` (run a command,
  buffered, streamed, or interactive), and a `process` supervisor for
  long-running, detached work. Sandboxes are isolated compute environments for
  AI agents.
- **`neev-cli sandbox template`** — the platform sandbox-template catalogue
  (list, get). A template id (e.g. `sb-ubuntu-26-04-minimal`) is optional when
  creating a sandbox; omit it to use the platform default.
- **`neev-cli org` / `project` / `context`** — browse organizations and
  projects, and save a default org/project so you can drop the flags.
- **`neev-cli airuntime`** — manage AI runtimes (create, list, get, metrics,
  delete) and browse runtime templates.
- **`neev-cli billing`** — billing product operations.

This repository distributes the prebuilt `neev-cli` binaries and the installer.
See [Releases](https://github.com/NeevCloudAI/neev-cli/releases) for downloads
and changelogs.

---

## Install

### Quick install (macOS / Linux, any arch)

```sh
curl -fsSL https://raw.githubusercontent.com/NeevCloudAI/neev-cli/main/install.sh | sh
```

The script detects your OS and architecture, downloads the matching release
archive, verifies its checksum, and installs `neev-cli` to `/usr/local/bin` (or
`~/.local/bin` if that isn't writable).

Pin a specific version, or change the install location:

```sh
curl -fsSL https://raw.githubusercontent.com/NeevCloudAI/neev-cli/main/install.sh | NEEV_CLI_VERSION=v0.1.0 sh
curl -fsSL https://raw.githubusercontent.com/NeevCloudAI/neev-cli/main/install.sh | NEEV_CLI_INSTALL_DIR="$HOME/bin" sh
```

### Manual download

Grab the archive for your platform from the [latest release](https://github.com/NeevCloudAI/neev-cli/releases/latest),
verify it against `checksums.txt`, extract, and move `neev-cli` onto your `PATH`:

```sh
tar -xzf neev-cli_darwin_arm64.tar.gz
sudo mv neev-cli /usr/local/bin/
```

### Windows

Download `neev-cli_windows_amd64.zip` (or `arm64`) from the [latest release](https://github.com/NeevCloudAI/neev-cli/releases/latest),
extract it, and add the folder to your `PATH`.

## Authentication

Sign in once with a **Personal Access Token** (mint one in the web UI). The
token is stored locally and sent on every request:

```sh
neev-cli auth login          # paste the pat-nc-… token (input is hidden on a TTY)
neev-cli auth status         # confirm the active session (exits non-zero if not signed in)
neev-cli auth logout         # clear the local session
```

For scripts and CI, avoid the interactive prompt:

```sh
# Pipe the token into login…
echo "$NEEV_API_TOKEN" | neev-cli auth login --token-stdin

# …or skip login entirely and authenticate a single command via the environment.
export NEEV_API_TOKEN="pat-nc-…"
neev-cli org list
```

Never pass a token as a plain flag — it would leak into shell history and the
process list. Use the prompt, `--token-stdin`, or the environment.

**Sandbox runtime commands** (`sandbox fs`, `sandbox exec`, `sandbox process`)
act inside a running sandbox and authenticate with a **sandbox API key**, passed
with `--api-key` or the `NEEV_API_KEY` environment variable:

```sh
export NEEV_API_KEY="your-sandbox-api-key"
```

## Quickstart

```sh
# 1. Sign in.
neev-cli auth login

# 2. Save a default org + project so later commands can omit the flags.
neev-cli context list                                   # discover your orgs/projects
neev-cli context set default <org-id> <project-id>      # save and make it current

# 3. Create a sandbox from a template.
neev-cli sandbox create --name my-agent --template-id sb-ubuntu-26-04-minimal \
  --cpu 1 --memory-gb 2 --disk-gb 10

# 4. Run a command inside it (needs NEEV_API_KEY set).
neev-cli sandbox exec --sandbox-id <sandbox-id> -- echo "hello from the sandbox"

# 5. Pause when idle, resume on demand, delete when done.
neev-cli sandbox pause  --sandbox-id <sandbox-id>
neev-cli sandbox resume --sandbox-id <sandbox-id>
neev-cli sandbox delete --sandbox-id <sandbox-id> --yes
```

Every command supports `--help`; append it to any command or subcommand for the
full flag set. See [`examples/`](examples/) for copy-pasteable end-to-end flows.

## Usage

### Default org/project context

Most commands take `--org-id` / `--project-id`. Save a **context** once and they
fall back to it, kubectl-style. An explicit flag always wins.

```sh
neev-cli context list                              # orgs/projects you can see, plus saved contexts
neev-cli context set prod <org-id> <project-id>    # save "prod" and make it current
neev-cli context current                           # print the current context name
neev-cli context use prod                          # switch between saved contexts
```

### Sandboxes

```sh
neev-cli sandbox create --name my-agent --template-id sb-ubuntu-26-04-minimal \
  --cpu 1 --memory-gb 2 --disk-gb 10 --env FOO=bar
neev-cli sandbox list --limit 50
neev-cli sandbox get     --sandbox-id <sandbox-id>
neev-cli sandbox pause   --sandbox-id <sandbox-id>   # stop billable runtime; keep disks
neev-cli sandbox resume  --sandbox-id <sandbox-id>
neev-cli sandbox delete  --sandbox-id <sandbox-id> --yes
neev-cli sandbox metrics --sandbox-id <sandbox-id> --step 60s   # live health metrics
```

For sandboxes that need egress rules or other advanced fields, pass the full
request body instead of the convenience flags:

```sh
neev-cli sandbox create --from-file ./sandbox.json     # or --from-file - to read stdin
```

### Templates

`--template-id` is optional — omit it to use the platform default, pass a known
id, or browse the catalogue first:

```sh
neev-cli sandbox template list
neev-cli sandbox template get --template-id sb-ubuntu-26-04-minimal
```

### Files

Runtime file operations act on a sandbox workspace. Paths are workspace-relative.
Set `NEEV_API_KEY` (or pass `--api-key`) first.

```sh
# Upload a local file (or --in - to read stdin).
neev-cli sandbox fs write --sandbox-id <sandbox-id> --path main.py --in ./main.py

# Read it back to stdout (or --out ./local.py to save it).
neev-cli sandbox fs read  --sandbox-id <sandbox-id> --path main.py

# List a directory (add --recursive to walk the subtree).
neev-cli sandbox fs list  --sandbox-id <sandbox-id> --path . --recursive
```

### Running commands

`sandbox exec` runs a command inside a running sandbox. The program and its
arguments follow `--`; no shell is invoked, so the program runs directly with its
argument vector.

```sh
# Buffered: run to completion, print captured output as JSON.
neev-cli sandbox exec --sandbox-id <sandbox-id> -- ls -la /workspace

# Streamed: see stdout/stderr live as the command produces it.
neev-cli sandbox exec --sandbox-id <sandbox-id> --stream -- python main.py

# Interactive (kubectl exec -it style): attach your terminal to the program.
neev-cli sandbox exec --sandbox-id <sandbox-id> -it -- bash
```

`-it` needs a real terminal on stdin and forwards resizes and Ctrl-C. Feed input
to a non-interactive run with `--stdin` (use `-` to pipe the CLI's own stdin).

### Long-running processes

`exec` ties a command's lifetime to your call. For background work that should
outlive a single call — a dev server, a build, a watcher — use `sandbox process`.
The supervisor runs it detached, addressed by a stable process id.

```sh
# Start a detached process; the id is returned.
neev-cli sandbox process start --sandbox-id <sandbox-id> --cwd app -- npm run dev

# Follow its combined output live, or read the last N lines.
neev-cli sandbox process logs --sandbox-id <sandbox-id> --process-id <process-id> -f
neev-cli sandbox process logs --sandbox-id <sandbox-id> --process-id <process-id> --tail 100

# Inspect, list, and signal.
neev-cli sandbox process get      --sandbox-id <sandbox-id> --process-id <process-id>
neev-cli sandbox process list     --sandbox-id <sandbox-id>
neev-cli sandbox process kill     --sandbox-id <sandbox-id> --process-id <process-id>
neev-cli sandbox process kill-all --sandbox-id <sandbox-id>
```

Output is captured in a bounded ring; `logs` prints from a resumable cursor, and
`-f` streams until the process exits.

### Snapshots, fork & restore

Capture a sandbox's state as a **snapshot**, then **restore** the same sandbox
back to it. A snapshot is created pending and must become Ready before you can
restore from it — poll `snapshot get`. **Fork** is separate: it branches a
sandbox's *current* live state into a brand-new sandbox, and the source keeps
running.

```sh
# Capture a snapshot, then watch it become Ready.
neev-cli sandbox snapshot create --sandbox-id <sandbox-id> --name checkpoint
neev-cli sandbox snapshot list   --sandbox-id <sandbox-id>
neev-cli sandbox snapshot get    --snapshot-id <snapshot-id>

# Restore the original in place once the snapshot is Ready.
neev-cli sandbox restore --sandbox-id <sandbox-id> --snapshot-id <snapshot-id>

# Fork the current live state into a new sandbox (no snapshot needed).
neev-cli sandbox fork --sandbox-id <sandbox-id> --name my-fork
```

### JSON output & scripting

Commands print JSON to stdout, so they compose with [`jq`](https://jqlang.github.io/jq/):

```sh
neev-cli sandbox list | jq -r '.data[].id'
```

## Documentation

Guides and reference live in [`docs/`](docs/):

- [Getting started](docs/getting-started.md) — install, sign in, first sandbox
- [Command reference](docs/command-reference.md) — grouped commands + snippets

Full platform documentation: <https://docs.neevcloud.com>.

## Support & issues

- **API documentation:** <https://docs.neevcloud.com>
- **Bugs / feature requests:** open an issue on this repository.

## License

[Apache-2.0](LICENSE).
