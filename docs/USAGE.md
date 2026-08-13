# Usage

## Quick reference

```
usage: ? [flags] "<question>"
  e.g. ? "why is the sky blue"
       ? -m:luna -w:~/projects "summarize this repo"
       ? -t:a1b2c3 "what was the last thing we discussed"

model aliases: from config (default set: luna, terra, sol, deep, flash, gemma, opus, grok)

flags:
  -m:<model> | --model:<model>    model or alias (also 'separated value' form)
  -w:<dir>  | --workspace:<dir>   workspace directory (also separated form)
  -a:<type> | --agent-type:<type>  ask (default) or agent (task-capable)
  -t:<id>   | --thread:<id>       continue a thread by its 6-hex suffix (today) or full id
  -l        | --list              list threads
  -s:<term> | --search:<term>     search threads
```

> **Always quote your question.** The command is literally named `?` and the
> shell treats `*`, `?`, and other metacharacters specially. Wrap your question
> in double quotes every time: `? "why is the sky blue"` — a bare question like
> `? why is the sky blue?` can be mangled by shell globbing, and a question
> starting with `-` (e.g. `? -m is that a flag?`) is read as an option.
>
> **Flag rule:** flags are parsed **only before the first ordinary word**.
> Once the first non-flag argument appears, everything after it is part of the
> literal question.
> If a question itself starts with a hyphen you must still quote it, and to be
> explicit use `--` to end flag parsing: `? -- "-m is that a flag?"`.

---

## Flags in detail

### `-m:<model>` / `--model:<model>` — choose the model

```sh
? -m:luna "do a creative rewrite"
? -m:deepseek/deepseek-v4-pro "explain the difference"
? -m flash "fast answer, low cost"
```

Both colon and separated forms work: `-m luna` is the same as `-m:luna`.
Values can be a full model id or an **alias** from your config file
(`QM_ALIAS_<name>` in `~/.config/ask-cli/models.conf` — e.g. `luna`, `opus`,
`grok`). Model-specific credentials are checked against your opencode account.

**What if I pass no `-m:` at all?** The config's `QM_DEFAULT_MODEL` decides.
Its shipped value is `default`, which means `?` passes no `--model` flag and
opencode uses its own default model. Pin a specific model by setting
`QM_DEFAULT_MODEL=<model id>` in the config. See [CONFIG.md](CONFIG.md).

### `-w:<dir>` / `--workspace:<dir>` — scope the answer to a directory

```sh
? -w:~/projects "who keeps the system notes?"
? --workspace "$HOME/projects" "list our conventions"
```

The default workspace is `$HOME`. The directory must already exist.

### `-a:<type>` / `--agent-type:<type>` — ask or task

| Type | Meaning |
| --- | --- |
| `ask` (default) | Read-only Q&A. No file edits, no shell, no web. See `docs/AGENTS.md`. |
| `agent` | Task-capable. Can edit files, run commands, browse. Mutates your system. |

```sh
? -a:ask "what is the capital of France"
? -a:agent "run the tests and fix the failure"
```

### `-t:<id>` / `--thread:<id>` — continue a conversation

```sh
? "remember the codeword: plumbus"
[thread 260813a1b2c3]

# later — either of these resumes the same opencode session:
? -t:a1b2c3 "what is the codeword?"
? -t:260813a1b2c3 "what is the codeword?"
```

- A **6-hex suffix** resolves to *today's* thread with that suffix; if none,
  it falls back to the most recently updated matching thread (any date).
- A **full 12-char id** (`yymmdd` + 6 hex) targets that exact thread.
- When continuing, the model and agent type are inherited from the stored
  thread unless you override them with `-m:` / `-a:`.

### `-l` / `--list` — list all threads

```sh
? -l
ID             AGENT  MODEL                        QUESTION
260813a1b2c3   ask    default                      why is the sky blue
2507319f0a11   ask    anthropic/claude-opus-4      remember the codeword
```

Newest first. Question shows only the first line, truncated to 60 chars.

### `-s:<term>` / `--search:<term>` — search threads

```sh
? -s:plumbus
? -s "gridlock"
```

Matches the term against the **entire thread metadata blob** (id, model,
agent, workspace, question, last question — any substring, case-insensitive).

---

## Output contract

| Stream | Content |
| --- | --- |
| stdout | the model's plain-text answer only |
| stderr | `[thinking… <model>]` progress line, `[thread <id>]` line, usage/errors |

This makes two patterns trivially safe:

```sh
? "what does this repo do" > answer.txt     # captures just the answer
? -t:a1b2c3 "hi again" 2>/dev/null          # quiet run, answer only
```

Exit codes:

| Code | Meaning |
| --- | --- |
| 0 | Answer produced (or thread listed / searched) |
| 2 | Usage/argument error, invalid option, bad agent type, missing value, workspace not a directory, unknown thread |
| 125 | temp-file creation failure |
| 126/127 | opencode binary missing or not executable |
| others | propagated from the opencode `run` call when it fails non-usage related |

---

## Fallback behavior

If a *default* model call fails with a usage-limit signature (`rate limit`,
`usage limit`, `quota`, `429`, `too many requests`, `insufficient`,
`limit exceeded`), `?` retries once on `opencode/gpt-5.6-luna` (low variant)
**in the same thread**, then prints:

```
[falling back to opencode/gpt-5.6-luna (low) -- <model> usage limit reached]
```

- Only triggers when you did **not** pass `-m:` explicitly (the heuristic is
  conservative).
- If both attempts fail, the error text is echoed to stderr and the last exit
  code is returned.

## Part-of-speech detail: `--`

Everything after a literal `--` is the question, even leading dashes. Always
still quote it:

```sh
? -- "-m:is this a flag or a word?"
? -- "--verbose is still terminal jargon"
```

---

## Examples gallery

```sh
# one-shot Q&A
? "summarize the git log in this repo"

# answer scoped to a specific workspace
? -w:~/projects/blog "explain the middleware stack"

# quick model alias (any alias from your config)
? -m:flash "compose a haiku about the command line"
? -m:grok "bet you can't rhyme ocelot"

# full task execution (mutating!) from the CLI
? -a:agent "create a README for this project and add a MIT LICENSE" -w:$PWD

# continue a conversation from this morning
? -t:4d90e1 "and one more thing about that idea"

# housekeeping
? -l
? -s:backup
```

## Privacy notes

Which model answers depends on your config (`QM_DEFAULT_MODEL`, or whatever
`-m:` you pass). Free-tier/Zen defaults permit training on request data — and
opencode's own default model may too, depending on provider policy. Do
**not** paste secrets, keys, or personal data into `?` unless you accept
that. The `agent` type is more capable and your real workspace contents (as
the model sees them) can end up in provider logs. Treat `?` as a read-write
remote evaluator and pin an authenticated, private model
(`QM_DEFAULT_MODEL=<model id>`, `opencode auth login`) for sensitive corpus
work.