#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# --- pretty banner printing helper --------------------------------------------
# ------------------------------------------------------------------------------

__print_banner_exports() {
	export _PB_RED=$'\e[1;38;5;196;49m'
	export _PB_ORANGE=$'\e[1;38;5;202;49m'
	export _PB_GREY=$'\e[1;38;5;246;49m'
	export _PB_GRAY=$'\e[1;38;5;246;49m'
	export _PB_BLUE=$'\e[1;38;5;27;49m'
	export _PB_CYAN=$'\e[1;38;5;51;49m'
	export _PB_GREEN=$'\e[1;38;5;40;49m'
	export _PB_YELLOW=$'\e[1;38;5;226;49m'
	export _PB_PURPLE=$'\e[1;38;5;141;49m'
	export _PB_PINK=$'\e[1;38;5;207;49m'
	export _PB_BROWN=$'\e[1;38;5;173;49m'
	export _PB_WHITE=$'\e[1;38;5;255;49m'
	export _PB_BOLD=$'\e[1m'
	export _PB_RESET=$'\e[0m'
}

__print_banner_visible_len() {
	local s=$1
	local esc=$'\033'
	local csi="${esc}"'\[[0-?]*[ -/]*[@-~]'
	local re="^(.*)${csi}(.*)$"

	while [[ $s =~ $re ]]; do
		s="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
	done

	s=${s//│/x}
	s=${s//┌/x}
	s=${s//┐/x}
	s=${s//┘/x}
	s=${s//└/x}
	s=${s//─/x}

	printf '%d' "${#s}"
}

__print_banner_repeat() {
	local char=$1 count=$2 out=
	while ((count > 0)); do
		out+="$char"
		((count--))
	done
	printf '%s' "$out"
}

__print_banner_examples() {
	# ----------------------------------------------------------------------------
	# Example usage:
	#
	print_banner "Plain message"
	# ┌───────────────┐
	# │ Plain message │
	# └───────────────┘
	#
	EXTRA_WARN_COLOR=$'\e[0;38;2;233;157;135;49m'
	print_banner -t "Careful Now" -l WARN \
		"Disk usage is ${EXTRA_WARN_COLOR}above${_PB_RESET} the warning threshold." \
		"Consider cleaning old artifacts."
	# ┌─ [!] Careful Now ──────────────────────────┐
	# │ Disk usage is above the warning threshold. │
	# │ Consider cleaning old artifacts.           │
	# └────────────────────────────────────────────┘
	#
	TRIANGLE_RIGHT=$'\u25B8'
	FULL_CIRCLE=$'\u25CF'
	EMPTY_CIRCLE=$'\u25CB'
	MSG_OK=$'\e[0;38;2;26;138;26;49m(\e[0;38;2;29;194;29;49m'"${FULL_CIRCLE} OK  "$'\e[0;38;2;26;138;26;49m)'"${_PB_RESET}"
	MSG_PASS=$'\e[0;38;2;162;158;32;49m(\e[0;38;2;217;213;64;49m'"${FULL_CIRCLE} PASS"$'\e[0;38;2;162;158;32;49m)'"${_PB_RESET}"
	MSG_FAIL=$'\e[0;38;2;164;35;32;49m(\e[0;38;2;216;56;52;49m'"${EMPTY_CIRCLE} FAIL"$'\e[0;38;2;164;35;32;49m)'"${_PB_RESET}"
	print_banner -t "Build Output - A/B/C/D Matrix Compilation" -l CUSTOM -i "info" -c BROWN \
		"" \
		"Build artifacts:" \
		"  ${TRIANGLE_RIGHT} ${_PB_RED}A${_PB_RESET}: /mnt/C/Users/rei/out/${_PB_RED}A" \
		"  ${TRIANGLE_RIGHT} ${_PB_GREEN}B${_PB_RESET}: /mnt/C/Users/rei/out/${_PB_GREEN}B" \
		"  ${TRIANGLE_RIGHT} ${_PB_BLUE}C${_PB_RESET}: /mnt/C/Users/rei/out/${_PB_BLUE}C" \
		"  ${TRIANGLE_RIGHT} ${_PB_YELLOW}D${_PB_RESET}: /mnt/C/Users/rei/out/${_PB_YELLOW}D" \
		"" \
		"Statistics:" \
		"  ${_PB_RED}GROUP A${_PB_RESET} | ${MSG_OK} @ 100.00% | 502/502 Tests" \
		"  ${_PB_GREEN}GROUP B${_PB_RESET} | ${MSG_FAIL} @  23.30% | 117/502 Tests" \
		"  ${_PB_BLUE}GROUP C${_PB_RESET} | ${MSG_PASS} @  97.41% | 489/502 Tests" \
		"  ${_PB_YELLOW}GROUP D${_PB_RESET} | ${MSG_OK} @ 100.00% | 502/502 Tests" \
		""
	# ┌─ [info] Build Output - A/B/C/D Matrix Compilation ─┐
	# │                                                    │
	# │ Build artifacts:                                   │
	# │   ▸ A: /mnt/C/Users/rei/out/A                      │
	# │   ▸ B: /mnt/C/Users/rei/out/B                      │
	# │   ▸ C: /mnt/C/Users/rei/out/C                      │
	# │   ▸ D: /mnt/C/Users/rei/out/D                      │
	# │                                                    │
	# │ Statistics:                                        │
	# │   GROUP A | (● OK  ) @ 100.00% | 502/502 Tests     │
	# │   GROUP B | (○ FAIL) @  23.30% | 117/502 Tests     │
	# │   GROUP C | (● PASS) @  97.41% | 489/502 Tests     │
	# │   GROUP D | (● OK  ) @ 100.00% | 502/502 Tests     │
	# │                                                    │
	# └────────────────────────────────────────────────────┘
	#
	# ----------------------------------------------------------------------------
}

print_banner() {
	local title= level= color= icon=
	local box_tl='┌' box_tr='┐' box_br='┘' box_bl='└'
	local box_lr='│' box_tb='─' box_space=' '
	local reset=$'\e[0m'
	local lines=()

	while (($#)); do
		case $1 in
		-t | --title)
			title=$2
			shift 2
			;;
		-l | --level)
			level=$2
			shift 2
			;;
		-c | --color)
			color=$2
			shift 2
			;;
		-i | --icon)
			icon=$2
			shift 2
			;;
		--)
			shift
			break
			;;
		-*)
			printf 'print_banner: unknown option: %s\n' "$1" >&2
			return 2
			;;
		*) break ;;
		esac
	done

	if (($#)); then
		lines=("$@")
	elif [[ ! -t 0 ]]; then
		while IFS= read -r line || [[ -n $line ]]; do
			lines+=("$line")
		done
	fi

	local level_u color_u outer inner title_color
	level_u=$(printf '%s' "$level" | tr '[:lower:]' '[:upper:]')

	if [[ -n $level_u ]]; then
		case $level_u in
		INFO)
			icon='i'
			: "${color:=GREY}"
			;;
		WARN)
			icon='!'
			: "${color:=ORANGE}"
			;;
		CRIT)
			icon='!'
			: "${color:=RED}"
			;;
		CUSTOM)
			[[ -n $icon ]] || {
				printf 'print_banner: CUSTOM requires --icon\n' >&2
				return 2
			}
			[[ -n $color ]] || {
				printf 'print_banner: CUSTOM requires --color\n' >&2
				return 2
			}
			;;
		*)
			printf 'print_banner: invalid level: %s\n' "$level" >&2
			return 2
			;;
		esac

		color_u=$(printf '%s' "$color" | tr '[:lower:]' '[:upper:]')
		case $color_u in
		RED)
			outer=$'\e[0;38;5;88;49m'
			inner=$'\e[1;38;5;196;49m'
			title_color=$'\e[0;38;5;9;49m'
			;;
		ORANGE)
			outer=$'\e[0;38;5;130;49m'
			inner=$'\e[1;38;5;202;49m'
			title_color=$'\e[0;38;5;173;49m'
			;;
		GREY | GRAY)
			outer=$'\e[0;38;5;244;49m'
			inner=$'\e[1;38;5;252;49m'
			title_color=$'\e[0;38;5;248;49m'
			;;
		BLUE)
			outer=$'\e[0;38;5;4;49m'
			inner=$'\e[1;38;5;27;49m'
			title_color=$'\e[0;38;5;12;49m'
			;;
		CYAN)
			outer=$'\e[0;38;5;87;49m'
			inner=$'\e[1;38;5;51;49m'
			title_color=$'\e[0;38;5;123;49m'
			;;
		GREEN)
			outer=$'\e[0;38;5;28;49m'
			inner=$'\e[1;38;5;40;49m'
			title_color=$'\e[0;38;5;48;49m'
			;;
		YELLOW)
			outer=$'\e[0;38;5;222;49m'
			inner=$'\e[1;38;5;226;49m'
			title_color=$'\e[0;38;5;220;49m'
			;;
		PURPLE)
			outer=$'\e[0;38;5;97;49m'
			inner=$'\e[1;38;5;141;49m'
			title_color=$'\e[0;38;5;99;49m'
			;;
		PINK)
			outer=$'\e[0;38;5;213;49m'
			inner=$'\e[1;38;5;207;49m'
			title_color=$'\e[0;38;5;177;49m'
			;;
		BROWN)
			outer=$'\e[0;38;5;138;49m'
			inner=$'\e[1;38;5;173;49m'
			title_color=$'\e[0;38;5;95;49m'
			;;
		WHITE)
			outer=$'\e[0;38;5;254;49m'
			inner=$'\e[1;38;5;255;49m'
			title_color=$'\e[0;38;5;231;49m'
			;;
		*)
			printf 'print_banner: invalid color: %s\n' "$color" >&2
			return 2
			;;
		esac
	fi

	local banner_title
	if [[ -n $level_u && -n $title ]]; then
		banner_title="${box_tb}${box_space}${outer}[${inner}${icon}${outer}]${reset}${box_space}${title_color}${title}${reset}${box_space}${box_tb}"
	elif [[ -n $level_u ]]; then
		banner_title="${box_tb}${box_space}${outer}[${inner}${icon}${outer}]${reset}${box_space}${box_tb}"
	else
		banner_title="$title"
	fi

	local max_len=0 line prepared_len title_len i pad last_line
	local prepared_lines=()

	title_len=$(__print_banner_visible_len "$banner_title")
	((title_len > max_len)) && max_len=$title_len

	for line in "${lines[@]}"; do
		line="${box_space}${line}${box_space}"
		prepared_lines+=("$line")
		prepared_len=$(__print_banner_visible_len "$line")
		((prepared_len > max_len)) && max_len=$prepared_len
	done

	for i in "${!prepared_lines[@]}"; do
		prepared_len=$(__print_banner_visible_len "${prepared_lines[$i]}")
		pad=$((max_len - prepared_len))
		prepared_lines[$i]+="$(__print_banner_repeat "$box_space" "$pad")"
	done

	title_len=$(__print_banner_visible_len "$banner_title")
	banner_title+="$(__print_banner_repeat "$box_tb" "$((max_len - title_len))")"
	last_line=$(__print_banner_repeat "$box_tb" "$max_len")

	printf '%s%s%s\n' "$reset$box_tl" "$banner_title" "$reset$box_tr"
	for line in "${prepared_lines[@]}"; do
		printf '%s%s%s\n' "$reset$box_lr" "$line" "$reset$box_lr"
	done
	printf '%s%s%s\n' "$reset$box_bl" "$last_line" "$reset$box_br"
}

__print_banner_exports # for convenience

export -f __print_banner_exports
export -f __print_banner_visible_len
export -f __print_banner_repeat
export -f __print_banner_examples
export -f print_banner

# ------------------------------------------------------------------------------
# --- end pretty banner code ---------------------------------------------------
# ------------------------------------------------------------------------------

REPO_URL="${HDR_REPO_URL:-https://github.com/HDR-Development/HewDraw-Remix}"
SD_HOME_DIR="${HDR_SD_HOME_DIR:-/mnt/c/Users/Savestate/dev/HDR Download AIO/YUZU_HDR/user/sdmc}"
RUST_TOOLCHAIN="${HDR_RUST_TOOLCHAIN:-nightly-2026-02-14}"
GH_VERSION="${HDR_GH_VERSION:-2.92.0}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# ------------------------------------------------------------------------------
FULL_CIRCLE=$'\u25CF'

echo ""

print_banner --title "Setup variables" --level INFO --color GREEN \
	"Provide setup variables here if the provided" \
	"defaults are not what you would like them to" "be." "" \
	"The defaults are shown in ${_PB_GRAY}(parenthesis)${_PB_RESET}, you" \
	"can hit ${_PB_BOLD}Enter${_PB_RESET} to continue using the provided" \
	"defaults without modifying them."

echo ""

read -rp \
	"  $FULL_CIRCLE REPO_URL ${_PB_GRAY}($REPO_URL)${_PB_RESET}: " \
	_input
REPO_URL="${_input:-$REPO_URL}"

read -rp \
	"  $FULL_CIRCLE RUST_TOOLCHAIN ${_PB_GRAY}($RUST_TOOLCHAIN)${_PB_RESET}: " \
	_input
RUST_TOOLCHAIN="${_input:-$RUST_TOOLCHAIN}"

read -rp \
	"  $FULL_CIRCLE GH_VERSION ${_PB_GRAY}($GH_VERSION)${_PB_RESET}: " \
	_input
GH_VERSION="${_input:-$GH_VERSION}"

read -rp \
	"  $FULL_CIRCLE SCRIPT_DIR ${_PB_GRAY}($SCRIPT_DIR)${_PB_RESET}: " \
	_input
SCRIPT_DIR="${_input:-$SCRIPT_DIR}"

read -rp \
	"  $FULL_CIRCLE SD_HOME_DIR ${_PB_GRAY}($SD_HOME_DIR)${_PB_RESET}: " \
	_input
SD_HOME_DIR="${_input:-$SD_HOME_DIR}"

echo ""
# ------------------------------------------------------------------------------

export HDR_SD_HOME_DIR="$SD_HOME_DIR"

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

clone_or_find_repo_and_set_repo_root() {
	local existing=""
	if existing="$(find_existing_repo 2>/dev/null)"; then
		REPO_ROOT="$existing"
		BASE_DIR="${BASE_DIR:-$(dirname "$REPO_ROOT")}"
		log "Using existing HewDraw-Remix checkout"
		return 0
	fi

	BASE_DIR="${BASE_DIR:-$SCRIPT_DIR}"
	REPO_ROOT="${REPO_ROOT:-$BASE_DIR/HewDraw-Remix}"

	if [[ -d "$REPO_ROOT/.git" ]]; then
		log "Using existing repo at $REPO_ROOT"
	elif [[ -e "$REPO_ROOT" ]]; then
		die "$REPO_ROOT exists but is not a git repo"
	else
		log "Cloning HewDraw-Remix"
		git clone "$REPO_URL" "$REPO_ROOT"
	fi

	export HDR_REPO_ROOT="$REPO_ROOT"
}

activate_local_rust_env() {
	BASE_DIR="${BASE_DIR:-$SCRIPT_DIR}"
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
	local q_env_root q_repo_root q_sd_home_dir
	local q_rustup_home q_cargo_home q_gh_config_dir q_rustflags

	printf -v q_env_root '%q' "$ENV_ROOT"
	printf -v q_repo_root '%q' "$REPO_ROOT"
	printf -v q_sd_home_dir '%q' "$SD_HOME_DIR"
	printf -v q_rustup_home '%q' "$RUSTUP_HOME"
	printf -v q_cargo_home '%q' "$CARGO_HOME"
	printf -v q_gh_config_dir '%q' "$GH_CONFIG_DIR"
	printf -v q_rustflags '%q' "$RUSTFLAGS"

	mkdir -p "$ENV_ROOT"
	cat >"$env_file" <<EOF
# shellcheck shell=bash
# Source this file to use the local HDR WSL Rust environment.

__hdr_env_root=$q_env_root
__hdr_env_file="\$__hdr_env_root/env.sh"
__hdr_backup_file="\$__hdr_env_root/env_backup.ini"
__hdr_backup_vars=(HDR_DIRECTORY_BEFORE_SOURCE HDR_DEV_ENV_ROOT HDR_DEV_ENV_ACTIVE RUSTUP_HOME CARGO_HOME GH_CONFIG_DIR GH_TOKEN GITHUB_TOKEN PATH SKYLINE_ADD_NRO_HEADER RUSTFLAGS PS1)

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

	__hdr_directory_before_source="\$HDR_DIRECTORY_BEFORE_SOURCE"

    # shellcheck source=/dev/null
    source "\$__hdr_backup_file"
    rm -f "\$__hdr_backup_file"
    unalias leave-hdr 2>/dev/null || true
    unset __hdr_env_root __hdr_env_file __hdr_backup_file __hdr_backup_vars __hdr_entering
    unset -f __hdr_write_backup __hdr_undo
	cd \$__hdr_directory_before_source
	unset __hdr_directory_before_source
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

export HDR_DIRECTORY_BEFORE_SOURCE=\$(pwd)
export HDR_DEV_ENV_ACTIVE=1
export HDR_DEV_ENV_ROOT=$q_env_root
export HDR_REPO_ROOT=$q_repo_root
export HDR_SD_HOME_DIR=$q_sd_home_dir
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

# ------------------------------------------------------------------------------
# --- pretty banner printing helper --------------------------------------------
# ------------------------------------------------------------------------------

__print_banner_exports() {
  export _PB_RED=$'\e[1;38;5;196;49m'
  export _PB_ORANGE=$'\e[1;38;5;202;49m'
  export _PB_GREY=$'\e[1;38;5;246;49m'
  export _PB_GRAY=$'\e[1;38;5;246;49m'
  export _PB_BLUE=$'\e[1;38;5;27;49m'
  export _PB_CYAN=$'\e[1;38;5;51;49m'
  export _PB_GREEN=$'\e[1;38;5;40;49m'
  export _PB_YELLOW=$'\e[1;38;5;226;49m'
  export _PB_PURPLE=$'\e[1;38;5;141;49m'
  export _PB_PINK=$'\e[1;38;5;207;49m'
  export _PB_BROWN=$'\e[1;38;5;173;49m'
  export _PB_WHITE=$'\e[1;38;5;255;49m'
  export _PB_BOLD=$'\e[1m'
  export _PB_RESET=$'\e[0m'
}

__print_banner_visible_len() {
  local s=\$1
  local esc=\$'\033'
  local csi="\${esc}"'\[[0-?]*[ -/]*[@-~]'
  local re="^(.*)\${csi}(.*)$"

  while [[ \$s =~ \$re ]]; do
    s="\${BASH_REMATCH[1]}\${BASH_REMATCH[2]}"
  done

  s=\${s//│/x}
  s=\${s//┌/x}
  s=\${s//┐/x}
  s=\${s//┘/x}
  s=\${s//└/x}
  s=\${s//─/x}

  printf '%d' "\${#s}"
}

__print_banner_repeat() {
  local char=\$1 count=\$2 out=
  while ((count > 0)); do
    out+="\$char"
    ((count--))
  done
  printf '%s' "\$out"
}

print_banner() {
  local title= level= color= icon=
  local box_tl='┌' box_tr='┐' box_br='┘' box_bl='└'
  local box_lr='│' box_tb='─' box_space=' '
  local reset=\$'\e[0m'
  local lines=()

  while ((\$#)); do
    case \$1 in
    -t | --title)
      title=\$2
      shift 2
      ;;
    -l | --level)
      level=\$2
      shift 2
      ;;
    -c | --color)
      color=\$2
      shift 2
      ;;
    -i | --icon)
      icon=\$2
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -*)
      printf 'print_banner: unknown option: %s\n' "\$1" >&2
      return 2
      ;;
    *) break ;;
    esac
  done

  if ((\$#)); then
    lines=("\$@")
  elif [[ ! -t 0 ]]; then
    while IFS= read -r line || [[ -n \$line ]]; do
      lines+=("\$line")
    done
  fi

  local level_u color_u outer inner title_color
  level_u=\$(printf '%s' "\$level" | tr '[:lower:]' '[:upper:]')

  if [[ -n \$level_u ]]; then
    case \$level_u in
    INFO)
      icon='i'
      : "\${color:=GREY}"
      ;;
    WARN)
      icon='!'
      : "\${color:=ORANGE}"
      ;;
    CRIT)
      icon='!'
      : "\${color:=RED}"
      ;;
    CUSTOM)
      [[ -n \$icon ]] || {
        printf 'print_banner: CUSTOM requires --icon\n' >&2
        return 2
      }
      [[ -n \$color ]] || {
        printf 'print_banner: CUSTOM requires --color\n' >&2
        return 2
      }
      ;;
    *)
      printf 'print_banner: invalid level: %s\n' "\$level" >&2
      return 2
      ;;
    esac

    color_u=\$(printf '%s' "\$color" | tr '[:lower:]' '[:upper:]')
    case \$color_u in
    RED)
      outer=\$'\e[0;38;5;88;49m'
      inner=\$'\e[1;38;5;196;49m'
      title_color=\$'\e[0;38;5;9;49m'
      ;;
    ORANGE)
      outer=\$'\e[0;38;5;130;49m'
      inner=\$'\e[1;38;5;202;49m'
      title_color=\$'\e[0;38;5;173;49m'
      ;;
    GREY | GRAY)
      outer=\$'\e[0;38;5;244;49m'
      inner=\$'\e[1;38;5;252;49m'
      title_color=\$'\e[0;38;5;248;49m'
      ;;
    BLUE)
      outer=\$'\e[0;38;5;4;49m'
      inner=\$'\e[1;38;5;27;49m'
      title_color=\$'\e[0;38;5;12;49m'
      ;;
    CYAN)
      outer=\$'\e[0;38;5;87;49m'
      inner=\$'\e[1;38;5;51;49m'
      title_color=\$'\e[0;38;5;123;49m'
      ;;
    GREEN)
      outer=\$'\e[0;38;5;28;49m'
      inner=\$'\e[1;38;5;40;49m'
      title_color=\$'\e[0;38;5;48;49m'
      ;;
    YELLOW)
      outer=\$'\e[0;38;5;222;49m'
      inner=\$'\e[1;38;5;226;49m'
      title_color=\$'\e[0;38;5;220;49m'
      ;;
    PURPLE)
      outer=\$'\e[0;38;5;97;49m'
      inner=\$'\e[1;38;5;141;49m'
      title_color=\$'\e[0;38;5;99;49m'
      ;;
    PINK)
      outer=\$'\e[0;38;5;213;49m'
      inner=\$'\e[1;38;5;207;49m'
      title_color=\$'\e[0;38;5;177;49m'
      ;;
    BROWN)
      outer=\$'\e[0;38;5;138;49m'
      inner=\$'\e[1;38;5;173;49m'
      title_color=\$'\e[0;38;5;95;49m'
      ;;
    WHITE)
      outer=\$'\e[0;38;5;254;49m'
      inner=\$'\e[1;38;5;255;49m'
      title_color=\$'\e[0;38;5;231;49m'
      ;;
    *)
      printf 'print_banner: invalid color: %s\n' "\$color" >&2
      return 2
      ;;
    esac
  fi

  local banner_title
  if [[ -n \$level_u && -n \$title ]]; then
    banner_title="\${box_tb}\${box_space}\${outer}[\${inner}\${icon}\${outer}]\${reset}\${box_space}\${title_color}\${title}\${reset}\${box_space}\${box_tb}"
  elif [[ -n \$level_u ]]; then
    banner_title="\${box_tb}\${box_space}\${outer}[\${inner}\${icon}\${outer}]\${reset}\${box_space}\${box_tb}"
  else
    banner_title="\$title"
  fi

  local max_len=0 line prepared_len title_len i pad last_line
  local prepared_lines=()

  title_len=\$(__print_banner_visible_len "\$banner_title")
  ((title_len > max_len)) && max_len=\$title_len

  for line in "\${lines[@]}"; do
    line="\${box_space}\${line}\${box_space}"
    prepared_lines+=("\$line")
    prepared_len=\$(__print_banner_visible_len "\$line")
    ((prepared_len > max_len)) && max_len=\$prepared_len
  done

  for i in "\${!prepared_lines[@]}"; do
    prepared_len=\$(__print_banner_visible_len "\${prepared_lines[\$i]}")
    pad=\$((max_len - prepared_len))
    prepared_lines[\$i]+="\$(__print_banner_repeat "\$box_space" "\$pad")"
  done

  title_len=\$(__print_banner_visible_len "\$banner_title")
  banner_title+="\$(__print_banner_repeat "\$box_tb" "\$((max_len - title_len))")"
  last_line=\$(__print_banner_repeat "\$box_tb" "\$max_len")

  printf '%s%s%s\n' "\$reset\$box_tl" "\$banner_title" "\$reset\$box_tr"
  for line in "\${prepared_lines[@]}"; do
    printf '%s%s%s\n' "\$reset\$box_lr" "\$line" "\$reset\$box_lr"
  done
  printf '%s%s%s\n' "\$reset\$box_bl" "\$last_line" "\$reset\$box_br"
}

__print_banner_exports # for convenience

export -f __print_banner_exports
export -f __print_banner_visible_len
export -f __print_banner_repeat
export -f print_banner

# ------------------------------------------------------------------------------
# --- end pretty banner code ---------------------------------------------------
# ------------------------------------------------------------------------------

print_banner --color green --level INFO --title "HDR Development Environment" "You have entered the \${_PB_BOLD}HDR Development Environment\${_PB_RESET} by running:" "  \${_PB_GRAY}source \\"$ENV_ROOT/env.sh\\"" "To leave the \${_PB_BOLD}HDR Development Environment\${_PB_RESET}, run this command:" "  \${_PB_GRAY}leave-hdr"
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

modify_build_wsl() {
	local build_wsl="$REPO_ROOT/scripts/build-wsl.sh"
	local tmp_file

	tmp_file="$(mktemp)"

	awk '
        NR == 1 {
            print
            print "original_build_wsl() {"
            next
        }

        {
            print "  " $0
        }

        END {
            print "}"
        }
    ' "$build_wsl" >"$tmp_file"

	cat >>"$tmp_file" <<'EOF'

HDR_TEMP_CURRENT_DIR="$PWD"

restore_dir() {
    cd "$HDR_TEMP_CURRENT_DIR" 2>/dev/null || true
}

fail_deploy() {
    echo "Deploy aborted: $1"
    restore_dir
    exit 1
}

DEPLOY=false
CLEAN=false
NEW=false

shopt -s nocasematch
for arg in "$@"; do
    case "$arg" in
        --deploy)
            DEPLOY=true
            ;;
        --clean)
            CLEAN=true
            ;;
        --new)
            NEW=true
            ;;
    esac
done
shopt -u nocasematch

if [[ "$NEW" != true ]]; then
    original_build_wsl
    restore_dir
    exit $?
fi

if [[ "${HDR_DEV_ENV_ACTIVE:-}" != "1" ]]; then
    fail_deploy "HDR_DEV_ENV_ACTIVE is not set to 1. This should be set automatically by .hdr-wsl-dev/env.sh or by running open-wsl-vscode.bat."
fi

if [[ -z "${HDR_REPO_ROOT:-}" ]]; then
    fail_deploy "HDR_REPO_ROOT is not set. This should be set automatically by .hdr-wsl-dev/env.sh or by running open-wsl-vscode.bat."
fi

if [[ -z "${HDR_SD_HOME_DIR:-}" ]]; then
    fail_deploy "HDR_SD_HOME_DIR is not set. Modify your .hdr-wsl-dev/env.sh or VS Code settings.json."
fi

if [[ ! -d "$HDR_SD_HOME_DIR/ultimate/mods" ]]; then
    fail_deploy "$HDR_SD_HOME_DIR/ultimate/mods does not exist. Check that HDR_SD_HOME_DIR is correct in your env.sh script or VS Code settings.json."
fi

cd "$HDR_REPO_ROOT" || fail_deploy "Could not cd to HDR_REPO_ROOT: $HDR_REPO_ROOT"

if [[ "$CLEAN" == true ]]; then
	echo "Cleaning..."
    cargo-skyline skyline clean-project || fail_deploy "cargo-skyline clean-project failed."
fi

cargo-skyline skyline build --release || fail_deploy "cargo-skyline build failed."
cd scripts || fail_deploy "Could not cd to scripts directory."
python3 build.py --release || fail_deploy "python3 build.py failed."

if [[ "$DEPLOY" == true ]]; then
	echo "Deploying..."
	rm -rf "$HDR_SD_HOME_DIR/ultimate/mods/hdr"
	rm -rf "$HDR_SD_HOME_DIR/ultimate/mods/hdr-dev"
	rm -rf "$HDR_SD_HOME_DIR/ultimate/mods/hdr-pr"
	rm -rf "$HDR_SD_HOME_DIR/ultimate/mods/hdr-wsl-deploy"
	mkdir -p "$HDR_SD_HOME_DIR/ultimate/mods/hdr-wsl-deploy"
	cp -a "$HDR_REPO_ROOT/build/hdr-switch/ultimate/mods/hdr-dev/." \
		"$HDR_SD_HOME_DIR/ultimate/mods/hdr-wsl-deploy/" \
		|| fail_deploy "Failed to copy hdr-dev files to hdr-wsl-deploy."
fi

restore_dir

EOF

	mv "$tmp_file" "$build_wsl"
	chmod +x "$build_wsl"

	cat >>"$REPO_ROOT/.git/info/exclude" <<'EOF'
# modified build-wsl.sh file
scripts/build-wsl.sh
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

write_open_wsl_vscode_bat_ps1() {
	local bat_path="$BASE_DIR/open-wsl-vscode.bat"
	cat >"$bat_path" <<'BAT'
@echo off
setlocal
start /b powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "$baseDir = '%~dp0'.TrimEnd('\'); $repoDir = Join-Path $baseDir 'HewDraw-Remix'; if (-not (Test-Path $repoDir)) { $repoDir = $baseDir }; if ($repoDir -match '^\\\\wsl(?:\.localhost|\$)\\([^\\]+)(\\.*)$') { $distro = $Matches[1]; $path = ($Matches[2] -replace '\\', '/'); code --folder-uri ('vscode-remote://wsl+' + $distro + $path) } else { code $repoDir }"
BAT

	local ps1_path="$BASE_DIR/open-wsl-vscode.ps1"
	cat >"$ps1_path" <<'PS1'
#Requires -Version 5.0
$baseDir = $PSScriptRoot
$repoDir = Join-Path $baseDir 'HewDraw-Remix'
if (-not (Test-Path $repoDir)) { $repoDir = $baseDir }
if ($repoDir -match '^\\\\wsl(?:\.localhost|\$)\\([^\\]+)(\\.*)$') {
    $distro = $Matches[1]
    $path = ($Matches[2] -replace '\\', '/')
    code --folder-uri ('vscode-remote://wsl+' + $distro + $path)
} else {
    code $repoDir
}
PS1
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
	(cd "$REPO_ROOT" && "$helper")
}

main() {
	require_ubuntu_wsl
	ensure_system_packages

	activate_local_rust_env
	install_local_gh
	ensure_github_login

	clone_or_find_repo_and_set_repo_root
	write_env_file

	install_rustup_and_toolchain
	install_cargo_skyline
	install_skyline_std_locally
	ensure_skyline_target_json

	write_rust_toolchain_file
	modify_build_wsl

	print_target_cfg

	write_open_wsl_vscode_bat_ps1
	merge_vscode_extensions
	setup_rust_analyzer

	log "Done"

	print_banner --title "Environment Setup" --color YELLOW --level INFO \
		"Repo:" "  $REPO_ROOT" \
		"Local environment:" "  $ENV_ROOT"

	print_banner --title "Entering the HDR Development Environment" --color GREEN --level INFO \
		"Use this shell setup before working in a normal terminal:" \
		"  source \"$ENV_ROOT/env.sh\"" \
		"Open the repo in VS Code from Windows:" \
		"  powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"\$(wslpath -w '$BASE_DIR/open-wsl-vscode.ps1')\""

	print_banner --title "Building HDR" --color BLUE --level INFO \
		"Initial build check:" \
		"  source \"$ENV_ROOT/env.sh\" # if not already done" \
		"  ./scripts/build-wsl.sh --new --clean" \
		"Building after initial build:" \
		"  ./scripts/build-wsl.sh --new" \
		"Deplying to SD Card:" \
		"  ./scripts/build-wsl.sh --new --deploy (--clean)"

	local HDR_ALIASES
	HDR_ALIASES="alias start-hdr=\"source \\\"$ENV_ROOT/env.sh\\\"\""$'\n'"alias start-hdr-vscode=\"powershell.exe -NoProfile -ExecutionPolicy Bypass -File \\\"\\\$(wslpath -w '$BASE_DIR/open-wsl-vscode.ps1')\\\"\""

	# list of .bashrc files
	local BASHRC_LIST_ARGS=()
	local USER_BASH_RC="$HOME/.bashrc"
	while IFS= read -r bashrc_file; do
		if [[ "$bashrc_file" == "$HOME/.bashrc" ]]; then
			BASHRC_LIST_ARGS+=("  * $bashrc_file ${_PB_GRAY}(default)${_PB_RESET}")
		else
			BASHRC_LIST_ARGS+=("  * $bashrc_file")
		fi
	done < <(find ~ -maxdepth 1 -name ".bashrc*" -type f | sort)

	print_banner --title "Helpful Aliases" --color PURPLE --level INFO \
		"Adding something like these to your .bashrc might be helpful:" \
		"  alias start-hdr=\"source \\\"$ENV_ROOT/env.sh\\\"\"" \
		"  alias start-hdr-vscode=\"powershell.exe -NoProfile -ExecutionPolicy Bypass -File \\\"\\\$(wslpath -w '$BASE_DIR/open-wsl-vscode.ps1')\\\"\"" \
		"" "All .bashrc files found:" \
		"${BASHRC_LIST_ARGS[@]}"

	echo ""
	read -rp "  Add these aliases to ~/.bashrc now? [Y/n]: " _input

	if [[ "${_input:-Y}" =~ ^[Yy]$ ]]; then
		echo ""
		read -rp \
			"  $FULL_CIRCLE USER_BASH_RC ${_PB_GRAY}($USER_BASH_RC)${_PB_RESET}: " \
			_input
		USER_BASH_RC="${_input:-$USER_BASH_RC}"
		USER_BASH_RC="${USER_BASH_RC/#\~/$HOME}"

        # make sure file ends with newline
        if [[ -s "$USER_BASH_RC" ]] && [[ "$(tail -c1 "$USER_BASH_RC" | wc -l)" -eq 0 ]]; then
            echo "" >> "$USER_BASH_RC"
        fi
        echo "$HDR_ALIASES" >> "$USER_BASH_RC"

		# tail output into banner args
		local TAIL_ARGS=()
		while IFS= read -r line; do
			TAIL_ARGS+=("  ${_PB_GRAY}$line${_PB_RESET}")
		done < <(tail -n 5 "$USER_BASH_RC")

		print_banner --title "New Aliases Added!" --color PURPLE --level INFO \
			"Added aliases!" "" \
			"Here is the output of 'tail -n 5 \"$USER_BASH_RC\"':" \
			"${TAIL_ARGS[@]}"

		print_banner --title "Re-run Source" --level WARN \
			"Make sure to run afterwards:" \
			"  source \"$USER_BASH_RC\""
	fi
}

main "$@"
