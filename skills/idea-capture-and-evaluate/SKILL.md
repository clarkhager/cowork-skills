---
name: idea-capture-and-evaluate
description: Score URLs against Clark's 12-column weighted rubric and append them to the Ideas Inbox database in Notion. Use this skill whenever Clark pastes one or more URLs in chat - especially with verbs like "evaluate", "score", "capture", "add to inbox", "research", "analyze these links", "run the rubric", "rank these", "deep dive on these", or even a raw URL dump with no explicit instruction (the implicit ask is always evaluate + capture, never ignore). Handles Instagram reels, Instagram carousel posts, GitHub repos, YouTube videos, Google Drive videos and PDFs, X/Twitter posts, Reddit posts, and generic web URLs. Auto-reads MEMORY.md when present to ground Wayfinder Fit scoring. Always runs mandatory verification of external factual claims before final scoring. Writes to the canonical Ideas Inbox database in Notion under the Jadyly Dev Shop page (creates the DB on first run, appends thereafter, skips duplicates with a note).
---

# Idea Capture and Evaluate

Clark constantly finds ideas (tools, repos, reels, articles, videos) that he wants to evaluate and remember. Without a system, they get hopelessly bookmarked or opened in tabs and nothing comes of them. This skill is the system: paste URLs, get them classified, fetched, scored, verified, and persisted into a single canonical Ideas Inbox he can return to.

## When this skill fires

Any time Clark pastes 1+ URLs in chat, regardless of explicit instruction. The default assumption is he wants evaluation. Specific high-confidence triggers:

- "evaluate these URLs" / "score these for me" / "rank these"
- "add to my ideas inbox" / "capture and evaluate"
- "run the rubric on these" / "research and score these" / "deep dive on these links"
- "what should I do with these" / "are any of these worth adopting"
- A raw URL dump with no verb (implicit ask: evaluate + capture)

If you see 1+ URLs and the user hasn't given an unambiguous non-evaluation instruction (e.g., "just open this and read it to me"), fire this skill.

## What this skill does (high level)

1. **Read context** - load MEMORY.md if it exists in the current working directory (grounds Wayfinder Fit scoring)
2. **Identify and classify** - parse URLs from the user's message, classify each by content type
3. **Estimate cost** - sum expected Apify spend across all URLs; warn if > $1, hard-stop if > $5 without confirmation
4. **Fetch content** - per type via the right Apify actor or GitHub MCP; see `references/content-types.md`
5. **First-pass scoring** - score each item against the 12-column weighted rubric; see `references/rubric.md`
6. **Mandatory verification pass** - identify external factual claims, verify via WebSearch, update scores if claims were wrong; see `references/verification-pass.md`
7. **Duplicate check + Notion write** - look up existing rows in Ideas Inbox by Source URL; if found, skip with a note; otherwise append with full rubric + rationale
8. **Synthesize and report** - chat summary of each item with verdict + Notion row link

## Step 1: Read context

Before processing any URLs, check for MEMORY.md in the current working directory.

```
if [ -f ./MEMORY.md ] || [ -f ./bizzabo-academy/MEMORY.md ]; then
  # read relevant slices: active sprint, locked decisions, design discipline, methodology rows
fi
```

Use Grep to pull just the rows likely to inform Wayfinder Fit scoring (search for: "Wayfinder", "TDVR", "v2-elevated", "RFD", "multi-source", "Phase 3", "V1 seed"). Don't read the entire file - it's typically 25k+ tokens.

If MEMORY.md doesn't exist (skill running outside the bizzabo workspace), skip this step. Score Wayfinder Fit as 0 with a note: "Not in Wayfinder context; T2 Wayfinder Fit = 0 by default."

## Step 2: Identify and classify URLs

Extract every URL from the user's message. For each URL, match against these patterns to determine type:

| Pattern | Type |
|---|---|
| `instagram.com/reels/` or `instagram.com/reel/` | IG reel |
| `instagram.com/p/` | IG post (may be carousel) |
| `github.com/{owner}/{repo}` | GitHub repo |
| `youtu.be/` or `youtube.com/watch` | YouTube video |
| `drive.google.com/file/` | Google Drive file (could be video or PDF - detect by trying video-intelligence first) |
| `twitter.com/` or `x.com/` | X/Twitter post |
| `reddit.com/r/` | Reddit post |
| anything else | Generic web URL |

If a URL doesn't match any pattern, treat it as Generic web. Don't fail - fall through gracefully.

## Step 3: Estimate cost

Quick reference (full table in `references/content-types.md`):

- IG reel: ~$0.005
- IG carousel: ~$0.10 + $0.01/slide
- GitHub repo: free (uses GitHub MCP)
- YouTube: ~$0.40-$0.75 (depends on length tier)
- Google Drive video: ~$0.40-$0.75
- Google Drive PDF: free (bash curl + pdf skill)
- Generic web: ~$0.005

Sum across all URLs. Apply guardrails:

- **Estimate < $1**: proceed silently
- **Estimate $1-$5**: report estimate to user in chat before fetching, then proceed
- **Estimate > $5**: report estimate and require explicit user confirmation ("ok", "yes", "proceed") before fetching

## Step 4: Fetch content

See `references/content-types.md` for the full mapping including exact actor names, input schemas, and fallback chains. Brief summary:

| Type | Primary | Fallback |
|---|---|---|
| IG reel | `apple_yang/instagram-transcripts-scraper` | `bulletproof/instagram-transcript-extractor` |
| IG carousel | `hikayatlabs/instagram-post-to-article` | flag for manual review on INTERPRETATION_FAILED |
| GitHub repo | GitHub MCP `get_file_contents` (README + root dir) | chunked Read if README > 25k tokens |
| YouTube | `marielise.dev/video-intelligence` | `akash9078/youtube-transcript-extractor` |
| Google Drive video | `marielise.dev/video-intelligence` (handles Drive URLs) | bash + ffmpeg + local whisper |
| Google Drive PDF | bash `curl https://drive.google.com/uc?export=download&id=$ID` + pdf skill | - |
| Generic web | `apify/rag-web-browser` | `WebFetch` (provenance permitting) |
| X/Twitter | `apify/rag-web-browser` (works for public posts) | search Apify for dedicated actor |
| Reddit | `apify/rag-web-browser` with .json suffix | dedicated actor |

**Critical patterns:**

- Always set `previewOutput: false` on `call-actor` to prevent overflow on `get-actor-run`
- Use `get-actor-output` with `fields` parameter to extract only the data you need (massive token savings)
- Poll `get-actor-run` to check status before fetching output
- If output overflows even with `fields`, save to file (paths returned in tool output) and Read selectively

## Step 5: First-pass scoring

Apply the 12-column weighted rubric to each item. See `references/rubric.md` for full definitions, scoring guidance, and verdict thresholds. Brief summary:

**Tier 1 (Clark's priorities, 2x weight, 0-6 each):** Design Ceiling, Design Floor, Autonomy / 24-7, Cost Optimization

**Tier 2 (standard, 0-3 each):** Replaces/Upgrades, Adds Capability, Maturity Signal, Integration Cost, Jadyly Studios Fit, Wayfinder Fit

**Tier 3 (risk guardrails, 0-3 each, 3 = good):** Drift Risk, Reversibility

**Total range:** 0-48
**Verdict thresholds:** 35+ Adopt / 25-34 Pilot / 15-24 Hold / <15 Pass

Be honest. Don't pad scores to make items look better. Cost Optimization is intentionally hard to score high on (most items don't move compute spend). That's by design.

## Step 6: Mandatory verification pass

Critical lesson from the May 15 session: first-pass scoring missed the Anthropic billing change being real because it was dismissed as "fear-based growth hack." See `references/verification-pass.md` for the full discipline.

Brief version: after first-pass scoring, identify external factual claims in the source content (especially: pricing claims, billing changes, performance benchmarks, vendor announcements, future-dated events, comparative numerical claims). For each material claim, use WebSearch to verify. Update scores if claims were wrong - either direction. Document verification attempts in the row's Sources Cited field with URLs.

If you find no verifiable claims (e.g., a personal story reel), note "no external claims to verify" in the row.

## Step 7: Duplicate check + Notion write

The canonical Ideas Inbox lives at: parent page `3299123d-1fc8-80e0-8c9f-dff5174c208a` (Jadyly Dev Shop).

**First-time setup (only if Ideas Inbox doesn't exist yet):**

1. Use `notion-search` for "Ideas Inbox" under that parent
2. If not found, create it via `notion-create-database` with the schema in `references/notion-schema.sql`
3. Cache the data_source_id for the session

**Duplicate check:**

For each URL about to be written, query the Ideas Inbox for existing rows where Source URL matches. If a match exists:
- Skip the write
- Tell user in chat: "Already in inbox - scored X/48 on [date], verdict [verdict]. Want me to re-evaluate? (paste the URL again with 're-eval' to force)"

**Write the row:**

Use `notion-create-pages` with all 12 rubric columns filled, verdict + rationale, per-Tier-1-column notes, guardrail flags (use JSON array string format: `"[\"DriftRisk\",\"LockIn\"]"` for multiple), source URL, sources cited (with verification URLs), date scored, and the Source-Channel + Research-Session-Tag columns.

## Step 8: Synthesize and report

Output a tight chat summary. Format:

```
Captured N URLs to Ideas Inbox. DB: <link>

- Item 1 title - score/48 - Verdict - one-line rationale - Notion row link
- Item 2 title - score/48 - Verdict - one-line rationale - Notion row link
- ...

Notable:
- [highest scorer] - why
- [anything verified-wrong from claims] - what the source got wrong
- [duplicates skipped] - count and list

Open items:
- [URLs that couldn't be fetched]
- [verification gaps that need manual eyeballs]
```

Don't over-format. Don't list scores in a giant table unless there are 10+ items.

## Edge cases

- **Failed fetch (actor returned 0 items, error, or empty transcript):** flag the item in the chat output as "fetch failed - manual review needed"; still create a Notion row with Status = "Researching" so it's not lost
- **Massive README (>25k tokens):** use chunked Read with offset, or fetch a subset of files (just the README + directory listing); document in Sources Cited that full README wasn't read
- **INTERPRETATION_FAILED on carousels:** the multimodal LLM couldn't extract content; ask Clark to describe the carousel OR offer to use a different Instagram actor (e.g., `futurizerush/instagram-profile-posts-scraper` for raw image URLs)
- **Cost overrun mid-fetch:** if an actor unexpectedly costs more than estimated, stop, report, ask for confirmation before continuing
- **Notion API multi-select validation failures:** the API accepts `"single_value"` for single multi-select option but requires JSON array string `"[\"a\",\"b\"]"` for multiple. Empty string is invalid - omit the field instead.
- **Verification surfaces a fact that changes verdict significantly:** rewrite the verdict rationale to explain the verification finding; don't bury it

## What NOT to do

- Don't score items without reading the source content. If fetch failed, mark as such; don't guess.
- Don't pad scores to push borderline items into a higher verdict tier. Honest 24/Hold > inflated 25/Pilot.
- Don't skip the verification pass even on items that look "obviously" promotional or "obviously" legitimate. The May 15 lesson: I dismissed a "fear-based growth hack" reel that was actually surfacing a real billing change.
- Don't write to Notion before verifying. If verification surfaces a material change, the row should reflect post-verification scores, not first-pass.
- Don't ask permission before fetching unless cost > $1. Clark wants this autonomous.
- Don't write a separate DB per session. Append to the canonical Ideas Inbox.
- Don't read all of MEMORY.md. Grep for the specific terms that inform Wayfinder Fit; reading the full file burns context.

## Reference files

When you need detail beyond what's in this SKILL.md, read these:

- `references/rubric.md` - full 12-column rubric definitions, scoring guidance per column, verdict tier definitions, examples from the May 15 session
- `references/content-types.md` - full URL pattern -> fetch method mapping with exact actor names, input schemas, cost estimates, fallback chains, known failure modes
- `references/verification-pass.md` - which claims warrant verification, how to verify each type, how to update scores after verification
- `references/notion-schema.sql` - exact SQL DDL for creating the Ideas Inbox database

Don't read all of them on every invocation. Read the one you need for the step you're on.

## Voice and writing rules for the chat output

Clark has explicit voice preferences:

- No em dashes - use space-hyphen-space
- No ALL CAPS, no "MUST", no "Absolutely", no "Definitely", no "Great question"
- No "straightforward", "It's worth noting", "It's important to note", "Let's dive in", "Let's break this down"
- No "In terms of"
- Direct and honest tone
- Match length to the task - tight when tight is right
- No filler sentences

Apply to all chat output the skill produces.
