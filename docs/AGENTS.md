# Agents

`?` supports two agent types, selected with `-a:<type>` / `--agent-type:<type>`:

| Type | Capability | Use for | Safety |
| --- | --- | --- | --- |
| `ask` (default) | read-only Q&A | questions, summaries, explanations | locked down |
| `agent` | full task execution | editing code, running commands | trust the model |

## `ask` — the read-only Q&A agent

Loaded from `agents/ask.md`, installed as
`~/.config/opencode/agents/ask.md` and dispatched with `--agent ask`. It is
deliberately conservative:

- **Reads** local files and your knowledge base to ground answers.
- **Cannot edit or create files.**
- **Cannot run shell commands.**
- **Cannot browse the web.**

It is the safe default for the "just ask" workflow: you can point it at a
workspace with `-w:` and trust it won't mutate anything.

> Note: `ask` mode answers from what the model already knows plus whatever it
> can read from the `-w:` workspace. It is not a web search tool.

## `agent` — the task-capable agent

Selected with `-a:agent`. Uses opencode's built-in default task agent, so no
`--agent` flag is passed to opencode. It **can**:

- edit and create files,
- run shell commands,
- perform multi-step tasks (e.g. "run the tests and fix the failure").

Because it mutates your system, `-a:agent` is the type you reach for when you
genuinely want the model doing work, not just answering.

## How the wrapper chooses

- When you don't pass `-a:`, a brand-new question uses `ask` (the default).
- When you **continue** a thread with `-t:` and don't pass `-a:`, the stored
  thread's agent type is inherited.
- An explicit `-a:` always wins.

## Where agents live

| File | Purpose | Installed to |
| --- | --- | --- |
| `agents/ask.md` | the read-only agent definition | `~/.config/opencode/agents/ask.md` |

You can add your own agents following OpenCode's agent format; pass any custom
agent name via `-a:<name>` and the wrapper will forward `--agent <name>` **if
the name isn't `agent`** (i.e. `ask` and anything else you define dispatch
`--agent`, while `agent` uses opencode's default task agent).

## Customizing

Want `?` to use a different built-in agent? Define it in
`~/.config/opencode/agents/` (see OpenCode's agent docs for the schema) and
invoke it with `? -a:yourname ...`.