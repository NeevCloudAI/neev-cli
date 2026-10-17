# Getting started

Install `neev-cli`, set up your credentials, and run code in your first sandbox. This
takes about five minutes. For every command and flag, see the [command reference](./command-reference.md).

## Contents

- [Before you start](#before-you-start)
- [1. Install](#1-install)
- [2. Sign in](#2-sign-in)
- [3. Choose your organization and project](#3-choose-your-organization-and-project)
- [4. Create a sandbox](#4-create-a-sandbox)
- [5. Run code and move files](#5-run-code-and-move-files)
- [6. Open your app in a browser](#6-open-your-app-in-a-browser)
- [7. Pause or delete it](#7-pause-or-delete-it)
- [Using the CLI in CI](#using-the-cli-in-ci)
- [Troubleshooting](#troubleshooting)
- [Next steps](#next-steps)

## Before you start

You need:

- macOS, Linux or Windows.
- A NeevCloud account with access to an organization and a project.
- A **Personal Access Token** (`pat-nc-…`), created in the
  [NeevCloud console](https://console.ai.neevcloud.com). It signs the CLI in to your account.
- A **sandbox API key** (`sk-nc-…`), also created in the console with the sandbox
  resource type. It lets the CLI work inside sandboxes. See
  [Create an API key](https://docs.ai.neevcloud.com/getting-started/create-api-key).

Why two? The token covers your account: organizations, projects, billing and AI
runtimes. The key covers sandboxes and agents, including running commands inside them.
Keeping them separate means you can give an automation the key alone, and it can use
sandboxes without touching anything else in your account.

## 1. Install

On macOS and Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/NeevCloudAI/neev-cli/main/install.sh | sh
```

On Windows, download `neev-cli_windows_amd64.zip` (or `_arm64.zip`) from the
[latest release](https://github.com/NeevCloudAI/neev-cli/releases/latest), extract it,
and add the folder to your `PATH`.

Check that it works:

```sh
neev-cli version
```

To pin a version, or install somewhere other than `/usr/local/bin` (or `~/.local/bin`):

```sh
curl -fsSL https://raw.githubusercontent.com/NeevCloudAI/neev-cli/main/install.sh | NEEV_CLI_VERSION=v0.9.0 sh
curl -fsSL https://raw.githubusercontent.com/NeevCloudAI/neev-cli/main/install.sh | NEEV_CLI_INSTALL_DIR="$HOME/bin" sh
```

## 2. Sign in

```sh
neev-cli auth login
```

Paste your Personal Access Token when asked. It isn't shown as you type, and it is saved
so later commands don't ask again. Confirm with:

```sh
neev-cli auth status
```

## 3. Choose your organization and project

Every sandbox lives in a project. Rather than pass `--org` and `--project` to every
command, save them once as a **context**:

```sh
neev-cli context get
```

This lists the organizations and projects you can access. Pick one and save it, along
with your sandbox API key:

```sh
neev-cli context set dev --org <org-id> --project <project-id> --sandbox-api-key
```

`--sandbox-api-key` asks for the key, so it stays out of your shell history. You can use
display names instead of IDs (`--org Acme --project Default`). For where to find the IDs
in the console, see
[Organizations and projects](https://docs.ai.neevcloud.com/getting-started/org-and-project#find-your-organization-id-and-project-id).

`dev` is now the current context. Save more with other names and switch with
`neev-cli context use <name>`.

## 4. Create a sandbox

```sh
neev-cli sandbox create --name hello --wait
```

```
NAME   STATUS  REGION      CPU  MEM  DISK  AGE
hello  Ready   as-south-1  1    2Gi  10Gi  3s
```

The sandbox starts from the default template with 1 vCPU, 2 GB of memory and 10 GB of
disk. To choose them, add `--template-id`, `--cpu`, `--memory-gb` and `--disk-gb`; see
the templates with `neev-cli sandbox template get`.

A new sandbox can't reach the internet. To let it install packages, open the hosts it
needs (or everything, with `--allow-internet`):

```sh
neev-cli sandbox create --name builder --allow pypi.org --allow files.pythonhosted.org --wait
```

## 5. Run code and move files

Run a program inside the sandbox. Everything after `--` runs there:

```sh
neev-cli sandbox exec hello -- python3 -c 'print(6 * 7)'
```

```
42
```

Write a file, read it back, and list the workspace:

```sh
echo 'hello from NeevCloud' | neev-cli sandbox fs write hello hello.txt --in -
neev-cli sandbox fs read hello hello.txt
neev-cli sandbox fs get hello
```

Copy a whole project in, and results back out:

```sh
neev-cli sandbox fs upload hello ./my-project /workspace/my-project
neev-cli sandbox exec hello --cwd my-project -- python3 main.py
neev-cli sandbox fs download hello /workspace/my-project/out ./out
```

For an interactive shell, use `-it`:

```sh
neev-cli sandbox exec hello -it -- bash
```

## 6. Open your app in a browser

Start a web server in the sandbox, then expose its port:

```sh
neev-cli sandbox exec hello -- sh -c 'nohup python3 -m http.server 3000 >/dev/null 2>&1 &'
neev-cli sandbox port create hello --port 3000 --wait
```

```
PORT  URL
3000  https://3000-01a14875-3519-7a8a-84f5-e2ff32054938-3rjrg5v8.as-south-1.neevsandbox.app
```

Open the URL in any browser. Anyone with it can reach your app without signing in, so
share it carefully, and close it when you're done:

```sh
neev-cli sandbox port delete hello --port 3000 --yes
```

## 7. Pause or delete it

A paused sandbox keeps its files and stops using compute, so you stop paying for CPU and
memory. Resume it when you need it again:

```sh
neev-cli sandbox pause hello
neev-cli sandbox resume hello --wait
```

When you're finished:

```sh
neev-cli sandbox delete hello --yes
```

Deleting a sandbox also deletes its files and snapshots.

## Using the CLI in CI

In a pipeline, skip `auth login` and `context set` and use environment variables, which
take precedence over anything saved:

```sh
export NEEV_API_TOKEN="pat-nc-…"   # from your CI secret store
export NEEV_API_KEY="sk-nc-…"

# No saved context in CI, so pass both --org and --project to each command.
SCOPE="--org <org-id> --project <project-id>"
neev-cli sandbox create --name "ci-$BUILD_ID" $SCOPE --label ci-run="$BUILD_ID" --wait
neev-cli sandbox fs upload "ci-$BUILD_ID" . /workspace/src $SCOPE
neev-cli sandbox exec "ci-$BUILD_ID" --cwd src $SCOPE -- make test
neev-cli sandbox delete "ci-$BUILD_ID" --yes $SCOPE
```

If the job only uses sandboxes, `NEEV_API_KEY` alone is enough. Commands exit non-zero
on failure, and `-o json` gives output you can parse.

## Troubleshooting

| Message | What to do |
| --- | --- |
| `not logged in: run 'neev-cli auth login'` | Sign in, or set `NEEV_API_TOKEN` or `NEEV_API_KEY` |
| `this command needs your account token` | `org`, `project`, `context`, `billing` and `airuntime` need your Personal Access Token, not the API key. Run `neev-cli auth login` or set `NEEV_API_TOKEN` |
| `no sandbox API key` | `exec`, `fs`, `ssh` and `proxy` need the sandbox API key. Save it with `neev-cli context set <name> --sandbox-api-key`, or set `NEEV_API_KEY` |
| `no project selected` | Set a context (`neev-cli context set`), or pass both `--org` and `--project` |
| A command inside the sandbox can't reach a host | Egress is closed by default. Check `neev-cli sandbox egress get <name>` and open the host with `neev-cli sandbox update <name> --allow-add <host>` |
| A preview URL answers 404 right after `port create` | The URL takes a few seconds to go live; `--wait` waits for it |
| A preview URL answers 503 | The sandbox is paused, or nothing is listening on that port yet |

## Next steps

- The [Sandboxes guide](./sandboxes.md) covers egress, preview URLs, SSH, snapshots
  and more; [Agents](./agents.md) and [AI runtimes](./ai-runtimes.md) cover the other
  products.
- [Configuration](./configuration.md) explains credentials, contexts and output formats.
- The [command reference](./command-reference.md) lists every command and flag.
- [`examples/`](../examples) has runnable scripts.
- [Connect from Claude Desktop](./claude-desktop-ssh.md) runs Claude Code inside a
  sandbox.
