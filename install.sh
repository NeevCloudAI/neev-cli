#!/bin/sh
# neev-cli installer — downloads the right prebuilt binary for your OS/arch from the
# latest GitHub release, verifies its checksum, and installs it onto your PATH.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/NeevCloudAI/neev-cli/main/install.sh | sh
#
# Environment overrides:
#   NEEV_CLI_VERSION      pin a release tag instead of "latest" (e.g. v0.1.0)
#   NEEV_CLI_INSTALL_DIR  install destination (default: /usr/local/bin if writable, else ~/.local/bin)
#
# Release-asset contract (must stay in lockstep with the monorepo's .goreleaser.yaml):
#   archive       neev-cli_<os>_<arch>.tar.gz   (os: darwin|linux, arch: amd64|arm64)
#   checksums     checksums.txt                 (sha256, one line per asset)
#   binary inside the archive is named "neev-cli"
set -eu

REPO="NeevCloudAI/neev-cli"
BIN="neev-cli"

# err prints a message to stderr and exits non-zero.
err() {
	echo "neev-cli install: $*" >&2
	exit 1
}

# need verifies a required command exists, failing with a clear message if not.
need() {
	command -v "$1" >/dev/null 2>&1 || err "required command not found: $1"
}

# detect_os maps `uname -s` onto the OS token used in release asset names.
detect_os() {
	os=$(uname -s)
	case "$os" in
	Darwin) echo "darwin" ;;
	Linux) echo "linux" ;;
	*) err "unsupported OS: $os (install manually from https://github.com/$REPO/releases)" ;;
	esac
}

# detect_arch maps `uname -m` onto the arch token used in release asset names.
detect_arch() {
	arch=$(uname -m)
	case "$arch" in
	x86_64 | amd64) echo "amd64" ;;
	arm64 | aarch64) echo "arm64" ;;
	*) err "unsupported architecture: $arch" ;;
	esac
}

# download fetches a URL to a local path using whichever of curl/wget is present.
download() {
	url="$1"
	dest="$2"
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL "$url" -o "$dest" || err "download failed: $url"
	elif command -v wget >/dev/null 2>&1; then
		wget -qO "$dest" "$url" || err "download failed: $url"
	else
		err "need curl or wget to download releases"
	fi
}

# sha256 prints the SHA-256 hex digest of a file using sha256sum or shasum.
sha256() {
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum "$1" | awk '{print $1}'
	elif command -v shasum >/dev/null 2>&1; then
		shasum -a 256 "$1" | awk '{print $1}'
	else
		err "need sha256sum or shasum to verify the download"
	fi
}

# resolve_install_dir picks the destination: an explicit override, then a
# system-wide bin if writable, then the per-user ~/.local/bin fallback.
resolve_install_dir() {
	if [ -n "${NEEV_CLI_INSTALL_DIR:-}" ]; then
		echo "$NEEV_CLI_INSTALL_DIR"
	elif [ -w /usr/local/bin ] 2>/dev/null; then
		echo "/usr/local/bin"
	else
		echo "$HOME/.local/bin"
	fi
}

need tar
need awk

OS=$(detect_os)
ARCH=$(detect_arch)
ASSET="${BIN}_${OS}_${ARCH}.tar.gz"

# A pinned version downloads from its tag; "latest" uses GitHub's stable latest-asset URL.
if [ -n "${NEEV_CLI_VERSION:-}" ]; then
	BASE="https://github.com/$REPO/releases/download/${NEEV_CLI_VERSION}"
	echo "Installing $BIN $NEEV_CLI_VERSION ($OS/$ARCH)…"
else
	BASE="https://github.com/$REPO/releases/latest/download"
	echo "Installing latest $BIN ($OS/$ARCH)…"
fi

TMP=$(mktemp -d)
# Always clean the temp dir, whether install succeeds or aborts.
trap 'rm -rf "$TMP"' EXIT

download "$BASE/$ASSET" "$TMP/$ASSET"
download "$BASE/checksums.txt" "$TMP/checksums.txt"

# Verify the archive against its line in checksums.txt before trusting it.
want=$(awk -v f="$ASSET" '$2 == f || $2 == "*"f {print $1}' "$TMP/checksums.txt" | head -n1)
[ -n "$want" ] || err "no checksum entry for $ASSET in checksums.txt"
got=$(sha256 "$TMP/$ASSET")
[ "$want" = "$got" ] || err "checksum mismatch for $ASSET (want $want, got $got)"

tar -xzf "$TMP/$ASSET" -C "$TMP"
[ -f "$TMP/$BIN" ] || err "archive did not contain expected binary: $BIN"

DIR=$(resolve_install_dir)
mkdir -p "$DIR"
install -m 0755 "$TMP/$BIN" "$DIR/$BIN" 2>/dev/null ||
	{ cp "$TMP/$BIN" "$DIR/$BIN" && chmod 0755 "$DIR/$BIN"; } ||
	err "could not install to $DIR (set NEEV_CLI_INSTALL_DIR to a writable path)"

echo "Installed $BIN → $DIR/$BIN"

# Remind the user to add the install dir to PATH when it isn't already there.
case ":$PATH:" in
*":$DIR:"*) ;;
*) echo "Note: $DIR is not on your PATH. Add it, e.g.:  export PATH=\"$DIR:\$PATH\"" ;;
esac

"$DIR/$BIN" --version 2>/dev/null || true
