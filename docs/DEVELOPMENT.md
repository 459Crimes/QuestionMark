# Development

## Repository layout

```
bin/?                 the wrapper (bash + inline python3 helpers)
agents/ask.md         the read-only `ask` agent definition
config/models.conf    default model/alias config template
install.sh            one-command installer (Linux/macOS/Git Bash)
shell/qm.cmd          optional Windows launcher
shell/ask-cli.bashrc  alias block: alias '?'='/usr/local/bin/?'
tests/
  test-wrapper.sh     full regression suite
  mock-opencode.sh    fake `opencode` CLI used by the tests
docs/                 this documentation
LICENSE               MIT
```

## Running the tests

The suite exercises the wrapper against a **mock** `opencode` binary
(`tests/mock-opencode.sh`), so no real model or network is needed. Tests use
a temporary threads dir, a temp HOME, and a temp workspace.

```sh
bash tests/test-wrapper.sh
```

On success the last line is `wrapper tests passed`. The suite covers:

- `-h` / `-H` / `--help` and the `? -h` convention
- flag forms (colon vs separated) and required-value errors
- unknown option rejection
- default model (opencode's own, i.e. no `--model`) + agent flags passed to
  opencode
- agent type inheritance when continuing a thread
- model override + fallback retry on a simulated usage-limit error
- thread id creation, suffix/full-id resolution, and collision fallback
- listing and searching thread stores
- config file loading: default model, custom aliases (`QM_ALIAS_*`), and
  `QM_CONFIG_FILE` override

## Mock opencode

`tests/mock-opencode.sh` is placed on PATH (as `opencode`) ahead of the real
binary. It logs/validates the argument vector the test expects (the
`expect-model` and `expect-session` scenarios), prints a fake NDJSON event
stream (sessionID + text part) for `run`, and can simulate a usage-limit
signature to exercise the fallback path. Its default model string is only the
mock's own fallback — the wrapper itself decides whether a `--model` flag is
passed.

## Making changes

1. `bin/?` is the whole CLI — flags, model aliases, thread logic, timeout.
2. Model defaults and aliases belong in `config/models.conf` and its docs
   (`docs/CONFIG.md`), not hardcoded.
3. Keep the wrapper POSIX-ish and dependency-light: bash + python3 + standard
   coreutils (see `docs/INSTALLATION.md` for the full list).
4. Add a test in `tests/test-wrapper.sh` for every behavior change.
5. Run the suite; then commit and push.

## Contributing

Open an issue or PR on GitHub:
https://github.com/459Crimes/QuestionMark

Changes that affect user-facing behavior should update `docs/USAGE.md` and
`docs/INSTALLATION.md` in the same commit.