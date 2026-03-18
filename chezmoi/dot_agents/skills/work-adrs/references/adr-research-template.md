# ADR Research Template

Use this as the default ADR draft body.

If the user wants the result published to Confluence, hand this draft to
`$confluence-pages` and let that skill choose the final page format.

## Suggested title

`ADR Research: <decision> - YYYY-MM-DD`

## Template

```md
# ADR Research: <Decision>

- Status: Proposed
- Date: <YYYY-MM-DD>
- Author: <name>
- Team: <team>
- Stakeholders: <names or groups>
- Related links: <Jira, PRD, docs, prior ADRs>

## Executive summary

<2-4 paragraphs with the decision, why it matters now, and the recommended
direction>

## Problem statement

<What needs to be decided, what is in scope, and what is explicitly out of
scope>

## Current state

<How the system works today, what hurts, and what constraints already exist>

## Decision drivers

- <driver 1>
- <driver 2>
- <driver 3>

## Options considered

### Option 1: <name>

**Summary**

<1 short paragraph>

**Benefits**

- <benefit>
- <benefit>

**Costs and risks**

- <cost or risk>
- <cost or risk>

**Evidence**

- <claim>: <source>
- <claim>: <source>

### Option 2: <name>

<Repeat the same structure>

### Option 3: Status quo

<Repeat the same structure>

## Comparison

| Option | Strengths | Weaknesses | Best fit |
| --- | --- | --- | --- |
| <option> | <text> | <text> | <text> |
| <option> | <text> | <text> | <text> |
| <option> | <text> | <text> | <text> |

## Recommendation

<State the recommendation plainly. Include why this option wins now and what
tradeoff is being accepted.>

## Consequences

### Positive

- <expected benefit>
- <expected benefit>

### Negative

- <accepted drawback>
- <accepted drawback>

## Rollout or follow-up

- <migration or experiment>
- <owner and next step>

## Open questions

- <question>
- <question>

## Sources

- <title> - <url or identifier> - retrieved <YYYY-MM-DD>
- <title> - <url or identifier> - retrieved <YYYY-MM-DD>
```

## Publishing checklist

- Replace every placeholder.
- Keep the recommendation explicit and testable.
- Preserve source links and retrieval dates.
- Add labels such as `adr`, `adr-research`, and the domain or system name.
- If an ADR draft already exists, update it instead of creating a duplicate.
