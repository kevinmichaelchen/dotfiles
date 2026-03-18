---
name: confluence-pages
description: Draft, format, create, and update Confluence pages using Atlassian tools via the Executor MCP. Use when Codex needs to publish or revise a Confluence page or personal-space post, especially when the page should include a short TL;DR, a table of contents, inline links, accessible progressive disclosure, and properly rendered Confluence code blocks.
---

# Confluence Pages

Use this skill only for Confluence page production. Its responsibility is to
shape content for Confluence and publish or update it with Atlassian tools.

## Workflow

1. Resolve the destination and page state.
   - Capture the page title, target space key, optional parent page, and whether
     this is a create or update.
   - Search first with `atlassian.confluence_search` to avoid duplicate drafts.
   - If updating, inspect the current page with `atlassian.confluence_get_page`
     before rewriting it.
   - For personal spaces, prefer explicit space keys. If needed, use
     `atlassian.confluence_search_user` and quoted CQL such as
     `space="~username"` to find the right destination.
   - Current Executor support is page-centric. If the user says "blog post" but
     no dedicated blog-post tool is available, publish a normal page in the
     personal space and say so.

2. Choose the content format deliberately.
   - Prefer `content_format: storage` when the page needs a native Confluence
     table of contents or code blocks that must render reliably.
   - Use `content_format: markdown` for simpler prose pages where headings,
     lists, inline links, and fenced code blocks are sufficient.
   - When using markdown, set `enable_heading_anchors: true` when deep links are
     useful.
   - Do not leave fenced code blocks inside a storage body. Convert each code
     example to a Confluence `code` macro. Read
     [storage snippets](./references/storage-snippets.md) before composing a
     storage page.

3. Compose the page with the default structure.
   - Start with a short TL;DR section.
   - Put the table of contents immediately after the TL;DR.
   - Put the most important material first, then supporting detail, then
     appendix-style material.
   - Prefer clear section headings over long uninterrupted prose.
   - Prefer inline links with descriptive anchor text over naked URLs.
   - Use tables only when they materially improve scanning or comparison.

4. Write for accessibility and progressive disclosure.
   - Lead with the answer, recommendation, or takeaway before background.
   - Keep paragraphs short and sections scannable.
   - Use headings to separate summary from detail.
   - Keep code examples small, relevant, and labeled with a language whenever
     possible.
   - Avoid jargon where plain language works.

5. Publish and verify.
   - Create with `atlassian.confluence_create_page` or update with
     `atlassian.confluence_update_page`.
   - Add labels with `atlassian.confluence_add_label` when useful.
   - If create fails because the page already exists, switch to search plus
     update instead of creating duplicates.
   - Report the page title, page id, URL if available, labels, and the chosen
     content format.

## Default Conventions

- TL;DR above the table of contents
- Inline links inside sentences
- Accessible writing that favors progressive disclosure
- Native Confluence code blocks when reliable rendering matters
- Confluence-native table of contents whenever navigation matters
