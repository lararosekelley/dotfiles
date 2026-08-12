---
name: recoll-search
description: Search the repo's full-text Recoll index to find code functions, patterns, strings, and files fast. Use instead of ad-hoc grep when a broad, ranked, full-text search across the whole repo (including non-code files: docs, PDFs, etc.) is more useful than a regex scan. Triggers on "search the codebase for", "find where X is used/defined", "is there existing code that does X", or any question better answered by an indexed search than a targeted grep.
---

# Recoll code search

Recoll is a full-text indexer/search tool (like a personal Google) that should already be configured on this
machine, indexing all repos in `~/Code` (config at `~/.recoll/recoll.conf`).

Before using this skill, confirm that `recoll` is installed and indexing the relevant directory.

## When to use this vs. grep/ripgrep

- Use **recoll** for: broad conceptual searches ("where do we compute wall thickness"), searching
  across file types recoll indexes well (docs, comments, markdown, PDFs), or when you don't know
  the exact string/regex to grep for.
- Use **grep/ripgrep** (still your default) for: exact symbol lookups, known strings, or when you
  need guaranteed up-to-the-second results — the recoll index updates on a schedule, not live on
  every file save. If a recoll result seems stale (renamed/deleted function), verify with a fresh
  grep/Read before trusting it.

## Basic query

```bash
recoll -t <query>
```

- `-t` = plain-text terminal query mode (always use this; without it recoll tries to launch the GUI).
- Bare words are ANDed together: `recoll -t generateBuilding Doc` finds docs containing both terms.
- Quote phrases: `recoll -t "generateBuilding Doc"` for an exact adjacent-word phrase.
- Exclude a term with a leading `-`: `recoll -t wall -freestanding`
- OR binds tighter than implicit AND: `t1 OR t2 t3` means `(t1 OR t2) AND t3`.
- Wildcards: `recoll -t 'generat*'` (quote to protect from shell globbing).
- Stemming: lowercase terms stem-expand (`floor` matches `flooring`, `floors`); Capitalized terms
  match the exact form only — capitalize a term (e.g. `Wall`) to avoid noisy stem matches on common
  words.

## Field and filter searches

- Filename only: `ext:ts`, `ext:tsx`, `ext:md`, other language extensions where relevant
- Restrict to a directory subtree: `dir:lib/studio`
- Combine: `recoll -t dir:lib/studio ext:ts FreestandingWall`
- Field search (title/author metadata, less useful for source code): `title:"..."`

## Useful output flags

- `-b` : bare URLs only (best for piping into further tooling/paths)
- `-a` : "all terms" mode (like ANDing every bare word, useful shorthand)
- `-o` : "any term" mode (OR every bare word)
- `-n <count>` : limit result count (default cap ~2000)
- `--paths-only` : print only `file://`-scheme results, with the scheme stripped — gives clean
  absolute paths, good for chaining into `Read`/`grep`
- `-A` : include a text abstract/snippet per result (helpful for judging relevance before opening files)

### Recommended default invocation

```bash
recoll -t -a --paths-only -n 30 <terms>
```

Gives a clean, capped list of absolute file paths matching all terms — pipe into `Read` or
follow up with targeted `grep`.

## Keeping the index fresh

Check status:

```bash
cat ~/.recoll/idxstatus.txt
```

Force a rescan (incremental — only re-indexes changed files):

```bash
recollindex
```

Full rebuild (rarely needed, slow given ~65k files in this repo):

```bash
recollindex -z
```

If search results look stale (missing recently added files, or expected recent renames still
showing old names), suggest running `recollindex` before trusting the results.
