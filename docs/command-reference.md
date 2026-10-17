# Command reference

Every `neev-cli` command, grouped by product, with its flags and examples. For a guided
tour, see the product guides ([Sandboxes](./sandboxes.md), [Agents](./agents.md),
[AI runtimes](./ai-runtimes.md)); to get set up, see
[Getting started](./getting-started.md). `neev-cli <command> --help` prints the same
information in your terminal.

## Contents

- [How commands are shaped](#how-commands-are-shaped)
- [Flags on every command](#flags-on-every-command)
- [Sandboxes](#sandboxes)
  - [Sandbox lifecycle](#sandbox-lifecycle): `create`, `get`, `describe`, `update`, `pause`, `resume`, `delete`
  - [`sandbox template get`](#sandbox-template-get)
  - [`sandbox exec`](#sandbox-exec)
  - [`sandbox fs`](#sandbox-fs): `read`, `write`, `get`, `upload`, `download`
  - [`sandbox port`](#sandbox-port): `create`, `get`, `delete`
  - [`sandbox egress get`](#sandbox-egress-get)
  - [`sandbox proxy`](#sandbox-proxy)
  - [`sandbox ssh-config`](#sandbox-ssh-config): `write`, `get`, `delete`
  - [`sandbox snapshot`](#sandbox-snapshot): `create`, `get`, `show`, `delete`
  - [`sandbox rollback`](#sandbox-rollback) and [`sandbox fork`](#sandbox-fork)
  - [`sandbox metrics`](#sandbox-metrics)
- [Agents](#agents)
- [AI runtimes](#ai-runtimes)
- [Account](#account): `org`, `project`, `billing`
- [Setup](#setup): `auth`, `context`, `config`, `completion`, `version`
- [Environment variables](#environment-variables)

## How commands are shaped

```
neev-cli <product> <verb> [NAME...] [flags]
neev-cli <product> <sub-resource> <verb> NAME [flags]
```

- **Names or IDs.** Sandboxes and agents are addressed by the name you gave them, or by
  their ID. Snapshots and AI runtimes, which you don't name, are addressed by ID.
- **Several at once.** Commands that take `NAME...` (`get`, `pause`, `resume`,
  `delete`, `describe`) act on every name you list.
- **`get` lists.** `get` with no name lists everything in the project; with names it
  fetches those.
- **Programs after `--`.** `exec` runs whatever follows `--` inside the sandbox.

## Flags on every command

| Flag | Description |
| --- | --- |
| `--org ID` | Organization to act in. Defaults to the current context |
| `-p, --project ID` | Project to act in. Defaults to the current context |
| `-o, --output FORMAT` | `table` (default), `wide`, `json`, `yaml` or `name` |
| `--no-headers` | Leave out the table header row |
| `-h, --help` | Help for the command |

Flags that several commands share:

| Flag | Commands | Description |
| --- | --- | --- |
| `--wait` | `create`, `pause`, `resume`, `delete`, `rollback`, `fork` | Block until the change is complete, then print the result |
| `--timeout DURATION` | the same | How long `--wait` waits, such as `90s` or `10m` (default `5m`) |
| `-y, --yes` | `delete`, `rollback`, `port delete`, `snapshot delete`, `airuntime delete` | Skip the confirmation prompt |
| `-f, --filename PATH` | `create`, `update` | Send the full request body from a JSON file, or `-` for stdin |
| `--refresh` | `exec`, `fs`, `proxy`, `ssh-config` | Look the sandbox's address up again instead of using the cached one. Rarely needed: a cached address the platform refuses as stale is looked up again automatically |

In `json` and `yaml`, `get` prints `{"items": [...]}` even for a single name, so
`jq '.items[0]'` works either way; `org get` and `project get` use `{"data": [...]}`.
`name` prints one `kind/id` per line.

---

## Sandboxes

### Sandbox lifecycle

#### sandbox create

Create a sandbox from a template, or from a snapshot.

```
neev-cli sandbox create --name NAME [flags]
```

| Flag | Description |
| --- | --- |
| `--name NAME` | Sandbox name: lowercase letters, digits and hyphens, up to 63 characters |
| `--template-id ID` | Template to start from (`sb-…`). Omit for the default. See [`sandbox template get`](#sandbox-template-get) |
| `--restore SNAPSHOT_ID` | Start from a snapshot instead of a template |
| `--cpu N` | vCPUs, 0.5 to 8 in steps of 0.5 |
| `--memory-gb N` | Memory, 1 to 16 GB |
| `--disk-gb N` | Disk, 10 to 100 GB in steps of 10 |
| `--env KEY=VALUE` | Environment variable (repeatable) |
| `--label KEY=VALUE` | Label (repeatable, up to 16). Find sandboxes by label with `get -l` |
| `--allow HOST[:PORT]` | Allow outbound traffic to a host (repeatable). See [host formats](#host-formats) |
| `--allow-internet` | Allow outbound traffic to any host |
| `--region REGION` | Region. Omit for the default |
| `--wait`, `--timeout` | Wait until the sandbox is Ready |
| `-f, --filename PATH` | Full request body as JSON |

Without `--allow` or `--allow-internet`, the sandbox can reach no outside host unless its
template opens some (the Docker template, for example, allows Docker Hub and GHCR).

```sh
neev-cli sandbox create --name web --wait
neev-cli sandbox create --name big --template-id sb-ubuntu-26-04-dev --cpu 4 --memory-gb 8 --disk-gb 50
neev-cli sandbox create --name ci --allow github.com --allow registry.npmjs.org --label team=payments
neev-cli sandbox create --name restored --restore 01a0ab20-cd18-70fb-91b5-96124c3be8e7 --wait
neev-cli sandbox create --filename ./sandbox.json
```

#### sandbox get

List sandboxes, or get the named ones.

```
neev-cli sandbox get [NAME...] [flags]
```

| Flag | Description |
| --- | --- |
| `--status STATUS` | Only sandboxes in this state, such as `Ready` or `Paused` |
| `--name TEXT` | Only sandboxes whose name contains this text |
| `-l, --selector KEY=VALUE` | Only sandboxes with this label (repeatable; all must match) |
| `-A, --all-projects` | List sandboxes in every project of the organization |
| `-w, --watch` | Keep the output on screen and reprint it when it changes, until Ctrl-C |
| `--limit N`, `--page N` | Page through a long list (default 20 per page) |

```sh
neev-cli sandbox get
neev-cli sandbox get web api
neev-cli sandbox get --status Paused
neev-cli sandbox get -l team=payments -o wide
neev-cli sandbox get -A --status Ready
neev-cli sandbox get web --watch
```

#### sandbox describe

Show every field of one or more sandboxes, including egress rules and timestamps.

```sh
neev-cli sandbox describe web
```

#### sandbox update

Resize a running sandbox, or change its egress rules, without a restart. Fields you leave
out are unchanged.

```
neev-cli sandbox update NAME [flags]
```

| Flag | Description |
| --- | --- |
| `--cpu N` | New vCPU count |
| `--memory-gb N` | New memory size |
| `--allow HOST[:PORT]` | Replace the egress rules with this allow-list (repeatable) |
| `--allow-internet` | Replace the egress rules with allow-all |
| `--deny-all` | Close egress entirely |
| `--allow-add HOST[:PORT]` | Add a host to the current allow-list, keeping the rest (repeatable) |
| `--allow-remove HOST[:PORT]` | Remove a host from the current allow-list (repeatable) |
| `-f, --filename PATH` | Full request body as JSON |

`--allow-add` and `--allow-remove` can't be combined with `--allow`, `--allow-internet` or
`--deny-all`. A sandbox whose egress is closed has no allow-list to edit: open one with
`--allow` first. Changes apply to new connections straight away. Disk size can't be
changed after create.

```sh
neev-cli sandbox update web --cpu 2 --memory-gb 4
neev-cli sandbox update web --allow github.com:443 --allow registry.npmjs.org
neev-cli sandbox update web --allow-add pypi.org:443
neev-cli sandbox update web --allow-remove registry.npmjs.org
neev-cli sandbox update web --deny-all
```

<a id="host-formats"></a>
**Host formats** for `--allow`, `--allow-add` and `--allow-remove`:

| Form | Example |
| --- | --- |
| Domain | `github.com` |
| Wildcard subdomain | `*.github.com` |
| IPv4 address or CIDR range | `203.0.113.7`, `10.0.0.0/8` |
| IPv6 address, in brackets | `[2001:db8::1]` |
| IPv6 CIDR range | `2001:db8::/32` |
| Any of the above, one port only | `github.com:443`, `[2001:db8::1]:443` |

Pass a host, not a URL: `github.com`, not `https://github.com`.

#### sandbox pause, resume

Pausing stops the sandbox's compute, so you stop paying for CPU and memory; its files are
kept. Resuming starts it again.

```sh
neev-cli sandbox pause web api
neev-cli sandbox resume web --wait
```

#### sandbox delete

Delete sandboxes, with their files and snapshots. Asks for confirmation unless `--yes`.

```sh
neev-cli sandbox delete web
neev-cli sandbox delete web api ci --yes
```

### sandbox template get

List sandbox templates, or get the named ones.

```
neev-cli sandbox template get [TEMPLATE_ID...] [--limit N] [--page N]
```

```sh
neev-cli sandbox template get
neev-cli sandbox template get sb-ubuntu-26-04-dev
```

### sandbox exec

Run a program inside a sandbox. Output streams to your terminal while it runs. No shell is
involved: the program after `--` runs with exactly the arguments you give, so use
`sh -c '…'` for pipes, `&&` or variables. If the program fails, the CLI exits non-zero
and reports its exit code.

```
neev-cli sandbox exec NAME [flags] -- PROGRAM [ARGS...]
```

| Flag | Description |
| --- | --- |
| `--cwd DIR` | Working directory, relative to `/workspace` |
| `--env KEY=VALUE` | Environment variable for this run (repeatable) |
| `--stdin TEXT` | Text to feed to the program's input; `-` passes the CLI's own input through |
| `-t, --tty` | Attach your terminal to the program, with resizing and Ctrl-C |
| `-i, --interactive` | Interactive session; implies `--tty` |
| `--timeout-ms N` | Stop the program after this many milliseconds |
| `-o json` | Print `{stdout, stderr, exit_code}` when it finishes, instead of streaming |

```sh
neev-cli sandbox exec web -- ls -la /workspace
neev-cli sandbox exec web --cwd app -- npm test
neev-cli sandbox exec web -- sh -c 'pip install -r requirements.txt && pytest'
neev-cli sandbox exec web -o json -- python3 main.py
neev-cli sandbox exec web -it -- bash
cat input.csv | neev-cli sandbox exec web --stdin - -- python3 process.py
```

To keep a server running after `exec` returns, start it in the background:
`-- sh -c 'nohup python3 -m http.server 3000 >/dev/null 2>&1 &'`.

### sandbox fs

Read and write files in a sandbox. Paths are relative to `/workspace`, or absolute inside
it.

| Command | What it does |
| --- | --- |
| `sandbox fs read NAME PATH [--out LOCAL]` | Print a file, or save it to `--out` |
| `sandbox fs write NAME PATH --in LOCAL` | Write a local file, or stdin with `--in -` |
| `sandbox fs get NAME [PATH] [-R] [--max-count N]` | List a directory; `-R` lists the whole tree |
| `sandbox fs upload NAME LOCAL REMOTE` | Copy a local directory (or file) into the sandbox |
| `sandbox fs download NAME REMOTE LOCAL` | Copy a sandbox directory (or file) to your machine |

`upload` sends four files at a time (`--concurrency`, 1 to 16) and splits a large file
into chunks (`--chunk-size`, 64KiB to 1MiB) that resume where they left off if the
connection drops. Every `fs` command also takes `--cwd DIR` as the base for relative
paths.

```sh
neev-cli sandbox fs write web app.py --in ./app.py
echo 'DEBUG=1' | neev-cli sandbox fs write web .env --in -
neev-cli sandbox fs read web app.py --out ./app.py
neev-cli sandbox fs get web src -R
neev-cli sandbox fs upload web ./src /workspace/src
neev-cli sandbox fs download web /workspace/results ./results
```

### sandbox port

Expose a sandbox port at a public HTTPS preview URL. Anyone with the URL can open it
without signing in, so treat it as a secret.

#### sandbox port create

```
neev-cli sandbox port create NAME --port PORT [flags]
```

| Flag | Description |
| --- | --- |
| `--port PORT` | Port your app listens on, 1 to 65535 |
| `--wait` | Wait until your app answers on the URL, then print it |
| `--timeout DURATION` | How long `--wait` waits (default `1m`) |
| `--slug SLUG` | Choose the URL's 8-character slug (lowercase letters and digits). On a port that is already exposed, this replaces the URL and the old one stops working |

A new URL can answer 404 for a few seconds; `--wait` covers that. Omit `--slug` for a
random, hard-to-guess URL.

```sh
neev-cli sandbox port create web --port 3000 --wait
neev-cli sandbox port create web --port 3000 --slug a1b2c3d4
```

#### sandbox port get, delete

```sh
neev-cli sandbox port get web
neev-cli sandbox port delete web --port 3000
neev-cli sandbox port delete web --port 3000 --port 8080 --yes
```

`-o name` prints each port as `port/NAME:PORT`.

### sandbox egress get

Show what a sandbox can reach, one row per host. Change the rules with
[`sandbox update`](#sandbox-update).

```sh
neev-cli sandbox egress get web
```

```
MODE        HOST        PORTS  PROTOCOL
allow_list  pypi.org    443    *
allow_list  github.com  *      *
```

`deny_all` means nothing is allowed. A sandbox open to all traffic shows a single
`(internet)` row.

### sandbox proxy

Let code in a sandbox reach hosts that only your machine can reach, such as a staging
site behind your company VPN. The sandbox's traffic leaves through your machine, and only
to the hosts you list. Inside the sandbox, send traffic through the SOCKS proxy at
`socks5h://127.0.0.1:1080`, for example by setting `ALL_PROXY`. It runs until you press
Ctrl-C.

```
neev-cli sandbox proxy (NAME | -l KEY=VALUE) --allow-host HOST:PORT... [flags]
```

| Flag | Description |
| --- | --- |
| `--allow-host HOST:PORT` | A host the sandbox may reach through your machine (repeatable). `any` allows every host |
| `--port PORT` | Proxy port inside the sandbox (default 1080) |
| `-l, --selector KEY=VALUE` | Serve every sandbox with this label, as they start and stop (repeatable; all must match) |
| `--max-sandboxes N` | With `-l`, the most sandboxes served at once (default 10) |

```sh
neev-cli sandbox proxy web --allow-host staging.example.com:443
# inside the sandbox:
curl -x socks5h://127.0.0.1:1080 https://staging.example.com/
```

**Serving automation with `-l`.** Your automation creates sandboxes with a label, and
the proxy picks them up when they're ready; the automation never needs access to your
machine. With `-l`, list each `--allow-host` exactly (no wildcards). The label is the
only check: anyone who can create a sandbox with it in that project reaches the allowed
hosts through your machine, so use a project only your automation uses. Every attach is
logged with the sandbox and who created it.

```sh
neev-cli sandbox proxy -l proxy=staging --allow-host staging.example.com:443
neev-cli sandbox create --name e2e --label proxy=staging
```

Requires OpenSSH 8.7 or later on your machine, or 9.2 or later for more than one host.

### sandbox ssh-config

Manage `~/.ssh/config` blocks for sandboxes, so `ssh`, `scp -O` and `rsync` connect by
name. Each block pins the sandbox's host key, so `ssh` doesn't prompt on first connect,
and reuses one connection for many sessions. Entries you wrote yourself are left alone.

| Command | What it does |
| --- | --- |
| `sandbox ssh-config write NAME...` | Add or update the block for each sandbox |
| `sandbox ssh-config get [NAME...]` | List the blocks neev-cli manages, or print one |
| `sandbox ssh-config delete NAME...` | Remove blocks and their host-key pins |

| Flag | Description |
| --- | --- |
| `--config-file PATH` | ssh config file to manage (default `~/.ssh/config`) |
| `--known-hosts-file PATH` | Where to pin host keys (default `~/.ssh/known_hosts`; empty to skip) |

Each connection uses the sandbox API key from your current context, or `NEEV_API_KEY`
in the environment `ssh` runs in. Sandboxes don't run an SFTP server, so `sftp` doesn't
work and `scp` needs `-O`.

```sh
neev-cli sandbox ssh-config write web
ssh web
rsync -a ./data/ web:/workspace/data/
neev-cli sandbox ssh-config get                       # the blocks neev-cli manages
neev-cli sandbox ssh-config delete web
```

### sandbox snapshot

A snapshot captures a sandbox's files and the memory of its running processes. It starts
`Pending` and becomes `Ready` a few seconds later; only a Ready snapshot can be used.

| Command | What it does |
| --- | --- |
| `sandbox snapshot create NAME [--name LABEL]` | Capture a snapshot |
| `sandbox snapshot get NAME [--limit N] [--page N]` | List a sandbox's snapshots |
| `sandbox snapshot show SNAPSHOT_ID` | Show one snapshot |
| `sandbox snapshot delete SNAPSHOT_ID... [--yes]` | Delete snapshots |

Note that `snapshot get` takes the **sandbox** name, while `show` and `delete` take
**snapshot** IDs. Deleting a sandbox deletes its snapshots.

```sh
neev-cli sandbox snapshot create web --name before-upgrade
neev-cli sandbox snapshot get web
neev-cli sandbox snapshot show 01a0ab20-cd18-70fb-91b5-96124c3be8e7
neev-cli sandbox snapshot delete 01a0ab20-cd18-70fb-91b5-96124c3be8e7 --yes
```

To start a new sandbox from a snapshot, use `sandbox create --restore SNAPSHOT_ID`.

### sandbox rollback

Return a sandbox to a snapshot, in place. Its current state is replaced. Asks for
confirmation unless `--yes`.

```
neev-cli sandbox rollback NAME --snapshot SNAPSHOT_ID [--wait] [--yes]
```

```sh
neev-cli sandbox rollback web --snapshot 01a0ab20-cd18-70fb-91b5-96124c3be8e7 --wait
```

### sandbox fork

Copy a sandbox's current state, files and running processes, into a new sandbox. The
original keeps running.

```
neev-cli sandbox fork NAME --as NEW_NAME [--wait]
```

```sh
neev-cli sandbox fork web --as web-experiment --wait
```

### sandbox metrics

CPU, memory and disk use over a time window.

```
neev-cli sandbox metrics NAME [--from TIME] [--to TIME] [--step DURATION]
```

| Flag | Description |
| --- | --- |
| `--from TIME` | Window start, RFC 3339 (default: an hour before `--to`) |
| `--to TIME` | Window end, RFC 3339 (default: now) |
| `--step DURATION` | Resolution, such as `60s` or `5m` |

```sh
neev-cli sandbox metrics web --step 60s
neev-cli sandbox metrics web --from 2026-10-17T09:00:00Z --to 2026-10-17T10:00:00Z -o json
```

---

## Agents

An agent is a ready-made coding agent running on its own sandbox. `neev-cli agent` has
the same commands and flags as `neev-cli sandbox`, applied to agents by name; this
section covers only what differs.

| Command | Same as |
| --- | --- |
| `agent get / describe / pause / resume / delete` | [Sandbox lifecycle](#sandbox-lifecycle) |
| `agent update` | [`sandbox update`](#sandbox-update), including `--allow-add` and `--allow-remove` |
| `agent exec` | [`sandbox exec`](#sandbox-exec) |
| `agent fs read / write / get / upload / download` | [`sandbox fs`](#sandbox-fs) |
| `agent port create / get / delete` | [`sandbox port`](#sandbox-port) |
| `agent egress get` | [`sandbox egress get`](#sandbox-egress-get) |
| `agent proxy` | [`sandbox proxy`](#sandbox-proxy), without `-l` |
| `agent ssh-config write / get / delete` | [`sandbox ssh-config`](#sandbox-ssh-config) |
| `agent snapshot create / get / show / delete` | [`sandbox snapshot`](#sandbox-snapshot) |
| `agent rollback` | [`sandbox rollback`](#sandbox-rollback) |
| `agent metrics` | [`sandbox metrics`](#sandbox-metrics) |

Agents don't have `fork` or labels. To copy an agent's live state, run `sandbox fork` on
its backing sandbox, whose ID is the `sandbox_id` field of `agent get -o json`.

### agent create

Create an agent from an agent template.

```
neev-cli agent create --name NAME --agent-template TEMPLATE [flags]
```

| Flag | Description |
| --- | --- |
| `--name NAME` | Agent name: lowercase letters, digits and hyphens, up to 63 characters |
| `--agent-template NAME` | The agent to run, such as `claude-code`. See [`agent template get`](#agent-template-get) |
| `--cpu`, `--memory-gb`, `--disk-gb` | Resources, with the same limits as a sandbox |
| `--env KEY=VALUE` | Environment variable (repeatable) |
| `--allow HOST[:PORT]` | Allow outbound traffic to a host (repeatable) |
| `--allow-internet` | Allow outbound traffic to any host |
| `--region REGION` | Region. Omit for the default |
| `--wait`, `--timeout` | Wait until the agent is Ready |
| `-f, --filename PATH` | Full request body as JSON |

An agent's egress starts from its template, which already allows what the agent needs
(Claude Code, for example, can reach its model API, GitHub and the common package
registries). `--allow` and `--allow-internet` replace that list rather than add to it,
so to allow one more host, create the agent first and then run
`agent update NAME --allow-add HOST`.

```sh
neev-cli agent create --name coder --agent-template claude-code --wait
neev-cli agent create --name coder --agent-template claude-code --cpu 2 --memory-gb 4
neev-cli agent egress get coder
```

### agent template get

List agent templates, or get the named ones.

```sh
neev-cli agent template get
neev-cli agent template get ag-claude-code
```

---

## AI runtimes

An AI runtime is a GPU environment, such as JupyterLab with PyTorch, on a pricing plan.
AI runtimes are addressed by ID.

### airuntime create

```
neev-cli airuntime create --name NAME --region REGION --template-id ID \
  --gpu-config-id ID --plan-id ID --gpu-count N [flags]
```

| Flag | Description |
| --- | --- |
| `--name NAME` | Runtime name: lowercase, words separated by hyphens |
| `--region REGION` | Region to run in |
| `--template-id ID` | Runtime template (`tpl-…`). See [`airuntime template get`](#airuntime-template-get) |
| `--gpu-config-id ID` | GPU configuration |
| `--plan-id ID` | Pricing plan. See `billing products get` |
| `--gpu-count N` | Number of GPUs |
| `--ssh-key KEY` | SSH public key to install (repeatable) |
| `-f, --filename PATH` | Full request body as JSON, for storage, environment variables and other settings |

```sh
neev-cli airuntime create --name notebook --region <region> \
  --template-id tpl-jupyterlab-pytorch \
  --gpu-config-id <gpu-config-id> --plan-id <plan-id> --gpu-count 1
neev-cli airuntime create --filename ./runtime.json
```

### airuntime get, metrics, delete

```sh
neev-cli airuntime get                       # list
neev-cli airuntime get <airuntime-id>
neev-cli airuntime metrics <airuntime-id>    # utilization
neev-cli airuntime delete <airuntime-id> --yes
```

### airuntime template get

List runtime templates: the platform catalogue, or your organization's own templates
when you pass `--org`.

```sh
neev-cli airuntime template get
neev-cli airuntime template get tpl-jupyterlab-pytorch
neev-cli airuntime template get --org <org-id>
```

---

## Account

These commands use your Personal Access Token.

| Command | What it does |
| --- | --- |
| `org get [ORG_ID...]` | Organizations you belong to |
| `project get [PROJECT_ID...]` | Projects in the current organization (`--org` for another) |
| `billing products get` | Products and their prices |

```sh
neev-cli org get
neev-cli project get --org <org-id>
neev-cli billing products get -o json
```

---

## Setup

### auth

| Command | What it does |
| --- | --- |
| `auth login` | Sign in with a Personal Access Token. It is prompted for and hidden as you type |
| `auth login --token-stdin` | Read the token from stdin, for scripts |
| `auth status` | Show whether you're signed in; exits non-zero if not |
| `auth logout` | Remove the saved session from this machine. To revoke the token itself, delete it in the console |

```sh
neev-cli auth login
echo "$NEEV_API_TOKEN" | neev-cli auth login --token-stdin
neev-cli auth status
```

### context

A context is a saved organization and project; the current one fills in `--org` and
`--project`. It can also hold your sandbox API key. To find your IDs, see
[Organizations and projects](https://docs.ai.neevcloud.com/getting-started/org-and-project#find-your-organization-id-and-project-id).

| Command | What it does |
| --- | --- |
| `context get` | Saved contexts, and the organizations and projects you can access |
| `context set NAME --org ORG --project PROJECT` | Save a context and make it current. Names or IDs both work |
| `context use NAME` | Switch to a saved context |
| `context current` | Show the current context (`-o name` for just its name) |
| `context delete NAME` | Delete a saved context |

`context set` flags:

| Flag | Description |
| --- | --- |
| `--sandbox-api-key` | Save a sandbox API key with the context. It takes no value: it is prompted for, or read from stdin |
| `--clear-sandbox-api-key` | Remove the saved key |
| `--org-name`, `--project-name` | Display names to show in `context get` |

```sh
neev-cli context set dev --org Acme --project Default --sandbox-api-key
echo "$NEEV_API_KEY" | neev-cli context set ci --org <org-id> --project <project-id> --sandbox-api-key
neev-cli context use dev
```

### config

A default organization and project, without naming a context. A current context takes
precedence over these, and a flag over both.

| Command | What it does |
| --- | --- |
| `config get [KEY]` | Show saved preferences |
| `config set KEY VALUE` | Save one (`org-id` or `project-id`) |
| `config unset KEY` | Clear one |

```sh
neev-cli config set org-id <org-id>
neev-cli config set project-id <project-id>
```

### completion

Print a shell completion script: `bash`, `zsh`, `fish` or `powershell`. Completion
suggests sandbox, agent and template names.

```sh
neev-cli completion zsh > "${fpath[1]}/_neev-cli"
neev-cli completion bash > /etc/bash_completion.d/neev-cli
neev-cli completion fish > ~/.config/fish/completions/neev-cli.fish
```

### version

```sh
neev-cli version          # version, commit, build date and platform
neev-cli version --json
```

---

## Environment variables

| Variable | Description |
| --- | --- |
| `NEEV_API_TOKEN` | Personal Access Token. Takes precedence over a saved session |
| `NEEV_API_KEY` | Sandbox API key. Takes precedence over a key saved on the context |
| `NEEVCLOUD_CONFIG_DIR` | Directory for the CLI's saved session, contexts and preferences (default `~/.config/neevcli`) |
| `NO_COLOR` | Turn off colored output |
| `NEEV_CLI_VERSION` | Installer only: the release to install, such as `v0.9.0` |
| `NEEV_CLI_INSTALL_DIR` | Installer only: where to install |
