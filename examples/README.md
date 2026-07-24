# neev-cli examples

Runnable, end-to-end scripts — one per resource — plus a quickstart that gets you
set up. Start with the quickstart; it saves a **context** (your org + project) so
every other command can drop `--org-id` / `--project-id`.

All scripts need [`jq`](https://jqlang.github.io/jq/). The ones that run *inside* a
sandbox (exec, files, processes) also need `NEEV_API_KEY` set to a sandbox API key.
Run `neev-cli <command> --help` for the full flag set of anything here.

| Script | What it does |
| ------ | ------------ |
| [`quickstart.sh`](quickstart.sh) | Check the install, sign in, save a context, and confirm it works — run this first |
| [`sandbox.sh`](sandbox.sh) | The sandbox resource end to end: create, exec, files, a background process, metrics, pause/resume, delete |
| [`agent.sh`](agent.sh) | The agent resource end to end: create a `claude-code` agent, reach its backing sandbox, resize, pause/resume, delete |
| [`airuntime.sh`](airuntime.sh) | The AI-runtime resource: browse templates, create from a request file, inspect, metrics, delete |
| [`snapshots.sh`](snapshots.sh) | Snapshot a sandbox, restore it in place, and fork its live state into a new sandbox |
| [`account.sh`](account.sh) | Browse organizations, projects, and billing products |

## Setup (once)

```sh
# 1. Sign in with a Personal Access Token (mint one in the web UI).
neev-cli auth login

# 2. Save a context — 'context set' saves it AND makes it current in one step.
#    After this, org/project are filled in automatically wherever they're needed.
neev-cli context set demo <org-id> <project-id>

# 3. A sandbox API key, for commands that run inside a sandbox (exec/fs/process).
export NEEV_API_KEY="your-sandbox-api-key"
```

`quickstart.sh` does steps 1–2 for you:

```sh
./examples/quickstart.sh <org-id> <project-id>
```

Don't know your ids? `neev-cli org list`, then `neev-cli project list --org-id <org-id>`.

## Run

Each script provisions real resources and cleans them up on exit, so the project
needs available credits.

```sh
./examples/quickstart.sh <org-id> <project-id>   # setup + a first look
./examples/sandbox.sh                            # the sandbox resource
./examples/agent.sh                              # the agent resource
./examples/snapshots.sh                          # snapshot / restore / fork
./examples/airuntime.sh                          # an AI runtime
./examples/account.sh                            # orgs, projects, billing
```

## Conventions used here

- **Context, not flags.** After `context set`/`context use`, commands read your
  org and project from the current context — the scripts don't pass `--org-id` /
  `--project-id`. (The one exception is `airuntime template`, where `--org-id`
  selects the org catalogue vs. the platform one.)
- **Positional ids.** Resources are addressed positionally:
  `neev-cli sandbox get <id>`, `agent delete <id> --yes`,
  `sandbox snapshot create <sandbox-id>`, `sandbox restore <sandbox-id> --snapshot-id <id>`.
  (`sandbox fs` and `sandbox process` are the exception — they take `--sandbox-id`.)
- **`-o json` to script.** The default output is a human-readable table; add
  `-o json` and pipe through `jq` when you need to capture an id or field.
- **`--yes` skips confirmation** on destructive commands (`-y` also works).
- **Sandbox file paths are workspace-relative** — absolute paths are rejected.

## Environment reference

| Variable | Used by | Notes |
| -------- | ------- | ----- |
| `NEEV_API_TOKEN` | lifecycle commands (via `auth login`) | Personal Access Token |
| `NEEV_API_KEY` | runtime commands (`exec`/`fs`/`process`) | a sandbox API key |
| `NEEV_ORG_ID` / `NEEV_PROJECT_ID` | `quickstart.sh` only | convenience inputs to the quickstart |
| `AGENT_TEMPLATE` | `agent.sh` | agent template id (default `claude-code`) |

## Scripting tip

Commands print a table by default and JSON with `-o json`, so they compose with
`jq`. Note the list envelope differs by resource — org/project lists use `.data[]`,
while sandbox lists use `.items[]`:

```sh
neev-cli project list -o json | jq -r '.data[].id'
neev-cli sandbox list -o json | jq -r '.items[].id'
```
