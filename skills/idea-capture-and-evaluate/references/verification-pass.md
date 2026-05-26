# Verification Pass Discipline

The verification pass is mandatory and non-negotiable. It exists because of a specific failure during the May 15, 2026 session: I scored a reel about Anthropic changing Claude billing on June 15 as "fear-based growth hack" with verdict Hold (22/48). On deeper audit, the billing change turned out to be REAL - confirmed by 6 authoritative sources (VentureBeat, The Register, The New Stack, Zed's blog, The Decoder, KuCoin). The reel was correct; my dismissive scoring was wrong. The verdict moved to Pilot (30/48) only because of the verification pass.

The lesson: first-pass scoring routinely misses material facts. The verification pass catches them.

## When to verify (which claims warrant verification)

Not every claim in source content needs verification. Focus on claims that, if true or false, would materially change the verdict:

**Always verify:**
- Pricing claims ($X/month, "free", "open source", "$X cheaper than alternative")
- Billing or policy changes from named companies
- Performance benchmarks with specific numbers ("3000 tokens/sec", "75% faster", "saves $200")
- Product release dates or future-dated events ("launching June 15", "Q4 2026")
- Adoption claims ("47k stars", "trusted by Amazon/Google/Shopify")
- Vendor announcements or product launches
- Comparative claims with specific numbers vs alternatives
- Security or compliance claims (SOC2, HIPAA, GDPR, etc.)

**Usually skip verification:**
- Subjective design/quality claims ("looks premium", "feels professional")
- Personal experience anecdotes
- Best-practice recommendations without specific numbers
- Pure opinion or framing claims

**Verify if material to verdict:**
- Architecture or capability claims that would change scoring
- "Anthropic recommends X" - verify against Anthropic's actual docs
- "Built on X technology" - quick check the dependency exists

## How to verify

For each claim that needs verification:

1. **Construct a targeted WebSearch query.** Don't search broadly - search for the specific factual claim with disambiguating context.

   Bad: `"Anthropic billing"`  
   Good: `"Anthropic Claude billing change agent SDK third party tools June 15 2026"`

2. **Use the WebSearch tool** (loaded via ToolSearch if needed).

3. **Evaluate the search results:**
   - **Multiple authoritative sources agree:** claim verified TRUE
   - **No mentions or contradictory mentions:** claim VERIFIED FALSE or UNVERIFIABLE
   - **Single source, unfamiliar publisher:** UNVERIFIED - note the limitation
   - **Source is the same content creator:** doesn't count as independent verification
   - **Sources confirm the claim BUT note partial walkbacks, exceptions, or evolution:** claim verified TRUE WITH CAVEAT - capture the walkback explicitly

Watch for policy changes that get announced then partially reversed. A real example from May 2026: the Anthropic June 15 billing change was confirmed as REAL by 6 sources, but VentureBeat also reported Anthropic had partially walked back the announcement under user backlash. A skill that captures only "claim verified TRUE" misses that the situation is fluid. Document the walkback in the rationale and Sources Cited.

4. **For "Anthropic says X" claims, verify against Anthropic's actual material:**
   - Try `https://platform.claude.com/docs/...`
   - Try `https://anthropic.com/news`
   - Try the `anthropics/claude-code` GitHub repo (has plugin docs)
   - Use Apify rag-web-browser to fetch since `mcp__workspace__web_fetch` is provenance-restricted

5. **For GitHub repos, verify maturity claims:**
   - Star count via `mcp__github__search_repositories`
   - Last update via the same call
   - Recent commits via `mcp__github__list_commits`

## How to update scores after verification

**If claim verified TRUE:**
- If the claim materially supports a HIGHER score on any column, recalculate that column
- Update verdict rationale with verification finding + source URLs
- Add verification URLs to Sources Cited field

**If claim verified FALSE:**
- DOWNGRADE the relevant column scores
- Note in verdict rationale: "Source claim X verified FALSE via [source]"
- The verdict might shift tier (e.g., Pilot -> Hold) - that's the point

**If claim UNVERIFIABLE:**
- Don't change scores
- Note in verdict rationale: "Source claim X could not be verified - score reflects first-pass assessment with caveat"
- Add note to Sources Cited: "Verification attempted, no confirmation found"

## Documenting verification

Every Notion row's Sources Cited field should include verification attempts. Format:

```
Source URL: https://www.instagram.com/reels/...
Verification attempts:
- Claim: "Anthropic billing change June 15"
  Verified TRUE via:
  - https://venturebeat.com/...
  - https://www.theregister.com/...
  - https://zed.dev/blog/...
- Claim: "GPT 5.5 covers everything else for pennies"
  UNVERIFIED - no specific GPT 5.5 announcement found
```

This creates an audit trail. If verdicts get challenged later, the verification record is right there.

## Anti-patterns

**Don't:**
- Skip verification because the source "looks promotional" - my May 15 lesson was exactly this mistake
- Skip verification because the content creator "seems credible" - independent verification still required
- Trust a single source as verification (need 2+ independent sources for important claims)
- Use the source content itself as verification (circular)
- Use the content creator's other content as verification (not independent)
- Verify only the claims that support your initial score (confirmation bias - verify both supportive and contradicting claims)

**Do:**
- Verify claims that would change verdict in EITHER direction
- Use diverse sources (different publishers, different perspectives)
- Note when verification is mid-conviction (e.g., "2 sources confirm, 1 source disputes")
- Treat the verification pass as a peer review of yourself

## Cost of verification

WebSearch costs nothing per query. The cost is:
- Time/latency (each search adds a few seconds)
- Context tokens (search results consume context budget)
- Apify rag-web-browser if fetching docs directly: ~$0.005/page

For a typical item with 1-3 verifiable claims, verification adds 10-30 seconds and minimal cost. Worth it.

## When to escalate beyond WebSearch

For high-stakes verdict decisions (e.g., Adopt-tier items being considered for actual deployment):

- Fetch the canonical source document directly (e.g., for Mariah's Opus 4.7 reel claim, fetched Anthropic's actual `claude-opus-4-5-migration/prompt-snippets.md`)
- Check GitHub for verification (commit history, issue discussions, README claims)
- Look for community independent reviews

The May 15 lesson here: Mariah's reel claimed "Opus 4.7" but Anthropic's official doc is for "Opus 4.5". Direct source-checking caught the version-number error that WebSearch alone might have missed.
