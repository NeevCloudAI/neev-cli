# Agents

An agent is a ready-made coding agent, such as Claude Code, running on its own sandbox.
You choose an agent template, and the agent comes with its tools installed and the
network access it needs. Every command addresses an agent by the name you gave it.

`neev-cli agent` has the same commands as `neev-cli sandbox`, so the
[Sandboxes guide](./sandboxes.md) applies to agents too; this page covers what is
specific to agents.

| Capability | Commands |
| --- | --- |
| [Create and manage agents](#create-and-manage-agents) | `agent create / get / describe / update / pause / resume / delete` |
| [Agent templates](#agent-templates) | `agent template get` |
| [Work inside an agent](#work-inside-an-agent) | `agent exec`, `agent fs` |
| [Network access](#network-access) | `agent egress get`, `agent update --allow-add` |
| [Preview URLs](#preview-urls) | `agent port create / get / delete` |
| [SSH and Claude Desktop](#ssh-and-claude-desktop) | `agent ssh-config`, `agent proxy` |
| [Snapshots and metrics](#snapshots-and-metrics) | `agent snapshot`, `agent rollback`, `agent metrics` |

## Create and manage agents

```sh
neev-cli agent create --name coder --agent-template claude-code --wait
neev-cli agent get                         # every agent in the project
neev-cli agent update coder --cpu 2 --memory-gb 4
neev-cli agent pause coder                 # stop paying for compute; files are kept
neev-cli agent resume coder --wait
neev-cli agent delete coder --yes
```

Resources take the same values as a sandbox: `--cpu`, `--memory-gb` and `--disk-gb`.

## Agent templates

An agent template is the agent you run. Pass its name to `--agent-template`.

```sh
neev-cli agent template get
```

```
ID               NAME          STATUS  CATEGORY  VERSION    DESCRIPTION
ag-claude-code   claude-code   active  coding    2.1.251    Anthropic Claude Code CLI agent
ag-codex-cli     codex-cli     active  coding    0.151.0    OpenAI Codex CLI agent
ag-opencode      opencode      active  coding    1.18.25    opencode agent (web UI)
```

The catalogue grows over time, so `agent template get` is the source of truth.

## Work inside an agent

Run the agent, or any other program, inside its sandbox, and move files in and out:

```sh
neev-cli agent exec coder -it -- claude                 # an interactive Claude Code session
neev-cli agent exec coder -- git clone https://github.com/acme/app
neev-cli agent fs upload coder ./specs /workspace/specs
neev-cli agent fs download coder /workspace/app ./app
```

`exec` and `fs` work exactly as they do for a sandbox; see
[Commands](./sandboxes.md#commands) and [Files](./sandboxes.md#files).

## Network access

An agent starts with its template's egress rules, which allow what the agent needs:
Claude Code, for example, can reach its model API, GitHub and the common package
registries.

```sh
neev-cli agent egress get coder                         # what it can reach
neev-cli agent update coder --allow-add api.example.com # add a host, keep the rest
neev-cli agent update coder --allow-remove github.com
```

`--allow` and `--allow-internet` on `agent create` replace the template's rules rather
than add to them, so to allow one more host, create the agent first and then use
`--allow-add`. See [Network egress](./sandboxes.md#network-egress) for host formats.

## Preview URLs

When the agent builds a web app, expose its port to try it in a browser:

```sh
neev-cli agent port create coder --port 3000 --wait
```

Anyone with the URL can open it without signing in. See
[Preview URLs](./sandboxes.md#preview-urls).

## SSH and Claude Desktop

```sh
neev-cli agent ssh-config write coder
ssh coder
```

To drive Claude Code in an agent from the Claude Desktop app, follow
[Connect from Claude Desktop](./claude-desktop-ssh.md). To let an agent reach a host
behind your VPN, use `agent proxy`; see [Reach private hosts](./sandboxes.md#reach-private-hosts).

## Snapshots and metrics

```sh
neev-cli agent snapshot create coder --name before-refactor
neev-cli agent snapshot get coder
neev-cli agent rollback coder --snapshot <snapshot-id> --wait   # back to the snapshot, in place
neev-cli agent metrics coder --step 60s
```

To copy an agent's live state, fork the sandbox behind it:
`neev-cli sandbox fork <sandbox-id> --as coder-copy`, with the ID from
`neev-cli agent get coder -o json`. The fork is a plain sandbox. Agents don't have labels.

See the [command reference](./command-reference.md#agents) for every flag.
