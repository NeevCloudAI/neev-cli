# Use neev-cli from an AI agent

This page lets a coding agent, such as Claude Code, Cursor or Codex, use NeevCloud
through `neev-cli` without guessing. The first part is for you: prompts to paste into
your agent. The rest is for the agent: the rules, recipes and error handling it should
follow.

- [Prompts to paste](#prompts-to-paste)
- [For agents: before the first command](#for-agents-before-the-first-command)
- [For agents: rules](#for-agents-rules)
- [Sandboxes](#sandboxes)
- [Agents](#agents)
- [AI runtimes](#ai-runtimes)
- [Account](#account)
- [Reading output](#reading-output)
- [Errors and what to do](#errors-and-what-to-do)

## Prompts to paste

Each prompt points your agent at this page, so it picks up the rules below. Set
`NEEV_API_TOKEN` and `NEEV_API_KEY` in the agent's environment first, or sign in with
`neev-cli auth login` and save a context yourself; never paste a token into the chat.

**General setup**

```md
Read https://raw.githubusercontent.com/NeevCloudAI/neev-cli/main/docs/ai-agents.md and
follow it to use NeevCloud through neev-cli. Run its pre-flight checks, tell me which
organization and project you will use, and wait for my go-ahead before creating anything.
```

**Run code in a sandbox**

```md
Read https://raw.githubusercontent.com/NeevCloudAI/neev-cli/main/docs/ai-agents.md.
Create a NeevCloud sandbox, copy this repository into it, install its dependencies and
run its test suite there. Report the results, then delete the sandbox.
```

**Preview a web app**

```md
Read https://raw.githubusercontent.com/NeevCloudAI/neev-cli/main/docs/ai-agents.md.
Run this app in a NeevCloud sandbox, expose its port, and give me the preview URL. Keep
the sandbox running until I tell you to delete it.
```

**Start a coding agent**

```md
Read https://raw.githubusercontent.com/NeevCloudAI/neev-cli/main/docs/ai-agents.md.
Create a NeevCloud claude-code agent named reviewer, upload this repository to it, and
tell me the command to open an interactive Claude Code session in it.
```

**GPU runtime**

```md
Read https://raw.githubusercontent.com/NeevCloudAI/neev-cli/main/docs/ai-agents.md.
List the NeevCloud AI runtime templates and plans, recommend one for fine-tuning a 7B
model, and show me the cost before you create anything.
```

If your agent supports MCP, the
[Sandbox MCP server](https://docs.ai.neevcloud.com/agentic-studio/Sandbox/sandbox-mcp-server)
gives it sandbox tools directly, without the CLI.

---

## For agents: before the first command

Run these checks in order. Stop and ask the user only when a check fails.

1. **Installed?** Run `neev-cli version`. If it fails, install it: on macOS and Linux,
   `curl -fsSL https://raw.githubusercontent.com/NeevCloudAI/neev-cli/main/install.sh | sh`.
   On Windows, give the user the manual steps from the
   [README](../README.md#install) instead of installing it yourself.
2. **Credentials?** Run `neev-cli auth status`.
   - If it succeeds (it does when the user signed in or set `NEEV_API_TOKEN`), every
     command works.
   - If it fails but `NEEV_API_KEY` is set, sandbox and agent commands still work;
     account and AI runtime commands don't. Carry on if the task only needs sandboxes
     or agents.
   - If it fails and `NEEV_API_KEY` isn't set, stop and ask the user to set
     `NEEV_API_TOKEN` and `NEEV_API_KEY`, or to run `neev-cli auth login` themselves.
     Never ask them to paste a token into the chat, and never put a token on a command
     line.
3. **Project?** Run `neev-cli context current`. It exits 0 either way, so read what it
   prints.
   - If it names a context, use it, and tell the user which one.
   - If it says `no current context`, run `neev-cli context get` and ask the user which
     organization and project to use. (With only `NEEV_API_KEY`, that list isn't
     available; ask the user for the IDs, which
     [Organizations and projects](https://docs.ai.neevcloud.com/getting-started/org-and-project#find-your-organization-id-and-project-id)
     shows how to find.) Then pass `--org <org-id> --project <project-id>` on every
     command; don't create a context unless the user asks.
4. **Runtime key?** Commands that run inside a sandbox (`exec`, `fs`, `proxy`, `ssh`)
   need the sandbox API key, either saved on the context or in `NEEV_API_KEY`. If one
   fails with `no sandbox API key`, ask the user to provide it that way.

## For agents: rules

1. **Never use an interactive mode.** No `-it`/`-t`/`-i` on `exec`, and no prompts.
   You have no terminal; these fail. Feed input with `--stdin` instead.
2. **Read JSON, not tables.** Add `-o json` whenever you need a value from the output.
3. **Wait for state changes.** Add `--wait` to `create`, `pause`, `resume`, `rollback`,
   `fork` and `delete`, so the next command starts once the change is done.
4. **Confirm before destroying or spending.** Ask the user before `delete`, `rollback`,
   `port delete`, `snapshot delete`, `update --deny-all`, or creating an AI runtime
   (it is billed until deleted). Once they agree, pass `--yes`; without a terminal,
   destructive commands refuse to run without it.
5. **Name what you create.** Use a short, unique name such as `agent-tests-4821`, and
   address it by that name afterwards.
6. **Clean up.** Delete the sandboxes and agents you created when the task is done,
   unless the user wants them kept. Tell the user what is still running.
7. **Open only the egress you need.** Prefer `--allow <host>` over `--allow-internet`,
   and mention any host you open.
8. **Preview URLs are public.** Anyone with one can open it. Give it only to the user,
   and close it with `port delete` when done.
9. **Check `--help` before guessing.** Every command documents its flags and examples:
   `neev-cli <command> --help`.

## Sandboxes

A sandbox is an isolated Linux machine. Inside it you are `root`, the working directory
is `/workspace`, and outbound network access is closed unless its template or you open
it.

**Create and remove**

```sh
neev-cli sandbox template get -o json                     # templates; omit --template-id for the default
neev-cli sandbox create --name task-4821 --wait -o json   # add --allow HOST or --allow-internet for network
neev-cli sandbox delete task-4821 --yes --wait
```

| Template | Use it for |
| --- | --- |
| `sb-ubuntu-26-04-dev` (default) | General development: git, gh, Python 3, Node 24 |
| `sb-ubuntu-26-04-docker` | Docker; run containers with `--network=host` |
| `sb-ubuntu-26-04-interpreter` | Python kernels that keep state between runs; drive them from the NeevCloud SDKs' code interpreter, since the CLI has no command for it |
| `sb-ubuntu-26-04-playwright` | Browser automation with Playwright and Chromium |

**Run commands.** Everything after `--` runs directly, without a shell; use `sh -c` for
pipes, `&&`, redirects or environment variables. A failing program makes the CLI exit
non-zero, with its exit code in the error; with `-o json` you also get
`{stdout, stderr, exit_code}`.

```sh
neev-cli sandbox exec task-4821 -- python3 --version
neev-cli sandbox exec task-4821 --cwd app -- sh -c 'pip install -r requirements.txt && pytest -q'
neev-cli sandbox exec task-4821 -o json -- python3 main.py
```

**Long-running work.** A call that prints nothing for about two minutes can be cut off,
so start long jobs and servers in the background with a log, then poll:

```sh
neev-cli sandbox exec task-4821 --cwd app -- sh -c 'nohup make build > build.log 2>&1 & echo started'
neev-cli sandbox exec task-4821 --cwd app -- tail -n 20 build.log
```

**Files.** Paths are relative to `/workspace`, or absolute inside it.

```sh
neev-cli sandbox fs upload task-4821 . /workspace/app            # copy the current project in
neev-cli sandbox fs write task-4821 app/config.json --in ./config.json
neev-cli sandbox fs read task-4821 app/result.txt
neev-cli sandbox fs get task-4821 app -R -o json                 # list files
neev-cli sandbox fs download task-4821 /workspace/app/dist ./dist
```

`fs upload` copies everything under the directory, including `.env` files, credentials,
`.git` and `node_modules`. Upload only what the task needs, such as a clean checkout
(`git archive` or `git worktree`) or the specific files, and never upload secrets the
user hasn't asked you to.

**Network access**

```sh
neev-cli sandbox egress get task-4821 -o json
neev-cli sandbox update task-4821 --allow pypi.org --allow files.pythonhosted.org   # replace the list
neev-cli sandbox update task-4821 --allow-add registry.npmjs.org                     # add one, keep the rest
```

`--allow-add` fails on a sandbox whose egress is closed; use `--allow` first. A host is a
domain, `*.domain`, an IP or CIDR, or `[IPv6]`, optionally with `:PORT`; never a URL.

**Preview a web app.** Start the server in the background, bound to `0.0.0.0`, then:

```sh
neev-cli sandbox exec task-4821 --cwd app -- sh -c 'nohup npm run dev -- --host 0.0.0.0 --port 3000 > dev.log 2>&1 &'
neev-cli sandbox port create task-4821 --port 3000 --wait -o json   # .items[0].preview_url
```

If `--wait` times out, the URL is still printed: check the server log, since nothing is
answering on the port yet.

**Checkpoints.** Snapshot before a risky change and roll back if it goes wrong.

```sh
neev-cli sandbox snapshot create task-4821 --name before-migration -o json   # .id
neev-cli sandbox snapshot show <snapshot-id> -o json                          # wait for "status": "Ready"
neev-cli sandbox rollback task-4821 --snapshot <snapshot-id> --yes --wait
neev-cli sandbox fork task-4821 --as task-4821-alt --wait                     # try something in parallel
```

Deleting a sandbox deletes its snapshots too.

**Pause instead of delete** to keep files but stop paying for compute:
`neev-cli sandbox pause task-4821 --wait`, and `resume … --wait` later.

## Agents

An agent is a ready-made coding agent (Claude Code, Codex and others) on its own
sandbox. `neev-cli agent` takes the same commands and flags as `neev-cli sandbox`,
addressed by the agent's name.

```sh
neev-cli agent template get -o json                                       # available agents
neev-cli agent create --name reviewer --agent-template claude-code --wait -o json
neev-cli agent fs upload reviewer . /workspace/repo
neev-cli agent exec reviewer --cwd repo -- git log --oneline -5
neev-cli agent snapshot create reviewer --name before-review -o json   # .id
neev-cli agent rollback reviewer --snapshot <snapshot-id> --yes --wait
neev-cli agent delete reviewer --yes --wait
```

The template already allows the hosts the agent needs. Don't pass `--allow` to
`agent create`, since it replaces that list; add hosts afterwards with
`neev-cli agent update <name> --allow-add <host>`.

The coding agent in a new agent isn't signed in to its model provider yet, so don't run
it non-interactively (such as `claude -p`) until the user has. Give the user the command
to open an interactive session, `neev-cli agent exec <name> -it -- claude`, and let them
sign in there.

## AI runtimes

An AI runtime is a billed GPU environment. Always show the user the template, plan and
price, and get their approval, before `create`.

```sh
neev-cli airuntime template get -o json
neev-cli billing products get -o json
neev-cli airuntime create --name notebook --region <region> --template-id <tpl-id> \
  --gpu-config-id <gpu-config-id> --plan-id <plan-id> --gpu-count 1 -o json   # .id
neev-cli airuntime get <airuntime-id> -o json
neev-cli airuntime delete <airuntime-id> --yes
```

AI runtimes are addressed by ID, not name, and need the Personal Access Token.

## Account

```sh
neev-cli org get -o json            # .data[]
neev-cli project get -o json        # .data[]
neev-cli context get                # saved contexts and accessible projects
```

## Reading output

| Command | JSON shape |
| --- | --- |
| `create`, `update`, `describe NAME` | One object: `.id`, `.name`, `.phase` … |
| `get` (sandboxes, agents, templates, snapshots, ports) | `{"items": [...]}`, even for one name |
| `org get`, `project get` | `{"data": [...]}` |
| `exec -o json` | `{"stdout", "stderr", "exit_code"}` |
| `port create -o json` / `port get -o json` | `{"items": [{"port", "slug", "preview_url"}]}` |

Progress lines from `--wait` go to stderr, so stdout stays valid JSON. Sandboxes and
agents are `Ready` when usable; snapshots are `Ready` when they can be restored.

## Errors and what to do

| Message contains | Do this |
| --- | --- |
| `not logged in` | Ask the user to set `NEEV_API_TOKEN` or run `neev-cli auth login` |
| `this command needs your account token` | The command needs the Personal Access Token, not the API key. Ask the user for `NEEV_API_TOKEN` |
| `no sandbox API key` | Ask the user to set `NEEV_API_KEY` or save it on the context |
| `no project selected` | Pass `--org` and `--project`, or ask the user which context to use |
| `refusing to prompt: stdin is not a terminal` | Confirm with the user, then add `--yes` |
| `requires a terminal on stdin` | Drop `-it`; pass input with `--stdin` instead |
| `command exited with code N` | The program inside the sandbox failed; read its output, fix, and rerun |
| `egress is closed, so there is no allow-list to add to` | Use `update --allow <host>` first, then `--allow-add` |
| `expected a host, not a URL` | Pass `github.com`, not `https://github.com` |
| `already exists` | Pick another name, or reuse the existing sandbox if it's yours |
| `sandbox not resolvable yet` | The sandbox was just created and isn't routable yet; wait a few seconds and retry |
| `Resolving timed out` or `Could not resolve host` inside the sandbox | The host isn't allowed: check `egress get` and add it |
| Preview URL answers 503 | Nothing is listening on that port, or the sandbox is paused |
