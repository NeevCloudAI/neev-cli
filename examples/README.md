# neev-cli examples

Short, copy-pasteable flows for common tasks. Replace `<org-id>` / `<project-id>`
/ `<sandbox-id>` with your own identifiers, and run `neev-cli <command> --help`
for the full flag set.

The runnable scripts in this folder need [`jq`](https://jqlang.github.io/jq/) and,
for anything that runs inside a sandbox, `NEEV_API_KEY` set to a sandbox API key.

| Script | What it does |
| ------ | ------------ |
| [`first-sandbox.sh`](first-sandbox.sh) | Create a sandbox, wait until Ready, run a command, write/read a file, delete it |
| [`files.sh`](files.sh) | Upload, read, and list files in a sandbox workspace |
| [`processes.sh`](processes.sh) | Start a detached process, follow its logs, inspect and signal it |
| [`snapshots-fork-restore.sh`](snapshots-fork-restore.sh) | Snapshot a sandbox, restore in place, and fork its live state |
| [`metrics.sh`](metrics.sh) | Read live health metrics for a sandbox |

## 1. Sign in

```sh
# Authenticate with a Personal Access Token (mint one in the web UI). `auth login`
# prompts for the PAT; pipe it with --token-stdin for scripts/CI.
neev-cli auth login
echo "$NEEV_API_TOKEN" | neev-cli auth login --token-stdin

# Confirm the active session
neev-cli auth status
```

## 2. Browse organizations and projects

```sh
neev-cli org list
neev-cli org get --org-id <org-id>

neev-cli project list --org-id <org-id>
neev-cli project get --org-id <org-id> --project-id <project-id>
```

Save a default org + project once so later commands can omit the flags:

```sh
neev-cli context set default <org-id> <project-id>   # saved and made current
neev-cli context current
```

## 3. Create and use a sandbox

```sh
# Create from a template (omit --template-id to use the platform default).
neev-cli sandbox create --name my-agent --template-id sb-ubuntu-26-04-minimal \
  --cpu 1 --memory-gb 2 --disk-gb 10

# Runtime commands (fs/exec/process) need a sandbox API key.
export NEEV_API_KEY="your-sandbox-api-key"

# Run a command; -- separates the program from CLI flags.
neev-cli sandbox exec --sandbox-id <sandbox-id> -- ls -la /workspace

# Stream output live, or attach an interactive terminal.
neev-cli sandbox exec --sandbox-id <sandbox-id> --stream -- python main.py
neev-cli sandbox exec --sandbox-id <sandbox-id> -it -- bash

# Pause, resume, delete.
neev-cli sandbox pause  --sandbox-id <sandbox-id>
neev-cli sandbox resume --sandbox-id <sandbox-id>
neev-cli sandbox delete --sandbox-id <sandbox-id> --yes
```

The [`first-sandbox.sh`](first-sandbox.sh) script runs this whole flow end to end.

## 4. Work with AI runtimes

```sh
# List available templates, then list running runtimes
neev-cli airuntime template list
neev-cli airuntime list --org-id <org-id> --project-id <project-id>

# Create a runtime from a request file
cat > runtime.json <<'JSON'
{
  "name": "my-jupyter",
  "region": "as-south-1",
  "templateID": "tpl-jupyterlab-pytorch",
  "planId": "gpu-h200-on-demand-1h",
  "gpuCount": 1
}
JSON
neev-cli airuntime create --org-id <org-id> --project-id <project-id> --from-file runtime.json

# Inspect, watch metrics, then tear it down
neev-cli airuntime get     --org-id <org-id> --project-id <project-id> --airuntime-id <id>
neev-cli airuntime metrics --org-id <org-id> --project-id <project-id> --airuntime-id <id>
neev-cli airuntime delete  --org-id <org-id> --project-id <project-id> --airuntime-id <id> --yes
```

## 5. Billing

```sh
neev-cli billing products list
```

## Scripting tip

Commands print JSON to stdout, so they compose with `jq`. Note the envelope
differs by resource — org/project lists use `.data[]`, while sandbox lists use
`.items[]`:

```sh
neev-cli project list --org-id <org-id> | jq -r '.data[].id'
neev-cli sandbox list --org-id <org-id> --project-id <project-id> | jq -r '.items[].id'
```
