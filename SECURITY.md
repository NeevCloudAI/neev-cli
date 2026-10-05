# Security Policy

## Reporting a vulnerability

If you discover a security vulnerability in `neev-cli` or its installer, please
report it privately. **Do not open a public GitHub issue for security reports.**

- Email **security@neevcloud.com** with details, or
- Use GitHub's [private vulnerability reporting](https://github.com/NeevCloudAI/neev-cli/security/advisories/new) for this repository.

Please include:

- A description of the issue and its impact
- Steps to reproduce or a proof of concept
- The affected version (`neev-cli --version`) and your OS and architecture

We aim to acknowledge reports within **3 business days** and to provide a
remediation timeline after triage. We will coordinate a disclosure date with you
and credit you in the release notes unless you prefer to remain anonymous.

## Supported versions

Security fixes ship in a new release. Only the latest release on the
[Releases](https://github.com/NeevCloudAI/neev-cli/releases) page is supported;
upgrade by re-running the installer.

## Verifying what you install

The installer downloads the release archive for your platform and verifies its
checksum before installing. If you download a release by hand, check it against
the checksums file published with that release.

## Handling credentials

- Sign in with `neev-cli auth login` (the token input is hidden on a TTY) or
  `--token-stdin`, or set `NEEV_API_TOKEN` for a single command. Never pass a
  token as a plain flag: it would leak into shell history and the process list.
- Sandbox runtime commands read the sandbox API key from `NEEV_API_KEY`.
- Never commit tokens or keys to version control. Run `neev-cli auth logout` to
  clear the local session on a shared machine.
