---
name: mach-product-ticket
description: >
  Use when drafting or rewriting the body of a Linear ticket so it reads for a
  product-level audience (Product Owner / stakeholder), not an engineer. Provides
  three product-framed templates: Feature/Change, Bug, and Spike/Discovery.
  Trigger on phrases like "draft a ticket", "write up this Linear issue",
  "create a feature/bug/spike ticket", "make this ticket product-readable", or
  when filling in an empty/thin issue description. Pairs with
  `mach-linear-ticket`, which handles team, issue-type, priority and PR linking
  — this skill handles the description itself.
---

# Product-Level Linear Tickets

You help write Linear ticket descriptions that a **Product Owner can read and
sign off without an engineer translating them**. The ticket states what changes
for the user, why it matters, and how we'll know it's done. Every technical
detail — architecture, root cause, file paths, design trade-offs — lives in one
**Implementation Notes** section at the bottom, clearly separated from the
product story above it.

This applies equally to backend and frontend work. A backend-only change still
has a product-level "what changes / why it matters" framing; the engineering
lives in Implementation Notes.

## Required tool

If you're reading or writing a ticket in Linear, this uses the Linear MCP server
(`mcp__claude_ai_Linear__get_issue` / `save_issue`). If it isn't connected, draft
the markdown for the user to paste in, and say so. You can also just produce the
body as text — the templates are useful independently of the API.

## Core principle: write for the Product Owner

Before writing, separate the two audiences:

| Product story (top of ticket) | Implementation Notes (bottom) |
|-------------------------------|-------------------------------|
| What the user can now do | Which classes/endpoints/components change |
| The customer or business value | Design decisions and trade-offs |
| Observable acceptance criteria | Root cause, queries, migrations |
| What's explicitly out of scope | File paths, risks, open questions, OpenSpec link |

Rules of thumb:

- **No jargon above the line.** No class names, table names, endpoints, or file
  paths in the Summary / Why / What / Acceptance sections. If you catch yourself
  writing one, move it to Implementation Notes.
- **Acceptance criteria are observable.** Phrase them as something a PO or tester
  can verify from the outside ("a user with X permission can…", "an unknown link
  returns not-found"), not as "the service returns a DTO".
- **Implementation Notes is optional in size, not in placement.** A trivial
  change may have one line there; a complex backend change may have the full
  design-decisions / risks / open-questions breakdown. It always comes last.
- **Don't invent detail.** If you don't know the root cause or the files, leave a
  `TODO` in Implementation Notes rather than guessing.
- **Don't overstate situations.** Be honest and present verifiable facts
  without embellishment.

## Step 1: Pick the template

| Work type | Template | Tell-tale |
|-----------|----------|-----------|
| Building/extending behaviour | **Feature / Change** | "users can now…", new page/endpoint/field |
| Something is broken | **Bug** | regression, wrong output, error in prod |
| Need to decide before building | **Spike / Discovery** | "investigate", "how should we…", time-boxed |

If the work is genuinely a test plan or a release sign-off, those stay on the
team's existing conventions (the test-case table; the sign-off checklist) — this
skill covers the three core authoring templates.

## Step 2: Fill the template

### Feature / Change

```markdown
## Summary
One paragraph, plain language: what a user can do once this ships.

## Why it matters
The customer or business driver. Link the cycle / project / goal it serves.
Why now?

## What changes
- User-facing, bold-led bullets: the pages, actions, or outcomes that change.
- Describe behaviour, not implementation.

## Acceptance criteria
- [ ] Observable, testable statements — include permission/flag behaviour and
      the important edge cases (empty input, not-enabled, no-permission).

## Out of scope
- What this explicitly does NOT do (deferred work).

## Dependencies
- Blocking tickets, feature flags, or permissions this relies on.

## Implementation Notes
_Engineering detail — safe for a PO to skip._
- Approach / key components touched (endpoints, services, pages, fields).
- **Design decisions** — D1, D2 … (decision + one-line rationale).
- **Risks & trade-offs** — R1, R2 …
- **Open questions** — Q1, Q2 … (resolve before or inline).
- _OpenSpec change:_ `change-name` (if used). Links to design docs/PRs.
```

### Bug

```markdown
## Problem
What the user experiences and the impact — in plain language. Where it happens
(which screen/flow) and whether it's in production.

## Expected vs actual
- **Expected:** …
- **Actual:** …

## Impact
Who's affected, how often, and how badly. (Severity/urgency labels are set per
`mach-linear-ticket`.)

## Steps to reproduce
1. …

## Acceptance criteria
- [ ] Fixed when … (observable — the wrong behaviour no longer happens).
- [ ] Regression covered by a test.

## Implementation Notes
_Engineering detail — safe for a PO to skip._
- **Root cause:** …
- **Fix approach:** …
- **Files / components:** `path` — what changes.
- **References:** logs, writeups, related tickets.
```

### Spike / Discovery

```markdown
## Question to answer
The specific decision this unblocks. (A spike is done when the decision is
recorded — not when code merges.)

## Why we need this now
What downstream work is waiting on the answer.

## What we need to know
- [ ] The open questions, in product terms.

## Timebox
e.g. 1 day. Spikes are bounded by design.

## Deliverable
Definition of done — a recommendation, an estimate, a short doc, or a throwaway
spike PR. Name the artifact.

## Implementation Notes
_Engineering detail — safe for a PO to skip._
- Candidate approaches, code areas to inspect, technical constraints.
```

## Step 3: Write it back

- **New ticket:** create via `mach-linear-ticket` (it handles team, issue-type
  label, and priority), then set this description.
- **Existing ticket:** `save_issue(id=..., description=...)`. Show the user the
  drafted markdown and confirm before overwriting a non-empty description.
- Keep the Linear markdown clean — Linear renders standard GitHub-flavoured
  markdown and checkbox lists.

## How this pairs with `mach-linear-ticket`

- `mach-linear-ticket` → **classification & linking**: detect ticket from branch,
  choose team, set issue-type label and priority, attach the PR, transition
  status.
- `mach-product-ticket` (this skill) → **the description body**: which template,
  product-level wording, and the Implementation Notes split.

When creating a brand-new ticket, run both: this skill writes the body,
`mach-linear-ticket` sets the metadata and links.

## Common pitfalls

- **Don't leak implementation above the line.** Endpoints, class names, table
  names, and file paths belong only in Implementation Notes.
- **Don't write untestable acceptance criteria.** "Works correctly" is not a
  criterion; "an unauthenticated user with a valid link sees the journey" is.
- **Don't drop Implementation Notes for backend tickets** — that's exactly where
  the engineering goes, so the top stays product-readable.
- **Don't leave a spike open-ended.** It must have a question, a timebox, and a
  named deliverable.
- **Don't overwrite an existing description without confirming.** Diff against
  what's there; preserve anything still useful.
- **Don't fabricate root cause or file lists.** Use `TODO` placeholders if
  unknown.

## Reference

- Sibling skill: `mach-linear-ticket` (issue-type and priority guidelines,
  branch detection, PR linking).
