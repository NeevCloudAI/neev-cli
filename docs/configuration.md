# Configuration

How `neev-cli` authenticates, picks the project to work in, and formats its output.

- [Credentials](#credentials)
- [Contexts](#contexts)
- [Output](#output)
- [Scripting](#scripting)
- [Shell completion](#shell-completion)
- [Help](#help)

## Credentials

The CLI uses two credentials, and they are not interchangeable.

| Credential | Looks like | Covers | How to provide it |
| --- | --- | --- | --- |
| Personal Access Token | `pat-nc-…` | Your account: organizations, projects, billing, AI runtimes, and sandbox and agent lifecycle | `neev-cli auth login`, or `NEEV_API_TOKEN` |
| Sandbox API key | `sk-nc-…` | Working inside sandboxes and agents: `exec`, `fs`, `proxy`, `ssh`; also sandbox and agent lifecycle | `context set --sandbox-api-key`, or `NEEV_API_KEY` |

Create both in the [console](https://console.ai.neevcloud.com); for the API key, choose
the sandbox resource type ([how](https://docs.ai.neevcloud.com/getting-started/create-api-key)).
With only an API key, sandbox and agent commands work and account commands do not.

No command takes a secret as a flag value, because it would end up in your shell
history and the process list. Use the prompt, stdin or the environment:

```sh
echo "$NEEV_API_TOKEN" | neev-cli auth login --token-stdin
echo "$NEEV_API_KEY"   | neev-cli context set ci --org <org-id> --project <project-id> --sandbox-api-key
```

In CI you can skip both and set the variables: `NEEV_API_TOKEN` and `NEEV_API_KEY` take
precedence over anything saved. `neev-cli auth status` shows what is in use, and
`auth logout` removes the saved session (revoke the token itself in the console).

## Contexts

A context is a saved organization and project. The current one fills in `--org` and
`--project` for every command, so you rarely type them. To find your IDs, see
[Organizations and projects](https://docs.ai.neevcloud.com/getting-started/org-and-project#find-your-organization-id-and-project-id),
or run `neev-cli context get`.

```sh
neev-cli context get                                          # saved contexts and what you can access
neev-cli context set prod --org Acme --project Default        # names or IDs both work
neev-cli context use dev                                      # switch
neev-cli context current
neev-cli sandbox get --project <other-project-id>             # a flag always wins
```

## Output

Every command prints a table by default. `-o` picks another format:

| Format | Use it for |
| --- | --- |
| `table` | Reading (default). `--no-headers` drops the header row |
| `wide` | A table with more columns |
| `json`, `yaml` | Scripts and tools such as `jq` |
| `name` | One `kind/id` per line, such as `sandbox/01a1…` |

```sh
neev-cli sandbox get -o json | jq -r '.items[].name'
neev-cli sandbox get --status Paused -o name | cut -d/ -f2   # IDs, which any command accepts in place of a name
```

## Scripting

- Commands exit non-zero on failure, including `exec` when the program it runs fails.
- `--wait` makes create, pause, resume, rollback, fork and delete block until done
  (`--timeout` sets the limit, 5 minutes by default).
- Destructive commands ask for confirmation; `--yes` skips it.
- `--filename request.json` (or `-` for stdin) sends a full request body to `create`
  and `update` when the flags don't cover what you need.

## Shell completion

```sh
neev-cli completion zsh > "${fpath[1]}/_neev-cli"       # zsh
neev-cli completion bash > /etc/bash_completion.d/neev-cli
neev-cli completion fish > ~/.config/fish/completions/neev-cli.fish
```

Completion suggests your sandbox, agent and template names as you type.

## Help

Every command and group has `--help`, with examples. The
[command reference](./command-reference.md) lists them all in one place.
