-- Ideas Inbox Database Schema
-- Pass this to notion-create-database when the Ideas Inbox doesn't exist yet
-- Parent page: Jadyly Dev Shop (page_id: 3299123d-1fc8-80e0-8c9f-dff5174c208a)
-- Database name: "Ideas Inbox"

CREATE TABLE (
  "Title" TITLE,
  "Description" RICH_TEXT COMMENT '2-3 sentence summary of what the item is and what it does',
  "Source URL" URL,
  "Source Channel" SELECT('Manual':gray, 'iOS Share':blue, 'Email Forward':green, 'Webhook':purple, 'Scheduled':orange) COMMENT 'How this URL got captured into the inbox',
  "Research Session Tag" RICH_TEXT COMMENT 'Optional tag for grouping URLs that belong to a single research effort',
  "Content Type" SELECT('IG Reel':pink, 'IG Carousel':pink, 'GitHub Repo':blue, 'YouTube':red, 'Google Drive':yellow, 'Twitter/X':blue, 'Reddit':orange, 'Web Article':gray, 'PDF':orange, 'Guide':yellow, 'Video':red),
  "Status" SELECT('Pending':gray, 'Researching':yellow, 'Scored':blue, 'Synthesized':green, 'Acted On':purple, 'Archived':default),
  "T1 Design Ceiling" NUMBER COMMENT 'Tier 1 weighted 0-6. Raises the design ceiling: best output the harness can produce.',
  "T1 Design Floor" NUMBER COMMENT 'Tier 1 weighted 0-6. Raises the design floor: worst output the harness can ship unsupervised.',
  "T1 Autonomy 24-7" NUMBER COMMENT 'Tier 1 weighted 0-6. Composable into round-the-clock loops without supervision.',
  "T1 Cost Optimization" NUMBER COMMENT 'Tier 1 weighted 0-6. Compute/API spend reduction is the dominant factor.',
  "T2 Replaces Upgrades" NUMBER COMMENT 'Tier 2 standard 0-3. Replaces or upgrades something we use today.',
  "T2 Adds Capability" NUMBER COMMENT 'Tier 2 standard 0-3. Adds capability we do not currently have.',
  "T2 Maturity Signal" NUMBER COMMENT 'Tier 2 standard 0-3. Production-grade, evidence of scale.',
  "T2 Integration Cost" NUMBER COMMENT 'Tier 2 standard 0-3. 3 = drop-in. 0 = high friction or vendor lock-in.',
  "T2 Jadyly Studios Fit" NUMBER COMMENT 'Tier 2 standard 0-3. Improves the harness for any product the studio ships.',
  "T2 Wayfinder Fit" NUMBER COMMENT 'Tier 2 standard 0-3. Directly accelerates current Phase 3 V1 seed skill or TDVR or brand kit work.',
  "T3 Drift Risk" NUMBER COMMENT 'Tier 3 guardrail 0-3. 3 = no conflict with locked methodology.',
  "T3 Reversibility" NUMBER COMMENT 'Tier 3 guardrail 0-3. 3 = drop out anytime.',
  "Total Score" FORMULA('prop("T1 Design Ceiling") + prop("T1 Design Floor") + prop("T1 Autonomy 24-7") + prop("T1 Cost Optimization") + prop("T2 Replaces Upgrades") + prop("T2 Adds Capability") + prop("T2 Maturity Signal") + prop("T2 Integration Cost") + prop("T2 Jadyly Studios Fit") + prop("T2 Wayfinder Fit") + prop("T3 Drift Risk") + prop("T3 Reversibility")'),
  "Verdict" SELECT('Adopt - Jadyly Studios':green, 'Adopt - Wayfinder':blue, 'Adopt - Actually':purple, 'Adopt - MultiScope':pink, 'Pilot in sandbox':yellow, 'Hold for Phase 1.0+':orange, 'Pass':red),
  "Verdict Rationale" RICH_TEXT,
  "Guardrail Flags" MULTI_SELECT('DriftRisk':red, 'LockIn':orange, 'MaturityRisk':yellow),
  "Design Ceiling Notes" RICH_TEXT,
  "Design Floor Notes" RICH_TEXT,
  "Autonomy Notes" RICH_TEXT,
  "Cost Notes" RICH_TEXT,
  "Sources Cited" RICH_TEXT COMMENT 'Source URL plus verification attempt URLs with TRUE/FALSE/UNVERIFIED status',
  "Date Captured" DATE,
  "Date Scored" DATE
)
