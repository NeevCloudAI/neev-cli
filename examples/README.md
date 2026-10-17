# Examples

Runnable scripts, one per area. Each creates real resources in your project and deletes
them when it finishes, even if a step fails.

| Script | What it does |
| --- | --- |
| [`quickstart.sh`](./quickstart.sh) | Check the install, sign in, and save a context. Run it first |
| [`sandbox.sh`](./sandbox.sh) | Create a sandbox, run commands, copy files in and out, read metrics, pause and resume |
| [`networking.sh`](./networking.sh) | Serve an app at a public preview URL, and allow or block outbound hosts |
| [`snapshots.sh`](./snapshots.sh) | Snapshot a sandbox, roll it back, fork it, and restore the snapshot into a new sandbox |
| [`agent.sh`](./agent.sh) | Create a Claude Code agent, work inside it, resize, pause and resume it |
| [`airuntime.sh`](./airuntime.sh) | Create a GPU runtime from a request file, inspect it, read its metrics |
| [`account.sh`](./account.sh) | List organizations, projects, prices and saved contexts |

## Setup

You need `neev-cli`, [`jq`](https://jqlang.github.io/jq/), a Personal Access Token and a
sandbox API key (see [Getting started](../docs/getting-started.md#before-you-start)).
Then save a context once:

```sh
./examples/quickstart.sh <org> <project>
```

`<org>` and `<project>` are IDs or display names. To find them, see
[Organizations and projects](https://docs.ai.neevcloud.com/getting-started/org-and-project#find-your-organization-id-and-project-id),
or sign in and run `neev-cli context get`.

## Run

```sh
./examples/sandbox.sh
./examples/networking.sh
./examples/snapshots.sh
./examples/agent.sh            # AGENT_TEMPLATE=codex-cli to try another agent
./examples/account.sh
```

`airuntime.sh` creates a billed GPU runtime. Fill in the region, GPU configuration and
plan in the script before running it.

## Patterns worth copying

- **Names, not IDs.** Each script names its sandbox and uses that name everywhere.
- **`--wait`** on create, pause, resume, rollback and fork, so each step starts once the
  last one has finished.
- **`trap … EXIT`** to delete what the script created, whatever happens.
- **`-o json | jq`** to read a field, such as a preview URL or snapshot ID.
