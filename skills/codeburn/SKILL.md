---
name: codeburn
description: |
  Track, analyze, and optimize Claude token usage and costs using CodeBurn. Use this
  skill whenever Clark asks about token usage, AI spending, session costs, what things
  have cost, how much he's spent, optimization recommendations, or wants to run any
  CodeBurn command. Also trigger when Clark says things like "how are my limits",
  "am I burning through tokens", "what's eating my context", "optimize my setup",
  "check my usage", "codeburn", or "how much have I used this week/month". This skill
  installs CodeBurn if it's not already present, then runs the appropriate command and
  interprets the results.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
---

# CodeBurn: Token Usage Tracking and Optimization

CodeBurn reads Claude Code and Claude Desktop session data directly from disk — no proxy, no wrapper — and gives Clark a clear picture of where his tokens and budget are going. It also scans his setup for waste and provides copy-paste fixes.

## Step 1: Ensure CodeBurn is installed

Before running any command, check if codeburn is available:

```bash
which codeburn
```

If not found, install it:

```bash
npm install -g codeburn
```

Confirm installation succeeded before proceeding.

## Step 2: Determine what Clark wants

Based on the conversation, pick the right command:

| Clark's intent | Command to run |
|---|---|
| General usage overview / "what have I spent" | `codeburn report --provider claude` |
| Today's usage | `codeburn today --provider claude` |
| This month | `codeburn month --provider claude` |
| Last 7 days | `codeburn report -p 7days --provider claude` |
| Find waste / optimize | `codeburn optimize --provider claude` |
| Compare models | `codeburn compare --provider claude` |
| Quick one-liner status | `codeburn status --provider claude` |
| Yield (productive vs abandoned sessions) | `codeburn yield --provider claude` |
| Set plan tracking | `codeburn plan set claude-max` |

If unclear, default to `codeburn report --provider claude` for a full 7-day overview.

## Step 3: Run the command and capture output

Run the command via bash and capture stdout. Example:

```bash
codeburn report --provider claude --format json
```

Use `--format json` for programmatic parsing when you need to pull specific numbers. Use the plain output for display when the user just wants to see results.

## Step 4: Interpret and present findings

Don't just dump raw output. Surface what matters:

- **Total spend** this period and how it compares to Clark's Max plan ($200/month)
- **Top cost drivers** by project, model, or task type
- **One-shot rate** — what percentage of edits the model got right first try
- **Cache hit rate** — whether prompt caching is working well
- **Biggest single sessions** — which sessions burned the most

For the **optimize** command specifically:
- List each finding with its estimated dollar/token savings
- Pull out the copy-paste fix for each one and show it clearly
- Prioritize by urgency (CodeBurn ranks them A-F)
- Flag bloated CLAUDE.md or MEMORY.md files immediately — these cost tokens on every session start and the fix is usually a one-line compress

## Step 5: Give a recommendation

After showing the data, add one concrete next step. Examples:

- "Your biggest waste is [X]. Run this to fix it: [command]"
- "You've used [Y]% of your Max plan equivalent this month — on track / ahead of pace"
- "The optimize scan found [N] issues. The highest-impact one is [X] — here's the fix"

## Notes

- CodeBurn tracks both Claude Code (`~/.claude/projects/`) and Claude Desktop (`~/Library/Application Support/Claude/local-agent-mode-sessions/`) — Clark uses Cowork which writes to the Desktop path, so both will be captured
- The `plan set claude-max` command sets a $200/month baseline for the progress bar — worth doing once if not already configured
- If Clark wants ongoing visibility, suggest running `codeburn status --provider claude` at the start of sessions
- Token counts for Cowork sessions may show as "Claude Desktop" in the provider breakdown
