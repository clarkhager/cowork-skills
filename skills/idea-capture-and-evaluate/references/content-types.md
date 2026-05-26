# Content Type -> Fetch Method Mapping

Complete mapping of URL patterns to fetch methods, including exact actor names, input schemas, cost estimates, fallback chains, and known failure modes.

## URL pattern -> type detection

| Pattern | Type | Notes |
|---|---|---|
| `instagram.com/reels/` or `instagram.com/reel/` | `ig_reel` | Single video reel |
| `instagram.com/p/` | `ig_post` | Could be carousel (multi-image) or single image |
| `github.com/{owner}/{repo}` | `github_repo` | Repository |
| `github.com/{owner}/{repo}/blob/` | `github_file` | Single file (treat as web URL or fetch directly) |
| `youtu.be/` or `youtube.com/watch` | `youtube` | Single video |
| `youtube.com/playlist` | `youtube_playlist` | Iterate over videos (out of scope for v1) |
| `drive.google.com/file/d/{ID}/` | `gdrive_file` | Detect actual content type by trying video-intelligence first; if fails, try PDF |
| `drive.google.com/drive/folders/` | `gdrive_folder` | List folder contents first (out of scope for v1) |
| `twitter.com/` or `x.com/` | `x_post` | Single post |
| `reddit.com/r/` | `reddit_post` | Could be link post or text post |
| `*.pdf` | `pdf` | Direct PDF URL |
| anything else | `web` | Generic web URL via rag-web-browser |

## IG Reel

**Actor:** `apple_yang/instagram-transcripts-scraper`

**Input schema:**
```json
{"videoUrl": "https://www.instagram.com/reels/{CODE}/"}
```

**Cost:** ~$0.005 per reel ($0.001 result + ~$0.0035 audio minute, minimum 1 min)

**Returns:** transcript text + timestamped segments + caption + engagement metrics + duration + user info

**Fallback chain:**
1. `apple_yang/instagram-transcripts-scraper` (primary - 100% success rate)
2. `bulletproof/instagram-transcript-extractor` ($0.01, 90.7% success)
3. `sian.agency/instagram-ai-transcript-extractor` ($0.023, includes speaker diarization)

**Known failure modes:**
- Reel with no audio (background music only) returns empty transcript - score from caption only
- Private/restricted reels return errors - flag for manual access

## IG Carousel Post

**Actor:** `hikayatlabs/instagram-post-to-article`

**Input schema:**
```json
{"postUrls": [{"url": "https://www.instagram.com/p/{CODE}/"}], "synthesisTemplate": "article_short", "includeExtracted": true}
```

Note: `postUrls` MUST be array of objects with `url` field, not array of strings.

**Cost:** $0.10 base + $0.01 per slide

**Returns:** longform article synthesis OR error

**Known failure modes:**
- `INTERPRETATION_FAILED` error: multimodal LLM couldn't extract content from visually-dominated carousel. Surface to user as: "Carousel content couldn't be parsed by the multimodal LLM. Please describe what the carousel covers, or paste image URLs directly."

**Fallback:** `futurizerush/instagram-profile-posts-scraper` - returns raw image URLs you can then process with vision separately

## GitHub Repo

**Method:** GitHub MCP `mcp__github__get_file_contents`

**Inputs:** owner, repo, path (`README.md` and `/` for directory)

**Cost:** Free

**Fallback chain:**
1. Get README.md directly
2. If README > 25k tokens (overflow), get root directory listing via path=`/` and read smaller files (CHANGELOG, AGENTS.md, RULES.md, CLAUDE.md)
3. Fall back to `mcp__github__search_repositories` for the repo description if needed
4. Read README in chunks via Read tool with offset (if file was saved to disk by an overflow)

**Additional context to gather:**
- Stars + forks + last update via `search_repositories`
- License (from root directory listing)
- Topics (often shows in search results)

**Scoring tip:** README + stars + last-update are usually enough. Don't read code files unless rubric scoring requires it (e.g., to validate Maturity Signal).

## YouTube Video

**Primary actor:** `marielise.dev/video-intelligence`

**Input schema:**
```json
{"url": "https://youtu.be/{VIDEO_ID}", "includeTranscript": true, "includeSummary": true}
```

**Cost:** $0.40 short (<5 min) / $0.75 medium (5-15 min) / $1.50 standard (15-30 min) / $2.75 long (30-60 min) / $5.50 extended (60-120 min)

**Returns:** transcript + summary + topics + key points + metadata

**Fallback chain:**
1. `marielise.dev/video-intelligence` (rich output)
2. `akash9078/youtube-transcript-extractor` ($0.012, 99.9% success, simpler output)
3. `starvibe/youtube-video-transcript` ($0.005, may overflow on long videos)

**Known failure modes:**
- video-intelligence returned 0 items for a specific YouTube video in May 15 session (cause unknown - possibly age-restricted or regional block). Fallback to akash9078 worked.

## Google Drive Video

**Method:** Same as YouTube - `marielise.dev/video-intelligence` handles Drive URLs directly via yt-dlp under the hood

**Input:**
```json
{"url": "https://drive.google.com/file/d/{ID}/view", "includeTranscript": true, "includeSummary": true}
```

**Cost:** Same tiers as YouTube

**Returns:** Same as YouTube

**Known failure modes:**
- Private Drive files return errors. The link must be set to "Anyone with the link" sharing.

## Google Drive PDF

**Method:** bash + curl + pdf skill

**Steps:**
1. Extract file ID from URL: `https://drive.google.com/file/d/{ID}/view`
2. Construct download URL: `https://drive.google.com/uc?export=download&id={ID}`
3. Download via bash: `curl -sL "{URL}" -o /tmp/file.pdf`
4. Detect actual file type with `file` command (Drive files don't have correct extensions in URLs)
5. If actually a video (MP4 etc.), fall through to Google Drive Video flow
6. If actually a PDF, use the pdf skill to extract text

**Cost:** Free (just bandwidth)

**Known failure modes:**
- Files named .pdf may actually be MP4 videos (May 15 session lesson - both BMAD "PDFs" were MP4 files). Always check file type after download.

## X/Twitter Post

**Method:** `apify/rag-web-browser` works for public posts

**Input:**
```json
{"query": "{TWEET_URL}", "maxResults": 1}
```

**Cost:** ~$0.005

**Returns:** rendered markdown of the post page

**Fallback:** search Apify Store for dedicated X actor if needed (`apify/twitter-scraper` family)

## Reddit Post

**Method:** `apify/rag-web-browser` with .json suffix

**Input:**
```json
{"query": "{REDDIT_URL}.json", "maxResults": 1}
```

**Cost:** ~$0.005

**Returns:** post content + top comments

## Generic Web URL

**Method:** `apify/rag-web-browser`

**Input:**
```json
{"query": "{URL}", "maxResults": 1}
```

**Cost:** ~$0.005

**Returns:** rendered markdown

**Fallback:** `mcp__workspace__web_fetch` - but only works for URLs already in the provenance set (user message OR prior web_fetch result). Apify rag-web-browser doesn't have this restriction.

## Cost guardrail summary

For a typical mixed batch (5 URLs, mix of reels/repos/articles):

- 2 IG reels: $0.01
- 2 GitHub repos: $0
- 1 YouTube short: $0.40
- **Total: ~$0.41**

For an expensive batch (10 URLs all long videos):

- 10 YouTube medium videos: $7.50

Apply the guardrails per SKILL.md Step 3:
- < $1: silent
- $1-$5: report, proceed
- > $5: require explicit confirmation

## Apify call discipline

Critical patterns to avoid overflow:

1. **Always set `previewOutput: false` on `call-actor`** when the actor returns large outputs (transcripts, READMEs)
2. **Use `get-actor-output` with `fields` parameter** to extract only needed fields:
   ```
   fields: "transcript.text,metadata.title,metadata.duration,summary.brief"
   ```
3. **Poll `get-actor-run` for status** before fetching output
4. **If output still overflows**, the tool returns a file path - use Read with `offset` and `limit` to chunk through it
5. **Save the dataset ID** from `get-actor-run` response - needed for `get-actor-output`

## Concurrent runs

Multiple Apify actors can run in parallel. Each `call-actor` returns a `runId` immediately; the actual work runs server-side. Pattern:

1. Fire all actors in a single message (multiple tool calls)
2. Poll each `runId` via `get-actor-run` after a brief delay
3. Once all SUCCEEDED, fetch outputs with `fields` selection

This is much faster than sequential fetching for batches of 5+ URLs.
