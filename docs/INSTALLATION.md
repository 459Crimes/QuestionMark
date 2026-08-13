# Installation

`?` (ask-cli) is a thin bash wrapper around the
[OpenCode](https://opencode.ai) CLI. Getting it running is three steps on every
platform:

1. **Install OpenCode** (the engine that answers the question).
2. **Install the base runtimes** `bash` and `python3`.
3. **Install the `?` wrapper + the `ask` agent**, then add the `?` command to
   your shell.

A single `?` run needs: `bash`, `python3`, `opencode`, `sed`, `grep`, `date`,
`mktemp`, and optionally `openssl` (used only for random thread suffixes;
there is a built-in shell fallback). `timeout`/`gtimeout`/Perl handle the 90s
timeout (Linux: GNU `timeout`; macOS: Perl fallback is automatic).

---

## 1. Install OpenCode

Pick any one of these; all put the `opencode` binary on your PATH.

| Method | Command | Platforms |
| --- | --- | --- |
| Official installer | `curl -fsSL https://opencode.ai/install \| bash` | Linux, macOS, WSL2 |
| npm | `npm i -g opencode-ai` | All (needs Node.js 18+) |
| bun | `bun add -g opencode-ai` | All (needs bun) |
| Homebrew | `brew install anomalyco/tap/opencode` | macOS, Linuxbrew |
| Chocolatey | `choco install opencode` | Windows (Native + Git Bash) |
| Scoop | `scoop install opencode` | Windows |
| Arch (AUR) | `paru -S opencode` | Arch Linux |
| Arch (extra) | `pacman -S opencode` | Arch Linux |
| mise | `mise use -g opencode` | All |
| Nix | `nix run nixpkgs#opencode` | NixOS / Nix |

Binary is placed (in priority order) at `$OPENCODE_INSTALL_DIR` →
`$XDG_BIN_DIR` → `~/.local/bin` → `~/.opencode/bin`. If it lands in a custom
spot, tell the wrapper where via `OPENCODE_BIN` (see step 3).

Verify:

```sh
opencode --version
opencode auth login   # only needed if your chosen model requires it
```

---

## 2. Install base runtimes

### Linux

```sh
sudo apt install bash python3        # Debian/Ubuntu
sudo dnf install bash python3        # Fedora
sudo pacman -S bash python3          # Arch
```

Both are already present on essentially every Linux system.

### macOS

`bash` ships with macOS (3.2; fine for this wrapper). If you use bash-heavy
interactive features, prefer a modern bash:

```sh
brew install bash python@3
```

`python3` is present on macOS 12.3+. If missing, `brew install python@3`.

### Windows

Windows does **not** ship `bash` or `python3` natively. There are two routes:

**Route A — WSL2 (recommended).** You get a full Linux environment; then
follow the *Linux* instructions above inside the WSL distro. The `?` binary
name works normally there (WSL filesystems allow `?`).

```sh
wsl --install -d Ubuntu        # from an admin PowerShell
# then: curl -fsSL https://opencode.ai/install | bash
#       sudo apt install python3
```

**Route B — Git Bash (MSYS2 / Git for Windows).**

1. Install [Git for Windows](https://git-scm.com/download/win) (provides
   `bash`, `sed`, `grep`, `mktemp`, `openssl`).
2. Install [python.org Python 3](https://www.python.org/downloads/) **and**
   check "Add python to PATH".
3. Git Bash exposes Python as `python` (not `python3`), so point the wrapper at
   it with `export PYTHON_BIN=python` in `~/.bashrc`.
4. On NTFS the literal filename `?` is illegal, so Windows installs get a
   renamed copy called `qm` plus a `qm.cmd` launcher. See the Windows section
   below.

---

## 3. Install the wrapper + `ask` agent

The repo ships these files:

```
bin/?                 the wrapper itself (bash)
agents/ask.md         the read-only `ask` agent definition
config/models.conf    default model/alias config template
install.sh           one-command installer (Linux/macOS/Git Bash)
shell/qm.cmd         optional Windows launcher
shell/ask-cli.bashrc alias block for interactive shells (optional)
```

### Linux / macOS — via install.sh

```sh
git clone https://github.com/459Crimes/QuestionMark.git
cd QuestionMark
./install.sh --prefix ~/.local/bin
? -h
```

`install.sh` copies `bin/?` to `--prefix` (default `~/.local/bin`) and
`agents/ask.md` to `~/.config/opencode/agents/ask.md`. With `--sudo` it
installs to `/usr/local/bin` and symlinks the repo copy so upgrades are
`git pull` + re-run. If the prefix isn't already on your PATH, add:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

### Linux / macOS — manual

```sh
install -Dm755 bin/? "$HOME/.local/bin/?"
mkdir -p "$HOME/.config/opencode/agents"
cp agents/ask.md "$HOME/.config/opencode/agents/ask.md"
```

### Windows — Git Bash (rename for NTFS)

Inside a Git Bash terminal:

```sh
git clone https://github.com/459Crimes/QuestionMark.git
cd QuestionMark
install -Dm755 bin/? "$HOME/bin/qm"
mkdir -p "$HOME/.config/opencode/agents"
cp agents/ask.md "$HOME/.config/opencode/agents/ask.md"
# rename for Windows callers
cp "$HOME/bin/qm" "$HOME/bin/qm.bash"
```

Then create the native launcher `%USERPROFILE%\bin\qm.cmd` (or use the shipped
`shell/qm.cmd`, edited to the right paths):

```bat
@echo off
bash -lc "qm.bash %*"
```

(In practice, most Windows users find it simplest to just run `qm` from inside
Git Bash, skipping the `.cmd`.

### Windows — WSL2

Follow the Linux instructions inside your WSL distro. `?` works as-is because
`?` is a legal filename on ext4. To call it from the Windows side,
`wsl ? <question>` works if you add the distro's bin dir to its PATH.

### macOS Perl-alarm note

macOS has GNU `timeout` only if you `brew install coreutils`. Otherwise the
wrapper automatically uses a Perl `alarm()` fallback for its 90-second
timeout, so no action is needed.

---

## Required files per platform

| File | Linux | macOS | Windows (Git Bash) | Windows (WSL2) |
| --- | --- | --- | --- | --- |
| `bin/?` → on PATH named `?` | yes | yes | rename to `qm` | yes (`?`) |
| `shell/qm.cmd` launcher | — | — | optional | optional |
| `agents/ask.md` → `~/.config/opencode/agents/ask.md` | yes | yes | yes | yes (in distro) |
| `config/models.conf` → `~/.config/ask-cli/models.conf` | yes | yes | yes | yes (in distro) |
| `bash` in PATH | yes | yes (3.2+) | via Git for Windows | via distro |
| `python3` in PATH | yes | yes (12.3+) | yes (as `python`, set `PYTHON_BIN`) | yes |
| `opencode` in PATH | yes | yes | yes | yes |
| `openssl` | optional | optional | via Git for Windows | optional |
| `timeout`/`gtimeout`/Perl | GNU `timeout` | Perl (auto) | via Git Bash | GNU `timeout` |

The only true platform difference: **Windows cannot create a file named
`?`**, so the wrapper is installed there under the name `qm`. Everything else
is identical.

---

## Configure models

Models and aliases live in a config file, not in the wrapper itself. See
[docs/CONFIG.md](CONFIG.md) for the full reference. The short version:

- **Default model:** `QM_DEFAULT_MODEL`. The shipped default is `default`,
  which means **opencode's own default model** — `?` then passes *no*
  `--model` flag to opencode. Set it to a full model id
  (`QM_DEFAULT_MODEL=anthropic/claude-opus-4`) to pin one.
- **Aliases:** any `QM_ALIAS_<name>=provider/model` line becomes a usable
  `? -m:<name>`. The repo ships `luna`, `terra`, `sol`, `deep`, `flash`,
  `gemma`, `opus`, and `grok`.
- **Fallback:** `QM_FALLBACK_MODEL` / `QM_FALLBACK_VARIANT` control the
  automatic retry when the default model hits a usage limit.

Config locations, first match wins:

1. `$QM_CONFIG_FILE`
2. `~/.config/ask-cli/models.conf` (`$XDG_CONFIG_HOME` aware)
3. the `config/models.conf` shipped with the repo

`install.sh` writes the default config to `~/.config/ask-cli/models.conf`
(without overwriting an existing file). Edit it and the change is picked up
immediately — no reinstall needed.

---

## Environment variables

| Variable | Purpose | Default |
| --- | --- | --- |
| `QM_THREADS_DIR` | central thread store | `$XDG_DATA_HOME/ask-cli/threads` → `~/.local/share/ask-cli/threads` |
| `QM_CONFIG_FILE` | path to the model/alias config | `~/.config/ask-cli/models.conf` → repo `config/models.conf` |
| `OPENCODE_BIN` | path/name of the opencode binary | `opencode` |
| `PYTHON_BIN` | python interpreter name | `python3` |

---

## Uninstall

```sh
rm -f "$HOME/.local/bin/?"            # or where install.sh --prefix put it
rm -f "$HOME/.config/opencode/agents/ask.md"
rm -rf "$HOME/.local/share/ask-cli"   # your threads — back them up first if needed
```

Windows: remove `%USERPROFILE%\bin\qm*` and the same agent/thread paths.