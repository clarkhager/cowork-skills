---
name: create-buzz-agent
description: Create, configure, or fix an agent in Buzz (block/buzz), the local agent runtime. Use whenever someone wants to set up a Buzz agent, choose a harness, write agent instructions or a system prompt for one, give an agent access to a folder or to MCP servers, skills or secrets, control who may send it instructions, tune parallelism or limits, or debug an agent that cannot see its files or tools. Trigger on "set up a Buzz agent", "make X a Buzz agent", "which harness should I use", "my Buzz agent can't read its files", "add MCP to my agent", "Buzz agent instructions", or a screenshot of Buzz's Create agent or Edit agent dialog. Also trigger when someone wants a persistent chat-addressable assistant and already runs Buzz, even if they never say "harness". Not for Claude Code subagents, Orca lanes, or OpenAI Assistants.
---

# Creating a Buzz agent

Buzz runs agents locally and exposes them over Nostr so you can talk to them from chat. This
skill covers the part people get wrong: **an agent's capability is decided almost entirely by the
harness you pick, and that choice is not obvious from the UI.**

Read `references/harnesses.md` when you need the full capability matrix, exact config paths, or
you are debugging why a tool is missing. Everything below is the decision flow.

## The mental model

Three things have confusingly similar names. Getting them straight prevents most confusion:

- **Agent definition** (what the "Create agent" dialog makes, called a *persona* in the source) is
  a reusable template: name, instructions, harness, model, limits.
- **Instance** is a deployed copy with its own identity and log file. One definition can mint many.
- **Harness** is the actual agent binary Buzz launches. This is the load-bearing choice.

The single most important fact: **Buzz passes at most one MCP server to an agent, and which one
(or none) is a fixed property of the harness.** The field holding it is a single string set from
a per-runtime constant, and the env key that would override it is on Buzz's reserved list, so no
amount of configuration changes it.

Be precise about the layer, because it changes what the workarounds are. The agent runtime itself
can accept several MCP servers; it is the Buzz side that only ever sends zero or one. So "add
another MCP server" is not a setting you missed — it is a different harness, or a custom one.

The corollary people miss: **a harness that receives zero MCP servers from Buzz is not toolless.**
It brings its own tools and reads its own MCP configuration, entirely outside Buzz's control.
That is a feature, but it means Buzz's UI cannot tell you what tools that agent will have.

## Decide in this order

Each decision constrains the next, so going out of order means redoing work.

### 1. Harness — what tools does this agent need?

Start from the tools, not from preference. Ask what the agent must actually do, then read across.

| | Buzz Agent | Claude Code | Codex |
|---|---|---|---|
| MCP server Buzz sends | `buzz-dev-mcp` | **none** | `buzz-dev-mcp` |
| Tools it therefore has | `shell`, `read_file`, `view_image`, `str_replace`, `todo` | its own native tool set only | Codex's own tools **plus** `buzz-dev-mcp` |
| Where extra MCP comes from | nowhere, ever | its own config, outside Buzz | its own config, outside Buzz |
| Skills directory scanned | `.agents/skills` | `.claude/skills` | — |
| `AGENTS.md` loaded by Buzz | yes | no | no |
| Model selectable in Buzz UI | yes | yes | yes |

The rows that decide most cases:

- **Needs any MCP server** (a hosted API, a scraper, a database) → not Buzz Agent. Its tool
  surface is five tools, permanently.
- **Needs only shell-reachable things** (CLIs, curl-able APIs, reading and editing local files) →
  Buzz Agent is genuinely sufficient and is the leanest option.
- **Wants both MCP and Buzz's own file tools** → Codex is the only harness that gets both.

**Verify the MCP question empirically rather than from config files.** For harnesses that load
their own configuration, what a CLI reports and what the agent actually receives can differ —
plugin systems and directory-scoped config are common sources of mismatch. Asking the running
agent to list its tools settles it in one turn and is worth doing every time.

**A CLI is not a missing tool.** Before ruling out Buzz Agent, check whether the capability has a
command-line form. An API you can `curl` and a tool that ships a binary are both fully available
through `shell`. This flips the answer more often than people expect.

Harnesses shown as "(not installed)" are real options — they need installing first, not avoiding.

### 2. Model

Model is pinned per agent and swappable later without rebuilding, so treat it as a dial rather
than a commitment. Some harnesses lock the *provider* while still letting you choose the model
within it — do not assume a locked provider means a fixed model.

Two things worth weighing:

- **Context size**, if the agent's work involves large tool responses. Search and scraping tools
  routinely return tens of KB per call, and a bigger context window removes the need to summarize
  between every step.
- **Judgment vs lookup.** Agents whose failures would be reasoning errors (choosing wrongly
  between options, missing something present in the data) benefit from a stronger model. Agents
  doing retrieval and formatting usually do not.

Also check what pool the model draws from. A harness backed by a subscription and one backed by
metered API can cost very differently for identical work.

### 3. Instructions

Instructions become the system prompt. Buzz wraps them as `[Workspace]`, `[Base]`, then
`[System]` with your text last. Two consequences shape how you write them:

**Buzz tells the agent to stay in its working directory.** The injected `[Workspace]` section
says the agent's directory is the nest (`~/.buzz`) and that it should not search elsewhere. If
your agent needs files outside the nest, **say so explicitly and give absolute paths**, otherwise
that instruction quietly wins and the agent reports it cannot find things that are right there.

Whether an absolute path then works depends on the harness, and this is worth getting right
because the two failures look identical from chat:

- **Buzz's own file tools enforce no containment at all.** Paths resolve anywhere on the
  filesystem by design. So for those harnesses this is purely a prompting problem.
- **Harnesses with their own permission model enforce it themselves, and Buzz feeds them
  nothing.** Buzz sends only `cwd` — no directory allowlist of any kind. So a harness that
  restricts file access by directory will restrict it, and you configure that in the harness's
  own settings, not in Buzz.

**There is no import or include syntax.** Everything is inline. This pushes you toward one of two
patterns:

- **Point, don't paste.** Write a short bootstrap that names the files to read, in order, by
  absolute path. Best when the referenced material already exists and is maintained elsewhere —
  it stays in one place and cannot drift into a stale second copy.
- **Inline it.** Best for rules that are short, safety-critical, or must survive the agent
  skipping a read.

Most good instruction blocks do both: inline the handful of things that must never be got wrong,
point at everything else.

A useful structure:

```
Who you are and what you never do.

FIRST ACTION, EVERY SESSION
  - the workspace override, if needed
  - the files to read, in order, by absolute path
  - which file wins on conflicts

THE THINGS YOU MUST NEVER DO
  - the irreversible ones, written out, not referenced

THE OBJECTIVE
  - what "good" means for this agent, in one paragraph

TOOL NOTES
  - per-tool traps: what returns a false success, what is cached, what is a human task

HOW TO REPORT
  - who the reader is and what they want first
```

Explain *why* each constraint exists where you can. An agent that understands the reason handles
the case you did not anticipate; an agent following a bare rule does not.

### 4. Environment and secrets

Agents do not inherit your shell profile. **Any API key the agent needs must be set in the
agent's environment variables field**, or its tools will fail with auth errors that look like
outages.

Some keys are reserved and silently ignored — anything controlling the MCP command or the access
gate. That is deliberate: it stops a saved UI setting and the running process from diverging.
See `references/harnesses.md` for the current reserved list.

Note the refresh difference: **global defaults are re-read when an agent restarts, but per-agent
environment variables are captured when the agent is created.** If you change a per-agent value
and nothing happens, that is why.

### 5. Access control

"Who can send instructions" is a real security boundary, not a preference, because a Buzz agent
is addressable by anyone who knows its identity.

- **Only me** — owner only. Note that if no owner has resolved yet, everything is dropped, which
  can look like the agent is dead when it is working correctly.
- **Anyone** — no filtering. Reasonable for a read-only helper, dangerous for anything that can
  act.
- **Selected people** — an allowlist of hex public keys, with the owner always implicit.

The question to ask is not "is this agent trustworthy" but **"what happens if an instruction
arrives that the owner did not send."** If the agent can only research and report, the blast
radius is small. If it can change state, restrict hard and require an explicit confirmation turn
in the instructions before anything irreversible.

Also worth knowing: the agent reads untrusted content. Anything it fetches or is sent is data,
not instructions, and it helps to say so in the instructions directly.

### 6. Parallelism and names

**Parallelism** is how many agent subprocesses run at once, each a full copy with its own memory
and MCP server. The app default is higher than most people need. Start at 1 or 2 and raise it
only when you observe queuing — the cost scales linearly and idle subprocesses are pure overhead.
A single conversation is never processed by two subprocesses at once, so parallelism buys you
concurrent *channels*, not a faster single answer.

**Instance name pool** is cosmetic. It supplies display names when you deploy multiple copies.
No behavioral effect.

## Defaults that surprise people

These are not in the Create agent dialog, which is exactly why they catch people out. Check them
against what the agent is allowed to do before deploying anything that can change state.

**Per-tool-call approval is off by default.** Buzz sends a permission mode that skips the
approval flow to any harness that supports one. The agent will run tools without asking. For a
research agent that is the right default and saves a lot of friction. For an agent holding a
cloud credential or a deploy token it is the single most consequential setting in the product,
and it is not surfaced in the creation UI at all.

**The runaway limits are off.** Maximum rounds per turn defaults to unlimited, and maximum
sessions is effectively unbounded. The two knobs you would reach for to bound a misbehaving agent
are both open unless you set them.

**A second message can cancel the first.** The default multi-message behavior steers the running
turn toward the new input. Depending on what the harness supports, that is either a graceful
injection or a cancel-and-restart. On a shared agent this means one person can interrupt
another's in-flight work — including a half-finished state change. Worth designing around rather
than discovering.

**The nest is shared, not per-agent.** Every agent on the host runs in the same working
directory, writes into the same subdirectories, and sees the same skills. There is no per-agent
isolation and no per-agent skill picker. Two consequences: agents can read each other's working
files, and a skill added for one agent costs prompt space for all of them. If you need real
separation, that is a host or container boundary, not a Buzz setting.

## Verify before declaring it done

Creating the agent is not the same as it working. Three checks catch nearly everything, and they
are worth running in this order because each one's failure explains the next.

1. **"List every tool you have."** This is the ground truth for the harness decision. It tells
   you whether MCP servers actually loaded, which is frequently different from what the config
   files imply. Run this even when you are confident.
2. **"Read <a specific file> and tell me what it says."** Confirms the workspace override took
   and the agent can reach its material.
3. **A real task, end to end.** Confirms secrets are present and tools authenticate.

When check 2 fails on macOS, suspect the OS permission layer before suspecting your config.
Reading `~/Documents`, `~/Desktop` or `~/Downloads` from an app- or launchd-spawned process
requires a one-time Files and Folders consent that a background process cannot prompt for. Agent
logs live under the Buzz app-data directory and will show the real error.

## Common failure modes

| Symptom | Usual cause |
|---|---|
| "I can't find that file" for a file that exists | The `[Workspace]` instruction won. Add the absolute path and an explicit override. |
| A tool you configured is absent | Wrong harness. MCP servers cannot be added to every harness. Run check 1. |
| Auth errors that look like an outage | The key is in your shell profile, not the agent's environment. |
| Agent ignores everyone including you | Access gate set to owner-only with no owner resolved yet. |
| Changed an env var, nothing happened | Per-agent env is snapshotted at creation. Recreate, or move it to global defaults. |
| Instructions seem partly ignored | Too long and too uniform. Inline the critical few, point at the rest. |

## When you are asked to write the instructions

Draft them, then read them back asking: *if I were an agent that had only this text and no other
context, what would I get wrong?* The gaps are almost always one of — no absolute paths, no
statement of which source wins on conflict, no named irreversible actions, and no description of
who the reader is. Fix those four and the rest tends to work.
