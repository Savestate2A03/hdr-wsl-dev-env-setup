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
    "CARGO_HOME": "/home/savestate/dev/hdr-dev/.hdr-wsl-dev/cargo",
    "RUSTUP_HOME": "/home/savestate/dev/hdr-dev/.hdr-wsl-dev/rustup",
    "GH_CONFIG_DIR": "/home/savestate/dev/hdr-dev/.hdr-wsl-dev/gh-config",
    "RUSTFLAGS": "--cfg skyline_std_v3",
    "SKYLINE_ADD_NRO_HEADER": "1",
    "PATH": "BIG_PATH_STRING_HERE"
  },
  "terminal.integrated.env.linux": {
    "CARGO_HOME": "/home/savestate/dev/hdr-dev/.hdr-wsl-dev/cargo",
    "RUSTUP_HOME": "/home/savestate/dev/hdr-dev/.hdr-wsl-dev/rustup",
    "GH_CONFIG_DIR": "/home/savestate/dev/hdr-dev/.hdr-wsl-dev/gh-config",
    "RUSTFLAGS": "--cfg skyline_std_v3",
    "SKYLINE_ADD_NRO_HEADER": "1",
    "PATH": "BIG_PATH_STRING_HERE"
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

Appends the lines to the user's local `.git/info/exclude` for HewDraw-Remix:
```.gitignore
# generated rust toolchain file from HDR WSL setup script
rust-toolchain.toml
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
curl -L https://github.com/Savestate2A03/hdr-wsl-dev-env-setup/releases/download/v1.0/hdr-dev-env-scripts.zip -o scripts.zip
unzip scripts.zip -d .
rm scripts.zip
chmod 755 setup-*.sh open-*.bat # make executable
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

Once packages finish installing, log into **GitHub** when prompted:

```txt
==> Installing GitHub CLI locally
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
100 13.6M  100 13.6M    0     0  39.6M      0 --:--:-- --:--:-- --:--:-- 39.6M

==> Checking GitHub login
The setup will open a GitHub login flow now.
This keeps GitHub credentials under the local .hdr-wsl-dev folder for this workspace.
? Authenticate Git with your GitHub credentials? Yes

! First copy your one-time code: ABCD-EF12
Press Enter to open https://github.com/login/device in your browser...
! Failed opening a web browser at https://github.com/login/device
  exec: "xdg-open,x-www-browser,www-browser,wslview": executable file not found in $PATH
  Please try entering the URL in your browser manually
✓ Authentication complete.
- gh config set -h github.com git_protocol https
✓ Configured git protocol
! Authentication credentials saved in plain text
✓ Logged in as YourGitHubUsernameHere
```

`HewDraw-Remix` will be cloned:

```txt
==> Cloning HewDraw-Remix
Cloning into '/home/savestate/hdr-dev/HewDraw-Remix'...
remote: Enumerating objects: 210422, done.
remote: Counting objects: 100% (11639/11639), done.
remote: Compressing objects: 100% (4563/4563), done.
remote: Total 210422 (delta 7548), reused 10283 (delta 6583), pack-reused 198783 (from 2)
Receiving objects: 100% (210422/210422), 125.14 MiB | 69.12 MiB/s, done.
Resolving deltas: 100% (120504/120504), done.
```

`rustc 1.95.0-nightly` will be installed:
```txt
==> Installing Rust toolchain nightly-2026-02-14
info: syncing channel updates for nightly-2026-02-14-x86_64-unknown-linux-gnu
info: latest update on 2026-02-14 for version 1.95.0-nightly (a423f68a0 2026-02-13)
info: downloading 6 components
        cargo installed                       10.49 MiB
       clippy installed                        4.46 MiB
    rust-docs installed                       20.91 MiB
     rust-std installed                       28.18 MiB
        rustc installed                       76.39 MiB
      rustfmt installed                        2.08 MiB
  nightly-2026-02-14-x86_64-unknown-linux-gnu installed - rustc 1.95.0-nightly (a423f68a0 2026-02-13)

info: default toolchain set to nightly-2026-02-14-x86_64-unknown-linux-gnu
info: checking for self-update (current version: 1.29.0)
info: using existing install for nightly-2026-02-14-x86_64-unknown-linux-gnu
info: default toolchain set to nightly-2026-02-14-x86_64-unknown-linux-gnu

  nightly-2026-02-14-x86_64-unknown-linux-gnu unchanged - rustc 1.95.0-nightly (a423f68a0 2026-02-13)
```

`cargo-skyline` will be compiled/installed:

```txt
==> Installing cargo-skyline
    Updating crates.io index
  Downloaded cargo-skyline v3.5.0
  Downloaded 1 crate (34.5KiB) in 0.03s
  Installing cargo-skyline v3.5.0
    Updating crates.io index
     Locking 292 packages to latest compatible versions
      Adding bytes v1.1.0 (available: v1.11.1)
      Adding cargo_metadata v0.10.0 (available: v0.23.1)
...
   Compiling linkle v0.2.11
   Compiling tokio-rustls v0.24.1
   Compiling hyper-rustls v0.24.2
   Compiling reqwest v0.11.27
   Compiling cargo-skyline-octocrab v0.1rm6.0
    Finished `release` profile [optimized] target(s) in 25.24s
  Installing /home/savestate/hdr-dev/.hdr-wsl-dev/cargo/bin/cargo-skyline
   Installed package `cargo-skyline v3.5.0` (executable `cargo-skyline`)

==> Installing Skyline std and target files
info: syncing channel updates for nightly-2026-02-14-x86_64-unknown-linux-gnu

  nightly-2026-02-14-x86_64-unknown-linux-gnu unchanged - rustc 1.95.0-nightly (a423f68a0 2026-02-13)

info: checking for self-update (current version: 1.29.0)
```

Skyline `std`/target files will be compiled/installed:

```txt
==> Installing Skyline std and target files
info: syncing channel updates for nightly-2026-02-14-x86_64-unknown-linux-gnu

  nightly-2026-02-14-x86_64-unknown-linux-gnu unchanged - rustc 1.95.0-nightly (a423f68a0 2026-02-13)

info: checking for self-update (current version: 1.29.0)

Cloning into '/home/savestate/hdr-dev/.hdr-wsl-dev/cargo/skyline/toolchain/skyline/lib/rustlib/src/rust'...
remote: Enumerating objects: 61171, done.
remote: Counting objects: 100% (61171/61171), done.
remote: Compressing objects: 100% (53289/53289), done.
Receiving objects: 100% (61171/61171), 44.14 MiB | 12.54 MiB/s, done.
remote: Total 61171 (delta 7697), reused 28724 (delta 6028), pack-reused 0 (from 0)
Resolving deltas: 100% (7697/7697), done.
Updating files: 100% (58144/58144), done.
Submodule 'library/backtrace' (https://github.com/rust-lang/backtrace-rs.git) registered for path 'library/backtrace'
Submodule 'src/doc/book' (https://github.com/rust-lang/book.git) registered for path 'src/doc/book'
...
Receiving objects: 100% (181/181), 118.59 KiB | 7.91 MiB/s, done.
Resolving deltas: 100% (113/113), completed with 101 local objects.
From https://github.com/rust-lang/rustc-perf
 * branch            c0301bc44d175b9b2c5442b25049475c39d7700c -> FETCH_HEAD
Submodule path 'src/tools/rustc-perf': checked out 'c0301bc44d175b9b2c5442b25049475c39d7700c'
```

Target JSON file will be updated:

```txt
Updated Skyline target JSON:
  /home/savestate/hdr-dev/.hdr-wsl-dev/cargo/skyline/aarch64-skyline-switch.json

==> Skyline target cfg
target_arch="aarch64"
target_feature="aes"
target_feature="crc"
target_feature="neon"
target_feature="sha2"
target_os="switch"
```

`rust-analyzer` will be configured properly:

```txt
==> Setting up rust-analyzer
Linked Skyline target:
  .cargo/aarch64-skyline-switch.json -> /home/savestate/hdr-dev/.hdr-wsl-dev/cargo/skyline/aarch64-skyline-switch.json
Updated .cargo/config.toml
Updated .vscode/settings.json

==> Done
```

Some final output information will be provided:

```txt
Repo:
  /home/savestate/hdr-dev/HewDraw-Remix

Local environment:
  /home/savestate/hdr-dev/.hdr-wsl-dev

Use this shell setup before working in a normal terminal:
  source "/home/savestate/hdr-dev/.hdr-wsl-dev/env.sh"

Open the repo in VS Code from Windows:
  \\wsl.localhost\Ubuntu-{xx.yy}\home\{username}\{hdr-dev-folder}\open-wsl-vscode.bat

Build check (after running source env above):
  cd "/home/savestate/hdr-dev/HewDraw-Remix"
  cargo skyline build --release
```

## Entering the HDR Development Environment

### From the Command Line
If you intend to run build commands from the command-line directly, run the provided `env.sh` script via `source`

```txt
savestate@DESKTOP-J27L40L:~/dev/hdr-dev$ source "/home/savestate/dev/hdr-dev/.hdr-wsl-dev/env.sh"
([HDR]) savestate@DESKTOP-J27L40L:~/dev/hdr-dev/HewDraw-Remix$
```

Note: You will be given an indication that you are in the **HDR Dev Env** in your shell: `([HDR])`. To exit, type in the command `leave-hdr`.

Build once you are in the **HDR Dev Env**:

```bash
cargo skyline build --release
```

### Directly in VSCode

Launching VSCode in the **HDR Dev Env**:
- Navigate to your WSL network drive: `\\wsl.localhost\Ubuntu-xx.yy\home\username\dev\hdr-dev` (example)
- Double click `open-wsl-vscode.bat`

On first launch:
- Click "I trust the authors" when prompted by VSCode
- Press Ctrl + Shift + P, run "`>Developer: Reload Window`"
- Install the WSL extension when prompted (if not, go [here](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl))
- Install the other workspace recommendations and enable them in the workspace:
- Press Ctrl + Shift + P, run "`>Developer: Reload Window`" again
- Double check all are installed and enabled in the workspace

**Before**:<br><img width="693" height="392" alt="image" src="https://github.com/user-attachments/assets/3f28d23d-7729-4f2f-871c-968412326233" />


**After**:<br><img width="693" height="535" alt="image" src="https://github.com/user-attachments/assets/901777ad-11bd-4ee1-8f09-a49dd966bcfe" />
