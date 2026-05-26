# The 12-Column Weighted Rubric

This rubric was developed during the May 15, 2026 research session evaluating 27 tools/repos/videos for fit with Jadyly Dev Studios and Wayfinder. It encodes Clark's stated priorities and methodology lessons.

## Scoring philosophy

- **Score honestly.** Don't pad scores to make items look better. A 24/Hold that's honest is more valuable than an inflated 25/Pilot.
- **N/A is OK.** Some columns won't apply to some content types (e.g., Wayfinder Fit doesn't meaningfully apply to a recipe blog post). Score 0 with a rationale note.
- **Cost Optimization is intentionally hard to score high on.** Most items don't move compute spend. That's by design - we want this column to flag genuine cost wins.
- **Drift Risk and Reversibility are inverted from intuition.** 3 = good (no drift / fully reversible). 0 = bad (high drift risk / sticky).

## Tier 1 - Clark's stated priorities (2x weight, 0-6 each)

These four columns matter most. They're weighted double because Clark explicitly prioritized them when designing the rubric.

### T1 Design Ceiling (0-6)

How much does this item raise the best output the harness can produce?

- **0** - No design contribution at all
- **2** - Modest ceiling lift in specific contexts
- **4** - Meaningful ceiling lift (new capabilities, better quality)
- **6** - Maximum ceiling lift - rivals professional studio output

Examples from May 15 session:
- open-design (71 design systems, multi-format output): 6
- 21st.dev + Mobbin MCPs reel (curated design references): 4
- BMAD method: 2 (process-driven, not design)
- hamelsmu/hamel (utility CLIs): 1

### T1 Design Floor (0-6)

How much does this item raise the WORST output the harness can ship unsupervised?

- **0** - No floor enforcement
- **2** - Modest floor lift when used correctly
- **4** - Real floor enforcement (catches mud-balls, enforces standards)
- **6** - Maximum floor lift - every output passes through quality gates

Examples:
- addyosmani/agent-skills (5 review skills + doubt-driven-development): 5
- claude-review-loop (auto-runs UX review on every UI change): 5
- BMAD (QA agent + Test Architect + Architect coding standards): 4
- Reel: Anthropic Opus 4.7 prompting playbook (removes anti-patterns from every prompt): 3

### T1 Autonomy / 24-7 (0-6)

Can this item be composed into round-the-clock loops without human supervision?

- **0** - Manual workflow only, requires human in the loop
- **2** - Composable but invocation-based (you trigger it)
- **4** - Sequential lifecycle commands chain into background workflows
- **6** - Lives independently, schedules itself, runs unattended on a server

Examples:
- ruflo (autopilot + 12 background workers + GOAP planner): 6
- hermes-agent (lives on $5 VPS, cron scheduler, autonomous skill creation): 6
- mattganzak reel (overnight agent finds 1000 B2B leads): 5
- addyosmani 7-command lifecycle: 4
- hamelsmu CLI tools (composable into pipelines): 3
- ItsHover icons (static assets, no autonomy): 1

### T1 Cost Optimization (0-6)

Does this item reduce compute/API spend? Compute spend dominates the score.

- **0** - Does not move compute spend
- **2** - Modest savings via better routing or cheaper alternatives
- **4** - Direct compute optimization (token reduction, model tiering, local inference)
- **6** - Massive cost win (orders of magnitude cheaper than alternative)

Examples:
- mattpocock /caveman (75% token reduction): 4
- hermes-agent (multi-provider routing + $5 VPS + Ollama): 4
- mattganzak reel (Ollama+Haiku+Sonnet tiering: $6 vs $250): 5
- nicholas.puru reel (multi-provider routing post-Anthropic-billing-change): 5
- ItsHover (free open source, no compute cost): 3
- addyosmani agent-skills (no explicit cost optimization): 2
- claude-review-loop (NEGATIVE on compute, 4 parallel Codex calls): 1

## Tier 2 - Standard weight (1x, 0-3 each)

### T2 Replaces / Upgrades (0-3)

Does this replace or upgrade something we use today?

- 0 = redundant with existing stack
- 1 = partial overlap, marginal upgrade
- 2 = replaces existing pattern with better one
- 3 = direct upgrade with clear switching path

### T2 Adds Capability (0-3)

Does this add capability we don't currently have?

- 0 = nothing new
- 1 = minor new capability
- 2 = real new capability
- 3 = unlocks a new operating mode

### T2 Maturity Signal (0-3)

Production-grade evidence?

- 0 = vibes only, single author, no users
- 1 = early-stage, small community
- 2 = moderate maturity (active dev, modest adoption)
- 3 = production-grade, evidence at scale (10k+ stars, big company backing, battle-tested)

### T2 Integration Cost (0-3)

How hard to integrate?

- 0 = high friction, vendor lock-in, heavy retooling
- 1 = significant integration work
- 2 = moderate (one command + config)
- 3 = drop-in (npx, brew, single plugin install)

### T2 Jadyly Studios Fit (0-3)

Improves the harness for any product the studio ever ships?

- 0 = orthogonal to studio work
- 1 = niche application
- 2 = useful in some studio contexts
- 3 = direct harness upgrade for everything the studio ships

### T2 Wayfinder Fit (0-3)

Directly accelerates current Phase 3 / V1 seed skill / TDVR / brand kit work?

- 0 = unrelated to Wayfinder
- 1 = tangential
- 2 = useful for some Wayfinder workstreams
- 3 = directly accelerates a known Wayfinder gap

**Note:** Wayfinder Fit requires MEMORY.md context. If MEMORY.md doesn't exist (skill running outside bizzabo workspace), score 0 with a note: "Not in Wayfinder context."

## Tier 3 - Risk guardrails (1x, 0-3 each, INVERTED - 3 = good)

### T3 Drift Risk (0-3, 3 = good)

Does this conflict with locked methodology (RFD + multi-source-validation + session-close protocols)?

- **0** = high drift risk - parallel methodology that would conflict
- **1** = some drift potential
- **2** = manageable drift, can selectively absorb
- **3** = no conflict, additive to existing methodology

Examples:
- BMAD (parallel agent topology vs RFD): 1
- GSD (parallel methodology vs RFD + BMAD): 1
- mattpocock skills (atomic and cherry-pickable): 2
- addyosmani agent-skills (aligns with Google practices that overlap RFD): 2
- docuseal (just a tool, no methodology): 3
- Mariah's Opus 4.7 prompting reel (CLAUDE.md update): 3

### T3 Reversibility (0-3, 3 = good)

If we adopt and it doesn't work, how hard is the rip-out?

- **0** = irreversible (data lock-in, workflow rewiring, accumulated state)
- **1** = hard to leave (state files, accumulated artifacts)
- **2** = annoying but possible (uninstall + cleanup)
- **3** = drop out anytime (single command uninstall, no residue)

Examples:
- ruflo (deep integration with workspace files): 1
- BMAD (state files + agent personas tied to projects): 2
- addyosmani agent-skills (per-skill uninstall): 3
- mattpocock skills (atomic and removable): 3

## Total score -> Verdict mapping

| Score | Verdict | Meaning |
|---|---|---|
| 35-48 | **Adopt** | Direct adoption candidate. Score the scope: Jadyly Studios / Wayfinder / Actually / MultiScope |
| 25-34 | **Pilot in sandbox** | Worth piloting before adoption. Sandbox first, validate in isolation. |
| 15-24 | **Hold for Phase 1.0+** | Right tool, wrong time. Park it; revisit when context shifts. |
| 0-14 | **Pass** | Doesn't survive the rubric. Don't pursue. |

## Verdict labels (full set)

When verdict is Adopt, pick the scope tag:

- **Adopt - Jadyly Studios** - universal harness upgrade for everything the studio ships
- **Adopt - Wayfinder** - specific to current Phase 3 / V1 seed work
- **Adopt - Actually** - specific to the Actually codebase
- **Adopt - MultiScope** - applies to multiple of the above

Other verdicts:

- **Pilot in sandbox** - score 25-34, needs real test before promotion
- **Hold for Phase 1.0+** - score 15-24, right tool wrong time
- **Pass** - score 0-14 or doesn't fit any current need

## Guardrail flags (multi-select)

Apply these flags regardless of total score - they signal risks the verdict alone doesn't capture:

- **DriftRisk** - introduces parallel methodology that conflicts with locked decisions
- **LockIn** - vendor lock-in, data lock-in, or workflow lock-in that's hard to escape
- **MaturityRisk** - unverified at scale, single author, or major-version churn

A 35-Adopt item with three guardrail flags should be flagged in the verdict rationale ("Adopt with caution - flag in adoption decision").

## Tuning notes

The rubric is intentionally calibrated against Clark's current priorities (May 2026). It will need re-tuning as priorities shift. Indicators that re-tuning is needed:

- Cluster of items all scoring in the same narrow band (suggests thresholds need adjustment)
- Repeated cases where the score feels wrong against intuition (suggests column weights need adjustment)
- New priorities emerging that aren't captured by any column (suggests adding a column)

Don't tune the rubric mid-session - it ruins comparison consistency. Tune between sessions, document the change as a Cat 1 row in MEMORY.md.
