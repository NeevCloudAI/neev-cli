# neev-cli examples

Short, copy-pasteable flows for common tasks. Replace `<org-id>` / `<project-id>` with
your own identifiers, and run `neev-cli <command> --help` for the full flag set.

## 1. Sign in and pin an environment

```sh
# Authenticate (dev/staging password login; see `auth login --help` for flags)
neev-cli auth login --tenant-url https://tenant.dev.ai.neevcloud.com

# Persist the tenant URL so later commands don't need the flag
neev-cli config set tenant-url https://tenant.dev.ai.neevcloud.com

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

## 3. Work with AI runtimes

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

## 4. Billing

```sh
neev-cli billing products list
```

## Scripting tip

Commands print JSON to stdout, so they compose with `jq`:

```sh
neev-cli project list --org-id <org-id> | jq -r '.data[].id'
```
