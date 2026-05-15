#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

if [[ -n "${HDR_REPO_ROOT:-}" ]]; then
    repo_root="$HDR_REPO_ROOT"
elif repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    :
elif [[ -d "$script_dir/HewDraw-Remix/.git" ]]; then
    repo_root="$script_dir/HewDraw-Remix"
elif [[ -d "$PWD/HewDraw-Remix/.git" ]]; then
    repo_root="$PWD/HewDraw-Remix"
else
    echo "ERROR: Could not find HewDraw-Remix."
    echo "Run this from the repo, place it next to HewDraw-Remix, or set HDR_REPO_ROOT."
    exit 1
fi

cd "$repo_root"

cargo_home="${CARGO_HOME:-$HOME/.cargo}"
skyline_target="$cargo_home/skyline/aarch64-skyline-switch.json"
local_target=".cargo/aarch64-skyline-switch.json"

ensure_skyline_target_json() {
    local skyline_dir="$cargo_home/skyline"
    local linker_script="$skyline_dir/link.T"
    local source_linker=""

    mkdir -p "$skyline_dir"

    source_linker="$(find "$cargo_home/registry/src" -path '*/cargo-skyline-*/src/link.T' -print 2>/dev/null | sort -V | tail -n 1 || true)"
    if [[ -n "$source_linker" ]]; then
        cp "$source_linker" "$linker_script"
    elif [[ ! -f "$linker_script" ]]; then
        return 1
    fi

    python3 - "$skyline_target" "$linker_script" <<'PY'
import json
import os
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
}

if [[ ! -f "$skyline_target" ]]; then
    ensure_skyline_target_json || true
fi

if [[ ! -f "$skyline_target" ]]; then
	echo "ERROR: Skyline target JSON not found:"
	echo "  $skyline_target"
	echo
	echo "Try running:"
	echo "  ./setup-wsl-dev-env.sh"
	exit 1
fi

mkdir -p .cargo .vscode
ln -sfn "$skyline_target" "$local_target"

python3 - .cargo/config.toml <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text() if path.exists() else ""
lines = text.splitlines()

managed = {
    "json-target-spec": "json-target-spec = true",
}
removed_keys = [*managed.keys(), "build-std"]

section_re = re.compile(r"^\s*\[([^\]]+)\]\s*$")
unstable_start = None
unstable_end = None

for index, line in enumerate(lines):
    match = section_re.match(line)
    if not match:
        continue
    if match.group(1).strip() == "unstable":
        unstable_start = index
        unstable_end = len(lines)
        for next_index in range(index + 1, len(lines)):
            if section_re.match(lines[next_index]):
                unstable_end = next_index
                break
        break

if unstable_start is None:
    if lines and lines[-1].strip():
        lines.append("")
    lines.extend(["[unstable]", *managed.values()])
else:
    before = lines[:unstable_start + 1]
    section = lines[unstable_start + 1:unstable_end]
    after = lines[unstable_end:]

    filtered = []
    managed_key_re = re.compile(r"^\s*(" + "|".join(re.escape(key) for key in removed_keys) + r")\s*=")
    for line in section:
        if managed_key_re.match(line):
            continue
        filtered.append(line)

    lines = before + list(managed.values()) + filtered + after

path.write_text("\n".join(lines).rstrip() + "\n")
PY

python3 - .vscode/settings.json <<'PY'
import json
import os
import sys
from pathlib import Path

path = Path(sys.argv[1])

start_marker = "===== START CARGO-SKYLINE SETTINGS FROM setup-wsl-rust-analyzer.sh ====="
end_marker = "===== END CARGO-SKYLINE SETTINGS FROM setup-wsl-rust-analyzer.sh ====="

managed_keys = [
    start_marker,
    "rust-analyzer.cargo.target",
    "rust-analyzer.cargo.allTargets",
    "rust-analyzer.cargo.features",
    "rust-analyzer.cargo.extraArgs",
    "rust-analyzer.cargo.metadataExtraArgs",
    "rust-analyzer.cargo.extraEnv",
    "terminal.integrated.env.linux",
    "rust-analyzer.check.extraArgs",
    "rust-analyzer.check.allTargets",
    "rust-analyzer.cargo.targetDir",
    "files.exclude",
    end_marker,
]

settings = {}
if path.exists() and path.read_text().strip():
    settings = json.loads(path.read_text())

existing_extra_env = settings.get("rust-analyzer.cargo.extraEnv", {})
existing_extra_env.update({
    "CARGO_HOME": os.environ.get("CARGO_HOME"),
    "RUSTUP_HOME": os.environ.get("RUSTUP_HOME"),
    "GH_CONFIG_DIR": os.environ.get("GH_CONFIG_DIR"),
    "RUSTFLAGS": "--cfg skyline_std_v3",
    "SKYLINE_ADD_NRO_HEADER": "1",
})
existing_extra_env = {key: value for key, value in existing_extra_env.items() if value is not None}
if "CARGO_HOME" in existing_extra_env:
    path_value = existing_extra_env["CARGO_HOME"] + "/bin"
    current_path = os.environ.get("PATH", "")
    path_parts = [part for part in current_path.split(":") if part and part != path_value]
    existing_extra_env["PATH"] = ":".join([path_value, *path_parts])

terminal_env = settings.get("terminal.integrated.env.linux", {})
terminal_env.update(existing_extra_env)

# Remove old managed settings first so the block is rewritten together.
for key in managed_keys:
    settings.pop(key, None)

managed_block = {
    start_marker: None,
    "rust-analyzer.cargo.target": ".cargo/aarch64-skyline-switch.json",
    "rust-analyzer.cargo.allTargets": False,
    "rust-analyzer.cargo.features": ["main_nro"],
    "rust-analyzer.cargo.extraArgs": [
        "-Z", "json-target-spec",
    ],
    "rust-analyzer.cargo.metadataExtraArgs": [
        "-Z", "json-target-spec",
    ],
    "rust-analyzer.cargo.extraEnv": existing_extra_env,
    "terminal.integrated.env.linux": terminal_env,
    "rust-analyzer.check.extraArgs": [
        "-Z", "json-target-spec",
        "-Z", "build-std=core,alloc,std,panic_abort",
    ],
    "rust-analyzer.check.allTargets": False,
    "rust-analyzer.cargo.targetDir": "target/rust-analyzer",
    "files.exclude": { "**/.git": False },
    end_marker: None,
}

settings.update(managed_block)

path.write_text(json.dumps(settings, indent=2) + "\n")
PY

echo "Linked Skyline target:"
echo "  $local_target -> $skyline_target"
echo "Updated .cargo/config.toml"
echo "Updated .vscode/settings.json"
