# Global Agent Guidance

## Search And Extraction Tools

- For local workspace questions, start with local search: use `rg` or
  `rg --files` before remote search when the answer may already be in the
  workspace. If a local folder should become reusable context across sessions,
  use [`nia local`][nia-cli] to add, sync, or watch it.
- For indexed code, docs, repositories, and cross-agent context, use
  [`nia search`][nia-cli] first. Reach for `nia repos`, `nia sources`,
  `nia github`, and `nia tracer` when the task needs repository indexing, live
  GitHub browsing, or code search without indexing. Use `nia contexts` to save
  or retrieve prior agent context.
- For package ecosystem questions, use [`nia packages`][nia-cli] for npm, PyPI,
  crates.io, and Go package source search. Use `nia deps` when project
  dependencies should be connected to relevant documentation subscriptions.
- For papers, datasets, and document-heavy work, use [`nia papers`,
  `nia datasets`, `nia extract`, or `nia document`][nia-cli]. Use extraction
  commands for tables, detected document elements, or engineering document
  analysis; use the document agent for multi-step questions over indexed PDFs
  and documents.
- For autonomous multi-step research over Nia-indexed context, use
  [`nia oracle`][nia-cli]. Prefer it when repository, documentation, local,
  paper, dataset, or connector context should guide the research.
- For converting a specific file, URL, or media artifact into Markdown, use
  [`markit`][markit]. It handles PDFs, DOCX, PPTX, XLSX, HTML, EPUB,
  notebooks, RSS, images, audio, and URLs, and can write output files or extract
  images. Treat it as a conversion tool, not a general research tool.
- For lightweight website or documentation pulls into local Markdown, use
  [`bunx webpull <url>`][webpull]. It is a good fit when a bounded set of pages
  from one site is enough; keep output scoped with `--out` and `--max`.
- For normal current-web lookup, URL extraction, entity discovery, enrichment,
  deep research, or web monitoring, use [`parallel-cli`][parallel-cli]:
  `search` for web lookup, `fetch` or `extract` for clean Markdown from known
  URLs, `findall` for entities matching a description, `enrich` for adding
  web-sourced fields to records, `research` for deeper open-ended work, and
  `monitor` for recurring change tracking.
- For web scraping, crawling, site maps, browser-like page interaction, file
  parsing, structured extraction, or recurring scrape/crawl monitoring, use
  [`firecrawl`][firecrawl-cli] when authenticated with `FIRECRAWL_API_KEY`.
  Start with `scrape` for known URLs, `crawl` for a site section, `map` for URL
  discovery, `parse` for local documents, `search` for web search, `agent` for
  structured web extraction, `interact` for dynamic pages, and `monitor` for
  recurring changes.
- For agent-accessible MCP tools, use [Executor MCP][executor]. Discover tools
  with `tools.search()` and configured sources with
  `tools.executor.sources.list()`. Current sources may include [Exa][exa-docs]
  for search, contents, similar-page, answer, and research tasks;
  [Perplexity][perplexity-docs] for search and reasoned answers with web
  context; [DeepWiki][deepwiki] for GitHub repository documentation; Grep MCP
  for literal public-code pattern search; and other authenticated workspace
  tools.

Prefer the narrowest tool that matches the job. For current facts, prices,
laws, software versions, or other time-sensitive claims, verify with a live web
or MCP source and include source context in the answer. When a CLI is missing,
try its package runner only when appropriate, otherwise state the availability
gap instead of silently substituting a weaker source.

[deepwiki]: https://deepwiki.com/
[exa-docs]: https://docs.exa.ai/
[executor]: https://executor.sh/
[firecrawl-cli]: https://docs.firecrawl.dev/cli
[markit]: https://github.com/Michaelliv/markit
[nia-cli]: https://docs.trynia.ai/cli/index
[parallel-cli]: https://docs.parallel.ai/integrations/cli
[perplexity-docs]: https://docs.perplexity.ai/
[webpull]: https://www.npmjs.com/package/webpull
