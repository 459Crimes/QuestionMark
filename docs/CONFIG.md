# Configuration

All model behavior of `?` is controlled by a single config file plus a small
set of environment variables. Models and aliases are **not** hardcoded in the
wrapper — they live in your config so you can change providers without
touching code.

## Config file

### Locations (first match wins)

1. `$QM_CONFIG_FILE` — explicit override
2. `~/.config/ask-cli/models.conf` (respects `$XDG_CONFIG_HOME`)
3. `config/models.conf` relative to the repo copy of `bin/?`

`install.sh` writes the default config to location 2 (never overwriting an
existing file). Edits are picked up immediately — no reinstall, no restart.

### Format

The file is sourced by the wrapper, so it's plain `NAME=value` shell syntax
(follow the format below; values must stay on one line).

### Keys

| Key | Meaning | Shipped default |
| --- | --- | --- |
| `QM_DEFAULT_MODEL` | model used when you pass no `-m:` | `default` |
| `QM_FALLBACK_MODEL` | auto-retry model on usage limits | `opencode/gpt-5.6-luna` |
| `QM_FALLBACK_VARIANT` | opencode variant for the fallback | `low` |
| `QM_ALIAS_<name>` | alias usable as `? -m:<name>` | see below |

### The `default` sentinel

```
QM_DEFAULT_MODEL=default
```

`default` is special: it tells `?` to **not pass `--model` at all**, leaving
model selection entirely to opencode (opencode's own default mode). Any other
value is treated as an explicit model id:

```
QM_DEFAULT_MODEL=anthropic/claude-opus-4
```

### Aliases

Every `QM_ALIAS_<name>=provider/model` line adds a `? -m:<name>` alias. The
shipped config defines:

```
luna   -> openai/gpt-5.6-luna
terra  -> openai/gpt-5.6-terra
sol    -> openai/gpt-5.6-sol
deep   -> deepseek/deepseek-v4-pro
flash  -> deepseek/deepseek-v4-flash
gemma  -> openrouter/google/gemma-4-31b-it
opus   -> anthropic/claude-opus-4
grok   -> x-ai/grok-4
```

Add your own freely:

```
QM_ALIAS_thor=mistralai/mistral-large
```

Alias lookup only kicks in for values without a `/` — anything containing a
slash is treated as a literal model id.

### Fallback

When the running model reports a usage-limit signature (`rate limit`, `usage
limit`, `quota`, `429`, `too many requests`, `insufficient`, `limit
exceeded`), `?` retries once on `QM_FALLBACK_MODEL` with
`QM_FALLBACK_VARIANT`. This only happens when you did **not** pass `-m:`
explicitly.

---

## Environment variables

| Variable | Purpose | Default |
| --- | --- | --- |
| `QM_THREADS_DIR` | central thread store directory | `$XDG_DATA_HOME/ask-cli/threads` → `~/.local/share/ask-cli/threads` |
| `QM_CONFIG_FILE` | explicit path to the model config | see locations above |
| `OPENCODE_BIN` | path/name of the opencode binary | `opencode` |
| `PYTHON_BIN` | python interpreter name | `python3` |

Example session overrides:

```sh
export QM_THREADS_DIR=/mnt/big/ask-threads
export OPENCODE_BIN="$HOME/.opencode/bin/opencode"
export PYTHON_BIN=python     # Windows Git Bash
```

---

## Quick recipes

Use opencode's default model unless told otherwise:

```conf
QM_DEFAULT_MODEL=default
```

Pin a private model for sensitive work:

```conf
QM_DEFAULT_MODEL=anthropic/claude-opus-4
opencode auth login
```

Add a cheap alias and make it the fallback:

```conf
QM_ALIAS_lite=deepseek/deepseek-v4-flash
QM_FALLBACK_MODEL=deepseek/deepseek-v4-flash
QM_FALLBACK_VARIANT=low
```

Explanation of every default: while `?` ships with a sensible fallback to
`opencode/gpt-5.6-luna`, the **default** is deliberately opencode's own
default model so you don't subscribe to any specific provider until you opt
in with a `QM_ALIAS_*` or `QM_DEFAULT_MODEL`.