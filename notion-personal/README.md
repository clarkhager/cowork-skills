# notion-personal

A Cowork plugin that adds a second Notion MCP server alongside the built-in Cowork Notion connector. Use this when you have two Notion workspaces (e.g., work + personal) and need Claude to reach both.

## Why this exists

Cowork's built-in Notion connector supports one Notion workspace at a time per Claude account. If you authenticate it against your work Notion, you can't simultaneously use the same connector for your personal Notion. This plugin gives you a second, parallel Notion MCP that can point at your other workspace.

MCP namespacing keeps them separate:

- Built-in Notion connector: `mcp__<uuid>__notion-*`
- This plugin: `mcp__notion-personal__*`

## Setup (do this once per machine)

### 1. Get a Notion Integration Token

The MCP server uses Notion's Internal Integration token (not OAuth).

- Go to https://www.notion.so/profile/integrations
- Click "New integration"
- Name it something like "Claude Cowork - Personal"
- Select your personal Notion workspace as the associated workspace
- Set capabilities: Read content, Update content, Insert content (or whatever scope you want)
- Copy the Internal Integration Secret (starts with `ntn_` or `secret_`)

Then share each Notion page or database you want Claude to reach with this integration:

- Open a Notion page > top right > Add connections > pick "Claude Cowork - Personal"
- For databases, share the database root and all child pages inherit access

### 2. Set the NOTION_TOKEN environment variable

Claude Desktop on macOS doesn't inherit shell env vars by default. Use `launchctl setenv` to set the var so the Claude app sees it on launch:

```bash
launchctl setenv NOTION_TOKEN ntn_your_actual_token_here
```

Verify it stuck:

```bash
launchctl getenv NOTION_TOKEN
```

This persists across reboots on macOS. On Linux / WSL, set it in `~/.profile` or your launcher script instead.

### 3. Install this plugin

From Cowork: Settings > Plugins > add this marketplace (if not already added) > install `notion-personal`.

From Claude Code:

```bash
claude plugin marketplace add clarkhager/cowork-skills
claude plugin install notion-personal@clarkhager-cowork-skills
```

### 4. Restart Claude

Full quit (Cmd+Q on macOS, not just close window) and reopen so the MCP server spawns with the new env var.

### 5. Verify

Ask Claude: "Search my personal Notion for the page titled X." If you see `mcp__notion-personal__*` tool calls succeed, it's working. If the MCP errors with "unauthorized" or "NOTION_TOKEN not set," check `launchctl getenv NOTION_TOKEN` returns your token and restart Claude.

## Why a plugin instead of editing claude_desktop_config.json

This plugin syncs across every machine signed into the same Claude account. The alternative - adding a `notion-personal` block to `~/Library/Application Support/Claude/claude_desktop_config.json` directly - works but requires editing that file on every new machine you set up. The plugin removes that step (you still need to set the NOTION_TOKEN env var per machine, but no config file editing).

## Troubleshooting

**MCP shows "server disconnected" after install.** Most likely the NOTION_TOKEN env var isn't visible to Claude Desktop. macOS GUI apps don't read `~/.zshrc` - you must use `launchctl setenv`. Confirm with `launchctl getenv NOTION_TOKEN` from any terminal, then full-quit and restart Claude.

**"Unauthorized" responses from the MCP.** Either the token is wrong, the integration isn't enabled on the workspace, or the specific Notion pages/databases haven't been shared with the integration (Notion integrations only see content explicitly granted to them).

**Both Notion connectors fire on the same query.** This is the cost of running two: Claude may call the wrong one for a given task. You can disambiguate in the prompt ("check my personal Notion for X" vs "check my work Notion for Y"), or temporarily disable one in Cowork Settings.

## Source

Wraps the official `@notionhq/notion-mcp-server` from Notion - just packaged as a Cowork plugin for cross-machine sync.
