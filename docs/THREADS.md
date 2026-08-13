# Threads

Every `?` response belongs to a named thread. Threads let you continue a
conversation later, keep the same opencode session (so context carries over),
and search your question history.

## Thread id format

```
<yymmdd><??????>
  │        └── 6 hex chars, random per thread
  └── date the thread was created, e.g. 260813 = 2026-08-13
```

Example: `260813a1b2c3` was created on 2026-08-13 with suffix `a1b2c3`.
Suffixes come from `openssl rand -hex 3` when available, else a shell-random
fallback, and are guaranteed unique against existing files before the thread
is created.

## Where threads live

Central store, independent of your working directory:

```
${QM_THREADS_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/ask-cli/threads}
```

So on a default Linux/macOS system: `~/.local/share/ask-cli/threads/`. One
JSON file per thread, named `<id>.json`:

```json
{
  "id": "260813a1b2c3",
  "date": "260813",
  "hex": "a1b2c3",
  "sessionID": "<opencode session id>",
  "agentType": "ask",
  "model": "default",
  "directory": "/home/alice",
  "question": "why is the sky blue",
  "lastQuestion": "why is the sky blue",
  "created": 1784044800,
  "updated": 1784044860
}
```

The `sessionID` is the real OpenCode session that produced the answer;
resuming a thread re-uses that session so the model remembers prior turns.

## Creating

A fresh question with no `-t:` gets a brand-new id, and the answer stores the
session, model, agent type, workspace, and the question.

## Continuing

```sh
? "the codeword is plumbus"
[thread 260813a1b2c3]

? -t:a1b2c3 "what is the codeword?"     # continues the same session
[thread 260813a1b2c3] (continued)
```

Resolution rules for `-t:<ref>`:

| Ref form | Resolution |
| --- | --- |
| 6 hex chars | `yymmdd` (today) + ref → exact thread; if none exists, **newest** past thread with that suffix by `updated` timestamp |
| 12 hex chars | the exact thread id |
| anything else | error: `invalid thread id` |

When continuing:

- The **model** is inherited from the stored thread unless you pass `-m:`.
- The **agent type** is inherited unless you pass `-a:`.
- The stored **sessionID** is passed back to opencode, preserving context.

## Listing

```sh
? -l
ID             AGENT  MODEL                        QUESTION
260813a1b2c3   ask    default                      why is the sky blue
2507319f0a11   ask    anthropic/claude-opus-4      remember the codeword
```

Sorted newest-first by `updated`. Shows id, agent type, model, and the first
line (60 chars) of `lastQuestion`. Empty store prints `no threads found`.

## Searching

```sh
? -s:plumbus
```

Case-insensitive substring match against the full thread metadata (id, date,
hex, model, agent, directory, question, lastQuestion). Newest-first, same
output format as `-l`.

## Deletion & housekeeping

There is no delete flag. Threads are plain JSON files — remove them directly:

```sh
rm "$HOME/.local/share/ask-cli/threads/260813a1b2c3.json"
```

Or wipe the store entirely (also see uninstall in `docs/INSTALLATION.md`).

## Collision behavior

- New ids retry until the hex suffix is unused, so accidental collision is
  practically impossible.
- Suffix continuation resolves "today first, else newest matching" precisely
  so an old thread can still be reached by a short suffix after today rolls
  over — but if two old threads share a suffix, the **newest one wins**. Use
  the full 12-char id to disambiguate.
