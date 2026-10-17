# neev-cli

The official command-line interface for NeevCloud.

[![Release](https://img.shields.io/github/v/release/NeevCloudAI/neev-cli)](https://github.com/NeevCloudAI/neev-cli/releases/latest)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](./LICENSE)

One binary for every NeevCloud product: Sandboxes, Agents and AI runtimes today, with
more to come. Commands read the way `kubectl` does, a product and then a verb, with
tables for people and JSON for scripts.

```sh
neev-cli sandbox create --name web --wait
neev-cli sandbox exec web -- python3 -c 'print(6 * 7)'
neev-cli sandbox port create web --port 3000 --wait
```

> **AI agents:** before running `neev-cli`, read [`docs/ai-agents.md`](./docs/ai-agents.md)
> ([raw](https://raw.githubusercontent.com/NeevCloudAI/neev-cli/main/docs/ai-agents.md)).
> It has the pre-flight checks, the rules for running without a terminal, a recipe per
> product, and what to do about each error.

## Contents

- [Install](#install)
- [Quick start](#quick-start)
- [Products](#products)
- [Documentation](#documentation)
- [Examples](#examples)
- [Security](#security)
- [License](#license)

## Install

macOS and Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/NeevCloudAI/neev-cli/main/install.sh | sh
```

Windows: download `neev-cli_windows_amd64.zip` (or `_arm64.zip`) from the
[latest release](https://github.com/NeevCloudAI/neev-cli/releases/latest), extract it,
and add the folder to your `PATH`.

Check it with `neev-cli version`. To pin a version or choose where it installs, see
[Getting started](./docs/getting-started.md#1-install).

## Quick start

You need a **Personal Access Token** and a **sandbox API key**, both from the
[NeevCloud console](https://console.ai.neevcloud.com)
([how to create the key](https://docs.ai.neevcloud.com/getting-started/create-api-key)).

```sh
# Sign in with your Personal Access Token.
neev-cli auth login

# Save your organization, project and sandbox API key as a context.
neev-cli context set dev --org <org-id> --project <project-id> --sandbox-api-key

# Create a sandbox, run code in it, and delete it.
neev-cli sandbox create --name hello --wait
neev-cli sandbox exec hello -- python3 -c 'print(6 * 7)'
neev-cli sandbox delete hello --yes
```

To find your organization and project IDs, see
[Organizations and projects](https://docs.ai.neevcloud.com/getting-started/org-and-project#find-your-organization-id-and-project-id),
or run `neev-cli context get` after signing in.

New to NeevCloud? [Getting started](./docs/getting-started.md) walks through each step.
Working with a coding agent? Paste one of the prompts in
[Use from an AI agent](./docs/ai-agents.md) and it will drive `neev-cli` for you.

## Products

| Product | What it is | Commands | Guide |
| --- | --- | --- | --- |
| Sandboxes | Isolated machines that run your code, commands and servers | `neev-cli sandbox` | [Sandboxes](./docs/sandboxes.md) |
| Agents | Ready-made coding agents, such as Claude Code, each on its own sandbox | `neev-cli agent` | [Agents](./docs/agents.md) |
| AI runtimes | GPU environments, such as JupyterLab with PyTorch | `neev-cli airuntime` | [AI runtimes](./docs/ai-runtimes.md) |
| Account | Organizations, projects and pricing | `neev-cli org`, `project`, `billing` | [Account](./docs/account.md) |

**What you can do with a sandbox:** run commands and interactive shells, move files and
whole directories, serve an app at a public preview URL, control which hosts it can
reach, connect over SSH, reach hosts behind your VPN, snapshot, fork and roll back, and
read its metrics. The [Sandboxes guide](./docs/sandboxes.md) covers each one.

## Documentation

| Guide | What you'll find |
| --- | --- |
| [Getting started](./docs/getting-started.md) | Install, sign in, and run code in your first sandbox |
| [Sandboxes](./docs/sandboxes.md) · [Agents](./docs/agents.md) · [AI runtimes](./docs/ai-runtimes.md) · [Account](./docs/account.md) | One guide per product |
| [Configuration](./docs/configuration.md) | Credentials, contexts, output formats, scripting and shell completion |
| [Command reference](./docs/command-reference.md) | Every command and flag |
| [Connect from Claude Desktop](./docs/claude-desktop-ssh.md) | Claude Code inside a sandbox, from the Claude Desktop app |
| [Use from an AI agent](./docs/ai-agents.md) | Prompts to paste into Claude Code, Cursor or Codex, and the rules they follow |

Every command also has `--help`, with examples. The full NeevCloud documentation is at
<https://docs.ai.neevcloud.com>. Questions and bugs:
[open an issue](https://github.com/NeevCloudAI/neev-cli/issues).

## Examples

[`examples/`](./examples) has runnable scripts, one per area: sandboxes, networking,
snapshots, agents, AI runtimes and your account. Each one cleans up after itself.

## Security

To report a vulnerability, see [SECURITY.md](./SECURITY.md). Please don't open a public
issue for it.

## License

[Apache-2.0](./LICENSE)
