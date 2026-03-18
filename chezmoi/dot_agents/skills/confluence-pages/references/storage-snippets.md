# Storage Snippets

Read this file before composing a page with `content_format: storage`.

## Minimal page skeleton

The Confluence page title already comes from the tool input. Start the body with
the TL;DR, then the table of contents, then `h2` and `h3` sections.

```xml
<p><strong>TL;DR.</strong> One short paragraph or a few bullets.</p>

<ac:structured-macro ac:name="toc">
  <ac:parameter ac:name="minLevel">2</ac:parameter>
  <ac:parameter ac:name="maxLevel">3</ac:parameter>
  <ac:parameter ac:name="type">list</ac:parameter>
</ac:structured-macro>

<h2>Overview</h2>
<p>Start with the key point.</p>
```

## Code block macro

Use one macro per code block. Keep the language parameter when it is known.

```xml
<ac:structured-macro ac:name="code">
  <ac:parameter ac:name="language">bash</ac:parameter>
  <ac:parameter ac:name="title">Example</ac:parameter>
  <ac:plain-text-body><![CDATA[
echo "hello"
  ]]></ac:plain-text-body>
</ac:structured-macro>
```

## Inline links

External inline links can stay simple in storage content.

```xml
<p>See the <a href="https://example.com/docs">deployment guide</a> before rollout.</p>
```

## Conversion checklist

- Put the TL;DR before the TOC.
- Use `h2` and `h3` headings so the TOC has useful entries.
- Convert every fenced code block to a `code` macro.
- Wrap code bodies in `<![CDATA[ ... ]]>`.
- Keep links inline and descriptive.
