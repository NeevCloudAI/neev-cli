# neev-cli — Command Reference

Every command group, its subcommands, and the flags you'll reach for most. Run
`neev-cli <command> --help` for the authoritative, always-current flag set.

Two kinds of authentication are in play:

- **Platform commands** (`auth`, `org`, `project`, `context`, `airuntime`,
  `billing`, and sandbox **lifecycle**) use your Personal Access Token
  (`neev-cli auth login`, or `NEEV_API_TOKEN`).
- **Sandbox runtime commands** (`sandbox fs`, `sandbox exec`, `sandbox process`)
  use a **sandbox API key** — `--api-key` or `NEEV_API_KEY`.

Commands that take `--org-id` / `--project-id` fall back to the current
[context](#context) when the flags are omitted.

## Contents

- [`auth`](#auth) — sign in and out
- [`config`](#config) — persistent preferences
- [`context`](#context) — named org/project defaults
- [`org`](#org) / [`project`](#project) — browse orgs and projects
- [`billing`](#billing) — billing products
- [`airuntime`](#airuntime) — AI runtimes
- [`sandbox`](#sandbox) — sandbox lifecycle
  - [`sandbox template`](#sandbox-template)
  - [`sandbox fs`](#sandbox-fs)
  - [`sandbox exec`](#sandbox-exec)
  - [`sandbox process`](#sandbox-process)
  - [`sandbox snapshot` / `fork` / `restore`](#sandbox-snapshot-fork-restore)
  - [`sandbox metrics`](#sandbox-metrics)

---

## auth

| Command | Purpose |
| ------- | ------- |
| `auth login` | Sign in with a Personal Access Token |
| `auth status` | Show login status (exits non-zero when not authenticated) |
| `auth logout` | Clear local credentials |

```sh
neev-cli auth login                              # paste the pat-nc-… token
echo "$NEEV_API_TOKEN" | neev-cli auth login --token-stdin   # scripts/CI
neev-cli auth status
```

`--token-stdin` reads the PAT from stdin instead of prompting. There is
intentionally no `--token` flag.

## config

Persistent per-user preferences (default org/project). An explicit flag always
overrides a stored preference.

| Command | Purpose |
| ------- | ------- |
| `config set <key> <value>` | Persist a preference (keys: `org-id`, `project-id`) |
| `config get <key>` | Read one preference |
| `config show` | Show all preferences and the file path |
| `config unset <key>` | Clear one preference |

```sh
neev-cli config set org-id <org-id>
neev-cli config show
```

## context

A context is a named org + project. The current context fills in
`--org-id` / `--project-id` for any command that omits them.

| Command | Purpose |
| ------- | ------- |
| `context list` | List saved contexts and the orgs/projects you can see |
| `context set <name> <org-id> <project-id>` | Save a context and make it current |
| `context use <name>` | Switch the current context |
| `context current` | Print the current context name |
| `context delete <name>` | Delete a context |

```sh
neev-cli context set prod <org-id> <project-id>
neev-cli context use prod
```

## org

| Command | Purpose |
| ------- | ------- |
| `org list` | List organizations visible to you |
| `org get --org-id <id>` | Get one organization |

## project

| Command | Purpose |
| ------- | ------- |
| `project list --org-id <id>` | List projects in an organization |
| `project get --org-id <id> --project-id <id>` | Get one project |

## billing

| Command | Purpose |
| ------- | ------- |
| `billing products list` | List billing products |

## airuntime

Manage AI runtimes and browse runtime templates.

| Command | Purpose |
| ------- | ------- |
| `airuntime template list` / `get` | Browse the runtime template catalogue |
| `airuntime create --from-file <path>` | Create a runtime from a JSON request body |
| `airuntime list` | List runtimes in a project |
| `airuntime get --airuntime-id <id>` | Get runtime details |
| `airuntime metrics --airuntime-id <id>` | Utilization metrics |
| `airuntime delete --airuntime-id <id> --yes` | Delete a runtime |

```sh
neev-cli airuntime create --org-id <org-id> --project-id <project-id> --from-file runtime.json
neev-cli airuntime list   --org-id <org-id> --project-id <project-id>
```

## sandbox

Isolated compute environments for AI agents. Lifecycle commands use your PAT;
runtime subcommands (`fs`, `exec`, `process`) use a sandbox API key.

| Command | Purpose |
| ------- | ------- |
| `sandbox create` | Create a sandbox |
| `sandbox list` | List sandboxes (`--page`, `--limit`) |
| `sandbox get --sandbox-id <id>` | Get sandbox details |
| `sandbox pause --sandbox-id <id>` | Stop billable runtime; keep disks |
| `sandbox resume --sandbox-id <id>` | Resume a paused sandbox |
| `sandbox delete --sandbox-id <id> --yes` | Delete a sandbox |

`sandbox create` flags:

| Flag | Meaning |
| ---- | ------- |
| `--name` | Sandbox name (DNS-1123 label, ≤63 chars) |
| `--template-id` | Template id; omit for the platform default |
| `--cpu` | vCPUs (multiples of 0.5, 0.5–8) |
| `--memory-gb` | Memory in GB (1–16) |
| `--disk-gb` | Ephemeral disk in GB (multiples of 10, 10–100) |
| `--env KEY=VALUE` | Environment variable (repeatable) |
| `--from-file <path>` | Full request body as JSON (`-` for stdin); use for egress rules and other advanced fields |

```sh
neev-cli sandbox create --name my-agent --template-id sb-ubuntu-26-04-minimal \
  --cpu 1 --memory-gb 2 --disk-gb 10 --env FOO=bar
```

A sandbox starts `Pending`; poll `sandbox get` until `.phase` is `Ready` before
running anything inside it.

### sandbox template

| Command | Purpose |
| ------- | ------- |
| `sandbox template list` | List sandbox templates |
| `sandbox template get --template-id <id>` | Get one template |

### sandbox fs

File operations on a running sandbox's workspace. Paths are **workspace-relative**
(absolute paths are rejected). Needs `NEEV_API_KEY` or `--api-key`.

| Command | Key flags |
| ------- | --------- |
| `sandbox fs write` | `--path`, `--in <local\|->` (upload a file or stdin) |
| `sandbox fs read` | `--path`, `--out <local>` (default: stdout) |
| `sandbox fs list` | `--path`, `--recursive`, `--max-count` |

```sh
printf 'print("hi")\n' | neev-cli sandbox fs write --sandbox-id <id> --path main.py --in -
neev-cli sandbox fs read  --sandbox-id <id> --path main.py
neev-cli sandbox fs list  --sandbox-id <id> --path . --recursive
```

### sandbox exec

Run a command inside a running sandbox. The program and its arguments follow
`--`; no shell is invoked. Needs `NEEV_API_KEY` or `--api-key`.

| Flag | Meaning |
| ---- | ------- |
| `--stream` | Stream stdout/stderr live instead of buffering JSON |
| `-i`, `--interactive` / `-t`, `--tty` | Attach an interactive terminal (`-it`); needs a real TTY |
| `--stdin <str\|->` | Feed input to the process (`-` pipes the CLI's stdin) |
| `--cwd` | Working directory relative to the workspace root |
| `--env KEY=VALUE` | Environment variable (repeatable) |
| `--timeout-ms` | Per-call timeout (0 = server default) |

```sh
neev-cli sandbox exec --sandbox-id <id> -- ls -la /workspace          # buffered
neev-cli sandbox exec --sandbox-id <id> --stream -- python main.py     # streamed
neev-cli sandbox exec --sandbox-id <id> -it -- bash                    # interactive
```

### sandbox process

Long-running, **detached** processes that outlive the call that started them,
each addressed by a stable process id. Needs `NEEV_API_KEY` or `--api-key`.

| Command | Purpose |
| ------- | ------- |
| `sandbox process start -- program [args…]` | Start a detached process (returns `process_id`) |
| `sandbox process list` | List tracked processes |
| `sandbox process get --process-id <id>` | Status of one process |
| `sandbox process logs --process-id <id>` | Read output; `-f` to follow, `--tail N`, `--cursor` to resume |
| `sandbox process kill --process-id <id>` | Signal a process |
| `sandbox process kill-all` | Signal every running process |

```sh
PROCESS_ID=$(neev-cli sandbox process start --sandbox-id <id> -- npm run dev | jq -r '.process_id')
neev-cli sandbox process logs --sandbox-id <id> --process-id "$PROCESS_ID" -f
neev-cli sandbox process kill --sandbox-id <id> --process-id "$PROCESS_ID"
```

### sandbox snapshot, fork & restore

Capture a sandbox's state as a snapshot, then restore the same sandbox back to
it. A snapshot starts pending and must reach `Ready` before it can be restored —
poll `snapshot get`. **Fork** is separate: it branches a sandbox's *current* live
state into a brand-new sandbox, and the source keeps running.

| Command | Purpose |
| ------- | ------- |
| `sandbox snapshot create --sandbox-id <id> --name <name>` | Capture a snapshot |
| `sandbox snapshot list --sandbox-id <id>` | List a sandbox's snapshots |
| `sandbox snapshot get --snapshot-id <id>` | Get a snapshot (check `.status`) |
| `sandbox snapshot delete --snapshot-id <id>` | Delete a snapshot |
| `sandbox restore --sandbox-id <id> --snapshot-id <id>` | Restore in place |
| `sandbox fork --sandbox-id <id> --name <name>` | Fork live state into a new sandbox |

```sh
SNAPSHOT_ID=$(neev-cli sandbox snapshot create --sandbox-id <id> --name checkpoint | jq -r '.id')
until [ "$(neev-cli sandbox snapshot get --snapshot-id "$SNAPSHOT_ID" | jq -r '.status')" = "Ready" ]; do sleep 2; done
neev-cli sandbox restore --sandbox-id <id> --snapshot-id "$SNAPSHOT_ID"
neev-cli sandbox fork    --sandbox-id <id> --name my-fork
```

### sandbox metrics

```sh
neev-cli sandbox metrics --sandbox-id <id> --step 60s
```

| Flag | Meaning |
| ---- | ------- |
| `--from` / `--to` | Window bounds (RFC3339); default is the last hour |
| `--step` | Resolution, e.g. `60s`, `5m` |
