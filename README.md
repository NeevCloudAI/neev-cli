# neev-cli

Official command-line interface for the **NeevCloud AI platform** — manage organizations, projects, AI runtimes, and billing from your terminal.

This repository distributes the prebuilt `neev-cli` binaries and the installer. Releases are published by the NeevCloud platform release pipeline; see [Releases](https://github.com/NeevCloudAI/neev-cli/releases) for downloads and changelogs.

## Install

### Quick install (macOS / Linux, any arch)

```sh
curl -fsSL https://raw.githubusercontent.com/NeevCloudAI/neev-cli/main/install.sh | sh
```

The script detects your OS and architecture, downloads the matching release archive, verifies its checksum, and installs `neev-cli` to `/usr/local/bin` (or `~/.local/bin` if that isn't writable).

Pin a specific version, or change the install location:

```sh
curl -fsSL https://raw.githubusercontent.com/NeevCloudAI/neev-cli/main/install.sh | NEEV_CLI_VERSION=v0.1.0 sh
curl -fsSL https://raw.githubusercontent.com/NeevCloudAI/neev-cli/main/install.sh | NEEV_CLI_INSTALL_DIR="$HOME/bin" sh
```

### Manual download

Grab the archive for your platform from the [latest release](https://github.com/NeevCloudAI/neev-cli/releases/latest), verify it against `checksums.txt`, extract, and move `neev-cli` onto your `PATH`:

```sh
tar -xzf neev-cli_darwin_arm64.tar.gz
sudo mv neev-cli /usr/local/bin/
```

### Windows

Download `neev-cli_windows_amd64.zip` (or `arm64`) from the [latest release](https://github.com/NeevCloudAI/neev-cli/releases/latest), extract it, and add the folder to your `PATH`.

## Quickstart

```sh
# Sign in with a Personal Access Token (mint one in the web UI), then paste it
neev-cli auth login
# For scripts/CI, pipe the token instead of prompting:
#   echo "$NEEVCLOUD_API_TOKEN" | neev-cli auth login --token-stdin

# Explore your resources
neev-cli org list
neev-cli project list --org-id <org-id>
neev-cli airuntime list --org-id <org-id> --project-id <project-id>

# Billing
neev-cli billing products list

# Version / help
neev-cli version
neev-cli --help
```

See [`examples/`](examples/) for fuller flows.

## Support & issues

- **API documentation:** https://docs.neevcloud.com
- **Bugs / feature requests:** open an issue on this repository.

This repository hosts distribution artifacts only; the CLI is developed inside the NeevCloud platform. File issues here and the team will route them.

## License

[Apache-2.0](LICENSE).
