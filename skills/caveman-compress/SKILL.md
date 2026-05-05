---
name: caveman-compress
description: |
  Compress memory and context files to cut input token usage, and optionally enable
  terse output mode to reduce response length. Trigger when Clark says "compress
  MEMORY.md", "compress my memory files", "shrink my context", "reduce tokens",
  "caveman mode", "terse mode", "less tokens", "compress my CLAUDE.md", "compress
  context files", or anything about making memory files smaller or AI responses
  shorter. This skill has two modes: (1) FILE COMPRESSION — rewrites MEMORY.md,
  CLAUDE.md, and similar files into compressed prose that preserves all meaning but
  cuts ~40-50% of input tokens loaded every session; (2) OUTPUT COMPRESSION — makes
  Claude's own responses shorter and more direct for the rest of the session.
  Always ask which mode Clark wants if it's not clear from context.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Bash
---

# Caveman Compress: Token Reduction for Memory Files and Responses

Two distinct modes. Understand which one Clark is asking for before doing anything.

---

## Mode 1: File Compression (compress MEMORY.md / CLAUDE.md / context files)

This cuts the input tokens loaded at the start of every session — a one-time investment that compounds across every future conversation. Average reduction: 40-50% of file size.

### Which files to compress

Common targets:
- `MEMORY.md` — session memory, project notes, personal preferences
- `CLAUDE.md` — project instructions, codebase context
- Any markdown file Clark uses as persistent context

If Clark doesn't specify a file, ask which one. Don't compress files blindly.

### The compression algorithm

Read the file carefully. Then rewrite it with these rules:

**Remove without losing meaning:**
- Filler phrases ("As a reminder...", "Please note that...", "It's important to...")
- Redundant context ("As we discussed...", "Given what we've established...")
- Verbose transitions ("In order to...", "Due to the fact that...")
- Politeness scaffolding ("Feel free to...", "Don't hesitate to...")
- Restated conclusions that duplicate earlier content

**Shorten without losing precision:**
- Convert long prose explanations of simple facts to direct statements
- Collapse multi-sentence rules into single imperative sentences
- Replace example lists where one clear example suffices

**Preserve byte-for-byte:**
- All code blocks, commands, and shell snippets
- All URLs and file paths
- All proper nouns, names, and identifiers
- All specific numbers, dates, and measurements
- All technical terms and tool names

**Never compress:**
- Content that is already terse and specific
- Rules where the exact wording matters (voice rules, formatting rules)
- Anything Clark has marked as important

### How to do it

1. Read the target file in full
2. Save a backup: copy it to `<filename>.backup.md` before making any changes
3. Write the compressed version — aim for 40-50% reduction in word count
4. Show Clark a brief summary: original word count → compressed word count, % saved
5. Ask for confirmation before saving, or save and note where the backup lives

### Example

**Before (28 words):**
> As a reminder, it's important to note that when drafting emails on Clark's behalf, you should always use "Hey [Name] -" as the salutation format. Please do not use "Hi" or "Hello".

**After (11 words):**
> Email salutation: always "Hey [Name] -". Never "Hi" or "Hello".

Same information. 61% fewer words. Nothing lost.

---

## Mode 2: Output Compression (terse response mode)

This makes Claude's own responses shorter for the rest of the session. Useful when Clark is moving fast and wants quick answers, not explanations.

### Levels

**Lite** — Drop filler, keep full sentences. Good for most work.
> "New object ref each render. Use useMemo."

**Full** — Drop articles and transitional phrases. Fragments OK.
> "New obj ref → re-render. Wrap in useMemo."

**Ultra** — Maximum compression. Telegraphic.
> "Inline obj prop → new ref → re-render. useMemo."

Default to **Lite** unless Clark specifies otherwise.

### What to compress in output

- Opening acknowledgments ("Sure!", "Happy to help with that")
- Transitional summaries that restate what was just said
- Hedging language ("It's worth noting that...", "Generally speaking...")
- Closing offers ("Let me know if you need anything else")
- Explaining reasoning when Clark just wants the answer

### What to preserve in output

- Technical accuracy — never sacrifice correctness for brevity
- Code blocks — always show the full code
- Warnings about irreversible actions
- Direct answers to direct questions

### Activating / deactivating

When Clark asks for terse/caveman mode: confirm the level and apply it for the rest of the session.

When Clark asks to stop: return to normal response style immediately.

---

## If Clark asks for both

Compress the files first (one-time win), then activate output compression for the session. Tell Clark both are active and what to expect.
