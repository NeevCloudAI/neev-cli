# Sandboxes

A sandbox is an isolated machine for running code, commands and servers. You create it
from a template, work inside it, and pause or delete it when you are done. Every command
addresses a sandbox by the name you gave it.

| Capability | Commands |
| --- | --- |
| [Sandbox lifecycle](#sandbox-lifecycle) | `sandbox create / get / describe / update / pause / resume / delete` |
| [Templates](#templates) | `sandbox template get` |
| [Commands](#commands) | `sandbox exec` |
| [Files](#files) | `sandbox fs read / write / get / upload / download` |
| [Preview URLs](#preview-urls) | `sandbox port create / get / delete` |
| [Network egress](#network-egress) | `sandbox create --allow`, `sandbox update --allow-add`, `sandbox egress get` |
| [Reach private hosts](#reach-private-hosts) | `sandbox proxy` |
| [SSH](#ssh) | `sandbox ssh-config write / get / delete` |
| [Snapshots, fork and rollback](#snapshots-fork-and-rollback) | `sandbox snapshot`, `sandbox fork`, `sandbox rollback` |
| [Labels](#labels) | `sandbox create --label`, `sandbox get -l` |
| [Metrics](#metrics) | `sandbox metrics` |

## Sandbox lifecycle

```sh
neev-cli sandbox create --name web --cpu 2 --memory-gb 4 --disk-gb 20 --env APP_ENV=dev --wait
neev-cli sandbox get                       # every sandbox in the project
neev-cli sandbox get web                   # one sandbox
neev-cli sandbox describe web              # every field
neev-cli sandbox update web --cpu 4 --memory-gb 8
neev-cli sandbox pause web                 # stop paying for compute; files are kept
neev-cli sandbox resume web --wait
neev-cli sandbox delete web --yes
```

| Resource | Allowed values |
| --- | --- |
| `--cpu` | 0.5 to 8 vCPUs, in steps of 0.5 |
| `--memory-gb` | 1 to 16 GB |
| `--disk-gb` | 10 to 100 GB, in steps of 10 |

`update` resizes CPU and memory in place, without a restart. Disk size is fixed at
create time.

`--wait` blocks until the sandbox reaches the state you asked for, then prints it. `get`
also filters (`--status Ready`, `--name web`), lists every project at once with `-A`,
and follows changes with `--watch`.

See [reference](./command-reference.md#sandbox-lifecycle)

## Templates

A template is the image a sandbox starts from. Omit `--template-id` to use the default,
or pick one from the catalogue.

```sh
neev-cli sandbox template get                        # the catalogue
neev-cli sandbox create --name box --template-id sb-ubuntu-26-04-docker --wait
```

Templates you can start from:

| Template | Use it for |
| --- | --- |
| `sb-ubuntu-26-04-dev` | General development: git, gh, Python 3, Node 24 LTS |
| `sb-ubuntu-26-04-docker` | Docker, Compose and Buildx, with Docker started at boot; run containers with `--network=host` |
| `sb-ubuntu-26-04-interpreter` | Python kernels that keep their state between runs, driven from the NeevCloud SDKs' code interpreter |
| `sb-ubuntu-26-04-playwright` | Browser testing: a desktop with Node 24, Playwright and Chromium, headless or headed (`DISPLAY=:1`) |

The catalogue grows over time, so `sandbox template get` is the source of truth.

See [reference](./command-reference.md#sandbox-template-get)

## Commands

`exec` runs a program inside the sandbox. Put it after `--`. Output streams to your
terminal as it runs. If the program fails, the CLI exits non-zero and reports its exit
code. With `-o json` it also prints the code in `exit_code`.

```sh
neev-cli sandbox exec web -- ls -la /workspace
neev-cli sandbox exec web --cwd app --env DEBUG=1 -- npm test
neev-cli sandbox exec web -o json -- python3 main.py    # {stdout, stderr, exit_code}
neev-cli sandbox exec web -it -- bash                   # an interactive shell
```

No shell is involved, so pipes and `&&` need one: `-- sh -c 'make && make test'`.
`-it` needs a real terminal; it forwards resizes and Ctrl-C.

See [reference](./command-reference.md#sandbox-exec)

## Files

Paths are relative to the sandbox's `/workspace`, or absolute inside it.

```sh
neev-cli sandbox fs write web app.py --in ./app.py    # --in - reads stdin
neev-cli sandbox fs read web app.py                   # --out ./app.py saves it
neev-cli sandbox fs get web src -R                    # list a directory tree
neev-cli sandbox fs upload web ./src /workspace/src   # copy a whole directory in
neev-cli sandbox fs download web /workspace/out ./out # and back out
```

`upload` sends several files at once and resumes a large file where it left off if the
connection drops.

See [reference](./command-reference.md#sandbox-fs)

## Preview URLs

Expose a port and get a public HTTPS URL for it. Start your server first, then:

```sh
neev-cli sandbox port create web --port 3000 --wait
```

```
PORT  URL
3000  https://3000-01a14875-3519-7a8a-84f5-e2ff32054938-3rjrg5v8.as-south-1.neevsandbox.app
```

`--wait` returns once your app answers on the URL. Anyone with the URL can open it
without signing in, so treat it as a secret.

```sh
neev-cli sandbox port get web                         # exposed ports
neev-cli sandbox port create web --port 3000 --slug a1b2c3d4   # replace the URL; the old one stops working
neev-cli sandbox port delete web --port 3000          # close it
```

See [reference](./command-reference.md#sandbox-port)

## Network egress

A new sandbox can reach no outside host unless its template opens some. Open what it
needs at create time, and change it later without a restart.

```sh
neev-cli sandbox create --name ci --allow github.com --allow pypi.org:443
neev-cli sandbox create --name web --allow-internet

neev-cli sandbox update ci --allow-add files.pythonhosted.org   # add a host, keep the rest
neev-cli sandbox update ci --allow-remove github.com            # remove one
neev-cli sandbox update ci --deny-all                           # close it
neev-cli sandbox egress get ci                                  # what it can reach
```

```
MODE        HOST        PORTS  PROTOCOL
allow_list  pypi.org    443    *
allow_list  github.com  *      *
```

A host is a domain (`github.com`), a wildcard (`*.github.com`), an IP address or CIDR
range, or an IPv6 address in brackets (`[2001:db8::1]:443`). Add `:PORT` to allow one
port only. `--allow` replaces the whole list; `--allow-add` and `--allow-remove` edit
it. A sandbox with egress closed has no list to edit: open it with `--allow` first.

See [reference](./command-reference.md#sandbox-update)

## Reach private hosts

`proxy` lets code in a sandbox reach a host that only your machine can reach, such as a
staging site behind your company VPN. Traffic leaves through your machine, and only to
the hosts you list.

```sh
neev-cli sandbox proxy web --allow-host staging.example.com:443
# then, inside the sandbox:
curl -x socks5h://127.0.0.1:1080 https://staging.example.com/
```

The proxy runs until you press Ctrl-C. It needs OpenSSH 8.7 or later on your machine
(9.2 or later for more than one host). For automation, `proxy -l KEY=VALUE` serves every
sandbox created with that label; see the [reference](./command-reference.md#sandbox-proxy)
before you use it, since anyone who can create a sandbox with the label in that project
gets the same access.

## SSH

`ssh-config write` adds a block to `~/.ssh/config`, so `ssh`, `scp` and `rsync`
connect by the sandbox's name.

```sh
neev-cli sandbox ssh-config write web
ssh web
rsync -a ./data/ web:/workspace/data/
scp -O ./data.csv web:/workspace/          # -O: sandboxes don't run SFTP
neev-cli sandbox ssh-config delete web     # remove the block
```

Each connection uses the sandbox API key saved on your context, or `NEEV_API_KEY`. To
run Claude Code inside a sandbox from the Claude Desktop app, see
[Connect from Claude Desktop](./claude-desktop-ssh.md).

## Snapshots, fork and rollback

A snapshot captures a sandbox's full state: its files and the memory of its running
processes. Roll the sandbox back to it later, fork the sandbox's current state into a
new one, or restore a snapshot into a new sandbox.

```sh
neev-cli sandbox snapshot create web --name checkpoint   # starts Pending, then Ready
neev-cli sandbox snapshot get web                        # the sandbox's snapshots and their ids
neev-cli sandbox rollback web --snapshot <snapshot-id> --wait   # back to the snapshot, in place
neev-cli sandbox fork web --as web-copy --wait           # a new sandbox from the current state
neev-cli sandbox create --name web-restored --restore <snapshot-id> --wait
```

Deleting a sandbox deletes its snapshots too. To keep a state, restore it into a new
sandbox first.

See [reference](./command-reference.md#sandbox-snapshot)

## Labels

Labels are `KEY=VALUE` tags you attach at create time and filter by later.

```sh
neev-cli sandbox create --name e2e-4821 --label team=payments --label ci-run=4821
neev-cli sandbox get -l team=payments
```

A sandbox takes up to 16 labels; `-l` keeps only sandboxes that carry every label you
give.

## Metrics

```sh
neev-cli sandbox metrics web --step 60s
```

```
METRIC              LATEST  MIN    MAX    AVG    POINTS
cpu_usage_cores     0.024   0.004  0.024  0.009  46
memory_usage_bytes  55.1M   21.5M  55.1M  45.7M  46
disk_usage_bytes    50.0K   48.0K  50.0K  48.0K  46
```

The window is the last hour unless you pass `--from` and `--to` (RFC 3339 times).

See the [command reference](./command-reference.md#sandboxes) for every flag.
