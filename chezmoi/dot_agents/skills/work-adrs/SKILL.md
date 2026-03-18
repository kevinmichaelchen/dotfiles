---
name: work-adrs
description: Research architectural decisions and produce work ADR material. Use when Codex needs to compare technical options, gather internal and external evidence, write an ADR research brief or decision memo, or prepare ADR content for later publishing. Prefer Nia for internal or indexed sources, but use other Executor MCP research tools such as Perplexity, Exa, DeepWiki, Grep, Firecrawl, and GitHub when they move the work forward faster. When Confluence page production or publishing is needed, hand off that step to $confluence-pages.
---

# Work ADRs

Produce evidence-backed ADR research that is easy to challenge, update, and
publish.

Use this skill to move from a vague "should we do X?" prompt to a decision memo
with sources, tradeoffs, and a publishable ADR draft.

## Workflow

1. Frame the decision.
   - Capture the decision statement, scope, constraints, success criteria,
     deadline, stakeholders, and current baseline.
   - Inspect the repo, existing ADRs, Jira tickets, and Confluence pages before
     asking the user for missing context.
   - Keep at least one baseline option, usually `status quo` or `do nothing`.

2. Gather evidence.
   - Start with local code, docs, and existing architecture notes.
   - Prefer Nia-first for internal or indexed sources. Use the Nia skill, Nia
     CLI, or Executor MCP `nia.*` tools first when those sources are likely to
     exist already.
   - Do not block on Nia indexing. If indexing is slow, the source is not ready
     yet, or another tool can answer the question faster, continue with other
     research tools immediately and return to Nia later if needed.
   - If using Executor MCP, discover and call concrete tools instead of relying
     on memory. Useful paths include:
     - `nia.search`, `nia.nia_read`, `nia.nia_research`
     - `perplexity_search.search`
     - `exa.web_search_exa`, `exa.get_code_context_exa`
     - `deepwiki.read_wiki_structure`, `deepwiki.read_wiki_contents`,
       `deepwiki.ask_question`
     - `grep.searchgithub`
     - relevant `github.*`, `firecrawl.*`, or `atlassian.*` tools
   - Use whichever mix of Nia, Perplexity, Exa, DeepWiki, Grep, Firecrawl, and
     GitHub gets to defensible evidence fastest. Nia is preferred, not
     mandatory.
   - Use multiple sources for claims that are current, vendor-specific, or
     likely to drift.
   - Record exact URLs, repo names, page titles, or document identifiers for
     every material claim.

3. Parallelize bounded research when useful.
   - If the question naturally decomposes, use parallel sub-agents to research
     independent options, vendors, source sets, or risk areas.
   - Good splits include `option A vs option B`, `internal precedent vs
     external market scan`, and `technical fit vs migration cost`.
   - Keep each delegated ask concrete and bounded. Ask sub-agents to return
     sources, claims, open questions, and a short recommendation for their
     slice.
   - Keep final synthesis, tradeoff weighting, and the ADR recommendation in
     the main agent. Do not outsource the decision itself.

4. Evaluate options.
   - Compare options against explicit criteria: complexity, migration cost,
     performance, reliability, security, developer ergonomics, operational
     burden, lock-in, and team fit.
   - Separate observed facts from inference.
   - Call out unknowns and how to retire them.
   - Prefer a clear recommendation. If the evidence is insufficient, recommend
     the next experiment instead of bluffing.

5. Draft the ADR research deliverables.
   - Produce a short executive summary plus a publishable ADR body.
   - Use [ADR research template](./references/adr-research-template.md) unless
     the user gives another house style.
   - Include: context, options considered, decision drivers, evidence matrix,
     recommendation, consequences, open questions, and sources.
   - Keep citations inline or in a dedicated sources section so the content
     survives handoff to other publication workflows.

6. Hand off page production when requested.
   - If the user wants the ADR published to Confluence, invoke
     `$confluence-pages` for page formatting, page creation or update, labels,
     and destination resolution.
   - Hand off the finalized ADR body, page title, target space or personal
     space, parent page if any, and any requested labels.
   - Let `$confluence-pages` choose `markdown` versus `storage` content and
     handle TL;DR, table of contents, inline links, and Confluence-native code
     blocks.
   - Return both the ADR recommendation and the publishing outcome.

## Quality Bar

- Prefer internal context over generic web content.
- Verify time-sensitive claims with current sources and note the retrieval date.
- Cite enough evidence that another engineer can challenge or extend the
  analysis.
- Parallelize research when it shortens the path to a decision, but keep the
  final recommendation coherent and single-authored.
- Keep the draft structured enough that `$confluence-pages` can publish it
  without re-researching the decision.
- Avoid writing an implementation plan unless the ADR explicitly needs one.
- State assumptions, rejected options, and residual risk plainly.
