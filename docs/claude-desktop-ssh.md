# Connect to a sandbox from Claude Desktop (SSH)

Run Claude Code *inside* a sandbox using the Claude Desktop app as your interface,
over the sandbox's SSH endpoint. `neev-cli` wires up the SSH config; Claude
Desktop's SSH sessions do the rest.

## Prerequisites

- `neev-cli` installed and signed in, with a context set (see
  [getting-started](getting-started.md)).
- Claude Desktop (the **Code** tab). The remote must run Linux or macOS —
  sandboxes are Linux, so that's covered.
- A **sandbox API key** exported as `NEEV_API_KEY`, visible to Claude Desktop
  (see step 3).

## 1. Pick a sandbox that can run Claude Code

Claude Desktop installs Claude Code on the remote on first connect, and Claude
Code then needs to reach `api.anthropic.com` — so the sandbox needs egress and a
capable image. Two ways:

**Option A — the `claude-code` agent (recommended).** Its image already has Claude
Code installed and its egress already allows Anthropic, so there's nothing to
install and no flags to add:

```sh
AGENT_ID=$(neev-cli agent create --name claude-desktop --agent-template claude-code -o json | jq -r '.id')
SANDBOX_ID=$(neev-cli agent get "$AGENT_ID" -o json | jq -r '.sandbox_id')
```

**Option B — a plain sandbox with egress opened at create time** (egress is
immutable afterward) so Desktop can install Claude Code and it can reach the API:

```sh
# Simplest — allow all egress (reliable for the first-connect auto-install):
SANDBOX_ID=$(neev-cli sandbox create --name claude-desktop --allow-internet -o json | jq -r '.id')

# Or lock it down — allow at least the API; add the hosts the installer fetches
# from (npm / GitHub / CDN), or fall back to --allow-internet for the install step:
#   neev-cli sandbox create --name claude-desktop \
#     --allow api.anthropic.com --allow registry.npmjs.org --allow github.com
```

Wait until it is Ready:

```sh
until [ "$(neev-cli sandbox get "$SANDBOX_ID" -o json | jq -r '.phase')" = "Ready" ]; do sleep 2; done
```

## 2. Write the SSH config block

`neev-cli sandbox ssh-config` emits a `~/.ssh/config` Host block: a `ProxyCommand`
that tunnels through `neev-cli sandbox ssh-proxy`, the `neev` login user, and a
pinned host key. Claude Desktop accepts such a config Host alias as its SSH Host.

```sh
neev-cli sandbox ssh-config "$SANDBOX_ID" --write
neev-cli sandbox ssh-config --list          # confirm the alias it wrote
```

The alias is the sandbox name (falling back to its id). On macOS/Linux the block
also enables SSH connection multiplexing (`ControlMaster`), which Desktop relies on
for its parallel channels.

## 3. Make NEEV_API_KEY available to the ProxyCommand

Claude Desktop runs the `ProxyCommand` (`neev-cli sandbox ssh-proxy …`) itself, so
`neev-cli` needs the sandbox API key **from the environment at that moment**. The
key is deliberately *not* written into the SSH config. Export it where Desktop can
see it:

- Launch Claude Desktop from a shell where the key is exported: `export NEEV_API_KEY=… && open -a "Claude"` (or your platform's launch), or
- Set it in your shell profile / `launchctl setenv NEEV_API_KEY …` on macOS so a GUI-launched Desktop inherits it.

## 4. Add the SSH connection in Claude Desktop

In the **Code** tab, open the environment dropdown and choose **+ Add SSH
connection**. Fill in:

- **SSH Host**: the sandbox alias from step 2 (its name or id) — or a full `user@host`.
- **SSH Port**: leave blank (defaults to 22 / your SSH config).
- **Identity File**: leave empty — the sandbox authenticates at the edge, so there is no client key.

Start the session. On first connect Desktop installs Claude Code on the sandbox;
after that you get a Claude Code session running inside it, with `/workspace` as the
project directory. SSH sessions support permission modes, connectors, plugins, and
MCP servers.

Administrators can pre-distribute these as `sshConfigs` in Claude Desktop's managed
settings (so they appear in everyone's environment dropdown), and restrict them with
`sshHostAllowlist` — see Claude Desktop's own documentation.

## 5. Disconnect and clean up

Close the session. When you're done with the sandbox, remove its config block and
host-key pin, then delete the sandbox (or agent):

```sh
neev-cli sandbox ssh-config "$SANDBOX_ID" --remove
neev-cli sandbox delete "$SANDBOX_ID" --yes
# for Option A: neev-cli agent delete "$AGENT_ID" --yes
```

## Plain SSH

The same config works from a terminal — you connect as `neev` through the
ProxyCommand:

```sh
ssh <sandbox-name-or-id>
```

## Troubleshooting

- **Permission denied / connection closes immediately** — `NEEV_API_KEY` isn't
  visible to the ProxyCommand (step 3), or the key isn't valid for this sandbox.
- **Claude Code fails to install on first connect** — the sandbox can't reach the
  internet; recreate it with egress open (step 1, Option B) or use the `claude-code`
  agent.
- **Host key changed** — the sandbox was recreated; run `ssh-config --remove` then
  `--write` again to re-pin the new key.
- **Session hangs on "Setting up SSH Host"** — confirm the sandbox is `Ready`
  (`neev-cli sandbox get <id>`) and that `neev-cli` is on your `PATH` (the
  ProxyCommand invokes it by name).
