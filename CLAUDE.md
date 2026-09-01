# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

The Jekyll source for <https://powershellexplained.com> (formerly `kevinmarquette.github.io`), Kevin Marquette's PowerShell blog. It is a customized fork of the **Beautiful Jekyll** theme. The published site is GitHub Pages, so **merging to `master` publishes**. Content is the product here; the theme files are inherited and rarely touched.

## Build & run

Builds run through `Invoke-Build` (`blog.build.ps1`) and use Docker rather than a local Ruby install.

```powershell
Invoke-Build                # UpdateTags, RecentPosts, Build, Image (default)
Invoke-Build Build          # jekyll build in the jekyll/jekyll container -> _site/
Invoke-Build Run            # serve _site/ via nginx at http://localhost:8080
Invoke-Build Stop           # tear down the nginx container
Invoke-Build UpdateTags     # regenerate tags.md from _posts (incremental)
Invoke-Build RecentPosts    # regenerate _includes/recent-posts.md (incremental)
Invoke-Build Image          # generate the share image for the newest post
```

There are no tests and no linter task. `.markdownlint.yaml` disables MD025/MD013/MD012 for editor linting only.

### Known breakage in the PowerShell scripts

`UpdateTags.ps1`, `UpdateRecentPosts.ps1`, and `CreateTitleImage.ps1` hardcode `C:\source\kevinmarquette.github.io\...` paths. This repo is checked out elsewhere, so those tasks will fail or write to the wrong place until the paths are fixed (or the repo is cloned to that path). Prefer passing `-path` where the script exposes it; otherwise fix the literal.

These scripts also depend on:

- `ConvertFrom-String` (Windows PowerShell 5.1 only — not in PowerShell 7)
- `New-WordCloud` (external module) for the `WordCloud` share-image type
- `System.Drawing` (Windows only)

`NewDraft.ps1` / the `NewPost` task call `Invoke-Plaster` against `..\PlasterTemplates\BlogPost`, a template that lives **outside** this repo (a sibling directory). Without it, create posts by hand.

## Content conventions

Posts live in `_posts/YYYY-MM-DD-Title-With-Dashes.md`. Permalinks are `/:year-:month-:day-:title/`, so the filename *is* the URL — **never rename a published post file**; use `redirect_from` in front matter instead (jekyll-redirect-from is enabled).

Standard front matter:

```yaml
---
layout: post          # implied by _config.yml defaults; usually omitted is fine
title: "Powershell: Some title"
date: 2020-03-15
tags: [PowerShell, SomeTag]
share-img: "/img/share-img/2020-03-15-Powershell-some-title.png"
---
```

Body conventions used consistently across posts:

- `<!--more-->` marks the excerpt cutoff (set via `excerpt_separator`) — place it after the intro paragraph.
- Every post opens with an `# Index` heading followed by a kramdown TOC (`* TOC` then `{:toc}` on the next line).
- **Internal links carry UTM params.** Cross-post links look like `/2018-03-14-Powershell-Post-Name/?utm_source=blog&utm_medium=blog`. Navigation links in `_config.yml` and generated pages add `utm_content=navbar|tags|recent`. Match the surrounding style when adding links.

`_draft/` (singular, not Jekyll's `_drafts`) holds unpublished work. Because of the leading underscore Jekyll ignores it; move a file to `_posts/` with a proper dated filename to publish.

## Author voice

When drafting or editing post content, write as Kevin. The voice is consistent across the whole archive and is a large part of why the posts land.

**Person and stance.** First person singular, present tense, talking to one reader. "I want to take a step back and talk about hashtables." "Let's take a close look at `$null`." Shift to "we" when walking through code together ("if we decide to set every server to the same value, this will fail"), and to "you" when describing what the reader will hit ("you are going to need an easy way to look at them from the console").

**Humble, never authoritative.** Kevin admits what confuses him, including in the post that is teaching the thing: *"I have to look up how to use `ShouldProcess` every time I need to use it... So don't worry if you still get confused from time to time."* He names bugs he personally wrote — *"It's a recreation of a bug I had to chase down before"*, *"it has been the source of many bugs for me because I was overlooking one important detail in my logic."* Never write in a way that implies the reader should already know this.

**Opinions are labeled as opinions.** "I personally don't like how long that makes commands." "I tend to use the dot property when I am treating it like a property." "This is one of my favorite things about hashtables." State the preference, give the reasoning, and leave the reader room to disagree. Then still show the thing he dislikes, because other people's code uses it: *"But there is a lot of code out there that does this so I wanted you to be aware of it."*

**Anti-cleverness.** Recurring judgment: readable beats clever. *"Just because you can do something, it does not mean that you should. That last one just looks like a bug waiting to happen."* Clarity, self-documenting code, and maintainability are the values being argued for.

**Credit people by name, with a link.** Mark Kraus, Mathias Jessen, Michael Sorens, Kirk, /r/PowerShell. When an idea came from someone, say so.

**Sentence rhythm.** Short declarative sentences. Plain words. Paragraphs of 1–4 sentences. No hype, no exclamation-point energy, no "simply" or "just" used to dismiss difficulty. Contractions are fine.

## The core writing model: teaching one evolving persona

This is Kevin's own description of how the deep dives are written, and it is the rule that generates everything else in this file. Understand this before restructuring or extending a post.

**Write to a persona, and tell them a story.** There is one reader in mind. They start out *almost foreign to the idea* — deliberately assume a lower level of base understanding than every other article on the topic assumes. That's the differentiator: most writing on `$null` or arrays starts a few rungs up the ladder, and these posts start below that.

**The persona evolves as the article goes.** Each section is pitched at who the reader has become by the time they reach it. The opening is for the newest user and is intentionally the most digestible part, because that is where the audience is widest. As the article teaches, the reader levels up, and later sections are written for that more capable reader.

**The ramp is simple → easy → medium → advanced → most obscure.** Sequence is determined by what the reader can now understand, not by what's most important or most interesting to the author. The obscure material earns its place at the end because only by then has the reader been given what they need to follow it.

**Examples build on earlier examples the same way the prose does.** Whenever possible, extend the example already on the page rather than introducing a fresh one — the `$ageList` hashtable becomes `$person`, becomes nested, becomes a `[pscustomobject]`; the `$environments` lookup table returns to demonstrate `BadEnumeration`. A reader who followed the first example can follow the fifth.

**Restructure freely to preserve the build.** Order is a dependency graph, not a fixed outline. When adding something new, find the point where the reader has just been given its prerequisites and put it there — and move existing sections if that's what it takes. Posts explicitly acknowledge this: *"this was written from top to bottom with examples that build on everything that came before it."*

**Be self-contained; reference his own material.** Prefer linking to another PowerShellExplained deep dive over sending the reader off-site. When a concept needs more room than the current post can give, that's a cross-link to a sibling article (or a reason to write one).

**Pick a tiny topic and exhaust it.** Scope narrow — one language feature, one concept — then explain *everything* known about it. The narrowness is what makes the completeness achievable.

**The posts are living documents.** Feedback is the mechanism: when a reader shares something that was left out, Kevin learns it and works it back into the article, with attribution. Editing an existing deep dive to fold in a new technique is normal, expected maintenance, not a rewrite. Credit the source by name and link (Mark Kraus on `GetEnumerator()`, Mathias Jessen on `$null` comparisons — both are folded-in reader contributions).

**The target: write the content he wishes he'd had.** When a judgment call comes up, this is the tiebreaker.

## Post structure

The shape that falls out of the model above.

1. **Intro, 2–4 sentences, then `<!--more-->`.** Frame the topic as fundamental and deceptively simple, link the relevant `about_*` doc on the first mention, and end on the promise: "Let's take a close look at X" / "In this article, we will dive deep into how to implement this feature."
2. **`# Index` + TOC.**
3. **Ground floor first.** The language-agnostic definition, then what PowerShell specifically does with it. Near-verbatim across posts: *"I am going to start with a basic technical description of what X are... before I shift into the other ways PowerShell makes use of them."* Arrays get explained before hashtables, because hashtables are explained in terms of arrays.
4. **Many small `##`/`###` sections, one idea each.** A short paragraph, a code sample, then a sentence explaining the output. Small enough to skim and to land on from the TOC.
5. **A late "all the fun stuff" stretch** — the obscure, the hidden gems, the things "most people are not aware of." This is where the leveled-up reader gets paid off.
6. **A closing section** (`# Anything else?`, `# Summary`, `# In closing`, `# Closing remarks`) that acknowledges how much ground was covered, frames the post as a reference to re-read (*"My hope is that you walk away learning something new or understanding it better every time you read this"*), notes that not all of it will apply to the reader today and that's fine, and invites sharing or feedback on Twitter.
7. **Cross-link the sibling deep dives** at natural points and in the closing.

### The "Everything you wanted to know" series

The flagship series, and by far the most-read content on the site. Conventions:

- Title: `"Powershell: Everything you wanted to know about <topic>"` — the `Powershell:` casing in front matter is historical; use `PowerShell` in body text.
- Tags include `Everything`.
- Scope is total coverage of one small language feature or concept — a reference the reader returns to, not a tutorial they read once.
- Cover the boring basics *and* the sharp edges: `BadEnumeration`, `-eq $null` against an array containing `$null`, `[PSCustomObject]` having no `.Count` on 5.1, shallow vs. deep clone. The gotchas are much of the value, and they belong late, after the reader can appreciate why they're surprising.

## Code examples

- **Fence with `powershell`** in new content. The archive is inconsistent — 2016–2017 posts use 4-space indented blocks, 2018–2019 use ` ``` posh ` (with the contents *also* indented 4 spaces inside the fence), 2020 uses ` ``` powershell ` unindented. Follow the 2020 style going forward; leave old posts alone unless editing them anyway.
- **Console transcripts use a `PS>` prefix** and show real output on the following lines inside the same block:

  ```powershell
  PS> $ageList.values | Measure-Object -Average
  Count   : 2
  Average : 22.5
  ```

- **Paste real error text verbatim**, including the `+ CategoryInfo` and `+ FullyQualifiedErrorId` lines. Readers find these posts by searching the error message.
- **Splat any command with 3+ parameters.** This is stated as a personal rule in the hashtable post and followed everywhere: *"I define too long as causing my window to scroll right."*
- **`$null` goes on the left** of comparisons, always, and the reason is explained wherever it comes up.
- **Extend the example already on the page** rather than inventing a new one — see the writing model above. A recurring cast keeps this cheap: `Kevin`/`Alex` with ages, Austin TX, `$data`/`$node`/`$result`, servers like `SrvProd05` or `ATX-FILE01`.
- Wrap variables in brackets in log/output strings (`"The value is [$value]"`) so empty values are visible — an explicitly taught habit.
- Link the `about_*` Microsoft Docs page the first time a concept is named.

## Generated files — do not hand-edit

- `tags.md` — rebuilt by `UpdateTags.ps1` from every post's `tags:` front matter.
- `_includes/recent-posts.md` — rebuilt by `UpdateRecentPosts.ps1` from the 8 newest posts (sorted by filename).
- `img/share-img/*` — produced by `CreateTitleImage.ps1`; the script prints the `share-img:` line to paste into front matter.
- `_site/` — build output, gitignored.

## Theme structure

- `_layouts/base.html` → `default.html` / `post.html` / `page.html` / `minimal.html`. Posts render through `post.html` → `base.html`.
- `_includes/` holds the header, nav, footer, analytics, adsense, social-share, and search partials.
- `_plugins/_tag_gen.rb` generates `/tag/<name>/` index pages using `_layouts/tag_index.html`. **Custom plugins don't run on GitHub Pages** — these pages only exist in a local Docker build. The site's real tag navigation is the generated `tags.md` page with `#anchor` links, which is what `post.html` links to when `link-tags: true`.
- Site chrome (title, nav, author links, analytics ID, pagination) is all in `_config.yml`.
