#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${HDR_REPO_URL:-https://github.com/HDR-Development/HewDraw-Remix}"
RUST_TOOLCHAIN="${HDR_RUST_TOOLCHAIN:-nightly-2026-02-14}"
GH_VERSION="${HDR_GH_VERSION:-2.92.0}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

log() {
	printf '\n==> %s\n' "$*"
}

warn() {
	printf '\nWARNING: %s\n' "$*" >&2
}

die() {
	printf '\nERROR: %s\n' "$*" >&2
	exit 1
}

sudo_cmd() {
	if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
		"$@"
	else
		sudo "$@"
	fi
}

is_wsl() {
	grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null
}

require_ubuntu_wsl() {
	if ! is_wsl; then
		warn "This script is intended for Ubuntu-based distros in WSL."
	fi

	if ! command -v apt-get >/dev/null 2>&1; then
		die "apt-get was not found. Use an Ubuntu-based WSL distro."
	fi
}

python_is_new_enough() {
	command -v python3 >/dev/null 2>&1 && python3 - <<'PY'
import sys
raise SystemExit(0 if sys.version_info >= (3, 9) else 1)
PY
}

ensure_system_packages() {
	local packages=(
		ca-certificates
		curl
		git
		tar
		gzip
		build-essential
		pkg-config
		libssl-dev
		python3
		python3-venv
		python3-pip
		iproute2
		iputils-ping
		ripgrep
	)

	local needs_install=0
	local cmd
	for cmd in curl git tar gzip python3 ip rg; do
		if ! command -v "$cmd" >/dev/null 2>&1; then
			needs_install=1
		fi
	done

	if ! python_is_new_enough; then
		needs_install=1
	fi

	if [[ "$needs_install" -eq 1 ]]; then
		log "Installing WSL packages"
		sudo_cmd apt-get update
		sudo_cmd apt-get install -y "${packages[@]}"
	fi

	if ! python_is_new_enough; then
		die "python3 is still older than 3.9 after apt install. Install Python 3.9 or newer for this distro."
	fi
}

find_existing_repo() {
	local dir="$PWD"

	while [[ "$dir" != "/" ]]; do
		if [[ -f "$dir/Cargo.toml" && -f "$dir/scripts/build.py" ]]; then
			printf '%s\n' "$dir"
			return 0
		fi
		dir="$(dirname "$dir")"
	done

	return 1
}

clone_or_find_repo() {
	local existing=""
	if existing="$(find_existing_repo 2>/dev/null)"; then
		REPO_ROOT="$existing"
		BASE_DIR="${BASE_DIR:-$(dirname "$REPO_ROOT")}"
		log "Using existing HewDraw-Remix checkout"
		return 0
	fi

	BASE_DIR="${BASE_DIR:-${HDR_WORKSPACE_DIR:-$SCRIPT_DIR}}"
	REPO_ROOT="${HDR_REPO_ROOT:-$BASE_DIR/HewDraw-Remix}"

	if [[ -d "$REPO_ROOT/.git" ]]; then
		log "Using existing repo at $REPO_ROOT"
	elif [[ -e "$REPO_ROOT" ]]; then
		die "$REPO_ROOT exists but is not a git repo"
	else
		log "Cloning HewDraw-Remix"
		git clone "$REPO_URL" "$REPO_ROOT"
	fi
}

activate_local_rust_env() {
	BASE_DIR="${BASE_DIR:-${HDR_WORKSPACE_DIR:-$SCRIPT_DIR}}"
	ENV_ROOT="${HDR_ENV_ROOT:-$BASE_DIR/.hdr-wsl-dev}"
	export RUSTUP_HOME="$ENV_ROOT/rustup"
	export CARGO_HOME="$ENV_ROOT/cargo"
	export GH_CONFIG_DIR="$ENV_ROOT/gh-config"
	export PATH="$CARGO_HOME/bin:$PATH"
	export SKYLINE_ADD_NRO_HEADER=1
	export RUSTFLAGS="--cfg skyline_std_v3"

	mkdir -p "$RUSTUP_HOME" "$CARGO_HOME/bin" "$GH_CONFIG_DIR"
}

write_env_file() {
	local env_file="$ENV_ROOT/env.sh"
	local q_env_root q_rustup_home q_cargo_home q_gh_config_dir q_rustflags q_repo_root

	printf -v q_env_root '%q' "$ENV_ROOT"
	printf -v q_rustup_home '%q' "$RUSTUP_HOME"
	printf -v q_cargo_home '%q' "$CARGO_HOME"
	printf -v q_gh_config_dir '%q' "$GH_CONFIG_DIR"
	printf -v q_rustflags '%q' "$RUSTFLAGS"
	printf -v q_repo_root '%q' "$REPO_ROOT"

	mkdir -p "$ENV_ROOT"
	cat >"$env_file" <<EOF
# shellcheck shell=bash
# Source this file to use the local HDR WSL Rust environment.

__hdr_env_root=$q_env_root
__hdr_env_file="\$__hdr_env_root/env.sh"
__hdr_backup_file="\$__hdr_env_root/env_backup.ini"
__hdr_backup_vars=(HDR_DEV_ENV_ROOT HDR_DEV_ENV_ACTIVE RUSTUP_HOME CARGO_HOME GH_CONFIG_DIR GH_TOKEN GITHUB_TOKEN PATH SKYLINE_ADD_NRO_HEADER RUSTFLAGS PS1)

__hdr_write_backup() {
    mkdir -p "\$__hdr_env_root"
    {
        printf '# shellcheck shell=bash\n'
        printf '# Backup created by env.sh; source env.sh --undo to restore it.\n'

        local __hdr_var __hdr_decl
        for __hdr_var in "\${__hdr_backup_vars[@]}"; do
            if [[ -v \$__hdr_var ]]; then
                __hdr_decl=\$(declare -p "\$__hdr_var" 2>/dev/null || true)
                if [[ \$__hdr_decl == declare\\ -x* ]]; then
                    printf 'export %s=%q\n' "\$__hdr_var" "\${!__hdr_var}"
                else
                    printf 'export -n %s 2>/dev/null || true\n' "\$__hdr_var"
                    printf '%s=%q\n' "\$__hdr_var" "\${!__hdr_var}"
                fi
            else
                printf 'unset %s\n' "\$__hdr_var"
            fi
        done
    } > "\$__hdr_backup_file"
}

__hdr_undo() {
    if [[ ! -f "\$__hdr_backup_file" ]]; then
        printf 'HDR environment backup not found: %s\n' "\$__hdr_backup_file" >&2
        return 1
    fi

    # shellcheck source=/dev/null
    source "\$__hdr_backup_file"
    rm -f "\$__hdr_backup_file"
    unalias leave-hdr 2>/dev/null || true
    unset __hdr_env_root __hdr_env_file __hdr_backup_file __hdr_backup_vars __hdr_entering
    unset -f __hdr_write_backup __hdr_undo
}

if [[ \${1:-} == --undo ]]; then
    __hdr_undo
    return 0 2>/dev/null || exit 0
fi

__hdr_entering=0
if [[ \${HDR_DEV_ENV_ACTIVE:-} != 1 ]]; then
    __hdr_write_backup
    __hdr_entering=1
fi

export HDR_DEV_ENV_ACTIVE=1
export HDR_DEV_ENV_ROOT=$q_env_root
export RUSTUP_HOME=$q_rustup_home
export CARGO_HOME=$q_cargo_home
export GH_CONFIG_DIR=$q_gh_config_dir
case ":\$PATH:" in
    *":\$CARGO_HOME/bin:"*) ;;
    *) export PATH="\$CARGO_HOME/bin:\$PATH" ;;
esac
export SKYLINE_ADD_NRO_HEADER=1
export RUSTFLAGS=$q_rustflags

if command -v gh >/dev/null 2>&1 && gh auth status --hostname github.com >/dev/null 2>&1; then
    __hdr_gh_token="\$(gh auth token --hostname github.com 2>/dev/null || true)"
    if [[ -n "\$__hdr_gh_token" ]]; then
        export GH_TOKEN="\$__hdr_gh_token"
        export GITHUB_TOKEN="\$__hdr_gh_token"
    fi
    unset __hdr_gh_token
fi

if [[ \$__hdr_entering == 1 ]]; then
    PS1='\[\e[40;32m\]([HDR])\[\e[0m\] '"\${PS1:-}"
fi

alias leave-hdr="source \"\$__hdr_env_file\" --undo"
cd $q_repo_root

unset __hdr_env_root __hdr_env_file __hdr_backup_file __hdr_backup_vars __hdr_entering
unset -f __hdr_write_backup __hdr_undo
EOF

	chmod +x "$env_file"
}

install_local_gh() {
	if command -v gh >/dev/null 2>&1; then
		log "GitHub CLI is already available"
		echo "  $(command -v gh)"
		return 0
	fi

	local machine arch asset url tmpdir extracted_dir
	machine="$(uname -m)"
	case "$machine" in
		x86_64 | amd64)
			arch="amd64"
			;;
		aarch64 | arm64)
			arch="arm64"
			;;
		*)
			die "Unsupported CPU architecture for local gh install: $machine"
			;;
	esac

	asset="gh_${GH_VERSION}_linux_${arch}.tar.gz"
	url="https://github.com/cli/cli/releases/download/v${GH_VERSION}/${asset}"
	tmpdir="$(mktemp -d)"
	extracted_dir="$tmpdir/gh_${GH_VERSION}_linux_${arch}"

	log "Installing GitHub CLI locally"
	curl -fL "$url" -o "$tmpdir/$asset"
	tar -xzf "$tmpdir/$asset" -C "$tmpdir"

	rm -rf "$ENV_ROOT/gh"
	mv "$extracted_dir" "$ENV_ROOT/gh"
	ln -sfn "$ENV_ROOT/gh/bin/gh" "$CARGO_HOME/bin/gh"
	rm -rf "$tmpdir"
}

export_github_token() {
	local token=""
	token="$(gh auth token --hostname github.com 2>/dev/null || true)"

	if [[ -z "$token" ]]; then
		warn "Could not export a GitHub token from gh. GitHub API calls may still be unauthenticated."
		return 0
	fi

	export GH_TOKEN="$token"
	export GITHUB_TOKEN="$token"
}

ensure_github_login() {
	log "Checking GitHub login"

	if gh auth status --hostname github.com >/dev/null 2>&1; then
		echo "GitHub CLI is already logged in for this local environment."
	else
		cat <<'EOF'
The setup will open a GitHub login flow now.
This keeps GitHub credentials under the local .hdr-wsl-dev folder for this workspace.
EOF
		gh auth login --hostname github.com --git-protocol https --web
	fi

	export_github_token
}

install_rustup_and_toolchain() {
	if [[ ! -x "$CARGO_HOME/bin/rustup" ]]; then
		log "Installing rustup into $ENV_ROOT"
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
			sh -s -- -y --no-modify-path --default-toolchain none
	fi

	log "Installing Rust toolchain $RUST_TOOLCHAIN"
	rustup toolchain install "$RUST_TOOLCHAIN"
	rustup default "$RUST_TOOLCHAIN"
}

install_cargo_skyline() {
	if cargo skyline --version >/dev/null 2>&1; then
		log "cargo-skyline is already installed"
	else
		log "Installing cargo-skyline"
		env -u RUSTFLAGS cargo install cargo-skyline
	fi
}

install_skyline_std_locally() {
	local host_triple base_toolchain skyline_toolchain src_root

	if rustup run skyline-v3 rustc --version >/dev/null 2>&1 &&
		[[ -d "$CARGO_HOME/skyline/toolchain/skyline/lib/rustlib/src/rust" ]]; then
		log "Skyline std toolchain is already installed"
		return 0
	fi

	log "Installing Skyline std and target files"

	rustup toolchain install "$RUST_TOOLCHAIN"

	rust_info="$(rustup run "$RUST_TOOLCHAIN" rustc -vV)"
	host_triple="$(printf '%s\n' "$rust_info" | awk '/^host: /{print $2; exit}')"
	base_toolchain="$RUSTUP_HOME/toolchains/${RUST_TOOLCHAIN}-${host_triple}"
	skyline_toolchain="$CARGO_HOME/skyline/toolchain/skyline"
	src_root="$skyline_toolchain/lib/rustlib/src"

	if [[ ! -d "$base_toolchain" ]]; then
		die "Base Rust toolchain was not found at $base_toolchain"
	fi

	rm -rf "$skyline_toolchain"
	mkdir -p "$(dirname "$skyline_toolchain")"
	cp -a "$base_toolchain" "$skyline_toolchain"

	rm -rf "$src_root"
	mkdir -p "$src_root"
	git clone --recurse-submodules --shallow-submodules --depth 1 \
		--branch skyline \
		https://github.com/skyline-rs/rust-src \
		"$src_root/rust"

	rustup toolchain link skyline-v3 "$skyline_toolchain" >/dev/null
}

ensure_skyline_target_json() {
	local skyline_dir="$CARGO_HOME/skyline"
	local target_json="$skyline_dir/aarch64-skyline-switch.json"
	local linker_script="$skyline_dir/link.T"
	local source_linker=""

	mkdir -p "$skyline_dir"

	source_linker="$(find "$CARGO_HOME/registry/src" -path '*/cargo-skyline-*/src/link.T' -print 2>/dev/null | sort -V | tail -n 1 || true)"
	if [[ -n "$source_linker" ]]; then
		cp "$source_linker" "$linker_script"
	elif [[ ! -f "$linker_script" ]]; then
		die "Could not find cargo-skyline link.T needed for $linker_script"
	fi

	python3 - "$target_json" "$linker_script" <<'PY'
import json
import sys
from pathlib import Path

target_json = Path(sys.argv[1])
linker_script = Path(sys.argv[2])

data = {
    "arch": "aarch64",
    "crt-static-default": False,
    "crt-static-respected": False,
    "data-layout": "e-m:e-p270:32:32-p271:32:32-p272:64:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-Fn32",
    "dynamic-linking": True,
    "executables": True,
    "has-rpath": False,
    "linker": "rust-lld",
    "linker-flavor": "ld.lld",
    "llvm-target": "aarch64-unknown-none",
    "max-atomic-width": 128,
    "os": "switch",
    "target-family": None,
    "env": "",
    "disable-redzone": True,
    "panic-strategy": "abort",
    "position-independent-executables": True,
    "pre-link-args": {
        "ld.lld": [
            f"-T{linker_script}",
            "-init=__custom_init",
            "-fini=__custom_fini",
            "--export-dynamic",
        ],
    },
    "post-link-args": {
        "ld.lld": [
            "--no-gc-sections",
            "--eh-frame-hdr",
        ],
    },
    "relro-level": "off",
    "target-c-int-width": 32,
    "target-endian": "little",
    "target-pointer-width": 64,
    "features": "+v8a,+neon,+crypto,+crc",
    "vendor": "jam1garner",
}

target_json.write_text(json.dumps(data, indent=2) + "\n")
PY

	echo "Updated Skyline target JSON:"
	echo "  $target_json"
}

write_rust_toolchain_file() {
	cat >"$REPO_ROOT/rust-toolchain.toml" <<'EOF'
[toolchain]
channel = "skyline-v3"
EOF

	cat >>"$REPO_ROOT/.git/info/exclude" <<'EOF'

# generated rust toolchain file from HDR WSL setup script
rust-toolchain.toml
EOF
}

print_target_cfg() {
	local target_json="$CARGO_HOME/skyline/aarch64-skyline-switch.json"

	if [[ ! -f "$target_json" ]]; then
		warn "Skyline target JSON was not found at $target_json"
		return 0
	fi

	log "Skyline target cfg"
	rustup run skyline-v3 rustc -Z unstable-options --print cfg \
		--target "$target_json" |
		rg 'target_arch|target_os|target_feature'
}

write_open_wsl_vscode_bat() {
	local bat_path="$BASE_DIR/open-wsl-vscode.bat"

	cat >"$bat_path" <<'BAT'
@echo off
setlocal
start /b powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "$baseDir = '%~dp0'.TrimEnd('\'); $repoDir = Join-Path $baseDir 'HewDraw-Remix'; if (-not (Test-Path $repoDir)) { $repoDir = $baseDir }; if ($repoDir -match '^\\\\wsl(?:\.localhost|\$)\\([^\\]+)(\\.*)$') { $distro = $Matches[1]; $path = ($Matches[2] -replace '\\', '/'); code --folder-uri ('vscode-remote://wsl+' + $distro + $path) } else { code $repoDir }"
BAT
}

merge_vscode_extensions() {
	local extensions_path="$REPO_ROOT/.vscode/extensions.json"

	mkdir -p "$REPO_ROOT/.vscode"
	python3 - "$extensions_path" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
wanted = [
    "ms-vscode-remote.remote-wsl",
    "editorconfig.editorconfig",
    "eamodio.gitlens",
    "ms-python.python",
    "rust-lang.rust-analyzer",
]

data = {}
if path.exists() and path.read_text().strip():
    data = json.loads(path.read_text())

existing = data.get("recommendations", [])
for item in wanted:
    if item not in existing:
        existing.append(item)

data["recommendations"] = existing
path.write_text(json.dumps(data, indent=4) + "\n")
PY
}

setup_rust_analyzer() {
	local helper="$BASE_DIR/setup-wsl-rust-analyzer.sh"

	if [[ ! -f "$helper" ]]; then
		die "Missing $helper"
	fi

	chmod +x "$helper"
	log "Setting up rust-analyzer"
	(cd "$REPO_ROOT" && HDR_REPO_ROOT="$REPO_ROOT" "$helper")
}

main() {
	require_ubuntu_wsl
	ensure_system_packages

	activate_local_rust_env
	install_local_gh
	ensure_github_login

	clone_or_find_repo
	write_env_file

	install_rustup_and_toolchain
	install_cargo_skyline
	install_skyline_std_locally
	ensure_skyline_target_json
	write_rust_toolchain_file
	print_target_cfg

	write_open_wsl_vscode_bat
	merge_vscode_extensions
	setup_rust_analyzer

	log "Done"
	cat <<EOF

Repo:
  $REPO_ROOT

Local environment:
  $ENV_ROOT

Use this shell setup before working in a normal terminal:
  source "$ENV_ROOT/env.sh"

Open the repo in VS Code from Windows:
  \\wsl.localhost\Ubuntu-{xx.yy}\home\{username}\{hdr-dev-folder}\open-wsl-vscode.bat

Build check:
  cd "$REPO_ROOT"
  cargo skyline build --release
EOF
}

main "$@"
