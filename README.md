# hdr-wsl-dev-env-setup
Scripts to facilitate a development environment in WSL for HewDraw-Remix

## What does this do?

Creates a `rust-toolchain.toml` file:
```toml
[toolchain]
channel = "skyline-v3"
```

Sets up a `settings.json` file with environment vars and to properly configure `rust-analyzer`.

Here is an example for my setup:
```json
{
  "===== START CARGO-SKYLINE SETTINGS FROM setup-wsl-rust-analyzer.sh =====": null,
  "rust-analyzer.cargo.target": ".cargo/aarch64-skyline-switch.json",
  "rust-analyzer.cargo.allTargets": false,
  "rust-analyzer.cargo.features": [
    "main_nro"
  ],
  "rust-analyzer.cargo.extraArgs": [
    "-Z",
    "json-target-spec"
  ],
  "rust-analyzer.cargo.metadataExtraArgs": [
    "-Z",
    "json-target-spec"
  ],
  "rust-analyzer.cargo.extraEnv": {
    "CARGO_HOME": "/home/savestate/dev/hewdraw-dev/.hdr-wsl-dev/cargo",
    "RUSTUP_HOME": "/home/savestate/dev/hewdraw-dev/.hdr-wsl-dev/rustup",
    "GH_CONFIG_DIR": "/home/savestate/dev/hewdraw-dev/.hdr-wsl-dev/gh-config",
    "HDR_REPO_ROOT": "/home/savestate/dev/hewdraw-dev/HewDraw-Remix",
    "HDR_SD_HOME_DIR": "/mnt/c/Users/Savestate/dev/HDR Download AIO/YUZU_HDR/user/sdmc",
    "RUSTFLAGS": "--cfg skyline_std_v3",
    "SKYLINE_ADD_NRO_HEADER": "1",
    "PATH": "BIG_PATH_REMOVED"
  },
  "terminal.integrated.env.linux": {
    "CARGO_HOME": "/home/savestate/dev/hewdraw-dev/.hdr-wsl-dev/cargo",
    "RUSTUP_HOME": "/home/savestate/dev/hewdraw-dev/.hdr-wsl-dev/rustup",
    "GH_CONFIG_DIR": "/home/savestate/dev/hewdraw-dev/.hdr-wsl-dev/gh-config",
    "HDR_REPO_ROOT": "/home/savestate/dev/hewdraw-dev/HewDraw-Remix",
    "HDR_SD_HOME_DIR": "/mnt/c/Users/Savestate/dev/HDR Download AIO/YUZU_HDR/user/sdmc",
    "RUSTFLAGS": "--cfg skyline_std_v3",
    "SKYLINE_ADD_NRO_HEADER": "1",
    "PATH": "BIG_PATH_REMOVED"
  },
  "rust-analyzer.check.extraArgs": [
    "-Z",
    "json-target-spec",
    "-Z",
    "build-std=core,alloc,std,panic_abort"
  ],
  "rust-analyzer.check.allTargets": false,
  "rust-analyzer.cargo.targetDir": "target/rust-analyzer",
  "files.exclude": {
    "**/.git": false
  },
  "editor.rulers": [
    {
      "column": 80,
      "color": "#00ff0044"
    },
    {
      "column": 79,
      "color": "#00ff0008"
    },
    {
      "column": 120,
      "color": "#ffff0044"
    },
    {
      "column": 119,
      "color": "#ffff0010"
    },
    {
      "column": 140,
      "color": "#ff000064"
    },
    {
      "column": 139,
      "color": "#ff000028"
    },
    {
      "column": 160,
      "color": "#0044ff88"
    },
    {
      "column": 159,
      "color": "#0044ff42"
    }
  ],
  "===== END CARGO-SKYLINE SETTINGS FROM setup-wsl-rust-analyzer.sh =====": null
}
```

Sets up these VSCode workplace extension recommendations in `extensions.json`:
```json
{
    "recommendations": [
        "ms-vscode-remote.remote-wsl",
        "editorconfig.editorconfig",
        "eamodio.gitlens",
        "ms-python.python",
        "rust-lang.rust-analyzer"
    ]
}
```

Adds a symbolic link to the target JSON file in `.cargo/aarch64-skyline-switch.json`

Adds `.cargo/config.toml` with the following content (allows specifying a target spec `.json` file): 
```toml
[unstable]
json-target-spec = true
```

Modifies `scripts/build-wsl.sh` to add new options: 
```bash
#!/bin/bash
original_build_wsl() {
  script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
  repo_root=$(dirname "$script_dir")
  
  app_data="$(wslpath $(cmd.exe /c echo %AppData%))"
  ryujinx_path="${app_data::-1}/Ryujinx" # remove the carriage return because Windows and WSL are both stupid
  mod_path="$ryujinx_path/mods/contents/01006a800016e000/skyline/romfs/skyline/plugins"
  base_path="$ryujinx_path/sdcard/ultimate/mods/HDR-Base"
  
  # do this before getting the rom files because this will update them
  cd "$repo_root/plugin"
  cargo skyline build --release
  cp target/aarch64-skyline-switch/release/libhdr.nro "$mod_path/libhdr.nro"
  
  files=$(find "$repo_root/romfs/build" -type f -name "*.prc" -print)
  for file in $files;
  do
      local_path=${file#"$repo_root/romfs/build"}
      full_rom_path=$base_path$local_path
      mkdir -p $(dirname "$full_rom_path")
      cp $file $full_rom_path
  done
}

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
```

Appends the lines to the user's local `.git/info/exclude` for HewDraw-Remix:
```.gitignore
# generated rust toolchain file from HDR WSL setup script
rust-toolchain.toml
# modified build-wsl.sh file
scripts/build-wsl.sh
```

# Setup

## WSL

List the available distros:

```cmd
wsl.exe --list --online
```

```txt
The following is a list of valid distributions that can be installed.
Install using 'wsl.exe --install <Distro>'.

NAME                            FRIENDLY NAME
Ubuntu                          Ubuntu
Ubuntu-26.04                    Ubuntu 26.04 LTS
Ubuntu-24.04                    Ubuntu 24.04 LTS
Ubuntu-22.04                    Ubuntu 22.04 LTS

...other distributions left out intentionally...
```

Install an Ubuntu of choice:

```cmd
wsl --install Ubuntu-24.04
```

```txt
Downloading: Ubuntu 24.04 LTS
Installing: Ubuntu 24.04 LTS
Distribution successfully installed. It can be launched via 'wsl.exe -d Ubuntu-24.04'
Launching Ubuntu-24.04...
Provisioning the new WSL instance Ubuntu-24.04
This might take a while...
Create a default Unix user account: your_username_here
New password:
Retype new password:
passwd: password updated successfully
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.
```

## Running the Setup Script

Change directories to your home directory (you start in a mounted local drive location):

```bash
# Current Directory: "/mnt/c/Users/Savestate"
cd ~
```

Create a folder for development:
```bash
# Current Directory: "~"
mkdir -m 755 hdr-dev
cd hdr-dev
```

Download the latest release of the setup scripts, and run `setup-wsl-dev-env.sh`:

```bash
# Current Directory: "~/hdr-dev"
sudo apt install unzip # if necessary
curl -L https://github.com/Savestate2A03/hdr-wsl-dev-env-setup/releases/download/v1.1/hdr-dev-env-scripts.zip -o scripts.zip
unzip scripts.zip -d .
rm scripts.zip
chmod 755 setup-*.sh # make executable
./setup-wsl-dev-env.sh
```

```txt
==> Installing WSL packages
Get:1 http://security.ubuntu.com/ubuntu noble-security InRelease [126 kB]
Hit:2 http://archive.ubuntu.com/ubuntu noble InRelease
Get:3 http://security.ubuntu.com/ubuntu noble-security/main amd64 Packages [1668 kB]
Get:4 http://archive.ubuntu.com/ubuntu noble-updates InRelease [126 kB]
Get:5 http://security.ubuntu.com/ubuntu noble-security/main Translation-en [264 kB]
...
```

Once packages finish installing, provide values for the setup variables (**Make sure to not use the default SD_HOME_DIR!**) \
You will see that I am using my own fork of HDR instead of the default here as well:

<img width="904" height="331" alt="image" src="https://github.com/user-attachments/assets/032bf512-c022-475d-ab08-1fc3907939e6" />

Log into **GitHub** when prompted and `HewDraw-Remix` will be cloned:

<img width="734" height="481" alt="image" src="https://github.com/user-attachments/assets/f15fa9e5-4b6c-4cdf-ab5a-74ea2dd97520" />

`rustc 1.95.0-nightly` will be installed:

<img width="819" height="956" alt="image" src="https://github.com/user-attachments/assets/22fc5af9-8fad-4f02-bbf4-62f33913762c" />

`cargo-skyline` will be compiled/installed:

<img width="784" height="472" alt="image" src="https://github.com/user-attachments/assets/3665a0ec-273d-461e-a454-6650ebc7a72e" />

Skyline `std`/target files will be compiled/installed:

<img width="1111" height="743" alt="image" src="https://github.com/user-attachments/assets/f4b0a63d-d87f-4f46-980a-9651d61a3713" />

Target JSON file will be updated:

<img width="719" height="190" alt="image" src="https://github.com/user-attachments/assets/bbba8f63-f0fd-4768-8fb8-5b9a5bf5d710" />

`rust-analyzer` will be configured properly:

<img width="1028" height="213" alt="image" src="https://github.com/user-attachments/assets/4f2612a8-e070-49ac-bfee-4865cfde67a5" />

Some final output information about directories, the environment, building, and helpful aliases will be provided:

<img width="1278" height="902" alt="image" src="https://github.com/user-attachments/assets/4a5070c6-894c-48f4-9495-eab595365336" />

**Do add the aliases!!!**

## Entering the HDR Development Environment

### From the Command Line
If you intend to run build commands from the command-line directly, run the alias `start-hdr` if added \
...or run the provided `env.sh` script via `source`.

Note: You will be given an indication that you are in the **HDR Dev Env** in your shell: `([HDR])`. To exit, type in the command `leave-hdr`.

<img width="692" height="122" alt="image" src="https://github.com/user-attachments/assets/1f2ad845-6d75-4223-b424-bd5c059fc2bb" />

Build once you are in the **HDR Dev Env**:

<img width="1209" height="320" alt="image" src="https://github.com/user-attachments/assets/7b55c6fc-e018-416c-abf1-0d459d16c396" />

<img width="1097" height="230" alt="image" src="https://github.com/user-attachments/assets/474f8b33-b613-48c2-9816-c0f8525996d6" />

Deploy to your SD card:

<img width="1220" height="861" alt="image" src="https://github.com/user-attachments/assets/12e364ce-629a-4212-a892-f5c55d647860" />

### Directly in VSCode

Run the alias `start-hdr-vscode` if added, or run the provided powershell command in the info block:

<img width="1042" height="76" alt="image" src="https://github.com/user-attachments/assets/5fb11bd3-ae30-437a-8484-36058680ec4f" />

On first launch:
- Click "I trust the authors" when prompted by VSCode
- Press Ctrl + Shift + P, run "`>Developer: Reload Window`"
- Install the WSL extension when prompted (if not, go [here](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl))
- Install the other workspace recommendations and enable them in the workspace:
- Press Ctrl + Shift + P, run "`>Developer: Reload Window`" again
- Double check all are installed and enabled in the workspace

**Before**:<br><img width="693" height="392" alt="image" src="https://github.com/user-attachments/assets/3f28d23d-7729-4f2f-871c-968412326233" />

**After**:<br><img width="693" height="535" alt="image" src="https://github.com/user-attachments/assets/901777ad-11bd-4ee1-8f09-a49dd966bcfe" />
