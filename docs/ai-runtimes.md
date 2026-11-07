# AI runtimes

An AI runtime is a GPU environment, such as JupyterLab with PyTorch, started from a
runtime template on a pricing plan you choose. AI runtimes are addressed by ID.

| Capability | Commands |
| --- | --- |
| [Choose a template and plan](#choose-a-template-and-plan) | `airuntime template get`, `billing products get` |
| [Create a runtime](#create-a-runtime) | `airuntime create` |
| [Manage runtimes](#manage-runtimes) | `airuntime get / metrics / delete` |

## Choose a template and plan

```sh
neev-cli airuntime template get                 # the platform catalogue
neev-cli airuntime template get --org <org-id>  # your organization's own templates
neev-cli billing products get                   # plans and prices
```

## Create a runtime

```sh
neev-cli airuntime create --name notebook --region <region> \
  --template-id tpl-jupyterlab-pytorch \
  --gpu-config-id <gpu-config-id> --plan-id <plan-id> --gpu-count 1
```

Add `--ssh-key` (repeatable) to install your public keys. For storage, environment
variables or other settings, write the full request as JSON and pass it with
`--filename runtime.json`.

## Manage runtimes

```sh
neev-cli airuntime get                          # every runtime in the project
neev-cli airuntime get <airuntime-id>
neev-cli airuntime metrics <airuntime-id>       # utilization
neev-cli airuntime delete <airuntime-id> --yes
```

A runtime is billed on its plan until you delete it.

See the [command reference](./command-reference.md#ai-runtimes) for every flag.
