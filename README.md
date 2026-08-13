# `?` — ask anything from your terminal

`?` is a single-shot question-and-answer command for the terminal, powered by
[OpenCode](https://opencode.ai). Ask a question and get a direct answer on the
command line — no IDE, no browser, no chat window. Every answer belongs to a
named **thread** you can continue, list, or search later.

```console
$ ? why is the sky blue
[thinking… opencode default model]
Rayleigh scattering scatters shorter wavelengths (blue) more than longer ones...

[thread 260813a1b2c3]
```

- **Zero chrome.** Flag parsing happens before the first ordinary word, so
  prompt quoting is optional: `? why is the sky blue` just works.
- **Read-only by default.** The built-in `ask` agent can read your local
  knowledge base but cannot edit files, run shell commands, or browse the web.
- **Task-capable on demand.** `? -a:agent` switches to a full task agent that
  *can* edit files, run commands, and do multi-step work from the CLI.
- **Named threads.** Every response carries a `<yymmdd??????>` thread id
  (`260813a1b2c3` = today + 6 random hex chars). Continue it with `-t:<suffix>`,
  keep answers in context, and housekeep with `-l` / `-s:<term>`.
- **One store, anywhere.** Threads live in a single central directory no
  matter which working directory you run `?` from.
- **Your models, your default.** The default is opencode's own default model.
  Pin any model (`? -m:opus`) or globally (`QM_DEFAULT_MODEL`) and add your own
  aliases via a config file — see [docs/CONFIG.md](docs/CONFIG.md).
- **Automatic fallback.** If the running model hits a usage limit, `?` retries
  on a configurable fallback model in the same thread.

---

## Quickstart

The only hard requirements are **bash**, **python3**, and the **opencode**
CLI. Nothing else — see [docs/INSTALLATION.md](docs/INSTALLATION.md) for full
platform instructions. As a tldr:

  - **Linux / macOS:** run `./install.sh`, then `? -h`.
  - **Windows:** install via WSL2 (recommended) or Git Bash with a renamed
    `qm` launcher — NTFS cannot hold a file literally named `?`.
  - **opencode** itself:
    `curl -fsSL https://opencode.ai/install | bash`, or
    `npm i -g opencode-ai`, `brew install anomalyco/tap/opencode`,
    `choco install opencode`, `scoop install opencode`.

After install, verify:

```sh
? -H
? "hello from questionmark"
? -l
```

---

## Documentation

| Doc | What it covers |
| --- | --- |
| [docs/INSTALLATION.md](docs/INSTALLATION.md) | Linux, macOS, and Windows installs; required files per platform; uninstall |
| [docs/CONFIG.md](docs/CONFIG.md) | Models, aliases, the `default` sentinel, fallback, env vars |
| [docs/USAGE.md](docs/USAGE.md) | Full CLI reference: flags, model aliases, examples, stdout/stderr contract, exit codes |
| [docs/THREADS.md](docs/THREADS.md) | Thread model, central storage, continuation and collision rules, list/search |
| [docs/AGENTS.md](docs/AGENTS.md) | The `ask` vs `agent` roles and the permission model behind them |
| [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) | Running the test suite, the mock opencode, and the repo layout |

## Feature overview

### Ask, one-shot

```sh
? "why is the sky blue"
? -m:deep "summarize this repository"
? -w:~/projects -m:opus "who keeps the notes here?"
```

### Run a task

```sh
? -a:agent "run the test suite and fix any failures"
? -a:agent -w:$PWD "add a --dry-run flag to the build script"
```

### Continue a conversation

```sh
? "remember the codeword: plumbus"
# … later …
? -t:<suffix> "what is the codeword?"
```

Continuations hit the same opencode session, so context carries over —
verified live across turns in the test suite and in production use.

### Find old answers

```sh
? -l              # list all threads, newest first
? -s:plumbus      # search thread metadata
```

See [docs/THREADS.md](docs/THREADS.md) for the full thread lifecycle.

---

## How it works

`?` runs `opencode run --format json`, which emits a newline-delimited JSON
event stream. The wrapper:

1. Runs opencode with the model from config (`-m:` / `QM_DEFAULT_MODEL`, or no
   `--model` at all for opencode's default) via the chosen agent (`ask` or
   `agent`).
2. Parses the event stream with `python3`, extracting the plain answer and the
   real opencode **session id**.
3. Stores that session id (plus model/agent/question metadata) in a central
   thread store keyed by its `<yymmdd??????>` id.
4. Prints the stripped answer to **stdout** and the thread id to **stderr**,
   so `? "..." > out.txt` captures only the answer.
5. On a usage-limit signature and no explicit `-m:`, retries the same thread
   on the configured fallback model.

Everything the wrapper needs is standard: `bash`, `python3`, `sed`, `grep`,
`date`, `mktemp`, and `openssl` (optional — random suffixes fall back to
`/dev/urandom`-free shell arithmetic). Timeouts use GNU `timeout`,
`gtimeout`, or a Perl `alarm()` fallback on macOS.

## Environment variables

| Variable | Meaning | Default |
| --- | --- | --- |
| `QM_THREADS_DIR` | Central thread store location | `$XDG_DATA_HOME/ask-cli/threads` → `~/.local/share/ask-cli/threads` |
| `QM_CONFIG_FILE` | Path to the model/alias config | `~/.config/ask-cli/models.conf` → repo `config/models.conf` |
| `OPENCODE_BIN` | Path/name of the opencode executable | `opencode` |
| `PYTHON_BIN` | Path/name of the python interpreter | `python3` |

## Models, aliases, and the default

`?` does not hardcode a model. Configuration lives in
`~/.config/ask-cli/models.conf` (see [docs/CONFIG.md](docs/CONFIG.md)):

- **Default:** `QM_DEFAULT_MODEL=default` means *opencode's default model* —
  no `--model` flag is passed. Set it to a full id to pin one.
- **Aliases:** `QM_ALIAS_opus=anthropic/claude-opus-4` gives you
  `? -m:opus`. Shipped aliases include `luna`, `terra`, `sol`, `deep`,
  `flash`, `gemma`, `opus`, `grok`.
- **Fallback:** a usage-limit hit retries once on `QM_FALLBACK_MODEL`
  (`opencode/gpt-5.6-luna` by default, low variant) in the same thread.

Providers require their credentials in opencode (`opencode auth login`).

## Security & data handling

The default `ask` agent is deliberately locked down: read-only, no shell, no
editing, no web — see [docs/AGENTS.md](docs/AGENTS.md). Switch to `agent` mode
only when you intend to let the model mutate your system. When no model is pinned, `?` runs opencode's own default model and opencode's
free-tier/Zen policies (which may permit training on request data) apply. See
[docs/USAGE.md#privacy-notes](docs/USAGE.md#privacy-notes).

## License

MIT — see [LICENSE](LICENSE).