# Buzz harness capability matrix and config reference

Verified against `block/buzz` @ `8342dfcc` (2026-08-04) on macOS. Buzz moves quickly — when a
detail here contradicts what you observe, trust the observation and update this file.

## Contents

- [Why the harness decides capability](#why-the-harness-decides-capability)
- [Harness catalog](#harness-catalog)
- [Tool surfaces](#tool-surfaces)
- [Working directory and file access](#working-directory-and-file-access)
- [System prompt assembly](#system-prompt-assembly)
- [Skills](#skills)
- [Access control](#access-control)
- [Reserved environment keys](#reserved-environment-keys)
- [Config precedence](#config-precedence)
- [File locations on macOS](#file-locations-on-macos)
- [Hard limits](#hard-limits)

## Why the harness decides capability

The harness dropdown selects which ACP agent binary `buzz-acp` spawns over stdio. Each entry in
the runtime catalog carries a fixed `mcp_command`. `build_mcp_servers()` returns either an empty
list or a **single-element** list built from that command. There is no code path that produces
two MCP servers for one harness.

Consequence: an agent's tools are the harness's built-in tools, plus at most one MCP server that
the harness itself specifies. You cannot bolt an extra MCP server onto an arbitrary harness from
the Buzz UI.

## Harness catalog

| Harness | `mcp_command` | Own config file | Own MCP config | Skills dir |
|---|---|---|---|---|
| **Buzz Agent** | `buzz-dev-mcp` | none (env only) | none | `.agents/skills` |
| **Claude Code** | none | `~/.claude/settings.json` | `~/.claude.json` → `mcpServers` | `.claude/skills` |
| **Codex** | `buzz-dev-mcp` | `~/.codex/config.toml` | `[mcp_servers.<id>]` | — |
| **Goose** | — | `~/.config/goose/config.yaml` | `extensions` | `.goose/skills` |
| Hermes, OpenCode, Amp | see catalog | varies | varies | varies |

**Codex is the only harness that gets both** its own MCP servers and `buzz-dev-mcp`.

**Buzz Agent supports stdio MCP only** — no HTTP, no SSE. This matters because many hosted MCP
servers are HTTP-only, so even the theoretical workaround does not apply.

### Plugin-provided MCP servers are a separate mechanism

If a CLI reports MCP servers that are not present in that harness's MCP config file, they are
probably coming from a plugin system rather than from `mcpServers`. Whether the ACP wrapper loads
plugins is a property of the wrapper, not of Buzz, and is worth testing empirically rather than
assuming in either direction. The "list every tool you have" check settles it in one turn.

## Tool surfaces

**`buzz-dev-mcp`** provides: `shell`, `read_file`, `view_image`, `str_replace`, `todo`, plus the
lifecycle hook tools `_Stop` and `_PostCompact`.

There is no web tool. `rg`, `tree` and the `buzz` CLI are on `PATH` inside `shell` rather than
being separate tools, so shell-reachable capability is broader than the tool list suggests.

Harnesses with `mcp_command: none` post results back to Buzz through the `buzz` CLI on `PATH`
rather than through MCP.

## Working directory and file access

**There is no per-agent working directory setting, and the nest is SHARED across every agent on
the host.** `nest.rs` describes it as "a shared knowledge directory... so every Buzz-spawned agent
starts with orientation." Every agent is spawned with cwd set to the nest (`~/.buzz`, or
`~/.buzz-dev` on dev builds), falling back to `$HOME`, and that cwd is passed as the session's
`cwd` (`lib.rs:1599`).

There is no worktree-per-agent and no per-agent subdirectory. Two agents write the same
`WORK_LOGS/`, read the same `RESEARCH/`, and can read each other's working files. If you need
real separation between agents, that is a host or container boundary, not a Buzz setting.

`buzz-acp` also injects a `[Workspace]` prompt section telling the agent that this is its
absolute working directory and that it should not search `$HOME` or other directories. The
stated reason is avoiding macOS permission prompts from stray home-directory scans.

**There is no filesystem containment.** The path resolver's own module documentation states that
a resolved path may land anywhere on the filesystem, and there is a test asserting that paths
outside the workspace resolve successfully. Absolute paths are used as-is; relative paths resolve
against the working directory.

So reaching a folder outside the nest is a *prompting* problem, not a permissions problem. Three
options, in order of preference:

1. **Absolute paths in the instructions**, with an explicit note overriding the workspace
   section. Simplest and has no side effects.
2. **The Repos Directory setting** (per workspace, not per agent), which symlinks `~/.buzz/REPOS`
   at a directory you choose. It refuses to replace a non-empty real `REPOS` directory.
3. **Symlink into the nest yourself.**

## System prompt assembly

The instructions field is stored as `system_prompt` on the agent definition, delivered to the
process as `BUZZ_ACP_SYSTEM_PROMPT`, and assembled as:

```
[Workspace]   <- Buzz-injected: cwd, stay-here instruction
[Base]        <- Buzz-injected: platform basics
[System]      <- your instructions, last
```

Yours comes last, which is why an explicit override of the workspace instruction works.

**No import or include syntax.** Everything is inline. Buzz Agent enforces a 512 KiB ceiling;
other harnesses enforce whatever their own limits are.

Two out-of-band mechanisms exist for Buzz Agent specifically:

- **`AGENTS.md`** (not `CLAUDE.md`) is loaded from `~/AGENTS.md` and from each directory between
  the git root and cwd, capped at 128 KiB total. `~/.buzz/AGENTS.md` is the practical hook. Buzz
  regenerates only the region between its managed markers, so text outside those markers
  survives.
- **Skills**, below.

## Skills

Buzz Agent scans, relative to cwd: `.agents/skills`, `.goose/skills`, `.claude/skills`, plus
`~/.agents/skills` globally.

Each immediate subdirectory needs a `SKILL.md` with YAML frontmatter containing `name` and
`description` — the same format Claude uses, so skills port between them. Name and description go
into the system prompt; the body is loaded on demand and capped at 32 KiB. On a name collision
the first wins, scanning in sorted order.

**Attachment is by directory placement.** There is no per-agent skill picker — every agent on
that host running a harness that scans a given directory sees every skill in it. Plan for that:
skills that only make sense for one agent still cost prompt space for all of them.

## Access control

Three modes are exposed, mapping to `--respond-to`:

| UI label | Value | Behavior |
|---|---|---|
| Only me (default) | `owner-only` | Only the registered owner. **If no owner has resolved, everything is dropped.** |
| Anyone | `anyone` | No author filtering. UI shows a persistent warning. |
| Selected people | `allowlist` | Listed keys plus the owner, who is always implicit. |

A fourth mode, `nobody` (heartbeat only), exists in the backend but is deliberately not exposed.

Allowlist entries are 64-character lowercase hex public keys. The field does not decode `npub`
form — convert first.

Owner control commands (`!shutdown`, `!cancel`, `!rotate`) are evaluated *before* the gate, so
they work regardless of the mode.

## Reserved environment keys

These cannot be overridden by user, persona, or global environment variables. The reason is that
they control code execution and the access gate, and allowing an env override would let the
running process diverge from the saved UI setting:

- `BUZZ_ACP_MCP_COMMAND`
- `BUZZ_ACP_RESPOND_TO`
- `BUZZ_ACP_RESPOND_TO_ALLOWLIST`

If you set one of these and nothing changes, that is why. It is not a bug.

## Config precedence

```
baked build env  <  GLOBAL  <  definition (linked) / instance (legacy)  <  Buzz identity
```

"Use agent defaults" reads the global record. "Customize for this agent" pins values at the
definition level.

**Refresh behavior differs and this trips people up:** global config is live-resolved at spawn,
so editing it takes effect on the next agent restart. Per-agent environment variables are
snapshotted when the agent is created, so changing one requires recreating the agent — or moving
the value to global defaults instead.

### Buzz Agent model tuning env vars

The "BUZZ-AGENT MODEL TUNING" section is structured UI over four env vars. They apply to the Buzz
Agent harness only:

| Field | Env var | Default |
|---|---|---|
| Thinking / Effort | `BUZZ_AGENT_THINKING_EFFORT` | inherit |
| Max rounds | `BUZZ_AGENT_MAX_ROUNDS` | 0 = unlimited |
| Max output tokens | `BUZZ_AGENT_MAX_OUTPUT_TOKENS` | 32768 |
| Context limit | `BUZZ_AGENT_MAX_CONTEXT_TOKENS` | 200000 |

Model and provider for Buzz Agent come from `BUZZ_AGENT_MODEL` and `BUZZ_AGENT_PROVIDER`.

## File locations on macOS

App-data root: `~/Library/Application Support/xyz.block.buzz.app` (dev builds append `.dev`).

| What | Path |
|---|---|
| Agent definitions and instances | `<app-data>/agents/managed-agents.json` (mode `0600`) |
| Global agent defaults | `<app-data>/agents/global-agent-config.json` (mode `0600`) |
| Teams | `<app-data>/agents/teams.json` |
| Custom harnesses | `<app-data>/custom_harnesses/<id>.json` |
| **Agent logs** | `<app-data>/agents/logs/<pubkey>.log` |
| Harness install logs | `<app-data>/agents/logs/install-<runtime_id>.log` |
| **The nest** | `~/.buzz/` — `AGENTS.md`, `GUIDES/`, `RESEARCH/`, `PLANS/`, `WORK_LOGS/`, `OUTBOX/`, `REPOS/`, `.scratch/`, `.agents/skills/` (mode `0700`) |
| Per-channel harness config | `~/.buzz/buzz-acp.toml` |
| Agent private keys | OS keyring, keyed `agent:<pubkey>` |
| Bundled CLI symlink | `~/.local/bin/buzz` |

Agent logs are the first place to look for any runtime failure. They show the actual `session/new`
payload, which is how you confirm what MCP servers and cwd the agent really received.

## Hard limits and defaults

Enforced by the Buzz Agent runtime (`crates/buzz-agent`), not by `buzz-acp`:

| Limit | Value | Source |
|---|---|---|
| MCP servers per session | 16 | `mcp.rs:26` |
| Tools per session | 128 | `mcp.rs:22` |
| Tool calls per turn | 64 | `config.rs:652` |
| Skill body read | 32 KiB | `hints.rs:7` |
| Hints (`AGENTS.md`) total | 128 KiB | `hints.rs:6` |
| System prompt | 512 KiB | `config.rs:641` |
| **Rounds per turn** | **0 = unlimited** | `BUZZ_AGENT_MAX_ROUNDS`, `config.rs:841` |
| **Sessions** | **effectively unbounded** | `BUZZ_AGENT_MAX_SESSIONS`, `config.rs:852` |

Note the last two. The two limits a user would reach for to bound a runaway agent are both open
by default.

Parallelism range is 1–32.

## Defaults that are not in the creation UI

### Permission mode — `bypassPermissions`

`--permission-mode` / `BUZZ_ACP_PERMISSION_MODE`, declared `default_value = "bypass-permissions"`
at `crates/buzz-acp/src/config.rs:436-444`; wire value `bypassPermissions` (`config.rs:141-151`).
Delivered as `session/set_config_option` with `configId: "mode"` (`pool.rs:1157-1164`).

It is sent only when the mode is not `Default` **and** the agent advertised support for the
option in its `session/new` response (`pool.rs:1021-1024`) — an unrecognized value crashes some
harnesses.

**This skips the per-tool-call approval flow.** It is the highest-consequence default for any
agent holding credentials, and it appears nowhere in the Create agent dialog.

### Multiple-event handling — `steer`

`--multiple-event-handling` defaults to `steer` (`config.rs:353-359`), and requires the dedup
mode to be `queue` (also default) or validation rejects the config (`config.rs:657-670`).

The behavior forks. `buzz-acp` first tries a **non-cancelling native steer** that injects the new
message into the live turn (`lib.rs:2300-2328` → `try_native_steer()`), gated on the harness
advertising `_meta.steering.supported`. **Only if that is unsupported or rejected** does it fall
back to cancel-and-merge, which fires `session/cancel` and re-dispatches a merged prompt.

So whether a second message cancels the in-flight turn depends on the harness. Either way the
mid-turn signal fires for **anyone the inbound gate admits** — owner, allowlist, and siblings
(`lib.rs:2291-2294`) — so on a shared agent one admitted party can steer another's running turn.

### No directory allowlist is ever sent

`additionalDirectories`, `--add-dir`, `add_dir` return zero matches repo-wide. `session_new_full`
(`acp.rs:638-663`) sends only `cwd`, `mcpServers`, optionally a system prompt, and optionally a
session title. A harness with its own directory permission model therefore applies it with no
input from Buzz, and must be configured in that harness's own settings.

### Source defect worth knowing

`crates/buzz-dev-mcp/src/lib.rs:65` — the `view_image` tool description tells the agent that
relative paths "may not escape" the working directory. The test at `view_image.rs:804-822` proves
they can, and is explicitly written to pin that as intended behavior. The agent is handed a false
constraint in its own tool schema, so do not rely on tool descriptions as a security boundary.

## Escape hatch: custom harness

If you need a runtime Buzz does not ship, you can register a custom harness as JSON under
`<app-data>/custom_harnesses/<id>.json` pointing at your own ACP wrapper. This is also the only
way to get a Buzz-Agent-like runtime with a different MCP server. See the `buzz-acp` README
section on bringing your own harness.
