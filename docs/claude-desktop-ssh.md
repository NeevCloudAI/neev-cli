# Connect from Claude Desktop

Run Claude Code inside a NeevCloud agent or sandbox, with the Claude Desktop app as your
interface. `neev-cli` writes the SSH configuration; Claude Desktop connects over SSH and
does the rest. Your code and Claude Code's work stay in the cloud, not on your laptop.

## Before you start

- `neev-cli` installed and on your `PATH`, signed in, with a context that holds your
  sandbox API key. See [Getting started](./getting-started.md); the key is saved with
  `neev-cli context set <name> --org <org> --project <project> --sandbox-api-key`.
- Claude Desktop, using its **Code** tab.

## 1. Create somewhere for Claude Code to run

**Option A: a Claude Code agent (recommended).** It comes with Claude Code installed and
with network access to Anthropic's API, GitHub and the common package registries.

```sh
neev-cli agent create --name claude-desktop --agent-template claude-code --wait
```

**Option B: a plain sandbox.** Claude Desktop installs Claude Code on first connect, so
the sandbox needs internet access:

```sh
neev-cli sandbox create --name claude-desktop --allow-internet --wait
```

You can narrow its egress afterwards with `neev-cli sandbox update`.

## 2. Write the SSH configuration

```sh
neev-cli agent ssh-config write claude-desktop      # Option A
neev-cli sandbox ssh-config write claude-desktop    # Option B
```

This adds a `Host claude-desktop` block to `~/.ssh/config`, pins the host key, and turns
on connection sharing, which Claude Desktop uses for its parallel sessions. Check it with
`ssh claude-desktop`.

## 3. Add the connection in Claude Desktop

In the **Code** tab, open the environment menu and choose **Add SSH connection**:

| Field | Value |
| --- | --- |
| SSH Host | `claude-desktop` |
| SSH Port | leave empty |
| Identity File | leave empty: NeevCloud authenticates the connection, so there is no key file |

Start a session. You're now running Claude Code inside the sandbox, in `/workspace`.

Each connection runs `neev-cli` with the API key from your current context. If you
switch contexts later, switch back (`neev-cli context use <name>`) before connecting, or
make `NEEV_API_KEY` available to Claude Desktop instead.

## 4. Clean up

```sh
neev-cli agent ssh-config delete claude-desktop
neev-cli agent delete claude-desktop --yes
```

Use `sandbox` in place of `agent` for Option B. To keep your work but stop paying for
compute, pause instead of deleting: `neev-cli agent pause claude-desktop`. A paused
agent must be resumed before you connect again.

## Troubleshooting

| Symptom | What to do |
| --- | --- |
| The connection closes straight away | The API key isn't available. Check `neev-cli context current` and that the context has a key (`context set … --sandbox-api-key`) |
| Stuck on "Setting up SSH host" | Check the agent is `Ready` (`neev-cli agent get claude-desktop`) and that `neev-cli` is on the `PATH` Claude Desktop sees |
| Claude Code fails to install (Option B) | The sandbox can't reach the internet. Run `neev-cli sandbox update claude-desktop --allow-internet` |
| `REMOTE HOST IDENTIFICATION HAS CHANGED` | The sandbox was recreated. Run `ssh-config delete`, then `ssh-config write` again |
