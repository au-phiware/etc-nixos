---
name: review-pr-latency
description: |
  Measure how long a squad's pull requests sat waiting for peer review over one or more
  Linear cycles, and how concentrated that waiting is. Handles the fact that different
  people signal "ready for review" differently (GitHub review request, `pending code
  review` label, `not ready` label, draft toggle, Slack post) by treating readiness as a
  state rather than an event. Excludes Copilot, stacked PRs that do not target trunk, and
  non-Production repos. Publishes two artifacts: a latency report and a Lorenz/Gini
  concentration chart.
  Usage: `/review-pr-latency` (current + previous cycle for the Uplift Squad)
         `/review-pr-latency 4` (last four cycles)
         `/review-pr-latency team="Uplift Squad" authors=a,b,c`
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Artifact
  - mcp__claude_ai_Linear__list_cycles
  - mcp__claude_ai_Linear__list_teams
  - mcp__claude_ai_Slack__slack_read_channel
  - mcp__claude_ai_Slack__slack_search_channels
---

# Measure PR review latency

Two scripts do the deterministic work. You do the three things they cannot: resolve the
cycle window from Linear, optionally mine Slack, and publish the artifacts.

## Defaults

| Setting | Default |
|---|---|
| Linear team | Uplift Squad |
| Cycles | current + previous (4 weeks) |
| Authors | `au-phiware`, `mikettn`, `shumayl-asmawi`, `kalegata` |
| Org | `machship` |
| Slack channel | `#uplift-squad-internal` (`C0APWAWRPLP`) |
| Clock | business days, Mon–Fri AEST |
| Slow threshold | 3 days |

Override any of these from the user's arguments. Ask only if a default is clearly wrong
for what they asked (a different squad, say) and you cannot infer it.

## Steps

### 1. Resolve the window from Linear

`list_teams` to get the team id, then `list_cycles` with `type: current` and
`type: previous`. Take `startsAt` of the oldest cycle as `--since`, `endsAt` of the
newest as `--until`, and the boundary between them as `--split-at`. Use the cycle
`title` values for `--split-names`.

For more than two cycles there is no `list_cycles` filter that returns them, so derive
the earlier boundaries by subtracting the cycle length from the previous cycle's start
and say in the report that those boundaries are derived rather than read.

### 2. Collect

The scripts live beside this file, in a read-only nix store directory:

```bash
SKILL=~/.claude/skills/review-pr-latency
OUT=$(mktemp -d)
bash "$SKILL/scripts/collect.sh" "$OUT" machship <since-date> <author>...
```

Pass a `--since` date a few days **before** the window start: a PR merged on day one may
have become reviewable before it. The script also fetches each repo's `project-type`
custom property, and warns if any PR's timeline was truncated — if you see that warning,
raise the `first:` limit in `collect.sh` and re-run rather than accepting the numbers.
The installed copy is a read-only nix store symlink, so edit the source in
`etc-nixos/share/claude-skills/review-pr-latency/` and re-switch.

### 3. Mine Slack (optional, small effect)

Some of the team announce readiness in Slack rather than on the PR. Measured over Q3.3 +
Q3.4 this shifted the median by 2.7h, left p90 untouched, and made **zero** PRs
measurable that were not already. Skip it when the user wants a quick number; include it
when the report is going to be shared.

Read `#uplift-squad-internal` across the window and pick out messages that announce a PR
as ready ("ready for review", "can I get a review", "needs review", "awaiting PR
review"). Ignore messages that merely mention a PR — a merge-conflict heads-up or a
release question is not a review request. Write:

```json
[{"at": "2026-08-26T05:18:57Z", "repo": "machship/machship", "prs": [6762]}]
```

Slack timestamps come back in AEST; `at` must be UTC.

### 4. Analyse

```bash
python3 "$SKILL/scripts/analyse.py" \
  --dir "$OUT" \
  --since <iso> --until <iso> --split-at <iso> --split-names "Q3.3,Q3.4" \
  --authors au-phiware,mikettn,shumayl-asmawi,kalegata \
  --slack-signals "$OUT/slack.json"     # omit if step 3 was skipped
```

Prints a markdown summary and writes `summary.json` (all aggregates, Lorenz points, Gini)
and `rows.json` (per-PR detail) into `$OUT`. Add `--calendar-days` to include weekends,
`--repo-types ""` to keep every repo, `--base-branches ""` to keep stacked PRs.

### 5. Publish

Two artifacts. Update them in place so the links stay stable across cycles — read the
existing page first, then republish the same URL with the new figures:

- **Uplift Review Latency** — https://claude.ai/code/artifact/c3fe4926-642c-4fd8-9cb9-f05348d038ff
- **PR Wait Concentration** — https://claude.ai/code/artifact/b7c58907-40df-4f70-8a84-b8c7499aa066

`Artifact` with `action: "read"` and the URL returns the current HTML. Keep the design,
swap the numbers, and update the narrative to whatever the new data actually says — do
not carry last cycle's conclusions forward. On the Lorenz page the curve is ordered
slowest-first so it bows below the diagonal with the fast PRs on the right; `summary.json`
already emits the points in that order.

## What the numbers mean

- **wait** — accumulated time in the reviewable state up to merge. This is the headline.
- **elapsed** — first-ready to merge in one span. Equal to `wait` unless the author pulled
  the PR back out of review, which this squad almost never does (118 of 120 last cycle).
- **rounds** — how many times the PR entered the reviewable state.
- **Gini / Lorenz** — how concentrated the waiting is. A *high* Gini alongside a *falling*
  total is good news: routine review got fast and the leftovers concentrated. Gini is
  scale-invariant, so never quote it without the PR-day total beside it.

## Traps this pipeline already handles

- **The one-second phantom window.** GitHub fires the human `ReviewRequestedEvent` at PR
  creation and the `not ready` label lands a second later. Counting that as a review
  window starts the clock at PR creation and inflates the round count. A 60-second floor
  drops them; every real window is far longer.
- **Copilot.** Requested on nearly every PR and reviews within minutes. Filtered by
  `requestedReviewer.__typename == "Bot"` on requests and a login check on reviews.
- **The Linear integration** posts an `IssueComment` seconds after creation. It is in the
  bot list; without it the first-response metric reads ~0h for everything.
- **Stacked PRs.** A PR targeting a feature branch is plumbing inside someone's stack, not
  work entering trunk, and it is usually self-merged. Ten of them last cycle looked like
  "merged with no peer review" until they were filtered out.
- **Weekends.** They change the tail and not the middle. Excluded by default.

## Sanity checks before you report

1. Population line: kept + excluded should equal merged-in-window.
2. Spot-check the slowest PR by hand against its GitHub timeline. If the state machine is
   wrong anywhere it will be wrong there most visibly.
3. If `never_reviewed` is non-empty, open each one — the usual cause is a filter that
   should have excluded it, not a genuinely unreviewed merge.
